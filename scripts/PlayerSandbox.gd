# res://scripts/PlayerSandbox.gd
class_name PlayerSandbox
extends RefCounted

var level_ref = null
var loop_counter: int = 0
const MAX_ITERATIONS: int = 300

func _init(p_level_ref = null) -> void:
	level_ref = p_level_ref

# Verifica si se excedió el límite de iteraciones en bucles
func _check_loop_guard() -> bool:
	loop_counter += 1
	if loop_counter > MAX_ITERATIONS:
		if level_ref:
			level_ref.append_console("[ERROR BUCLE INFINITO] Se superó el límite de " + str(MAX_ITERATIONS) + " iteraciones.")
			level_ref.level_state = "GAME_OVER"
		return false
	return true

func avanzar():
	if not _check_loop_guard(): return
	if level_ref and level_ref.is_executing and level_ref.level_state == "RUNNING":
		await level_ref.execute_action("avanzar")

func girar_izquierda():
	if not _check_loop_guard(): return
	if level_ref and level_ref.is_executing and level_ref.level_state == "RUNNING":
		await level_ref.execute_action("girar_izquierda")

func girar_derecha():
	if not _check_loop_guard(): return
	if level_ref and level_ref.is_executing and level_ref.level_state == "RUNNING":
		await level_ref.execute_action("girar_derecha")

func frente_libre() -> bool:
	if not _check_loop_guard(): return false
	if level_ref:
		return level_ref.is_front_free()
	return false

func izquierda_libre() -> bool:
	if not _check_loop_guard(): return false
	if level_ref:
		return level_ref.is_left_free()
	return false

func derecha_libre() -> bool:
	if not _check_loop_guard(): return false
	if level_ref:
		return level_ref.is_right_free()
	return false
