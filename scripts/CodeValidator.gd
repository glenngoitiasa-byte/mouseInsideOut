# res://scripts/CodeValidator.gd
class_name CodeValidator
extends RefCounted

# Comandos, sensores y palabras clave oficiales del juego
const GAME_COMMANDS = ["avanzar", "girar_izquierda", "girar_derecha"]
const GAME_SENSORS = ["frente_libre", "izquierda_libre", "derecha_libre"]
const GD_KEYWORDS = ["if", "elif", "else", "while", "for", "in", "range", "not", "and", "or", "true", "false", "pass", "var"]

# Retorna la lista de tokens autorizados según el nivel activo
static func get_allowed_tokens(level_number: int) -> Array[String]:
	match level_number:
		1:
			return GAME_COMMANDS
		2:
			var list: Array[String] = []
			list.append_array(GAME_COMMANDS)
			list.append_array(GAME_SENSORS)
			list.append_array(["if", "elif", "else", "pass"])
			return list
		3, 4:
			var list: Array[String] = []
			list.append_array(GAME_COMMANDS)
			list.append_array(GAME_SENSORS)
			list.append_array(GD_KEYWORDS)
			return list
		_:
			return []

class ValidationResult:
	var is_valid: bool = true
	var error_message: String = ""
	var line_number: int = -1

static func validate_code(code: String, level_number: int, custom_allowed_tokens: Array[String] = []) -> ValidationResult:
	var result = ValidationResult.new()
	var lines = code.split("\n")
	
	var all_known_identifiers: Array[String] = []
	all_known_identifiers.append_array(GAME_COMMANDS)
	all_known_identifiers.append_array(GAME_SENSORS)
	all_known_identifiers.append_array(GD_KEYWORDS)

	# --- NUEVO: Determinar tokens permitidos según el modo ---
	var allowed_tokens: Array = [] # <-- Cambiado a genérico para evitar el error
	if GlobalState.is_random_mode:
		if custom_allowed_tokens.is_empty():
			allowed_tokens.assign(all_known_identifiers.duplicate()) # Permite todo si está vacío
		else:
			allowed_tokens.assign(custom_allowed_tokens) # Restringe a lo que diga el creador
	else:
		allowed_tokens.assign(get_allowed_tokens(level_number))

	# Variables para rastrear las tabulaciones
	var require_indent_next: bool = false
	var last_indent: int = 0

	for idx in range(lines.size()):
		var line_num = idx + 1
		var raw_line = lines[idx]
		var trimmed = raw_line.strip_edges()
		
		# Ignorar líneas vacías o comentarios
		if trimmed.is_empty() or trimmed.begins_with("#"):
			continue

		# --- NUEVO: Validar Tabulación (Evitar Crasheos) ---
		var current_indent = 0
		for i in range(raw_line.length()):
			if raw_line[i] == "\t":
				current_indent += 1
			elif raw_line[i] == " ":
				continue # Ignora espacios si mezclaron tab y espacio, pero la base es \t
			else:
				break

		# Si la línea anterior terminaba en ':' y esta línea no tiene mayor tabulación
		if require_indent_next and current_indent <= last_indent:
			result.is_valid = false
			result.line_number = line_num
			result.error_message = "Falta tabulación. Recuerda usar 'Tab' para indentar el bloque dentro de la estructura."
			return result

		require_indent_next = trimmed.ends_with(":")
		last_indent = current_indent

		# 1. Detección de "else if"
		if trimmed.begins_with("else if") or " else if " in trimmed:
			result.is_valid = false
			result.line_number = line_num
			result.error_message = "Sintaxis incorrecta: Usa 'elif' en lugar de 'else if'."
			return result

		# 2. Balance de paréntesis en la línea
		if trimmed.count("(") != trimmed.count(")"):
			result.is_valid = false
			result.line_number = line_num
			result.error_message = "Paréntesis sin cerrar '()' en la línea."
			return result

		# 3. Validar dos puntos al final de estructuras de control
		if trimmed.begins_with("if ") or trimmed.begins_with("elif ") or trimmed.begins_with("while ") or trimmed.begins_with("for ") or trimmed == "else:":
			if not trimmed.ends_with(":"):
				result.is_valid = false
				result.line_number = line_num
				result.error_message = "Falta ':' al final de la estructura de control."
				return result
		elif trimmed.begins_with("else") and trimmed != "else:":
			result.is_valid = false
			result.line_number = line_num
			result.error_message = "Sintaxis de 'else' incorrecta. Debe ser únicamente 'else:'."
			return result

		# 4. Extraer e inspeccionar cada palabra/identificador de la línea
		var clean_line = trimmed
		for symbol in [":", "(", ")", ",", "=", "+", "-", "*", "/", ">", "<", "!", "\t"]:
			clean_line = clean_line.replace(symbol, " ")
		
		var words = clean_line.split(" ", false)
		for word in words:
			if word.is_valid_int() or word.is_valid_float():
				continue

			if not all_known_identifiers.has(word):
				result.is_valid = false
				result.line_number = line_num
				result.error_message = "La función o instrucción '" + word + "' no existe o está mal escrita."
				return result

			if not allowed_tokens.has(word):
				result.is_valid = false
				result.line_number = line_num
				result.error_message = "La instrucción '" + word + "' no está permitida en este nivel."
				return result

	return result
