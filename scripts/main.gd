extends Node2D

@onready var player: StarkBoyPlayer = $Player
@onready var hud: StarkBoyHUD = $HUD
@onready var music = $Music
var enemy_script := preload("res://scripts/enemy.gd")
var hit_effect_script := preload("res://scripts/hit_effect.gd")
var projectile_script := preload("res://scripts/projectile.gd")
var boss_attack_script := preload("res://scripts/boss_attack.gd")
var ammo_crate_script := preload("res://scripts/ammo_crate.gd")
var supply_pickup_script := preload("res://scripts/supply_pickup.gd")
var enemies: Array[Node] = []
var score := 0
var combo := 0
var combo_time := 0.0
var best_combo := 0
var attack_variety: Dictionary = {}
var wheelie_crowd_bonus_awarded := false
var hit_stop_serial := 0
var hit_stop_timer: Timer
var section_start_score := 0
var section_damage_taken := 0.0
var lives := 3
var continues := 2
var boss: Node
var boss_started := false
var victory := false
var section_spawned := [false, false, false]
var game_state := "title"
var current_wave := 0
var wave_alive := 0
var run_time := 0.0
var kill_count := 0
var boss_summons := 0
var forest_guard_wave_spawned := false
var encounter_index := 0
var encounter_active := false
var current_encounter_is_boss := false
var next_enemy_attack_msec := 0
var next_mushroom_attack_msec := 0
var next_ranged_attack_msec := 0
var active_supply: Node
var supply_spawn_chance := 0.48
var supply_rng := RandomNumberGenerator.new()
var wheelie_hit_targets: Dictionary = {}
const INTER_WAVE_DELAY := 1.5
const BOSS_TRANSITION_DELAY := 3.5
var inter_wave_delay := 0.0
const BIKE_COLOR_NAMES := ["RED", "WHITE", "FOREST GREY"]
const BIKE_COLORS := [Color("d72b32"), Color("edf1f2"), Color("68726d")]
var bike_color_index := 0
var bike_preview: Sprite2D
const PAUSE_OPTIONS := ["RESUME", "MAIN MENU", "EXIT GAME"]
var pause_option_index := 0
@onready var overlay: ColorRect = $HUD/Overlay
@onready var overlay_title: Label = $HUD/Overlay/OverlayTitle
@onready var overlay_body: Label = $HUD/Overlay/OverlayBody
@onready var title_art: TextureRect = $HUD/Overlay/TitleArt
@onready var game_logo: TextureRect = $HUD/Overlay/GameLogo

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hit_stop_timer = Timer.new()
	hit_stop_timer.one_shot = true
	hit_stop_timer.ignore_time_scale = true
	hit_stop_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	hit_stop_timer.timeout.connect(_end_hit_stop)
	add_child(hit_stop_timer)
	supply_rng.randomize()
	hud.bind_player(player)
	hud.cheat_code_submitted.connect(_on_cheat_code_submitted)
	hud.code_console_toggled.connect(_on_code_console_toggled)
	player.attack_requested.connect(_on_player_attack)
	player.defeated.connect(_on_player_defeated)
	player.damaged.connect(_on_player_damaged)
	hud.set_arcade(score, combo, lives, continues)
	_spawn_ammo_crates()
	_show_title()
	queue_redraw()

func _on_code_console_toggled(open: bool) -> void:
	player.movement_enabled = game_state == "playing" and not open

func _on_cheat_code_submitted(code: String) -> void:
	match code:
		"alpha 1":
			player.infinite_health = true
			hud._on_action_message("ALPHA: INFINITE HEALTH ON")
		"alpha 0":
			player.infinite_health = false
			hud._on_action_message("ALPHA: INFINITE HEALTH OFF")
		"hunter 1":
			player.infinite_ammo = true
			player.ammo = 6
			player.stats_changed.emit(player.health, player.battery, player.ammo, player.mounted)
			hud._on_action_message("HUNTER: INFINITE AMMO ON")
		"hunter 0":
			player.infinite_ammo = false
			hud._on_action_message("HUNTER: INFINITE AMMO OFF")
		"energy 1":
			player.infinite_battery = true
			hud._on_action_message("ENERGY: BATTERY HOLD ON")
		"energy 0":
			player.infinite_battery = false
			hud._on_action_message("ENERGY: BATTERY HOLD OFF")
		_:
			hud._on_action_message("UNKNOWN CODE")

