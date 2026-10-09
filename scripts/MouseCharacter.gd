# res://scripts/MouseCharacter.gd
class_name MouseCharacter
extends Node2D

const TILE_SIZE: int = 32

var grid_pos: Vector2i = Vector2i(1, 1)
var current_dir_index: int = 1 # 0: Norte, 1: Este, 2: Sur, 3: Oeste
var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var active_tween: Tween = null

func _ready() -> void:
	update_world_position_instant()

# Cancela cualquier animación activa de forma segura
func kill_active_tween() -> void:
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
		active_tween = null

# Actualiza la velocidad del Tween en ejecución sin reiniciarlo (RQNF25)
func set_speed_scale(speed_scale: float) -> void:
	if active_tween != null and active_tween.is_valid() and active_tween.is_running():
		active_tween.set_speed_scale(max(speed_scale, 0.1))

func update_world_position_instant() -> void:
	kill_active_tween()
	position = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	rotation_degrees = current_dir_index * 90.0

# Animación fluida de desplazamiento (Base: 0.5 s a velocidad x1)
func move_to_grid(target_grid_pos: Vector2i, speed_scale: float = 1.0) -> void:
	kill_active_tween()
	grid_pos = target_grid_pos
	var target_world_pos = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	
	active_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.set_speed_scale(max(speed_scale, 0.1))
	active_tween.tween_property(self, "position", target_world_pos, 0.5)
	
	await active_tween.finished

# Animación de rotación (Base: 0.4 s a velocidad x1)
func turn(degrees_change: float, speed_scale: float = 1.0) -> void:
	kill_active_tween()
	var target_rotation = rotation_degrees + degrees_change
	
	active_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	active_tween.set_speed_scale(max(speed_scale, 0.1))
	active_tween.tween_property(self, "rotation_degrees", target_rotation, 0.4)
	
	await active_tween.finished
	
	if degrees_change > 0:
		current_dir_index = (current_dir_index + 1) % 4
	else:
		current_dir_index = (current_dir_index - 1 + 4) % 4

func get_facing_cell() -> Vector2i:
	return grid_pos + directions[current_dir_index]

func get_cell_in_direction(dir_offset: int) -> Vector2i:
	var target_index: int = (current_dir_index + dir_offset + 4) % 4
	return grid_pos + directions[target_index]

func reset_to_start(start_pos: Vector2i, dir_index: int = 1) -> void:
	grid_pos = start_pos
	current_dir_index = dir_index
	update_world_position_instant()
