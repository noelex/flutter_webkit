import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'gtk_view.dart';

/// A web view widget for showing html content.
class WebView2 extends StatefulWidget {
  /// Creates a new web view.
  ///
  /// The web view can be controlled using a `WebViewController` that is passed to the
  /// `onWebViewCreated` callback once the web view is created.
  ///
  /// The `javascriptMode` and `autoMediaPlaybackPolicy` parameters must not be null.
  const WebView2({
    super.key,
    required this.uri,
  });

  final String uri;

  @override
  State<StatefulWidget> createState() => _WebViewState();
}

class _WebViewState extends State<WebView2> {
  @override
  Widget build(BuildContext context) {
    return GtkView(
      viewType: 'plugins.flutter.io/webview',
      creationParams:
          creationParamsToMap(_creationParamsFromWidget(widget)),
      creationParamsCodec: const StandardMessageCodec(),
    );
  }

  static Map<String, dynamic> creationParamsToMap(
      CreationParams creationParams) {
    return <String, dynamic>{
      'uri': creationParams.uri,
    };
  }
}

class CreationParams {
  CreationParams({
    required this.uri,
  });

  final String uri;

  @override
  String toString() {
    return '$runtimeType(uri: $uri)';
  }
}

CreationParams _creationParamsFromWidget(WebView2 widget) {
  return CreationParams(
    uri: widget.uri,
  );
}