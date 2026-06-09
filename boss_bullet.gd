extends Area2D

const SPEED = 250.0
var damage = 25
var lifetime = 5.0

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += transform.x * SPEED * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		if body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()
