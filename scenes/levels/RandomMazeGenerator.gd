# res://scenes/levels/RandomMazeGenerator.gd
extends "res://scenes/levels/LevelMapData.gd"

@onready var tilemap: TileMapLayer = $TileMapLayer

# Dimensiones del laberinto (Deben ser números IMPARES para que las paredes funcionen bien)
@export var width: int = 15
@export var height: int = 15
@export var wall_source_id: int = 0
@export var floor_source_id: int = 1
# (Añade esto arriba con tus otros @export)
@export var entrance_source_id: int = 2 # ID de tu tile de entrada
@export var goal_source_id: int = 3 # ID de tu tile de salida
@export var cheese_scene: PackedScene # Arrastra aquí tu escena Cheese.tscn en el Inspecto

# Coordenadas en tu TileSet (Ajusta estos valores a tu atlas)
@export var wall_atlas_coord: Vector2i = Vector2i(0, 0) # Celda de pared
@export var floor_atlas_coord: Vector2i = Vector2i(0, 0) # -1 borra el tile (suelo vacío) o usa Vector2i(1,0)

var rng := RandomNumberGenerator.new()
var floor_cells: Array[Vector2i] = [] # Para guardar dónde podemos poner quesos

func generate_seeded_maze(seed_value: int) -> void:
	rng.seed = seed_value
	
	# Leer el tamaño desde la interfaz
	width = GlobalState.current_maze_width
	height = GlobalState.current_maze_height
	floor_cells.clear()
	
	_fill_with_walls()
	
	start_cell = Vector2i(1, 1)
	_carve_path(start_cell.x, start_cell.y)
	
	# Dibujar Entrada y Salida
	goal_cell = Vector2i(width - 2, height - 2)
	tilemap.set_cell(start_cell, entrance_source_id, Vector2i(0,0))
	tilemap.set_cell(goal_cell, goal_source_id, Vector2i(0,0))
	
	_spawn_cheeses()

func _fill_with_walls() -> void:
	for x in range(width):
		for y in range(height):
			# Asume que tu TileSet está en el source_id 0
			tilemap.set_cell(Vector2i(x, y), wall_source_id, wall_atlas_coord)

func _carve_path(cx: int, cy: int) -> void:
	# Convertimos la celda actual en suelo
	tilemap.set_cell(Vector2i(cx, cy), floor_source_id, floor_atlas_coord)
	if not floor_cells.has(Vector2i(cx, cy)):
		floor_cells.append(Vector2i(cx, cy))
		
	# Posibles direcciones: Norte, Sur, Este, Oeste
	var directions = [Vector2i(0, -2), Vector2i(0, 2), Vector2i(-2, 0), Vector2i(2, 0)]
	
	# Mezclar direcciones
	_shuffle_array_with_rng(directions)
	
	for dir in directions:
		var nx = cx + dir.x
		var ny = cy + dir.y
		var wall_pos = Vector2i(cx + dir.x / 2, cy + dir.y / 2)
		
		# Verificar límites del mapa
		if nx > 0 and nx < width - 1 and ny > 0 and ny < height - 1:
			# Si la celda vecina es una pared, excavamos hacia ella
			if tilemap.get_cell_source_id(Vector2i(nx, ny)) == wall_source_id:
				# Derribar la pared intermedia de forma segura
				tilemap.set_cell(wall_pos, floor_source_id, floor_atlas_coord)
				if not floor_cells.has(wall_pos):
					floor_cells.append(wall_pos)
					
				# Llamada recursiva
				_carve_path(nx, ny)

func _spawn_cheeses() -> void:
	if GlobalState.current_cheese_count <= 0 or cheese_scene == null: return
	
	# Buscar o crear el contenedor
	var collectibles = get_node_or_null("Collectibles")
	if collectibles == null:
		collectibles = Node2D.new()
		collectibles.name = "Collectibles"
		add_child(collectibles)
	else:
		# ¡LIMPIEZA! Eliminar cualquier queso residual de generaciones previas
		for child in collectibles.get_children():
			child.queue_free()
			
	# Quitar entrada y salida para no poner quesos ahí
	floor_cells.erase(start_cell)
	floor_cells.erase(goal_cell)
	
	_shuffle_array_with_rng(floor_cells)
	
	var max_cheeses = min(GlobalState.current_cheese_count, floor_cells.size())
	for i in range(max_cheeses):
		var cheese = cheese_scene.instantiate()
		var map_pos = floor_cells[i]
		
		# Ajusta el multiplicador según el tamaño de tu tile (ej. 32x32 o 16x16)
		cheese.grid_pos = map_pos
		collectibles.add_child(cheese)

# Mezcla de Fisher-Yates personalizada (Array.shuffle usa el RNG global, nosotros necesitamos el seeded)
func _shuffle_array_with_rng(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp
