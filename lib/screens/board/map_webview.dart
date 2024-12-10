import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapWebView extends StatelessWidget {
  final String address;

  const MapWebView({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    final encodedAddress = Uri.encodeComponent(address);
    final mapUrl = 'https://map.naver.com/v5/search/$encodedAddress';

    return Scaffold(
      appBar: AppBar(
        title: const Text('지도 보기'),
      ),
      body: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(mapUrl)),
      ),
    );
  }
}
