const _notes = ["C", "c", "D", "d", "E", "F", "f", "G", "g", "A", "a", "B"];

String svNumberToNoteString(int noteNum) {
  final idx = noteNum % 12;
  final tone = _notes[idx];
  final octave = noteNum ~/ 12;
  return tone + "$octave";
}

int svNoteToMidi(int sunvoxNoteNumber) => sunvoxNoteNumber + 13;
int svMidiNoteToSunvox(int midiNoteNumber) => midiNoteNumber - 13;