func _process(delta: float) -> void:
	_handle_flow_input()
	_update_music_mode()
	if game_state != "playing" or get_tree().paused: return
	run_time += delta
	combo_time = maxf(0, combo_time - delta)
	inter_wave_delay = maxf(0.0, inter_wave_delay - delta)
	if combo_time <= 0: combo = 0
	_spawn_progression()
	if is_instance_valid(boss):
		hud.show_boss(boss.health, boss.max_health, boss._boss_name())

func _spawn_progression() -> void:
	if encounter_active or inter_wave_delay > 0.0: return
	var encounters := _encounter_plan()
	if encounter_index >= encounters.size(): return
	var encounter: Dictionary = encounters[encounter_index]
	if player.global_position.x < float(encounter["trigger"]): return
	encounter_active = true
	current_encounter_is_boss = encounter.has("boss")
	current_wave = encounter_index
	if current_encounter_is_boss:
		boss = _spawn_enemy(encounter["boss"], encounter["position"])
		wave_alive = 1
		boss_started = encounter["boss"] == "media_boss"
		if boss_started:
			player.min_x = 2760
			player.max_x = 3170
			boss_summons = 0
			forest_guard_wave_spawned = false
		hud._on_action_message(encounter["label"])
	else:
		_start_wave(encounter["enemies"], encounter["label"], int(encounter["level"]))
	var level := int(encounter["level"])
	if level >= 0 and level < section_spawned.size(): section_spawned[level] = true

func _encounter_plan() -> Array:
	return [
		{"level": 0, "trigger": 220.0, "label": "FOREST 1/3 — BREAK THE LINE", "enemies": [["picker", 420, 225], ["dog", 535, 292], ["picker", 650, 260]]},
		{"level": 0, "trigger": 450.0, "label": "FOREST 2/3 — HOUND PINCER", "enemies": [["dog", 585, 220], ["picker", 720, 300], ["dog", 835, 265], ["picker", 900, 235]]},
		{"level": 0, "trigger": 690.0, "label": "FOREST 3/3 — MUSHROOM CROSSFIRE", "enemies": [["picker", 750, 220], ["picker", 860, 300], ["dog", 930, 250]]},
		{"level": 0, "trigger": 875.0, "label": "BOSS — MUSHROOM KING!", "boss": "forest_boss", "position": Vector2(950, 255)},
		{"level": 1, "trigger": 1080.0, "label": "CITY 1/3 — STREET WELCOME", "enemies": [["dres", 1220, 230], ["bottle", 1350, 300], ["dres", 1440, 260]]},
		{"level": 1, "trigger": 1320.0, "label": "CITY 2/3 — PROTECT THE THROWER", "enemies": [["dres", 1430, 220], ["dres", 1540, 300], ["bottle", 1660, 255]]},
		{"level": 1, "trigger": 1560.0, "label": "CITY 3/3 — ALLEY CROSSFIRE", "enemies": [["bottle", 1630, 220], ["dres", 1730, 300], ["dres", 1810, 245], ["bottle", 1870, 285]]},
		{"level": 1, "trigger": 1810.0, "label": "BOSS — TRACKSUIT KING!", "boss": "city_boss", "position": Vector2(1850, 255)},
		{"level": 2, "trigger": 2000.0, "label": "MOTOCROSS 1/3 — FIRST LAP", "enemies": [["rider", 2140, 225], ["rider", 2260, 295], ["rider", 2350, 255]]},
		{"level": 2, "trigger": 2220.0, "label": "MOTOCROSS 2/3 — SPLIT LANES", "enemies": [["rider", 2320, 215], ["rider", 2440, 305], ["rider", 2540, 255]]},
		{"level": 2, "trigger": 2440.0, "label": "MOTOCROSS 3/3 — PACK BREAKER", "enemies": [["rider", 2510, 220], ["rider", 2600, 300], ["rider", 2690, 250]]},
		{"level": 2, "trigger": 2670.0, "label": "BOSS — QUAD WARLORD!", "boss": "quad_boss", "position": Vector2(2700, 255)},
		{"level": 3, "trigger": 2780.0, "label": "FOREST GUARD — FINAL CHECKPOINT", "enemies": [["forest_guard", 2860, 220], ["forest_guard_heavy", 2920, 295], ["forest_guard", 2990, 255], ["forest_guard_heavy", 3070, 285]]},
		{"level": 3, "trigger": 2940.0, "label": "FINAL STAGE — MEDIA BOSS!", "boss": "media_boss", "position": Vector2(3070, 255)}
	]

