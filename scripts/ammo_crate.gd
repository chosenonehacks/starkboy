class_name AmmoCrate
extends Area2D

signal collected(amount: int)

const CRATE_SHEET := preload("res://assets/sprites/ammo_crate_v5.png")

var player: StarkBoyPlayer
var age := 0.0
var opened := false
var open_time := 0.0
var sprite: Sprite2D

func setup(target: StarkBoyPlayer) -> void:
	player = target

func _ready() -> void:
	add_to_group("ammo_crate")
	sprite = Sprite2D.new()
	sprite.texture = CRATE_SHEET
	sprite.hframes = 4
	sprite.vframes = 1
	sprite.frame = 0
	sprite.scale = Vector2(0.18, 0.18)
	sprite.position = Vector2(0, -18)
	add_child(sprite)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(46, 34)
	shape.shape = rectangle
	shape.position = Vector2(0, -8)
	add_child(shape)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	age += delta
	if not opened:
		sprite.position.y = -18.0 + sin(age * 3.0) * 1.5
		if is_instance_valid(player) and global_position.distance_to(player.global_position) < 43.0:
			_collect()
	else:
		open_time += delta
		sprite.frame = mini(3, 1 + int(open_time / 0.11))
		if open_time >= 0.55:
			queue_free()

func _on_body_entered(body: Node) -> void:
	if body == player:
		_collect()

func _collect() -> void:
	if opened: return
	opened = true
	monitoring = false
	collected.emit(3)
