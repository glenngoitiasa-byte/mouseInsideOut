extends Control

# Referencias a los nodos de la interfaz
@onready var code_editor: CodeEdit = $MainHBox/RightVBox/CodeEditor
@onready var console_log: RichTextLabel = $MainHBox/LeftVBox/ConsoleContainer/ConsoleLog
@onready var btn_execute: Button = $MainHBox/RightVBox/ControlsHBox/BtnExecute
@onready var btn_stop: Button = $MainHBox/RightVBox/ControlsHBox/BtnStop
@onready var btn_clear: Button = $MainHBox/RightVBox/ControlsHBox/BtnClear

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Configurar textos iniciales de botones
	btn_execute.text = "Ejecutar"
	btn_stop.text = "Detener"
	btn_clear.text = "Limpiar"
	
	# Conectar señales de los botones
	btn_execute.pressed.connect(_on_btn_execute_pressed)
	btn_stop.pressed.connect(_on_btn_stop_pressed)
	btn_clear.pressed.connect(_on_btn_clear_pressed)
	
	# Configuración inicial de la consola
	console_log.scroll_following = true
	append_console("Consola inicializada correctamente. Listo para recibir código.")
	pass # Replace with function body.

# Función auxiliar para imprimir mensajes en la consola in-game
func append_console(message: String) -> void:
	console_log.append_text(message + "\n")

# Evento: Botón Ejecutar
func _on_btn_execute_pressed() -> void:
	append_console("[INFO] Ejecutando código del editor...")
	# Mañana conectaremos aquí la compilación con RefCounted

# Evento: Botón Detener
func _on_btn_stop_pressed() -> void:
	append_console("[AVISO] Ejecución detenida por el usuario.")

# Evento: Botón Limpiar
func _on_btn_clear_pressed() -> void:
	code_editor.clear() # Vacía el CodeEdit conservando el historial
	append_console("[SISTEMA] Editor de código limpiado.")
