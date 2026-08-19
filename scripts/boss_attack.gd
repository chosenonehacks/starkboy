class_name BossAttack
extends Node2D

var kind := "impact"
var target: Node2D
var damage := 20.0
var radius := 55.0
var windup := 0.75
var age := 0.0
var resolved := false
var effect_sprite: Sprite2D
var start_position := Vector2.ZERO
var destination := Vector2.ZERO
var stationary_growth := false
const EFFECTS := preload("res://assets/sprites/boss_attacks_v15.png")

func setup(attack_kind: String, origin: Vector2, target_position: Vector2, player: Node2D, hit_damage: float, hit_radius: float, travel_time: float) -> void:
	kind = attack_kind
	start_position = origin
	destination = target_position
	stationary_growth = kind in ["spore", "bash", "charge"]
	global_position = destination if stationary_growth else start_position
	target = player
	damage = hit_damage
	radius = hit_radius
	windup = travel_time
	add_to_group("boss_attack_telegraph")
	effect_sprite = Sprite2D.new()
	effect_sprite.texture = EFFECTS
	effect_sprite.hframes = 4
	effect_sprite.vframes = 4
	effect_sprite.scale = Vector2(0.22, 0.22)
	effect_sprite.position.y = -24.0
	add_child(effect_sprite)
	var row := _effect_row()
	effect_sprite.frame = row * 4
	effect_sprite.flip_h = not stationary_growth and destination.x < start_position.x and row in [1, 3]

func _physics_process(delta: float) -> void:
	age += delta
	var progress := clampf(age / windup, 0.0, 1.0)
	if not stationary_growth and not resolved:
		global_position = start_position.lerp(destination, ease(progress, 0.72))
	if effect_sprite:
		var row := _effect_row()
		effect_sprite.frame = row * 4 + (int(age * 11.0) % 4 if not stationary_growth else mini(3, int(clampf(age / windup, 0.0, 0.999) * 4.0)))
		effect_sprite.modulate.a = 1.0 if not resolved else maxf(0.0, 1.0 - (age - windup) / 0.22)
	if not resolved and age >= windup:
		resolved = true
		if is_instance_valid(target) and target.global_position.distance_to(global_position) <= radius:
			target.take_damage(damage, global_position)
	if age >= windup + 0.22: queue_free()

func _effect_row() -> int:
	if kind in ["spore", "bash", "charge"]: return 0
	if kind in ["combo", "kick", "slam", "tackle"]: return 1
	if kind in ["wheelie", "slide", "exhaust", "jump"]: return 2
	return 3
