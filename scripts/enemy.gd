class_name StarkEnemy
extends CharacterBody2D

signal died(enemy: StarkEnemy, points: int)
signal attacked_player(damage: float, from_position: Vector2)
signal boss_phase_changed(phase: int)
signal boss_quote(text: String)
signal summon_requested
signal projectile_requested(kind: String, origin: Vector2, target_position: Vector2)
signal boss_attack_requested(kind: String, origin: Vector2, target_position: Vector2, damage: float, radius: float, travel_time: float)

var enemy_type := "thug"
var target: Node2D
var max_health := 35.0
var health := 35.0
var speed := 62.0
var damage := 10.0
var points := 500
var attack_range := 35.0
var attack_cooldown := 0.0
var special_cooldown := 1.5
var flash_time := 0.0
var phase := 1
var active := true
var rng := RandomNumberGenerator.new()
var boss_sprite: Sprite2D
var boss_anim_time := 0.0
var enemy_sprite: Sprite2D
var enemy_anim_time := 0.0
var enemy_frame_base := 0
var smoke_cooldown := 0.0
var smoke_script := preload("res://scripts/smoke_puff.gd")
var pending_attack := ""
var attack_windup := 0.0
var recovery_time := 0.0
var movement_anim_clock := 0.0
var facing_left := false
var turn_cooldown := 0.0
var hitstun_time := 0.0
var knockdown_time := 0.0
var launched_chain_used := false
var boss_vulnerable_delay := 0.0
var boss_vulnerable_time := 0.0
var boss_vulnerability_armed := false

