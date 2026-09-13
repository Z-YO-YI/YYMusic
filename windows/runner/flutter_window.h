#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/encodable_value.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>

#include <memory>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  void InitializeWindowChannel();
  void InitializeAudioOutputChannel();
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> audio_output_channel_;
  flutter::EncodableValue WindowState();
  void PublishWindowState();
  bool SetCustomFrame(bool enabled);
  void InitializeFullscreenChannel();
  flutter::EncodableValue FullscreenState();
  bool SetFullscreen(bool enabled, bool preserve_minimized = false);
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> fullscreen_channel_;
  WINDOWPLACEMENT fullscreen_placement_{};
  LONG_PTR fullscreen_style_ = 0;
  LONG_PTR fullscreen_extended_style_ = 0;
  bool fullscreen_ = false;
  bool fullscreen_transition_ = false;
  bool fullscreen_connected_ = false;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> window_channel_;
  LONG_PTR original_window_style_ = 0;
  bool custom_frame_ = false;
  bool close_approved_ = false;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