func _start_wave(data: Array, label := "ENEMIES AHEAD!", level := 0) -> void:
	wave_alive = data.size()
	player.max_x = 3170.0
	hud._on_action_message(label)
	for item in data:
		_spawn_enemy(item[0], Vector2(item[1], item[2]))
	_maybe_spawn_supply_for_wave(level)

func _maybe_spawn_supply_for_wave(level: int) -> void:
	if is_instance_valid(active_supply): active_supply.queue_free()
	active_supply = null
	if supply_rng.randf() > supply_spawn_chance: return
	var ranges := [Vector2(300, 920), Vector2(1120, 1840), Vector2(2050, 2700)]
	var bounds: Vector2 = ranges[clampi(level, 0, ranges.size() - 1)]
	var kind := "health" if supply_rng.randf() < 0.5 else "energy"
	if player.health < 45.0: kind = "health"
	elif player.battery < 35.0: kind = "energy"
	_spawn_supply_pickup(kind, Vector2(supply_rng.randf_range(bounds.x, bounds.y), supply_rng.randf_range(220.0, 300.0)))

func _spawn_supply_pickup(kind: String, at: Vector2) -> Node:
	var pickup = supply_pickup_script.new()
	add_child(pickup)
	pickup.global_position = at
	pickup.setup(player, kind)
	pickup.collected.connect(_on_supply_collected)
	active_supply = pickup
	return pickup

func _on_supply_collected(kind: String, amount: float) -> void:
	active_supply = null
	if kind == "health": hud._on_action_message("MEDKIT +%d HEALTH" % int(amount))
	else: hud._on_action_message("ENERGY DRINK +%d BATTERY" % int(amount))

func _spawn_enemy(kind: String, at: Vector2) -> Node:
	var enemy: Node = enemy_script.new()
	add_child(enemy)
	enemy.global_position = at
	enemy.setup(kind, player)
	enemy.died.connect(_on_enemy_died)
	enemy.attacked_player.connect(player.take_damage)
	enemy.boss_quote.connect(hud._on_action_message)
	enemy.summon_requested.connect(_on_boss_summon)
	enemy.projectile_requested.connect(_on_enemy_projectile)
	enemy.boss_attack_requested.connect(_on_boss_attack_requested)
	enemies.append(enemy)
	return enemy

func _spawn_ammo_crates() -> void:
	for at in [Vector2(780, 285), Vector2(1660, 225), Vector2(2530, 300), Vector2(2840, 235)]:
		var crate = ammo_crate_script.new()
		add_child(crate)
		crate.global_position = at
		crate.setup(player)
		crate.collected.connect(_on_ammo_crate_collected)

func _on_ammo_crate_collected(amount: int) -> void:
	player.add_ammo(amount)
	hud._on_action_message("AMMO CRATE +%d" % amount)

