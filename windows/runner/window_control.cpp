#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

#include <variant>

flutter::EncodableValue FlutterWindow::WindowState() {
  const HWND window = GetHandle();
  return flutter::EncodableValue(flutter::EncodableMap{
      {flutter::EncodableValue("maximized"),
       flutter::EncodableValue(IsZoomed(window) != FALSE)},
      {flutter::EncodableValue("minimized"),
       flutter::EncodableValue(IsIconic(window) != FALSE)},
      {flutter::EncodableValue("customFrame"),
       flutter::EncodableValue(custom_frame_ &&
           (GetWindowLongPtr(window, GWL_STYLE) & WS_CAPTION) == 0)},
  });
}

void FlutterWindow::PublishWindowState() {
  window_channel_->InvokeMethod(
      "stateChanged",
      std::make_unique<flutter::EncodableValue>(WindowState()));
}

bool FlutterWindow::SetCustomFrame(bool enabled) {
  if (enabled == custom_frame_) return true;
  const HWND window = GetHandle();
  const LONG_PTR previous_style = GetWindowLongPtr(window, GWL_STYLE);
  const LONG_PTR next_style =
      enabled ? (previous_style & ~static_cast<LONG_PTR>(WS_CAPTION))
              : original_window_style_;
  SetLastError(0);
  const LONG_PTR result = SetWindowLongPtr(window, GWL_STYLE, next_style);
  if (result == 0 && GetLastError() != 0) return false;
  if (!SetWindowPos(window, nullptr, 0, 0, 0, 0,
                    SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER |
                        SWP_NOACTIVATE | SWP_FRAMECHANGED)) {
    SetWindowLongPtr(window, GWL_STYLE, previous_style);
    SetWindowPos(window, nullptr, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER |
                     SWP_NOACTIVATE | SWP_FRAMECHANGED);
    return false;
  }
  if (enabled) original_window_style_ = previous_style;
  custom_frame_ = enabled;
  close_approved_ = false;
  return true;
}

void FlutterWindow::InitializeWindowChannel() {
  window_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "io.github.z_y_o_y_i.yymusic/window",
          &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (!IsWindow(GetHandle()) || (call.arguments() &&
            !std::holds_alternative<std::monostate>(*call.arguments()))) {
          result->Error("window.invalid-call", "Window request unavailable");
          return;
        }
        const auto& method = call.method_name();
        if (method == "configure" || method == "detach") {
          if (!SetCustomFrame(method == "configure")) {
            result->Error("window.frame-failed", "Window request unavailable");
            return;
          }
          result->Success(WindowState());
          return;
        }
        if (method == "getState") {
          result->Success(WindowState());
          return;
        }
        if (!custom_frame_) {
          result->Error("window.not-ready", "Window request unavailable");
          return;
        }
        const HWND window = GetHandle();
        if (method == "minimize") {
          // ShowWindow returns previous visibility, not operation success.
          ShowWindow(window, SW_MINIMIZE);
        } else if (method == "toggleMaximize") {
          ShowWindow(window, IsZoomed(window) ? SW_RESTORE : SW_MAXIMIZE);
        } else if (method == "restore") {
          ShowWindow(window, SW_RESTORE);
        } else if (method == "startDrag") {
          // Only a real primary-button drag can start a system move loop.
          POINT position;
          if ((GetAsyncKeyState(VK_LBUTTON) & 0x8000) != 0 &&
              GetCursorPos(&position)) {
            ReleaseCapture();
            if (!PostMessage(window, WM_NCLBUTTONDOWN, HTCAPTION,
                MAKELPARAM(position.x, position.y))) {
              result->Error("window.move-failed", "Window request unavailable");
              return;
            }
          }
        } else if (method == "requestClose" || method == "completeClose") {
          const bool approve = method == "completeClose";
          close_approved_ = approve;
          if (!PostMessage(window, WM_CLOSE, 0, 0)) {
            close_approved_ = false;
            result->Error("window.close-failed", "Window request unavailable");
            return;
          }
          result->Success();
          return;
        } else {
          result->NotImplemented();
          return;
        }
        result->Success(WindowState());
      });
}