func setup(kind: String, player: Node2D) -> void:
	add_to_group("active_enemies")
	if kind == "boss": kind = "media_boss"
	enemy_type = kind
	target = player
	match kind:
		"bottle", "thrower":
			max_health = 28; speed = 46; damage = 8; points = 650; attack_range = 150
			_create_atlas_sprite("res://assets/sprites/urban_media_enemies_v3.png", 4, 4, 4, 0.18, Vector2(0, -25))
		"dres":
			max_health = 38; speed = 68; damage = 11; points = 600; attack_range = 36
			_create_atlas_sprite("res://assets/sprites/urban_media_enemies_v3.png", 4, 4, 0, 0.18, Vector2(0, -25))
		"rider":
			max_health = 48; speed = 90; damage = 15; points = 900; attack_range = 55
			_create_atlas_sprite("res://assets/sprites/combustion_rider_v3.png", 4, 2, 0, 0.19, Vector2(0, -22))
		"picker":
			max_health = 30; speed = 42; damage = 7; points = 700; attack_range = 145
			_create_forest_sprite(0)
		"dog":
			max_health = 20; speed = 115; damage = 8; points = 450; attack_range = 28
			_create_forest_sprite(4)
		"forest_boss":
			max_health = 310; speed = 48; damage = 20; points = 5500; attack_range = 82
			_create_boss_sprite("res://assets/sprites/forest_boss_v9.png", 0.205, Vector2(0, -34))
		"city_boss":
			max_health = 360; speed = 66; damage = 22; points = 7000; attack_range = 78
			_create_boss_sprite("res://assets/sprites/city_boss_v9.png", 0.205, Vector2(0, -33))
		"quad_boss":
			max_health = 440; speed = 92; damage = 25; points = 8500; attack_range = 105
			_create_boss_sprite("res://assets/sprites/quad_boss_v9.png", 0.19, Vector2(0, -26))
		"media_boss":
			max_health = 420; speed = 54; damage = 18; points = 10000; attack_range = 70
			_create_boss_sprite("res://assets/sprites/media_boss_sheet_v9.png", 0.18, Vector2(0, -28))
		"camera_helper":
			max_health = 42; speed = 54; damage = 12; points = 850; attack_range = 48
			_create_atlas_sprite("res://assets/sprites/urban_media_enemies_v3.png", 4, 4, 8, 0.18, Vector2(0, -25))
		"drone":
			max_health = 25; speed = 72; damage = 9; points = 750; attack_range = 170
			_create_atlas_sprite("res://assets/sprites/urban_media_enemies_v3.png", 4, 4, 12, 0.18, Vector2(0, -35))
		"forest_guard":
			max_health = 52; speed = 62; damage = 14; points = 950; attack_range = 46
			_create_atlas_sprite("res://assets/sprites/forest_guards_v16.png", 4, 2, 0, 0.17, Vector2(0, -29))
		"forest_guard_heavy":
			max_health = 66; speed = 52; damage = 18; points = 1200; attack_range = 49
			_create_atlas_sprite("res://assets/sprites/forest_guards_v16.png", 4, 2, 4, 0.17, Vector2(0, -29))
	health = max_health
	rng.randomize()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(target):
		velocity = velocity.move_toward(Vector2.ZERO, 600 * delta)
		move_and_slide()
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	flash_time = maxf(0.0, flash_time - delta)
	hitstun_time = maxf(0.0, hitstun_time - delta)
	knockdown_time = maxf(0.0, knockdown_time - delta)
	boss_vulnerable_delay = maxf(0.0, boss_vulnerable_delay - delta)
	if boss_vulnerable_delay <= 0.0 and boss_vulnerability_armed:
		boss_vulnerable_time = 0.72
		boss_vulnerability_armed = false
	boss_vulnerable_time = maxf(0.0, boss_vulnerable_time - delta)
	modulate = Color(1.45, 1.45, 1.45) if flash_time > 0.0 else (Color("fff0b0") if boss_vulnerable_time > 0.0 else Color.WHITE)
	if hitstun_time > 0.0 or knockdown_time > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, (420.0 if knockdown_time > 0.0 else 720.0) * delta)
		move_and_slide()
		_check_launched_enemy_collision()
		global_position.y = clampf(global_position.y, 205.0, 315.0)
		rotation = lerpf(rotation, (0.9 if facing_left else -0.9) if knockdown_time > 0.0 else 0.0, minf(1.0, delta * 12.0))
		queue_redraw()
		return
	rotation = lerpf(rotation, 0.0, minf(1.0, delta * 14.0))
	turn_cooldown = maxf(0.0, turn_cooldown - delta)
	recovery_time = maxf(0.0, recovery_time - delta)
	if attack_windup > 0.0:
		attack_windup = maxf(0.0, attack_windup - delta)
		velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		if attack_windup <= 0.0:
			_execute_pending_attack()
		move_and_slide()
		global_position.y = clampf(global_position.y, 205.0, 315.0)
		return
	special_cooldown = maxf(0.0, special_cooldown - delta)
	smoke_cooldown = maxf(0.0, smoke_cooldown - delta)
	movement_anim_clock += delta
	boss_anim_time = maxf(0.0, boss_anim_time - delta)
	if boss_sprite and boss_anim_time <= 0.0: boss_sprite.frame = 0
	enemy_anim_time = maxf(0.0, enemy_anim_time - delta)
	if absf(velocity.x) > 12.0 and turn_cooldown <= 0.0:
		var wants_left := velocity.x < 0.0
		if wants_left != facing_left:
			facing_left = wants_left
			turn_cooldown = 0.48 if _is_boss() else 0.34
	if enemy_sprite:
		enemy_sprite.flip_h = facing_left
	if boss_sprite:
		boss_sprite.flip_h = facing_left
		if boss_anim_time <= 0.0:
			boss_sprite.frame = int(movement_anim_clock * 5.0) % 2 if velocity.length() > 12.0 else 0
	if enemy_sprite and enemy_anim_time <= 0.0:
		var moving_frame := int(movement_anim_clock * (8.0 if enemy_type == "dog" else 6.0)) % 2 if velocity.length() > 12.0 else 0
		enemy_sprite.frame = enemy_frame_base + moving_frame
	var to_target := target.global_position - global_position
	var distance := to_target.length()
	var desired := Vector2.ZERO
	if enemy_type in ["thrower", "bottle", "picker", "drone"]:
		if distance > attack_range:
			desired = to_target.normalized()
		elif distance < 90:
			desired = -to_target.normalized()
		elif attack_cooldown <= 0 and recovery_time <= 0:
			_begin_attack("ranged")
	elif _is_boss():
		_boss_logic(distance, to_target, delta)
	elif distance > attack_range:
		desired = to_target.normalized()
	elif attack_cooldown <= 0 and recovery_time <= 0:
		_begin_attack("melee")
	var separation := _separation_steering()
	var desired_velocity := (desired + separation).limit_length(1.0) * speed
	var steering := 390.0 if enemy_type in ["picker", "bottle", "thrower"] else 560.0
	velocity = velocity.move_toward(desired_velocity, steering * delta)
	move_and_slide()
	if enemy_type == "rider" and active and velocity.length() > 20.0 and smoke_cooldown <= 0.0:
		_spawn_exhaust_smoke()
		smoke_cooldown = 0.16
	global_position.y = clampf(global_position.y, 205.0, 315.0)
	queue_redraw()

