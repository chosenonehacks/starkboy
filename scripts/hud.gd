class_name StarkBoyHUD
extends CanvasLayer

signal cheat_code_submitted(code: String)
signal code_console_toggled(open: bool)

@onready var health_bar: ProgressBar = %HealthBar
@onready var battery_bar: ProgressBar = %BatteryBar
@onready var ammo_label: Label = %AmmoLabel
@onready var ammo_icons: HBoxContainer = %AmmoIcons
@onready var mode_label: Label = %ModeLabel
@onready var message_label: Label = %MessageLabel
@onready var score_label: Label = %ScoreLabel
@onready var lives_label: Label = %LivesLabel
@onready var boss_bar: ProgressBar = %BossBar
@onready var boss_label: Label = %BossLabel
@onready var code_entry: LineEdit = %CodeEntry
var message_tween: Tween
var sfx_player: AudioStreamPlayer
const BULLET_ICON := preload("res://assets/ui/bullet_icon_v10.png")
var bullet_nodes: Array[TextureRect] = []

func _ready() -> void:
	code_entry.text_submitted.connect(_on_code_submitted)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.physical_keycode == KEY_QUOTELEFT or key.unicode in [96, 126]:
			_toggle_code_console()
			get_viewport().set_input_as_handled()
		elif key.keycode == KEY_ESCAPE and code_entry.visible:
			_toggle_code_console(false)
			get_viewport().set_input_as_handled()

func _toggle_code_console(force_open = null) -> void:
	var should_open: bool = not code_entry.visible if force_open == null else bool(force_open)
	code_entry.visible = should_open
	code_entry.text = ""
	if should_open:
		code_entry.grab_focus()
	else:
		code_entry.release_focus()
	code_console_toggled.emit(should_open)

func _on_code_submitted(code: String) -> void:
	cheat_code_submitted.emit(code.strip_edges().to_lower())
	_toggle_code_console(false)

func bind_player(player: StarkBoyPlayer) -> void:
	_build_ammo_icons()
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	player.stats_changed.connect(_on_stats_changed)
	player.action_message.connect(_on_action_message)
	_on_stats_changed(player.health, player.battery, player.ammo, player.mounted)

func _on_stats_changed(health: float, battery: float, ammo: int, mounted: bool) -> void:
	health_bar.value = health
	battery_bar.value = battery
	ammo_label.text = "AMMO"
	for i in bullet_nodes.size():
		bullet_nodes[i].modulate = Color.WHITE if i < ammo else Color(0.18, 0.2, 0.25, 0.42)
	mode_label.text = "RIDE" if mounted else "ON FOOT"

func _build_ammo_icons() -> void:
	if not bullet_nodes.is_empty(): return
	for i in 6:
		var icon := TextureRect.new()
		icon.texture = BULLET_ICON
		icon.custom_minimum_size = Vector2(11, 19)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ammo_icons.add_child(icon)
		bullet_nodes.append(icon)

func _on_action_message(text: String) -> void:
	message_label.text = text
	message_label.modulate.a = 1.0
	if message_tween:
		message_tween.kill()
	message_tween = create_tween()
	message_tween.tween_interval(0.65)
	message_tween.tween_property(message_label, "modulate:a", 0.0, 0.35)
	var kind := "ui"
	if "BANG" in text: kind = "shot"
	elif "PUNCH" in text: kind = "punch"
	elif "KICK" in text or "WHEELIE" in text: kind = "heavy"
	elif "OUCH" in text: kind = "hurt"
	elif "BATTERY" in text or "CLICK" in text: kind = "empty"
	elif "VICTORY" in text: kind = "victory"
	_play_sfx(kind)

