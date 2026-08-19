extends AudioStreamPlayer

var playback: AudioStreamGeneratorPlayback
var melody_phase := 0.0
var bass_phase := 0.0
var sample_clock := 0
var music_mode := "menu"
var music_enabled := true
var noise_state := 9127
const RATE := 22050.0
const MENU_MELODY := [261.63, 329.63, 392.0, 523.25, 392.0, 329.63, 293.66, 349.23, 440.0, 392.0, 329.63, 293.66, 261.63, 0.0, 196.0, 246.94]
const MENU_BASS := [65.41, 65.41, 87.31, 87.31, 73.42, 73.42, 98.0, 98.0]
const GAME_MELODY := [220.0, 261.63, 329.63, 392.0, 440.0, 392.0, 329.63, 261.63, 293.66, 349.23, 440.0, 523.25, 440.0, 349.23, 293.66, 246.94]
const GAME_BASS := [55.0, 55.0, 65.41, 73.42, 55.0, 82.41, 73.42, 65.41]

func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = RATE
	generator.buffer_length = 0.35
	stream = generator
	volume_db = -12.0
	play()
	playback = get_stream_playback()

func _process(_delta: float) -> void:
	if playback == null: return
	for i in playback.get_frames_available():
		var beat_duration := 0.22 if music_mode == "menu" else 0.14
		var melody: Array = MENU_MELODY if music_mode == "menu" else GAME_MELODY
		var bass: Array = MENU_BASS if music_mode == "menu" else GAME_BASS
		var beat_samples := int(RATE * beat_duration)
		var beat := int(sample_clock / beat_samples)
		var beat_t := float(sample_clock % beat_samples) / RATE
		var melody_frequency: float = melody[beat % melody.size()]
		var bass_frequency: float = bass[int(beat / 2) % bass.size()]
		melody_phase = fmod(melody_phase + melody_frequency / RATE, 1.0)
		bass_phase = fmod(bass_phase + bass_frequency / RATE, 1.0)
		var note_gate := 1.0 if beat_t < beat_duration * 0.72 else 0.12
		var lead := (1.0 if melody_phase < 0.25 else -0.72) * note_gate if melody_frequency > 0.0 else 0.0
		var bass_pulse := (0.65 if bass_phase < 0.5 else -0.65) * (1.0 - beat_t / beat_duration)
		var kick := sin(TAU * (72.0 - beat_t * 180.0) * beat_t) * exp(-beat_t * 28.0) if beat % 4 in [0, 2] else 0.0
		noise_state = int((noise_state * 1103515245 + 12345) & 0x7fffffff)
		var noise := (float(noise_state % 2000) / 1000.0) - 1.0
		var hat := noise * exp(-beat_t * 55.0) if music_mode == "game" else noise * exp(-beat_t * 70.0) * 0.3
		var energy := 0.038 if music_mode == "menu" else 0.052
		var sample := (lead * 0.52 + bass_pulse * 0.42 + kick * 0.65 + hat * 0.16) * energy
		playback.push_frame(Vector2(sample * 0.94, sample))
		sample_clock += 1

func set_mode(mode: String) -> void:
	if mode == music_mode: return
	music_mode = mode
	sample_clock = 0
	melody_phase = 0.0
	bass_phase = 0.0

func toggle_music() -> bool:
	music_enabled = not music_enabled
	volume_db = -12.0 if music_enabled else -80.0
	return music_enabled
