# res://scripts/GlobalState.gd
extends Node

var current_selected_level: int = 1
var is_random_mode: bool = false
var current_seed: int = 0
var current_maze_width: int = 15
var current_maze_height: int = 15
var current_cheese_count: int = 0

func complete_history_level(level_num: int, cheeses_collected: int, steps: int, rank: String) -> void:
	if level_num >= SaveManager.current_save["history_levels_unlocked"]:
		SaveManager.current_save["history_levels_unlocked"] = level_num + 1
		
	SaveManager.current_save["player_stats"]["total_cheeses"] += cheeses_collected
	
	# Guardar estadísticas específicas del nivel
	var best_scores = SaveManager.current_save["player_stats"]["best_scores"]
	var lvl_key = str(level_num)
	
	# Si ya existía un registro, podrías comparar si el nuevo rango es mejor. 
	# Por ahora, simplemente sobrescribimos con la victoria más reciente:
	best_scores[lvl_key] = {
		"rank": rank,
		"steps": steps,
		"cheeses": cheeses_collected
	}
	
	SaveManager.save_game()

func complete_random_level(seed_value: int, cheeses: int, steps: int, lines: int, rank: String) -> void:
	var level_key = "random_" + str(seed)
	var stats = SaveManager.current_save["player_stats"]
	
	if not stats["best_scores"].has(level_key):
		stats["best_scores"][level_key] = {
			"rank": rank,
			"best_steps": steps,
			"best_lines": lines,
			"max_cheeses": cheeses
		}
	else:
		var current_record = stats["best_scores"][level_key]
		# Actualizar récord de pasos si es menor
		if steps < current_record["best_steps"]:
			current_record["best_steps"] = steps
		# Actualizar récord de líneas si es menor
		if lines < current_record["best_lines"]:
			current_record["best_lines"] = lines
			
		# Actualizar el rango solo si el nuevo es mejor (opcional según tu jerarquía)
		current_record["rank"] = rank # Asume que el último jugado con éxito sobreescribe el rango actual
		
	SaveManager.save_game()

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
