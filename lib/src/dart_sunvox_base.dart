import 'dart:ffi';
import 'dart:typed_data';

import 'package:dart_sunvox/src/libsunvox_generated_bindings.dart';
import 'package:ffi/ffi.dart';

class LibSunvox {
  final String libPath;
  final int slotNumber;
  late final int version;

  libsunvox get _sunvox => libsunvox(DynamicLibrary.open(libPath));

  LibSunvox(this.slotNumber, [this.libPath = 'sunvox_lib/linux/lib_x86_64/sunvox.so']) {
    final configPtr = calloc<Int8>();
    version = _init(configPtr);
    if (version >= 0) {
      _sunvox.sv_open_slot(slotNumber);
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
    final result = _sunvox.sv_load(slotNumber, namePtr);
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
    final result = _sunvox.sv_load_from_memory(slotNumber, sData.cast(), data.length);

    if (result != 0) {
      throw Exception("cannot load data, error code:$result");
    }
  }

  int play() => _sunvox.sv_play(slotNumber);

  int playFromStart() => _sunvox.sv_play_from_beginning(slotNumber);

  int pause() => _sunvox.sv_pause(slotNumber);

  int resume() => _sunvox.sv_resume(slotNumber);

  int syncResume() => _sunvox.sv_sync_resume(slotNumber);

  void stop() => _sunvox.sv_stop(slotNumber);

  // volume 0 to 256
  set volume(int v) => _sunvox.sv_volume(slotNumber, v);

  int get moduleSlotsCount => _sunvox.sv_get_number_of_modules(slotNumber);

  String get projectName => _sunvox.sv_get_song_name(slotNumber).cast<Utf8>().toDartString();

  // eg. "Kicker"
  int findModuleByName(String name) => _sunvox.sv_find_module(slotNumber, name.toNativeUtf8().cast());

  SVModule? getModule(int moduleId) {
    final flags = _sunvox.sv_get_module_flags(0, moduleId);
    if ((flags & SV_MODULE_FLAG_EXISTS) == 0) {
      return null;
    } else {
      return SVModule(_sunvox, moduleId, slotNumber);
    }
  }

  /// track_num - track number (within the virtual pattern)
  /// module: 0 (empty) or module number + 1 (1..65535);
  /// note: 0 - nothing; 1..127 - note number; 128 - note off; 129, 130...
  /// velocity 129 (max)
  void sendEvent(int trackNumber, int moduleId, int note, int velocity) {
    _sunvox.sv_set_event_t(slotNumber, 1, 0);
    _sunvox.sv_send_event(slotNumber, trackNumber, note, velocity, moduleId + 1, 0, 0);
  }

  void shutDown() {
    _sunvox.sv_close_slot(slotNumber);
    _sunvox.sv_deinit();
  }
}

class SVModule {
  final libsunvox _sunvox;
  final int id;
  final int slot;

  int get flags => _sunvox.sv_get_module_flags(slot, id);

  String get name => _sunvox.sv_get_module_name(slot, id).cast<Utf8>().toDartString();

  SVColor get color {
    final int rgb = _sunvox.sv_get_module_color(slot, id);
    final r = rgb & 0xFF; //r = 0...255
    final g = (rgb >> 8) & 0xFF; //g = 0...255
    final b = (rgb >> 16) & 0xFF; //b = 0...255
    return SVColor(r, g, b);
  }

  SVModule(this._sunvox, this.id, this.slot);
  List<int> get inputs {
    final int inputSlots = (flags & SV_MODULE_INPUTS_MASK) >> SV_MODULE_INPUTS_OFF;
    final inputsArrayPtr = _sunvox.sv_get_module_inputs(slot, id);
    final inputsList = inputsArrayPtr.asTypedList(inputSlots);
    return inputsList.where((e) => e >= 0).toList();
  }

  List<int> get outputs {
    final int outputSlots = (flags & SV_MODULE_OUTPUTS_MASK) >> SV_MODULE_OUTPUTS_OFF;
    final outputsArrayPtr = _sunvox.sv_get_module_outputs(slot, id);
    final outputsList = outputsArrayPtr.asTypedList(outputSlots);
    return outputsList.where((e) => e >= 0).toList();
  }
}

class SVColor {
  final int r;
  final int g;
  final int b;

  SVColor(this.r, this.g, this.b);

  @override
  String toString() {
    return "rgb $r:$g:$b";
  }
}
