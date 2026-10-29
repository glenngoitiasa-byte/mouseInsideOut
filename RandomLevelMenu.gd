# res://scenes/RandomLevelMenu.gd
extends Control

const MAIN_MENU_SCENE: String = "res://scenes/MainMenu.tscn"
const PLAYABLE_LEVEL_SCENE: String = "res://scenes/PlayableLevel.tscn"

# Referencias Top y Tarjetas
@onready var btn_back: Button = $TopBar/BtnBack
@onready var btn_play_template: Button = $CardsScroll/CardsHBox/CardTemplate/VBox/BtnPlay
@onready var template_seed_input: LineEdit = $CardsScroll/CardsHBox/CardTemplate/VBox/InputSeed

# Referencias Formulario de Generación
@onready var btn_generate: Button = $GeneratorSection/VBoxGenerate/BtnGenerate
@onready var input_name: LineEdit = $GeneratorSection/GeneratorForm/InputName
@onready var option_algo: OptionButton = $GeneratorSection/GeneratorForm/OptionAlgo
@onready var input_seed: LineEdit = $GeneratorSection/GeneratorForm/InputSeed
@onready var option_size: OptionButton = $GeneratorSection/GeneratorForm/OptionSize
@onready var input_cheese: LineEdit = $GeneratorSection/GeneratorForm/InputCheese
@onready var check_dark: CheckBox = $GeneratorSection/GeneratorForm/CheckDark
@onready var check_password: CheckBox = $GeneratorSection/GeneratorForm/CheckPassword

func _ready() -> void:
	btn_back.pressed.connect(_on_btn_back_pressed)
	btn_generate.pressed.connect(_on_btn_generate_pressed)
	
	# Conexión de prueba para la tarjeta estática
	btn_play_template.pressed.connect(func(): _launch_level(template_seed_input.text))
	
	_setup_dropdowns()

func _setup_dropdowns() -> void:
	option_algo.add_item("Backtracking")
	option_algo.add_item("Prim")
	option_algo.add_item("Kruskal")
	
	option_size.add_item("Pequeño (9x9)")
	option_size.add_item("Mediano (15x15)")
	option_size.add_item("Grande (21x21)")

func _on_btn_generate_pressed() -> void:
	var seed_text: String = input_seed.text.strip_edges()
	var seed_value: int = seed_text.to_int() if seed_text.is_valid_int() else randi()
	
	# Aquí en el futuro guardaremos la tarjeta en disco usando los demás datos del formulario
	print("[CREACIÓN] Generando laberinto '", input_name.text, "' con algoritmo: ", option_algo.text)
	
	_launch_level(str(seed_value))

func _launch_level(seed_string: String) -> void:
	var final_seed: int = seed_string.to_int() if seed_string.is_valid_int() else randi()
	
	GlobalState.is_random_mode = true
	GlobalState.current_seed = final_seed
	get_tree().change_scene_to_file(PLAYABLE_LEVEL_SCENE)

func _on_btn_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
