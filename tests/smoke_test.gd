extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	check(scene != null, "main scene loads")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var player = game.get_node("Player")
	var hud = game.get_node("HUD")
	check(player != null and hud != null, "player and HUD exist")
	check(game.has_node("WorldBackground"), "pixel-art world panorama is present")
	check(game.title_art.visible and game.title_art.texture.resource_path.ends_with("title_forest_ride_v7.png"), "title screen uses dedicated forest ride pixel art")
	check(game.game_logo.visible and game.game_logo.texture.resource_path.ends_with("starkboy_logo_v8.png") and not game.overlay_title.visible, "title screen uses dedicated electric pixel-art logo")
	check(game.overlay_body.get_theme_font("font").resource_path.ends_with("Oxanium.ttf"), "modern Oxanium font is applied through the project UI theme")
	check(player.mounted and player.battery == 100.0 and player.ammo == 6, "initial ride stats")
	check(game.music.music_mode == "menu" and game.music.music_enabled and game.music.volume_db == -12.0, "title starts with an audible 8-bit menu theme")
	game.game_state = "playing"
	game._update_music_mode()
	check(game.music.music_mode == "game", "gameplay switches to the faster dynamic 8-bit theme")
	check(not game.music.toggle_music() and game.music.volume_db <= -80.0, "M can mute music")
	check(game.music.toggle_music() and game.music.volume_db == -12.0, "M can restore music at the full mix volume")
	game.game_state = "title"
	game._update_music_mode()
	game.game_state = "bike_select"
	game.bike_color_index = 1
	game._show_bike_selection()
	check("WHITE" in game.overlay_body.text, "startup flow offers the white motorcycle")
	check(player.bike_color.is_equal_approx(Color("edf1f2")), "selected motorcycle paint is applied to the rider sprite")
	check(game.bike_preview.visible and game.bike_preview.texture.resource_path.ends_with("starkboy_sheet.png"), "color selection displays a large live motorcycle preview")
	check(game.overlay_body.z_index > game.bike_preview.z_index, "bike selection instructions render above and below the motorcycle preview")
	hud.play_menu_sfx()
	check(hud.sfx_player.stream != null, "changing a menu option plays an arcade selection sound")
	hud.play_menu_sfx(true)
	check(hud.sfx_player.playing, "confirming a menu option plays a confirmation sound")
	game.game_state = "intro"
	check(game._go_back_menu() and game.game_state == "bike_select", "Escape returns from intro to motorcycle selection")
	check(game._go_back_menu() and game.game_state == "title", "Escape returns from motorcycle selection to title")
	game.game_state = "playing"
	game._open_pause_menu()
	check(game.game_state == "paused" and paused and "MAIN MENU" in game.overlay_body.text and "EXIT GAME" in game.overlay_body.text, "Escape opens pause menu with resume, main menu and exit options")
	game._resume_game()
	check(game.game_state == "playing" and not paused, "Escape resumes gameplay from pause menu")
	game.game_state = "title"
	game.bike_color_index = 2
	game._show_bike_selection()
	check("FOREST GREY" in game.overlay_body.text and player.bike_color.is_equal_approx(Color("68726d")), "startup flow offers Forest Grey paint")
	game.bike_color_index = 0
	game._show_bike_selection()
	check(player.bike_color.is_equal_approx(Color("d72b32")), "red remains the default motorcycle color")
	game.game_state = "title"
	game._show_title()
	hud._toggle_code_console(true)
	check(hud.code_entry.visible and hud.code_entry.has_focus(), "tilde code console opens in the upper-left corner")
	game._on_cheat_code_submitted("alpha 1")
	player.health = 70.0
	player.invulnerable_time = 0.0
	player.take_damage(20.0, player.global_position + Vector2.LEFT)
	check(player.health == 70.0, "alpha 1 enables infinite health")
	game._on_cheat_code_submitted("alpha 0")
	check(not player.infinite_health, "alpha 0 disables infinite health")
	game._on_cheat_code_submitted("hunter 1")
	player.ammo = 2
	check(player.infinite_ammo, "hunter 1 enables infinite ammunition")
	game._on_cheat_code_submitted("hunter 0")
	check(not player.infinite_ammo, "hunter 0 disables infinite ammunition")
	player.battery = 47.0
	game._on_cheat_code_submitted("energy 1")
	player._update_battery(3.0, Vector2.RIGHT)
	check(player.infinite_battery and player.battery == 47.0, "energy 1 holds the current battery level")
	game._on_cheat_code_submitted("energy 0")
	check(not player.infinite_battery, "energy 0 restores normal battery behavior")
	player.health = 100.0
	player.invulnerable_time = 0.0
	player.battery = 100.0
	player.battery = 50.0
	player.mounted = true
	player._update_battery(1.0, Vector2.ZERO)
	check(player.battery == 50.0, "battery never charges while StarkBoy remains mounted")
	player.battery = 100.0
	player.facing = 1.0
	player.action_time = 0.0
	player._try_heavy_attack()
	check(player.current_action == "wheelie" and player.battery == 76.0, "wheelie consumes 24 battery")
	check(player.wheelie_velocity.x == player.WHEELIE_SPEED, "wheelie launches StarkBoy forward")
	player.invulnerable_time = 0.0
	var wheelie_health: float = player.health
	player.take_damage(20.0, player.global_position + Vector2.LEFT)
	check(player.health == wheelie_health, "wheelie grants immunity for the full attack")
	player.current_action = "idle"
	player.action_time = 0.0
	player._try_quick_attack()
	player._try_quick_attack()
	check(player.current_action == "jab_combo" and player.action_time == 0.46, "two rapid jabs trigger the combo finisher")
	check(player.skid_velocity.x == player.facing * 165.0, "mounted combo performs a sideways rear-wheel skid")
	check(get_nodes_in_group("skid_dust").size() == 4, "mounted combo throws a visible four-puff dust cloud")
	player.current_action = "idle"
	player.action_time = 0.0
	player.mounted = false
	player.battery = 50.0
	player.parked_bike_position = player.global_position
	player._show_parked_bike()
	player._update_battery(1.0, Vector2.ZERO)
	check(player.battery == 58.0 and player.parked_bike.visible, "battery charges only while the bike is parked at the dismount position")
	check(player.charger_sprite.visible and player.charger_sprite.texture.resource_path.ends_with("stark_charger_v12.png"), "dismount shows the pixel-art charger based on the supplied reference")
	check(player.charger_cable.visible and player.charger_cable.points.size() == 3, "visible charging cable connects the charger to the parked Stark bike")
	player.global_position += Vector2(100, 0)
	check(player.global_position.distance_to(player.parked_bike_position) > player.MOUNT_DISTANCE, "StarkBoy must return to the parked bike before mounting")
	player.global_position = player.parked_bike_position
	player.mounted = true
	player._hide_parked_bike()
	check(not player.charger_sprite.visible and not player.charger_cable.visible, "charger and cable disappear after mounting")
	player.battery = 100.0
	check(hud.health_bar.get_theme_stylebox("fill").bg_color.r > 0.8 and hud.health_bar.get_theme_stylebox("fill").bg_color.g < 0.2, "hero health uses a red HUD bar")
	check(hud.battery_bar.get_theme_stylebox("fill").bg_color.r > 0.8 and hud.battery_bar.get_theme_stylebox("fill").bg_color.g > 0.6, "battery uses a yellow HUD bar")
	check(hud.bullet_nodes.size() == 6 and hud.ammo_label.text == "AMMO", "ammo count is represented by six cartridge icons")
	player.health = 55.0
	var medkit = game._spawn_supply_pickup("health", player.global_position + Vector2(10, 0))
	medkit._collect()
	check(player.health == 85.0 and medkit.sprite.texture.resource_path.ends_with("supply_pickups_v10.png"), "animated red-cross medkit restores health")
	player.battery = 35.0
	var drink = game._spawn_supply_pickup("energy", player.global_position + Vector2(10, 0))
	drink._collect()
	check(player.battery == 75.0, "animated electric energy drink restores battery")
	game.supply_spawn_chance = 0.0
	var crates: Array[Node] = get_nodes_in_group("ammo_crate")
	check(crates.size() == 4, "every main level and the media finale has a visible ammo crate")
	player.ammo = 0
	crates[0]._collect()
	check(player.ammo == 3 and crates[0].opened, "ammo crate pickup visibly opens and restores three rounds")
	player.ammo = 6
	player.current_action = "shoot"
	player.action_time = 0.18
	player._update_sprite(Vector2.ZERO)
	check(player.get_node("Sprite2D").texture.resource_path.ends_with("starkboy_gun_v5.png"), "shoot uses dedicated visible pistol animation")
	player.current_action = "idle"
	player.mounted = false
	player._update_sprite(Vector2.RIGHT)
	check(player.get_node("Sprite2D").texture.resource_path.ends_with("starkboy_walk_v6.png") and player.get_node("Sprite2D").hframes == 4, "on-foot movement uses a four-frame leg walk cycle")
	player.mounted = true
	game.game_state = "playing"
	player.movement_enabled = true
	game.overlay.visible = false
	player.global_position.x = 250
	game._spawn_progression()
	check(game.enemies.size() == 3, "forest wave spawns three enemies")
	check(game.enemies[0].enemy_sprite != null and game.enemies[1].enemy_sprite != null, "picker and dog use dedicated sprite sheets")
	var direction_enemy = game.enemies[1]
	direction_enemy.velocity = Vector2(-50, 0)
	direction_enemy._physics_process(0.16)
	check(direction_enemy.enemy_sprite.flip_h, "moving enemies and motorcycles face their travel direction")
	direction_enemy.enemy_anim_time = 0.0
	direction_enemy.velocity = Vector2(50, 0)
	direction_enemy._physics_process(0.16)
	check(direction_enemy.enemy_sprite.frame != direction_enemy.enemy_frame_base or direction_enemy.movement_anim_clock > 0.0, "enemy movement advances animated leg frames")
	check(game.enemies.all(func(e): return e.enemy_type in ["picker", "dog"]), "forest contains only mushroom pickers and dogs")
	var swept_enemy = game.enemies[0]
	swept_enemy.global_position = player.global_position + Vector2(140, 0)
	swept_enemy.health = 100.0
	var swept_health: float = swept_enemy.health
	game._on_player_attack("wheelie", player.global_position, 1.0)
	game._on_player_attack("wheelie_active", swept_enemy.global_position - Vector2(20, 0), 1.0)
	check(swept_enemy.health == swept_health - 40.0, "wheelie damages an enemy reached later during the charge")
	game._on_player_attack("wheelie_active", swept_enemy.global_position - Vector2(10, 0), 1.0)
	check(swept_enemy.health == swept_health - 40.0, "one wheelie cannot damage the same enemy twice")
	swept_enemy.health = swept_enemy.max_health
	var first_picker = game.enemies.filter(func(e): return e.enemy_type == "picker")[0]
	var second_picker = game.enemies.filter(func(e): return e.enemy_type == "picker")[1]
	check(game.try_enemy_attack(first_picker, "mushroom") and not game.try_enemy_attack(second_picker, "mushroom"), "mushroom attacks are globally staggered")
	game.next_enemy_attack_msec = 0
	game.next_mushroom_attack_msec = 0
	game.next_ranged_attack_msec = 0
	check(game.try_enemy_attack(first_picker, "ranged") and not game.try_enemy_attack(second_picker, "ranged"), "all ranged mob attacks share one readable queue")
	game.next_enemy_attack_msec = 0
	game.next_ranged_attack_msec = 0
	game.enemies[0]._ranged_attack()
	await process_frame
	var forest_projectiles := get_nodes_in_group("visible_projectiles")
	check(forest_projectiles.size() > 0 and forest_projectiles[0].sprite != null, "mushroom throw creates a visible physical projectile")
	var first = game.enemies[0]
	first.global_position = player.global_position + Vector2(30, 0)
	game._on_player_attack("heavy", player.global_position, 1.0)
	check(first.health < first.max_health, "heavy attack damages enemy")
	check(first.knockdown_time > 0.0 and first.hitstun_time > 0.0, "heavy finishers knock regular enemies down")
	check(game.best_combo >= game.combo and game.hit_stop_serial > 0, "successful hits track best combo and trigger arcade hit-stop")
	check("heavy" in game.attack_variety, "varied attacks contribute to the score bonus")
	var old_ammo: int = player.ammo
	player.attack_requested.emit("shoot", player.global_position, 1.0)
	check(player.ammo == old_ammo, "combat signal is decoupled from ammo state")
	first.take_hit(999, Vector2.ZERO)
	await process_frame
	check(game.score >= first.points, "enemy death awards score")
	for enemy in game.enemies.duplicate():
		if is_instance_valid(enemy) and enemy.active:
			enemy.take_hit(999, Vector2.ZERO)
	await process_frame
	check(player.max_x == 3170.0, "forest wave never creates an invisible wall")
	check(game.inter_wave_delay > 1.0 and game.inter_wave_delay <= game.INTER_WAVE_DELAY, "clearing a wave starts a 1.5 second breathing room")
	game._spawn_progression()
	check(not game.encounter_active, "the next wave cannot spawn during the breathing room")
	game.inter_wave_delay = 0.0
	var plan: Array = game._encounter_plan()
	for stage_index in range(1, plan.size()):
		var encounter: Dictionary = plan[stage_index]
		player.global_position.x = float(encounter["trigger"]) + 5.0
		game._spawn_progression()
		check(game.encounter_active and game.encounter_index == stage_index, "encounter %d starts sequentially" % (stage_index + 1))
		var active_now: Array = game.enemies.filter(func(e): return is_instance_valid(e) and e.active)
		if stage_index in [1, 2]:
			check(active_now.all(func(e): return e.enemy_type in ["picker", "dog"]), "all three forest waves contain only pickers and dogs")
		elif stage_index == 3:
			check(game.boss.enemy_type == "forest_boss" and game.boss.boss_sprite.texture.resource_path.ends_with("forest_boss_v9.png"), "forest ends with animated Mushroom King")
			game.boss._perform_boss_special(0, 120.0, Vector2.RIGHT)
		elif stage_index in [4, 5, 6]:
			check(active_now.all(func(e): return e.enemy_type in ["dres", "bottle"]), "all three city waves contain tracksuit enemies")
			if stage_index == 4:
				var bottle_enemy = active_now.filter(func(e): return e.enemy_type == "bottle")[0]
				bottle_enemy._ranged_attack()
				await process_frame
				check(get_nodes_in_group("visible_projectiles").any(func(p): return p.kind == "bottle" and p.sprite != null), "bottle throw creates a visible physical projectile")
		elif stage_index == 7:
			check(game.boss.enemy_type == "city_boss" and game.boss.boss_sprite.texture.resource_path.ends_with("city_boss_v9.png"), "city ends with animated Tracksuit King")
			game.boss._perform_boss_special(0, 100.0, Vector2.RIGHT)
			await process_frame
			check(get_nodes_in_group("visible_projectiles").any(func(p): return p.kind == "street_wave" and p.sprite != null), "city boss throws a visible manga-style energy wave")
		elif stage_index in [8, 9, 10]:
			check(active_now.all(func(e): return e.enemy_type == "rider"), "all three motocross waves contain combustion riders")
			if stage_index == 8:
				active_now[0]._spawn_exhaust_smoke()
				await process_frame
				check(get_nodes_in_group("exhaust_smoke").size() > 0, "combustion rider leaves animated exhaust smoke")
		elif stage_index == 11:
			check(game.boss.enemy_type == "quad_boss" and game.boss.boss_sprite.texture.resource_path.ends_with("quad_boss_v9.png"), "motocross ends with animated Quad Warlord")
			game.boss._perform_boss_special(3, 120.0, Vector2.RIGHT)
			await process_frame
			var warnings := get_nodes_in_group("boss_attack_telegraph")
			check(warnings.size() > 0 and warnings[-1].effect_sprite.texture.resource_path.ends_with("boss_attacks_v15.png"), "Quad Warlord attacks use visible thematic tire effects")
			var tire_effect = warnings[-1]
			var tire_start: Vector2 = tire_effect.global_position
			tire_effect._physics_process(0.2)
			check(tire_effect.global_position.distance_to(tire_start) > 1.0, "Quad tire effect visibly travels instead of appearing in place")
			check(not tire_effect.has_method("_draw"), "boss attacks no longer use placeholder warning circles")
		elif stage_index == 12:
			check(active_now.all(func(e): return e.enemy_type in ["forest_guard", "forest_guard_heavy"]), "forest guards block the approach to MediaBoss")
			check(active_now.all(func(e): return e.enemy_sprite.texture.resource_path.ends_with("forest_guards_v16.png")), "forest guards use complete green-uniform baton sprites")
		elif stage_index == 13:
			check(game.boss_started and game.boss.enemy_type == "media_boss" and game.boss._boss_name() == "MEDIA BOSS", "final arena uses renamed generic MediaBoss")
			break
		for enemy in active_now:
			if is_instance_valid(enemy) and enemy.active: enemy.take_hit(999, Vector2.ZERO)
		await process_frame
		if stage_index in [3, 7, 11]:
			check(game.inter_wave_delay > 3.0, "defeating level boss %d starts a 3.5 second area transition" % stage_index)
			var next_encounter: Dictionary = plan[stage_index + 1]
			player.global_position.x = float(next_encounter["trigger"]) + 5.0
			game._spawn_progression()
			check(not game.encounter_active, "next area cannot spawn immediately after level boss %d" % stage_index)
			for transition_step in range(20):
				game._process(0.1)
			check(not game.encounter_active and game.inter_wave_delay > 1.0, "next area stays empty for two full seconds after level boss %d" % stage_index)
		game.inter_wave_delay = 0.0
	check(game.encounter_index == 13, "nine waves, three level bosses and forest guards lead to the media finale")
	game._on_boss_summon()
	var summoned_guards: Array = game.enemies.filter(func(e): return is_instance_valid(e) and e.active and e.enemy_type in ["forest_guard", "forest_guard_heavy"])
	check(summoned_guards.size() == 3 and game.forest_guard_wave_spawned, "MediaBoss summons exactly one forest guard reinforcement wave")
	game._on_boss_summon()
	var helper_types: Array = game.enemies.filter(func(e): return is_instance_valid(e) and e.active and e.enemy_type in ["camera_helper", "drone"]).map(func(e): return e.enemy_type)
	check("camera_helper" in helper_types and "drone" in helper_types, "boss summons two distinct fully-sprited helpers")
	check(game.enemies.filter(func(e): return is_instance_valid(e) and e.active and e.enemy_type in ["camera_helper", "drone"]).all(func(e): return e.enemy_sprite != null), "all boss helpers use full sprite atlases")
	player.invulnerable_time = 0.0
	var old_health: float = player.health
	player.take_damage(10, player.global_position - Vector2(20, 0))
	check(player.health < old_health, "player receives damage")
	check(player.invulnerable_time > 0.0, "damage grants invulnerability without locking movement")
	player.respawn(Vector2(100, 260))
	check(player.health == 100.0, "respawn restores health")
	check(player.invulnerable_time == 2.0 and player.respawn_flash_time == 2.0, "respawn grants at most two synchronized seconds of flashing invulnerability")
	check(game._respawn_position(1500).x == 1050 and game._respawn_position(2200).x == 1950, "life loss respawns at the left checkpoint of the current section")
	player.global_position = Vector2(2850, 205)
	player.mounted = true
	player.facing = 1.0
	player.dodge_time = 0.28
	player.dodge_velocity = Vector2(355, 0)
	player._physics_process(0.1)
	check(player.global_position.y >= 205.0 and is_zero_approx(player.velocity.y), "mounted boss dodge travels forward without sticking to top edge")
	var test_boss = game.boss
	test_boss._set_boss_frame(3)
	test_boss._physics_process(0.6)
	check(test_boss.boss_vulnerable_time > 0.0, "boss specials open a visible punish window")
	test_boss.take_hit(220, Vector2.ZERO)
	test_boss._physics_process(0.016)
	check(test_boss.phase == 2, "boss enters phase two below half health")
	test_boss.take_hit(999, Vector2.ZERO)
	await process_frame
	check(game.victory, "boss defeat reaches victory state")
	check(game.game_state == "victory_sequence" and not game.overlay.visible, "boss defeat animation is visible before results")
	await create_timer(2.5).timeout
	check(game.game_state == "results" and game.overlay.visible, "results appear after death animation and fanfare delay")
	game.lives = 1
	game.continues = 0
	game._on_player_defeated()
	check(game.game_state == "game_over" and paused and not player.movement_enabled, "game over freezes mobs, projectiles and player instead of respawning")
	paused = false
	print("SMOKE TEST RESULT: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	game.queue_free()
	await process_frame
	quit(failures)
