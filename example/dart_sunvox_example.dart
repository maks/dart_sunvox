import 'package:dart_sunvox/dart_sunvox.dart';

void main(List<String> args) async {
  final sunvox = LibSunvox(0);
  final v = sunvox.versionString();
  print('sunvox lib version: $v');

  const filename = "sunvox_lib/resources/song01.sunvox";
  await sunvox.load(filename);
  // or as data using Dart's file ops
  // final data = File(filename).readAsBytesSync();

  sunvox.volume = 256;

  sunvox.play();
  print("playing:$filename ...");

  await Future<void>.delayed(Duration(seconds: 5));

  sunvox.stop();

  sunvox.shutDown();
}
