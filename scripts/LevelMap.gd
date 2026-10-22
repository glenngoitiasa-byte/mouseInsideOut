# res://scenes/LevelMap.gd
extends Control

const PLAYABLE_LEVEL_SCENE = "res://scenes/PlayableLevel.tscn"

# Referencias a UI
@onready var label_title: Label = $InfoPanel/VBox/LabelTitle
@onready var label_desc: Label = $InfoPanel/VBox/LabelDesc
@onready var label_stats: Label = $InfoPanel/VBox/LabelStats
@onready var btn_start_level: Button = $BtnStartLevel
@onready var mouse_avatar: Node2D = $MouseAvatar

# Referencia a las paradas/niveles
@onready var level_nodes: Array[Node] = $LevelNodes.get_children()

var current_target_level: int = 1
var is_moving: bool = false

# Diccionario con metadatos de cada escenario para la UI
var levels_info: Dictionary = {
	1: {
		"title": "Nivel 1: El Pasillo Inicial",
		"desc": "Aprende los comandos básicos 
		de movimiento y secuencia.",
		"best_steps": 12,
		"cheeses": "1/1",
		"pos": Vector2(350, 480)
	},
	2: {
		"title": "Nivel 2: La Encrucijada",
		"desc": "Usa sensores (frente_libre, etc.)
		 y tomadores de decisiones 'if'.",
		"best_steps": 24,
		"cheeses": "2/2",
		"pos": Vector2(800, 600)
	},
	3: {
		"title": "Nivel 3: El Espiral sin Fin",
		"desc": "Domina los bucles 'while' y 
		optimiza tu código.",
		"best_steps": 45,
		"cheeses": "3/3",
		"pos": Vector2(950, 300)
	},
	4: {
		"title": "Nivel 4: Niebla en la Penumbra",
		"desc": "Navega a oscuras usando visión 
		radial. Consigue las contraseñas.",
		"best_steps": "---",
		"cheeses": "0/3",
		"pos": Vector2(380, 180)
	}
}

func _ready() -> void:
	btn_start_level.pressed.connect(_on_btn_start_level_pressed)
	
	# Conectar señales de click y hover a cada nodo de nivel
	for idx in range(level_nodes.size()):
		var level_num: int = idx + 1
		var node = level_nodes[idx]
		
		# Si usas TextureButton:
		if node is TextureButton:
			node.pressed.connect(func(): _select_level(level_num))
			node.mouse_entered.connect(func(): _preview_info(level_num))
		
		# Si usas Area2D con Sprite:
		elif node is Area2D:
			node.input_event.connect(func(_v, event, _i):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_select_level(level_num)
			)
			node.mouse_entered.connect(func(): _preview_info(level_num))

	# Posicionar al ratón inicialmente en el Nivel 1
	_move_mouse_to_level_instant(1)
	_update_info_panel(1)

# Actualiza la tarjeta de información lateral
func _update_info_panel(level_num: int) -> void:
	if not levels_info.has(level_num):
		return
	var data = levels_info[level_num]
	label_title.text = data["title"]
	label_desc.text = data["desc"]
	label_stats.text = "Récord pasos: " + str(data["best_steps"]) + "\nQuesos: " + str(data["cheeses"])

func _preview_info(level_num: int) -> void:
	if not is_moving:
		_update_info_panel(level_num)

# Selecciona un nivel y desplaza al ratón hacia esa posición
func _select_level(level_num: int) -> void:
	if is_moving or current_target_level == level_num:
		return
		
	current_target_level = level_num
	_update_info_panel(level_num)
	
	var target_pos: Vector2 = levels_info[level_num]["pos"]
	
	is_moving = true
	btn_start_level.disabled = true
	
	# Transición fluida del avatar del ratón
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(mouse_avatar, "global_position", target_pos, 0.8)
	
	await tween.finished
	is_moving = false
	btn_start_level.disabled = false

func _move_mouse_to_level_instant(level_num: int) -> void:
	current_target_level = level_num
	if levels_info.has(level_num):
		mouse_avatar.global_position = levels_info[level_num]["pos"]

func _on_btn_start_level_pressed() -> void:
	if is_moving:
		return
	GlobalState.current_selected_level = current_target_level
	get_tree().change_scene_to_file(PLAYABLE_LEVEL_SCENE)
