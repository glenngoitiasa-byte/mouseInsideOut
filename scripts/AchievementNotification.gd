extends CanvasLayer

@onready var label_desc = $Panel/LabelAchUnblk
@onready var anim_player = $NotificationAnimation
@onready var panel = $Panel

func _ready() -> void:
	panel.hide()
	# Escuchamos globalmente la señal de desbloqueo
	AchievementManager.achievement_unlocked.connect(_mostrar_notificacion)

func _mostrar_notificacion(id: int, descripcion: String) -> void:
	label_desc.text = descripcion
	panel.show()
	anim_player.play("entrada") 
	
	# Esperar 4 segundos y ocultar
	await get_tree().create_timer(4.0).timeout
	anim_player.play("salida")
