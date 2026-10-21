extends CanvasLayer
## Hoja con lo que hay en cada piso. Se abre/cierra con la tecla M.
## Para usarla: en main.gd, dentro de _ready(), agregar:
##     add_child(preload("res://scripts/hoja_pisos.gd").new())

const TECLA := KEY_M

const CONTENIDO := """[center][font_size=24][b]UTN FRC — EDIFICIO CENTRAL[/b][/font_size]
[i]Guía de pisos[/i][/center]

[font_size=10][b]PLANTA BAJA[/b][/font_size]
• Aulas 101 a 115
• Laboratorio Central — Depto. Ingeniería Electrónica
• Cafetería
• Fotocopiadora 1 y Fotocopiadora 2
• Auditorio Central (entrada celeste)
• Patio del Estudiante
	Examenes: Aula 106 - Cafeteria - Patio del Estudiante - Fotocopiadora 1

[font_size=10][b]PRIMER PISO[/b][/font_size]
• Bedelía General
• Dirección Departamental
• Depto. Ing. en Sistemas
• Depto. Ing. Electrónica
• CETRA (Trámites)
• Biblioteca Central
	Fusible: Laberinto Bedelia General

[font_size=10][b]SEGUNDO PISO[/b][/font_size]
• Aulas 201 a 219
• Aula 210 (Magna)
• Cafetería y Comedor — Bar y retiro de bandejas
• Monumento AETI
	Llave: "Que ganas de comer algo!"

[center][i]Presioná M para cerrar[/i][/center]"""

var hoja: PanelContainer

func _ready() -> void:
	layer = 10                                   # por encima del HUD
	process_mode = Node.PROCESS_MODE_ALWAYS      # funciona aunque el juego esté en pausa

	# Fondo oscuro detrás de la hoja
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.6)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# La "hoja" de papel
	hoja = PanelContainer.new()
	hoja.custom_minimum_size = Vector2(620, 0)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.965, 0.796, 0.626, 1.0)    # color papel
	estilo.set_corner_radius_all(4)
	estilo.set_content_margin_all(32)
	estilo.shadow_size = 12
	hoja.add_theme_stylebox_override("panel", estilo)

	var texto := RichTextLabel.new()
	texto.bbcode_enabled = true
	texto.fit_content = true
	texto.scroll_active = false
	texto.text = CONTENIDO
	texto.add_theme_color_override("default_color", Color(0.12, 0.1, 0.08))
	texto.add_theme_font_size_override("normal_font_size", 15)
	hoja.add_child(texto)

	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(fondo)
	var centro := CenterContainer.new()          # centra la hoja en pantalla
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(hoja)
	raiz.add_child(centro)
	add_child(raiz)

	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == TECLA:
		visible = not visible
		get_tree().paused = visible              # congela al jugador mientras lee
		get_viewport().set_input_as_handled()
