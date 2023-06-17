#include <algorithm>
#include "WebViewManager.h"

#define FIND_WEBVIEW(id) \
    (std::find(this->_webviews.begin(), this->_webviews.end(), ID_TO_WEBVIEW(id)))

#define ID_TO_WEBVIEW(id) ((WebView *)(void *)id)

WebViewManager::WebViewManager(FlMethodChannel *channel, FlView *fl)
    : _webviews(), _channel(channel)
{
    auto overlay = GTK_OVERLAY(gtk_widget_get_parent(GTK_WIDGET(fl)));
    auto fixed = gtk_fixed_new();
    this->_container = GTK_FIXED(fixed);
    gtk_overlay_add_overlay(overlay, fixed);
    gtk_widget_show(fixed);
}

WebViewManager::~WebViewManager()
{
    for (auto i = 0; i < this->_webviews.size(); i++)
    {
        delete this->_webviews.at(i);
    }
    this->_webviews.clear();

    gtk_widget_destroy(GTK_WIDGET(this->_container));
    this->_container = nullptr;
}

uint64_t WebViewManager::create_webview()
{
    auto webview = new WebView(this->_channel, this->_container);
    this->_webviews.push_back(webview);
    g_message("Created webview #%ld, %ld views total.", (uint64_t)webview, this->_webviews.size());
    return (uint64_t)webview;
}

void WebViewManager::destroy_webview(uint64_t id)
{
    auto pos = FIND_WEBVIEW(id);
    if (pos != this->_webviews.end())
    {
        delete ID_TO_WEBVIEW(id);
        this->_webviews.erase(pos);
    }
    else
    {
        g_warning("Webview #%ld does not exists.\n", id);
    }
}

WebView *WebViewManager::get_webview(uint64_t id)
{
    auto pos = FIND_WEBVIEW(id);
    if (pos != this->_webviews.end())
    {
        return ID_TO_WEBVIEW(id);
    }
    else
    {
        g_warning("Webview #%ld does not exists.\n", id);
        return NULL;
    }
}