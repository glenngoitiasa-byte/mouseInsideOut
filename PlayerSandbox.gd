# res://scripts/PlayerSandbox.gd
class_name PlayerSandbox
extends RefCounted

# Referencia al nivel activo para notificar las acciones
var level_ref = null

func _init(p_level_ref = null) -> void:
	level_ref = p_level_ref

# Comandos expuestos al jugador
func avanzar() -> void:
	if level_ref:
		level_ref.append_console("[ACCION] avanzar()")

func girar_izquierda() -> void:
	if level_ref:
		level_ref.append_console("[ACCION] girar_izquierda()")

func girar_derecha() -> void:
	if level_ref:
		level_ref.append_console("[ACCION] girar_derecha()")
