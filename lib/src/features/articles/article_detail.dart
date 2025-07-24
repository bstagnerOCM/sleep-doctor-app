import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sleep_doctor/main.dart';
import 'package:provider/provider.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String? link;
  final String? domain;
  const ArticleDetailScreen({super.key, this.link, this.domain});

  bool isDarkMode(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return themeProvider.themeMode == ThemeMode.dark;
  }

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreen();
}

class _ArticleDetailScreen extends State<ArticleDetailScreen> {
  late WebViewController _controller;
  String? didLoad = 'false';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.link!
          .replaceAll('tsdv2.local', 'sleepdoctor.com')
          .replaceAll('sleepfoundationv2.local', 'sleepfoundation.org')))
      ..addJavaScriptChannel("myChannel",
          onMessageReceived: (JavaScriptMessage message) {
        setdidLoad(message.message);
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (widget.isDarkMode(context)) {
              _injectJavascriptDark(_controller);
            } else {
              _injectJavascriptLight(_controller);
            }
          },
        ),
      );

    super.initState();
  }

  setdidLoad(String javascriptdidLoad) {
    if (mounted) {
      setState(() {
        didLoad = 'true';
      });
    }
  }

  _injectJavascriptLight(WebViewController controller) async {
    controller.runJavaScript('''
      const header = document.querySelector("header#site_header");
      const footer = document.querySelector("footer");
      const theBreadcrumb = document.querySelector(".breadcrumbs");
      const postBottomArticle = document.querySelector(".post-bottom-article");
      if (header) {
        header.style.setProperty('display', 'none', 'important');
      }
      if (footer) {
        footer.style.setProperty('display', 'none', 'important');
      }
      if (theBreadcrumb) {
        theBreadcrumb.style.setProperty('display', 'none', 'important');
      }
      if (postBottomArticle) {
        postBottomArticle.style.setProperty('display', 'none', 'important');
      }
      myChannel.postMessage('true');
    ''');
  }

  _injectJavascriptDark(WebViewController controller) async {
    controller.runJavaScript('''
      const header = document.querySelector("header#site_header");
      const footer = document.querySelector("footer");
      const theBreadcrumb = document.querySelector(".breadcrumbs");
      const postBottomArticle = document.querySelector(".post-bottom-article");
      const sheet = document.styleSheets[0];
      sheet.insertRule(":root{--color-body-bg: #2e3038 !important;}");
      sheet.insertRule(":root{--color-primary-dark: #f1f1f1 !important;}");
      sheet.insertRule(":root{--color-primary: #f1f1f1 !important;}");
      sheet.insertRule(":root{--color-gray-dark: #f1f1f1 !important;}");
      sheet.insertRule(":root{--color-neutral-light: #2e3038 !important;}");
      sheet.insertRule(":root{--color-headings-text: #f1f1f1  !important;}");
      sheet.insertRule(":root{--color-neutral-dark: #f1f1f1 !important;}");
      sheet.insertRule(":root{--color-gray-medium: #f1f1f1 !important;}");
      sheet.insertRule(":root{--color-body-text: #f1f1f1 !important;}");
      sheet.insertRule(":root{--color-secondary-light: #585858 !important;}");
      sheet.insertRule(":root{--color-links: #65DEB1 !important;}");

      if (header) {
        header.style.setProperty('display', 'none', 'important');
      }
      if (footer) {
        footer.style.setProperty('display', 'none', 'important');
      }
      if (theBreadcrumb) {
        theBreadcrumb.style.setProperty('display', 'none', 'important');
      }
      if (postBottomArticle) {
        postBottomArticle.style.setProperty('display', 'none', 'important');
      }
      myChannel.postMessage('true');
    ''');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(themeProvider.sdLogoAsset, height: 40),
          ],
        ),
      ),
      body: didLoad == 'false'
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 100),
              child: WebViewWidget(controller: _controller),
            ),
    );
  }
}
