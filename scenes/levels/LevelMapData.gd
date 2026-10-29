# res://scenes/levels/LevelMapData.gd
extends Node2D

@export_group("Configuración de Posición")
## Coordenadas de la celda donde inicia el ratón en la cuadrícula
@export var start_cell: Vector2i = Vector2i(1, 1)

## Orientación inicial del ratón (0: Norte, 1: Este, 2: Sur, 3: Oeste)
@export var start_dir_index: int = 1 

## Coordenadas de la celda de la meta
@export var goal_cell: Vector2i = Vector2i(1, 14)

@export_group("Configuración Ambiental y Mecánicas")
## Activa el ambiente oscuro y la linterna en el ratón (útil para el Nivel 4)
@export var is_dark_level: bool = false

## Palabras clave permitidas en el editor de código para este nivel (dejar vacío si no hay restricción)
@export var allowed_keywords: Array[String] = []
