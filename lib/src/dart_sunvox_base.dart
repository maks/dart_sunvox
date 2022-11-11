import 'dart:ffi';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dart_sunvox/src/libsunvox_generated_bindings.dart';
import 'package:ffi/ffi.dart';

import 'controller_data.dart';
import 'pattern_data.dart';

export 'module_data.dart';

const sunvoxNoteOffCommand = 128;

const sunvoxModuleFlagExists = SV_MODULE_FLAG_EXISTS;
const sunvoxModuleFlagEffect = SV_MODULE_FLAG_EFFECT;
const sunvoxModuleFlagMute = SV_MODULE_FLAG_MUTE;
const sunvoxModuleFlagSolo = SV_MODULE_FLAG_SOLO;
const sunvoxModuleFlagByPass = SV_MODULE_FLAG_BYPASS;
const sunvoxModuleFlagOff = SV_MODULE_INPUTS_OFF;

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
      // SunVox is initialized. Slot is open and ready for use.
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

  SVModule? createModule(String type, String name) {
    final namePtr = name.toNativeUtf8().cast<Int8>();
    final typePtr = type.toNativeUtf8().cast<Int8>();

    _sunvox.sv_lock_slot(slotNumber);

    final nuModuleId = _sunvox.sv_new_module(slotNumber, typePtr, namePtr, 512, 512, 0);
    if (nuModuleId < 0) {
      print("create module error: $nuModuleId");
    }
    _sunvox.sv_unlock_slot(slotNumber);
    return SVModule(_sunvox, nuModuleId, slotNumber);
  }

  /// track_num - track number (within the virtual pattern)
  /// module: 0 (empty) or module number + 1 (1..65535)
  /// note: 0 - nothing; 1..127 - note number
  /// velocity 129 (max) 128 - note off;
  void sendNote(int trackNumber, int moduleId, int note, int velocity) {
    _sunvox.sv_set_event_t(slotNumber, 1, 0);
    _sunvox.sv_send_event(slotNumber, trackNumber, note, velocity, moduleId + 1, 0, 0);
  }

  void sendControllerValue(int moduleId, int controllerId, int value) {
    _sunvox.sv_set_event_t(slotNumber, 1, 0);
    _sunvox.sv_send_event(slotNumber, 0, 0, 0, moduleId + 1, controllerId << 8, value);
  }

  int get patternCount {
    final patternSlots = _sunvox.sv_get_number_of_patterns(slotNumber);
    int patternCount = 0;
    for (int i = 0; i < patternSlots; i++) {
      if (_sunvox.sv_get_pattern_lines(slotNumber, i) > 0) {
        patternCount++;
      }
    }
    return patternCount;
  }

  SVPattern? getPattern(int patternId) {
    return SVPattern(_sunvox, patternId, slotNumber);
  }

  void shutDown() {
    _sunvox.sv_close_slot(slotNumber);
    _sunvox.sv_deinit();
  }
}

class SVPattern {
  final libsunvox _sunvox;
  final int id;
  final int slot;

  int get patternTrackCount => _sunvox.sv_get_pattern_tracks(slot, id);

  int get patternLineCount => _sunvox.sv_get_pattern_lines(slot, id);

  String? get name {
    final ptr = _sunvox.sv_get_pattern_name(slot, id);
    return ptr.address != 0 ? ptr.cast<Utf8>().toDartString() : null;
  }

  List<SVPatternLine> get data {
    final cData = _sunvox.sv_get_pattern_data(slot, id);

    final trackCnt = patternTrackCount;
    final lineCnt = patternLineCount;

    final List<SVPatternLine> lines = [];

    for (int j = 0; j < lineCnt; j++) {
      final List<SVPatternEvent> events = [];
      for (int i = j * trackCnt; i < ((j + 1) * trackCnt); i++) {
        final lineData = cData.elementAt(i);
        events.add(SVPatternEvent(
          note: lineData.ref.note - 1,
          controller: lineData.ref.ctl,
          controllerValue: lineData.ref.ctl_val,
          module: math.max(0, lineData.ref.module - 1),
          velocity: math.max(0, lineData.ref.vel - 1),
        ));
      }
      lines.add(SVPatternLine(j, events));
    }
    return lines;
  }

