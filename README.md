Dart FFI binding for the SunVox library.

## Features

See the [SunVox lib website](https://warmplace.ru/soft/sunvox/sunvox_lib.php).

## Getting started

You will need to obtain the LibSunvox shared library for your OS from [it's webpage](https://warmplace.ru/soft/sunvox/sunvox_lib.php) and pass to the LibSunvox constructor the path to the shared library file as the second parameter.

## Usage

See  examples in the `/example` folder. 

```dart
  final sunvox = LibSunvox(0, "./sunvox.so");
  const filename = "sunvox_lib/resources/song01.sunvox";
  await sunvox.load(filename);
  sunvox.volume = 256;
  sunvox.play();
  print("playing:$filename ...");
  await Future<void>.delayed(Duration(seconds: 5));
  sunvox.stop();
  sunvox.shutDown();
```

## Development

To rebuild the Dart FFI bindings file run:
```
dart run ffigen
```

## Licenses

The Dart binding is under the `LICENSE` file in this repo. Please see `sunvox_lib/docs/license` for information on licensing of the code contained within the subvox lib.