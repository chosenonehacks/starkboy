class_name SupplyPickup
extends Area2D

signal collected(kind: String, amount: float)

const SHEET := preload("res://assets/sprites/supply_pickups_v10.png")
var kind := "health"
var player: StarkBoyPlayer
var sprite: Sprite2D
var age := 0.0
var base_y := 0.0
var taken := false

func setup(target: StarkBoyPlayer, pickup_kind: String) -> void:
	player = target
	kind = pickup_kind
	add_to_group("random_supply_pickup")
	sprite = Sprite2D.new()
	sprite.texture = SHEET
	sprite.region_enabled = true
	sprite.scale = Vector2(0.17, 0.17)
	add_child(sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 25.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	base_y = position.y
	_update_frame(0)

func _process(delta: float) -> void:
	age += delta
	position.y = base_y + sin(age * 3.3) * 3.0
	_update_frame(int(age * 6.0) % 4)
	if not taken and is_instance_valid(player) and global_position.distance_to(player.global_position) < 34.0:
		_collect()

func _update_frame(frame: int) -> void:
	if sprite == null: return
	var cell_w := 443.0
	var cell_h := 443.0
	var row := 0 if kind == "health" else 1
	sprite.region_rect = Rect2(frame * cell_w, row * cell_h, cell_w, cell_h)

func _on_body_entered(body: Node) -> void:
	if body == player: _collect()

func _collect() -> void:
	if taken or not is_instance_valid(player): return
	taken = true
	monitoring = false
	var amount := 30.0 if kind == "health" else 40.0
	if kind == "health": player.heal(amount)
	else: player.recharge_battery(amount)
	collected.emit(kind, amount)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.18)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)
