#include "flutter_window.h"

#include <flutter/standard_method_codec.h>
#include <mmdeviceapi.h>
#include <propsys.h>
#include <initguid.h>
#include <functiondiscoverykeys_devpkey.h>
#include <shellapi.h>
#include <wrl/client.h>
#include <optional>
#include <string>
#include <variant>

namespace {
using Microsoft::WRL::ComPtr;

struct ScopedProperty {
  PROPVARIANT value{};
  ~ScopedProperty() { PropVariantClear(&value); }
};

std::optional<std::string> OutputLabel(const wchar_t* label) {
  if (!label) return std::nullopt;
  int units = 0;
  int scalars = 0;
  bool visible = false;
  while (units < 256 && label[units] != L'\0') {
    const wchar_t ch = label[units++];
    if (ch < 32 || (ch >= 127 && ch <= 159)) return std::nullopt;
    if (ch >= 0xD800 && ch <= 0xDBFF) {
      if (units >= 256 || label[units] < 0xDC00 || label[units] > 0xDFFF) {
        return std::nullopt;
      }
      ++units;
    } else if (ch >= 0xDC00 && ch <= 0xDFFF) {
      return std::nullopt;
    }
    const bool whitespace = ch == 0x20 || ch == 0xA0 || ch == 0x1680 ||
        (ch >= 0x2000 && ch <= 0x200A) || ch == 0x2028 || ch == 0x2029 ||
        ch == 0x202F || ch == 0x205F || ch == 0x3000 || ch == 0xFEFF;
    visible = visible || !whitespace;
    if (++scalars > 128) return std::nullopt;
  }
  if (!visible || label[units] != L'\0') return std::nullopt;
  const int bytes = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS,
      label, units, nullptr, 0, nullptr, nullptr);
  if (bytes <= 0) return std::nullopt;
  std::string utf8(static_cast<size_t>(bytes), '\0');
  if (WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, label, units,
      utf8.data(), bytes, nullptr, nullptr) != bytes) return std::nullopt;
  return utf8;
}

std::optional<std::string> DefaultOutputLabel() {
  // The runner initializes COM on this UI thread in wWinMain. Borrow it;
  // do not uninitialize another owner's apartment or enumerate all devices.
  ComPtr<IMMDeviceEnumerator> enumerator;
  if (FAILED(CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr,
      CLSCTX_INPROC_SERVER, IID_PPV_ARGS(enumerator.GetAddressOf())))) {
    return std::nullopt;
  }
  ComPtr<IMMDevice> endpoint;
  if (FAILED(enumerator->GetDefaultAudioEndpoint(eRender, eMultimedia,
      endpoint.GetAddressOf()))) return std::nullopt;
  DWORD state = 0;
  if (FAILED(endpoint->GetState(&state)) || state != DEVICE_STATE_ACTIVE) {
    return std::nullopt;
  }
  ComPtr<IPropertyStore> properties;
  if (FAILED(endpoint->OpenPropertyStore(STGM_READ, properties.GetAddressOf()))) {
    return std::nullopt;
  }
  ScopedProperty name;
  if (FAILED(properties->GetValue(PKEY_Device_FriendlyName, &name.value)) ||
      name.value.vt != VT_LPWSTR) return std::nullopt;
  return OutputLabel(name.value.pwszVal);
}

flutter::EncodableValue OutputState(bool settings_available) {
  const auto label = settings_available ? DefaultOutputLabel() : std::nullopt;
  flutter::EncodableMap state{
      {flutter::EncodableValue("observation"),
       flutter::EncodableValue(label ? "systemDefault" : "unknown")},
      {flutter::EncodableValue("canOpenSettings"),
       flutter::EncodableValue(settings_available)},
  };
  if (label) state.emplace(flutter::EncodableValue("label"), flutter::EncodableValue(*label));
  return flutter::EncodableValue(state);
}
}  // namespace

void FlutterWindow::InitializeAudioOutputChannel() {
  audio_output_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "io.github.z_y_o_y_i.yymusic/audio-output",
          &flutter::StandardMethodCodec::GetInstance());
  audio_output_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.arguments() &&
            !std::holds_alternative<std::monostate>(*call.arguments())) {
          result->Error("audio-output.invalid-call", "Output request unavailable");
          return;
        }
        if (call.method_name() == "getState") {
          result->Success(OutputState(IsWindow(GetHandle()) != FALSE));
        } else if (call.method_name() == "openSystemSettings") {
          if (!IsWindow(GetHandle()) || GetForegroundWindow() != GetHandle()) {
            result->Success(flutter::EncodableValue("unavailable"));
            return;
          }
          // Fixed documented target, never a URI supplied by Dart or media data.
          const auto launched = reinterpret_cast<INT_PTR>(ShellExecuteW(
              GetHandle(), L"open", L"ms-settings:sound", nullptr, nullptr, SW_SHOWNORMAL));
          result->Success(flutter::EncodableValue(launched > 32 ? "opened" : "failed"));
        } else {
          result->NotImplemented();
        }
      });
}