func _on_player_attack(kind: String, origin: Vector2, direction: float) -> void:
	if kind == "wheelie":
		# Start a fresh sweep; damage is dealt by the moving hitbox on subsequent frames.
		wheelie_hit_targets.clear()
		wheelie_crowd_bonus_awarded = false
		return
	var reach := 52.0
	var hit_damage := 12.0
	match kind:
		"quick": hit_damage = 12; reach = 48
		"quick_ride": hit_damage = 15; reach = 60
		"jab_combo": hit_damage = 22; reach = 62
		"jab_combo_ride": hit_damage = 28; reach = 78
		"heavy": hit_damage = 26; reach = 62
		"wheelie_active": hit_damage = 40; reach = 48
		"shoot": hit_damage = 28; reach = 330
	var hit_any := false
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy) or not enemy.active: continue
		var enemy_id: int = enemy.get_instance_id()
		if kind == "wheelie_active" and wheelie_hit_targets.has(enemy_id): continue
		var delta: Vector2 = enemy.global_position - origin
		var enemy_reach: float = reach + (28.0 if enemy._is_boss() else 0.0)
		var lane_tolerance := 52.0 if enemy._is_boss() else 40.0
		var faces_target := absf(delta.x) <= reach if kind == "wheelie_active" else signf(delta.x) == direction
		if faces_target and absf(delta.x) <= enemy_reach and absf(delta.y) <= lane_tolerance:
			if kind == "wheelie_active": wheelie_hit_targets[enemy_id] = true
			var knockback_force := 380.0 if kind in ["jab_combo", "jab_combo_ride"] else (270.0 if kind == "wheelie_active" else 190.0)
			var knocks_down := kind in ["heavy", "wheelie_active", "jab_combo", "jab_combo_ride"]
			enemy.take_hit(hit_damage, Vector2(direction * knockback_force, -35 if knocks_down else -20), knocks_down)
			_spawn_hit_effect(enemy.global_position + Vector2(0, -18), kind in ["heavy", "wheelie_active", "shoot", "jab_combo", "jab_combo_ride"])
			hud.play_impact_sfx("knockdown" if knocks_down else "impact")
			hit_any = true
			if kind == "shoot": break
	if hit_any:
		combo += 1
		best_combo = maxi(best_combo, combo)
		combo_time = 2.2
		attack_variety[kind] = true
		var variety_bonus := mini(4, attack_variety.size()) * 15
		score += 50 * maxi(1, combo) + variety_bonus
		if kind == "wheelie_active" and wheelie_hit_targets.size() >= 3 and not wheelie_crowd_bonus_awarded:
			wheelie_crowd_bonus_awarded = true
			score += 750
			hud._on_action_message("WHEELIE CROWD BREAK +750")
			_request_hit_stop(0.11)
		else:
			_request_hit_stop(0.085 if kind in ["heavy", "wheelie_active", "jab_combo", "jab_combo_ride"] else 0.045)
		hud.set_arcade(score, combo, lives, continues)

func try_enemy_attack(enemy: Node, category: String) -> bool:
	var now := Time.get_ticks_msec()
	if now < next_enemy_attack_msec:
		return false
	var active_attackers := enemies.filter(func(e): return is_instance_valid(e) and e.active and (e.attack_windup > 0.0 or e.pending_attack != ""))
	if category == "melee" and active_attackers.size() >= 2:
		return false
	# Enemies behind StarkBoy wait more often, keeping attacks readable and fair.
	if category == "melee" and is_instance_valid(enemy):
		var behind_player := signf(enemy.global_position.x - player.global_position.x) != player.facing
		if behind_player and active_attackers.size() >= 1:
			return false
	if category in ["mushroom", "ranged"]:
		if now < next_ranged_attack_msec:
			return false
		# Ranged mobs share one readable projectile lane: mushroom, bottle or drone shot.
		if get_tree().get_nodes_in_group("visible_projectiles").any(func(p): return is_instance_valid(p) and p.kind in ["mushroom", "bottle", "signal"]):
			return false
		next_ranged_attack_msec = now + 900
	if category == "mushroom":
		if now < next_mushroom_attack_msec:
			return false
		next_mushroom_attack_msec = now + 1350
	next_enemy_attack_msec = now + (520 if category in ["mushroom", "ranged"] else 340)
	return true

func _request_hit_stop(duration: float) -> void:
	hit_stop_serial += 1
	Engine.time_scale = 0.08
	hit_stop_timer.start(maxf(duration, hit_stop_timer.time_left))

func _end_hit_stop() -> void:
	Engine.time_scale = 1.0

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _spawn_hit_effect(at: Vector2, is_heavy: bool, player_damage := false) -> void:
	var effect = hit_effect_script.new()
	add_child(effect)
	effect.global_position = at
	effect.setup(is_heavy, player_damage)
	if is_heavy:
		var camera := player.get_node_or_null("Camera2D") as Camera2D
		if camera:
			camera.offset = Vector2(4, -2)
			var shake := create_tween()
			shake.tween_property(camera, "offset", Vector2(-3, 2), 0.04)
			shake.tween_property(camera, "offset", Vector2.ZERO, 0.07)

