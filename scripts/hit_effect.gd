extends Node2D

var age := 0.0
var lifetime := 0.22
var heavy := false
var player_damage := false
var sprite: Sprite2D

func setup(is_heavy: bool, is_player_damage := false) -> void:
	heavy = is_heavy
	player_damage = is_player_damage
	lifetime = 0.36 if player_damage else (0.3 if heavy else 0.24)
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/sprites/combat_vfx_v4.png")
	sprite.hframes = 4
	sprite.vframes = 2
	sprite.frame = 4 if player_damage else 0
	sprite.scale = Vector2(0.16 if player_damage else (0.14 if heavy else 0.1), 0.16 if player_damage else (0.14 if heavy else 0.1))
	add_child(sprite)
	queue_redraw()

func _process(delta: float) -> void:
	age += delta
	if sprite:
		var base := 4 if player_damage else 0
		sprite.frame = base + mini(3, int(age / (lifetime / 4.0)))
	if age >= lifetime:
		queue_free()

func _draw() -> void:
	pass
