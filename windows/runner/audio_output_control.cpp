#include "flutter_window.h"

#include <flutter/standard_method_codec.h>
#include <shellapi.h>
#include <variant>

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
          result->Success(flutter::EncodableValue(flutter::EncodableMap{
              {flutter::EncodableValue("observation"), flutter::EncodableValue("unknown")},
              {flutter::EncodableValue("canOpenSettings"),
               flutter::EncodableValue(IsWindow(GetHandle()) != FALSE)},
          }));
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
