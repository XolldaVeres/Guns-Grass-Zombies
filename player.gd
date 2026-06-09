extends CharacterBody2D

const SPEED = 400.0
var current_speed_mult = 1.0
const SLOW_WHEN_SHOOTING = 0.6

const DASH_SPEED = 900.0
const DASH_DURATION = 0.15
const DASH_COOLDOWN = 1.0

var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var is_dashing = false
var dash_direction = Vector2.ZERO

var health = 100
var max_health = 100
var is_dead = false

var level = 1
var xp = 0
var xp_to_next = 70

enum Weapon { PISTOL, SHOTGUN, MINIGUN, MAGIC }
var current_weapon: Weapon = Weapon.PISTOL
var fire_cooldown = 0.0

const MINIGUN_FIRE_RATE = 0.05

var unlocked_weapons = [Weapon.PISTOL]

var player_skins = {
	Weapon.PISTOL: preload("res://asset/player_skins/player_pistol.png"),
	Weapon.SHOTGUN: preload("res://asset/player_skins/player_shotgun.png"),
	Weapon.MINIGUN: preload("res://asset/player_skins/player_minigun.png"),
	Weapon.MAGIC: preload("res://asset/player_skins/player_pistol.png")
}

var pistol_clip = 30
var pistol_max_clip = 30
var pistol_reserve = 90

var shotgun_clip = 6
var shotgun_max_clip = 6
var shotgun_reserve = 24

var minigun_clip = 100
var minigun_max_clip = 100
var minigun_reserve = 300

var magic_charges = 3

var is_reloading = false
var reload_time = 1.5

var bullet_scene = preload("res://bullet.tscn")
var magic_scene = preload("res://magic_spell.tscn")

@onready var shoot_sound = get_node_or_null("ShootSound")
@onready var footstep_sound = get_node_or_null("FootstepSound")
@onready var reload_sound = get_node_or_null("ReloadSound")
@onready var hurt_sound = get_node_or_null("HurtSound")
@onready var player_sprite = $PlayerSprite
@onready var crosshair = $Crosshair
@onready var muzzle_flash = $MuzzleFlash

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	if muzzle_flash:
		muzzle_flash.visible = false
		muzzle_flash.stop()
	update_ammo_ui()
	update_health_ui()
	update_level_ui()
	apply_skin()

func _physics_process(delta):
	if is_dead: return

	if dash_timer > 0:
		dash_timer -= delta
		if dash_timer <= 0: is_dashing = false
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	var direction = Vector2.ZERO
	if Input.is_key_pressed(KEY_D): direction.x += 1
	if Input.is_key_pressed(KEY_A): direction.x -= 1
	if Input.is_key_pressed(KEY_S): direction.y += 1
	if Input.is_key_pressed(KEY_W): direction.y -= 1
	direction = direction.normalized()

	if Input.is_key_pressed(KEY_SPACE) and dash_cooldown_timer <= 0 and direction != Vector2.ZERO and not is_reloading:
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN
		dash_direction = direction

	if is_dashing:
		velocity = dash_direction * DASH_SPEED
	else:
		velocity = direction * SPEED * current_speed_mult

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_reloading:
		current_speed_mult = SLOW_WHEN_SHOOTING
	else:
		current_speed_mult = 1.0

	move_and_slide()

	if velocity.length() > 0 and not is_dashing and footstep_sound and not footstep_sound.playing:
		footstep_sound.play()
	elif (velocity.length() == 0 or is_dashing) and footstep_sound:
		footstep_sound.stop()

	look_at(get_global_mouse_position())

	# Переключение оружия (буквенные клавиши для веб-версии)
	if not is_reloading:
		if Input.is_key_pressed(KEY_Q) and current_weapon != Weapon.PISTOL:
			if Weapon.PISTOL in unlocked_weapons:
				current_weapon = Weapon.PISTOL
				apply_skin()
				update_ammo_ui()
		elif Input.is_key_pressed(KEY_E) and current_weapon != Weapon.SHOTGUN:
			if Weapon.SHOTGUN in unlocked_weapons:
				current_weapon = Weapon.SHOTGUN
				apply_skin()
				update_ammo_ui()
		elif Input.is_key_pressed(KEY_F) and current_weapon != Weapon.MAGIC:
			if Weapon.MAGIC in unlocked_weapons:
				current_weapon = Weapon.MAGIC
				apply_skin()
				update_ammo_ui()
		elif Input.is_key_pressed(KEY_V) and current_weapon != Weapon.MINIGUN:
			if Weapon.MINIGUN in unlocked_weapons:
				current_weapon = Weapon.MINIGUN
				apply_skin()
				update_ammo_ui()

		# Колесико мыши (работает всегда)
		var total = Weapon.size()
		var id = current_weapon as int
		if Input.is_action_just_pressed("ui_wheel_up"):
			id = (id - 1 + total) % total
			var new_weapon = id as Weapon
			if new_weapon in unlocked_weapons:
				current_weapon = new_weapon
				apply_skin()
				update_ammo_ui()
		elif Input.is_action_just_pressed("ui_wheel_down"):
			id = (id + 1) % total
			var new_weapon = id as Weapon
			if new_weapon in unlocked_weapons:
				current_weapon = new_weapon
				apply_skin()
				update_ammo_ui()

	# Перезарядка на R
	if Input.is_key_pressed(KEY_R) and not is_reloading and current_weapon != Weapon.MAGIC:
		check_reload_input()

	if fire_cooldown > 0: fire_cooldown -= delta

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and fire_cooldown <= 0 and not is_reloading:
		handle_shooting()

	if crosshair:
		crosshair.global_position = crosshair.global_position.lerp(get_global_mouse_position(), 25 * delta)

