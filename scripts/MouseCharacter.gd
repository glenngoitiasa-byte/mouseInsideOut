# res://scripts/MouseCharacter.gd
class_name MouseCharacter
extends Node2D

const TILE_SIZE: int = 32

var grid_pos: Vector2i = Vector2i(1, 1)
var current_dir_index: int = 1 # 0: Norte, 1: Este, 2: Sur, 3: Oeste
var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

# Variables de configuración del zoom
@onready var camera: Camera2D = $Camera2D
var zoom_min: float = 0.8  # Límite máximo para alejar (zoom out)
var zoom_max: float = 3.0  # Límite máximo para acercar (zoom in)
var zoom_step: float = 0.25 # Cuánto cambia el zoom por cada "clic" de la rueda
var current_target_zoom: float = 2.5 # Nivel de zoom inicial

var active_tween: Tween = null

func _ready() -> void:
	camera.zoom = Vector2(current_target_zoom, current_target_zoom)
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

# res://scripts/MouseCharacter.gd

func move_to_grid(target_grid_pos: Vector2i, speed_scale: float = 1.0) -> void:
	kill_active_tween()
	grid_pos = target_grid_pos
	var target_world_pos = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	
	active_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.set_speed_scale(max(speed_scale, 0.1))
	active_tween.tween_property(self, "position", target_world_pos, 0.5)
	
	# Si el tween fue destruido o no es válido, no hace await para no congelar el hilo
	if active_tween != null and active_tween.is_valid():
		await active_tween.finished

func turn(degrees_change: float, speed_scale: float = 1.0) -> void:
	kill_active_tween()
	var target_rotation = rotation_degrees + degrees_change
	
	active_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	active_tween.set_speed_scale(max(speed_scale, 0.1))
	active_tween.tween_property(self, "rotation_degrees", target_rotation, 0.4)
	
	if active_tween != null and active_tween.is_valid():
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

func _unhandled_input(event: InputEvent) -> void:
	# Filtramos para que solo reaccione a botones del ratón al ser presionados
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_aplicar_zoom(zoom_step) # Rueda hacia arriba -> Acercar
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_aplicar_zoom(-zoom_step) # Rueda hacia abajo -> Alejar

func _aplicar_zoom(cambio: float) -> void:
	# clamp() asegura que el valor nunca baje de zoom_min ni pase de zoom_max
	current_target_zoom = clamp(current_target_zoom + cambio, zoom_min, zoom_max)
	
	# Usamos un Tween muy rápido (0.15s) para que el salto del scroll se sienta suave
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "zoom", Vector2(current_target_zoom, current_target_zoom), 0.15)
