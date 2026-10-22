import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ThreeDsPage extends StatefulWidget {
  final String url;
  final String callbackUrl;

  const ThreeDsPage({
    super.key,
    required this.url,
    required this.callbackUrl,
  });

  @override
  State<ThreeDsPage> createState() => _ThreeDsPageState();
}

class _ThreeDsPageState extends State<ThreeDsPage> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(NavigationDelegate(
      onNavigationRequest: (request) {
        if (_isCallback(request.url)) {
          Navigator.of(context).pop(true);
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
    ))
    ..loadRequest(Uri.parse(widget.url));

  bool _isCallback(String value) {
    final url = Uri.tryParse(value);
    final callback = Uri.tryParse(widget.callbackUrl);
    return url != null &&
        callback != null &&
        url.scheme == callback.scheme &&
        url.host == callback.host &&
        url.path == callback.path;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Secure payment')),
        body: WebViewWidget(controller: _controller),
      );
}
