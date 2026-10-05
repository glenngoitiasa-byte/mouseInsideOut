# res://scenes/PlayableLevel.gd
extends Control

@onready var code_editor: CodeEdit = $MainHBox/RightVBox/CodeEditor
@onready var console_log: RichTextLabel = $MainHBox/LeftVBox/ConsoleContainer/ConsoleLog
@onready var btn_execute: Button = $MainHBox/RightVBox/ControlsHBox/BtnExecute
@onready var btn_stop: Button = $MainHBox/RightVBox/ControlsHBox/BtnStop
@onready var btn_clear: Button = $MainHBox/RightVBox/ControlsHBox/BtnClear
@onready var speed_slider: HSlider = $MainHBox/RightVBox/ControlsHBox/SpeedSlider

var is_executing: bool = false
var execution_start_time: float = 0.0
const TIMEOUT_SECONDS: float = 120.0 # Timeout de 2 minutos (RQNF22)

func _ready() -> void:
	btn_execute.text = "Ejecutar"
	btn_stop.text = "Detener"
	btn_clear.text = "Limpiar"
	
	btn_execute.pressed.connect(_on_btn_execute_pressed)
	btn_stop.pressed.connect(_on_btn_stop_pressed)
	btn_clear.pressed.connect(_on_btn_clear_pressed)
	
	console_log.scroll_following = true
	append_console("[SISTEMA] Sistema de control de ejecución inicializado.")

func append_console(message: String) -> void:
	console_log.append_text(message + "\n")

# Función invocada de forma asíncrona por el Sandbox
func execute_action(action_name: String) -> void:
	if not is_executing:
		return

	# Detección de Timeout de 2 minutos (RQNF22)
	var elapsed_time = (Time.get_ticks_msec() - execution_start_time) / 1000.0
	if elapsed_time > TIMEOUT_SECONDS:
		append_console("[ERROR] La ejecución tardó demasiado, vuelve a intentarlo.")
		_reset_execution_state()
		return

	# Cálculo de la duración de animación según velocidad slider (RQNF25)
	var speed_modifier: float = speed_slider.value
	var duration: float = 0.5 / speed_modifier # x1 -> 0.5s, x0.25 -> 2.0s, x3 -> 0.166s

	append_console("[ACCION] " + action_name + " (Duración: " + str(snapped(duration, 0.01)) + "s)")

	# Simulación de animación paso a paso con timer asíncrono
	await get_tree().create_timer(duration).timeout

# Evento: Botón Ejecutar
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
	code_editor.editable = false # Bloquear editor durante ejecución (RQNF11)
	execution_start_time = Time.get_ticks_msec()
	append_console("[COMPILACIÓN] Analizando sintaxis...")

	# Envolver el código dentro de una función asíncrona run()
	var script_source: String = "extends PlayerSandbox\n\nfunc run():\n"
	var lines: PackedStringArray = raw_code.split("\n")
	for line in lines:
		# Convertir llamadas a las funciones expuestas en llamadas 'await'
		var trimmed = line.strip_edges()
		if trimmed.begins_with("avanzar()") or trimmed.begins_with("girar_izquierda()") or trimmed.begins_with("girar_derecha()"):
			script_source += "\tawait " + line + "\n"
		else:
			script_source += "\t" + line + "\n"

	var dynamic_script: GDScript = GDScript.new()
	dynamic_script.source_code = script_source
	var err: Error = dynamic_script.reload()

	if err != OK:
		append_console("[ERROR SINTAXIS] Error de sintaxis. Revisa ':' al final de if/for/while, paréntesis cerrados y sangría consistente.")
		_reset_execution_state()
		return

	append_console("[SISTEMA] Iniciando simulación paso a paso...")
	var sandbox_instance = dynamic_script.new(self)
	
	if sandbox_instance.has_method("run"):
		await sandbox_instance.run()
		if is_executing:
			append_console("[ÉXITO] Ejecución completada.")
	
	_reset_execution_state()

func _reset_execution_state() -> void:
	is_executing = false
	code_editor.editable = true # Restablecer editor (RQNF12)

# Interrupción inmediata sin cerrar la pantalla (RQNF12)
func _on_btn_stop_pressed() -> void:
	if is_executing:
		_reset_execution_state()
		append_console("[AVISO] Ejecución detenida por el usuario.")

func _on_btn_clear_pressed() -> void:
	if not is_executing:
		code_editor.clear()
		append_console("[SISTEMA] Editor de código limpiado.")
