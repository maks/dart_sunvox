Dart FFI binding for the SunVox library.

## Features

See the [SunVox lib website](https://warmplace.ru/soft/sunvox/sunvox_lib.php).

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

See  examples in the `/example` folder. 

```dart
  final sunvox = LibSunvox();
  const filename = "sunvox_lib/resources/song01.sunvox";
  await sunvox.load(filename);
  sunvox.volume = 256;
  sunvox.play();
  print("playing:$filename ...");
  await Future<void>.delayed(Duration(seconds: 5));
  sunvox.stop();
  sunvox.shutDown();
```

## Licenses

The Dart binding is under the `LICENSE` file in this repo. Please see `sunvox_lib/docs/license` for information on licensing of the code contained within the subvox lib.