extends CharacterBody2D

var SPEED = 100.0   # теперь var, чтобы survival.gd мог усиливать боссов
var health = 10

var attack_damage = 35
var attack_cooldown = 1.5
var attack_timer = 0.0

var shoot_cooldown = 1.5
var shoot_timer = 0.0
var boss_bullet_scene = preload("res://boss_bullet.tscn")

var knockback = Vector2.ZERO
var blood_scene = preload("res://blood_particles.tscn")
@onready var player = get_tree().current_scene.get_node_or_null("Player")
@onready var cast_sound = get_node_or_null("CastSound")
@onready var hit_sound = get_node_or_null("HitSound")
@onready var attack_sound = get_node_or_null("AttackSound")

func _ready():
	add_to_group("enemy")

func _physics_process(delta):
	if attack_timer > 0: attack_timer -= delta
	if shoot_timer > 0: shoot_timer -= delta

	knockback = knockback.move_toward(Vector2.ZERO, 400.0 * delta)

	if player and not player.is_dead:
		var direction = (player.global_position - global_position).normalized()
		velocity = (direction * SPEED) + knockback
		look_at(player.global_position)
		move_and_slide()

		if shoot_timer <= 0:
			shoot_sphere()
			shoot_timer = shoot_cooldown

		if get_slide_collision_count() > 0:
			for i in range(get_slide_collision_count()):
				var collider = get_slide_collision(i).get_collider()
				if collider and collider.name == "Player" and attack_timer <= 0:
					collider.take_damage(attack_damage)
					attack_timer = attack_cooldown
					if attack_sound: attack_sound.play()

func shoot_sphere():
	if cast_sound: cast_sound.play()
	var bullet = boss_bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.global_rotation = global_rotation
	bullet.scale = Vector2(2.2, 2.2)
	get_tree().current_scene.add_child(bullet)

func apply_knockback(knockback_velocity: Vector2):
	knockback = knockback_velocity * 0.5

func take_damage(amount):
	health -= amount
	if hit_sound: hit_sound.play()
	if health <= 0: die()

func die():
	var blood = blood_scene.instantiate()
	blood.global_position = global_position
	blood.scale = Vector2(3.0, 3.0)
	get_tree().current_scene.add_child(blood)
	if get_tree().current_scene.has_method("add_kill"):
		get_tree().current_scene.add_kill("boss")
	queue_free()
