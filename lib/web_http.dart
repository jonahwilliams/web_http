import 'dart:async';
import 'dart:html';

/// A web HTTP client focused on speed and correctness.
///
/// This client is based around streams to allow cancelation of requests. The
/// request is sent when the stream is listened to, and canceled if the
/// subscription is canceled before a response is recieved.
/// 
/// The stream is always single subscription and will return 0 or 1 responses.
/// 
/// If the HTTP request completes with a non 2xx response code or times out,
/// then an [HttpException] is emitted in the returned stream's error channel.
/// 
/// Example use:
/// 
///     @Component(selector: 'my-component', ...)
///     class MyComponent implements OnInit {
///       final HttpClient _client;
///       StreamSubscription _onResponse;
///       String data = '';
/// 
///       MyComponent(this._client);
/// 
///       @override
///       void ngOnInit() {
///         _onResponse = _client
///          .get('/my-api')
///          .listen((response) => data = response);
///       }
/// 
///       @override
///       void ngOnDestroy() {
///         _onResponse?.cancel();
///       }
///     }
/// 
/// See also:
///   * [HttpTestClient](), for an example of testing.
class HttpClient {
  /// Creates a new [HttpClient].
  const HttpClient();

  /// A convience wrapper around [request] which sends a GET request.
  ///
  /// See also:
  ///
  ///  * [request], for a description of the method parameters.
  Stream<String> get(
    String url, {
    Map<String, String> headers,
    int timeout,
    bool withCredentials,
  }) {
    return request(url, 'GET', headers: headers, timeout: timeout)
        .map((HttpResponse response) => response.body as String);
  }

  /// A convience wrapper around [request] which sends a POST request.
  ///
  /// See also:
  ///
  ///  * [request], for a description of the method parameters.
  Stream<String> post(
    String url,
    String body, {
    Map<String, String> headers,
    int timeout,
    bool withCredentials,
  }) {
    return request(url, 'POST', headers: headers, timeout: timeout)
        .map((HttpResponse response) => response.body as String);
  }

  /// Sends an HTTP request to a specified domain.
  ///
  ///  * [url] is the string encoded url.
  ///  * [method] is an http verb such as 'GET' or 'POST'.
  ///  * [responseType] is the expected server response type. Valid values are
  ///    'arraybuffer', 'blob',  'document', 'json', or 'text'. Defaults to
  ///    'text' if not set.
  ///  * [body] is the (optional) request body.
  ///  * [headers] are the (optional) request headers.
  ///  * [timeout] is an (optional) time limit in milliseconds before aborting
  ///    the request automatically.
  ///  * [withCredentials] whether cross-site requests should use cookie or
  ///    header credentials.
  /// 
  /// See also:
  /// 
  ///  * [HttpRequest.responseType], for more information on the return type
  ///    for each [responseType].
  Stream<HttpResponse> request(
    String url,
    String method, {
    String responseType,
    String body,
    Map<String, String> headers,
    int timeout,
    bool withCredentials,
  }) {
    final request = new HttpRequest();
    final controller = new StreamController<HttpResponse>(
      sync: true,
      onCancel: request.abort,
      onListen: () {
        request.send(body);
      },
    );
    request.open(method, url);
    if (responseType != null) {
      request.responseType = responseType;
    }
    if (headers != null) {
      headers.forEach(request.setRequestHeader);
    }
    if (timeout != null) {
      request.timeout = timeout;
    }
    if (withCredentials != null) {
      request.withCredentials = withCredentials;
    }
    request.onError.listen((ProgressEvent event) {
      if (controller.isClosed) return;
      final exception = new HttpException(
        request.statusText,
        request.status,
      );
      controller.addError(exception);
      controller.close();
    });
    request.onLoadEnd.listen((ProgressEvent event) {
      if (controller.isClosed) return;
      if (request.status >= 200 && request.status < 300) {
        final response =
            new HttpResponse._(request.response, request.responseHeaders);
        controller.add(response);
        controller.close();
      } else {
        final exception = new HttpException(
          request.statusText,
          request.status,
        );
        controller.addError(exception);
        controller.close();
      }
    });
    if (timeout != null) {
      request.onTimeout.listen((ProgressEvent event) {
        if (controller.isClosed) return;
        final exception = new HttpException(
          request.statusText,
          request.status,
        );
        controller.addError(exception);
        controller.close();
      });
    }
    return controller.stream;
  }
}

/// An exception thrown when an HTTP request returns a non 200 status.
class HttpException implements Exception {
  const HttpException(this.statusText, this.statusCode);

  /// The status code from the HTTP request.
  final int statusCode;

  /// The status text from the HTTP request.
  final String statusText;

  @override
  String toString() => '$statusCode: $statusText';
}

/// An HTTP response containing the text response body and headers.
class HttpResponse {
  const HttpResponse._(this.body, this.headers);

  /// The body of the response.
  ///
  /// Depending on the respond type requested, might be a [String], [Document],
  /// or a [ByteBuffer].
  final dynamic body;

  /// response headers.
  final Map<String, String> headers;
}
