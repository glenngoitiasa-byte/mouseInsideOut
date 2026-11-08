extends Control

@onready var vbox_logros = $ScrollBar/VBoxLogros
# Modificado: El molde ahora es el PanelContainer completo
@onready var logro_template = $ScrollBar/VBoxLogros/PanelContainer
@onready var btn_volver = $HBoxContainer/HBoxContainer2/ButtonBack

const MAIN_MENU_SCENE: String = "res://scenes/main_menu.tscn"

func _ready() -> void:
	logro_template.hide()
	
	for child in vbox_logros.get_children():
		if child != logro_template:
			child.queue_free()
			
	btn_volver.pressed.connect(func():
		get_tree().change_scene_to_file(MAIN_MENU_SCENE) 
	)
			
	_cargar_lista_logros()

func _cargar_lista_logros() -> void:
	var stats: Dictionary = SaveManager.current_save.get("player_stats", {})
	var raw_unlocked: Array = stats.get("achievements", [])
	
	var unlocked_ids: Array = []
	for item in raw_unlocked:
		unlocked_ids.append(int(item))
	
	for id in AchievementManager.ACHIEVEMENTS_DATA.keys():
		var nuevo_item = logro_template.duplicate()
		vbox_logros.add_child(nuevo_item)
		nuevo_item.show()
		
		# Modificado: Buscar los nombres correctos según el árbol de nodos
		var icon = nuevo_item.find_child("ColorRect", true, false)
		var label = nuevo_item.find_child("Label", true, false)
		
		if label:
			label.text = str(id) + ". " + AchievementManager.ACHIEVEMENTS_DATA[id]
			
			if unlocked_ids.has(id):
				label.modulate = Color(1.0, 1.0, 1.0, 1.0)
				if icon: icon.color = Color(1.0, 0.84, 0.0) 
			else:
				label.modulate = Color(0.5, 0.5, 0.5, 0.7)
				if icon: icon.color = Color(0.2, 0.2, 0.2, 1.0)
		else:
			print("[ERROR] Godot no pudo encontrar 'Label' dentro del molde.")
