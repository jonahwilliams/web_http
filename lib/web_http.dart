import 'dart:async';
import 'dart:html';

/// A web http client focused on speed and correctness.
///
/// Unlike other http clients, this client is based around streams to allow
/// cancelation of extra requests.
class HttpClient {
  /// Creates a new [HttpClient].
  const HttpClient();

  /// A convience wrapper around [request] which sends a GET request.
  ///
  /// See also:
  ///
  ///   * [request], for a description of the method parameters.
  Stream<String> get(
    String url, {
    Map<String, String> headers,
    int timeout,
    bool withCredentials,
  }) {
    return request(url, 'GET', headers: headers, timeout: timeout)
        .map((HttpResponse response) => response.body);
  }

  /// A convience wrapper around [request] which sends a POST request.
  ///
  /// See also:
  ///
  ///   * [request], for a description of the method parameters.
  Stream<String> post(
    String url,
    String body, {
    Map<String, String> headers,
    int timeout,
    bool withCredentials,
  }) {
    return request(url, 'POST', headers: headers, timeout: timeout)
        .map((HttpResponse response) => response.body);
  }

  /// Sends an http request to a specified domain.
  ///
  /// [url] is the String encoded url.
  /// [method] is an http verb such as 'GET' or 'POST'.
  /// [body] is the (optional) request body.
  /// [headers] are the (optional) response headers.
  /// [timeout] is an (optional) time limit in milliseconds before aborting
  /// the request automatically.
  /// [withCredentials] whether cross-site requests should use cookie or
  /// header credentials.
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
      final exception = new HttpException._(
        request.statusText,
        request.status,
      );
      controller.addError(exception);
      controller.close();
    });
    request.onLoadEnd.listen((ProgressEvent event) {
      if (controller.isClosed) return;
      if (request.status == 200) {
        final response =
            new HttpResponse._(request.response, request.responseHeaders);
        controller.add(response);
        controller.close();
      } else {
        final exception = new HttpException._(
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
        final exception = new HttpException._(
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

/// An exception thrown when an http request returns a non 200 status.
class HttpException implements Exception {
  const HttpException._(this.statusText, this.statusCode);

  /// The status code from the http request.
  final int statusCode;

  /// The status text from the http request.
  final String statusText;

  @override
  String toString() => statusText;
}

/// An http response containing the text response body and headers.
class HttpResponse {
  const HttpResponse._(this.body, this.headers);

  /// The body of the response.
  ///
  /// Depending on the respond type requested, might be a String, Document,
  /// or a buffer.
  final dynamic body;

  /// response headers.
  final Map<String, String> headers;
}
