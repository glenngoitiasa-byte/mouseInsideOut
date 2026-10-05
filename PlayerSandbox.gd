# res://scripts/PlayerSandbox.gd
class_name PlayerSandbox
extends RefCounted

var level_ref = null

func _init(p_level_ref = null) -> void:
	level_ref = p_level_ref

# Comandos convertidos en corrutinas asíncronas
func avanzar() -> void:
	if level_ref and level_ref.is_executing:
		await level_ref.execute_action("avanzar")

func girar_izquierda() -> void:
	if level_ref and level_ref.is_executing:
		await level_ref.execute_action("girar_izquierda")

func girar_derecha() -> void:
	if level_ref and level_ref.is_executing:
		await level_ref.execute_action("girar_derecha")
