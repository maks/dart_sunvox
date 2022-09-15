import 'package:dart_sunvox/dart_sunvox.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final sunvox = LibSunvox();

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(sunvox.version(), isNotNull);
    });
  });
}
