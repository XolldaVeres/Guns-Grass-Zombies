extends Area2D

const SPEED = 500.0       
const EXPLOSION_RADIUS = 250.0 
const DAMAGE = 15          

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += transform.x * SPEED * delta

func _on_body_entered(body):
	if body.name == "Player" or "Turret" in body.name:
		return
	explode()

func explode():
	print("МАГИЧЕСКИЙ ВЗРЫВ ПО ПЛОЩАДИ!")
	
	# Проверяем абсолютно ВСЕ объекты на карте
	for child in get_tree().current_scene.get_children():
		# Если объект существует и у него в принципе есть функция take_damage (значит это враг!)
		if is_instance_valid(child) and child.has_method("take_damage") and child.name != "Player":
			var distance = global_position.distance_to(child.global_position)
			
			# Если враг попал в радиус взрыва магии
			if distance <= EXPLOSION_RADIUS:
				child.take_damage(DAMAGE) # Наносим огромный урон
				
				# Отталкиваем назад
				if child.has_method("apply_knockback"):
					var knockback_direction = (child.global_position - global_position).normalized()
					child.apply_knockback(knockback_direction * 600.0)
					
	queue_free() # Магический снаряд исчезает
