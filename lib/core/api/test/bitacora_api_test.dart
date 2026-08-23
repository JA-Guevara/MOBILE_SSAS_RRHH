import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for BitacoraApi
void main() {
  final instance = Openapi().getBitacoraApi();

  group(BitacoraApi, () {
    // Bitacora Health
    //
    //Future<BuiltMap<String, String>> bitacoraHealthBitacoraHealthGet() async
    test('test bitacoraHealthBitacoraHealthGet', () async {
      // TODO
    });

  });
}
