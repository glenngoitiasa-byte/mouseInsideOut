# res://scripts/BaseMap.gd
extends Node2D

@export var max_cheeses: int = 1
@export var ideal_steps: int = 15
@export var ideal_lines: int = 5
@export var allowed_keywords: Array[String] = ["avanzar", "girar_izquierda", "girar_derecha"]
@export var start_cell: Vector2i = Vector2i(1, 1)
@export var start_dir_index: int = 1
@export var goal_cell: Vector2i = Vector2i(1, 10)
