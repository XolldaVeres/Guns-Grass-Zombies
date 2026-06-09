extends Area2D

const SPEED = 1200.0
var damage = 1

# Таймер времени жизни пули в секундах
var lifetime = 2.0 

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += transform.x * SPEED * delta
	
	# Уменьшаем время жизни каждый кадр
	lifetime -= delta
	if lifetime <= 0:
		queue_free() # Пуля сама стирается из памяти, если улетела в никуда

func _on_body_entered(body):
	# Полный игнор игрока и любых турелей
	if body.name == "Player" or "Turret" in body.name:
		return
		
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free() 
		
	if body.name == "Walls":
		queue_free()
