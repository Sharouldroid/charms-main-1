import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Base64ImageViewer extends StatefulWidget {
  final String base64String;
  final double height;
  final double width;
  final BoxFit fit;

  const Base64ImageViewer({
    Key? key,
    required this.base64String,
    this.height = 100,
    this.width = 100,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  _Base64ImageViewerState createState() => _Base64ImageViewerState();
}

class _Base64ImageViewerState extends State<Base64ImageViewer> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(_buildHtmlContent());
  }

  String _buildHtmlContent() {
    // Determine the image format based on the first few characters
    String mimeType = 'image/jpeg';
    String base64 = widget.base64String;
    
    // Clean up the base64 string if needed
    if (base64.contains(',')) {
      base64 = base64.split(',').last;
    }
    
    // Create HTML that displays the image with proper styling
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body {
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            background-color: transparent;
          }
          img {
            max-width: 100%;
            max-height: 100%;
            object-fit: ${widget.fit == BoxFit.cover ? 'cover' : 'contain'};
          }
        </style>
      </head>
      <body>
        <img src="data:$mimeType;base64,$base64" alt="Image" />
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: Colors.grey[200],
      ),
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
