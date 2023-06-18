import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_webkit/src/flutter_webkit.dart';
import 'package:flutter_webkit/src/types.dart';

class WebView extends StatelessWidget {
  final WebViewController controller;
  const WebView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
          final renderObject = context.findRenderObject();
          if (renderObject != null) {
            final matrix = renderObject.getTransformTo(null);
            final rect =
                MatrixUtils.transformRect(matrix, renderObject.paintBounds);
            controller._update(rect);
          }
        });
        return Container(constraints: const BoxConstraints.expand(), color: const Color(0x00000000),);
      },
    );
  }
}

class WebViewController {
  final _plugin = FlutterWebkit();
  int _handle = 0;
  final _readyCompleter = Completer<void>();
  late final _loadEvents = StreamController<LoadEvent>.broadcast();
  late final _uriEvents = StreamController<String?>.broadcast();
  late final _titleEvents = StreamController<String?>.broadcast();

  int _jsCallId = 0;

  WebViewController({String? uri}) {
    _plugin.createWebView().then((value) {
      _handle = value!;

      _loadEvents.addStream(_plugin.getLoadEvents(_handle));
      _uriEvents.addStream(_plugin.getUriEvents(_handle));
      _titleEvents.addStream(_plugin.getTitleEvents(_handle));

      _readyCompleter.complete();
      if (uri != null) {
        open(uri);
      }
    });
  }

  Future<void> get ready {
    return _readyCompleter.future;
  }

  Stream<String?> get uriStream {
    return _uriEvents.stream;
  }

  Stream<String?> get titleStream {
    return _titleEvents.stream;
  }

  Stream<LoadEvent> get loadingStatusStream {
    return _loadEvents.stream;
  }

  void open(String uri) async {
    await ready;
    _plugin.open(_handle, uri);
  }

  Future<dynamic> evaluateJavascript(String script) async {
    await ready;
    return _plugin.evaluateJavascript(_handle, _jsCallId++, script);
  }

  Future<void> reload({bool bypassCache = false}) async{
    await ready;
    return _plugin.reload(_handle, bypassCache);
  }

  void _update(Rect rect) async {
    await ready;
    _plugin.setDimension(_handle, rect);
  }

  void dispose() async {
    await ready;
    _plugin.destroyWebView(_handle);
  }
}
