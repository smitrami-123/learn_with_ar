import 'dart:async' show Completer;
import 'dart:convert' show utf8;
import 'dart:io'
    show File, HttpRequest, HttpServer, HttpStatus, InternetAddress, Platform;
import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_android/android_content.dart' as android_content;
import 'package:webview_flutter/platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'controller.dart';
import 'html_builder.dart';
class ModelViewer extends StatefulWidget {
  ModelViewer(
      {Key key,
        this.backgroundColor = Colors.white,
        @required this.src,
        this.alt,
        this.ar,
        this.arModes,
        this.arScale,
        this.autoRotate,
        this.autoRotateDelay,
        this.autoPlay,
        this.cameraControls,
        this.enableColorChange,
        this.colorController,
        this.iosSrc,
        this.onModelViewCreated,
        this.onModelViewError,
        this.onModelViewFinished,
        this.onModelIsVisisble,
        this.onModelViewStarted})
      : super(key: key);

  final Color backgroundColor;
  final String src;
  final String alt;
  final bool ar;
  final List<String> arModes;
  final String arScale;
  final bool enableColorChange;
  ModelViewerColorController colorController;
  final bool autoRotate;
  final int autoRotateDelay;
  final bool autoPlay;
  final bool cameraControls;
  final String iosSrc;

  /// Invoked once when the model viewer is created.
  final VoidCallback onModelViewCreated;

  /// Invoked when the model viewer has finished loading the url.
  final VoidCallback onModelViewStarted;

  /// Invoked when the model viewer has finished loading the url.
  ///
  /// Please note: This function is invoked when the url has finished loading,
  /// but it doesn't represents the finished loading process of the model visibility.
  final VoidCallback onModelViewFinished;

  /// Invoked when the model viewer has loaded the model and the model is visibile.
  /// See: https://modelviewer.dev/docs/#entrydocs-loading-events-modelVisibility
  final VoidCallback onModelIsVisisble;

  /// Invoked when the model viewer has failed to load the resource.
  final ValueChanged<String> onModelViewError;

  @override
  State<ModelViewer> createState() => _ModelViewerState();
}

class _ModelViewerState extends State<ModelViewer> {
  final Completer<WebViewController> _controller =
  Completer<WebViewController>();

  HttpServer _proxy;

  @override
  void initState() {
    super.initState();
    var _colorController = widget.colorController;
    if (_colorController != null) {
      _colorController.changeColor = _changeColor;
    }
    _initProxy();
  }

  @override
  void dispose() {
    super.dispose();
    if (_proxy != null) {
      _proxy.close(force: true);
      _proxy = null;
    }
  }

  @override
  void didUpdateWidget(final ModelViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // TODO
  }

  @override
  Widget build(final BuildContext context) {
    return WebView(
      initialUrl: null,
      javascriptMode: JavascriptMode.unrestricted,
      javascriptChannels: Set.from({
        JavascriptChannel(
            name: 'messageIsVisibile',
            onMessageReceived: (JavascriptMessage message) {
              if (widget.onModelIsVisisble != null) {
                if (message.message == 'true') {
                  widget.onModelIsVisisble();
                }
              }
            }),
      }),
      initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
      onWebViewCreated: (final WebViewController webViewController) async {
        _controller.complete(webViewController);
        final host = _proxy.address.address;
        final port = _proxy.port;
        final url = "http://$host:$port/";
        print('>>>> ModelViewer initializing... <$url>'); // DEBUG
        await webViewController.loadUrl(url).then((value) {
          if (widget.onModelViewCreated != null) {
            widget.onModelViewCreated();
          }
        });
      },
      navigationDelegate: (final NavigationRequest navigation) async {
        //print('>>>> ModelViewer wants to load: <${navigation.url}>'); // DEBUG
        if (!Platform.isAndroid) {
          return NavigationDecision.navigate;
        }
        if (!navigation.url.startsWith("intent://")) {
          return NavigationDecision.navigate;
        }
        try {
          // See: https://developers.google.com/ar/develop/java/scene-viewer
          final intent = android_content.Intent(
            action: "android.intent.action.VIEW", // Intent.ACTION_VIEW
            data: Uri.parse("https://arvr.google.com/scene-viewer/1.0").replace(
              queryParameters: <String, dynamic>{
                'file': widget.src,
                'mode': 'ar_only',
              },
            ),
            package: "com.google.ar.core",
            flags: 0x10000000, // Intent.FLAG_ACTIVITY_NEW_TASK,
          );
          await intent.startActivity();
        } catch (error) {
          print('>>>> ModelViewer failed to launch AR: $error'); // DEBUG
        }
        return NavigationDecision.prevent;
      },
      onPageStarted: (final String url) {
        if (widget.onModelViewStarted != null) {
          widget.onModelViewStarted();
        }
        //print('>>>> ModelViewer began loading: <$url>'); // DEBUG
      },
      onPageFinished: (final String url) {
        if (widget.onModelViewFinished != null) {
          widget.onModelViewFinished();
        }
        //print('>>>> ModelViewer finished loading: <$url>'); // DEBUG
      },
      onWebResourceError: (final WebResourceError error) {
        if (widget.onModelViewError != null) {
          widget.onModelViewError(error.description);
        }

        print(
            '>>>> ModelViewer failed to load: ${error.description} (${error.errorType} ${error.errorCode})'); // DEBUG
      },
    );
  }

