# res://scenes/PlayableLevel.gd
extends Control

@onready var code_editor: CodeEdit = $MainHBox/RightVBox/CodeEditor
@onready var console_log: RichTextLabel = $MainHBox/LeftVBox/ConsoleContainer/ConsoleLog
@onready var btn_execute: Button = $MainHBox/RightVBox/ControlsHBox/BtnExecute
@onready var btn_stop: Button = $MainHBox/RightVBox/ControlsHBox/BtnStop
@onready var btn_clear: Button = $MainHBox/RightVBox/ControlsHBox/BtnClear
@onready var speed_slider: HSlider = $MainHBox/RightVBox/ControlsHBox/SpeedSlider

# Referencias al personaje y mapa
@onready var tilemap_layer: TileMapLayer = $MainHBox/LeftVBox/MazeArea/SubViewportContainer/SubViewport/MazeNode/TileMapLayer
@onready var mouse_character: MouseCharacter = $MainHBox/LeftVBox/MazeArea/SubViewportContainer/SubViewport/MazeNode/MouseCharacter

var is_executing: bool = false
var execution_start_time: float = 0.0
var collision_count: int = 0 # Contador de choques (RQNF12)
const TIMEOUT_SECONDS: float = 120.0

func _ready() -> void:
	speed_slider.custom_minimum_size.x = 140
	speed_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	btn_execute.pressed.connect(_on_btn_execute_pressed)
	btn_stop.pressed.connect(_on_btn_stop_pressed)
	btn_clear.pressed.connect(_on_btn_clear_pressed)
	
	console_log.scroll_following = true
	
	# Posicionar al ratón al inicio
	if mouse_character:
		mouse_character.grid_pos = Vector2i(1, 1)
		mouse_character.update_world_position_instant()

func append_console(message: String) -> void:
	console_log.append_text(message + "\n")

# Ejecución asíncrona enviada desde el Sandbox
func execute_action(action_name: String) -> void:
	if not is_executing:
		return

	var elapsed_time = (Time.get_ticks_msec() - execution_start_time) / 1000.0
	if elapsed_time > TIMEOUT_SECONDS:
		append_console("[ERROR] Tiempo límite superado (2 minutos).")
		_reset_execution_state()
		return

	var duration: float = 0.4 / speed_slider.value # Duración dinámica

	match action_name:
		"avanzar":
			var target_cell = mouse_character.get_facing_cell()
			
			# Comprobar colisión en TileMapLayer (si la celda tiene tile ID != -1 es pared)
			if _is_wall(target_cell):
				collision_count += 1
				append_console("[COLISIÓN] ¡El ratón chocó contra una pared! Choques totales: " + str(collision_count))
				# Pequeña pausa de impacto
				await get_tree().create_timer(duration * 0.5).timeout
			else:
				append_console("[MOVIMIENTO] Avanzando a celda " + str(target_cell))
				await mouse_character.move_to_grid(target_cell, duration)

		"girar_izquierda":
			append_console("[GIRO] Girando a la izquierda")
			await mouse_character.turn(-90.0, duration)

		"girar_derecha":
			append_console("[GIRO] Girando a la derecha")
			await mouse_character.turn(90.0, duration)

# Verificación básica de colisión contra pared
func _is_wall(cell_pos: Vector2i) -> bool:
	if tilemap_layer:
		# Si la celda en TileMapLayer no está vacía (source_id != -1), es pared
		return tilemap_layer.get_cell_source_id(cell_pos) != -1
	return false

func _on_btn_execute_pressed() -> void:
	if is_executing:
		return
	var user_code: String = code_editor.text.strip_edges()
	if user_code.is_empty():
		append_console("[ERROR] El editor está vacío.")
		return
	_compile_and_run(user_code)

func _compile_and_run(raw_code: String) -> void:
	is_executing = true
	code_editor.editable = false
	execution_start_time = Time.get_ticks_msec()
	
	var script_source: String = "extends PlayerSandbox\n\nfunc run():\n"
	var lines: PackedStringArray = raw_code.split("\n")
	for line in lines:
		var trimmed = line.strip_edges()
		if trimmed.begins_with("avanzar()") or trimmed.begins_with("girar_izquierda()") or trimmed.begins_with("girar_derecha()"):
			script_source += "\tawait " + line + "\n"
		else:
			script_source += "\t" + line + "\n"

	var dynamic_script: GDScript = GDScript.new()
	dynamic_script.source_code = script_source
	var err: Error = dynamic_script.reload()

	if err != OK:
		append_console("[ERROR SINTAXIS] Error en el código. Verifica la sintaxis.")
		_reset_execution_state()
		return

	var sandbox_instance = dynamic_script.new(self)
	if sandbox_instance.has_method("run"):
		await sandbox_instance.run()
		if is_executing:
			append_console("[ÉXITO] Ejecución finalizada. Total de choques: " + str(collision_count))

	_reset_execution_state()

func _reset_execution_state() -> void:
	is_executing = false
	code_editor.editable = true

func _on_btn_stop_pressed() -> void:
	if is_executing:
		_reset_execution_state()
		append_console("[AVISO] Ejecución detenida por el usuario.")

func _on_btn_clear_pressed() -> void:
	if not is_executing:
		code_editor.clear()
		append_console("[SISTEMA] Editor de código limpiado.")
