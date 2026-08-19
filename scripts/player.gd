class_name StarkBoyPlayer
extends CharacterBody2D

signal stats_changed(health: float, battery: float, ammo: int, mounted: bool)
signal action_message(text: String)
signal attack_requested(kind: String, origin: Vector2, direction: float)
signal defeated
signal damaged(at_position: Vector2)

const RIDE_SPEED := 220.0
const WALK_SPEED := 115.0
const RIDE_ACCELERATION := 560.0
const WALK_ACCELERATION := 820.0
const RIDE_FRICTION := 720.0
const WALK_FRICTION := 980.0
const WHEELIE_BATTERY_COST := 24.0
const WHEELIE_SPEED := 360.0
const JAB_COMBO_WINDOW := 0.34
const NORMAL_SHEET := preload("res://assets/sprites/starkboy_sheet.png")
const GUN_SHEET := preload("res://assets/sprites/starkboy_gun_v5.png")
const WALK_SHEET := preload("res://assets/sprites/starkboy_walk_v6.png")
const PARKED_BIKE_TEXTURE := preload("res://assets/sprites/parked_starkboy_bike_v11.png")
const CHARGER_TEXTURE := preload("res://assets/sprites/stark_charger_v12.png")
const SMOKE_PUFF_SCRIPT := preload("res://scripts/smoke_puff.gd")

var health := 100.0
var battery := 100.0
var ammo := 6
var mounted := true
var infinite_health := false
var infinite_ammo := false
var infinite_battery := false
var facing := 1.0
var action_time := 0.0
var dodge_time := 0.0
var flash_time := 0.0
var invulnerable_time := 0.0
var respawn_flash_time := 0.0
var movement_enabled := false
var min_x := 30.0
var max_x := 3170.0
var current_action := "idle"
var sprite_base_position := Vector2(0, -18)
var dodge_velocity := Vector2.ZERO
var wheelie_velocity := Vector2.ZERO
var skid_velocity := Vector2.ZERO
var jab_combo_time := 0.0
var parked_bike: Sprite2D
var charger_sprite: Sprite2D
var charger_cable: Line2D
var charger_energy: Line2D
var charge_visual_time := 0.0
var parked_bike_position := Vector2.ZERO
var bike_color := Color("d72b32")
var bike_paint_material: ShaderMaterial
const MOUNT_DISTANCE := 62.0

func _ready() -> void:
	_set_bike_paint_material()
	queue_redraw()
	stats_changed.emit(health, battery, ammo, mounted)

func _physics_process(delta: float) -> void:
	action_time = maxf(0.0, action_time - delta)
	jab_combo_time = maxf(0.0, jab_combo_time - delta)
	if action_time <= 0.0 and dodge_time <= 0.0:
		current_action = "idle"
	dodge_time = maxf(0.0, dodge_time - delta)
	flash_time = maxf(0.0, flash_time - delta)
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	respawn_flash_time = maxf(0.0, respawn_flash_time - delta)
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down") if movement_enabled else Vector2.ZERO
	var speed := RIDE_SPEED if mounted else WALK_SPEED
	if input_vector.length() > 1.0: input_vector = input_vector.normalized()
	var target := input_vector * speed
	var acceleration := RIDE_ACCELERATION if mounted else WALK_ACCELERATION
	var friction := RIDE_FRICTION if mounted else WALK_FRICTION
	var rate := acceleration if input_vector.length_squared() > 0.0 else friction
	if current_action == "wheelie" and action_time > 0.0:
		velocity = wheelie_velocity
	elif current_action == "jab_combo" and mounted and action_time > 0.0:
		velocity = skid_velocity
	elif dodge_time > 0.0:
		velocity = dodge_velocity
	else:
		velocity = velocity.move_toward(target, rate * delta)
	if absf(input_vector.x) > 0.1:
		facing = signf(input_vector.x)
	move_and_slide()
	if current_action == "wheelie" and action_time > 0.0:
		# Recheck the hitbox along the whole charge, not only where wheelie began.
		attack_requested.emit("wheelie_active", global_position, facing)
	global_position.x = clampf(global_position.x, min_x, max_x)
	global_position.y = clampf(global_position.y, 205.0, 315.0)
	if movement_enabled:
		_handle_actions()
	_update_battery(delta, input_vector)
	_update_charger_visual(delta)
	_update_sprite(input_vector)
	queue_redraw()

