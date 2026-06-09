extends Camera2D

var shake_amount = 0.0
var shake_decay = 5.0

func _ready():
	add_to_group("camera")

func _process(delta):
	if shake_amount > 0:
		offset = Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
		shake_amount = max(0, shake_amount - shake_decay * delta)
	else:
		offset = Vector2.ZERO

func add_shake(amount: float):
	shake_amount = min(shake_amount + amount, 4.0)
