class SVCtlData {
  final bool scaled;
  final List<String>? values;

  const SVCtlData(this.scaled, [this.values]);
}

const Map<String, SVCtlData> controllerMap = {
  "volume": SVCtlData(true),
  "waveform": SVCtlData(
    false,
    [
      "triangle",
      "saw",
      "square",
      "noise",
      "drawn",
      "sine",
      "half sine",
      "abs sine",
      "drawn spline",
      "noise spline",
      "white noise",
      "pink noise",
      "red noise",
      "blue noise",
      "violet noise",
      "grey noise",
      "hand drawn",
    ],
  ),
  "panning": SVCtlData(true),
  "attack": SVCtlData(true),
  "release": SVCtlData(true),
  "sustain": SVCtlData(false, ["off", "on"]),
  "exponential envelope": SVCtlData(false, ["off", "on"]),
  "duty cycle": SVCtlData(true),
  "osc2": SVCtlData(true),
  "filter": SVCtlData(false, [
    "off",
    "lp 12db",
    "hp 12db",
    "bp 12db",
    "br 12db",
    "lp 24db",
    "hp 24db",
    "bp 24db",
    "br 24db",
  ]),
  "f.freq": SVCtlData(true),
  "f.resonance": SVCtlData(true),
  "f.exponential": SVCtlData(false, ["off", "on"]),
  "f.attack": SVCtlData(true),
  "f.release": SVCtlData(true),
  "f.envelope": SVCtlData(false, ["off", "susOff", "susOn"]),
  "polyphony": SVCtlData(false),
  "mode": SVCtlData(false, ["hq", "hqMono", "lq", "lqMono", "hqSpline"]),
  "noise": SVCtlData(true),
  "osc2 volume": SVCtlData(true),
  "osc2 mode": SVCtlData(false, ["add", "sub", "mul", "min", "max", "and", "xor"]),
  "osc2 phase": SVCtlData(true),
};
