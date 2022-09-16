import 'dart:ffi';

import 'package:dart_sunvox/src/libsunvox_generated_bindings.dart';
import 'package:ffi/ffi.dart';

class LibSunvox {
  String libPath;
  late int version;

  libsunvox get _sunvox => libsunvox(DynamicLibrary.open(libPath));

  LibSunvox([this.libPath = 'sunvox_lib/linux/lib_x86_64/sunvox.so']) {
    version = _init();
    if (version >= 0) {
      _sunvox.sv_open_slot(0);
      // The SunVox is initialized.
      // Slot 0 is open and ready for use.
      // Then you can load and play some files in this slot.
    } else {
      throw Exception("failed to initialise libsunvox");
    }
  }

  String versionString() {
    final version = _init();

    final major = (version >> 16) & 255;
    final minor1 = (version >> 8) & 255;
    final minor2 = (version) & 255;

    return '$major.$minor1.$minor2';
  }

  int _init() {
    final config = calloc<Int8>();
    return _sunvox.sv_init(config, 44100, 2, 0);
  }

  void shutDown() {
    _sunvox.sv_close_slot(0);
    _sunvox.sv_deinit();
  }
}
