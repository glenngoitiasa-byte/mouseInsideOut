# res://scripts/PlayerSandbox.gd
class_name PlayerSandbox
extends RefCounted

var level_ref = null
var my_execution_id: int = 0
var action_count: int = 0
var consecutive_sensor_calls: int = 0

const MAX_ACTIONS: int = 300
const MAX_SENSORS_WITHOUT_ACTION: int = 1000

func _init(p_level_ref = null, p_exec_id: int = 0) -> void:
	level_ref = p_level_ref
	my_execution_id = p_exec_id

# Comprueba si la instancia actual sigue siendo la ejecución activa
# Verifica si la ejecución actual sigue activa y en estado RUNNING
func _is_valid_execution() -> bool:
	return (
		level_ref != null 
		and level_ref.is_executing 
		and level_ref.level_state == "RUNNING" 
		and level_ref.current_execution_id == my_execution_id
	)

func _check_action_guard() -> bool:
	if not _is_valid_execution():
		return false
	consecutive_sensor_calls = 0
	action_count += 1
	if action_count > MAX_ACTIONS:
		if level_ref:
			level_ref.append_console("[ERROR BUCLE INFINITO] Se superó el límite de " + str(MAX_ACTIONS) + " acciones de movimiento.")
			level_ref.level_state = "GAME_OVER"
		return false
	return true

func _check_sensor_guard() -> bool:
	if not _is_valid_execution():
		return false
	consecutive_sensor_calls += 1
	if consecutive_sensor_calls > MAX_SENSORS_WITHOUT_ACTION:
		if level_ref:
			level_ref.append_console("[ERROR BUCLE INFINITO] Bucle detectado sin acciones de movimiento.")
			level_ref.level_state = "GAME_OVER"
		return false
	return true

# Si la ejecución ya no es válida, cede un fotograma para evitar bucles de CPU al 100%
func _safe_yield_cancel() -> void:
	if level_ref != null and level_ref.get_tree() != null:
		await level_ref.get_tree().process_frame

func avanzar():
	if not _check_action_guard():
		await _safe_yield_cancel()
		return
	await level_ref.execute_action("avanzar")

func girar_izquierda():
	if not _check_action_guard():
		await _safe_yield_cancel()
		return
	await level_ref.execute_action("girar_izquierda")

func girar_derecha():
	if not _check_action_guard():
		await _safe_yield_cancel()
		return
	await level_ref.execute_action("girar_derecha")

func frente_libre() -> bool:
	if not _is_valid_execution(): return false
	if not _check_sensor_guard(): return false
	return level_ref.is_front_free()

func izquierda_libre() -> bool:
	if not _is_valid_execution(): return false
	if not _check_sensor_guard(): return false
	return level_ref.is_left_free()

func derecha_libre() -> bool:
	if not _is_valid_execution(): return false
	if not _check_sensor_guard(): return false
	return level_ref.is_right_free()
