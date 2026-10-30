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
	# 1. Convertir los datos a texto JSON puro
	var json_data_string: String = JSON.stringify(current_save)
	
	# 2. Generar el Checksum SHA-256 usando la cadena + SALT
	var checksum: String = (json_data_string + SALT).sha256_text()
	
	# 3. Empaquetar datos y firma
	var save_file_data: Dictionary = {
		"data": current_save,
		"checksum": checksum
	}
	
	# 4. Crear backup si ya existe una partida previa
	if FileAccess.file_exists(SAVE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.copy(SAVE_PATH, BACKUP_PATH)
			
	# 5. Escribir el nuevo archivo de guardado
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var final_json: String = JSON.stringify(save_file_data, "\t")
		file.store_string(final_json)
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
	if not file: 
		return false
		
	var content: String = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(content)
	
	if error != OK: 
		return false
		
	var loaded_data: Dictionary = json.data
	
	# Verificar estructura del contenedor
	if not loaded_data.has("data") or not loaded_data.has("checksum"): 
		return false
		
	# Recalcular el Checksum con los datos leídos
	var expected_checksum: String = (JSON.stringify(loaded_data["data"]) + SALT).sha256_text()
	
	if loaded_data["checksum"] != expected_checksum:
		print("[SAVE ERROR] Violación de Checksum. El archivo fue manipulado externamente.")
		return false
		
	# Si pasa la validación, actualizar el estado actual
	current_save = loaded_data["data"]
	print("[SAVE] Partida cargada y validada correctamente.")
	return true

func _restore_backup() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		dir.copy(BACKUP_PATH, SAVE_PATH)
		print("[SAVE] Backup restaurado con éxito.")