func _melee_attack() -> void:
	attack_cooldown = 1.15 if enemy_type != "dog" else 0.85
	recovery_time = 0.28
	_set_enemy_frame(2, 0.35)
	var to_target := target.global_position - global_position
	var target_is_in_front := (to_target.x < 0.0) == facing_left or absf(to_target.x) < 8.0
	if to_target.length() <= attack_range + 10.0 and target_is_in_front:
		attacked_player.emit(damage, global_position)

func _ranged_attack() -> void:
	attack_cooldown = 2.15 if enemy_type == "picker" else 1.85
	recovery_time = 0.38
	_set_enemy_frame(2 if enemy_type in ["bottle", "thrower", "drone"] else 1, 0.45)
	var projectile_kind := "mushroom" if enemy_type == "picker" else ("signal" if enemy_type == "drone" else "bottle")
	projectile_requested.emit(projectile_kind, global_position + Vector2(0, -24), target.global_position)
	boss_quote.emit("MUSHROOM!" if enemy_type == "picker" else ("LIVE SIGNAL!" if enemy_type == "drone" else "CATCH!"))

func _begin_attack(kind: String) -> void:
	var category := "mushroom" if enemy_type == "picker" else ("ranged" if kind == "ranged" else "melee")
	var director := target.get_parent() if is_instance_valid(target) else null
	if director and director.has_method("try_enemy_attack") and not director.try_enemy_attack(self, category):
		attack_cooldown = 0.12 + rng.randf_range(0.0, 0.16)
		return
	pending_attack = kind
	attack_windup = 0.42 if kind == "ranged" else (0.22 if enemy_type == "dog" else 0.30)
	if kind == "ranged":
		_set_enemy_frame(1 if enemy_type == "picker" else 2, attack_windup + 0.12)
	else:
		_set_enemy_frame(2, attack_windup + 0.10)

func _execute_pending_attack() -> void:
	var kind := pending_attack
	pending_attack = ""
	if kind == "ranged":
		_ranged_attack()
	elif kind == "melee":
		_melee_attack()

func _separation_steering() -> Vector2:
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("active_enemies"):
		if other == self or not is_instance_valid(other) or not other.active:
			continue
		var away: Vector2 = global_position - other.global_position
		var distance := away.length()
		if distance > 0.1 and distance < 54.0:
			push += away.normalized() * (1.0 - distance / 54.0)
	return push * 0.85

func _check_launched_enemy_collision() -> void:
	if launched_chain_used or knockdown_time <= 0.0 or absf(velocity.x) < 85.0:
		return
	for other in get_tree().get_nodes_in_group("active_enemies"):
		if other == self or not is_instance_valid(other) or not other.active or other._is_boss():
			continue
		if global_position.distance_to(other.global_position) <= 42.0:
			launched_chain_used = true
			other.take_hit(10.0, Vector2(signf(velocity.x) * 245.0, -18.0), true)
			var director := target.get_parent() if is_instance_valid(target) else null
			if director and director.has_method("_spawn_hit_effect"):
				director._spawn_hit_effect(other.global_position + Vector2(0, -18), true)
			break

func _boss_logic(distance: float, to_target: Vector2, _delta: float) -> void:
	if health <= max_health * 0.5 and phase == 1:
		phase = 2
		speed *= 1.18
		boss_phase_changed.emit(phase)
		boss_quote.emit(_boss_name() + " — PHASE TWO!")
	if recovery_time > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, 45.0)
		return
	if special_cooldown <= 0:
		var choice := rng.randi_range(0, 3 if phase == 1 else 5)
		special_cooldown = 2.55 if phase == 1 else 1.75
		_perform_boss_special(choice, distance, to_target)
	elif distance > attack_range:
		velocity = velocity.move_toward(to_target.normalized() * speed, 20)
	elif attack_cooldown <= 0 and recovery_time <= 0:
		_begin_attack("melee")

