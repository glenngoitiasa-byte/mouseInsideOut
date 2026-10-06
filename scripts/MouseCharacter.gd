# res://scripts/MouseCharacter.gd
class_name MouseCharacter
extends Area2D

const TILE_SIZE: int = 32

# Coordenadas en la cuadrícula
var grid_pos: Vector2i = Vector2i(1, 1)

# Direcciones: 0 = Norte (0, -1), 1 = Este (1, 0), 2 = Sur (0, 1), 3 = Oeste (-1, 0)
var current_dir_index: int = 1 # Inicia mirando al Este
var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

# Convierte la posición de celda a posición global (centrada en la celda)
func update_world_position_instant() -> void:
	position = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	rotation_degrees = current_dir_index * 90.0

# Animación de giro
func turn(degrees_change: float, duration: float) -> void:
	var target_rotation = rotation_degrees + degrees_change
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation_degrees", target_rotation, duration)
	await tween.finished
	
	# Normalizar la dirección
	if degrees_change > 0:
		current_dir_index = (current_dir_index + 1) % 4
	else:
		current_dir_index = (current_dir_index - 1 + 4) % 4

# Animación de avance
func move_to_grid(target_grid_pos: Vector2i, duration: float) -> void:
	grid_pos = target_grid_pos
	var target_world_pos = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", target_world_pos, duration)
	await tween.finished

# Obtener la celda hacia la que está mirando
func get_facing_cell() -> Vector2i:
	return grid_pos + directions[current_dir_index]
