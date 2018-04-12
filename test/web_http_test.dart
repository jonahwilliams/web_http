import 'package:test/test.dart';
import 'package:web_http/testing.dart';
import 'package:web_http/web_http.dart';

void main() {
  group(TestHttpClient, () {
    TestHttpClient client;
    bool shouldFail;
    setUp(() {
      shouldFail = false;
      client = new TestHttpClient((String url, String method,
          {String responseType,
          String body,
          Map<String, String> headers,
          int timeout,
          bool withCredentials}) {
        if (shouldFail) {
          return new TestHttpResponse.failure();
        }
        return new TestHttpResponse('hello');
      });
    });

    test('sends successful mock response', () async {
      final response = await client.get('foobar').first;

      expect(response, 'hello');
    });

    test('sends successful mock failure', () async {
      shouldFail = true;
      
      expect(client.get('foobar'), throwsA(const isInstanceOf<HttpException>()));
    });
  });
}
