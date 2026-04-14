extends AudioStreamPlayer

const MIX_RATE := 44100.0
const BUFFER_LENGTH := 0.35
const TWO_PI := PI * 2.0

const MIN_BPM := 62.0
const MAX_BPM := 168.0
const ROOT_MIDI := 40
const SCALE := [0, 2, 3, 5, 7, 9, 10]
const CHORD_PROGRESSION := [
	[0, 3, 4],
	[5, 1, 3],
	[3, 5, 0],
	[4, 6, 1],
]

var playback: AudioStreamGeneratorPlayback

var live_density_target := 0.0
var live_density := 0.0
var energy_target := 0.0
var energy := 0.0
var board_running := true

var song_time := 0.0
var note_time := 0.0
var chord_time := 0.0
var note_duration := 0.75
var chord_duration := 4.0
var chord_index := 0
var lead_note_index := 0
var random_state := RandomNumberGenerator.new()

var lead_frequency := 0.0
var lead_phase := 0.0
var lead_age := 0.0
var lead_duration_seconds := 0.8

var pad_frequencies := PackedFloat32Array([0.0, 0.0, 0.0])
var pad_phases := PackedFloat32Array([0.0, 0.0, 0.0])
var pad_age := 0.0
var pad_duration_seconds := 2.0

var bass_frequency := 0.0
var bass_phase := 0.0
var bass_age := 0.0
var bass_duration_seconds := 1.1


func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = BUFFER_LENGTH
	stream = generator
	volume_db = -18.0
	bus = &"Master"
	random_state.randomize()
	play()
	playback = get_stream_playback() as AudioStreamGeneratorPlayback
	_advance_harmony(true)
	_schedule_next_note(true)
	_fill_buffer()
	set_process(true)


func _process(delta: float) -> void:
	live_density = lerpf(live_density, live_density_target, min(1.0, delta * 1.6))
	energy = lerpf(energy, energy_target, min(1.0, delta * 2.0))
	if playback == null:
		return
	_fill_buffer()


func _exit_tree() -> void:
	stop()
	playback = null


func update_state(live_cells: int, total_cells: int, is_running: bool) -> void:
	if total_cells <= 0:
		live_density_target = 0.0
	else:
		live_density_target = clampf(float(live_cells) / float(total_cells), 0.0, 1.0)
	board_running = is_running
	energy_target = live_density_target if board_running else live_density_target * 0.45


func _fill_buffer() -> void:
	var frames_available := playback.get_frames_available()
	for _frame in range(frames_available):
		var seconds_per_beat := 60.0 / _current_bpm()
		var sample := _sample_current_mix(seconds_per_beat)
		playback.push_frame(Vector2(sample, sample))

		var delta_time := 1.0 / MIX_RATE
		song_time += delta_time
		note_time += delta_time / seconds_per_beat
		chord_time += delta_time / seconds_per_beat
		lead_age += delta_time
		pad_age += delta_time
		bass_age += delta_time

		if chord_time >= chord_duration:
			chord_time -= chord_duration
			_advance_harmony(false)
		if note_time >= note_duration:
			note_time -= note_duration
			_schedule_next_note(false)


func _sample_current_mix(seconds_per_beat: float) -> float:
	var lead := _sample_lead(seconds_per_beat)
	var pad := _sample_pad(seconds_per_beat)
	var bass := _sample_bass(seconds_per_beat)
	var movement := sin(song_time * TWO_PI * (0.08 + energy * 0.18)) * 0.01
	return clampf(lead + pad + bass + movement, -0.92, 0.92)


func _sample_lead(seconds_per_beat: float) -> float:
	if lead_frequency <= 0.0:
		return 0.0
	var phase_step := lead_frequency / MIX_RATE
	lead_phase = fmod(lead_phase + phase_step, 1.0)
	var brightness := lerpf(0.42, 0.64, energy)
	var wave := 1.0 if lead_phase < brightness else -1.0
	var envelope := _adsr(lead_age, lead_duration_seconds, 0.08, 0.15, 0.55 + energy * 0.2)
	return wave * envelope * lerpf(0.04, 0.09, energy) * sqrt(seconds_per_beat)


