extends Sprite2D

var age := 0.0
var dust_mode := false
var drift := Vector2.ZERO

func setup_dust(direction: float, intensity := 1.0) -> void:
	dust_mode = true
	drift = Vector2(-direction * 22.0, -8.0) * intensity
	scale = Vector2.ONE * intensity

func _ready() -> void:
	add_to_group("exhaust_smoke")
	if dust_mode: add_to_group("skid_dust")
	texture = load("res://assets/sprites/combustion_rider_v3.png")
	hframes = 4
	vframes = 2
	frame = 4
	scale *= Vector2(0.14, 0.11) if dust_mode else Vector2(0.11, 0.11)
	z_index = -1
	if dust_mode: modulate = Color("c9a66b")

func _process(delta: float) -> void:
	age += delta
	frame = 4 + mini(3, int(age / 0.12))
	modulate.a = clampf(1.0 - age / 0.58, 0.0, 1.0)
	position += (drift if dust_mode else Vector2(0.0, -9.0)) * delta
	if age >= 0.58: queue_free()
