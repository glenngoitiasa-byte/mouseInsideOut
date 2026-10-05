# res://scenes/PlayableLevel.gd
extends Control

@onready var code_editor: CodeEdit = $MainHBox/RightVBox/CodeEditor
@onready var console_log: RichTextLabel = $MainHBox/LeftVBox/ConsoleContainer/ConsoleLog
@onready var btn_execute: Button = $MainHBox/RightVBox/ControlsHBox/BtnExecute
@onready var btn_stop: Button = $MainHBox/RightVBox/ControlsHBox/BtnStop
@onready var btn_clear: Button = $MainHBox/RightVBox/ControlsHBox/BtnClear

var is_executing: bool = false

func _ready() -> void:
	btn_execute.text = "Ejecutar"
	btn_stop.text = "Detener"
	btn_clear.text = "Limpiar"
	
	btn_execute.pressed.connect(_on_btn_execute_pressed)
	btn_stop.pressed.connect(_on_btn_stop_pressed)
	btn_clear.pressed.connect(_on_btn_clear_pressed)
	
	console_log.scroll_following = true
	append_console("[SISTEMA] Consola y Sandbox inicializados. Escribe tu código.")

func append_console(message: String) -> void:
	console_log.append_text(message + "\n")

# Evento: Botón Ejecutar
func _on_btn_execute_pressed() -> void:
	if is_executing:
		return
		
	var user_code: String = code_editor.text.strip_edges()
	if user_code.is_empty():
		append_console("[ERROR] El editor está vacío.")
		return
		
	_compile_and_run(user_code)

# Compilación e instanciación del código usando RefCounted y GDScript.new()
func _compile_and_run(raw_code: String) -> void:
	# 1. Bloquear el CodeEdit durante la ejecución (RQNF11)
	is_executing = true
	code_editor.editable = false
	append_console("[COMPILACIÓN] Analizando sintaxis...")

	# 2. Construir la estructura completa de la clase en memoria
	var script_source: String = "extends PlayerSandbox\n\nfunc run():\n"
	
	# Indentar cada línea del usuario para dentro del método run()
	var lines: PackedStringArray = raw_code.split("\n")
	for line in lines:
		script_source += "\t" + line + "\n"

	# 3. Compilador nativo de Godot (RQNF21)
	var dynamic_script: GDScript = GDScript.new()
	dynamic_script.source_code = script_source
	var err: Error = dynamic_script.reload()

	# 4. Manejo de errores de sintaxis
	if err != OK:
		append_console("[ERROR SINTAXIS] Error de sintaxis. Revisa ':' al final de if/for/while, paréntesis cerrados y sangría consistente.")
		_reset_execution_state()
		return

	# 5. Instanciación y ejecución en el sandbox aislado
	append_console("[SISTEMA] Compilación exitosa. Iniciando sandbox...")
	var sandbox_instance = dynamic_script.new(self)
	
	if sandbox_instance.has_method("run"):
		sandbox_instance.run()
		append_console("[ÉXITO] Código ejecutado con éxito.")
	else:
		append_console("[ERROR] No se pudo encontrar el punto de entrada 'run()'.")
	await get_tree().create_timer(3.0).timeout
	_reset_execution_state()

# Restablecer el estado del editor
func _reset_execution_state() -> void:
	is_executing = false
	code_editor.editable = true # El editor vuelve a ser editable (RQNF12)

# Evento: Botón Detener
func _on_btn_stop_pressed() -> void:
	if is_executing:
		_reset_execution_state()
		append_console("[AVISO] Ejecución interrumpida por el usuario.")

# Evento: Botón Limpiar
func _on_btn_clear_pressed() -> void:
	if not is_executing:
		code_editor.clear()
		append_console("[SISTEMA] Editor de código limpiado.")
