# res://scripts/PlayerSandbox.gd
class_name PlayerSandbox
extends RefCounted

var level_ref = null

func _init(p_level_ref = null) -> void:
	level_ref = p_level_ref

# Comandos de movimiento
func avanzar():
	if level_ref and level_ref.is_executing:
		await level_ref.execute_action("avanzar")

func girar_izquierda():
	if level_ref and level_ref.is_executing:
		await level_ref.execute_action("girar_izquierda")

func girar_derecha():
	if level_ref and level_ref.is_executing:
		await level_ref.execute_action("girar_derecha")

# Sensores booleanos (Día 5 - RQNF26, RQNF27)
func frente_libre() -> bool:
	if level_ref:
		return level_ref.is_front_free()
	return false

func izquierda_libre() -> bool:
	if level_ref:
		return level_ref.is_left_free()
	return false

func derecha_libre() -> bool:
	if level_ref:
		return level_ref.is_right_free()
	return false
