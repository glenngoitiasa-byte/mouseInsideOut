# res://scripts/MouseCharacter.gd
class_name MouseCharacter
extends Node2D

const TILE_SIZE: int = 32

var grid_pos: Vector2i = Vector2i(1, 1)
var current_dir_index: int = 1 # 0: Norte, 1: Este, 2: Sur, 3: Oeste
var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

func _ready() -> void:
	# Centrar el origen del sprite en la celda (16, 16)
	update_world_position_instant()

# Ubica al personaje centrado en la celda de la cuadrícula
func update_world_position_instant() -> void:
	position = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	rotation_degrees = current_dir_index * 90.0

# Animación fluida de desplazamiento por suelo
func move_to_grid(target_grid_pos: Vector2i, duration: float) -> void:
	grid_pos = target_grid_pos
	var target_world_pos = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", target_world_pos, duration)
	await tween.finished

# Animación de rotación
func turn(degrees_change: float, duration: float) -> void:
	var target_rotation = rotation_degrees + degrees_change
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation_degrees", target_rotation, duration)
	await tween.finished
	
	if degrees_change > 0:
		current_dir_index = (current_dir_index + 1) % 4
	else:
		current_dir_index = (current_dir_index - 1 + 4) % 4

func get_facing_cell() -> Vector2i:
	return grid_pos + directions[current_dir_index]

# Reubica al personaje en la celda y dirección iniciales
func reset_to_start(start_pos: Vector2i, dir_index: int = 1) -> void:
	grid_pos = start_pos
	current_dir_index = dir_index
	update_world_position_instant()

# Retorna la celda hacia la que apunta la orientación relativa dada
func get_cell_in_direction(dir_offset: int) -> Vector2i:
	var target_index = (current_dir_index + dir_offset + 4) % 4
	return grid_pos + directions[target_index]
