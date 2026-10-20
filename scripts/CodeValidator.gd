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

static func validate_code(code: String, level_number: int) -> ValidationResult:
	var result = ValidationResult.new()
	var lines = code.split("\n")
	var allowed_tokens = get_allowed_tokens(level_number)
	
	var all_known_identifiers: Array[String] = []
	all_known_identifiers.append_array(GAME_COMMANDS)
	all_known_identifiers.append_array(GAME_SENSORS)
	all_known_identifiers.append_array(GD_KEYWORDS)

	for idx in range(lines.size()):
		var line_num = idx + 1
		var raw_line = lines[idx]
		var trimmed = raw_line.strip_edges()
		
		# Ignorar líneas vacías o comentarios
		if trimmed.is_empty() or trimmed.begins_with("#"):
			continue

		# 1. Detección de "else if" (Sintaxis no válida en GDScript)
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
			# Omitir números
			if word.is_valid_int() or word.is_valid_float():
				continue

			# A. Verificar si la función o palabra EXISTE en el juego
			if not all_known_identifiers.has(word):
				result.is_valid = false
				result.line_number = line_num
				result.error_message = "La función o instrucción '" + word + "' no existe o está mal escrita."
				return result

			# B. Verificar si está PERMITIDA en el nivel actual
			if not allowed_tokens.has(word):
				result.is_valid = false
				result.line_number = line_num
				result.error_message = "La instrucción '" + word + "' no está permitida en el Nivel " + str(level_number) + "."
				return result

	return result