func _on_enemy_died(enemy: Node, points: int) -> void:
	score += points
	combo += 1
	best_combo = maxi(best_combo, combo)
	combo_time = 2.2
	hud.set_arcade(score, combo, lives, continues)
	kill_count += 1
	if kill_count % 3 == 0:
		player.add_ammo(2)
		hud._on_action_message("AMMO PICKUP +2")
	wave_alive = maxi(0, wave_alive - 1)
	if enemy == boss:
		hud.hide_boss()
		var defeated_type: String = enemy.enemy_type
		boss = null
		if defeated_type == "media_boss":
			victory = true
			game_state = "victory_sequence"
			player.movement_enabled = false
			hud._on_action_message("MEDIA BOSS DEFEATED!")
			hud.play_victory_fanfare()
			_finish_victory_after_animation()
		else:
			_award_section_grade(defeated_type)
			encounter_active = false
			encounter_index += 1
			inter_wave_delay = BOSS_TRANSITION_DELAY
			current_encounter_is_boss = false
			player.min_x = 30.0
			player.max_x = 3170.0
			hud._on_action_message("LEVEL BOSS DEFEATED — NEXT AREA INCOMING...")
	elif wave_alive == 0:
		encounter_active = false
		encounter_index += 1
		inter_wave_delay = INTER_WAVE_DELAY
		player.max_x = 3170.0
		hud._on_action_message("WAVE CLEAR — NEXT WAVE INCOMING...")

func _on_player_defeated() -> void:
	lives -= 1
	if lives <= 0:
		if continues > 0:
			continues -= 1
			lives = 3
			hud._on_action_message("CONTINUE! 3 LIVES RESTORED")
		else:
			lives = 0
			game_state = "game_over"
			player.movement_enabled = false
			_show_overlay("GAME OVER", "THE CAMPAIGN WON THIS ROUND.\n\nPRESS ENTER TO TRY AGAIN")
			get_tree().paused = true
			return
	player.respawn(_respawn_position(player.global_position.x))
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera: camera.reset_smoothing()
	hud.set_arcade(score, combo, lives, continues)

func _respawn_position(world_x: float) -> Vector2:
	# Each checkpoint is at the left edge of its current gameplay section.
	if world_x >= 2760.0: return Vector2(2790, 260)
	if world_x >= 1900.0: return Vector2(1950, 260)
	if world_x >= 1000.0: return Vector2(1050, 260)
	return Vector2(80, 260)

func _handle_flow_input() -> void:
	if Input.is_action_just_pressed("toggle_music"):
		var enabled: bool = music.toggle_music()
		hud._on_action_message("MUSIC ON" if enabled else "MUSIC OFF")
		return
	if Input.is_action_just_pressed("ui_cancel") and _go_back_menu():
		return
	if game_state == "bike_select":
		if Input.is_action_just_pressed("move_left"):
			bike_color_index = wrapi(bike_color_index - 1, 0, BIKE_COLOR_NAMES.size())
			_show_bike_selection()
			hud.play_menu_sfx()
		elif Input.is_action_just_pressed("move_right"):
			bike_color_index = wrapi(bike_color_index + 1, 0, BIKE_COLOR_NAMES.size())
			_show_bike_selection()
			hud.play_menu_sfx()
		if Input.is_action_just_pressed("ui_accept"):
			hud.play_menu_sfx(true)
			player.set_bike_color(BIKE_COLORS[bike_color_index])
			game_state = "intro"
			_show_overlay("RIDE BEGINS!", "Three districts are under hostile control.\nClear three waves and a boss in each district.\n\nFOREST → CITY → MOTOCROSS → MEDIA FINALE\n\nENTER TO RIDE    •    ESC — BACK")
		return
	if Input.is_action_just_pressed("ui_cancel") and game_state in ["playing", "paused"]:
		if game_state == "playing":
			_open_pause_menu()
		else:
			_resume_game()
		return
	if game_state == "paused":
		if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_left"):
			pause_option_index = wrapi(pause_option_index - 1, 0, PAUSE_OPTIONS.size())
			_show_pause_menu()
			hud.play_menu_sfx()
		elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("move_right"):
			pause_option_index = wrapi(pause_option_index + 1, 0, PAUSE_OPTIONS.size())
			_show_pause_menu()
			hud.play_menu_sfx()
		if Input.is_action_just_pressed("ui_accept"):
			hud.play_menu_sfx(true)
			_activate_pause_option()
		return
	if not Input.is_action_just_pressed("ui_accept"): return
	match game_state:
		"title":
			game_state = "bike_select"
			_show_bike_selection()
		"intro":
			game_state = "playing"
			overlay.visible = false
			player.movement_enabled = true
			hud._on_action_message("RIDE ON!")
		"game_over", "results":
			get_tree().paused = false
			get_tree().reload_current_scene()

