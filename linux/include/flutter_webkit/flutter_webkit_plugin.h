#ifndef FLUTTER_PLUGIN_FLUTTER_WEBKIT_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_WEBKIT_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

typedef struct _FlutterWebkitPlugin FlutterWebkitPlugin;
typedef struct {
  GObjectClass parent_class;
} FlutterWebkitPluginClass;

FLUTTER_PLUGIN_EXPORT GType flutter_webkit_plugin_get_type();

FLUTTER_PLUGIN_EXPORT void flutter_webkit_plugin_register_with_registrar(
    FlPluginRegistrar* registrar);

FLUTTER_PLUGIN_EXPORT void flutter_webkit_plugin_enable_overlay(GtkWindow* window, FlView* fl_view);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_FLUTTER_WEBKIT_PLUGIN_H_