func _update_sprite(input_vector: Vector2) -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null: return
	var walking_on_foot := not mounted and current_action == "idle" and input_vector.length() > 0.15
	sprite.material = bike_paint_material if mounted else null
	sprite.texture = GUN_SHEET if current_action == "shoot" else (WALK_SHEET if walking_on_foot else NORMAL_SHEET)
	sprite.hframes = 4
	sprite.vframes = 2 if current_action == "shoot" else (1 if walking_on_foot else 3)
	sprite.scale = Vector2(0.115, 0.115) if walking_on_foot else Vector2(0.24, 0.24)
	sprite.flip_h = facing < 0
	sprite.modulate.a = (0.28 if int(respawn_flash_time * 12.0) % 2 == 0 else 1.0) if respawn_flash_time > 0.0 else 1.0
	sprite.position = sprite_base_position
	sprite.rotation = 0.0
	if mounted:
		match current_action:
			"quick": sprite.frame = 4
			"jab_combo":
				sprite.frame = 5
				var combo_progress := clampf((0.46 - action_time) / 0.46, 0.0, 1.0)
				var skid_curve := sin(combo_progress * PI)
				sprite.position.x -= skid_curve * 13.0 * facing
				sprite.position.y += skid_curve * 7.0
				sprite.rotation = skid_curve * 0.38 * facing
				sprite.scale.y *= 0.92
			"shoot":
				sprite.frame = _gun_animation_frame()
				sprite.position.x += 7.0 * facing
			"wheelie":
				sprite.frame = 6
				sprite.position.y -= 8.0
				sprite.rotation = -0.08 * facing
			"dodge":
				sprite.frame = 7
				sprite.position.x += 9.0 * facing
				sprite.position.y += 2.0
				sprite.rotation = 0.035 * facing
			_:
				if input_vector.length() > 0.15:
					sprite.frame = 1 + (int(Time.get_ticks_msec() / 110) % 3)
					sprite.position.y += sin(Time.get_ticks_msec() * 0.018) * 1.5
				else:
					sprite.frame = 0
	else:
		match current_action:
			"quick":
				sprite.frame = 9
				sprite.position.x += 5.0 * facing
			"jab_combo":
				sprite.frame = 10
				sprite.position.x += 11.0 * facing
				sprite.rotation = -0.12 * facing
			"shoot":
				sprite.frame = 4 + _gun_animation_frame()
				sprite.position.x += 7.0 * facing
			"heavy":
				sprite.frame = 10
				sprite.position.x += 8.0 * facing
			"dodge":
				sprite.frame = 11
				sprite.position.y += 4.0
			_:
				if walking_on_foot:
					sprite.frame = int(Time.get_ticks_msec() / 115) % 4
					sprite.position.y = -21.0
				else:
					sprite.frame = 8

func _gun_animation_frame() -> int:
	var progress := clampf((0.36 - action_time) / 0.36, 0.0, 0.999)
	return mini(3, int(progress * 4.0))

func _handle_actions() -> void:
	if Input.is_action_just_pressed("dismount"):
		if mounted and velocity.length() > 18.0:
			action_message.emit("STOP TO DISMOUNT")
		elif mounted:
			mounted = false
			parked_bike_position = global_position
			_show_parked_bike()
			global_position.x += 38.0 * facing
			action_message.emit("ON FOOT")
			stats_changed.emit(health, battery, ammo, mounted)
		elif global_position.distance_to(parked_bike_position) <= MOUNT_DISTANCE:
			mounted = true
			global_position = parked_bike_position
			_hide_parked_bike()
			action_message.emit("MOUNTED")
			stats_changed.emit(health, battery, ammo, mounted)
		else:
			action_message.emit("GET CLOSER TO YOUR BIKE")
	if Input.is_action_just_pressed("quick_attack"):
		_try_quick_attack()
	if Input.is_action_just_pressed("heavy_attack") and action_time <= 0.0:
		_try_heavy_attack()
	if Input.is_action_just_pressed("shoot") and action_time <= 0.0:
		if ammo > 0:
			if not infinite_ammo: ammo -= 1
			action_time = 0.36
			current_action = "shoot"
			action_message.emit("BANG!")
			attack_requested.emit("shoot", global_position, facing)
		else:
			action_message.emit("CLICK — NO AMMO")
		stats_changed.emit(health, battery, ammo, mounted)
	if Input.is_action_just_pressed("dodge") and dodge_time <= 0.0:
		if not mounted or battery >= 8.0:
			if mounted and not infinite_battery:
				battery -= 8.0
			dodge_time = 0.28
			current_action = "dodge"
			if mounted:
				dodge_velocity = Vector2(facing * 355.0, 0.0)
			else:
				var foot_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
				if foot_direction.length_squared() < 0.1: foot_direction = Vector2(facing, 0)
				dodge_velocity = foot_direction.normalized() * 245.0
			action_message.emit("DODGE")
			stats_changed.emit(health, battery, ammo, mounted)

