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

/// An implementation of [FlutterWebkitPlatform] that uses method channels.
class MethodChannelFlutterWebkit extends FlutterWebkitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_webkit');
  final _loadEventStream =
      StreamController<_WebViewEvent<LoadEvent>>.broadcast();
  final _jsCallResponseStream =
      StreamController<_WebViewEvent<_JSCallResponse>>.broadcast();

  MethodChannelFlutterWebkit() {
    methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case "on_load_changed":
          final webview = call.arguments["webview"] as int;
          final e = call.arguments["event"] as int;

          _loadEventStream.add(_WebViewEvent<LoadEvent>(webview, LoadEvent.values[e]));
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
                  data == null || data.isEmpty ? null : jsonDecode(data))));
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
  Future<int?> createWebView() {
    return methodChannel.invokeMethod<int>('create_webview');
  }

  @override
  Future<void> destroyWebView(int webviewId) {
    return methodChannel
        .invokeMethod<void>('destroy_webview', {"id": webviewId});
  }

  @override
  Future<void> open(int webviewId, String uri) {
    return methodChannel
        .invokeMethod<void>('open', {"id": webviewId, "uri": uri});
  }

  @override
  Future<void> setDimension(int webviewId, Rect rect) {
    return methodChannel.invokeMethod<void>('set_dimension', {
      "id": webviewId,
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
  Future<dynamic> evaluateJavascript(int webviewId, String script) async {
    final id = await methodChannel.invokeMethod<int>(
        "evaluate_javascript", {"id": webviewId, "script": script});
    final result = await _jsCallResponseStream.stream.firstWhere((element) =>
        element.webviewId == webviewId && element.data.callId == id);
    if (result.data.error != 0) {
      throw WebViewError(
          "Failed to evaluate javascript (error ${result.data.error}): ${result.data.message}");
    }
    return result.data.data;
  }
}
