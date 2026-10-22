# res://scenes/PlayableLevel.gd
extends Control

# Configuración de mapa
var START_CELL: Vector2i = Vector2i(1, 1)
var START_DIR_INDEX: int = 1 # 1 = Este (Mirando a la derecha)
var GOAL_CELL: Vector2i = Vector2i(1, 14) # Coordenada de la salida/queso
const MAX_COLLISIONS: int = 5
const MAX_CONSOLE_LINES: int = 150

# Referencias a nodos de UI
@onready var code_editor: CodeEdit = $MainHBox/RightVBox/CodeEditor
@onready var console_log: RichTextLabel = $MainHBox/LeftVBox/ConsoleContainer/ConsoleLog
@onready var btn_execute: Button = $MainHBox/RightVBox/ControlsHBox/BtnExecute
@onready var btn_stop: Button = $MainHBox/RightVBox/ControlsHBox/BtnStop
@onready var btn_clear: Button = $MainHBox/RightVBox/ControlsHBox/BtnClear
@onready var speed_slider: HSlider = $MainHBox/RightVBox/ControlsHBox/SpeedSlider

# Referencias a nodos de la escena
@onready var mouse_character: MouseCharacter = $MainHBox/LeftVBox/MazeArea/SubViewportContainer/SubViewport/Node2D/MouseCharacter
@onready var map_container: Node2D = $MainHBox/LeftVBox/MazeArea/SubViewportContainer/SubViewport/Node2D

# Referencias dinámicas (Se asignan en runtime al cargar el nivel)
var tilemap_layer: TileMapLayer = null
var collectibles_node: Node2D = null
var current_map_node: Node2D = null

# Estado del nivel y Recolectables
var is_executing: bool = false
var execution_start_time: float = 0.0
var collision_count: int = 0
var cheese_count: int = 0
var password_collected: Array[String] = []
var level_state: String = "READY"
var step_count: int = 0
var current_execution_id: int = 0
var console_line_count: int = 0


func _ready() -> void:
	# Configurar el rango del slider de velocidad según RQNF25 (x0.25 a x3.0)
	speed_slider.min_value = 0.25
	speed_slider.max_value = 3.0
	speed_slider.step = 0.05
	speed_slider.value = 1.0
	speed_slider.custom_minimum_size.x = 140
	speed_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Conectar señal de cambio de velocidad en tiempo real
	speed_slider.value_changed.connect(_on_speed_slider_value_changed)
	
	btn_execute.pressed.connect(_on_btn_execute_pressed)
	btn_stop.pressed.connect(_on_btn_stop_pressed)
	btn_clear.pressed.connect(_on_btn_clear_pressed)
	
	console_log.scroll_following = true
	current_level_number = GlobalState.current_selected_level
	_load_active_map()
	_reset_to_entrance()

func _load_active_map() -> void:
	# 1. Limpiar mapa anterior si existe
	if current_map_node != null:
		current_map_node.queue_free()
	
	# 2. Cargar subescena correspondiente
	var map_path: String = "res://scenes/levels/level_0" + str(current_level_number) + ".tscn"
	if not ResourceLoader.exists(map_path):
		append_console("[ERROR] No se encontró el recurso: " + map_path)
		return
		
	var map_scene = load(map_path)
	current_map_node = map_scene.instantiate()
	
	# 3. Insertar mapa antes del ratón para que quede en el fondo
	map_container.add_child(current_map_node)
	map_container.move_child(current_map_node, 0)
	
	# 4. Vincular referencias de TileMap, Collectibles y Coordenadas
	tilemap_layer = current_map_node.get_node_or_null("TileMapLayer")
	collectibles_node = current_map_node.get_node_or_null("Collectibles")
	
	if "start_cell" in current_map_node:
		START_CELL = current_map_node.start_cell
		START_DIR_INDEX = current_map_node.start_dir_index
		GOAL_CELL = current_map_node.goal_cell