func handle_shooting():
	match current_weapon:
		Weapon.PISTOL:
			if pistol_clip >= 1:
				pistol_clip -= 1
				fire_cooldown = max(0.08, 0.2 - (level - 1) * 0.02)
				if shoot_sound: shoot_sound.play()
				spawn_bullet(0.0, 2 + int(level / 2.0))
				trigger_effects(3.0)
			else:
				start_reload()
		Weapon.SHOTGUN:
			var shots = 3 + int(level / 2.0)
			var cost = max(1, 3 - int(level / 3.0))
			if shotgun_clip >= cost:
				shotgun_clip -= cost
				fire_cooldown = 0.8
				shoot_shotgun(shots)
				trigger_effects(5.0)
			else:
				start_reload()
		Weapon.MINIGUN:
			if minigun_clip >= 1:
				minigun_clip -= 1
				fire_cooldown = max(0.03, MINIGUN_FIRE_RATE - (level - 1) * 0.005)
				if shoot_sound: shoot_sound.play()
				var spread = randf_range(-0.15, 0.15) * max(0.3, 1.0 - level * 0.1)
				spawn_bullet(spread, 2 + int(level / 2.0))
				trigger_effects(1.5)
			else:
				start_reload()
		Weapon.MAGIC:
			if magic_charges > 0:
				magic_charges -= 1
				fire_cooldown = 1.2
				if shoot_sound: shoot_sound.play()
				var spell = magic_scene.instantiate()
				spell.global_position = global_position
				spell.global_rotation = global_rotation
				spell.damage = 15 + (level - 1) * 5
				spell.explosion_radius = 150 + (level - 1) * 10
				get_tree().current_scene.add_child(spell)
				trigger_effects(4.0)
				update_ammo_ui()

func shoot_shotgun(shots_count: int):
	if shoot_sound: shoot_sound.play()
	spawn_shotgun_wave(shots_count)
	await get_tree().create_timer(0.1).timeout
	if is_dead: return
	if shoot_sound: shoot_sound.play()
	spawn_shotgun_wave(shots_count)
	update_ammo_ui()

func spawn_shotgun_wave(count: int):
	for i in range(count):
		var angle = randf_range(-0.3, 0.3)
		spawn_bullet(angle, 3 + int(level / 2.0))

func spawn_bullet(angle_offset: float, dmg: int):
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.global_rotation = global_rotation + angle_offset
	bullet.damage = dmg
	get_tree().current_scene.add_child(bullet)
	if muzzle_flash:
		muzzle_flash.visible = true
		muzzle_flash.play("default")
		await get_tree().create_timer(0.05).timeout
		muzzle_flash.visible = false
		muzzle_flash.stop()

func trigger_effects(shake_power: float):
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("add_shake"):
		cam.add_shake(shake_power)

func check_reload_input():
	if current_weapon == Weapon.PISTOL and pistol_clip < pistol_max_clip and pistol_reserve > 0:
		start_reload()
	elif current_weapon == Weapon.SHOTGUN and shotgun_clip < shotgun_max_clip and shotgun_reserve > 0:
		start_reload()
	elif current_weapon == Weapon.MINIGUN and minigun_clip < minigun_max_clip and minigun_reserve > 0:
		start_reload()

func start_reload():
	is_reloading = true
	if reload_sound: reload_sound.play()
	await get_tree().create_timer(reload_time).timeout
	if is_dead: return

	match current_weapon:
		Weapon.PISTOL:
			var needed = pistol_max_clip - pistol_clip
			var to_load = min(needed, pistol_reserve)
			pistol_clip += to_load
			pistol_reserve -= to_load
		Weapon.SHOTGUN:
			var needed = shotgun_max_clip - shotgun_clip
			var to_load = min(needed, shotgun_reserve)
			shotgun_clip += to_load
			shotgun_reserve -= to_load
		Weapon.MINIGUN:
			var needed = minigun_max_clip - minigun_clip
			var to_load = min(needed, minigun_reserve)
			minigun_clip += to_load
			minigun_reserve -= to_load

	is_reloading = false
	update_ammo_ui()

