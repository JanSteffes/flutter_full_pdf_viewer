import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_full_pdf_viewer/models/full_pdf_viewer_pageinfo.dart';

enum PDFViewState { shouldStart, startLoad, finishLoad }

class PDFViewerPlugin {
  final _channel = const MethodChannel("flutter_full_pdf_viewer");
  static PDFViewerPlugin _instance;

  factory PDFViewerPlugin() => _instance ??= new PDFViewerPlugin._();
  PDFViewerPlugin._() {
    _channel.setMethodCallHandler(_handleMessages);
  }

  final _onDestroy = new StreamController<Null>.broadcast();
  final _onPageChange = new StreamController<FullPdfViewerPageInfo>.broadcast();

  Stream<Null> get onDestroy => _onDestroy.stream;
  Stream<FullPdfViewerPageInfo> get onPageChange => _onPageChange.stream;

  Future<Null> _handleMessages(MethodCall call) async {
    switch (call.method) {
      case 'onDestroy':
        if (!_onDestroy.isClosed) {
          _onDestroy.add(null);
        }
        break;
      case 'onPageChange':
        var casted = call.arguments as List<int>;
        var model =
            FullPdfViewerPageInfo(page: casted[0], pageCount: casted[1]);
        _onPageChange.add(model);
    }
  }

  Future<Null> launch(String path, {Rect rect}) async {
    final args = <String, dynamic>{'path': path};
    if (rect != null) {
      args['rect'] = {
        'left': rect.left,
        'top': rect.top,
        'width': rect.width,
        'height': rect.height
      };
    }
    await _channel.invokeMethod('launch', args);
  }

  /// Close the PDFViewer
  /// Will trigger the [onDestroy] event
  Future close() => _channel.invokeMethod('close');

  /// adds the plugin as ActivityResultListener
  /// Only needed and used on Android
  Future registerAcitivityResultListener() =>
      _channel.invokeMethod('registerAcitivityResultListener');

  /// removes the plugin as ActivityResultListener
  /// Only needed and used on Android
  Future removeAcitivityResultListener() =>
      _channel.invokeMethod('removeAcitivityResultListener');

  /// Close all Streams
  void dispose() {
    _onDestroy.close();
    _onPageChange.close();
    _instance = null;
  }

  /// Returns the current page
  Future<dynamic> getPage() => _channel.invokeMethod('getPage');

  /// Returns the current pageCount
  Future<dynamic> getPageCount() => _channel.invokeMethod('getPageCount');

  /// Sets the current page
  Future<dynamic> setPage(int pageNumber) => _channel
      .invokeMethod('setPage', <String, dynamic>{'pageNumber': pageNumber});

  /// resize PDFViewer
  Future<Null> resize(Rect rect) async {
    final args = {};
    args['rect'] = {
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height
    };
    await _channel.invokeMethod('resize', args);
  }
}