func _try_quick_attack() -> void:
	if jab_combo_time > 0.0 and current_action == "quick":
		jab_combo_time = 0.0
		action_time = 0.46
		current_action = "jab_combo"
		if mounted:
			skid_velocity = Vector2(facing * 165.0, 58.0)
			_spawn_skid_dust()
		action_message.emit("REAR-WHEEL COMBO!" if mounted else "JAB COMBO!")
		attack_requested.emit("jab_combo_ride" if mounted else "jab_combo", global_position, facing)
	elif action_time <= 0.0:
		action_time = 0.22
		jab_combo_time = JAB_COMBO_WINDOW
		current_action = "quick"
		action_message.emit("RIDE-BY PUNCH" if mounted else "QUICK PUNCH")
		attack_requested.emit("quick_ride" if mounted else "quick", global_position, facing)

func _spawn_skid_dust() -> void:
	for index in range(4):
		var puff = SMOKE_PUFF_SCRIPT.new()
		puff.setup_dust(facing, 0.78 + index * 0.12)
		get_parent().add_child(puff)
		puff.global_position = global_position + Vector2(-facing * (25.0 + index * 8.0), 10.0 + index * 2.0)

func _try_heavy_attack() -> void:
	if mounted:
		if battery >= WHEELIE_BATTERY_COST:
			if not infinite_battery: battery -= WHEELIE_BATTERY_COST
			action_time = 0.48
			current_action = "wheelie"
			wheelie_velocity = Vector2(facing * WHEELIE_SPEED, 0.0)
			action_message.emit("WHEELIE!")
			attack_requested.emit("wheelie", global_position, facing)
		else:
			action_message.emit("LOW BATTERY")
	else:
		action_time = 0.48
		current_action = "heavy"
		action_message.emit("HEAVY KICK")
		attack_requested.emit("heavy", global_position, facing)
	stats_changed.emit(health, battery, ammo, mounted)

func _update_battery(delta: float, input_vector: Vector2) -> void:
	if infinite_battery: return
	var old_battery := battery
	if mounted and input_vector.length() > 0.75:
		battery = maxf(0.0, battery - delta * 2.5)
	elif not mounted:
		# The parked electric bike charges while StarkBoy continues on foot.
		battery = minf(100.0, battery + delta * 8.0)
	if int(old_battery) != int(battery):
		stats_changed.emit(health, battery, ammo, mounted)

func _show_parked_bike() -> void:
	if not is_instance_valid(parked_bike):
		parked_bike = Sprite2D.new()
		parked_bike.name = "ParkedBike"
		parked_bike.texture = PARKED_BIKE_TEXTURE
		parked_bike.scale = Vector2(0.085, 0.085)
		parked_bike.position = Vector2(0, -18)
		add_child(parked_bike)
	parked_bike.material = bike_paint_material
	parked_bike.top_level = true
	parked_bike.global_position = parked_bike_position + Vector2(0, -18)
	parked_bike.flip_h = facing < 0.0
	parked_bike.visible = true
	_show_charger()

func set_bike_color(color: Color) -> void:
	bike_color = color
	_set_bike_paint_material()
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite and mounted: sprite.material = bike_paint_material
	if is_instance_valid(parked_bike): parked_bike.material = bike_paint_material

func _set_bike_paint_material() -> void:
	if bike_paint_material == null:
		var paint_shader := Shader.new()
		paint_shader.code = """
shader_type canvas_item;
uniform vec4 bike_color : source_color = vec4(0.84, 0.17, 0.20, 1.0);
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	float red_paint = smoothstep(0.08, 0.28, pixel.r - max(pixel.g, pixel.b));
	float brightness = max(pixel.r, max(pixel.g, pixel.b));
	vec3 painted = bike_color.rgb * (0.48 + brightness * 0.72);
	COLOR = vec4(mix(pixel.rgb, painted, red_paint), pixel.a);
}
"""
		bike_paint_material = ShaderMaterial.new()
		bike_paint_material.shader = paint_shader
	bike_paint_material.set_shader_parameter("bike_color", bike_color)

func _hide_parked_bike() -> void:
	if is_instance_valid(parked_bike): parked_bike.visible = false
	if is_instance_valid(charger_sprite): charger_sprite.visible = false
	if is_instance_valid(charger_cable): charger_cable.visible = false
	if is_instance_valid(charger_energy): charger_energy.visible = false

