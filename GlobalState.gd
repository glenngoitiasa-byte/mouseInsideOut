# res://scripts/GlobalState.gd
extends Node

var current_selected_level: int = 1
var is_random_mode: bool = false
var current_seed: int = 0
var current_maze_width: int = 15
var current_maze_height: int = 15
var current_cheese_count: int = 0
var current_random_level_name: String = "Nivel Desconocido"

# Modificadores activos del nivel actual
var current_is_dark_mode: bool = false
var current_has_password: bool = false
var current_max_cheeses: int = 0 # Necesario para saber si recogió el 100%

func complete_history_level(level_num: int, cheeses_collected: int, steps: int, lines: int, crashes:int, rank: String) -> void:
	if level_num >= SaveManager.current_save["history_levels_unlocked"]:
		SaveManager.current_save["history_levels_unlocked"] = level_num + 1
		
	SaveManager.current_save["player_stats"]["total_cheeses"] += cheeses_collected
	var best_scores = SaveManager.current_save["player_stats"]["best_scores"]
	var lvl_key = str(level_num)
	
	best_scores[lvl_key] = {
		"rank": rank,
		"steps": steps,
		"cheeses": cheeses_collected,
		"all_cheeses": (cheeses_collected >= current_max_cheeses) # NUEVO: Marca si recogió todos
	}
	
	# Al ganar/perder, crea el diccionario del intento
	var attempt_data = {
		"tipo": "historia", # O "aleatorio" según corresponda
		"nivel_id": str(level_num), # O la semilla si es aleatorio
		"pasos": steps,
		"quesos": cheeses_collected,
		"choques": crashes,
		"lineas": lines,
		"victoria": true # o false si perdió
	}
	
	var log_array = SaveManager.current_save["player_stats"]["attempts_log"]
	log_array.append(attempt_data)
	if log_array.size() > 50:
		log_array.pop_front()
		
	
	SaveManager.save_game()
	AchievementManager.check_achievements() # Dispara la evaluación de logros

func complete_random_level(seed_value: int, cheeses_collected: int, steps: int, crashes: int, lines: int, rank: String) -> void:
	var level_key = "random_" + str(seed_value)
	var stats = SaveManager.current_save["player_stats"]
	
	# Guardar Récord (Tu código actual...)
	if not stats["best_scores"].has(level_key):
		stats["best_scores"][level_key] = {"rank": rank, "best_steps": steps, "best_lines": lines,  "max_cheeses": cheeses_collected}
	else:
		var current_record = stats["best_scores"][level_key]
		if steps < current_record["best_steps"]: current_record["best_steps"] = steps
		if lines < current_record["best_lines"]: current_record["best_lines"] = lines
		current_record["rank"] = rank 
		
	# --- NUEVO: Actualizar Contadores para Logros ---
	stats["random_wins"] += 1
	if rank == "S": stats["random_s_ranks"] += 1
	
	# Evaluar Insignia (Tamaño)
	if current_maze_width == 9: stats["bronze_wins"] += 1
	elif current_maze_width == 15: stats["silver_wins"] += 1
	elif current_maze_width == 21: stats["gold_wins"] += 1
		
	# Evaluar Modificadores
	if current_is_dark_mode: stats["dark_mode_wins"] += 1
	if current_has_password: stats["password_wins"] += 1
		
	# Al ganar/perder, crea el diccionario del intento
	var attempt_data = {
		"tipo": "aleatorio", # O "aleatorio" según corresponda
		"nivel_id": GlobalState.current_random_level_name, # O la semilla si es aleatorio
		"pasos": steps,
		"quesos": cheeses_collected,
		"choques": crashes,
		"lineas": lines,
		"victoria": true # o false si perdió
	}
	
	var log_array = SaveManager.current_save["player_stats"]["attempts_log"]
	log_array.append(attempt_data)
	if log_array.size() > 50:
		log_array.pop_front()
		
	SaveManager.save_game()
	AchievementManager.check_achievements() # Dispara la evaluación de logros

func save_random_level_card(card_data: Dictionary) -> void:
	var saved_cards: Array = SaveManager.current_save["random_levels_saved"]
	
	# Prevenir duplicados exactos (misma semilla y tamaño)
	for card in saved_cards:
		if str(card["seed"]) == str(card_data["seed"]) and card["size"] == card_data["size"]:
			print("[SISTEMA] Esta tarjeta ya está en tu colección.")
			return
			
	
	# Agregar y guardar
	saved_cards.append(card_data)
	SaveManager.save_game()
	print("[SISTEMA] Tarjeta de nivel guardada correctamente.")
