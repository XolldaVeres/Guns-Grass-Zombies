extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		var player = body
		# Список возможного лута (без привязки к enum)
		var loot_table = ["ammo", "heal"]   # патроны и лечение доступны всегда

		# Проверяем, есть ли у игрока магия, дробовик, миниган
		# Используем собственный метод игрока has_weapon(имя)
		if player.has_method("has_weapon") and player.has_weapon("magic"):
			loot_table.append("magic")
		else:
			loot_table.append("ammo")   # если магии нет, заменяем на патроны

		if player.has_method("has_weapon") and not player.has_weapon("shotgun"):
			loot_table.append("shotgun")
		if player.has_method("has_weapon") and not player.has_weapon("minigun"):
			loot_table.append("minigun")

		# Случайный выбор
		var choice = loot_table[randi() % loot_table.size()]
		match choice:
			"ammo":
				player.add_ammo(randi_range(20, 60))
			"heal":
				player.heal(randi_range(20, 50))
			"magic":
				player.add_magic_charge(1)
			"shotgun":
				# Вызываем unlock_weapon с именем, игрок сам решит, дать оружие или патроны
				if player.has_method("unlock_weapon_by_name"):
					player.unlock_weapon_by_name("shotgun")
			"minigun":
				if player.has_method("unlock_weapon_by_name"):
					player.unlock_weapon_by_name("minigun")
		queue_free()
