import 'dart:async';

import 'package:web_http/web_http.dart';

/// A signature for callback which is invoked whenever the [TestHttpClient]
/// recieves a request.
typedef FutureOr<TestHttpResponse> TestClientCallback(String url, String method,
    {String responseType,
    String body,
    Map<String, String> headers,
    int timeout,
    bool withCredentials});

/// A testing implementation of [HttpClient].
///
/// The exact responses returned can be controlled with the provided
/// [callback].
class TestHttpClient implements HttpClient {
  final TestClientCallback callback;

  /// Creates a new [TestHttpClient].
  TestHttpClient(this.callback) {
    _throwOnProductionMode();
  }

  @override
  Stream<String> get(String url,
      {Map<String, String> headers, int timeout, bool withCredentials}) {
    return request(url, 'GET',
            headers: headers,
            timeout: timeout,
            withCredentials: withCredentials)
        .map((HttpResponse response) => response.body as String);
  }

  @override
  Stream<String> post(String url, String body,
      {Map<String, String> headers, int timeout, bool withCredentials}) {
    return request(url, 'POST',
            body: body,
            headers: headers,
            timeout: timeout,
            withCredentials: withCredentials)
        .map((HttpResponse response) => response.body as String);
  }

  @override
  Stream<HttpResponse> request(String url, String method,
      {String responseType,
      String body,
      Map<String, String> headers,
      int timeout,
      bool withCredentials}) {
    StreamController controller;
    controller = new StreamController(
        sync: true,
        onListen: () {
          final FutureOr<TestHttpResponse> response = callback(
            url,
            method,
            headers: headers,
            timeout: timeout,
            withCredentials: withCredentials,
          );
          new Future.value(response).then((TestHttpResponse response) {
            if (response.statusCode >= 200 && response.statusCode < 300) {
              controller.add(response);
              controller.close();
            } else {
              controller.addError(
                  new HttpException('test exception', response.statusCode));
              controller.close();
            }
          });
        });
    return controller.stream;
  }
}

/// An implementation of [HttpResponse] for testing purposes.
class TestHttpResponse implements HttpResponse {
  /// Creates a [TestHttpResponse] with a 400 status code and empty body.
  TestHttpResponse.failure()
      : _body = '',
        headers = const {},
        statusCode = 400 {
    _throwOnProductionMode();
  }

  /// Creates a [TestHttpResponse].
  TestHttpResponse(this._body,
      {Map<String, String> headers, this.statusCode = 200})
      : this.headers = headers ?? const {} {
    _throwOnProductionMode();
  }

  String _body;

  @override
  dynamic get body => _body;

  @override
  final Map<String, String> headers;

  /// The status code of the HTTP response.
  ///
  /// Non 2XX status code will cause the [TestHttpClient] to return an
  /// [HttpException].
  final int statusCode;
}

/// Helper function which throws an [UnsupportedError] if the [TestHttpClient] or
/// [TestHttpResponse] classes are created in production mode.
void _throwOnProductionMode() {
  bool inProductionMode = true;
  assert(inProductionMode = false);
  if (inProductionMode)
    throw new UnsupportedError(
        'Cannot use TestHttpClient or TestHttpResponse in production mode');
}
