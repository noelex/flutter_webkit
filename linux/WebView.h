#pragma once
#include <flutter_linux/flutter_linux.h>
#include <webkitgtk-4.1/webkit2/webkit2.h>

#include <atomic>
#include <map>
#include <string>

class WebView;

typedef struct
{
    gulong handler_id;
    std::string name;
    WebView *webview;
} JavascriptCallbackState;

class WebView
{
public:
    WebView(FlMethodChannel* method_channel, GtkFixed* container);
    ~WebView();

    void resize(int width, int height);
    void move(int x, int y);
    void load_uri(const gchar* uri);
    void evaluate_javascript(uint64_t id, const gchar* script);
    void reload(bool bypass_cache);
    bool register_javascript_callback(const gchar* name);
    void unregister_javascript_callback(const gchar* name);

private:
    WebKitWebView *_webview;
    GtkFixed* _container;
    FlMethodChannel* _method_channel;
    std::map<std::string, JavascriptCallbackState> _callback_states;
};