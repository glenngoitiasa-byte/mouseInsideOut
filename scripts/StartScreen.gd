# res://scenes/StartScreen.gd
extends Control

# Ruta a la escena del menú principal (Pantalla 2)
const MAIN_MENU_SCENE: String = "res://scenes/main_menu.tscn"

@onready var label_prompt: Label = $CenterContainer/VBoxContainer/LabelPrompt

var is_transitioning: bool = false

func _ready() -> void:
	_start_prompt_blink()

# Animación básica de parpadeo para el mensaje inferior
func _start_prompt_blink() -> void:
	if label_prompt == null:
		return
	var tween = create_tween().set_loops()
	tween.tween_property(label_prompt, "modulate:a", 0.2, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(label_prompt, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return

	# Detecta presionar una tecla, clic de mouse o botón de control
	if (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.is_pressed():
		is_transitioning = true
		_go_to_main_menu()

func _go_to_main_menu() -> void:
	# Transición limpia al Menú Principal
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
