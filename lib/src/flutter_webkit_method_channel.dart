import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webkit/src/types.dart';

import 'flutter_webkit_platform_interface.dart';

class _WebViewEvent<T> {
  final int webviewId;
  final T data;

  _WebViewEvent(this.webviewId, this.data);
}

class _JSCallResponse {
  final int callId;
  final int error;
  final String? message;
  final dynamic data;

  _JSCallResponse(this.callId, this.error, this.message, this.data);
}

class _JSCallback {
  final String name;
  final dynamic data;

  _JSCallback(this.name, this.data);
}

/// An implementation of [FlutterWebkitPlatform] that uses method channels.
class MethodChannelFlutterWebkit extends FlutterWebkitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_webkit');
  final _loadEventStream =
      StreamController<_WebViewEvent<LoadEvent>>.broadcast();
  final _jsCallResponseStream =
      StreamController<_WebViewEvent<_JSCallResponse>>.broadcast();
  final _uriEventStream = StreamController<_WebViewEvent<String?>>.broadcast();
  final _titleEventStream =
      StreamController<_WebViewEvent<String?>>.broadcast();
  final _javascriptCallbackStream =
      StreamController<_WebViewEvent<_JSCallback>>.broadcast();

  MethodChannelFlutterWebkit() {
    methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case "on_load_changed":
          final webview = call.arguments["webview"] as int;
          final e = call.arguments["event"] as int;

          _loadEventStream
              .add(_WebViewEvent<LoadEvent>(webview, LoadEvent.values[e]));
          break;
        case "on_evaluate_javascript_completed":
          final webview = call.arguments["webview"] as int;
          final id = call.arguments["id"] as int;
          final error = call.arguments["error"] as int;
          final msg = call.arguments["message"] as String?;
          final data = call.arguments["data"] as String?;

          _jsCallResponseStream.add(_WebViewEvent(
            webview,
            _JSCallResponse(id, error, msg,
                data == null || data.isEmpty ? null : jsonDecode(data)),
          ));
          break;
        case "on_uri_changed":
          final webview = call.arguments["webview"] as int;
          final uri = call.arguments["uri"] as String?;
          _uriEventStream.add(_WebViewEvent(webview, uri));
          break;
        case "on_title_changed":
          final webview = call.arguments["webview"] as int;
          final title = call.arguments["title"] as String?;
          _titleEventStream.add(_WebViewEvent(webview, title));
          break;
        case "on_javascript_callback":
          final webview = call.arguments["webview"] as int;
          final name = call.arguments["name"] as String;
          final data = call.arguments["data"] as String?;
          _javascriptCallbackStream.add(_WebViewEvent(
            webview,
            _JSCallback(
                name, data == null || data.isEmpty ? null : jsonDecode(data)),
          ));
          break;
      }

      return null;
    });
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<int?> createWebView(Map<dynamic, dynamic> args) {
    return methodChannel.invokeMethod<int>('create_webview', args);
  }

  @override
  Future<void> destroyWebView(int webviewId) {
    return methodChannel
        .invokeMethod<void>('destroy_webview', {"webview": webviewId});
  }

  @override
  Future<void> open(int webviewId, String uri) {
    return methodChannel
        .invokeMethod<void>('open', {"webview": webviewId, "uri": uri});
  }

  @override
  Future<void> setDimension(int webviewId, Rect rect) {
    return methodChannel.invokeMethod<void>('set_dimension', {
      "webview": webviewId,
      "x": rect.topLeft.dx.toInt(),
      "y": rect.topLeft.dy.toInt(),
      "w": rect.width.toInt(),
      "h": rect.height.toInt()
    });
  }

  @override
  Stream<LoadEvent> getLoadEvents(int webviewId) {
    return _loadEventStream.stream
        .where((event) => event.webviewId == webviewId)
        .map((event) => event.data);
  }

  @override
  Stream<String?> getUriEvents(int webviewId) {
    return _uriEventStream.stream
        .where((event) => event.webviewId == webviewId)
        .map((event) => event.data);
  }

  @override
  Stream<String?> getTitleEvents(int webviewId) {
    return _titleEventStream.stream
        .where((event) => event.webviewId == webviewId)
        .map((event) => event.data);
  }

  @override
  Future<dynamic> evaluateJavascript(
      int webviewId, int callId, String script) async {
    final completion = _jsCallResponseStream.stream.firstWhere((element) =>
        element.webviewId == webviewId && element.data.callId == callId);

    await methodChannel.invokeMethod<void>("evaluate_javascript", {
      "webview": webviewId,
      "id": callId,
      "script": script,
    });

    final result = await completion;
    if (result.data.error != 0) {
      throw WebViewError(
          "Failed to evaluate javascript (error ${result.data.error}): ${result.data.message}");
    }

    return result.data.data;
  }

  @override
  Future<void> reload(int webviewId, bool bypassCache) {
    return methodChannel.invokeMethod<void>("reload", {
      "webview": webviewId,
      "bypass_cache": bypassCache,
    });
  }

  @override
  Future<bool> registerJavascriptCallback(int webviewId, String name) async {
    final v =
        await methodChannel.invokeMethod<bool>("register_javascript_callback", {
      "webview": webviewId,
      "name": name,
    });
    return v ?? false;
  }

  @override
  Future<void> unregisterJavascriptCallback(int webviewId, String name) {
    return methodChannel.invokeMethod<void>("unregister_javascript_callback", {
      "webview": webviewId,
      "name": name,
    });
  }

  @override
  Stream<dynamic> getJavascriptCallbackStream(int webviewId, String name) {
    return _javascriptCallbackStream.stream
        .where(
            (event) => event.webviewId == webviewId && event.data.name == name)
        .map((event) => event.data.data);
  }

  @override
  Future<void> openInspector(int webviewId) {
    return methodChannel
        .invokeMethod<void>("open_inspector", {"webview": webviewId});
  }
}
