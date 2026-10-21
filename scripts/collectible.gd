# res://scripts/Collectible.gd
class_name Collectible
extends Node2D

const TILE_SIZE: int = 32

@export var grid_pos: Vector2i = Vector2i(5, 7):
	set(value):
		grid_pos = value
		update_position_from_grid()

@export var is_cheese: bool = true
@export var char_val: String = ""

func _ready() -> void:
	# Asigna los metadatos dinámicamente para que los lea PlayableLevel
	set_meta("grid_pos", grid_pos)
	set_meta("is_cheese", is_cheese)
	set_meta("char_val", char_val)
	update_position_from_grid()

# Posiciona el objeto centrado en la celda del TileMapLayer
func update_position_from_grid() -> void:
	position = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
