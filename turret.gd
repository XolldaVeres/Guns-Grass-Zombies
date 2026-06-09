extends StaticBody2D

const FIRE_RATE = 0.05
var fire_cooldown = 0.0

var bullet_scene = preload("res://bullet.tscn")
@onready var detection_area = $DetectionArea

func _physics_process(delta):
	if fire_cooldown > 0:
		fire_cooldown -= delta
		
	var target = get_closest_target()
	if target and is_instance_valid(target): # Проверяем, что цель РЕАЛЬНО существует
		look_at(target.global_position)
		if fire_cooldown <= 0:
			shoot(target)
			fire_cooldown = FIRE_RATE

func get_closest_target() -> Node2D:
	var overlapped_bodies = detection_area.get_overlapping_bodies()
	var closest_zombie = null
	var min_distance = INF
	
	for body in overlapped_bodies:
		# Жесткая проверка: объект существует, не удаляется и это зомби
		if is_instance_valid(body) and "Zombie" in body.name and not body.is_queued_for_deletion():
			var distance = global_position.distance_to(body.global_position)
			if distance < min_distance:
				min_distance = distance
				closest_zombie = body
				
	return closest_zombie

func shoot(target):
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.global_rotation = global_rotation
	
	bullet.scale = Vector2(2.0, 2.0) 
	bullet.damage = 3 
	get_tree().current_scene.add_child(bullet)
	
	if is_instance_valid(target) and target.has_method("apply_knockback"):
		var push_dir = (target.global_position - global_position).normalized()
		target.apply_knockback(push_dir * 500.0)