func _perform_boss_special(choice: int, distance: float, to_target: Vector2) -> void:
	if enemy_type == "forest_boss":
		match choice % 4:
			0:
				_set_boss_frame(2); boss_quote.emit("GIANT MUSHROOM!")
				projectile_requested.emit("mushroom", global_position + Vector2(0, -50), target.global_position)
			1:
				_set_boss_frame(4); boss_quote.emit("SPORE SLAM!")
				_warn_attack("spore", target.global_position, 18, 62, 0.82)
			2:
				_set_boss_frame(3); boss_quote.emit("BASKET BASH!")
				_warn_attack("bash", global_position + to_target.normalized() * 48.0, 25, 43, 0.62)
			3:
				_set_boss_frame(5); boss_quote.emit("FOREST CHARGE!")
				_warn_attack("charge", target.global_position, 22, 48, 0.78)
	elif enemy_type == "city_boss":
		match choice % 4:
			0:
				_set_boss_frame(2); boss_quote.emit("STREET WAVE!")
				projectile_requested.emit("street_wave", global_position + Vector2(0, -28), target.global_position)
				attack_cooldown = 1.4; recovery_time = 0.55
			1:
				_set_boss_frame(3); boss_quote.emit("STREET KICK!")
				_warn_attack("kick", target.global_position, 27, 42, 0.72)
			2:
				_set_boss_frame(4); boss_quote.emit("PAVEMENT SLAM!")
				_warn_attack("slam", target.global_position, 19, 70, 0.88)
			3:
				_set_boss_frame(5); boss_quote.emit("TRACKSUIT TACKLE!")
				_warn_attack("tackle", target.global_position, 24, 48, 0.78)
	elif enemy_type == "quad_boss":
		match choice % 4:
			0:
				_set_boss_frame(2); boss_quote.emit("QUAD WHEELIE!")
				_warn_attack("wheelie", target.global_position, 29, 52, 0.82)
			1:
				_set_boss_frame(3); boss_quote.emit("FLYING TIRE!")
				projectile_requested.emit("quad_tire", global_position + Vector2(0, -25), target.global_position)
				attack_cooldown = 1.5; recovery_time = 0.6
			2:
				_set_boss_frame(4); boss_quote.emit("EXHAUST BURST!")
				_warn_attack("exhaust", global_position + to_target.normalized() * 72.0, 17, 76, 0.92)
			3:
				_set_boss_frame(5); boss_quote.emit("CRUSHING JUMP!")
				_warn_attack("jump", target.global_position, 31, 58, 1.0)
	else:
		match choice:
			0:
				_set_boss_frame(1); boss_quote.emit("YOU'RE LIVE!")
				_warn_attack("broadcast", target.global_position, 14, 65, 0.88)
			1:
				_set_boss_frame(2); boss_quote.emit("LOOK INTO THE LENS!")
				projectile_requested.emit("media_wave", global_position + Vector2(0, -35), target.global_position)
			2:
				_set_boss_frame(3); boss_quote.emit("STAY ON SCRIPT!")
				_warn_attack("script", global_position + to_target.normalized() * 48.0, 22, 42, 0.66)
			3:
				_set_boss_frame(4); boss_quote.emit("CAMERA RUSH!")
				_warn_attack("rush", target.global_position, 18, 48, 0.76)
			4:
				_set_boss_frame(6); boss_quote.emit("SEND IN THE CREW!"); summon_requested.emit()
			5:
				_set_boss_frame(5); boss_quote.emit("FEEDBACK BEAM!")
				projectile_requested.emit("media_wave", global_position + Vector2(0, -35), target.global_position)

func _warn_attack(kind: String, at: Vector2, hit_damage: float, hit_radius: float, warning: float) -> void:
	attack_cooldown = warning + 0.65
	recovery_time = warning + 0.25
	boss_attack_requested.emit(kind, global_position + Vector2(0, -20), at, hit_damage, hit_radius, warning)

func _is_boss() -> bool:
	return enemy_type in ["forest_boss", "city_boss", "quad_boss", "media_boss"]

func _boss_name() -> String:
	match enemy_type:
		"forest_boss": return "MUSHROOM KING"
		"city_boss": return "TRACKSUIT KING"
		"quad_boss": return "QUAD WARLORD"
		_: return "MEDIA BOSS"

func take_hit(amount: float, knockback: Vector2, causes_knockdown := false) -> void:
	if not active: return
	if _is_boss() and boss_vulnerable_time > 0.0:
		amount *= 1.35
	health = maxf(0, health - amount)
	velocity = knockback
	flash_time = 0.14
	hitstun_time = 0.0 if _is_boss() else (0.14 if not causes_knockdown else 0.08)
	if causes_knockdown and not _is_boss():
		knockdown_time = 0.72
		launched_chain_used = false
	_set_enemy_frame(2 if enemy_type in ["picker", "dog"] else 3, 0.3)
	if health <= 0:
		active = false
		_set_enemy_frame(3, 1.0)
		if boss_sprite: boss_sprite.frame = 7
		died.emit(self, points)
		var tween := create_tween()
		tween.tween_property(self, "rotation", 1.4, 0.25)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
	queue_redraw()