func _on_speed_slider_value_changed(new_value: float) -> void:
	if mouse_character != null:
		mouse_character.set_speed_scale(new_value)

func append_console(message: String) -> void:
	if console_log == null:
		return
		
	console_line_count += 1
	
	# Evita el error 'Element limit reached' en RichTextLabel purgando el historial antiguo
	if console_line_count > MAX_CONSOLE_LINES:
		console_log.clear()
		console_line_count = 1
		console_log.append_text("[SISTEMA] Consola purgada automáticamente por límite de memoria.\n")
		
	console_log.append_text(message + "\n")

# --- SENSORES (RQNF26, RQNF27) ---
func is_front_free() -> bool:
	if mouse_character == null: return false
	return _is_cell_free(mouse_character.get_cell_in_direction(0))

func is_left_free() -> bool:
	if mouse_character == null: return false
	return _is_cell_free(mouse_character.get_cell_in_direction(-1))

func is_right_free() -> bool:
	if mouse_character == null: return false
	return _is_cell_free(mouse_character.get_cell_in_direction(1))

func _is_cell_free(cell_pos: Vector2i) -> bool:
	if _is_out_of_bounds(cell_pos):
		return false
	# RQNF26: Consulta source_id del TileMapLayer
	if tilemap_layer != null and tilemap_layer.get_cell_source_id(cell_pos) == -1:
		return false # Celda vacía/sin terreno
	return not _is_wall(cell_pos)

# --- RECOLECTABLES (RQNF30, RQNF31, RQNF32) ---
func _check_collectibles(cell_pos: Vector2i) -> void:
	if collectibles_node == null: return

	for item in collectibles_node.get_children():
		if item is Node2D and item.visible:
			var item_grid_pos = item.get_meta("grid_pos", Vector2i(-1, -1))
			if item_grid_pos == cell_pos:
				item.visible = false # RQNF31: Oculta sprite al pasar sobre la celda
				if item.has_meta("is_cheese") and item.get_meta("is_cheese"):
					cheese_count += 1
					append_console("[QUESO] ¡Queso recolectado! Total: " + str(cheese_count))
				elif item.has_meta("char_val"):
					var val: String = str(item.get_meta("char_val"))
					password_collected.append(val)
					append_console("[CONTRASEÑA] Letra recolectada: " + val)

func _reset_collectibles() -> void:
	cheese_count = 0
	password_collected.clear()
	if collectibles_node != null:
		for item in collectibles_node.get_children():
			if item is Node2D:
				item.visible = true # RQNF32: Reaparece todos los objetos

func _reset_to_entrance() -> void:
	if mouse_character != null:
		mouse_character.reset_to_start(START_CELL, START_DIR_INDEX)
	collision_count = 0
	step_count = 0
	level_state = "READY"
	_reset_collectibles()

func execute_action(action_name: String):
	if not is_executing or mouse_character == null or level_state == "VICTORY" or level_state == "GAME_OVER":
		return

	var speed_scale: float = max(speed_slider.value, 0.1)

	match action_name:
		"avanzar":
			var target_cell = mouse_character.get_facing_cell()
			
			if _is_out_of_bounds(target_cell) or _is_wall(target_cell):
				collision_count += 1
				append_console("[COLISIÓN] Impacto en celda " + str(target_cell) + ". Total choques: " + str(collision_count))
				
				if collision_count >= MAX_COLLISIONS:
					level_state = "GAME_OVER"
					append_console("[DERROTA] Demasiadas colisiones acumuladas.")
					return
				
				await get_tree().create_timer(0.2 / speed_scale).timeout
			else:
				step_count += 1
				append_console("[MOVIMIENTO] Avanzando a " + str(target_cell))
				await mouse_character.move_to_grid(target_cell, speed_scale)
				
				_check_collectibles(target_cell)
				
				if target_cell == GOAL_CELL:
					level_state = "VICTORY"
					append_console("-------------------------------------------")
					append_console("[¡VICTORIA!] ¡El ratón alcanzó la meta en " + str(target_cell) + "!")
					append_console("-------------------------------------------")

		"girar_izquierda":
			step_count += 1
			append_console("[GIRO] Izquierda")
			await mouse_character.turn(-90.0, speed_scale)

		"girar_derecha":
			step_count += 1
			append_console("[GIRO] Derecha")
			await mouse_character.turn(90.0, speed_scale)

