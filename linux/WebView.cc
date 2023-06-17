#include "WebView.h"
#include <JavaScriptCore/JavaScript.h>
#include <memory>

typedef struct
{
    WebView *webview;
    uint64_t id;
} js_callback_closure_t;

WebView::WebView(FlMethodChannel *method_channel, GtkFixed *container)
    : _container(container), _method_channel(method_channel), _js_call_id(0)
{
    auto webview = webkit_web_view_new();
    this->_webview = WEBKIT_WEB_VIEW(webview);

    auto widget = GTK_WIDGET(webview);
    gtk_widget_set_size_request(widget, 0, 0);
    gtk_fixed_put(container, widget, 0, 0);

    gtk_widget_show(widget);

    g_signal_connect(
        webview, "load-changed", (GCallback)(+[](WebKitWebView *web_view, WebKitLoadEvent load_event, gpointer user_data)
                                             {
            auto self = (WebView *)user_data;
            auto handle = (uint64_t)self;
            g_autoptr(FlValue) r = fl_value_new_map();
            fl_value_set_string_take(r, "webview", fl_value_new_int(handle));
            fl_value_set_string_take(r, "event", fl_value_new_int(load_event));
            fl_method_channel_invoke_method(self->_method_channel, "on_load_changed", r, NULL, NULL, NULL); }),
        this);
}

WebView::~WebView()
{
    gtk_widget_destroy(GTK_WIDGET(this->_webview));
    this->_container = nullptr;
    this->_webview = nullptr;
    this->_method_channel = nullptr;
}

void WebView::resize(int width, int height)
{
    gtk_widget_set_size_request(GTK_WIDGET(this->_webview), width, height);
}

void WebView::move(int x, int y)
{
    gtk_fixed_move(this->_container, GTK_WIDGET(this->_webview), x, y);
}

void WebView::load_uri(const gchar *uri)
{
    webkit_web_view_load_uri(this->_webview, uri);
}

uint64_t WebView::evaluate_javascript(const gchar *script)
{
    auto data = new js_callback_closure_t();
    auto id = _js_call_id++;
    data->id = id;
    data->webview = this;

    webkit_web_view_run_javascript(
        this->_webview,
        script,
        NULL,
        +[](GObject *source_object, GAsyncResult *res, gpointer user_data)
        {
            auto data = (js_callback_closure_t *)user_data;
            auto self = data->webview;
            auto handle = (uint64_t)self;
            auto id = data->id;

            delete data;

            if (self->_webview == NULL)
            {
                return;
            }

            GError *err = NULL;
            auto js_result = webkit_web_view_run_javascript_finish(self->_webview, res, &err);

            FlValue *r = fl_value_new_map();
            fl_value_set_string_take(r, "webview", fl_value_new_int(handle));
            fl_value_set_string_take(r, "id", fl_value_new_int(id));
            if (!err)
            {
                auto val = webkit_javascript_result_get_js_value(js_result);
                auto json = jsc_value_to_json(val, 0);

                fl_value_set_string_take(r, "error", fl_value_new_int(0));
                fl_value_set_string_take(r, "message", fl_value_new_null());
                fl_value_set_string_take(r, "data", json == NULL ? fl_value_new_null() : fl_value_new_string(json));
                g_free(json);
            }
            else
            {
                fl_value_set_string_take(r, "error", fl_value_new_int(err->code));
                fl_value_set_string_take(r, "message", err->message == NULL ? fl_value_new_null() : fl_value_new_string(err->message));
                fl_value_set_string_take(r, "data", fl_value_new_null());
            }

            fl_method_channel_invoke_method(self->_method_channel, "on_evaluate_javascript_completed", r, NULL, NULL, NULL);
        },
        data);

    return id;
}