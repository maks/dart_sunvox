import 'dart:ffi';

import 'package:dart_sunvox/src/libsunvox_generated_bindings.dart';
import 'package:ffi/ffi.dart';

class LibSunvox {
  String libPath;

  LibSunvox([this.libPath = 'sunvox_lib/linux/lib_x86_64/sunvox.so']);

  String version() {
    final sunvox = libsunvox(DynamicLibrary.open(libPath));

    final config = calloc<Int8>();

    final version = sunvox.sv_init(config, 44100, 2, 0);

    final major = (version >> 16) & 255;
    final minor1 = (version >> 8) & 255;
    final minor2 = (version) & 255;

    return '$major.$minor1.$minor2';
  }
}
