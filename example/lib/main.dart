import 'package:flutter/material.dart';
import 'package:flutter_webkit/webview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController(
      uri: "https://threejs.org",
      settings: WebViewSettings(
        enableDeveloperExtras: true,
      )
    );

    _controller.loadingStatusStream.listen((event) {
      debugPrint("Load state changed to '$event'.");
    });

    _controller.loadingStatusStream
        .where((element) => element == LoadEvent.finished)
        .listen((value) async {
      final val = await _controller.evaluateJavascript(
          "window.webkit.messageHandlers.onLoadComplete.postMessage({msg:'Hello from javascript.'});"
          "let e = document.querySelector('#header > h1 > span, a');"
          "if(e!=null) e.innerHTML = 'Hello! three.js';");
      debugPrint("js result: $val");
    });

    _controller.registerJavascriptCallback(
        "onLoadComplete", (data) => debugPrint("onLoadComplete: $data"));    
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: StreamBuilder(
            builder: (context, snapshot) => Text(snapshot.data ?? ""),
            stream: _controller.titleStream,
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reload',
              onPressed: () {
                _controller.reload();
              },
            ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Inspect',
              onPressed: () {
                _controller.openInspector();
              },
            )
          ],
        ),
        body: Center(
          child: WebView(controller: _controller),
        ),
      ),
    );
  }
}
