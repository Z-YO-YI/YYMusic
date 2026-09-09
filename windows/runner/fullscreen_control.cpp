#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

#include <variant>

namespace {
bool WriteStyle(HWND window, int index, LONG_PTR style) {
  SetLastError(0);
  return SetWindowLongPtr(window, index, style) != 0 || GetLastError() == 0;
}
}  // namespace

flutter::EncodableValue FlutterWindow::FullscreenState() {
  // Geometry is this window's restoration evidence, never an input capability.
  RECT bounds{};
  GetWindowRect(GetHandle(), &bounds);
  MONITORINFO monitor{};
  monitor.cbSize = sizeof(monitor);
  GetMonitorInfo(MonitorFromWindow(GetHandle(), MONITOR_DEFAULTTONEAREST), &monitor);
  return flutter::EncodableValue(flutter::EncodableMap{
      {flutter::EncodableValue("enabled"), flutter::EncodableValue(fullscreen_)},
      {flutter::EncodableValue("style"), flutter::EncodableValue(
          static_cast<int64_t>(GetWindowLongPtr(GetHandle(), GWL_STYLE)))},
      {flutter::EncodableValue("extendedStyle"), flutter::EncodableValue(
          static_cast<int64_t>(GetWindowLongPtr(GetHandle(), GWL_EXSTYLE)))},
      {flutter::EncodableValue("left"), flutter::EncodableValue(static_cast<int>(bounds.left))},
      {flutter::EncodableValue("top"), flutter::EncodableValue(static_cast<int>(bounds.top))},
      {flutter::EncodableValue("right"), flutter::EncodableValue(static_cast<int>(bounds.right))},
      {flutter::EncodableValue("bottom"), flutter::EncodableValue(static_cast<int>(bounds.bottom))},
      {flutter::EncodableValue("monitorLeft"), flutter::EncodableValue(static_cast<int>(monitor.rcMonitor.left))},
      {flutter::EncodableValue("monitorTop"), flutter::EncodableValue(static_cast<int>(monitor.rcMonitor.top))},
      {flutter::EncodableValue("monitorRight"), flutter::EncodableValue(static_cast<int>(monitor.rcMonitor.right))},
      {flutter::EncodableValue("monitorBottom"), flutter::EncodableValue(static_cast<int>(monitor.rcMonitor.bottom))},
  });
}

bool FlutterWindow::SetFullscreen(bool enabled, bool preserve_minimized) {
  if (fullscreen_transition_) return false;
  if (enabled == fullscreen_) return true;
  const HWND window = GetHandle();
  if (!IsWindow(window)) return false;
  fullscreen_transition_ = true;
  bool success = false;
  if (enabled) {
    WINDOWPLACEMENT placement{};
    placement.length = sizeof(placement);
    MONITORINFO monitor{};
    monitor.cbSize = sizeof(monitor);
    if (!IsIconic(window) && GetWindowPlacement(window, &placement) &&
        GetMonitorInfo(MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST), &monitor)) {
      fullscreen_placement_ = placement;
      fullscreen_style_ = GetWindowLongPtr(window, GWL_STYLE);
      fullscreen_extended_style_ = GetWindowLongPtr(window, GWL_EXSTYLE);
      // Retain the recovery record even if an intermediate native call fails.
      fullscreen_ = true;
      success = WriteStyle(window, GWL_STYLE,
          fullscreen_style_ & ~static_cast<LONG_PTR>(WS_OVERLAPPEDWINDOW)) &&
          WriteStyle(window, GWL_EXSTYLE,
              fullscreen_extended_style_ & ~static_cast<LONG_PTR>(
                  WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE | WS_EX_DLGMODALFRAME | WS_EX_STATICEDGE)) &&
          SetWindowPos(window, nullptr, monitor.rcMonitor.left, monitor.rcMonitor.top,
              monitor.rcMonitor.right - monitor.rcMonitor.left,
              monitor.rcMonitor.bottom - monitor.rcMonitor.top,
              SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
    }
  } else {
    auto placement = fullscreen_placement_;
    if (preserve_minimized) {
      if (placement.showCmd == SW_SHOWMAXIMIZED) placement.flags |= WPF_RESTORETOMAXIMIZED;
      placement.showCmd = SW_SHOWMINNOACTIVE;
    }
    // Attempt every restoration step; keep the record if any step failed.
    const bool style = WriteStyle(window, GWL_STYLE, fullscreen_style_);
    const bool extended = WriteStyle(window, GWL_EXSTYLE, fullscreen_extended_style_);
    const bool position = SetWindowPlacement(window, &placement) != FALSE;
    const bool frame = SetWindowPos(window, nullptr, 0, 0, 0, 0,
        SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED) != FALSE;
    success = style && extended && position && frame;
    if (success) fullscreen_ = false;
  }
  fullscreen_transition_ = false;
  if (!success && enabled && fullscreen_) {
    SetFullscreen(false);
  }
  if (fullscreen_channel_ && fullscreen_connected_) {
    fullscreen_channel_->InvokeMethod("stateChanged",
        std::make_unique<flutter::EncodableValue>(FullscreenState()));
  }
  return success;
}

void FlutterWindow::InitializeFullscreenChannel() {
  fullscreen_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "io.github.z_y_o_y_i.yymusic/fullscreen",
          &flutter::StandardMethodCodec::GetInstance());
  fullscreen_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (!IsWindow(GetHandle()) || (call.arguments() &&
            !std::holds_alternative<std::monostate>(*call.arguments()))) {
          result->Error("fullscreen.invalid-call", "Fullscreen request unavailable");
          return;
        }
        const auto& method = call.method_name();
        if (method == "configure") {
          fullscreen_connected_ = true;
        } else if (method == "getState") {
          // Read-only observation is available after detach for verification.
        } else if (method == "restore" || method == "detach") {
          if (!SetFullscreen(false)) {
            result->Error("fullscreen.restore-failed", "Fullscreen request unavailable");
            return;
          }
          if (method == "detach") fullscreen_connected_ = false;
        } else if (method == "enter") {
          if (!fullscreen_connected_ || !SetFullscreen(true)) {
            result->Error("fullscreen.enter-failed", "Fullscreen request unavailable");
            return;
          }
        } else {
          result->NotImplemented();
          return;
        }
        result->Success(FullscreenState());
      });
}
