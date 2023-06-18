#pragma once

#include <flutter_linux/flutter_linux.h>

#include <vector>
#include <webkitgtk-4.1/webkit2/webkit2.h>

#include "WebView.h"

class WebViewManager {
    public:
        WebViewManager(FlMethodChannel *channel, FlView* fl);
        ~WebViewManager();
        
        uint64_t create_webview(FlValue *args);
        void destroy_webview(uint64_t id);
        WebView* get_webview(uint64_t id);

    private:
        std::vector<WebView*> _webviews;
        GtkFixed* _container;
        FlMethodChannel *_channel;
};