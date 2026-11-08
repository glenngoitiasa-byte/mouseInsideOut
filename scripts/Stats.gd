extends Control

@onready var btn_volver = $HBoxContainer/Volver
@onready var graphic_canvas = $VScrollBar/VBoxContainer/PanelContainer/VBoxContainer/Graphic
@onready var opt_type = $VScrollBar/VBoxContainer/PanelContainer/VBoxContainer/HBoxButtonContainer/OptType
@onready var opt_level = $VScrollBar/VBoxContainer/PanelContainer/VBoxContainer/HBoxButtonContainer/OptLevel
@onready var chk_steps = $VScrollBar/VBoxContainer/PanelContainer/VBoxContainer/HBoxButtonContainer/CheckBoxSteps
@onready var chk_cheeses = $VScrollBar/VBoxContainer/PanelContainer/VBoxContainer/HBoxButtonContainer/CheckBoxCheeses
@onready var chk_lines = $VScrollBar/VBoxContainer/PanelContainer/VBoxContainer/HBoxButtonContainer/CheckBoxLines
@onready var chk_crashes = $VScrollBar/VBoxContainer/PanelContainer/VBoxContainer/HBoxButtonContainer/CheckBoxCrashes
@onready var lbl_victories = $VScrollBar/VBoxContainer/PanelContainer/VBoxContainer/HBoxButtonContainer/LblVictories

var historial_completo: Array = []
var historial_filtrado: Array = []

func _ready() -> void:
	# Cargar datos desde SaveManager
	var stats = SaveManager.current_save.get("player_stats", {})
	historial_completo = stats.get("attempts_log", [])
	
	# 1. Configurar Opciones Principales
	opt_type.clear()
	opt_type.add_item("Todos los Niveles", 0)
	opt_type.add_item("Solo Historia", 1)
	opt_type.add_item("Solo Aleatorios", 2)
	
	# 2. Conectar señales
	btn_volver.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	opt_type.item_selected.connect(_on_tipo_seleccionado)
	opt_level.item_selected.connect(_actualizar_vista_index)
	
	chk_steps.toggled.connect(_actualizar_vista_toggle)
	chk_cheeses.toggled.connect(_actualizar_vista_toggle)
	chk_lines.toggled.connect(_actualizar_vista_toggle)
	chk_crashes.toggled.connect(_actualizar_vista_toggle)
	
	graphic_canvas.draw.connect(_dibujar_graficas)
	
	# Inicializar la interfaz en "Todos los Niveles"
	_on_tipo_seleccionado(0)

# --- LÓGICA DE MENÚS DESPLEGABLES ---

func _on_tipo_seleccionado(tipo_index: int) -> void:
	opt_level.clear()
	opt_level.add_item("Todos", 0)
	opt_level.set_item_metadata(0, "todos")
	
	# Deshabilitar selector de nivel si estamos en "Todos los niveles"
	opt_level.disabled = (tipo_index == 0)
	
	if tipo_index != 0:
		var ids_encontrados = []
		
		# Extraer niveles jugados del historial
		for intento in historial_completo:
			var tipo = intento.get("tipo", "historia")
			var nid = str(intento.get("nivel_id", ""))
			
			if (tipo_index == 1 and tipo == "historia") or (tipo_index == 2 and tipo == "aleatorio"):
				if not ids_encontrados.has(nid):
					ids_encontrados.append(nid)
					
		ids_encontrados.sort() # Ordenar alfabética o numéricamente
		
		# Agregar los niveles/nombres descubiertos al selector
		for nid in ids_encontrados:
			var texto_mostrar = "Nivel " + nid if tipo_index == 1 else nid # Ej: "Nivel 1" o "Mi Nivel Loco"
			opt_level.add_item(texto_mostrar)
			opt_level.set_item_metadata(opt_level.get_item_count() - 1, nid)
	
	opt_level.select(0) # Volver a "Todos" por defecto al cambiar de categoría
	_actualizar_vista()

# --- LÓGICA DE FILTROS Y UI ---

func _actualizar_vista_toggle(_toggled: bool) -> void: _actualizar_vista()
func _actualizar_vista_index(_index: int) -> void: _actualizar_vista()

func _actualizar_vista() -> void:
	# REGLA: Los checkboxes solo se habilitan si se seleccionó un nivel en específico (índice > 0)
	var es_nivel_especifico = (opt_type.selected != 0 and opt_level.selected != 0)
	chk_steps.disabled = not es_nivel_especifico
	chk_cheeses.disabled = not es_nivel_especifico
	chk_lines.disabled = not es_nivel_especifico
	chk_crashes.disabled = not es_nivel_especifico

	# 1. Filtrar los datos con la selección actual
	_filtrar_datos()
	
	# 2. Actualizar el conteo de victorias del filtro actual
	var victorias = 0
	for intento in historial_filtrado:
		if intento.get("victoria", false):
			victorias += 1
			
	lbl_victories.text = "Victorias: " + str(victorias)
	
	# 3. Mandar a redibujar la gráfica
	graphic_canvas.queue_redraw()

func _filtrar_datos() -> void:
	historial_filtrado.clear()
	var filtro_tipo = opt_type.selected
	var filtro_nivel = opt_level.get_item_metadata(opt_level.selected) if opt_level.get_item_count() > 0 else "todos"
	
	for intento in historial_completo:
		var tipo = intento.get("tipo", "historia")
		var nid = str(intento.get("nivel_id", ""))
		
		var pasa_tipo = (filtro_tipo == 0) or (filtro_tipo == 1 and tipo == "historia") or (filtro_tipo == 2 and tipo == "aleatorio")
		var pasa_nivel = (filtro_nivel == "todos") or (nid == filtro_nivel)
		
		if pasa_tipo and pasa_nivel:
			historial_filtrado.append(intento)

