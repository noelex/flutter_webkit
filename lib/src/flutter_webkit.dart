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


  Stream<String?> getUriEvents(int webviewId) {
    return FlutterWebkitPlatform.instance.getUriEvents(webviewId);
  }

  Stream<String?> getTitleEvents(int webviewId) {
    return FlutterWebkitPlatform.instance.getTitleEvents(webviewId);
  }

  Future<dynamic> evaluateJavascript(int webviewId, int callId, String script) {
    return FlutterWebkitPlatform.instance.evaluateJavascript(webviewId, callId, script);
  }

  Future<void> reload(int webviewId, bool bypassCache) {
    return FlutterWebkitPlatform.instance.reload(webviewId, bypassCache);
  }
}
