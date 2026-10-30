extends Node

const SAVE_PATH: String = "user://savegame.json"
const BACKUP_PATH: String = "user://savegame.bak"
const SALT: String = "MouseInsideOut_2026_SecureKey!" # Semilla para hacer el checksum irrepetible

# Estructura base de los datos de guardado
var current_save: Dictionary = {
	"history_levels_unlocked": 1,
	"random_levels_saved": [],
	"player_stats": {
		"total_cheeses": 0,
		"best_scores": {}
	}
}

func _ready() -> void:
	load_game()

func save_game() -> void:
	var json_data_string: String = JSON.stringify(current_save)
	var checksum: String = (json_data_string + SALT).sha256_text()
	
	var save_file_data: Dictionary = {
		"data_string": json_data_string, # Guardamos el string puro
		"checksum": checksum
	}
	
	if FileAccess.file_exists(SAVE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.copy(SAVE_PATH, BACKUP_PATH)
			
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_file_data, "\t"))
		file.close()
		print("[SAVE] Partida guardada exitosamente.")
	else:
		print("[ERROR] No se pudo escribir el archivo de guardado.")

func load_game() -> void:
	# Si no hay guardado principal, intentar cargar el backup
	if not FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists(BACKUP_PATH):
			_restore_backup()
		else:
			print("[SAVE] No hay partida previa. Iniciando nueva partida.")
			return

	# Leer archivo principal; si falla la validación, restaurar backup
	if not _read_save_file(SAVE_PATH):
		print("[ERROR] Archivo principal corrupto o modificado. Intentando recuperar backup...")
		if FileAccess.file_exists(BACKUP_PATH):
			_restore_backup()
			_read_save_file(SAVE_PATH)

func _read_save_file(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return false
		
	var content: String = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(content) != OK: return false
	var loaded_data: Dictionary = json.data
	
	if not loaded_data.has("data_string") or not loaded_data.has("checksum"): 
		return false
		
	# Calculamos el hash usando el string exacto original, evitando la conversión a flotantes de Godot
	var expected_checksum: String = (loaded_data["data_string"] + SALT).sha256_text()
	
	if loaded_data["checksum"] != expected_checksum:
		print("[SAVE ERROR] Violación de Checksum. El archivo fue manipulado externamente.")
		return false
		
	# Si pasa la prueba, ahora sí extraemos el diccionario
	var inner_json = JSON.new()
	if inner_json.parse(loaded_data["data_string"]) == OK:
		current_save = inner_json.data
		print("[SAVE] Partida cargada y validada correctamente.")
		return true
		
	return false

func _restore_backup() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		dir.copy(BACKUP_PATH, SAVE_PATH)
		print("[SAVE] Backup restaurado con éxito.")
