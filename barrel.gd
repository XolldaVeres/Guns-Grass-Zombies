extends Area2D

var health = 1
var explosion_damage = 40
var explosion_radius = 150.0

func _ready():
	collision_layer = 6
	collision_mask = 1 | 3
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _on_body_entered(body):
	if body.name == "Player":
		explode()

func _on_area_entered(_area):
	explode()

func take_damage(amount):
	health -= amount
	if health <= 0:
		explode()

func explode():
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = explosion_radius
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	var results = space.intersect_shape(query)
	for result in results:
		var obj = result["collider"]
		if obj.is_in_group("enemy"):
			if obj.has_method("take_damage"):
				obj.take_damage(explosion_damage)
	if has_node("ExplosionSound"):
		$ExplosionSound.play()
	if has_node("CPUParticles2D"):
		$CPUParticles2D.emitting = true
	await get_tree().create_timer(0.5).timeout
	queue_free()
