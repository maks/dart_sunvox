import 'package:dart_sunvox/dart_sunvox.dart';

void main(List<String> args) {
  final v = LibSunvox().version();
  print('sunvox lib version: $v');
}
