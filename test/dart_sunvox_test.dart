import 'package:dart_sunvox/dart_sunvox.dart';
import 'package:test/test.dart';

void main() {
  group('top level lib tests', () {
    final sunvox = LibSunvox(0);

    setUp(() {
      // Additional setup goes here.
    });

    test('sanity check version string', () {
      expect(sunvox.versionString(), isNotNull);
      expect(sunvox.versionString(), "2.0.0");
    });

    test('the expected slot number is used', () {
      expect(sunvox.slotNumber, 0);
    });
  });
}
