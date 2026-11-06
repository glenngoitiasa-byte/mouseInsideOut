
extends Node

# Emitimos esta señal para que la interfaz pueda mostrar un pop-up o notificación
signal achievement_unlocked(id: int, description: String)

const ACHIEVEMENTS_DATA = {
	1: "Completa los cuatro niveles predefinidos.",
	2: "Completa los cuatro niveles con calificación B o superior.",
	3: "Completa los cuatro niveles con calificación S.",
	4: "Recoge todos los quesos en el nivel 1.",
	5: "Recoge todos los quesos en el nivel 2.",
	6: "Recoge todos los quesos en el nivel 3.",
	7: "Recoge todos los quesos en el nivel 4.",
	8: "Recoge todos los quesos en los 4 niveles predefinidos.",
	9: "Alcanza la victoria en 3 niveles aleatorios.",
	10: "Alcanza la victoria en 5 niveles aleatorios.",
	11: "Alcanza la victoria en 10 niveles aleatorios.",
	12: "Alcanza la calificación S en 10 niveles aleatorios.",
	13: "Completa 1 nivel aleatorio con insignia bronce.",
	14: "Completa 2 niveles aleatorios con insignia bronce.",
	15: "Completa 3 niveles aleatorios con insignia bronce.",
	16: "Completa 1 nivel aleatorio con insignia plata.",
	17: "Completa 2 niveles aleatorios con insignia plata.",
	18: "Completa 3 niveles aleatorios con insignia plata.",
	19: "Completa 1 nivel aleatorio con insignia oro.",
	20: "Completa 2 niveles aleatorios con insignia oro.",
	21: "Completa 3 niveles aleatorios con insignia oro.",
	22: "Completa 1 nivel aleatorio en modo oscuro.",
	23: "Completa 3 niveles aleatorios en modo oscuro.",
	24: "Completa 1 nivel aleatorio en modo contraseña.",
	25: "Completa 3 niveles aleatorios en modo contraseña."
}

func check_achievements() -> void:
	var stats = SaveManager.current_save["player_stats"]
	var best_scores = stats["best_scores"]
	var unlocked = stats["achievements"]

	# --- LÓGICA DE HISTORIA (1 al 8) ---
	var history_completed = 0
	var history_b_or_better = 0
	var history_s_rank = 0
	var all_cheeses_count = 0
	
	for i in range(1, 5):
		var lvl_key = str(i)
		if best_scores.has(lvl_key):
			history_completed += 1
			
			var rank = best_scores[lvl_key]["rank"]
			if rank in ["S", "A", "B"]: history_b_or_better += 1
			if rank == "S": history_s_rank += 1
			
			if best_scores[lvl_key].get("all_cheeses", false):
				all_cheeses_count += 1
				_unlock(i + 3) # Logros 4, 5, 6, 7 (Niveles 1 al 4)

	if history_completed >= 4: _unlock(1)
	if history_b_or_better >= 4: _unlock(2)
	if history_s_rank >= 4: _unlock(3)
	if all_cheeses_count >= 4: _unlock(8)

	# --- LÓGICA ALEATORIA (9 al 25) ---
	var rw = stats["random_wins"]
	if rw >= 3: _unlock(9)
	if rw >= 5: _unlock(10)
	if rw >= 10: _unlock(11)
	
	if stats["random_s_ranks"] >= 10: _unlock(12)
	
	var bw = stats["bronze_wins"]
	if bw >= 1: _unlock(13)
	if bw >= 2: _unlock(14)
	if bw >= 3: _unlock(15)
	
	var sw = stats["silver_wins"]
	if sw >= 1: _unlock(16)
	if sw >= 2: _unlock(17)
	if sw >= 3: _unlock(18)
	
	var gw = stats["gold_wins"]
	if gw >= 1: _unlock(19)
	if gw >= 2: _unlock(20)
	if gw >= 3: _unlock(21)
	
	var dw = stats["dark_mode_wins"]
	if dw >= 1: _unlock(22)
	if dw >= 3: _unlock(23)
	
	var pw = stats["password_wins"]
	if pw >= 1: _unlock(24)
	if pw >= 3: _unlock(25)

func _unlock(id: int) -> void:
	var unlocked_list: Array = SaveManager.current_save["player_stats"]["achievements"]
	if not unlocked_list.has(id):
		unlocked_list.append(id)
		SaveManager.save_game()
		achievement_unlocked.emit(id, ACHIEVEMENTS_DATA[id])
		print("[LOGRO DESBLOQUEADO] ", ACHIEVEMENTS_DATA[id])