func _go_back_menu() -> bool:
	match game_state:
		"intro":
			game_state = "bike_select"
			_show_bike_selection()
			hud.play_menu_sfx()
			return true
		"bike_select":
			game_state = "title"
			_show_title()
			hud.play_menu_sfx()
			return true
	return false

func _update_music_mode() -> void:
	var desired_mode := "game" if game_state in ["playing", "victory_sequence"] else "menu"
	music.set_mode(desired_mode)

func _open_pause_menu() -> void:
	game_state = "paused"
	pause_option_index = 0
	player.movement_enabled = false
	get_tree().paused = true
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_show_pause_menu()

func _show_pause_menu() -> void:
	var lines: Array[String] = []
	for index in PAUSE_OPTIONS.size():
		lines.append("▶  %s  ◀" % PAUSE_OPTIONS[index] if index == pause_option_index else PAUSE_OPTIONS[index])
	_show_overlay("PAUSED", "\n".join(lines) + "\n\nARROWS — SELECT    ENTER — CONFIRM\nESC — RESUME")

func _resume_game() -> void:
	get_tree().paused = false
	game_state = "playing"
	player.movement_enabled = true
	overlay.visible = false

func _activate_pause_option() -> void:
	match pause_option_index:
		0:
			_resume_game()
		1:
			get_tree().paused = false
			get_tree().reload_current_scene()
		2:
			get_tree().paused = false
			get_tree().quit()

func _show_title() -> void:
	_show_overlay("STARKBOY", "ELECTRIC FOREST BEAT 'EM UP\n\n3 LIVES  •  2 CONTINUES\nKEYBOARD + GAMEPAD\n\nPRESS ENTER")
	title_art.visible = true
	game_logo.visible = true
	overlay_title.visible = false
	overlay_body.offset_left = 42.0
	overlay_body.offset_top = 160.0
	overlay_body.offset_right = 388.0
	overlay_body.offset_bottom = 330.0

func _show_bike_selection() -> void:
	player.set_bike_color(BIKE_COLORS[bike_color_index])
	_show_overlay("CHOOSE YOUR BIKE", "◀  %s  ▶\n\n\n\n\nLEFT / RIGHT    •    ENTER — CONFIRM    •    ESC — BACK" % BIKE_COLOR_NAMES[bike_color_index])
	overlay_title.add_theme_color_override("font_color", BIKE_COLORS[bike_color_index])
	overlay_title.z_index = 3
	overlay_body.z_index = 3
	if not is_instance_valid(bike_preview):
		bike_preview = Sprite2D.new()
		bike_preview.name = "BikeColorPreview"
		bike_preview.texture = player.NORMAL_SHEET
		bike_preview.hframes = 4
		bike_preview.vframes = 3
		bike_preview.frame = 0
		bike_preview.scale = Vector2(0.38, 0.38)
		bike_preview.position = Vector2(320, 195)
		bike_preview.z_index = 1
		overlay.add_child(bike_preview)
	bike_preview.material = player.bike_paint_material
	bike_preview.visible = true

func _show_overlay(title: String, body: String) -> void:
	overlay.visible = true
	if is_instance_valid(bike_preview): bike_preview.visible = false
	title_art.visible = false
	game_logo.visible = false
	overlay_title.visible = true
	overlay_body.offset_left = 55.0
	overlay_body.offset_top = 130.0
	overlay_body.offset_right = 585.0
	overlay_body.offset_bottom = 310.0
	overlay_title.text = title
	overlay_body.text = body

func _calculate_grade() -> String:
	if score >= 42000 and lives >= 2: return "S"
	if score >= 32000: return "A"
	if score >= 22000: return "B"
	if score >= 12000: return "C"
	return "D"