  SVPattern(this._sunvox, this.id, this.slot);
}

class SVPatternLine {
  final int number;
  List<SVPatternEvent> events = [];

  SVPatternLine(this.number, this.events);

  @override
  String toString() {
    return "[$number] ${events.join(' ')}";
  }
}

class SVPatternEvent {
  final int note;
  final int velocity;
  final int module;
  final int controller;
  final int controllerValue;

  SVPatternEvent({
    required this.note,
    required this.velocity,
    required this.module,
    required this.controller,
    required this.controllerValue,
  });

  @override
  String toString() {
    return "n:${svNumberToNoteString(note)} v:${velocity.hex} m:${module.hex} c:${controller.hex} cv:${controllerValue.hex}|";
  }
}

class SVModule {
  final libsunvox _sunvox;
  final int id;
  final int slot;

  List<SVModuleController>? _controllers;

  int get flags => _sunvox.sv_get_module_flags(slot, id);

  String? get name {
    final ptr = _sunvox.sv_get_module_name(slot, id);
    return ptr.address != 0 ? ptr.cast<Utf8>().toDartString() : null;
  }

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

  List<SVModuleController> get controllers {
    if (_controllers == null) {
      final controllerCount = _sunvox.sv_get_number_of_module_ctls(slot, id);

      _controllers = List.generate(controllerCount, (index) {
        final nameCStr = _sunvox.sv_get_module_ctl_name(slot, id, index);       
        final c = SVModuleController(_sunvox, slot, id, index, nameCStr.cast<Utf8>().toDartString());
        return c;
      });
    }
    return _controllers!;
  }

  bool get isInstrument => !((flags & sunvoxModuleFlagEffect) == 2);

  // connect this module to the module for the given moduleId
  void connectToModule(int toModuleId) {
    _sunvox.sv_lock_slot(slot);
    final result = _sunvox.sv_connect_module(slot, id, toModuleId);
    _sunvox.sv_unlock_slot(slot);
    if (result < 0) {
      throw Exception("error connecting module $id->$toModuleId [$result]");
    }
  }

  // connect this module to the module for the given moduleId
  void disconnectFromModule(int toModuleId) {
    _sunvox.sv_lock_slot(slot);
    final result = _sunvox.sv_disconnect_module(slot, id, toModuleId);
    _sunvox.sv_unlock_slot(slot);
    if (result < 0) {
      throw Exception("error DISconnecting module $id->$toModuleId [$result]");
    }
  }

  void remove() {
    _sunvox.sv_lock_slot(slot);
    final result = _sunvox.sv_remove_module(slot, id);
    _sunvox.sv_unlock_slot(slot);
    if (result < 0) {
      throw Exception("error removing module $id [$result]");
    }
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

class SVModuleController {
  final int id;
  final int slot;
  final int moduleId;
  final String name;
  final libsunvox _sunvox;

  bool get useScaling => controllerMap[name.toLowerCase()]?.scaled ?? false;

  int get value => _sunvox.sv_get_module_ctl_value(slot, moduleId, id, useScaling ? 1 : 0);

  String? get displayValue {
    final displayValues = controllerMap[name.toLowerCase()]?.values;
    if (displayValues != null && !useScaling) {
      if (displayValues.length <= value) {
        throw Exception("Invalid display value for:$name val:$value");
      }
      return displayValues[value];
    } else {
      return "$value";
    }
  }
  
  SVModuleController(this._sunvox, this.slot, this.moduleId, this.id, this.name);
  
  void inc(int amount) async {
    final update = useScaling ? math.min(value + (amount * 128), 32768) : math.min(value + amount, 128);
    _sunvox.sv_set_event_t(slot, 1, 0);
    final ctl = (id + 1) << 8;
    _sunvox.sv_send_event(slot, 0, 0, 0, moduleId + 1, ctl, update);
  }

  void dec(int amount) {
    final update = math.max(value - amount, 0);
    _sunvox.sv_set_event_t(slot, 1, 0);
    final ctl = (id + 1) << 8;
    _sunvox.sv_send_event(slot, 0, 0, 0, moduleId + 1, ctl, update);
  }

  @override
  String toString() {
    return "[$id] $name scale:$useScaling";
  }
}


extension IntExt on int {
  String get hex => toRadixString(16);
}
