# res://scripts/CodeValidator.gd
class_name CodeValidator
extends RefCounted

# Configuración de palabras permitidas por nivel
static func get_allowed_tokens(level_number: int) -> Array[String]:
	match level_number:
		1:
			return ["avanzar", "girar_izquierda", "girar_derecha"]
		2:
			return ["avanzar", "girar_izquierda", "girar_derecha", "frente_libre", "izquierda_libre", "derecha_libre", "if", "else"]
		3, 4:
			return ["avanzar", "girar_izquierda", "girar_derecha", "frente_libre", "izquierda_libre", "derecha_libre", "if", "else", "while", "for", "var", "in", "range", "not", "and", "or", "true", "false"]
		_:
			return []

# Resultado de la validación
class ValidationResult:
	var is_valid: bool = true
	var error_message: String = ""
	var line_number: int = -1

static func validate_code(code: String, level_number: int) -> ValidationResult:
	var result = ValidationResult.new()
	var lines = code.split("\n")
	var allowed_tokens = get_allowed_tokens(level_number)
	
	# Palabras clave estructurales que queremos fiscalizar por nivel
	var structural_keywords = ["while", "for", "if", "else", "var"]
	
	for idx in range(lines.size()):
		var line_num = idx + 1
		var raw_line = lines[idx]
		var trimmed = raw_line.strip_edges()
		
		if trimmed.is_empty() or trimmed.begins_with("#"):
			continue
			
		# 1. Verificar palabras no permitidas en el nivel actual
		var words = trimmed.replace(":", " ").replace("(", " ").replace(")", " ").split(" ", false)
		for word in words:
			if structural_keywords.has(word) and not allowed_tokens.has(word):
				result.is_valid = false
				result.line_number = line_num
				result.error_message = "La instrucción '" + word + "' no está permitida en el Nivel " + str(level_number) + "."
				return result

		# 2. Validar dos puntos al final de estructuras de control
		if trimmed.begins_with("if ") or trimmed.begins_with("while ") or trimmed.begins_with("for ") or trimmed == "else:":
			if not trimmed.ends_with(":"):
				result.is_valid = false
				result.line_number = line_num
				result.error_message = "Falta ':' al final de la estructura de control."
				return result

	return result