func _draw() -> void:
	var color := Color("c94b45")
	match enemy_type:
		"thrower": color = Color("d58b35")
		"rider": color = Color("7e5ac8")
		"picker": color = Color("517c3a")
		"dog": color = Color("2e2522")
		"forest_boss", "city_boss", "quad_boss", "media_boss": color = Color("233a67")
	if flash_time > 0: color = Color.WHITE
	if (_is_boss() and boss_sprite) or enemy_sprite:
		pass
	elif enemy_type == "dog":
		draw_rect(Rect2(-13, -5, 26, 14), color)
		draw_circle(Vector2(14, -7), 8, color)
		draw_line(Vector2(-10, 8), Vector2(-12, 17), color, 4)
		draw_line(Vector2(8, 8), Vector2(10, 17), color, 4)
	elif enemy_type == "rider":
		draw_circle(Vector2(-16, 11), 9, Color("17191f"))
		draw_circle(Vector2(17, 11), 9, Color("17191f"))
		draw_line(Vector2(-16, 8), Vector2(17, 8), color, 5)
		draw_rect(Rect2(-5, -18, 12, 24), color)
		draw_circle(Vector2(0, -23), 7, Color("17191f"))
	else:
		var scale_factor := 1.45 if _is_boss() else 1.0
		draw_rect(Rect2(-9 * scale_factor, -22 * scale_factor, 18 * scale_factor, 31 * scale_factor), color)
		draw_circle(Vector2(0, -28 * scale_factor), 9 * scale_factor, Color("d8a276"))
		draw_line(Vector2(-5, 8), Vector2(-9, 21), color, 5 * scale_factor)
		draw_line(Vector2(5, 8), Vector2(9, 21), color, 5 * scale_factor)
		if enemy_type == "picker":
			draw_arc(Vector2(0, -34), 11, PI, TAU, 12, Color("c9413b"), 5)
		if _is_boss():
			draw_rect(Rect2(12, -24, 18, 13), Color("31343b"))
			draw_line(Vector2(-12, -16), Vector2(-30, -22), Color("6e6e75"), 4)
	var ratio := health / max_health
	var bar_width := 72.0 if _is_boss() else 42.0
	var bar_y := -72.0 if _is_boss() else -50.0
	draw_rect(Rect2(-bar_width * 0.5, bar_y, bar_width, 6), Color("21151d"))
	draw_rect(Rect2(-bar_width * 0.5 + 1, bar_y + 1, (bar_width - 2) * ratio, 4), Color("e34b55"))

func _set_boss_frame(frame_index: int) -> void:
	if boss_sprite:
		boss_sprite.frame = frame_index
		boss_anim_time = 0.8
		# The gold flash after a special is the classic punish window.
		boss_vulnerable_delay = 0.58
		boss_vulnerability_armed = true

func _create_boss_sprite(path: String, sprite_scale: float, sprite_position: Vector2) -> void:
	boss_sprite = Sprite2D.new()
	boss_sprite.texture = load(path)
	boss_sprite.hframes = 4
	boss_sprite.vframes = 2
	boss_sprite.scale = Vector2(sprite_scale, sprite_scale)
	boss_sprite.position = sprite_position
	add_child(boss_sprite)

func _create_forest_sprite(base_frame: int) -> void:
	enemy_frame_base = base_frame
	enemy_sprite = Sprite2D.new()
	enemy_sprite.texture = load("res://assets/sprites/forest_enemies_v2.png")
	enemy_sprite.hframes = 4
	enemy_sprite.vframes = 2
	enemy_sprite.frame = base_frame
	enemy_sprite.scale = Vector2(0.18, 0.18)
	enemy_sprite.position = Vector2(0, -27 if base_frame == 0 else -15)
	add_child(enemy_sprite)

func _set_enemy_frame(local_frame: int, duration: float) -> void:
	if enemy_sprite:
		enemy_sprite.frame = enemy_frame_base + local_frame
		enemy_anim_time = duration

func _create_atlas_sprite(path: String, columns: int, rows: int, base_frame: int, sprite_scale: float, sprite_position: Vector2) -> void:
	enemy_frame_base = base_frame
	enemy_sprite = Sprite2D.new()
	enemy_sprite.texture = load(path)
	enemy_sprite.hframes = columns
	enemy_sprite.vframes = rows
	enemy_sprite.frame = base_frame
	enemy_sprite.scale = Vector2(sprite_scale, sprite_scale)
	enemy_sprite.position = sprite_position
	add_child(enemy_sprite)

func _spawn_exhaust_smoke() -> void:
	var puff = smoke_script.new()
	get_parent().add_child(puff)
	var direction := signf(velocity.x) if absf(velocity.x) > 1.0 else -1.0
	puff.global_position = global_position + Vector2(-direction * 38.0, 3.0)
