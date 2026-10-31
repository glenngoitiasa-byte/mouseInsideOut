# res://scenes/RandomLevelMenu.gd
extends Control

const MAIN_MENU_SCENE: String = "res://scenes/main_menu.tscn"
const PLAYABLE_LEVEL_SCENE: String = "res://scenes/playable_level.tscn"

# Referencias Top y Tarjetas
@onready var btn_back: Button = $TopBar/BtnBack
@onready var btn_play_template: Button = $CardScroll/CardHBox/CardTemplante/VBoxContainer/BtnPlay
@onready var template_seed_input: LineEdit = $CardScroll/CardHBox/CardTemplante/VBoxContainer/InputSeed

# Referencias Formulario de Generación
@onready var btn_generate: Button = $GeneratorSection/VBoxContainer/BtnGenerate
@onready var input_name: LineEdit = $GeneratorSection/VBoxContainer3/VBoxContainer2/InputName
@onready var option_algo: OptionButton = $GeneratorSection/VBoxContainer3/VBoxContainer2/HBoxContainer/VBoxContainer/OptionSub
@onready var input_seed: LineEdit = $GeneratorSection/VBoxContainer3/VBoxContainer2/HBoxContainer/VBoxContainer2/InputSeed
@onready var option_size: OptionButton = $GeneratorSection/VBoxContainer3/VBoxContainer2/HBoxContainer/VBoxContainer3/OptionSize
@onready var input_cheese: LineEdit = $GeneratorSection/VBoxContainer3/VBoxContainer2/HBoxContainer2/VBoxContainer/InputCheese
@onready var check_dark: CheckBox = $GeneratorSection/VBoxContainer3/VBoxContainer2/HBoxContainer2/HBoxContainer/CheckDark
@onready var check_password: CheckBox = $GeneratorSection/VBoxContainer3/VBoxContainer2/HBoxContainer2/HBoxContainer/CheckPassword
@onready var card_hbox: HBoxContainer = $CardScroll/CardHBox
@onready var card_template: Control = $CardScroll/CardHBox/CardTemplante

func _ready() -> void:
	btn_back.pressed.connect(_on_btn_back_pressed)
	btn_generate.pressed.connect(_on_btn_generate_pressed)
	
	_setup_dropdowns()
	_load_saved_cards()

func _setup_dropdowns() -> void:
	option_algo.add_item("Backtracking")
	option_algo.add_item("Prim")
	option_algo.add_item("Kruskal")
	
	option_size.add_item("Pequeño (9x9)")
	option_size.add_item("Mediano (15x15)")
	option_size.add_item("Grande (21x21)")

func _on_btn_generate_pressed() -> void:
	# 1. Obtener y validar la semilla
	var seed_text: String = input_seed.text.strip_edges()
	var final_seed: int = seed_text.to_int() if seed_text.is_valid_int() else randi()
	input_seed.text = str(final_seed) # Actualizar el texto por si estaba vacío
	
	# 2. Recopilar el resto de los datos
	var level_name = input_name.text.strip_edges()
	if level_name == "": level_name = "Nivel Aleatorio"
	
	var algo_str = option_algo.get_item_text(option_algo.selected)
	var size_str = option_size.get_item_text(option_size.selected)
	
	var cheese_txt = input_cheese.text.strip_edges()
	var final_cheeses: int = cheese_txt.to_int() if cheese_txt.is_valid_int() else 0
	
	# 3. Empaquetar la tarjeta con todos los datos
	var card_data = {
		"name": level_name,
		"seed": final_seed,
		"size": size_str,
		"cheeses": final_cheeses,
		"algorithm": algo_str,
		"is_dark": check_dark.button_pressed,
		"has_password": check_password.button_pressed
	}
	
	# 4. Guardar la tarjeta en el SaveManager (vía GlobalState)
	print("[CREACIÓN] Guardando y generando laberinto '", level_name, "' con algoritmo: ", algo_str)
	GlobalState.save_random_level_card(card_data)
	
	# 5. Iniciar el nivel
	_launch_level(str(final_seed))
func _launch_level(seed_string: String) -> void:
	var final_seed: int = seed_string.to_int() if seed_string.is_valid_int() else randi()
	
	# Leer tamaño
	match option_size.selected:
		0: # Pequeño
			GlobalState.current_maze_width = 9
			GlobalState.current_maze_height = 9
		1: # Mediano
			GlobalState.current_maze_width = 15
			GlobalState.current_maze_height = 15
		2: # Grande
			GlobalState.current_maze_width = 21
			GlobalState.current_maze_height = 21
			
	# Leer cantidad de quesos
	var cheese_txt = input_cheese.text.strip_edges()
	GlobalState.current_cheese_count = cheese_txt.to_int() if cheese_txt.is_valid_int() else 0
	
	GlobalState.is_random_mode = true
	GlobalState.current_seed = final_seed
	get_tree().change_scene_to_file(PLAYABLE_LEVEL_SCENE)

func _on_btn_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

# En res://scripts/RandomLevelMenu.gd (o donde controles este menú)

# Asegúrate de tener la referencia a tu botón (ajusta la ruta según tu árbol de nodos)
@onready var btn_save_card: Button = $Panel/BtnSaveCard 

func _load_saved_cards() -> void:
	# 1. Ocultar el molde original
	card_template.hide()
	
	# 2. Limpiar tarjetas clonadas anteriormente (por si el menú se recarga)
	for child in card_hbox.get_children():
		if child != card_template:
			child.queue_free()
			
	# 3. Leer los niveles guardados
	var saved_levels: Array = SaveManager.current_save["random_levels_saved"]
	
	# 4. Generar una tarjeta por cada nivel
	for level_data in saved_levels:
		var new_card = card_template.duplicate()
		card_hbox.add_child(new_card)
		new_card.show()
		
		# Referencias internas de la nueva tarjeta clonada
		var input_seed_card = new_card.get_node("VBoxContainer/InputSeed")
		var btn_play = new_card.get_node("VBoxContainer/BtnPlay")
		
		# Opcional: Si agregas un Label para el título en tu escena, puedes llenarlo así:
		if new_card.has_node("VBoxContainer/LabelName"):
			new_card.get_node("VBoxContainer/LabelName").text = level_data["name"]
			
		# Llenar la semilla
		if input_seed_card:
			input_seed_card.text = str(level_data["seed"])
			input_seed_card.editable = false # Evita que la modifiquen desde la tarjeta
			
		# Conectar el botón "Jugar" a los datos específicos de esta tarjeta
		btn_play.pressed.connect(func(): _launch_saved_level(level_data))

func _launch_saved_level(data: Dictionary) -> void:
	GlobalState.is_random_mode = true
	GlobalState.current_seed = data["seed"]
	GlobalState.current_cheese_count = data["cheeses"]
	
	# Restaurar el tamaño basado en el texto guardado
	match data["size"]:
		"Pequeño (9x9)":
			GlobalState.current_maze_width = 9
			GlobalState.current_maze_height = 9
		"Mediano (15x15)":
			GlobalState.current_maze_width = 15
			GlobalState.current_maze_height = 15
		"Grande (21x21)":
			GlobalState.current_maze_width = 21
			GlobalState.current_maze_height = 21
			
	get_tree().change_scene_to_file(PLAYABLE_LEVEL_SCENE)
