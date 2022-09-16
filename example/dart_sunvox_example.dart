import 'package:dart_sunvox/dart_sunvox.dart';

void main(List<String> args) {
  final sunvox = LibSunvox();
  final v = sunvox.versionString();
  print('sunvox lib version: $v');
  sunvox.shutDown();
}