func _on_boss_summon() -> void:
	if not is_instance_valid(boss): return
	if boss.enemy_type == "media_boss" and not forest_guard_wave_spawned:
		forest_guard_wave_spawned = true
		hud._on_action_message("FOREST GUARD REINFORCEMENTS!")
		_spawn_enemy("forest_guard", boss.global_position + Vector2(-155, -38))
		_spawn_enemy("forest_guard_heavy", boss.global_position + Vector2(-115, 42))
		_spawn_enemy("forest_guard", boss.global_position + Vector2(105, 28))
		return
	if boss_summons >= 4: return
	boss_summons += 2
	_spawn_enemy("camera_helper", boss.global_position + Vector2(-95, -35))
	_spawn_enemy("drone", boss.global_position + Vector2(-130, 40))

func _on_enemy_projectile(kind: String, origin: Vector2, target_position: Vector2) -> void:
	var projectile = projectile_script.new()
	add_child(projectile)
	projectile.setup(kind, origin, target_position, player)

func _on_boss_attack_requested(kind: String, origin: Vector2, target_position: Vector2, hit_damage: float, radius: float, travel_time: float) -> void:
	var warning = boss_attack_script.new()
	add_child(warning)
	warning.setup(kind, origin, target_position, player, hit_damage, radius, travel_time)

func _on_player_damaged(at: Vector2) -> void:
	section_damage_taken += 1.0
	combo = 0
	combo_time = 0.0
	attack_variety.clear()
	hud.set_arcade(score, combo, lives, continues)
	_spawn_hit_effect(at, true, true)
	hud.play_impact_sfx("hurt")
	_request_hit_stop(0.09)

func _award_section_grade(defeated_type: String) -> void:
	var earned := score - section_start_score
	var grade := "S" if earned >= 8500 and section_damage_taken <= 1.0 else ("A" if earned >= 6500 else ("B" if earned >= 4500 else "C"))
	var bonus: int = int({"S": 2000, "A": 1200, "B": 600, "C": 250}[grade])
	score += bonus
	hud.set_arcade(score, combo, lives, continues)
	hud._on_action_message("%s CLEAR — GRADE %s  +%d" % [_section_name(defeated_type), grade, bonus])
	section_start_score = score
	section_damage_taken = 0.0
	attack_variety.clear()

func _section_name(defeated_type: String) -> String:
	match defeated_type:
		"forest_boss": return "FOREST"
		"city_boss": return "CITY"
		"quad_boss": return "MOTOCROSS"
		_: return "STAGE"

func _finish_victory_after_animation() -> void:
	await get_tree().create_timer(2.4).timeout
	if not is_inside_tree(): return
	game_state = "results"
	var grade := _calculate_grade()
	_show_overlay("RIDE COMPLETE — GRADE %s" % grade, "SCORE %06d\nTIME %02d:%02d\nBEST COMBO %d\n\nMediaBoss drops the broadcast.\nThe trails belong to the riders again.\n\nPRESS ENTER FOR TITLE" % [score, int(run_time) / 60, int(run_time) % 60, best_combo])

func _draw() -> void:
	if has_node("WorldBackground"):
		return
	draw_rect(Rect2(0, 0, 3200, 360), Color("162c2b"))
	draw_rect(Rect2(0, 180, 1000, 180), Color("66543d"))
	draw_rect(Rect2(1000, 180, 900, 180), Color("39434d"))
	draw_rect(Rect2(1900, 180, 850, 180), Color("8b613d"))
	draw_rect(Rect2(2750, 180, 450, 180), Color("332d3c"))
	for x in range(50, 1000, 120):
		draw_rect(Rect2(x, 90, 20, 115), Color("283f2d"))
		draw_circle(Vector2(x + 10, 75), 42, Color("315a38"))
	for x in range(1050, 1900, 170):
		draw_rect(Rect2(x, 95, 120, 95), Color("5c6470"))
		draw_rect(Rect2(x + 12, 112, 22, 30), Color("d7bb78"))
	for x in range(1980, 2700, 180):
		draw_circle(Vector2(x, 215), 46, Color("a97745"))
	draw_string(ThemeDB.fallback_font, Vector2(110, 155), "FOREST ROAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(1210, 155), "CITY STREET", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(2150, 155), "MOTOCROSS TRACK", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(2850, 155), "BOSS ARENA", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
