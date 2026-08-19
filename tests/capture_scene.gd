extends SceneTree

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp/screenshots"))
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("res://tmp/screenshots/title_screen_v7.png")
	game.game_state = "playing"
	game.overlay.visible = false
	game.player.movement_enabled = true
	game.player.global_position = Vector2(250, 260)
	game._spawn_progression()
	await _capture_at(game, 250, "zone_forest_v3.png")
	await _capture_at(game, 1250, "zone_city_v3.png")
	await _capture_at(game, 2130, "zone_track_v3.png")
	await _capture_at(game, 2820, "zone_boss_v3.png")
	game.queue_free()
	await process_frame
	quit()

func _capture_at(game: Node, x: float, file_name: String) -> void:
	game.player.global_position = Vector2(x, 260)
	game.player.get_node("Camera2D").reset_smoothing()
	game._spawn_progression()
	await process_frame
	await process_frame
	var image := root.get_viewport().get_texture().get_image()
	image.save_png("res://tmp/screenshots/" + file_name)
