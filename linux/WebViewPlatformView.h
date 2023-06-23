#ifndef WEBVIEW_PLATFORM_VIEW_H_
#define WEBVIEW_PLATFORM_VIEW_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(WebViewPlatformView,
                     webview_platform_view,
                     WEBVIEW,
                     PLATFORM_VIEW,
                     FlPlatformView)

WebViewPlatformView* webview_platform_view_new(FlBinaryMessenger* messenger,
                                               int64_t view_identifier,
                                               FlValue* args);

G_END_DECLS

#endif  // WEBVIEW_PLATFORM_VIEW_H_