func _is_out_of_bounds(cell_pos: Vector2i) -> bool:
	if tilemap_layer == null: return true
	return not tilemap_layer.get_used_rect().has_point(cell_pos)

func _is_wall(cell_pos: Vector2i) -> bool:
	if tilemap_layer == null: return true
	var tile_data: TileData = tilemap_layer.get_cell_tile_data(cell_pos)
	if tile_data == null: return true
	return tile_data.get_collision_polygons_count(0) > 0

func _on_btn_execute_pressed() -> void:
	if is_executing: return
	var user_code: String = code_editor.text.strip_edges()
	if user_code.is_empty():
		append_console("[ERROR] El editor está vacío.")
		return
	
	_reset_to_entrance()
	_compile_and_run(user_code)

# res://scenes/PlayableLevel.gd (Añadir constante de nivel actual)
@export var current_level_number: int = 3 # Nivel activo para filtrar instrucciones

func _compile_and_run(raw_code: String) -> void:
	current_execution_id += 1 # Invalida cualquier corrutina previa que siga viva
	is_executing = true
	level_state = "RUNNING"
	code_editor.editable = false
	execution_start_time = Time.get_ticks_msec()
	
	append_console("[SISTEMA] Validando código...")
	
	var validation: CodeValidator.ValidationResult = CodeValidator.validate_code(raw_code, current_level_number)
	if not validation.is_valid:
		append_console("[ERROR SINTAXIS] Línea " + str(validation.line_number) + ": " + validation.error_message)
		_reset_execution_state()
		return

	var script_source: String = "extends PlayerSandbox\n\nfunc run():\n"
	var lines: PackedStringArray = raw_code.split("\n")
	
	for line in lines:
		var trimmed = line.strip_edges()
		if trimmed.is_empty():
			continue
		
		var indent_len: int = line.length() - line.lstrip(" \t").length()
		var leading_indent: String = line.left(indent_len).replace("    ", "\t")
		
		# Inyección automática de await en comandos de movimiento
		if trimmed.begins_with("avanzar") or trimmed.begins_with("girar_izquierda") or trimmed.begins_with("girar_derecha"):
			script_source += "\t" + leading_indent + "await " + trimmed + "\n"
		else:
			script_source += "\t" + leading_indent + trimmed + "\n"

	# 3. Compilador GDScript dinámico
	var dynamic_script: GDScript = GDScript.new()
	dynamic_script.source_code = script_source
	var err: Error = dynamic_script.reload()

	if err != OK:
		append_console("[ERROR SINTAXIS] Código no válido o estructura de bloques incorrecta.")
		_reset_execution_state()
		return

	# 4. Instanciación y Ejecución Segura
	# Pasamos el ID de ejecución actual al Sandbox
	var sandbox_instance = dynamic_script.new(self, current_execution_id)
	if sandbox_instance.has_method("run"):
		await sandbox_instance.run()
		if is_executing and level_state == "RUNNING" and sandbox_instance.my_execution_id == current_execution_id:
			append_console("[FIN] Código completado sin alcanzar la meta.")
	_reset_execution_state()

func _reset_execution_state() -> void:
	current_execution_id += 1
	is_executing = false
	code_editor.editable = true

func _on_btn_stop_pressed() -> void:
	if is_executing:
		_reset_execution_state()
		append_console("[AVISO] Ejecución detenida por el usuario.")
	_reset_to_entrance()

func _on_btn_clear_pressed() -> void:
	if not is_executing:
		code_editor.clear()
		console_log.clear()
		console_line_count = 0
		append_console("[SISTEMA] Consola y editor limpiados.")
		_reset_to_entrance()
