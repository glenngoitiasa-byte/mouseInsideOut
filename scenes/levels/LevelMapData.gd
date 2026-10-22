# res://scenes/levels/LevelMapData.gd
extends Node2D

@export var start_cell: Vector2i = Vector2i(1, 1)
@export var start_dir_index: int = 1 # 1 = Este
@export var goal_cell: Vector2i = Vector2i(1, 14)