func _play_sfx(kind: String) -> void:
	if sfx_player == null: return
	var sample_rate := 44100
	var duration := 0.09
	var frequency := 330.0
	match kind:
		"shot": duration = 0.24; frequency = 115.0
		"punch": duration = 0.14; frequency = 145.0
		"heavy": duration = 0.21; frequency = 82.0
		"hurt": duration = 0.2; frequency = 185.0
		"empty": duration = 0.07; frequency = 62.0
		"victory": duration = 0.4; frequency = 660.0
		"menu_select": duration = 0.065; frequency = 520.0
		"menu_confirm": duration = 0.14; frequency = 760.0
	var sample_count := int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var noise_state := 777
	for i in sample_count:
		var t := float(i) / sample_rate
		noise_state = int((noise_state * 1103515245 + 12345) & 0x7fffffff)
		var noise := (float(noise_state % 2000) / 1000.0) - 1.0
		var envelope := pow(1.0 - float(i) / sample_count, 2.2)
		var wave := sin(TAU * frequency * t) * envelope
		if kind in ["punch", "heavy"]:
			# Short gi-sleeve whoosh followed by a dry palm/body impact.
			var impact_at := 0.038 if kind == "punch" else 0.052
			var whoosh_env := sin(clampf(t / impact_at, 0.0, 1.0) * PI) if t < impact_at else 0.0
			var impact_t := maxf(0.0, t - impact_at)
			var slap := noise * exp(-impact_t * (62.0 if kind == "punch" else 42.0)) if t >= impact_at else 0.0
			var body := sin(TAU * frequency * impact_t) * exp(-impact_t * 28.0) if t >= impact_at else 0.0
			wave = noise * whoosh_env * 0.22 + slap * 0.82 + body * (0.62 if kind == "heavy" else 0.42)
		elif kind == "shot":
			# Pistol-like primer crack, short pressure blast, low report and tiny street echo.
			var crack := noise * exp(-t * 420.0)
			var blast := noise * exp(-t * 54.0) * 0.62
			var report := sin(TAU * frequency * t) * exp(-t * 24.0) * 0.78
			var echo_t := maxf(0.0, t - 0.095)
			var echo := noise * exp(-echo_t * 48.0) * 0.2 if t >= 0.095 else 0.0
			wave = crack + blast + report + echo
		if kind == "victory": wave += sin(TAU * frequency * 1.5 * t) * 0.45
		elif kind == "menu_select": wave += sin(TAU * frequency * 2.0 * t) * 0.22
		elif kind == "menu_confirm": wave += sin(TAU * frequency * 1.5 * t) * 0.38
		var sample := int(clampf(wave * envelope, -1.0, 1.0) * 24000.0)
		bytes[i * 2] = sample & 0xff
		bytes[i * 2 + 1] = (sample >> 8) & 0xff
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = bytes
	sfx_player.stream = wav
	sfx_player.play()

func play_menu_sfx(confirm := false) -> void:
	_play_sfx("menu_confirm" if confirm else "menu_select")

func play_impact_sfx(kind := "impact") -> void:
	_play_sfx("heavy" if kind == "knockdown" else ("hurt" if kind == "hurt" else "punch"))

func play_victory_fanfare() -> void:
	if sfx_player == null: return
	var sample_rate := 22050
	var notes := [523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5]
	var note_duration := 0.22
	var sample_count := int(sample_rate * note_duration * notes.size())
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in sample_count:
		var note_index := mini(notes.size() - 1, int(i / int(sample_rate * note_duration)))
		var local_t := fmod(float(i) / sample_rate, note_duration)
		var envelope := minf(1.0, local_t / 0.018) * pow(1.0 - local_t / note_duration, 0.65)
		var frequency: float = notes[note_index]
		var wave := sin(TAU * frequency * local_t) * 0.7 + sin(TAU * frequency * 2.0 * local_t) * 0.18
		var sample := int(clampf(wave * envelope, -1.0, 1.0) * 25000.0)
		bytes[i * 2] = sample & 0xff
		bytes[i * 2 + 1] = (sample >> 8) & 0xff
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = bytes
	sfx_player.stream = wav
	sfx_player.play()

func set_arcade(score: int, combo: int, lives: int, continues: int) -> void:
	score_label.text = "SCORE %06d%s" % [score, "  COMBO x%d" % combo if combo > 1 else ""]
	lives_label.text = "LIVES %d  C %d" % [lives, continues]

func show_boss(current: float, maximum: float, display_name := "BOSS") -> void:
	boss_bar.visible = true
	boss_label.visible = true
	boss_label.text = display_name
	boss_bar.max_value = maximum
	boss_bar.value = current

func hide_boss() -> void:
	boss_bar.visible = false
	boss_label.visible = false
