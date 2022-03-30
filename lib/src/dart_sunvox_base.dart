import 'dart:ffi';

import 'package:dart_sunvox/src/libsunvox_generated_bindings.dart';
import 'package:ffi/ffi.dart';

class LibSunvox {
  String libPath;

  LibSunvox([this.libPath = '/usr/lib/x86_64-linux-gnu/libgit2.so']);

  String version() {
    final sunvox = libsunvox(DynamicLibrary.open(libPath));

    final majorPtr = calloc<Int32>();
    final minorPtr = calloc<Int32>();
    final revPtr = calloc<Int32>();

    final initFnPtr = sunvox.sv_init;
    initFnPtr.asFunction<tsv_init>();

    if (result != 0) {
      throw Exception('failed gettin libgit2 version');
    } else {
      return '${majorPtr.value}.${minorPtr.value}.${revPtr.value}.';
    }
  }
}
