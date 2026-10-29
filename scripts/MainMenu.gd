# res://scenes/MainMenu.gd
extends Control

# Ruta a la siguiente pantalla (Mapa de Niveles)
const LEVEL_MAP_SCENE: String = "res://scenes/level_map.tscn"
const RANDOM_MENU_SCENE: String = "res://scenes/RandomLevelMenu.tscn"

@onready var btn_play: Button = $CenterContainer/VBoxContainer/BtnPlay
@onready var btn_creation: Button = $CenterContainer/VBoxContainer/BtnCreation
@onready var btn_achievements: Button = $CenterContainer/VBoxContainer/BtnAchievements
@onready var btn_settings: Button = $CenterContainer/VBoxContainer/BtnSettings

func _ready() -> void:
	btn_play.pressed.connect(_on_btn_play_pressed)
	btn_creation.pressed.connect(_on_btn_creation_pressed)
	btn_achievements.pressed.connect(_on_btn_achievements_pressed)
	btn_settings.pressed.connect(_on_btn_settings_pressed)
	
	# Enfocar automáticamente el primer botón para navegación con teclado/mando
	btn_play.grab_focus()

# 1. Opción Jugar -> Transición al mapa de niveles (Pantalla 3)
func _on_btn_play_pressed() -> void:
	get_tree().change_scene_to_file(LEVEL_MAP_SCENE)

# 2. Opción Creación (Placeholder para el generador aleatorio)
func _on_btn_creation_pressed() -> void:
	get_tree().change_scene_to_file(RANDOM_MENU_SCENE)
# 3. Opción Logros (Placeholder para estadísticas)
func _on_btn_achievements_pressed() -> void:
	print("[MENÚ] Panel de Logros seleccionado (En desarrollo).")

# 4. Opción Configuración (Placeholder para preferencias)
func _on_btn_settings_pressed() -> void:
	print("[MENÚ] Configuración seleccionada (En desarrollo).")
