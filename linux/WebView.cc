#include "WebView.h"
#include <JavaScriptCore/JavaScript.h>
#include <memory>
#include <string>
#include <vector>

// Fix IntelliSense errors
#ifndef g_autoptr
#define g_autoptr(x) x *
#define g_autofree
#endif

typedef struct
{
    WebView *webview;
    uint64_t id;
} js_callback_closure_t;

WebView::WebView(FlValue *args, FlMethodChannel *method_channel, GtkFixed *container)
    : _container(container),
      _method_channel(method_channel),
      _callback_states()
{
    auto webview = webkit_web_view_new();
    this->_webview = WEBKIT_WEB_VIEW(webview);

    auto widget = GTK_WIDGET(webview);
    gtk_widget_set_size_request(widget, 0, 0);
    gtk_fixed_put(container, widget, 0, 0);

    gtk_widget_show(widget);

    auto settings = webkit_web_view_get_settings(this->_webview);

    auto arg_cors_allowlist = fl_value_lookup_string(args, "cors_allowlist");
    auto arg_allow_file_access_from_file_urls = fl_value_lookup_string(args, "allow_file_access_from_file_urls");
    auto arg_enable_developer_extras = fl_value_lookup_string(args, "enable_developer_extras");

    if (arg_cors_allowlist != NULL)
    {
        if (fl_value_get_type(arg_cors_allowlist) != FL_VALUE_TYPE_LIST)
        {
            g_warning("'cors_allowlist' is ignored as it's not a FL_VALUE_TYPE_LIST.\n");
        }
        else
        {
            auto length = fl_value_get_length(arg_cors_allowlist);
            std::vector<const char *> arr;
            for (int i = 0; i < length; i++)
            {
                auto e = fl_value_get_list_value(arg_cors_allowlist, i);
                if (e != NULL && fl_value_get_type(e) == FL_VALUE_TYPE_STRING)
                {
                    auto s = fl_value_get_string(e);
                    arr.push_back(s);
                    g_message("'%s' is added to 'cors_allowlist'.\n", s);
                }
            }

            webkit_web_view_set_cors_allowlist(this->_webview, arr.data());
        }
    }

    if (arg_allow_file_access_from_file_urls != NULL)
    {
        if (fl_value_get_type(arg_allow_file_access_from_file_urls) != FL_VALUE_TYPE_BOOL)
        {
            g_warning("'allow_file_access_from_file_urls' is ignored as it's not a FL_VALUE_TYPE_BOOL.\n");
        }
        else
        {
            auto value = fl_value_get_bool(arg_allow_file_access_from_file_urls);
            webkit_settings_set_allow_file_access_from_file_urls(settings, value);
            g_message("'allow_file_access_from_file_urls' is set to %s.\n", value ? "true" : "false");
        }
    }

    if (arg_enable_developer_extras != NULL)
    {
        if (fl_value_get_type(arg_enable_developer_extras) != FL_VALUE_TYPE_BOOL)
        {
            g_warning("'enable_developer_extras' is ignored as it's not a FL_VALUE_TYPE_BOOL.\n");
        }
        else
        {
            auto value = fl_value_get_bool(arg_enable_developer_extras);
            webkit_settings_set_enable_developer_extras(settings, value);
            g_message("'enable_developer_extras' is set to %s.\n", value ? "true" : "false");
        }
    }

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

    g_signal_connect(
        webview, "notify::uri", (GCallback)(+[](WebKitWebView *web_view, GParamSpec *property, gpointer user_data)
                                            {
        auto self = (WebView *)user_data;
        auto handle = (uint64_t)self;

        auto uri = webkit_web_view_get_uri(web_view);
        g_autoptr(FlValue) r = fl_value_new_map();
        fl_value_set_string_take(r, "webview", fl_value_new_int(handle));
        fl_value_set_string_take(r, "uri", uri == NULL ? fl_value_new_null() : fl_value_new_string(uri));
        fl_method_channel_invoke_method(self->_method_channel, "on_uri_changed", r, NULL, NULL, NULL); }),
        this);

    g_signal_connect(
        webview, "notify::title", (GCallback)(+[](WebKitWebView *web_view, GParamSpec *property, gpointer user_data)
                                              {
        auto self = (WebView *)user_data;
        auto handle = (uint64_t)self;

        auto title = webkit_web_view_get_title(web_view);
        g_autoptr(FlValue) r = fl_value_new_map();
        fl_value_set_string_take(r, "webview", fl_value_new_int(handle));
        fl_value_set_string_take(r, "title", title == NULL ? fl_value_new_null() : fl_value_new_string(title));
        fl_method_channel_invoke_method(self->_method_channel, "on_title_changed", r, NULL, NULL, NULL); }),
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

void WebView::evaluate_javascript(uint64_t id, const gchar *script)
{
    auto data = new js_callback_closure_t();
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

            g_autoptr(FlValue) r = fl_value_new_map();
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
}

void WebView::reload(bool bypass_cache)
{
    if (bypass_cache)
    {
        webkit_web_view_reload_bypass_cache(this->_webview);
    }
    else
    {
        webkit_web_view_reload(this->_webview);
    }
}

bool WebView::register_javascript_callback(const gchar *name)
{
    std::string cb_name(name);
    if (this->_callback_states.count(cb_name) > 0)
    {
        g_warning("Javascript callback '%s' is already register in webview #%ld.", name, (uint64_t)this);
        return false;
    }

    JavascriptCallbackState state{
        .handler_id = 0,
        .name = cb_name,
        .webview = this};

    this->_callback_states.insert(std::make_pair(cb_name, state));

    auto manager = webkit_web_view_get_user_content_manager(this->_webview);

    std::string signal_name("script-message-received::");
    signal_name.append(cb_name);

    auto handler_id = g_signal_connect(
        manager, signal_name.c_str(), (GCallback)(+[](WebKitUserContentManager *content_manager, WebKitJavascriptResult *res, gpointer user_data)
                                                  {
            auto state =(JavascriptCallbackState *)user_data;
            auto self = state->webview;
            auto handle = (uint64_t)self;

            auto value = webkit_javascript_result_get_js_value(res);
            auto json = jsc_value_to_json(value, 0);

            g_autoptr(FlValue) r = fl_value_new_map();
            fl_value_set_string_take(r, "webview", fl_value_new_int(handle));
            fl_value_set_string_take(r, "name", fl_value_new_string(state->name.c_str()));
            fl_value_set_string_take(r, "data", json == NULL ? fl_value_new_null() : fl_value_new_string(json));
            g_free(json);

            fl_method_channel_invoke_method(self->_method_channel, "on_javascript_callback", r, NULL, NULL, NULL); }),
        &this->_callback_states[cb_name]);

    this->_callback_states[cb_name].handler_id = handler_id;

    auto ok = webkit_user_content_manager_register_script_message_handler(manager, name);
    if (!ok)
    {
        this->_callback_states.erase(cb_name);
        g_signal_handler_disconnect(manager, handler_id);
    }
    else
    {
        g_message("Registered callback '%s' in webview #%ld.", name, (uint64_t)this);
    }

    return ok;
}

void WebView::unregister_javascript_callback(const gchar *name)
{
    std::string cb_name(name);
    if (this->_callback_states.count(cb_name) == 0)
    {
        g_warning("Unable to unregister callback '%s' from webview #%ld as it's not registered.", name, (uint64_t)this);
        return;
    }

    auto manager = webkit_web_view_get_user_content_manager(this->_webview);
    webkit_user_content_manager_unregister_script_message_handler(manager, name);

    g_signal_handler_disconnect(manager, this->_callback_states[cb_name].handler_id);
    this->_callback_states.erase(cb_name);

    g_message("Unregistered callback '%s' from webview #%ld.", name, (uint64_t)this);
}

void WebView::open_inspector()
{
    WebKitWebInspector *inspector = webkit_web_view_get_inspector(this->_webview);
    webkit_web_inspector_show(WEBKIT_WEB_INSPECTOR(inspector));
}