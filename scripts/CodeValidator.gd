# res://scripts/CodeValidator.gd
class_name CodeValidator
extends RefCounted

const GAME_COMMANDS = ["avanzar", "girar_izquierda", "girar_derecha", "leer_letra", "recolectar", "escapar"]
const GAME_SENSORS = ["frente_libre", "izquierda_libre", "derecha_libre", "casilla_salida"]
const GD_KEYWORDS = ["if", "elif", "else", "while", "for", "in", "range", "not", "and", "or", "true", "false", "pass", "var", "func"]

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

	# 1. Utilizar siempre la configuración del Inspector (LevelMapData)
	var allowed_tokens: Array[String] = custom_allowed_tokens.duplicate()

	# 2. Pre-escanear funciones y variables creadas por el jugador para no marcarlas como error
	if allowed_tokens.has("func") or allowed_tokens.has("var"):
		for raw_line in lines:
			var trimmed = raw_line.strip_edges()
			if trimmed.begins_with("func "):
				var func_name = trimmed.replace("func ", "").split("(")[0].strip_edges()
				all_known_identifiers.append(func_name)
				allowed_tokens.append(func_name)
			elif trimmed.begins_with("var "):
				var var_name = trimmed.replace("var ", "").split("=")[0].strip_edges()
				all_known_identifiers.append(var_name)
				allowed_tokens.append(var_name)

	var require_indent_next: bool = false
	var last_indent: int = 0

	for idx in range(lines.size()):
		var line_num = idx + 1
		var raw_line = lines[idx]
		var trimmed = raw_line.strip_edges()
		
		if trimmed.is_empty() or trimmed.begins_with("#"):
			continue

		var current_indent = 0
		for i in range(raw_line.length()):
			if raw_line[i] == "\t":
				current_indent += 1
			elif raw_line[i] == " ":
				continue
			else:
				break

		if require_indent_next and current_indent <= last_indent:
			result.is_valid = false
			result.line_number = line_num
			result.error_message = "Falta tabulación tras una estructura de control o declaración."
			return result

		require_indent_next = trimmed.ends_with(":")
		last_indent = current_indent

		if trimmed.begins_with("else if") or " else if " in trimmed:
			result.is_valid = false
			result.line_number = line_num
			result.error_message = "Usa 'elif' en lugar de 'else if'."
			return result

		if trimmed.count("(") != trimmed.count(")"):
			result.is_valid = false
			result.line_number = line_num
			result.error_message = "Paréntesis sin cerrar '()'."
			return result

		if trimmed.begins_with("if ") or trimmed.begins_with("elif ") or trimmed.begins_with("while ") or trimmed.begins_with("for ") or trimmed.begins_with("func ") or trimmed == "else:":
			if not trimmed.ends_with(":"):
				result.is_valid = false
				result.line_number = line_num
				result.error_message = "Falta ':' al final."
				return result

		var clean_line = trimmed
		for symbol in [":", "(", ")", ",", "=", "+", "-", "*", "/", ">", "<", "!", "\t", "[", "]"]:
			clean_line = clean_line.replace(symbol, " ")
		
		var words = clean_line.split(" ", false)
		for word in words:
			if word.is_valid_int() or word.is_valid_float() or word.begins_with('"') or word.begins_with("'"):
				continue

			if not all_known_identifiers.has(word):
				result.is_valid = false
				result.line_number = line_num
				result.error_message = "Identificador desconocido: '" + word + "'."
				return result

			if not allowed_tokens.has(word):
				result.is_valid = false
				result.line_number = line_num
				result.error_message = "La instrucción '" + word + "' no está permitida en este nivel."
				return result

	return result
