extends CharacterBody2D

const SPEED_WANDER = 100.0
const SPEED_COMBAT = 180.0
const WANDER_RADIUS = 200.0
const ARRIVE_DISTANCE = 10.0
const REST_TIME = 1.0

const ATTACK_RANGE = 300.0
const ATTACK_COOLDOWN = 0.15
const BULLET_SPREAD = 5.0
const DAMAGE = 5
const BURST_COUNT = 3
const BURST_DELAY = 0.08

var health = 30
var is_raised = false

var attack_timer = 0.0
var target = null
var player = null
var state = "wander"
var wander_target = Vector2.ZERO
var rest_timer = 0.0
var burst_timer = 0.0
var burst_shots_left = 0

@onready var detection_area = $DetectionArea
@onready var sprite = $Sprite2D

func _ready():
	collision_layer = 4
	collision_mask = 2 | 16
	player = get_tree().get_first_node_in_group("player")
	if is_raised:
		sprite.modulate = Color(0.2, 0.8, 0.2)
		health = 15
	pick_new_wander_target()
	add_to_group("ally")

func _physics_process(delta):
	if health <= 0:
		queue_free()
		return

	if attack_timer > 0: attack_timer -= delta
	if rest_timer > 0: rest_timer -= delta
	if burst_timer > 0: burst_timer -= delta

	if not is_instance_valid(target):
		find_target()

	state = "combat" if target else "wander"

	match state:
		"wander": wander_behavior(delta)
		"combat": combat_behavior(delta)

	move_and_slide()

	if target: look_at(target.global_position)
	elif velocity.length() > 10: look_at(global_position + velocity)

func wander_behavior(_delta):
	if not player: return
	if rest_timer > 0:
		velocity = Vector2.ZERO
		return
	var dist = global_position.distance_to(wander_target)
	if dist < ARRIVE_DISTANCE:
		rest_timer = REST_TIME + randf() * 0.5
		pick_new_wander_target()
		velocity = Vector2.ZERO
	else:
		velocity = (wander_target - global_position).normalized() * SPEED_WANDER

func pick_new_wander_target():
	if not player: return
	var angle = randf_range(0, 2 * PI)
	var radius = randf_range(50.0, WANDER_RADIUS)
	wander_target = player.global_position + Vector2(cos(angle), sin(angle)) * radius

func combat_behavior(_delta):
	if not is_instance_valid(target): return
	var dist = global_position.distance_to(target.global_position)
	if dist > ATTACK_RANGE:
		velocity = (target.global_position - global_position).normalized() * SPEED_COMBAT
	elif dist < ATTACK_RANGE * 0.7:
		velocity = (global_position - target.global_position).normalized() * SPEED_COMBAT * 0.7
	else:
		var to_target = target.global_position - global_position
		velocity = Vector2(-to_target.y, to_target.x).normalized() * SPEED_COMBAT * 0.4

	if attack_timer <= 0 and burst_shots_left == 0:
		burst_shots_left = BURST_COUNT
		burst_timer = 0.0
	if burst_shots_left > 0 and burst_timer <= 0:
		shoot()
		burst_shots_left -= 1
		burst_timer = BURST_DELAY
		if burst_shots_left == 0:
			attack_timer = ATTACK_COOLDOWN

func find_target():
	var nearest = null
	var min_dist = INF
	if detection_area:
		for body in detection_area.get_overlapping_bodies():
			if body.is_in_group("enemy") and is_instance_valid(body):
				var dist = global_position.distance_to(body.global_position)
				if dist < min_dist:
					min_dist = dist
					nearest = body
	target = nearest

func shoot():
	if not is_instance_valid(target): return
	var bullet = preload("res://bullet.tscn").instantiate()
	bullet.global_position = global_position
	var base_angle = global_position.direction_to(target.global_position).angle()
	var spread_rad = deg_to_rad(randf_range(-BULLET_SPREAD, BULLET_SPREAD))
	bullet.global_rotation = base_angle + spread_rad
	bullet.damage = DAMAGE
	# Явно исключаем слой союзников и игрока из маски пули
	bullet.collision_mask = 2 | 5 | 6   # враги, окружение, бочки
	get_tree().current_scene.add_child(bullet)

func take_damage(amount):
	health -= amount
	if health <= 0: queue_free()