func _sample_pad(seconds_per_beat: float) -> float:
	var total := 0.0
	for index in range(pad_frequencies.size()):
		var frequency := pad_frequencies[index]
		if frequency <= 0.0:
			continue
		var phase := fmod(pad_phases[index] + frequency / MIX_RATE, 1.0)
		pad_phases[index] = phase
		total += _triangle_wave(phase)
	var envelope := _adsr(pad_age, pad_duration_seconds, 0.22, 0.35, 0.72)
	return total * envelope * lerpf(0.025, 0.05, energy) * seconds_per_beat


func _sample_bass(seconds_per_beat: float) -> float:
	if bass_frequency <= 0.0:
		return 0.0
	bass_phase = fmod(bass_phase + bass_frequency / MIX_RATE, 1.0)
	var sub := sin(bass_phase * TWO_PI)
	var envelope := _adsr(bass_age, bass_duration_seconds, 0.04, 0.24, 0.68)
	return sub * envelope * lerpf(0.05, 0.1, energy) * seconds_per_beat


func _advance_harmony(initial: bool) -> void:
	if not initial:
		chord_index = (chord_index + 1) % CHORD_PROGRESSION.size()
	var chord: Array = CHORD_PROGRESSION[chord_index]
	var root_degree: int = chord[0]
	pad_frequencies[0] = _degree_to_frequency(root_degree, 1)
	pad_frequencies[1] = _degree_to_frequency(chord[1], 1)
	pad_frequencies[2] = _degree_to_frequency(chord[2], 1)
	pad_age = 0.0
	pad_duration_seconds = (60.0 / _current_bpm()) * chord_duration * 1.1
	bass_frequency = _degree_to_frequency(root_degree, 0)
	bass_age = 0.0
	bass_duration_seconds = (60.0 / _current_bpm()) * lerpf(1.8, 0.75, energy)


func _schedule_next_note(initial: bool) -> void:
	var chord: Array = CHORD_PROGRESSION[chord_index]
	var activity := pow(live_density, 0.75)
	var rest_chance := lerpf(0.38, 0.04, activity)
	if not initial and random_state.randf() < rest_chance:
		lead_frequency = 0.0
	else:
		var use_chord_tone := random_state.randf() < lerpf(0.92, 0.62, activity)
		var degree: int
		if use_chord_tone:
			degree = chord[(lead_note_index + random_state.randi_range(0, 1)) % chord.size()]
		else:
			degree = int(random_state.randi() % SCALE.size())
		var octave_offset := 1 if activity < 0.45 else (2 if activity < 0.82 else 3)
		lead_frequency = _degree_to_frequency(degree, octave_offset)
		lead_age = 0.0
		lead_duration_seconds = (60.0 / _current_bpm()) * lerpf(1.35, 0.3, activity)
	lead_note_index = (lead_note_index + 1) % chord.size()
	note_duration = _next_note_length_beats(activity)


func _next_note_length_beats(activity: float) -> float:
	if activity < 0.18:
		return 1.5
	if activity < 0.38:
		return 1.0
	if activity < 0.58:
		return 0.75 if random_state.randf() < 0.3 else 0.5
	if activity < 0.8:
		return 0.5 if random_state.randf() < 0.6 else 0.25
	return 0.25


func _degree_to_frequency(scale_degree: int, octave: int) -> float:
	var normalized_degree := posmod(scale_degree, SCALE.size())
	var octave_offset := floori(float(scale_degree) / float(SCALE.size()))
	var semitone: int = SCALE[normalized_degree] + (octave + octave_offset) * 12
	return 440.0 * pow(2.0, (float(ROOT_MIDI + semitone) - 69.0) / 12.0)


func _current_bpm() -> float:
	return lerpf(MIN_BPM, MAX_BPM, pow(energy, 1.35))


func _adsr(age: float, duration: float, attack_portion: float, release_portion: float, sustain_level: float) -> float:
	if duration <= 0.0:
		return 0.0
	var attack_time := maxf(0.01, duration * attack_portion)
	var release_time := maxf(0.04, duration * release_portion)
	var sustain_end := maxf(attack_time, duration - release_time)
	if age < attack_time:
		return age / attack_time
	if age < sustain_end:
		return sustain_level
	if age < duration:
		return lerpf(sustain_level, 0.0, (age - sustain_end) / release_time)
	return 0.0


func _triangle_wave(phase: float) -> float:
	return 1.0 - 4.0 * abs(phase - 0.5)
