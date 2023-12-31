import 'dart:ui';

import 'package:flutter_webkit/src/types.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_webkit_method_channel.dart';

abstract class FlutterWebkitPlatform extends PlatformInterface {
  /// Constructs a FlutterWebkitPlatform.
  FlutterWebkitPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterWebkitPlatform _instance = MethodChannelFlutterWebkit();

  /// The default instance of [FlutterWebkitPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterWebkit].
  static FlutterWebkitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterWebkitPlatform] when
  /// they register themselves.
  static set instance(FlutterWebkitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<LoadEvent> getLoadEvents(int webviewId) {
    throw UnimplementedError('getLoadEvents() has not been implemented.');
  }

  Stream<String?> getUriEvents(int webviewId) {
    throw UnimplementedError('getUriEvents() has not been implemented.');
  }

  Stream<String?> getTitleEvents(int webviewId) {
    throw UnimplementedError('getTitleEvents() has not been implemented.');
  }

  Stream<dynamic> getJavascriptCallbackStream(int webviewId, String name){
    throw UnimplementedError('getJavascriptCallbackStream() has not been implemented.');
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<int?> createWebView(Map<dynamic,dynamic> args) {
    throw UnimplementedError('createWebView() has not been implemented.');
  }

  Future<void> destroyWebView(int webviewId) {
    throw UnimplementedError('destroyWebView() has not been implemented.');
  }

  Future<void> open(int webviewId, String uri) {
    throw UnimplementedError('open() has not been implemented.');
  }

  Future<void> setDimension(int webviewId, Rect rect) {
    throw UnimplementedError('setDimension() has not been implemented.');
  }

  Future<dynamic> evaluateJavascript(int webviewId, int callId, String script) {
    throw UnimplementedError('evaluateJavascript() has not been implemented.');
  }

  Future<void> reload(int webviewId, bool bypassCache) {
    throw UnimplementedError('reload() has not been implemented.');
  }

  Future<bool> registerJavascriptCallback(int webviewId, String name) {
    throw UnimplementedError('register_javascript_callback() has not been implemented.');
  }

  Future<void> unregisterJavascriptCallback(int webviewId, String name) {
    throw UnimplementedError('unregister_javascript_callback() has not been implemented.');
  }

  Future<void> openInspector(int webviewId) {
    throw UnimplementedError('openInspector() has not been implemented.');
  }
}
