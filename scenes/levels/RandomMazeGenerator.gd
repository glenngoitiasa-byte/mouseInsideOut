# res://scenes/levels/RandomMazeGenerator.gd
extends "res://scenes/levels/LevelMapData.gd"

@onready var tilemap: TileMapLayer = $TileMapLayer

# Dimensiones del laberinto (Deben ser números IMPARES para que las paredes funcionen bien)
@export var width: int = 15
@export var height: int = 15
@export var wall_source_id: int = 0
@export var floor_source_id: int = 1

# Coordenadas en tu TileSet (Ajusta estos valores a tu atlas)
@export var wall_atlas_coord: Vector2i = Vector2i(0, 0) # Celda de pared
@export var floor_atlas_coord: Vector2i = Vector2i(0, 0) # -1 borra el tile (suelo vacío) o usa Vector2i(1,0)

var rng := RandomNumberGenerator.new()

func generate_seeded_maze(seed_value: int) -> void:
	rng.seed = seed_value
	print("[GENERADOR] Construyendo laberinto con semilla: ", seed_value)
	
	_fill_with_walls()
	
	# Iniciamos la excavación en la celda (1, 1)
	start_cell = Vector2i(1, 1)
	_carve_path(start_cell.x, start_cell.y)
	
	# Colocar la meta en la esquina opuesta inferior derecha
	goal_cell = Vector2i(width - 2, height - 2)
	# Asegurarnos de que la meta sea caminable
	tilemap.set_cell(goal_cell, floor_source_id, floor_atlas_coord)
	
	# TODO: Aquí puedes instanciar el sprite del Queso en la goal_cell

func _fill_with_walls() -> void:
	for x in range(width):
		for y in range(height):
			# Asume que tu TileSet está en el source_id 0
			tilemap.set_cell(Vector2i(x, y), wall_source_id, wall_atlas_coord)

func _carve_path(cx: int, cy: int) -> void:
	# Convertimos la celda actual en suelo
	tilemap.set_cell(Vector2i(cx, cy), floor_source_id, floor_atlas_coord)
	
	# Posibles direcciones: Norte, Sur, Este, Oeste (saltando 2 celdas)
	var directions = [Vector2i(0, -2), Vector2i(0, 2), Vector2i(-2, 0), Vector2i(2, 0)]
	
	# Mezclar direcciones usando nuestro RNG específico para garantizar reproducibilidad
	_shuffle_array_with_rng(directions)
	
	for dir in directions:
		var nx = cx + dir.x
		var ny = cy + dir.y
		
		# Verificar límites del mapa
		if nx > 0 and nx < width - 1 and ny > 0 and ny < height - 1:
			# Si la celda vecina es una pared, excavamos hacia ella
			if tilemap.get_cell_source_id(Vector2i(nx, ny)) == wall_source_id:
				# Derribar la pared intermedia
				tilemap.set_cell(Vector2i(cx + dir.x / 2, cy + dir.y / 2), floor_source_id, floor_atlas_coord)
				# Llamada recursiva
				_carve_path(nx, ny)

# Mezcla de Fisher-Yates personalizada (Array.shuffle usa el RNG global, nosotros necesitamos el seeded)
func _shuffle_array_with_rng(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp
