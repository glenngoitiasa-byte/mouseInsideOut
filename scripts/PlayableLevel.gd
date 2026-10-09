# res://scenes/PlayableLevel.gd
extends Control

# Configuración de mapa
const START_CELL: Vector2i = Vector2i(1, 1)
const START_DIR_INDEX: int = 1 # 1 = Este (Mirando a la derecha)
const GOAL_CELL: Vector2i = Vector2i(1, 14) # Coordenada de la salida/queso
const MAX_COLLISIONS: int = 5
const TIMEOUT_SECONDS: float = 30.0

# Referencias a nodos de UI
@onready var code_editor: CodeEdit = $MainHBox/RightVBox/CodeEditor
@onready var console_log: RichTextLabel = $MainHBox/LeftVBox/ConsoleContainer/ConsoleLog
@onready var btn_execute: Button = $MainHBox/RightVBox/ControlsHBox/BtnExecute
@onready var btn_stop: Button = $MainHBox/RightVBox/ControlsHBox/BtnStop
@onready var btn_clear: Button = $MainHBox/RightVBox/ControlsHBox/BtnClear
@onready var speed_slider: HSlider = $MainHBox/RightVBox/ControlsHBox/SpeedSlider

# Referencias a nodos de la escena
@onready var tilemap_layer: TileMapLayer = $MainHBox/LeftVBox/MazeArea/SubViewportContainer/SubViewport/Node2D/TileMapLayer
@onready var mouse_character: MouseCharacter = $MainHBox/LeftVBox/MazeArea/SubViewportContainer/SubViewport/Node2D/MouseCharacter
@onready var collectibles_node: Node2D = $MainHBox/LeftVBox/MazeArea/SubViewportContainer/SubViewport/Node2D/Collectibles

# Estado del nivel y Recolectables
var is_executing: bool = false
var execution_start_time: float = 0.0
var collision_count: int = 0
var cheese_count: int = 0
var password_collected: Array[String] = []
var level_state: String = "READY"

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
	_reset_to_entrance()

func _on_speed_slider_value_changed(new_value: float) -> void:
	if mouse_character != null:
		mouse_character.set_speed_scale(new_value)

func append_console(message: String) -> void:
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
	level_state = "READY"
	_reset_collectibles()

func _check_timeout() -> bool:
	var elapsed_time: float = (Time.get_ticks_msec() - execution_start_time) / 1000.0
	if elapsed_time > TIMEOUT_SECONDS:
		level_state = "GAME_OVER"
		append_console("[TIEMPO AGOTADO] Se superó el límite de " + str(TIMEOUT_SECONDS) + " segundos.")
		return true
	return false

func execute_action(action_name: String):
	if not is_executing or mouse_character == null or level_state == "VICTORY" or level_state == "GAME_OVER":
		return

	if _check_timeout():
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
				append_console("[MOVIMIENTO] Avanzando a " + str(target_cell))
				await mouse_character.move_to_grid(target_cell, speed_scale)
				
				_check_collectibles(target_cell)
				
				if target_cell == GOAL_CELL:
					level_state = "VICTORY"
					append_console("-------------------------------------------")
					append_console("[¡VICTORIA!] ¡El ratón alcanzó la meta en " + str(target_cell) + "!")
					append_console("-------------------------------------------")

		"girar_izquierda":
			append_console("[GIRO] Izquierda")
			await mouse_character.turn(-90.0, speed_scale)

		"girar_derecha":
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

func _compile_and_run(raw_code: String) -> void:
	is_executing = true
	level_state = "RUNNING"
	code_editor.editable = false
	execution_start_time = Time.get_ticks_msec()
	
	append_console("[SISTEMA] Iniciando ejecución...")
	
	var script_source: String = "extends PlayerSandbox\n\nfunc run():\n"
	var lines: PackedStringArray = raw_code.split("\n")
	
	for line in lines:
		var trimmed = line.strip_edges()
		if trimmed.is_empty():
			continue
		
		# Extraer y normalizar la sangría del usuario (convierte 4 espacios a 1 tabulación)
		var indent_len: int = line.length() - line.lstrip(" \t").length()
		var leading_indent: String = line.left(indent_len).replace("    ", "\t")
		
		# Anteponer 'await' a las funciones asíncronas respetando la sangría exacta
		if trimmed.begins_with("avanzar") or trimmed.begins_with("girar_izquierda") or trimmed.begins_with("girar_derecha"):
			script_source += "\t" + leading_indent + "await " + trimmed + "\n"
		else:
			script_source += "\t" + leading_indent + trimmed + "\n"

	var dynamic_script: GDScript = GDScript.new()
	dynamic_script.source_code = script_source
	var err: Error = dynamic_script.reload()

	if err != OK:
		append_console("[ERROR SINTAXIS] Error de compilación en el código.")
		_reset_execution_state()
		return

	var sandbox_instance = dynamic_script.new(self)
	if sandbox_instance.has_method("run"):
		await sandbox_instance.run()
		if is_executing and level_state == "RUNNING":
			append_console("[FIN] Código completado sin alcanzar la meta.")

	_reset_execution_state()

func _reset_execution_state() -> void:
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
		append_console("[SISTEMA] Consola y editor limpiados.")
		_reset_to_entrance()
