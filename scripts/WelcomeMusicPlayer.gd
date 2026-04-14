extends AudioStreamPlayer

const MIX_RATE := 44100.0
const BUFFER_LENGTH := 0.35
const BPM := 92.0
const BEAT_DURATION := 60.0 / BPM
const STEP_DURATION := BEAT_DURATION * 0.5
const MASTER_GAIN := 0.15
const TWO_PI := PI * 2.0

const MELODY_STEPS := [
	{"note": "E4", "beats": 2.0},
	{"note": "G4", "beats": 1.0},
	{"note": "A4", "beats": 1.0},
	{"note": "G4", "beats": 2.0},
	{"note": "E4", "beats": 2.0},
	{"note": "D4", "beats": 2.0},
	{"note": "E4", "beats": 2.0},
	{"note": "B3", "beats": 2.0},
	{"note": "D4", "beats": 2.0},
	{"note": "E4", "beats": 2.0},
	{"note": "REST", "beats": 2.0},
	{"note": "A3", "beats": 2.0},
	{"note": "B3", "beats": 2.0},
	{"note": "D4", "beats": 2.0},
	{"note": "E4", "beats": 4.0},
]

const BASS_STEPS := [
	{"note": "E2", "beats": 2.0},
	{"note": "E2", "beats": 2.0},
	{"note": "C3", "beats": 2.0},
	{"note": "B2", "beats": 2.0},
	{"note": "A2", "beats": 2.0},
	{"note": "A2", "beats": 2.0},
	{"note": "B2", "beats": 2.0},
	{"note": "E2", "beats": 2.0},
]

var playback: AudioStreamGeneratorPlayback
var melody_notes: Array[Dictionary] = []
var bass_notes: Array[Dictionary] = []
var song_length := 0.0
var playhead := 0.0


func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = BUFFER_LENGTH
	stream = generator
	volume_db = -19.0
	bus = &"Master"
	melody_notes = _build_notes(MELODY_STEPS, 0.0)
	bass_notes = _build_notes(BASS_STEPS, 0.0)
	song_length = max(_sequence_length(melody_notes), _sequence_length(bass_notes))
	play()
	playback = get_stream_playback() as AudioStreamGeneratorPlayback
	_fill_buffer()
	set_process(true)


func _process(_delta: float) -> void:
	if playback == null:
		return
	_fill_buffer()


func _exit_tree() -> void:
	stop()
	playback = null


func _fill_buffer() -> void:
	var frames_available := playback.get_frames_available()
	for _frame in range(frames_available):
		var sample := _sample_song(playhead) * MASTER_GAIN
		playback.push_frame(Vector2(sample, sample))
		playhead += 1.0 / MIX_RATE
		if playhead >= song_length:
			playhead = fmod(playhead, song_length)


func _sample_song(song_time: float) -> float:
	var melody := _sample_voice(song_time, melody_notes, 0.48, 0.22, 0.62)
	var bass := _sample_voice(song_time, bass_notes, 0.42, 0.12, 0.0)
	var shimmer := sin(song_time * TWO_PI * 0.35) * 0.01
	return clampf(melody + bass + shimmer, -0.95, 0.95)


func _sample_voice(song_time: float, notes: Array[Dictionary], gain: float, attack: float, pulse_width: float) -> float:
	var note := _find_note(notes, song_time)
	if note.is_empty():
		return 0.0

	var frequency: float = note["frequency"]
	if frequency <= 0.0:
		return 0.0

	var local_time: float = song_time - note["start"]
	var duration: float = note["duration"]
	var envelope := _envelope(local_time, duration, attack)
	var phase := fmod(local_time * frequency, 1.0)
	var oscillator := _pulse_wave(phase, pulse_width) if pulse_width > 0.0 else _triangle_wave(phase)
	return oscillator * envelope * gain


func _envelope(local_time: float, duration: float, attack_portion: float) -> float:
	var attack_time: float = maxf(0.01, duration * attack_portion)
	var release_time: float = maxf(0.04, duration * 0.24)
	var sustain_end: float = maxf(attack_time, duration - release_time)

	if local_time < attack_time:
		return local_time / attack_time
	if local_time > sustain_end:
		return max(0.0, (duration - local_time) / release_time)
	return 1.0


func _pulse_wave(phase: float, width: float) -> float:
	return 1.0 if phase < width else -1.0


func _triangle_wave(phase: float) -> float:
	return 1.0 - 4.0 * abs(phase - 0.5)


func _build_notes(steps: Array, octave_shift: float) -> Array[Dictionary]:
	var notes: Array[Dictionary] = []
	var cursor := 0.0
	for step in steps:
		var duration: float = float(step.get("beats", 1.0)) * STEP_DURATION
		var note_name: String = step.get("note", "REST")
		notes.append(
			{
				"start": cursor,
				"duration": duration,
				"frequency": _note_to_frequency(note_name, octave_shift),
			}
		)
		cursor += duration
	return notes


func _sequence_length(notes: Array[Dictionary]) -> float:
	if notes.is_empty():
		return 0.0
	var last_note: Dictionary = notes[notes.size() - 1]
	return float(last_note["start"]) + float(last_note["duration"])


func _find_note(notes: Array[Dictionary], song_time: float) -> Dictionary:
	for note in notes:
		var start: float = note["start"]
		var finish: float = start + note["duration"]
		if song_time >= start and song_time < finish:
			return note
	return {}


func _note_to_frequency(note_name: String, octave_shift: float) -> float:
	if note_name == "REST":
		return 0.0

	var semitone_map := {
		"C": 0,
		"C#": 1,
		"D": 2,
		"D#": 3,
		"E": 4,
		"F": 5,
		"F#": 6,
		"G": 7,
		"G#": 8,
		"A": 9,
		"A#": 10,
		"B": 11,
	}

	var pitch: String = note_name.left(note_name.length() - 1)
	var octave: int = int(note_name.right(1))
	var midi_note := (octave + 1) * 12 + int(semitone_map.get(pitch, 0))
	var shifted_note: float = midi_note + octave_shift
	return 440.0 * pow(2.0, (shifted_note - 69.0) / 12.0)
