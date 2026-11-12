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

@onready var sprite: Sprite2D = $Sprite2D # Cambia el nombre si tu sprite se llama diferente
@onready var label_letra: Label = $Label

func _ready() -> void:
	# Asigna los metadatos dinámicamente para que los lea PlayableLevel
	set_meta("grid_pos", grid_pos)
	set_meta("is_cheese", is_cheese)
	set_meta("char_val", char_val)
	update_position_from_grid()
	if is_cheese:
		sprite.visible = true
		label_letra.visible = false
	else:
		sprite.visible = false
		label_letra.visible = true
		label_letra.text = char_val # Muestra la letra que configuraste en el Inspector

# Posiciona el objeto centrado en la celda del TileMapLayer
func update_position_from_grid() -> void:
	position = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
