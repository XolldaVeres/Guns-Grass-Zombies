extends CharacterBody2D

const SPEED = 100.0
var health = 2
var attack_damage = 20
var attack_cooldown = 1.0
var attack_timer = 0.0

var knockback = Vector2.ZERO
var blood_scene = preload("res://blood_particles.tscn")
@onready var player = get_tree().current_scene.get_node_or_null("Player")
@onready var hit_sound = $HitSound

func _ready():
	add_to_group("enemy")

func _physics_process(delta):
	if attack_timer > 0:
		attack_timer -= delta

	knockback = knockback.move_toward(Vector2.ZERO, 500.0 * delta)

	if player and not player.is_dead:
		var direction = (player.global_position - global_position).normalized()
		velocity = (direction * SPEED) + knockback
		look_at(player.global_position)
		move_and_slide()

		if get_slide_collision_count() > 0:
			for i in range(get_slide_collision_count()):
				var collider = get_slide_collision(i).get_collider()
				if collider and collider.name == "Player" and attack_timer <= 0:
					collider.take_damage(attack_damage)
					attack_timer = attack_cooldown

func apply_knockback(knockback_velocity: Vector2):
	knockback = knockback_velocity

func take_damage(amount):
	health -= amount
	if hit_sound: hit_sound.play()
	if health <= 0:
		die()

func die():
	var blood = blood_scene.instantiate()
	blood.global_position = global_position
	get_tree().current_scene.add_child(blood)

	# Сообщаем Main о убийстве и запускаем некромантию
	if get_tree().current_scene.has_method("add_kill"):
		get_tree().current_scene.add_kill("zombie")
		# Шанс 25% — поднять зомби как союзника (вызываем метод Main)
		if randi() % 100 < 25 and get_tree().current_scene.has_method("spawn_raised_ally_at"):
			get_tree().current_scene.spawn_raised_ally_at(global_position)

	queue_free()
