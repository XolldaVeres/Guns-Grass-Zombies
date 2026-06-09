extends CPUParticles2D

func _ready():
	# Запускаем взрыв частиц
	emitting = true
	# Ждем полсекунды и удаляем узел, чтобы игра не лагала
	await get_tree().create_timer(0.5).timeout
	queue_free()
