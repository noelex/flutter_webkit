#include "include/flutter_webkit/flutter_webkit_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#include "flutter_webkit_plugin_private.h"
#include "WebViewManager.h"


#include "WebViewViewFactory.h"

#define FLUTTER_WEBKIT_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), flutter_webkit_plugin_get_type(), \
                              FlutterWebkitPlugin))

// Fix IntelliSense errors
#ifndef g_autoptr
#define g_autoptr(x) x *
#define g_autofree
#endif

struct _FlutterWebkitPlugin
{
  GObject parent_instance;
  WebViewManager *manager;
};

G_DEFINE_TYPE(FlutterWebkitPlugin, flutter_webkit_plugin, g_object_get_type())

static FlMethodResponse *handle_create_webview(FlutterWebkitPlugin *self, FlValue *args)
{
  auto id = self->manager->create_webview(args);
  g_autoptr(FlValue) result = fl_value_new_int(id);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static FlMethodResponse *handle_destroy_webview(FlutterWebkitPlugin *self, FlValue *args)
{
  auto arg = fl_value_lookup_string(args, "webview");
  if (arg && fl_value_get_type(arg) == FL_VALUE_TYPE_INT)
  {
    auto id = fl_value_get_int(arg);
    g_message("Destroying webview #%ld.\n", id);
    self->manager->destroy_webview(id);
  }
  else
  {
    g_warning("Unable to detroy webview, invalid arguments.\n");
  }

  g_autoptr(FlValue) result = fl_value_new_null();
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static FlMethodResponse *handle_set_dimension(FlutterWebkitPlugin *self, FlValue *args)
{
  auto arg_id = fl_value_lookup_string(args, "webview");
  auto arg_x = fl_value_lookup_string(args, "x");
  auto arg_y = fl_value_lookup_string(args, "y");
  auto arg_w = fl_value_lookup_string(args, "w");
  auto arg_h = fl_value_lookup_string(args, "h");

  if (arg_id == NULL ||
      arg_x == NULL || arg_y == NULL ||
      arg_w == NULL || arg_h == NULL ||
      fl_value_get_type(arg_id) != FL_VALUE_TYPE_INT ||
      fl_value_get_type(arg_x) != FL_VALUE_TYPE_INT ||
      fl_value_get_type(arg_y) != FL_VALUE_TYPE_INT ||
      fl_value_get_type(arg_w) != FL_VALUE_TYPE_INT ||
      fl_value_get_type(arg_h) != FL_VALUE_TYPE_INT)
  {
    g_warning("Unable to set dimension, invalid arguments.\n");
  }
  else
  {
    auto id = fl_value_get_int(arg_id);
    auto x = fl_value_get_int(arg_x);
    auto y = fl_value_get_int(arg_y);
    auto w = fl_value_get_int(arg_w);
    auto h = fl_value_get_int(arg_h);

    auto webview = self->manager->get_webview(id);
    if (webview == NULL)
    {
      g_warning("Unable to set dimension, webview #%ld is not found.\n", id);
    }
    else
    {
      g_debug("Setting dimension of webview #%ld to { x = %ld, y = %ld, w = %ld, h = %ld }.\n", id, x, y, w, h);
      webview->move(x, y);
      webview->resize(w, h);
    }
  }

  g_autoptr(FlValue) result = fl_value_new_null();
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static FlMethodResponse *handle_open(FlutterWebkitPlugin *self, FlValue *args)
{
  auto arg_id = fl_value_lookup_string(args, "webview");
  auto arg_uri = fl_value_lookup_string(args, "uri");

  if (arg_id == NULL || arg_uri == NULL ||
      fl_value_get_type(arg_id) != FL_VALUE_TYPE_INT ||
      fl_value_get_type(arg_uri) != FL_VALUE_TYPE_STRING)
  {
    g_warning("Unable to open URI, invalid arguments.\n");
  }
  else
  {
    auto id = fl_value_get_int(arg_id);
    auto uri = fl_value_get_string(arg_uri);

    auto webview = self->manager->get_webview(id);
    if (webview == NULL)
    {
      g_warning("Unable to open URI, webview #%ld is not found.\n", id);
    }
    else
    {
      g_message("Opening URI '%s' with webview #%ld..\n", uri, id);
      webview->load_uri(uri);
    }
  }

  g_autoptr(FlValue) result = fl_value_new_null();
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static FlMethodResponse *handle_evaluate_javascript(FlutterWebkitPlugin *self, FlValue *args)
{
  auto arg_webview = fl_value_lookup_string(args, "webview");
  auto arg_id = fl_value_lookup_string(args, "id");
  auto arg_script = fl_value_lookup_string(args, "script");

  if (arg_webview == NULL || arg_id == NULL || arg_script == NULL ||
      fl_value_get_type(arg_webview) != FL_VALUE_TYPE_INT ||
      fl_value_get_type(arg_id) != FL_VALUE_TYPE_INT ||
      fl_value_get_type(arg_script) != FL_VALUE_TYPE_STRING)
  {
    g_warning("Unable to evaluate javascript, invalid arguments.\n");
  }
  else
  {
    auto webviewId = fl_value_get_int(arg_webview);
    auto id = fl_value_get_int(arg_id);
    auto script = fl_value_get_string(arg_script);

    auto webview = self->manager->get_webview(webviewId);
    if (webview == NULL)
    {
      g_warning("Unable to evaluate javascript, webview #%ld is not found.\n", webviewId);
    }
    else
    {
      g_debug("Evaluating javascript in webview #%ld..\n", id);
      webview->evaluate_javascript(id, script);
    }
  }

  g_autoptr(FlValue) result = fl_value_new_null();
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static FlMethodResponse *handle_reload(FlutterWebkitPlugin *self, FlValue *args)
{
  auto arg_id = fl_value_lookup_string(args, "webview");
  auto arg_bypass_cache = fl_value_lookup_string(args, "bypass_cache");

  if (arg_id == NULL || arg_bypass_cache == NULL ||
      fl_value_get_type(arg_id) != FL_VALUE_TYPE_INT ||
      fl_value_get_type(arg_bypass_cache) != FL_VALUE_TYPE_BOOL)
  {
    g_warning("Unable to reload, invalid arguments.\n");
  }
  else
  {
    auto id = fl_value_get_int(arg_id);
    auto bypass_cache = fl_value_get_bool(arg_bypass_cache);

    auto webview = self->manager->get_webview(id);
    if (webview == NULL)
    {
      g_warning("Unable to reload, webview #%ld is not found.\n", id);
    }
    else
    {
      g_debug("Reloading webview #%ld, bypass_cache = %s.\n", id, bypass_cache ? "yes" : "no");
      webview->reload(bypass_cache);
    }
  }

  g_autoptr(FlValue) result = fl_value_new_null();
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static FlMethodResponse *handle_register_javascript_callback(FlutterWebkitPlugin *self, FlValue *args)
{
  auto arg_id = fl_value_lookup_string(args, "webview");
  auto arg_name = fl_value_lookup_string(args, "name");

  bool ret = false;
  if (arg_id == NULL || arg_name == NULL ||
      fl_value_get_type(arg_id) != FL_VALUE_TYPE_INT ||
      fl_value_get_type(arg_name) != FL_VALUE_TYPE_STRING)
  {
    g_warning("Unable to register javascript callback, invalid arguments.\n");
  }
  else
  {
    auto id = fl_value_get_int(arg_id);
    auto name = fl_value_get_string(arg_name);

    auto webview = self->manager->get_webview(id);
    if (webview == NULL)
    {
      g_warning("Unable to register javascript callback, webview #%ld is not found.\n", id);
    }
    else
    {
      ret = webview->register_javascript_callback(name);
    }
  }

  g_autoptr(FlValue) result = fl_value_new_bool(ret);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static FlMethodResponse *handle_unregister_javascript_callback(FlutterWebkitPlugin *self, FlValue *args)
{
  auto arg_id = fl_value_lookup_string(args, "webview");
  auto arg_name = fl_value_lookup_string(args, "name");

  if (arg_id == NULL || arg_name == NULL ||
      fl_value_get_type(arg_id) != FL_VALUE_TYPE_INT ||
      fl_value_get_type(arg_name) != FL_VALUE_TYPE_STRING)
  {
    g_warning("Unable to unregister javascript callback, invalid arguments.\n");
  }
  else
  {
    auto id = fl_value_get_int(arg_id);
    auto name = fl_value_get_string(arg_name);

    auto webview = self->manager->get_webview(id);
    if (webview == NULL)
    {
      g_warning("Unable to register javascript callback, webview #%ld is not found.\n", id);
    }
    else
    {
      webview->unregister_javascript_callback(name);
    }
  }

  g_autoptr(FlValue) result = fl_value_new_null();
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static FlMethodResponse *handle_open_inspector(FlutterWebkitPlugin *self, FlValue *args)
{
  auto arg_id = fl_value_lookup_string(args, "webview");

  if (arg_id == NULL ||
      fl_value_get_type(arg_id) != FL_VALUE_TYPE_INT)
  {
    g_warning("Unable to open inspector, invalid arguments.\n");
  }
  else
  {
    auto id = fl_value_get_int(arg_id);

    auto webview = self->manager->get_webview(id);
    if (webview == NULL)
    {
      g_warning("Unable to open inspector, webview #%ld is not found.\n", id);
    }
    else
    {
      webview->open_inspector();
    }
  }

  g_autoptr(FlValue) result = fl_value_new_null();
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

// Called when a method call is received from Flutter.
static void flutter_webkit_plugin_handle_method_call(
    FlutterWebkitPlugin *self,
    FlMethodCall *method_call)
{
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar *method = fl_method_call_get_name(method_call);
  auto args = fl_method_call_get_args(method_call);

  if (strcmp(method, "getPlatformVersion") == 0)
  {
    response = get_platform_version();
  }
  else if (strcmp(method, "create_webview") == 0)
  {
    response = handle_create_webview(self, args);
  }
  else if (strcmp(method, "destroy_webview") == 0)
  {
    response = handle_destroy_webview(self, args);
  }
  else if (strcmp(method, "set_dimension") == 0)
  {
    response = handle_set_dimension(self, args);
  }
  else if (strcmp(method, "open") == 0)
  {
    response = handle_open(self, args);
  }
  else if (strcmp(method, "evaluate_javascript") == 0)
  {
    response = handle_evaluate_javascript(self, args);
  }
  else if (strcmp(method, "reload") == 0)
  {
    response = handle_reload(self, args);
  }
  else if (strcmp(method, "register_javascript_callback") == 0)
  {
    response = handle_register_javascript_callback(self, args);
  }
  else if (strcmp(method, "unregister_javascript_callback") == 0)
  {
    response = handle_unregister_javascript_callback(self, args);
  }
  else if (strcmp(method, "open_inspector") == 0)
  {
    response = handle_open_inspector(self, args);
  }
  else
  {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

FlMethodResponse *get_platform_version()
{
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) result = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static void flutter_webkit_plugin_dispose(GObject *object)
{
  delete FLUTTER_WEBKIT_PLUGIN(object)->manager;
  G_OBJECT_CLASS(flutter_webkit_plugin_parent_class)->dispose(object);
}

static void flutter_webkit_plugin_class_init(FlutterWebkitPluginClass *klass)
{
  G_OBJECT_CLASS(klass)->dispose = flutter_webkit_plugin_dispose;
}

static void flutter_webkit_plugin_init(FlutterWebkitPlugin *self)
{
  self->manager = NULL;
}

static void method_call_cb(FlMethodChannel *channel, FlMethodCall *method_call,
                           gpointer user_data)
{
  FlutterWebkitPlugin *plugin = FLUTTER_WEBKIT_PLUGIN(user_data);
  flutter_webkit_plugin_handle_method_call(plugin, method_call);
}

void flutter_webkit_plugin_register_with_registrar(FlPluginRegistrar *registrar)
{
  FlutterWebkitPlugin *plugin = FLUTTER_WEBKIT_PLUGIN(
      g_object_new(flutter_webkit_plugin_get_type(), nullptr));

  FlView *view = fl_plugin_registrar_get_view(registrar);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "flutter_webkit",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);
  plugin->manager = new WebViewManager(channel, view);

  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
  WebViewViewFactory* factory = webview_view_factory_new(messenger);
  fl_plugin_registrar_register_view_factory(registrar,
                                            FL_PLATFORM_VIEW_FACTORY(factory),
                                            "plugins.flutter.io/webview");

  g_object_unref(plugin);
}

void flutter_webkit_plugin_enable_overlay(GtkWindow *window, FlView *fl_view)
{
  GtkOverlay *overlay = GTK_OVERLAY(gtk_overlay_new());
  gtk_overlay_add_overlay(overlay, GTK_WIDGET(fl_view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(overlay));
  gtk_widget_show(GTK_WIDGET(overlay));
}