func _show_charger() -> void:
	var charger_position := parked_bike_position + Vector2(-68.0 if facing > 0.0 else 68.0, 7.0)
	if not is_instance_valid(charger_sprite):
		charger_sprite = Sprite2D.new()
		charger_sprite.name = "PortableCharger"
		charger_sprite.texture = CHARGER_TEXTURE
		charger_sprite.scale = Vector2(0.055, 0.055)
		add_child(charger_sprite)
		charger_sprite.top_level = true
	if not is_instance_valid(charger_cable):
		charger_cable = Line2D.new()
		charger_cable.name = "ChargingCable"
		charger_cable.width = 5.0
		charger_cable.default_color = Color("17151f")
		charger_cable.z_index = -1
		charger_cable.antialiased = false
		add_child(charger_cable)
		charger_cable.top_level = true
	if not is_instance_valid(charger_energy):
		charger_energy = Line2D.new()
		charger_energy.name = "ChargingEnergy"
		charger_energy.width = 2.0
		charger_energy.default_color = Color("ffd52a")
		charger_energy.z_index = -1
		charger_energy.antialiased = false
		add_child(charger_energy)
		charger_energy.top_level = true
	charger_sprite.global_position = charger_position + Vector2(0, -22)
	charger_sprite.flip_h = facing < 0.0
	charger_sprite.visible = true
	charger_cable.global_position = Vector2.ZERO
	charger_energy.global_position = Vector2.ZERO
	var cable_start := charger_position + Vector2(22.0 * facing, -9.0)
	var cable_end := parked_bike_position + Vector2(-8.0 * facing, -5.0)
	var cable_points := PackedVector2Array([cable_start, Vector2(lerpf(cable_start.x, cable_end.x, 0.5), maxf(cable_start.y, cable_end.y) + 13.0), cable_end])
	charger_cable.points = cable_points
	charger_energy.points = cable_points
	charger_cable.visible = true
	charger_energy.visible = true

func _update_charger_visual(delta: float) -> void:
	if mounted or not is_instance_valid(charger_energy) or not charger_energy.visible: return
	charge_visual_time += delta
	var pulse := 0.58 + sin(charge_visual_time * 9.0) * 0.32
	charger_energy.default_color = Color(1.0, 0.72 + pulse * 0.2, 0.05, pulse)
	if is_instance_valid(charger_sprite):
		charger_sprite.modulate = Color(1.0, 1.0, 0.88 + pulse * 0.12, 1.0)

func _draw() -> void:
	if has_node("Sprite2D"):
		return
	var flip := facing
	if mounted:
		draw_circle(Vector2(-15.0 * flip, 11), 9, Color("17191f"))
		draw_circle(Vector2(17.0 * flip, 11), 9, Color("17191f"))
		draw_line(Vector2(-15 * flip, 10), Vector2(7 * flip, -1), Color("d72b32"), 5)
		draw_line(Vector2(7 * flip, -1), Vector2(17 * flip, 10), Color("d72b32"), 4)
		draw_rect(Rect2(-7, -19, 13, 22), Color("242832"))
		draw_circle(Vector2(1, -22), 7, Color("111319"))
	else:
		draw_rect(Rect2(-7, -18, 14, 25), Color("242832"))
		draw_circle(Vector2(0, -23), 7, Color("111319"))
		draw_line(Vector2(-3, 7), Vector2(-7, 20), Color("242832"), 5)
		draw_line(Vector2(3, 7), Vector2(7, 20), Color("242832"), 5)
	if action_time > 0.0:
		draw_arc(Vector2(18 * flip, -7), 13, -1.2, 1.2, 12, Color("ffd166"), 3)

func take_damage(amount: float, from_position: Vector2) -> void:
	if invulnerable_time > 0.0 or (current_action == "wheelie" and action_time > 0.0):
		return
	if not infinite_health:
		health = maxf(0.0, health - amount)
	invulnerable_time = 0.8
	current_action = "hurt"
	damaged.emit(global_position + Vector2(0, -14))
	velocity = (global_position - from_position).normalized() * 240.0
	action_message.emit("OUCH!")
	stats_changed.emit(health, battery, ammo, mounted)
	if health <= 0.0:
		defeated.emit()

func respawn(at_position: Vector2) -> void:
	global_position = at_position
	if not mounted:
		parked_bike_position = at_position
		_show_parked_bike()
	health = 100.0
	battery = maxf(battery, 50.0)
	ammo = maxi(ammo, 3)
	velocity = Vector2.ZERO
	invulnerable_time = 2.0
	respawn_flash_time = 2.0
	action_time = 0.0
	dodge_time = 0.0
	current_action = "idle"
	stats_changed.emit(health, battery, ammo, mounted)

func add_ammo(amount: int) -> void:
	ammo = mini(6, ammo + amount)
	stats_changed.emit(health, battery, ammo, mounted)

func heal(amount: float) -> void:
	health = minf(100.0, health + amount)
	stats_changed.emit(health, battery, ammo, mounted)

func recharge_battery(amount: float) -> void:
	battery = minf(100.0, battery + amount)
	stats_changed.emit(health, battery, ammo, mounted)
