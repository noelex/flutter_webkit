import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webkit/flutter_webkit_platform_interface.dart';
import 'package:flutter_webkit/flutter_webkit_method_channel.dart';
import 'package:flutter_webkit/src/flutter_webkit.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterWebkitPlatform
    with MockPlatformInterfaceMixin
    implements FlutterWebkitPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<int> createWebView() {
    throw UnimplementedError();
  }

  @override
  Future<void> destroyWebView(int webviewId) {
    throw UnimplementedError();
  }
  
  @override
  Future<void> open(int webviewId, String uri) {
    throw UnimplementedError();
  }
  
  @override
  Future<void> setDimension(int webviewId, Rect rect) {
    throw UnimplementedError();
  }
}

void main() {
  final FlutterWebkitPlatform initialPlatform = FlutterWebkitPlatform.instance;

  test('$MethodChannelFlutterWebkit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterWebkit>());
  });

  test('getPlatformVersion', () async {
    FlutterWebkit flutterWebkitPlugin = FlutterWebkit();
    MockFlutterWebkitPlatform fakePlatform = MockFlutterWebkitPlatform();
    FlutterWebkitPlatform.instance = fakePlatform;

    expect(await flutterWebkitPlugin.getPlatformVersion(), '42');
  });
}
