# res://scripts/GlobalState.gd
extends Node

var current_selected_level: int = 1
var is_random_mode: bool = false
var current_seed: int = 0
var current_maze_width: int = 15
var current_maze_height: int = 15
var current_cheese_count: int = 0

func complete_history_level(level_num: int, cheeses_collected: int) -> void:
	# 1. Desbloquear el siguiente nivel si es la primera vez que se pasa
	if level_num >= SaveManager.current_save["history_levels_unlocked"]:
		SaveManager.current_save["history_levels_unlocked"] = level_num + 1
		
	# 2. Actualizar estadísticas globales
	SaveManager.current_save["player_stats"]["total_cheeses"] += cheeses_collected
	
	# 3. Guardar en disco duro (genera JSON, SHA-256 y Backup)
	SaveManager.save_game()
