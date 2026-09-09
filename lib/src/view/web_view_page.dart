import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../foundation/locale_controller.dart';
import '../styles/story_colors.dart';
import '../widgets/widgets.dart';

/// 应用内 WebView 页，用于展示服务条款 / 隐私政策等公开页。
class WebViewPage extends StatefulWidget {
  final String title;
  final String url;

  const WebViewPage({super.key, required this.title, required this.url});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  var _loading = true;
  var _hasError = false;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.url);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _hasError = false;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _hasError = true;
            });
          },
        ),
      );
    if (uri != null) {
      _controller.loadRequest(uri);
    } else {
      _hasError = true;
      _loading = false;
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    return AppScaffold(
      title: widget.title,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!_hasError) WebViewWidget(controller: _controller),
          if (_hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off_outlined,
                    size: 40,
                    color: StoryColors.mutedForegroundOf(brightness),
                  ),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _reload, child: Text(l10n.commonRetry)),
                ],
              ),
            ),
          if (_loading && !_hasError)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
