import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for DefaultApi
void main() {
  final instance = Openapi().getDefaultApi();

  group(DefaultApi, () {
    // Health Check
    //
    //Future<BuiltMap<String, String>> healthCheckHealthGet() async
    test('test healthCheckHealthGet', () async {
      // TODO
    });

    // Read Root
    //
    //Future<BuiltMap<String, String>> readRootGet() async
    test('test readRootGet', () async {
      // TODO
    });

  });
}
