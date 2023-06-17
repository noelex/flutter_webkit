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
    _controller = WebViewController(uri: "https://threejs.org/");
    _controller.load.listen((event) {
      debugPrint("Load state changed to '$event'.");
    });

    _controller.load
        .where((element) => element == LoadEvent.finished)
        .listen((value) async {
      final val = await _controller.evaluateJavascript(
          "let e = document.querySelector('#header > h1 > span, a'); if(e!=null) e.innerHTML = \"Hello! three.js\";");
      debugPrint("js result: $val");
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: WebView(controller: _controller),
        ),
      ),
    );
  }
}
