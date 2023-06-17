#pragma once
#include <flutter_linux/flutter_linux.h>
#include <webkitgtk-4.1/webkit2/webkit2.h>

#include <atomic>

class WebView
{
public:
    WebView(FlMethodChannel* method_channel, GtkFixed* container);
    ~WebView();

    void resize(int width, int height);
    void move(int x, int y);
    void load_uri(const gchar* uri);
    uint64_t evaluate_javascript(const gchar* script);

private:
    WebKitWebView *_webview;
    GtkFixed* _container;
    FlMethodChannel* _method_channel;
    std::atomic_uint64_t _js_call_id;
};