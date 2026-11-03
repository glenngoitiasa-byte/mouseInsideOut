class_name GradingEngine

static func calculate_history_rank(
	cheeses: int, max_cheeses: int,
	lines: int, ideal_lines: int,
	steps: int, ideal_steps: int,
	collisions: int
) -> String:
	
	var score: float = 100.0

	# 1. Quesos (Alta prioridad: perder un queso resta drásticamente)
	if max_cheeses > 0:
		var missing_cheeses = max_cheeses - cheeses
		score -= missing_cheeses * (40.0 / max_cheeses) 
		
	# 2. Líneas de código (Castigo por código redundante)
	if lines > ideal_lines:
		var extra_lines = lines - ideal_lines
		score -= extra_lines * 5.0 # -5 puntos por línea extra

	# 3. Pasos (Castigo por rutas ineficientes o bucles innecesarios)
	if steps > ideal_steps:
		var extra_steps = steps - ideal_steps
		score -= extra_steps * 2.0 # -2 puntos por paso extra

	# 4. Choques (Castigo por golpear paredes)
	score -= collisions * 10.0 # -10 puntos por cada golpe frontal
	
	# Asegurar límite inferior
	score = max(score, 0.0)

	# Asignar Rango
	if score >= 95.0: return "S"
	elif score >= 80.0: return "A"
	elif score >= 60.0: return "B"
	elif score >= 40.0: return "C"
	else: return "D"