# --- DIBUJADO DE LA GRÁFICA ---

func _dibujar_graficas() -> void:
	var rect_size = graphic_canvas.size
	# Fondo oscuro
	graphic_canvas.draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0.15, 0.15, 0.15, 1.0))
	
	if historial_filtrado.size() == 0 or chk_steps.disabled: 
		return
		
	var dibuja_pasos = chk_steps.button_pressed
	var dibuja_quesos = chk_cheeses.button_pressed
	var dibuja_lineas = chk_lines.button_pressed
	var dibuja_choques = chk_crashes.button_pressed
	
	# Si no hay ninguna opción marcada, no dibujamos nada más
	if not (dibuja_pasos or dibuja_quesos or dibuja_lineas or dibuja_choques):
		return
		
	# 1. Encontrar el valor máximo global para compartir la misma escala Y
	var max_val = 10.0
	for intento in historial_filtrado:
		if dibuja_pasos: max_val = max(max_val, float(intento.get("pasos", 0)))
		if dibuja_quesos: max_val = max(max_val, float(intento.get("quesos", 0)))
		if dibuja_lineas: max_val = max(max_val, float(intento.get("lineas", 0)))
		if dibuja_choques: max_val = max(max_val, float(intento.get("choques", 0)))
		
	# Márgenes para dejar espacio a los números
	var margen_izq = 30.0 # Espacio para el eje Y
	var margen_inf = 20.0 # Espacio para el eje X
	var margen_sup = 10.0
	var altura_util = rect_size.y - margen_sup - margen_inf
	var ancho_util = rect_size.x - margen_izq
	
	var font = ThemeDB.fallback_font
	var font_size = 12
	var color_texto = Color(0.7, 0.7, 0.7)
	
	# 2. Dibujar Cuadrícula y Textos del Eje Y
	var lineas_y = 5
	for i in range(lineas_y + 1):
		var proporcion = 1.0 - (float(i) / lineas_y)
		var pos_y = margen_sup + (altura_util * (1.0 - proporcion))
		var valor_etiqueta = max_val * proporcion
		
		# Línea de fondo
		graphic_canvas.draw_line(Vector2(margen_izq, pos_y), Vector2(rect_size.x, pos_y), Color(1, 1, 1, 0.1), 1.0)
		# Texto Y (Redondeado para que no tenga decimales largos)
		graphic_canvas.draw_string(font, Vector2(2, pos_y + 4), str(round(valor_etiqueta)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color_texto)

	# 3. Dibujar Textos del Eje X (Número de Intento)
	var num_intentos = historial_filtrado.size()
	var step_x = 0.0
	if num_intentos > 1:
		step_x = ancho_util / float(num_intentos - 1)
	
	for i in range(num_intentos):
		var pos_x = margen_izq + (i * step_x)
		if num_intentos == 1:
			pos_x = margen_izq + (ancho_util / 2.0)
			
		# Para evitar que los números se amontonen si el jugador tiene 50 intentos:
		# Solo mostramos el número si hay pocos intentos, o de 5 en 5, y siempre el último.
		if num_intentos <= 15 or (i + 1) % 5 == 0 or i == num_intentos - 1:
			graphic_canvas.draw_string(font, Vector2(pos_x - 4, rect_size.y - 4), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color_texto)
	
	# 4. Dibujar las líneas enviando los márgenes y el máximo global
	if dibuja_pasos: _dibujar_linea("pasos", Color.LIGHT_BLUE, rect_size, max_val, margen_izq, margen_sup, margen_inf)
	if dibuja_quesos: _dibujar_linea("quesos", Color.GOLD, rect_size, max_val, margen_izq, margen_sup, margen_inf)
	if dibuja_lineas: _dibujar_linea("lineas", Color.ORANGE_RED, rect_size, max_val, margen_izq, margen_sup, margen_inf)
	if dibuja_choques: _dibujar_linea("choques", Color.RED, rect_size, max_val, margen_izq, margen_sup, margen_inf)

func _dibujar_linea(llave_dato: String, color: Color, rect_size: Vector2, max_val: float, m_izq: float, m_sup: float, m_inf: float) -> void:
	var altura_util = rect_size.y - m_sup - m_inf
	var ancho_util = rect_size.x - m_izq
	var puntos = PackedVector2Array()
	
	if historial_filtrado.size() == 1:
		var valor = float(historial_filtrado[0].get(llave_dato, 0))
		var pos_y = rect_size.y - m_inf - ((valor / max_val) * altura_util)
		var punto_unico = Vector2(m_izq + (ancho_util / 2.0), pos_y)
		graphic_canvas.draw_circle(punto_unico, 4.0, color)
		return

	var step_x = ancho_util / float(historial_filtrado.size() - 1)
	for i in range(historial_filtrado.size()):
		var valor = float(historial_filtrado[i].get(llave_dato, 0))
		var pos_x = m_izq + (i * step_x)
		var pos_y = rect_size.y - m_inf - ((valor / max_val) * altura_util)
		puntos.append(Vector2(pos_x, pos_y))
		
	graphic_canvas.draw_polyline(puntos, color, 2.0, true)
	for p in puntos:
		graphic_canvas.draw_circle(p, 3.0, color)
