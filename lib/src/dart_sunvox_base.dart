import 'dart:ffi';
import 'dart:typed_data';

import 'package:dart_sunvox/src/libsunvox_generated_bindings.dart';
import 'package:ffi/ffi.dart';

class LibSunvox {
  String libPath;
  late int version;

  libsunvox get _sunvox => libsunvox(DynamicLibrary.open(libPath));

  LibSunvox([this.libPath = 'sunvox_lib/linux/lib_x86_64/sunvox.so']) {
    final configPtr = calloc<Int8>();
    version = _init(configPtr);
    if (version >= 0) {
      _sunvox.sv_open_slot(0);
      // The SunVox is initialized.
      // Slot 0 is open and ready for use.
      // Then you can load and play some files in this slot.
    } else {
      throw Exception("failed to initialise libsunvox");
    }
    calloc.free(configPtr);
  }

  String versionString() {
    final major = (version >> 16) & 255;
    final minor1 = (version >> 8) & 255;
    final minor2 = (version) & 255;

    return '$major.$minor1.$minor2';
  }

  int _init(Pointer<Int8> config) {
    return _sunvox.sv_init(config, 44100, 2, 0);
  }

  /// Load sunvox file
  Future<void> load(String filename) async {
    final namePtr = filename.toNativeUtf8().cast<Int8>();
    final result = _sunvox.sv_load(0, namePtr);
    if (result != 0) {
      throw Exception("cannot load file: $filename error code:$result");
    }
    // don't forget to free the pointer created by toNativeUtf8
    // TODO: use arena allocator
    calloc.free(namePtr);
  }

  /// Load project file as binary data
  Future<void> loadData(Uint8List data) async {   
    final Pointer<Uint8> sData = calloc<Uint8>(data.length); // Allocate a pointer large enough.
    for (int i = 0; i < data.length; i++) {
      sData[i] = data[i];
    }
    final result = _sunvox.sv_load_from_memory(0, sData.cast(), data.length);

    if (result != 0) {
      throw Exception("cannot load data, error code:$result");
    }
  }

  int play() => _sunvox.sv_play_from_beginning(0);

  void stop() => _sunvox.sv_stop(0);

  // volume 0 to 256
  set volume(int v) => _sunvox.sv_volume(0, v);

  int get moduleCount => _sunvox.sv_get_number_of_modules(0);

  void shutDown() {
    _sunvox.sv_close_slot(0);
    _sunvox.sv_deinit();
  }
}