  Future<String> _changeColor(String color, int id) async {
    var c = Completer<String>();
    var webviewcontroller = await _controller.future;
    await webviewcontroller
        .evaluateJavascript('changeColor("$color", $id)')
        .then((result) {
      c.complete(result);
    }).catchError((onError) {
      c.completeError(onError.toString());
    });
    return c.future;
  }

  String _buildHTML(final String htmlTemplate) {
    return HTMLBuilder.build(
      htmlTemplate: htmlTemplate,
      backgroundColor: widget.backgroundColor,
      src: '/model',
      alt: widget.alt,
      ar: widget.ar,
      arModes: widget.arModes,
      arScale: widget.arScale,
      autoRotate: widget.autoRotate,
      autoRotateDelay: widget.autoRotateDelay,
      autoPlay: widget.autoPlay,
      cameraControls: widget.cameraControls,
      enableColorChange: widget.enableColorChange,
      iosSrc: widget.iosSrc,
    );
  }

  Future<void> _initProxy() async {
    final url = Uri.parse(widget.src);
    _proxy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _proxy.listen((final HttpRequest request) async {
      //print("${request.method} ${request.uri}"); // DEBUG
      //print(request.headers); // DEBUG
      final response = request.response;

      switch (request.uri.path) {
        case '/':
        case '/index.html':
          final htmlTemplate = await rootBundle
              .loadString('packages/model_viewer/etc/assets/template.html');
          final html = utf8.encode(_buildHTML(htmlTemplate));
          response
            ..statusCode = HttpStatus.ok
            ..headers.add("Content-Type", "text/html;charset=UTF-8")
            ..headers.add("Content-Length", html.length.toString())
            ..add(html);
          await response.close();
          break;

        case '/model-viewer.js':
          final code = await _readAsset(
              'packages/model_viewer/etc/assets/model-viewer.js');
          response
            ..statusCode = HttpStatus.ok
            ..headers
                .add("Content-Type", "application/javascript;charset=UTF-8")
            ..headers.add("Content-Length", code.lengthInBytes.toString())
            ..add(code);
          await response.close();
          break;

        case '/model':
          if (url.isAbsolute && !url.isScheme("file")) {
            await response.redirect(url); // TODO: proxy the resource
          } else {
            final data = await (url.isScheme("file")
                ? _readFile(url.path)
                : _readAsset(url.path));
            response
              ..statusCode = HttpStatus.ok
              ..headers.add("Content-Type", "application/octet-stream")
              ..headers.add("Content-Length", data.lengthInBytes.toString())
              ..headers.add("Access-Control-Allow-Origin", "*")
              ..add(data);
            await response.close();
          }
          break;

        case '/favicon.ico':
        default:
          final text = utf8.encode("Resource '${request.uri}' not found");
          response
            ..statusCode = HttpStatus.notFound
            ..headers.add("Content-Type", "text/plain;charset=UTF-8")
            ..headers.add("Content-Length", text.length.toString())
            ..add(text);
          await response.close();
          break;
      }
    });
  }

  Future<Uint8List> _readAsset(final String key) async {
    final data = await rootBundle.load(key);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<Uint8List> _readFile(final String path) async {
    return await File(path).readAsBytes();
  }
}