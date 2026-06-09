extends Node2D

var zombie_scene = preload("res://zombie.tscn")
var ammo_box_scene = preload("res://ammo_box.tscn")
var boss_scene = preload("res://boss.tscn")

@onready var spawn_points = get_node_or_null("SpawnPoints")
@onready var timer = get_node_or_null("Timer")

var current_wave = 1
var zombies_to_spawn = 15
var zombies_spawned = 0
var ammo_spawn_timer = 4.0
var game_won = false

var BOSSES_PER_WAVE = 1
var bosses_spawned_this_wave = 0

var zombie_kills = 0
var boss_kills = 0
const ZOMBIE_TARGET = 500
const BOSS_TARGET = 100

func _ready():
	if timer:
		timer.timeout.connect(_on_timer_timeout)
	start_wave()
	var player = get_node_or_null("Player")
	if player:
		player.add_to_group("player")
	update_ui_labels()

func _process(delta):
	if game_won: return
	ammo_spawn_timer -= delta
	if ammo_spawn_timer <= 0:
		spawn_ammo_box()
		ammo_spawn_timer = 5.0 + randf() * 3.0

func start_wave():
	zombies_spawned = 0
	bosses_spawned_this_wave = 0
	zombies_to_spawn = current_wave * 8
	if timer: timer.stop()
	if current_wave >= 2:
		BOSSES_PER_WAVE = min(current_wave + 1, 8)
		await spawn_bosses_with_delay()
	if timer:
		timer.wait_time = max(0.15, 0.6 - (current_wave * 0.05))
		timer.start()

func spawn_bosses_with_delay():
	for i in range(BOSSES_PER_WAVE):
		if spawn_points and spawn_points.get_child_count() > 0:
			var random_marker = spawn_points.get_child(randi() % spawn_points.get_child_count())
			var boss = boss_scene.instantiate()
			boss.global_position = random_marker.global_position
			boss.health = 15 + (current_wave - 1) * 10
			boss.SPEED = 100.0 + (current_wave - 2) * 10
			add_child(boss)
			bosses_spawned_this_wave += 1
		await get_tree().create_timer(0.8).timeout

func _on_timer_timeout():
	if not spawn_points or spawn_points.get_child_count() == 0: return
	if zombies_spawned < zombies_to_spawn:
		var random_marker = spawn_points.get_child(randi() % spawn_points.get_child_count())
		var zombie = zombie_scene.instantiate()
		zombie.global_position = random_marker.global_position
		zombie.health = 2 + int(current_wave / 3.0)
		add_child(zombie)
		zombies_spawned += 1
	else:
		if timer: timer.stop()
		check_wave_cleared()

func check_wave_cleared():
	var active_enemies = 0
	for child in get_children():
		var child_name = child.name.to_lower()
		if "zombie" in child_name or "boss" in child_name:
			active_enemies += 1
	if active_enemies == 0:
		current_wave += 1
		await get_tree().create_timer(2.0).timeout
		start_wave()
	else:
		await get_tree().create_timer(0.5).timeout
		check_wave_cleared()

func spawn_ammo_box():
	var box = ammo_box_scene.instantiate()
	box.global_position = Vector2(randf_range(100, 1000), randf_range(100, 600))
	add_child(box)

func add_kill(type: String):
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_xp"):
		player.add_xp(20)
	if type == "zombie":
		zombie_kills += 1
	elif type == "boss":
		boss_kills += 1
	if zombie_kills >= ZOMBIE_TARGET and boss_kills >= BOSS_TARGET:
		win_game()
	else:
		update_ui_labels()

func update_ui_labels():
	var zombie_label = get_node_or_null("UI/ZombieKillsLabel")
	if zombie_label:
		zombie_label.text = "Зомби убито: " + str(zombie_kills)
	var boss_label = get_node_or_null("UI/BossKillsLabel")
	if boss_label:
		boss_label.text = "Боссов убито: " + str(boss_kills)
	var wave_label = get_node_or_null("UI/WaveLabel")
	if wave_label:
		wave_label.text = "Волна: " + str(current_wave)
	var progress_label = get_node_or_null("UI/ProgressLabel")
	if progress_label:
		progress_label.text = "Цель: " + str(min(zombie_kills, ZOMBIE_TARGET)) + "/" + str(ZOMBIE_TARGET) + " зомби, " + str(min(boss_kills, BOSS_TARGET)) + "/" + str(BOSS_TARGET) + " боссов"

func show_cursor():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func win_game():
	game_won = true
	get_tree().paused = true
	show_cursor()
	var win_label = get_node_or_null("UI/WinLabel")
	if win_label:
		win_label.visible = true
		win_label.text = "ЗАЧИСТКА ПРОЙДЕНА!"
	var menu_btn = get_node_or_null("UI/GameOverLabel/MenuButton")
	if menu_btn:
		menu_btn.visible = true

func die():
	show_cursor()
	var game_over_label = get_node_or_null("UI/GameOverLabel")
	if game_over_label:
		game_over_label.visible = true
		game_over_label.text = "ВЫ ПОГИБЛИ"
	var menu_btn = get_node_or_null("UI/GameOverLabel/MenuButton")
	if menu_btn:
		menu_btn.visible = true
