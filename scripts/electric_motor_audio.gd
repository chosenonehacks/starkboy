extends AudioStreamPlayer

@export var player_path: NodePath
var playback: AudioStreamGeneratorPlayback
var phase := 0.0
var inverter_phase := 0.0
var noise_state := 12345
var filtered_noise := 0.0

func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.25
	stream = generator
	volume_db = -15.0
	play()
	playback = get_stream_playback()

func _process(_delta: float) -> void:
	if playback == null: return
	var player := get_node_or_null(player_path)
	var speed_ratio: float = clampf(player.velocity.length() / 220.0, 0.0, 1.0) if player else 0.0
	var mounted: bool = player.mounted if player else false
	var frequency := 72.0 + speed_ratio * 510.0
	var amplitude := (0.012 + speed_ratio * 0.07) if mounted else 0.0
	var frames := playback.get_frames_available()
	for i in frames:
		phase = fmod(phase + frequency / 22050.0, 1.0)
		inverter_phase = fmod(inverter_phase + (frequency * 6.0 + 900.0) / 22050.0, 1.0)
		noise_state = int((noise_state * 1103515245 + 12345) & 0x7fffffff)
		var raw_noise := (float(noise_state % 2000) / 1000.0) - 1.0
		filtered_noise = lerpf(filtered_noise, raw_noise, 0.08)
		var whine := sin(phase * TAU) + sin(phase * TAU * 2.01) * 0.32 + sin(inverter_phase * TAU) * 0.1
		var tire := filtered_noise * speed_ratio * 0.38
		var sample := (whine + tire) * amplitude
		playback.push_frame(Vector2(sample, sample))
