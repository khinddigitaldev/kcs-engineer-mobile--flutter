import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class AppWebview extends StatefulWidget {
  final String url;
  const AppWebview({Key? key, required this.url}) : super(key: key);

  @override
  _AppWebviewState createState() => _AppWebviewState();
}

class _AppWebviewState extends State<AppWebview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                child: InAppWebView(
                  androidOnPermissionRequest: (controller, origin, resources) async {
                    return PermissionRequestResponse(
                      resources: resources,
                      action: PermissionRequestResponseAction.GRANT,
                    );
                  },
                  initialUrlRequest: URLRequest(
                    url: Uri.parse(widget.url),
                  ),
                  initialOptions: InAppWebViewGroupOptions(
                    crossPlatform: InAppWebViewOptions(
                      useShouldOverrideUrlLoading: false,
                      mediaPlaybackRequiresUserGesture: false,
                      useOnDownloadStart: true,
                    ),
                    android: AndroidInAppWebViewOptions(
                      hardwareAcceleration: true,
                    ),
                    ios: IOSInAppWebViewOptions(
                      allowsInlineMediaPlayback: true,
                    ),
                  ),
                  onConsoleMessage: (controller, consoleMessage) {
                    // print(consoleMessage);
                  },
                  onLoadStop: (controller, url) async {
                    print('current url is $url');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