func apply_skin():
	if not player_sprite: return
	if player_skins.has(current_weapon):
		player_sprite.texture = player_skins[current_weapon]
	else:
		player_sprite.texture = null
	update_ammo_ui()

func update_ammo_ui():
	var label = get_tree().current_scene.get_node_or_null("UI/AmmoLabel")
	if label:
		match current_weapon:
			Weapon.MAGIC: label.text = "СУПЕР-МАГИЯ: " + str(magic_charges) + " заклинаний"
			Weapon.PISTOL: label.text = "ПИСТОЛЕТ: " + str(pistol_clip) + " / " + str(pistol_reserve)
			Weapon.SHOTGUN: label.text = "ДРОБОВИК: " + str(shotgun_clip) + " / " + str(shotgun_reserve)
			Weapon.MINIGUN: label.text = "ПУЛЕМЕТ ГАТЛИНГА: " + str(minigun_clip) + " / " + str(minigun_reserve)

func update_health_ui():
	var label = get_tree().current_scene.get_node_or_null("UI/HealthLabel")
	if label:
		if health > 0: label.text = "ЗДОРОВЬЕ: " + str(health) + "%"
		else:
			label.text = "ЗДОРОВЬЕ: МЕРТВ"
			label.modulate = Color(1, 0, 0)

func update_level_ui():
	var label = get_tree().current_scene.get_node_or_null("UI/LevelLabel")
	if label:
		label.text = "Уровень: " + str(level) + " (опыт: " + str(xp) + "/" + str(xp_to_next) + ")"

func add_xp(amount: int):
	xp += amount
	if xp >= xp_to_next:
		level += 1
		xp -= xp_to_next
		xp_to_next = int(xp_to_next * 1.5)
		health = max_health
		pistol_reserve += 50
		if Weapon.SHOTGUN in unlocked_weapons: shotgun_reserve += 15
		if Weapon.MINIGUN in unlocked_weapons: minigun_reserve += 200
		update_health_ui()
		update_ammo_ui()
	update_level_ui()

func unlock_weapon(weapon_type: Weapon):
	if weapon_type not in unlocked_weapons:
		unlocked_weapons.append(weapon_type)
		match weapon_type:
			Weapon.SHOTGUN:
				shotgun_clip = shotgun_max_clip
				shotgun_reserve = 24
			Weapon.MINIGUN:
				minigun_clip = minigun_max_clip
				minigun_reserve = 300
			Weapon.MAGIC:
				magic_charges = 3
		current_weapon = weapon_type
		apply_skin()
		update_ammo_ui()
	else:
		add_ammo(30)

func has_weapon(weapon_name: String) -> bool:
	match weapon_name:
		"shotgun": return Weapon.SHOTGUN in unlocked_weapons
		"minigun": return Weapon.MINIGUN in unlocked_weapons
		"magic": return Weapon.MAGIC in unlocked_weapons
	return false

func unlock_weapon_by_name(weapon_name: String):
	match weapon_name:
		"shotgun": unlock_weapon(Weapon.SHOTGUN)
		"minigun": unlock_weapon(Weapon.MINIGUN)
		"magic": unlock_weapon(Weapon.MAGIC)

func add_ammo(amount):
	pistol_reserve += amount
	if Weapon.SHOTGUN in unlocked_weapons: shotgun_reserve += int(amount / 3.0)
	if Weapon.MINIGUN in unlocked_weapons: minigun_reserve += amount * 2
	update_ammo_ui()

func heal(amount):
	health = min(max_health, health + amount)
	update_health_ui()

func add_magic_charge(amount):
	magic_charges += amount
	update_ammo_ui()

func take_damage(amount):
	if is_dead: return
	health -= amount
	update_health_ui()
	if hurt_sound: hurt_sound.play()
	if health <= 0: die()

func die():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	is_dead = true
	if footstep_sound: footstep_sound.stop()
	update_health_ui()
	var game_over_label = get_tree().current_scene.get_node_or_null("UI/GameOverLabel")
	if game_over_label:
		game_over_label.visible = true
		var menu_btn = game_over_label.get_node_or_null("MenuButton")
		if menu_btn:
			if menu_btn.pressed.is_connected(_on_menu_button_pressed):
				menu_btn.pressed.disconnect(_on_menu_button_pressed)
			menu_btn.pressed.connect(_on_menu_button_pressed)

func _on_menu_button_pressed():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://main_menu.tscn")
