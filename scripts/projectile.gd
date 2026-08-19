extends Node2D

var kind := "mushroom"
var velocity := Vector2.ZERO
var damage := 8.0
var target: Node
var age := 0.0
var sprite: Sprite2D
const BOSS_EFFECTS := preload("res://assets/sprites/boss_attacks_v15.png")
var frame_base := 0

func setup(projectile_kind: String, origin: Vector2, target_position: Vector2, player: Node) -> void:
	add_to_group("visible_projectiles")
	kind = projectile_kind
	target = player
	global_position = origin
	var travel_speed := 185.0 if kind == "mushroom" else (225.0 if kind == "bottle" else (205.0 if kind == "quad_tire" else 255.0))
	velocity = (target_position - origin).normalized() * travel_speed
	damage = 7.0 if kind == "mushroom" else (9.0 if kind == "bottle" else (18.0 if kind in ["street_wave", "quad_tire", "media_wave"] else 8.0))
	if kind in ["mushroom", "bottle"]:
		sprite = Sprite2D.new()
		sprite.texture = load("res://assets/sprites/projectiles_v3.png")
		sprite.hframes = 4
		sprite.vframes = 2
		sprite.frame = 0 if kind == "mushroom" else 4
		sprite.scale = Vector2(0.105, 0.105)
		add_child(sprite)
	elif kind in ["street_wave", "quad_tire", "media_wave"]:
		sprite = Sprite2D.new()
		sprite.texture = BOSS_EFFECTS
		sprite.hframes = 4
		sprite.vframes = 4
		frame_base = 4 if kind == "street_wave" else (8 if kind == "quad_tire" else 12)
		sprite.frame = frame_base
		sprite.scale = Vector2(0.18, 0.18)
		sprite.flip_h = velocity.x < 0.0 and kind != "quad_tire"
		add_child(sprite)
	queue_redraw()

func _physics_process(delta: float) -> void:
	age += delta
	global_position += velocity * delta
	if sprite:
		var base := frame_base if kind in ["street_wave", "quad_tire", "media_wave"] else (0 if kind == "mushroom" else 4)
		sprite.frame = base + (int(age * 10.0) % (4 if kind in ["street_wave", "quad_tire", "media_wave"] else 3))
		if kind in ["mushroom", "bottle", "quad_tire"]: sprite.rotation += delta * 2.5
	if is_instance_valid(target) and global_position.distance_to(target.global_position) < 24.0:
		target.take_damage(damage, global_position - velocity.normalized() * 15.0)
		if sprite and kind == "bottle":
			sprite.frame = 7
			velocity = Vector2.ZERO
			var tween := create_tween()
			tween.tween_interval(0.12)
			tween.tween_callback(queue_free)
		else:
			queue_free()
	if age > 3.0 or global_position.x < 0 or global_position.x > 3200:
		queue_free()
	queue_redraw()

func _draw() -> void:
	if kind == "signal":
		var pulse := 7.0 + sin(age * 18.0) * 2.0
		draw_circle(Vector2.ZERO, pulse, Color(0.2, 0.9, 1.0, 0.85))
		draw_arc(Vector2.ZERO, pulse + 5.0, 0, TAU, 16, Color(1, 1, 1, 0.75), 2)
