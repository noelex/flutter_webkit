import 'dart:ui';

import 'package:flutter_webkit/src/types.dart';

import 'flutter_webkit_platform_interface.dart';

class FlutterWebkit {
  Future<String?> getPlatformVersion() {
    return FlutterWebkitPlatform.instance.getPlatformVersion();
  }

  Future<int?> createWebView() {
    return FlutterWebkitPlatform.instance.createWebView();
  }

  Future<void> destroyWebView(int webviewId) {
    return FlutterWebkitPlatform.instance.destroyWebView(webviewId);
  }

  Future<void> open(int webviewId, String uri) {
    return FlutterWebkitPlatform.instance.open(webviewId, uri);
  }

  Future<void> setDimension(int webviewId, Rect rect) {
    return FlutterWebkitPlatform.instance.setDimension(webviewId, rect);
  }

  Stream<LoadEvent> getLoadEvents(int webviewId) {
    return FlutterWebkitPlatform.instance.getLoadEvents(webviewId);
  }

  Future<dynamic> evaluateJavascript(int webviewId, String script) {
    return FlutterWebkitPlatform.instance.evaluateJavascript(webviewId, script);
  }
}
