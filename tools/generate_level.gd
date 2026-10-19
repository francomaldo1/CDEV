extends SceneTree
# =====================================================================
# UTN FRC - Edificio Central - 3 Pisos Completos
# Pasillos 100% despejados según mapa anotado en rojo
# Entrada del Auditorio (línea celeste) en el pasillo sur entre fotocopiadoras
# =====================================================================
const H = 4.5       # Altura por piso
const HA = 9.0      # Altura auditorio (hasta el piso 2)
const G = 0.3       # Grosor pared
const PW = 2.8      # Ancho estándar de puertas
const INF_V = 99999.0

# Materiales
var mp: Material   # piso granito
var mw: Material   # pared facu
var mc: Material   # techo
var ma: Material   # auditorio
var mpa: Material  # patio
var ms: Material   # escalera negra
var mg: Material   # vidrio
var my: Material   # franja amarilla
var ml: Material   # locker
var mco: Material  # comedor
var mu: Material   # UTN azul
var mcr: Material  # silla roja

func _init():
	print(">>> Generando UTN FRC con Piso 2 clonado de PB y Cafetería real...")
	mp = load("res://materials/mat_floor_granito.tres")
	mw = load("res://materials/mat_wall_facu.tres")
	mc = load("res://materials/mat_ceiling.tres")
	ma = load("res://materials/mat_auditorio.tres")
	mpa = load("res://materials/mat_patio.tres")
	ms = load("res://materials/mat_stairs.tres")
	mg = load("res://materials/mat_glass.tres")
	my = load("res://materials/mat_yellow_stripe.tres")
	ml = load("res://materials/mat_locker.tres")
	mco = load("res://materials/mat_comedor.tres")
	mu = load("res://materials/mat_utn_blue.tres")
	mcr = load("res://materials/mat_chair_red.tres")

	var ed = Node3D.new()
	ed.name = "EdificioCentral"

	# Generar los 3 pisos
	for piso in range(3):
		var y = piso * H
		var pn = Node3D.new()
		pn.name = ["PlantaBaja", "PrimerPiso", "SegundoPiso"][piso]
		ed.add_child(pn); pn.owner = ed

		_pisos_y_techos(pn, ed, y, piso)
		_paredes_perimetrales(pn, ed, y, piso)

		match piso:
			0: _planta_baja(pn, ed, y)
			1: _primer_piso(pn, ed, y)
			2: _segundo_piso(pn, ed, y)

	_patio_elementos(ed)
	_auditorio_completo(ed)
	_escaleras_torres(ed)
	_luces_completas(ed)

	var pk = PackedScene.new()
	pk.pack(ed)
	ResourceSaver.save(pk, "res://scenes/edificio_central.tscn")
	print(">>> res://scenes/edificio_central.tscn GUARDADO!")

	# _gen_main() -- Desactivado para no pisar main.gd ni main.tscn personalizados
	print(">>> TODO GENERADO CON ÉXITO!")
	quit()

# =====================================================================
# HELPERS
# =====================================================================
func _caja(p: Node, r: Node, n: String, pos: Vector3, sz: Vector3, mat: Material) -> CSGBox3D:
	var b = CSGBox3D.new()
	b.name = n; b.position = pos; b.size = sz; b.use_collision = true; b.material = mat
	p.add_child(b); b.owner = r; return b

func _lbl(p: Node, r: Node, n: String, txt: String, pos: Vector3, rot: Vector3):
	var l = Label3D.new()
	l.name = n; l.text = txt; l.position = pos; l.rotation_degrees = rot
	l.font_size = 42; l.modulate = Color(1.0, 0.9, 0.45); l.outline_size = 10
	p.add_child(l); l.owner = r

# Pared E-W (corre a lo largo de X) con puerta opcional
func _pew(p: Node, r: Node, n: String, z: float, x1: float, x2: float, y: float, h: float, dx: float, mat: Material):
	if x1 > x2: var tmp = x1; x1 = x2; x2 = tmp
	if dx < 90000:
		var lw = (dx - PW/2.0) - x1
		if lw > 0.3: _caja(p, r, n+"_L", Vector3(x1 + lw/2.0, y + h/2.0, z), Vector3(lw, h, G), mat)
		var rw = x2 - (dx + PW/2.0)
		if rw > 0.3: _caja(p, r, n+"_R", Vector3(x2 - rw/2.0, y + h/2.0, z), Vector3(rw, h, G), mat)
		_caja(p, r, n+"_Dintel", Vector3(dx, y + h - 0.4, z), Vector3(PW + 0.1, 0.8, G), mat)
	else:
		_caja(p, r, n, Vector3((x1+x2)/2.0, y + h/2.0, z), Vector3(x2 - x1, h, G), mat)

# Pared N-S (corre a lo largo de Z) con puerta opcional
func _pns(p: Node, r: Node, n: String, x: float, z1: float, z2: float, y: float, h: float, dz: float, mat: Material):
	if z1 > z2: var tmp = z1; z1 = z2; z2 = tmp
	if dz < 90000:
		var fw = (dz - PW/2.0) - z1
		if fw > 0.3: _caja(p, r, n+"_F", Vector3(x, y + h/2.0, z1 + fw/2.0), Vector3(G, h, fw), mat)
		var bw = z2 - (dz + PW/2.0)
		if bw > 0.3: _caja(p, r, n+"_B", Vector3(x, y + h/2.0, z2 - bw/2.0), Vector3(G, h, bw), mat)
		_caja(p, r, n+"_Dintel", Vector3(x, y + h - 0.4, dz), Vector3(G, 0.8, PW + 0.1), mat)
	else:
		_caja(p, r, n, Vector3(x, y + h/2.0, (z1+z2)/2.0), Vector3(G, h, z2 - z1), mat)

func _pupitres(p: Node, r: Node, n: String, x1: float, z1: float, x2: float, z2: float, y: float):
	var c = 0
	var x = x1 + 2.5
	while x < x2 - 1.5:
		var z = z1 + 2.0
		while z < z2 - 1.5:
			_caja(p, r, "%s_%d" % [n, c], Vector3(x, y + 0.4, z), Vector3(2.0, 0.8, 1.0), mp)
			c += 1; z += 3.2
		x += 4.0

func _pizarron(p: Node, r: Node, n: String, x: float, z: float, y: float, horiz: bool):
	if horiz:
		_caja(p, r, n, Vector3(x, y + 1.5, z), Vector3(5.0, 1.5, 0.08), mpa)
	else:
		_caja(p, r, n, Vector3(x, y + 1.5, z), Vector3(0.08, 1.5, 5.0), mpa)

# =====================================================================
# PISOS Y TECHOS (Hueco abierto en patio para todos los pisos)
# =====================================================================
func _pisos_y_techos(p: Node, r: Node, y: float, piso: int):
	var ty = y + H + 0.1

	if piso == 0:
		# PB: Piso continuo en todo el terreno
		_caja(p, r, "PisoBase", Vector3(0, y - 0.1, 0), Vector3(130, 0.2, 90), mp)
		# Suelo del patio en PB
		_caja(p, r, "PisoPatioVerde", Vector3(0, y - 0.05, 0), Vector3(34, 0.2, 49), mpa)
	else:
		# P1 y P2: Suelo con hueco en el patio (X: -17 a 17, Z: -24 a 25)
		_caja(p, r, "PisoNorte", Vector3(0, y - 0.1, -34.5), Vector3(130, 0.2, 21), mp)
		_caja(p, r, "PisoSur", Vector3(0, y - 0.1, 35.0), Vector3(130, 0.2, 20), mp)
		_caja(p, r, "PisoOeste", Vector3(-41, y - 0.1, 0.5), Vector3(48, 0.2, 49), mp)
		_caja(p, r, "PisoEste", Vector3(41, y - 0.1, 0.5), Vector3(48, 0.2, 49), mp)

	# Techo del piso: siempre tiene hueco sobre el patio (a cielo abierto)
	_caja(p, r, "TechoNorte", Vector3(0, ty, -34.5), Vector3(130, 0.2, 21), mc)
	_caja(p, r, "TechoSur", Vector3(0, ty, 35.0), Vector3(130, 0.2, 20), mc)
	_caja(p, r, "TechoOeste", Vector3(-41, ty, 0.5), Vector3(48, 0.2, 49), mc)
	_caja(p, r, "TechoEste", Vector3(41, ty, 0.5), Vector3(48, 0.2, 49), mc)

	if piso == 2:
		# Piso 2: Suelo y techo del ala sur (Cafetería del 2do piso, Z: 35 a 85, X: -20 a 20)
		_caja(p, r, "CafeSueloP2", Vector3(0, y - 0.1, 60.0), Vector3(40, 0.2, 50), mp)
		_caja(p, r, "CafeTechoP2", Vector3(0, ty, 60.0), Vector3(40, 0.2, 50), mc)

	# (Pisos y techos de escaleras se manejan como pozo vertical continuo en _escaleras_torres)

# =====================================================================
# PAREDES PERIMETRALES EXTERIORES
# =====================================================================
func _paredes_perimetrales(p: Node, r: Node, y: float, piso: int):
	# Norte (Z = -45): de X = -65 a +37, y de X = 47 a 65 (deja libre X: 37 a 47 para la escalera norte)
	_pew(p, r, "ExtNorteOeste", -45.0, -65.0, 37.0, y, H, INF_V, mw)
	_pew(p, r, "ExtNorteEste", -45.0, 47.0, 65.0, y, H, INF_V, mw)

	# Oeste (X = -65): deja abierta la conexión con la escalera oeste (Z: 25 a 35)
	_pns(p, r, "ExtOesteNorte", -65.0, -45.0, 25.0, y, H, INF_V, mw)
	_pns(p, r, "ExtOesteSur", -65.0, 35.0, 45.0, y, H, INF_V, mw)

	# Este (X = 65): deja abierta la conexión con la escalera este (Z: 25 a 35)
	_pns(p, r, "ExtEsteNorte", 65.0, -45.0, 25.0, y, H, INF_V, mw)
	_pns(p, r, "ExtEsteSur", 65.0, 35.0, 45.0, y, H, INF_V, mw)

	# Sur (Z = 45): pared exterior sur
	_pew(p, r, "ExtSurOeste", 45.0, -65.0, -16.0, y, H, INF_V, mw)
	_pew(p, r, "ExtSurEste", 45.0, 16.0, 65.0, y, H, INF_V, mw)

# =====================================================================
# PLANTA BAJA (CON PASILLOS ROJOS 100% LIBRES)
# =====================================================================
func _planta_baja(p: Node, r: Node, y: float):
	var pb = Node3D.new()
	pb.name = "HabitacionesPB"; p.add_child(pb); pb.owner = r

	# -------------------------------------------------------------
	# 1. BLOQUE AULAS NORTE (Z: -45 a -33)
	# Pared frontal sur (Z = -33) con 4 puertas que dan al PASILLO NORTE
	# -------------------------------------------------------------
	_pew(pb, r, "AulaN1_Sur", -33.0, -65.0, -40.0, y, H, -52.5, mw)
	_pew(pb, r, "AulaN2_Sur", -33.0, -40.0, -15.0, y, H, -27.5, mw)
	_pew(pb, r, "AulaN3_Sur", -33.0, -15.0, 10.0, y, H, -2.5, mw)
	_pew(pb, r, "AulaN4_Sur", -33.0, 10.0, 37.0, y, H, 23.5, mw)

	# Divisorias entre aulas norte
	_pns(pb, r, "DivN_1_2", -40.0, -45.0, -33.0, y, H, INF_V, mw)
	_pns(pb, r, "DivN_2_3", -15.0, -45.0, -33.0, y, H, INF_V, mw)
	_pns(pb, r, "DivN_3_4", 10.0, -45.0, -33.0, y, H, INF_V, mw)
	_pns(pb, r, "ParedEsteAulasN", 37.0, -45.0, -33.0, y, H, INF_V, mw)

	# Equipamiento aulas norte
	_pizarron(pb, r, "PizN1", -52.5, -44.6, y, true)
	_pizarron(pb, r, "PizN2", -27.5, -44.6, y, true)
	_pizarron(pb, r, "PizN3", -2.5, -44.6, y, true)
	_pizarron(pb, r, "PizN4", 23.5, -44.6, y, true)

	_pupitres(pb, r, "PupN1", -63.0, -43.0, -42.0, -35.0, y)
	_pupitres(pb, r, "PupN2", -38.0, -43.0, -17.0, -35.0, y)
	_pupitres(pb, r, "PupN3", -13.0, -43.0, 8.0, -35.0, y)
	_pupitres(pb, r, "PupN4", 12.0, -43.0, 35.0, -35.0, y)

	_lbl(pb, r, "CartelN1", "AULA 101", Vector3(-52.5, y + 3.2, -32.7), Vector3(0, 180, 0))
	_lbl(pb, r, "CartelN2", "AULA 102", Vector3(-27.5, y + 3.2, -32.7), Vector3(0, 180, 0))
	_lbl(pb, r, "CartelN3", "AULA 103", Vector3(-2.5, y + 3.2, -32.7), Vector3(0, 180, 0))
	_lbl(pb, r, "CartelN4", "AULA 104", Vector3(23.5, y + 3.2, -32.7), Vector3(0, 180, 0))

	# -------------------------------------------------------------
	# 2. BLOQUE AULAS OESTE EXTERIORES (X: -65 a -47)
	# Pared este (X = -47) con puertas que dan al PASILLO OESTE
	# -------------------------------------------------------------
	_pns(pb, r, "AulaW1_Este", -47.0, -33.0, -19.0, y, H, -26.0, mw)
	_pns(pb, r, "AulaW2_Este", -47.0, -19.0, -5.0, y, H, -12.0, mw)
	_pns(pb, r, "AulaW3_Este", -47.0, -5.0, 10.0, y, H, 2.5, mw)
	_pns(pb, r, "AulaW4_Este", -47.0, 10.0, 25.0, y, H, 17.5, mw)

	# Divisorias E-W
	_pew(pb, r, "DivW_1_2", -19.0, -65.0, -47.0, y, H, INF_V, mw)
	_pew(pb, r, "DivW_2_3", -5.0, -65.0, -47.0, y, H, INF_V, mw)
	_pew(pb, r, "DivW_3_4", 10.0, -65.0, -47.0, y, H, INF_V, mw)
	_pew(pb, r, "AulaW4_Sur", 25.0, -65.0, -47.0, y, H, INF_V, mw)

	_pizarron(pb, r, "PizW1", -64.6, -26.0, y, false)
	_pizarron(pb, r, "PizW2", -64.6, -12.0, y, false)
	_pizarron(pb, r, "PizW3", -64.6, 2.5, y, false)
	_pizarron(pb, r, "PizW4", -64.6, 17.5, y, false)

	_pupitres(pb, r, "PupW1", -63.0, -31.0, -49.0, -21.0, y)
	_pupitres(pb, r, "PupW2", -63.0, -17.0, -49.0, -7.0, y)
	_pupitres(pb, r, "PupW3", -63.0, -3.0, -49.0, 8.0, y)
	_pupitres(pb, r, "PupW4", -63.0, 12.0, -49.0, 23.0, y)

	_lbl(pb, r, "CartelW1", "AULA 105", Vector3(-46.7, y + 3.2, -26.0), Vector3(0, 90, 0))
	_lbl(pb, r, "CartelW2", "AULA 106", Vector3(-46.7, y + 3.2, -12.0), Vector3(0, 90, 0))
	_lbl(pb, r, "CartelW3", "AULA 107", Vector3(-46.7, y + 3.2, 2.5), Vector3(0, 90, 0))
	_lbl(pb, r, "CartelW4", "AULA 108", Vector3(-46.7, y + 3.2, 17.5), Vector3(0, 90, 0))

	# -------------------------------------------------------------
	# 3. BLOQUE OESTE INTERIOR (Aula, Lab Electrónica, Aula) (X: -37 a -17)
	# Pared oeste (X = -37) con puertas que dan al PASILLO OESTE
	# -------------------------------------------------------------
	_pew(pb, r, "BloqueWI_Norte", -24.0, -37.0, -17.0, y, H, INF_V, mw)
	_pew(pb, r, "BloqueWI_Sur", 25.0, -37.0, -17.0, y, H, INF_V, mw)
	_pns(pb, r, "BloqueWI_Patio", -17.0, -24.0, 25.0, y, H, INF_V, mw) # Cara hacia el patio

	# Aula WI1 (Norte)
	_pns(pb, r, "AulaWI1_Oeste", -37.0, -24.0, -10.0, y, H, -17.0, mw)
	_pew(pb, r, "DivWI_1_Lab", -10.0, -37.0, -17.0, y, H, INF_V, mw)
	_pupitres(pb, r, "PupWI1", -35.0, -22.0, -19.0, -12.0, y)
	_lbl(pb, r, "CartelWI1", "AULA 109", Vector3(-37.3, y + 3.2, -17.0), Vector3(0, -90, 0))

	# LABORATORIO DE INGENIERÍA ELECTRÓNICA (Centro)
	_pns(pb, r, "Lab_Oeste", -37.0, -10.0, 11.0, y, H, 0.5, mw)
	# Ventanal de vidrio en la pared del pasillo
	_caja(pb, r, "LabVidrio", Vector3(-37.0, y + 2.0, -4.5), Vector3(0.08, 2.2, 5.0), mg)
	# Cartel oficial idéntico al de la foto
	_lbl(pb, r, "CartelLabOficial", "LABORATORIO CENTRAL\nDEPARTAMENTO\nINGENIERÍA ELECTRÓNICA", Vector3(-37.3, y + 2.2, -4.5), Vector3(0, -90, 0))
	# Locker metálico afuera en el pasillo
	_caja(pb, r, "LabLocker", Vector3(-37.6, y + 0.9, -8.0), Vector3(0.6, 1.8, 0.8), ml)
	# Mesadas de trabajo de electrónica adentro
	for i in range(3):
		_caja(pb, r, "MesadaLab_%d" % i, Vector3(-27.0, y + 0.45, -6.0 + i * 5.0), Vector3(14.0, 0.9, 1.6), mw)
	_pew(pb, r, "DivLab_WI2", 11.0, -37.0, -17.0, y, H, INF_V, mw)

	# Aula WI2 (Sur)
	_pns(pb, r, "AulaWI2_Oeste", -37.0, 11.0, 25.0, y, H, 18.0, mw)
	_pupitres(pb, r, "PupWI2", -35.0, 13.0, -19.0, 23.0, y)
	_lbl(pb, r, "CartelWI2", "AULA 110", Vector3(-37.3, y + 3.2, 18.0), Vector3(0, -90, 0))

	# -------------------------------------------------------------
	# 4. BLOQUE ESTE INTERIOR (3 Aulas) (X: 17 a 37)
	# Pared este (X = 37) con puertas que dan al PASILLO ESTE
	# -------------------------------------------------------------
	_pew(pb, r, "BloqueEI_Norte", -24.0, 17.0, 37.0, y, H, INF_V, mw)
	_pew(pb, r, "BloqueEI_Sur", 25.0, 17.0, 37.0, y, H, INF_V, mw)
	_pns(pb, r, "BloqueEI_Patio", 17.0, -24.0, 25.0, y, H, INF_V, mw) # Cara hacia el patio

	_pns(pb, r, "AulaEI1_Este", 37.0, -24.0, -8.0, y, H, -16.0, mw)
	_pew(pb, r, "DivEI_1_2", -8.0, 17.0, 37.0, y, H, INF_V, mw)
	_pupitres(pb, r, "PupEI1", 19.0, -22.0, 35.0, -10.0, y)
	_lbl(pb, r, "CartelEI1", "AULA 111", Vector3(37.3, y + 3.2, -16.0), Vector3(0, 90, 0))

	_pns(pb, r, "AulaEI2_Este", 37.0, -8.0, 8.0, y, H, 0.0, mw)
	_pew(pb, r, "DivEI_2_3", 8.0, 17.0, 37.0, y, H, INF_V, mw)
	_pupitres(pb, r, "PupEI2", 19.0, -6.0, 35.0, 6.0, y)
	_lbl(pb, r, "CartelEI2", "AULA 112", Vector3(37.3, y + 3.2, 0.0), Vector3(0, 90, 0))

	_pns(pb, r, "AulaEI3_Este", 37.0, 8.0, 25.0, y, H, 16.5, mw)
	_pupitres(pb, r, "PupEI3", 19.0, 10.0, 35.0, 23.0, y)
	_lbl(pb, r, "CartelEI3", "AULA 113", Vector3(37.3, y + 3.2, 16.5), Vector3(0, 90, 0))

	# -------------------------------------------------------------
	# 5. BLOQUE ESTE EXTERIOR (Aula, Cafetería, Aula) (X: 47 a 65)
	# Pared oeste (X = 47) con puertas que dan al PASILLO ESTE
	# -------------------------------------------------------------
	# Aula E1 (Norte)
	_pns(pb, r, "AulaE1_Oeste", 47.0, -45.0, -15.0, y, H, -30.0, mw)
	_pew(pb, r, "DivE_1_Cafe", -15.0, 47.0, 65.0, y, H, INF_V, mw)
	_pizarron(pb, r, "PizE1", 64.6, -30.0, y, false)
	_pupitres(pb, r, "PupE1", 49.0, -43.0, 63.0, -17.0, y)
	_lbl(pb, r, "CartelE1", "AULA 114", Vector3(46.7, y + 3.2, -30.0), Vector3(0, -90, 0))

	# CAFETERÍA (Centro)
	_pns(pb, r, "Cafe_Oeste", 47.0, -15.0, 10.0, y, H, -2.5, mw)
	_pew(pb, r, "DivCafe_E2", 10.0, 47.0, 65.0, y, H, INF_V, mw)
	_caja(pb, r, "CafeBarra", Vector3(51.0, y + 0.55, -2.0), Vector3(1.8, 1.1, 14.0), ma)
	for i in range(3):
		for j in range(2):
			_caja(pb, r, "MesaCafe_%d_%d" % [i,j], Vector3(56.0 + j * 5.0, y + 0.4, -10.0 + i * 8.0), Vector3(2.5, 0.8, 2.5), mp)
	_lbl(pb, r, "CartelCafe", "CAFETERÍA", Vector3(46.7, y + 3.2, -2.5), Vector3(0, -90, 0))

	# Aula E2 (Sur)
	_pns(pb, r, "AulaE2_Oeste", 47.0, 10.0, 25.0, y, H, 17.5, mw)
	_pew(pb, r, "AulaE2_Sur", 25.0, 47.0, 65.0, y, H, INF_V, mw)
	_pupitres(pb, r, "PupE2", 49.0, 12.0, 63.0, 23.0, y)
	_lbl(pb, r, "CartelE2", "AULA 115", Vector3(46.7, y + 3.2, 17.5), Vector3(0, -90, 0))

	# -------------------------------------------------------------
	# 6. FOTOCOPIADORAS (Sur del pasillo horizontal)
	# -------------------------------------------------------------
	# Fotocopiadora Oeste (X: -55 a -16, Z: 35 a 45)
	_pew(pb, r, "FotoO_Norte", 35.0, -55.0, -16.0, y, H, -35.0, mw)
	_pns(pb, r, "FotoO_Oeste", -55.0, 35.0, 45.0, y, H, INF_V, mw)
	_pns(pb, r, "FotoO_Este", -16.0, 35.0, 45.0, y, H, INF_V, mw) # Pared que linda con la entrada del auditorio
	_caja(pb, r, "FotoO_Mostrador", Vector3(-35.0, y + 0.55, 38.0), Vector3(6.0, 1.1, 1.5), ma)
	_lbl(pb, r, "CartelFotoO", "FOTOCOPIADORA 1", Vector3(-35.0, y + 3.2, 34.7), Vector3(0, 0, 0))

	# Fotocopiadora Este (X: 16 a 55, Z: 35 a 45)
	_pew(pb, r, "FotoE_Norte", 35.0, 16.0, 55.0, y, H, 35.0, mw)
	_pns(pb, r, "FotoE_Oeste", 16.0, 35.0, 45.0, y, H, INF_V, mw) # Pared que linda con la entrada del auditorio
	_pns(pb, r, "FotoE_Este", 55.0, 35.0, 45.0, y, H, INF_V, mw)
	_caja(pb, r, "FotoE_Mostrador", Vector3(35.0, y + 0.55, 38.0), Vector3(6.0, 1.1, 1.5), ma)
	_lbl(pb, r, "CartelFotoE", "FOTOCOPIADORA 2", Vector3(35.0, y + 3.2, 34.7), Vector3(0, 0, 0))

	# -------------------------------------------------------------
	# 7. ENTRADA AL AUDITORIO (LA LÍNEA CELESTE DEL PLANO)
	# Justo en Z = 35.0, entre X = -16 y X = +16 (entre las dos fotocopiadoras)
	# -------------------------------------------------------------
	_entrada_auditorio_celeste(pb, r, y)

# =====================================================================
# ENTRADA DE VIDRIO AL AUDITORIO (LÍNEA CELESTE)
# =====================================================================
func _entrada_auditorio_celeste(p: Node, r: Node, y: float):
	var z = 35.0 # Justo en el pasillo sur, entre las fotocopiadoras
	# Paños de vidrio laterales fijos con marco de aluminio
	_caja(p, r, "VidrioAud_L", Vector3(-9.5, y + H/2.0, z), Vector3(13.0, H, 0.08), mg)
	_caja(p, r, "VidrioAud_R", Vector3(9.5, y + H/2.0, z), Vector3(13.0, H, 0.08), mg)

	# Puertas centrales de vidrio (vano abierto en el centro para pasar)
	# Dintel superior sobre las puertas
	_caja(p, r, "MarcoSupAud", Vector3(0.0, y + H - 0.4, z), Vector3(6.2, 0.8, 0.15), mw)
	# Marcos verticales de las puertas
	_caja(p, r, "MarcoAud_ColL", Vector3(-3.0, y + H/2.0, z), Vector3(0.15, H, 0.15), mw)
	_caja(p, r, "MarcoAud_ColR", Vector3(3.0, y + H/2.0, z), Vector3(0.15, H, 0.15), mw)
	_caja(p, r, "MarcoAud_ColExtL", Vector3(-16.0, y + H/2.0, z), Vector3(0.2, H, 0.2), mw)
	_caja(p, r, "MarcoAud_ColExtR", Vector3(16.0, y + H/2.0, z), Vector3(0.2, H, 0.2), mw)

	# Logo oficial UTN FRC en el ventanal como en la foto real
	_lbl(p, r, "LogoUTN_FRC", "UTN\nFRC", Vector3(-7.0, y + 2.2, z - 0.1), Vector3(0, 0, 0))
	_lbl(p, r, "CartelAudEntrada", "AUDITORIO CENTRAL", Vector3(0.0, y + 3.6, z - 0.1), Vector3(0, 0, 0))

# =====================================================================
# AUDITORIO COMPLETO (SALA PRINCIPAL)
# =====================================================================
func _auditorio_completo(r: Node):
	var au = Node3D.new()
	au.name = "AuditorioPrincipal"; r.add_child(au); au.owner = r
	var y = 0.0

	# Suelo del auditorio (Z: 35 a 85, X: -20 a 20) - Elevado 4cm para evitar z-fighting con el piso gris
	_caja(au, r, "AudSuelo", Vector3(0, y - 0.06, 60.0), Vector3(40.2, 0.22, 50.2), ma)
	# Techo alto a 10m
	_caja(au, r, "AudTechoAlto", Vector3(0, y + HA + 0.1, 60.0), Vector3(40, 0.2, 50), mc)

	# Paredes de la sala
	# Paredes de embocadura (desde la entrada X: +-16 hasta el ancho de sala +-20)
	_caja(au, r, "AudFoyerO", Vector3(-18.0, y + HA/2.0, 37.5), Vector3(4.0, HA, G), mw)
	_caja(au, r, "AudFoyerE", Vector3(18.0, y + HA/2.0, 37.5), Vector3(4.0, HA, G), mw)

	# Paredes laterales
	_caja(au, r, "AudParedOeste", Vector3(-20.0, y + HA/2.0, 62.5), Vector3(G, HA, 45), mw)
	_caja(au, r, "AudParedEste", Vector3(20.0, y + HA/2.0, 62.5), Vector3(G, HA, 45), mw)
	# Pared de fondo
	_caja(au, r, "AudParedFondo", Vector3(0.0, y + HA/2.0, 85.0), Vector3(40, HA, G), mw)

	# Escenario elevado al fondo (Z: 73 a 83, X: -14 a 14)
	_caja(au, r, "Escenario", Vector3(0, y + 0.5, 78.0), Vector3(26.0, 1.0, 10.0), mco)
	# Atril / podio en el escenario
	_caja(au, r, "PodioEscenario", Vector3(0, y + 1.4, 74.5), Vector3(1.2, 0.9, 0.8), mw)
	# Escalones para subir al escenario (a los costados)
	_caja(au, r, "EscalonEscenarioL", Vector3(-13.8, y + 0.25, 74.0), Vector3(1.6, 0.5, 2.0), mco)
	_caja(au, r, "EscalonEscenarioR", Vector3(13.8, y + 0.25, 74.0), Vector3(1.6, 0.5, 2.0), mco)

	# Butacas individuales en filas orientadas hacia el escenario (foto real)
	# Pasillo central de 3m para circular (X: -1.5 a 1.5)
	for fila in range(8):
		var fz = 44.0 + fila * 3.4
		# Bloque izquierdo de butacas
		for col in range(8):
			var bx = -13.5 + col * 1.45
			var sfx_l = "ButacaL_%d_%d" % [fila, col]
			# Asiento rojo
			_caja(au, r, sfx_l + "_Asiento", Vector3(bx, y + 0.42, fz), Vector3(0.65, 0.12, 0.55), ma)
			# Respaldo rojo
			_caja(au, r, sfx_l + "_Respaldo", Vector3(bx, y + 0.72, fz - 0.23), Vector3(0.65, 0.50, 0.10), ma)
			# Apoyabrazos de madera
			_caja(au, r, sfx_l + "_Apoyabrazos", Vector3(bx + 0.35, y + 0.52, fz), Vector3(0.08, 0.32, 0.45), mco)

		# Bloque derecho de butacas
		for col in range(8):
			var bx = 2.2 + col * 1.45
			var sfx_r = "ButacaR_%d_%d" % [fila, col]
			# Asiento rojo
			_caja(au, r, sfx_r + "_Asiento", Vector3(bx, y + 0.42, fz), Vector3(0.65, 0.12, 0.55), ma)
			# Respaldo rojo
			_caja(au, r, sfx_r + "_Respaldo", Vector3(bx, y + 0.72, fz - 0.23), Vector3(0.65, 0.50, 0.10), ma)
			# Apoyabrazos de madera
			_caja(au, r, sfx_r + "_Apoyabrazos", Vector3(bx - 0.35, y + 0.52, fz), Vector3(0.08, 0.32, 0.45), mco)

	# Balcón técnico en lo alto de la pared trasera
	_caja(au, r, "BalconTecnico", Vector3(0, y + 7.5, 83.0), Vector3(8.0, 2.5, 3.0), mw)

# =====================================================================
# PATIO DEL ESTUDIANTE (A cielo abierto con canteros y galerías)
# =====================================================================
func _patio_elementos(r: Node):
	var pt = Node3D.new()
	pt.name = "PatioEstudiante"; r.add_child(pt); pt.owner = r

	# Balcones / Galerías con baranda en pisos 1 y 2
	for p_i in [1, 2]:
		var ly = p_i * H
		_caja(pt, r, "GaleriaOeste_%d" % p_i, Vector3(-18.5, ly, 0.5), Vector3(3.0, 0.2, 49.0), mc)
		_caja(pt, r, "GaleriaEste_%d" % p_i, Vector3(18.5, ly, 0.5), Vector3(3.0, 0.2, 49.0), mc)
		_caja(pt, r, "GaleriaNorte_%d" % p_i, Vector3(0.0, ly, -22.5), Vector3(34.0, 0.2, 3.0), mc)
		_caja(pt, r, "GaleriaSur_%d" % p_i, Vector3(0.0, ly, 23.5), Vector3(34.0, 0.2, 3.0), mc)

		# Barandas de protección
		_caja(pt, r, "BarandaO_%d" % p_i, Vector3(-17.1, ly + 0.5, 0.5), Vector3(0.1, 1.0, 49.0), mw)
		_caja(pt, r, "BarandaE_%d" % p_i, Vector3(17.1, ly + 0.5, 0.5), Vector3(0.1, 1.0, 49.0), mw)
		_caja(pt, r, "BarandaN_%d" % p_i, Vector3(0.0, ly + 0.5, -21.1), Vector3(34.0, 1.0, 0.1), mw)
		_caja(pt, r, "BarandaS_%d" % p_i, Vector3(0.0, ly + 0.5, 22.1), Vector3(34.0, 1.0, 0.1), mw)

	# Columnas verticales que suben los 3 pisos
	for lado_x in [-17.0, 17.0]:
		for cz in range(-20, 21, 8):
			_caja(pt, r, "ColPatio_%d_%d" % [int(lado_x), cz], Vector3(lado_x, H * 1.5, float(cz)), Vector3(0.6, H * 3.0, 0.6), mw)

	# Canteros elevados de material verde en PB
	_caja(pt, r, "CanteroGrande", Vector3(-5.0, 0.35, -2.0), Vector3(10.0, 0.7, 14.0), mpa)
	_caja(pt, r, "CanteroChico", Vector3(6.0, 0.35, 7.0), Vector3(7.0, 0.7, 10.0), mpa)

	# Senderos peatonales de baldosas
	_caja(pt, r, "SenderoLongitudinal", Vector3(1.5, 0.01, 0.5), Vector3(3.5, 0.02, 47.0), mp)
	_caja(pt, r, "SenderoTransversal", Vector3(0.0, 0.01, 5.0), Vector3(32.0, 0.02, 3.5), mp)

	# Cartel de entrada al patio
	_lbl(pt, r, "CartelPatioEntrada", "PATIO DEL ESTUDIANTE", Vector3(0.0, 3.5, 24.6), Vector3(0, 0, 0))

# =====================================================================
# PRIMER PISO (OFICINAS Y TRÁMITES - MISMA DISPOSICIÓN DE PASILLOS)
# =====================================================================
func _primer_piso(p: Node, r: Node, y: float):
	var of = Node3D.new()
	of.name = "OficinasP1"; p.add_child(of); of.owner = r

	# Bloque Norte: Bedelía, Dirección, Secretaría
	_pew(of, r, "P1_Bedelia_Sur", -33.0, -65.0, -15.0, y, H, -40.0, mw)
	_pew(of, r, "P1_Direccion_Sur", -33.0, -15.0, 37.0, y, H, 10.0, mw)
	_pns(of, r, "P1_Div_Bed_Dir", -15.0, -45.0, -33.0, y, H, INF_V, mw)
	_pns(of, r, "P1_ParedEsteDir", 37.0, -45.0, -33.0, y, H, INF_V, mw)

	_lbl(of, r, "CartelBedelia", "BEDELÍA GENERAL", Vector3(-40.0, y + 3.2, -32.7), Vector3(0, 180, 0))
	_lbl(of, r, "CartelDireccion", "DIRECCIÓN DEPARTAMENTAL", Vector3(10.0, y + 3.2, -32.7), Vector3(0, 180, 0))

	# Bloque Oeste: Departamentos de ingeniería
	_pns(of, r, "P1_Sistemas_Este", -47.0, -33.0, -5.0, y, H, -19.0, mw)
	_pns(of, r, "P1_Electronica_Este", -47.0, -5.0, 25.0, y, H, 10.0, mw)
	_pew(of, r, "P1_Div_Sist_Elec", -5.0, -65.0, -47.0, y, H, INF_V, mw)
	_pew(of, r, "P1_Sur_Elec", 25.0, -65.0, -47.0, y, H, INF_V, mw)

	_lbl(of, r, "CartelSistemas", "DEPTO. ING. EN SISTEMAS", Vector3(-46.7, y + 3.2, -19.0), Vector3(0, 90, 0))
	_lbl(of, r, "CartelDeptoElec", "DEPTO. ING. ELECTRÓNICA", Vector3(-46.7, y + 3.2, 10.0), Vector3(0, 90, 0))

	# Bloque Este: CETRA, Biblioteca
	_pns(of, r, "P1_CETRA_Oeste", 47.0, -45.0, -10.0, y, H, -27.5, mw)
	_pns(of, r, "P1_Biblio_Oeste", 47.0, -10.0, 25.0, y, H, 7.5, mw)
	_pew(of, r, "P1_Div_CETRA_Bib", -10.0, 47.0, 65.0, y, H, INF_V, mw)
	_pew(of, r, "P1_Sur_Bib", 25.0, 47.0, 65.0, y, H, INF_V, mw)

	_lbl(of, r, "CartelCETRA", "CETRA (TRÁMITES)", Vector3(46.7, y + 3.2, -27.5), Vector3(0, -90, 0))
	_lbl(of, r, "CartelBiblio", "BIBLIOTECA CENTRAL", Vector3(46.7, y + 3.2, 7.5), Vector3(0, -90, 0))

# =====================================================================
# SEGUNDO PISO (CLONADO DE PB - SOLO AULAS + CAFETERÍA EN ALA SUR)
# =====================================================================
func _segundo_piso(p: Node, r: Node, y: float):
	var sp = Node3D.new()
	sp.name = "Piso2_AulasYCafeteria"; p.add_child(sp); sp.owner = r

	# -------------------------------------------------------------
	# 1. BLOQUE AULAS NORTE (Aulas 201 a 204)
	# -------------------------------------------------------------
	_pew(sp, r, "P2_AulaN1_Sur", -33.0, -65.0, -40.0, y, H, -52.5, mw)
	_pew(sp, r, "P2_AulaN2_Sur", -33.0, -40.0, -15.0, y, H, -27.5, mw)
	_pew(sp, r, "P2_AulaN3_Sur", -33.0, -15.0, 10.0, y, H, -2.5, mw)
	_pew(sp, r, "P2_AulaN4_Sur", -33.0, 10.0, 37.0, y, H, 23.5, mw)

	_pns(sp, r, "P2_DivN_1_2", -40.0, -45.0, -33.0, y, H, INF_V, mw)
	_pns(sp, r, "P2_DivN_2_3", -15.0, -45.0, -33.0, y, H, INF_V, mw)
	_pns(sp, r, "P2_DivN_3_4", 10.0, -45.0, -33.0, y, H, INF_V, mw)
	_pns(sp, r, "P2_ParedEsteAulasN", 37.0, -45.0, -33.0, y, H, INF_V, mw)

	_pizarron(sp, r, "P2_PizN1", -52.5, -44.6, y, true)
	_pizarron(sp, r, "P2_PizN2", -27.5, -44.6, y, true)
	_pizarron(sp, r, "P2_PizN3", -2.5, -44.6, y, true)
	_pizarron(sp, r, "P2_PizN4", 23.5, -44.6, y, true)

	_pupitres(sp, r, "P2_PupN1", -63.0, -43.0, -42.0, -35.0, y)
	_pupitres(sp, r, "P2_PupN2", -38.0, -43.0, -17.0, -35.0, y)
	_pupitres(sp, r, "P2_PupN3", -13.0, -43.0, 8.0, -35.0, y)
	_pupitres(sp, r, "P2_PupN4", 12.0, -43.0, 35.0, -35.0, y)

	_lbl(sp, r, "P2_CartelN1", "AULA 201", Vector3(-52.5, y + 3.2, -32.7), Vector3(0, 180, 0))
	_lbl(sp, r, "P2_CartelN2", "AULA 202", Vector3(-27.5, y + 3.2, -32.7), Vector3(0, 180, 0))
	_lbl(sp, r, "P2_CartelN3", "AULA 203", Vector3(-2.5, y + 3.2, -32.7), Vector3(0, 180, 0))
	_lbl(sp, r, "P2_CartelN4", "AULA 204", Vector3(23.5, y + 3.2, -32.7), Vector3(0, 180, 0))

	# -------------------------------------------------------------
	# 2. BLOQUE AULAS OESTE EXTERIORES (Aulas 205 a 208)
	# -------------------------------------------------------------
	_pns(sp, r, "P2_AulaW1_Este", -47.0, -33.0, -19.0, y, H, -26.0, mw)
	_pns(sp, r, "P2_AulaW2_Este", -47.0, -19.0, -5.0, y, H, -12.0, mw)
	_pns(sp, r, "P2_AulaW3_Este", -47.0, -5.0, 10.0, y, H, 2.5, mw)
	_pns(sp, r, "P2_AulaW4_Este", -47.0, 10.0, 25.0, y, H, 17.5, mw)

	_pew(sp, r, "P2_DivW_1_2", -19.0, -65.0, -47.0, y, H, INF_V, mw)
	_pew(sp, r, "P2_DivW_2_3", -5.0, -65.0, -47.0, y, H, INF_V, mw)
	_pew(sp, r, "P2_DivW_3_4", 10.0, -65.0, -47.0, y, H, INF_V, mw)
	_pew(sp, r, "P2_AulaW4_Sur", 25.0, -65.0, -47.0, y, H, INF_V, mw)

	_pizarron(sp, r, "P2_PizW1", -64.6, -26.0, y, false)
	_pizarron(sp, r, "P2_PizW2", -64.6, -12.0, y, false)
	_pizarron(sp, r, "P2_PizW3", -64.6, 2.5, y, false)
	_pizarron(sp, r, "P2_PizW4", -64.6, 17.5, y, false)

	_pupitres(sp, r, "P2_PupW1", -63.0, -31.0, -49.0, -21.0, y)
	_pupitres(sp, r, "P2_PupW2", -63.0, -17.0, -49.0, -7.0, y)
	_pupitres(sp, r, "P2_PupW3", -63.0, -3.0, -49.0, 8.0, y)
	_pupitres(sp, r, "P2_PupW4", -63.0, 12.0, -49.0, 23.0, y)

	_lbl(sp, r, "P2_CartelW1", "AULA 205", Vector3(-46.7, y + 3.2, -26.0), Vector3(0, 90, 0))
	_lbl(sp, r, "P2_CartelW2", "AULA 206", Vector3(-46.7, y + 3.2, -12.0), Vector3(0, 90, 0))
	_lbl(sp, r, "P2_CartelW3", "AULA 207", Vector3(-46.7, y + 3.2, 2.5), Vector3(0, 90, 0))
	_lbl(sp, r, "P2_CartelW4", "AULA 208", Vector3(-46.7, y + 3.2, 17.5), Vector3(0, 90, 0))

	# -------------------------------------------------------------
	# 3. BLOQUE OESTE INTERIOR (Aulas 209, 210, 211)
	# -------------------------------------------------------------
	_pew(sp, r, "P2_BloqueWI_Norte", -24.0, -37.0, -17.0, y, H, INF_V, mw)
	_pew(sp, r, "P2_BloqueWI_Sur", 25.0, -37.0, -17.0, y, H, INF_V, mw)
	_pns(sp, r, "P2_BloqueWI_Patio", -17.0, -24.0, 25.0, y, H, INF_V, mw)

	_pns(sp, r, "P2_AulaWI1_Oeste", -37.0, -24.0, -10.0, y, H, -17.0, mw)
	_pew(sp, r, "P2_DivWI_1_2", -10.0, -37.0, -17.0, y, H, INF_V, mw)
	_pupitres(sp, r, "P2_PupWI1", -35.0, -22.0, -19.0, -12.0, y)
	_lbl(sp, r, "P2_CartelWI1", "AULA 209", Vector3(-37.3, y + 3.2, -17.0), Vector3(0, -90, 0))

	# Aula 210 (En PB era el Lab, aquí es Aula Magna 210)
	_pns(sp, r, "P2_Aula210_Oeste", -37.0, -10.0, 11.0, y, H, 0.5, mw)
	_pew(sp, r, "P2_DivWI_2_3", 11.0, -37.0, -17.0, y, H, INF_V, mw)
	_pizarron(sp, r, "P2_Piz210", -17.4, 0.5, y, false)
	_pupitres(sp, r, "P2_Pup210", -35.0, -8.0, -19.0, 9.0, y)
	_lbl(sp, r, "P2_Cartel210", "AULA 210 (MAGNA)", Vector3(-37.3, y + 3.2, 0.5), Vector3(0, -90, 0))

	# Aula 211
	_pns(sp, r, "P2_AulaWI2_Oeste", -37.0, 11.0, 25.0, y, H, 18.0, mw)
	_pupitres(sp, r, "P2_PupWI2", -35.0, 13.0, -19.0, 23.0, y)
	_lbl(sp, r, "P2_CartelWI2", "AULA 211", Vector3(-37.3, y + 3.2, 18.0), Vector3(0, -90, 0))

	# -------------------------------------------------------------
	# 4. BLOQUE ESTE INTERIOR (Aulas 212, 213, 214)
	# -------------------------------------------------------------
	_pew(sp, r, "P2_BloqueEI_Norte", -24.0, 17.0, 37.0, y, H, INF_V, mw)
	_pew(sp, r, "P2_BloqueEI_Sur", 25.0, 17.0, 37.0, y, H, INF_V, mw)
	_pns(sp, r, "P2_BloqueEI_Patio", 17.0, -24.0, 25.0, y, H, INF_V, mw)

	_pns(sp, r, "P2_AulaEI1_Este", 37.0, -24.0, -8.0, y, H, -16.0, mw)
	_pew(sp, r, "P2_DivEI_1_2", -8.0, 17.0, 37.0, y, H, INF_V, mw)
	_pupitres(sp, r, "P2_PupEI1", 19.0, -22.0, 35.0, -10.0, y)
	_lbl(sp, r, "P2_CartelEI1", "AULA 212", Vector3(37.3, y + 3.2, -16.0), Vector3(0, 90, 0))

	_pns(sp, r, "P2_AulaEI2_Este", 37.0, -8.0, 8.0, y, H, 0.0, mw)
	_pew(sp, r, "P2_DivEI_2_3", 8.0, 17.0, 37.0, y, H, INF_V, mw)
	_pupitres(sp, r, "P2_PupEI2", 19.0, -6.0, 35.0, 6.0, y)
	_lbl(sp, r, "P2_CartelEI2", "AULA 213", Vector3(37.3, y + 3.2, 0.0), Vector3(0, 90, 0))

	_pns(sp, r, "P2_AulaEI3_Este", 37.0, 8.0, 25.0, y, H, 16.5, mw)
	_pupitres(sp, r, "P2_PupEI3", 19.0, 10.0, 35.0, 23.0, y)
	_lbl(sp, r, "P2_CartelEI3", "AULA 214", Vector3(37.3, y + 3.2, 16.5), Vector3(0, 90, 0))

	# -------------------------------------------------------------
	# 5. BLOQUE ESTE EXTERIOR (Aulas 215, 216, 217 - SIN CAFETERÍA)
	# -------------------------------------------------------------
	_pns(sp, r, "P2_AulaE1_Oeste", 47.0, -45.0, -15.0, y, H, -30.0, mw)
	_pew(sp, r, "P2_DivE_1_2", -15.0, 47.0, 65.0, y, H, INF_V, mw)
	_pizarron(sp, r, "P2_PizE1", 64.6, -30.0, y, false)
	_pupitres(sp, r, "P2_PupE1", 49.0, -43.0, 63.0, -17.0, y)
	_lbl(sp, r, "P2_CartelE1", "AULA 215", Vector3(46.7, y + 3.2, -30.0), Vector3(0, -90, 0))

	# Aula 216 (donde en PB estaba la cafetería, ahora es un aula grande!)
	_pns(sp, r, "P2_AulaE2_Oeste", 47.0, -15.0, 10.0, y, H, -2.5, mw)
	_pew(sp, r, "P2_DivE_2_3", 10.0, 47.0, 65.0, y, H, INF_V, mw)
	_pizarron(sp, r, "P2_PizE2", 64.6, -2.5, y, false)
	_pupitres(sp, r, "P2_PupE2", 49.0, -13.0, 63.0, 8.0, y)
	_lbl(sp, r, "P2_CartelE2", "AULA 216", Vector3(46.7, y + 3.2, -2.5), Vector3(0, -90, 0))

	# Aula 217
	_pns(sp, r, "P2_AulaE3_Oeste", 47.0, 10.0, 25.0, y, H, 17.5, mw)
	_pew(sp, r, "P2_AulaE3_Sur", 25.0, 47.0, 65.0, y, H, INF_V, mw)
	_pizarron(sp, r, "P2_PizE3", 64.6, 17.5, y, false)
	_pupitres(sp, r, "P2_PupE3", 49.0, 12.0, 63.0, 23.0, y)
	_lbl(sp, r, "P2_CartelE3", "AULA 217", Vector3(46.7, y + 3.2, 17.5), Vector3(0, -90, 0))

	# -------------------------------------------------------------
	# 6. HABITACIONES SUR (Aulas de estudio 218 y 219)
	# -------------------------------------------------------------
	_pew(sp, r, "P2_SalasO_Norte", 35.0, -55.0, -16.0, y, H, -35.0, mw)
	_pns(sp, r, "P2_SalasO_Oeste", -55.0, 35.0, 45.0, y, H, INF_V, mw)
	_pns(sp, r, "P2_SalasO_Este", -16.0, 35.0, 45.0, y, H, INF_V, mw)
	_pupitres(sp, r, "P2_PupSO", -53.0, 37.0, -18.0, 43.0, y)
	_lbl(sp, r, "P2_CartelSO", "AULA 218", Vector3(-35.0, y + 3.2, 34.7), Vector3(0, 0, 0))

	_pew(sp, r, "P2_SalasE_Norte", 35.0, 16.0, 55.0, y, H, 35.0, mw)
	_pns(sp, r, "P2_SalasE_Oeste", 16.0, 35.0, 45.0, y, H, INF_V, mw)
	_pns(sp, r, "P2_SalasE_Este", 55.0, 35.0, 45.0, y, H, INF_V, mw)
	_pupitres(sp, r, "P2_PupSE", 18.0, 37.0, 53.0, 43.0, y)
	_lbl(sp, r, "P2_CartelSE", "AULA 219", Vector3(35.0, y + 3.2, 34.7), Vector3(0, 0, 0))

	# -------------------------------------------------------------
	# 7. CAFETERÍA DEL 2DO PISO (EN EL ALA SUR, DONDE ESTÁ EL AUDITORIO EN PB)
	# Basada exactamente en las 3 fotos del usuario
	# -------------------------------------------------------------
	_cafeteria_segundo_piso(sp, r, y)

# =====================================================================
# CAFETERÍA DEL 2DO PISO (ESCULTURA UTN AZUL, BANCOS, MESAS Y BUFÉ)
# =====================================================================
func _cafeteria_segundo_piso(p: Node, r: Node, y: float):
	var cf = Node3D.new()
	cf.name = "CafeteriaP2"; p.add_child(cf); cf.owner = r

	# Paredes perimetrales de la cafetería del 2do piso
	# Entrada vidriada en Z = 35.0
	_caja(cf, r, "CafeVidrioL", Vector3(-9.5, y + H/2.0, 35.0), Vector3(13.0, H, 0.08), mg)
	_caja(cf, r, "CafeVidrioR", Vector3(9.5, y + H/2.0, 35.0), Vector3(13.0, H, 0.08), mg)
	_caja(cf, r, "CafeDintel", Vector3(0.0, y + H - 0.4, 35.0), Vector3(6.2, 0.8, 0.15), mw)
	_lbl(cf, r, "CartelEntradaCafe", "CAFETERÍA Y COMEDOR\nPISO 2", Vector3(0.0, y + 3.5, 34.8), Vector3(0, 0, 0))

	# Paredes laterales con grandes ventanales (como en las fotos)
	_caja(cf, r, "CafeParedO", Vector3(-20.0, y + H/2.0, 60.0), Vector3(G, H, 50.0), mw)
	_caja(cf, r, "CafeVentanalO", Vector3(-19.9, y + 2.2, 60.0), Vector3(0.08, 2.4, 42.0), mg)

	_caja(cf, r, "CafeParedE", Vector3(20.0, y + H/2.0, 60.0), Vector3(G, H, 50.0), mw)
	_caja(cf, r, "CafeVentanalE", Vector3(19.9, y + 2.2, 60.0), Vector3(0.08, 2.4, 42.0), mg)

	# Pared de fondo (Sur Z = 85.0)
	_caja(cf, r, "CafeParedFondo", Vector3(0.0, y + H/2.0, 85.0), Vector3(40.0, H, G), mw)
	_caja(cf, r, "CafeVentanalS", Vector3(0.0, y + 2.2, 84.9), Vector3(32.0, 2.4, 0.08), mg)

	# -------------------------------------------------------------
	# MONUMENTO CENTRAL: ESCULTURA UTN AZUL (FOTO REAL)
	# -------------------------------------------------------------
	var mon_z = 58.0
	# Base de madera/metal
	_caja(cf, r, "MonPedestal", Vector3(0.0, y + 0.25, mon_z), Vector3(3.2, 0.5, 1.2), mco)
	# Pilar central azul
	_caja(cf, r, "MonPilarCentral", Vector3(0.0, y + 1.8, mon_z), Vector3(0.65, 2.6, 0.35), mu)
	# Brazos curvos estilizados del logo UTN
	var brazo_l = _caja(cf, r, "MonBrazoL", Vector3(-1.45, y + 2.2, mon_z), Vector3(2.3, 1.8, 0.35), mu)
	brazo_l.rotation_degrees = Vector3(0, 0, 25.0)
	var brazo_r = _caja(cf, r, "MonBrazoR", Vector3(1.45, y + 2.2, mon_z), Vector3(2.3, 1.8, 0.35), mu)
	brazo_r.rotation_degrees = Vector3(0, 0, -25.0)
	# Anillo/engranaje central y siglas oficiales
	_lbl(cf, r, "CartelMonumento", "AETI\nUTN", Vector3(0.0, y + 1.85, mon_z + 0.22), Vector3(0, 0, 0))

	# -------------------------------------------------------------
	# BANCOS DE MADERA CON ESTRUCTURA NEGRA ALREDEDOR DEL MONUMENTO
	# -------------------------------------------------------------
	_caja(cf, r, "BancoNorte", Vector3(0.0, y + 0.25, mon_z - 5.5), Vector3(11.0, 0.45, 0.8), mco)
	_caja(cf, r, "BancoSur", Vector3(0.0, y + 0.25, mon_z + 5.5), Vector3(11.0, 0.45, 0.8), mco)
	_caja(cf, r, "BancoOeste", Vector3(-5.5, y + 0.25, mon_z), Vector3(0.8, 0.45, 10.0), mco)
	_caja(cf, r, "BancoEste", Vector3(5.5, y + 0.25, mon_z), Vector3(0.8, 0.45, 10.0), mco)

	# Macetero con planta/palmera en la esquina del cantero (foto real)
	_caja(cf, r, "MaceteroCafe", Vector3(5.8, y + 0.4, mon_z - 5.8), Vector3(1.2, 0.8, 1.2), mco)
	_caja(cf, r, "PlantaPalmera", Vector3(5.8, y + 1.8, mon_z - 5.8), Vector3(1.6, 2.0, 1.6), mpa)

	# -------------------------------------------------------------
	# MESAS DE COMEDOR CON SILLAS ROJAS Y NEGRAS (FOTOS REALES)
	# -------------------------------------------------------------
	# Bloque Oeste de mesas (4 filas x 2 columnas = 8 mesas)
	for i in range(4):
		for j in range(2):
			var tx = -15.5 + j * 5.5
			var tz = 42.0 + i * 8.5
			_mesa_cafeteria(cf, r, y, tx, tz)

	# Bloque Este de mesas (4 filas x 2 columnas = 8 mesas)
	for i in range(4):
		for j in range(2):
			var tx = 10.0 + j * 5.5
			var tz = 42.0 + i * 8.5
			_mesa_cafeteria(cf, r, y, tx, tz)

	# -------------------------------------------------------------
	# MOSTRADOR / BUFÉ DE COMIDA AL FONDO (Z = 81.0)
	# -------------------------------------------------------------
	_caja(cf, r, "CafeBufetBarra", Vector3(0.0, y + 0.55, 81.0), Vector3(26.0, 1.1, 2.2), mco)
	_caja(cf, r, "CafeBufetVidrio", Vector3(0.0, y + 1.3, 81.0), Vector3(24.0, 0.4, 0.08), mg)
	_lbl(cf, r, "CartelBufet", "BAR Y COMEDOR - RETIRO DE BANDEJAS", Vector3(0.0, y + 2.8, 80.8), Vector3(0, 0, 0))

	# -------------------------------------------------------------
	# LUCES CÁLIDAS Y BRILLANTES DE LA CAFETERÍA (FOTOS REALES)
	# -------------------------------------------------------------
	for lx in [-12.0, 0.0, 12.0]:
		for lz in [44.0, 58.0, 72.0]:
			var cl = OmniLight3D.new()
			cl.name = "LuzCafeP2_%d_%d" % [int(lx), int(lz)]
			cl.position = Vector3(lx, y + 3.8, lz)
			cl.light_color = Color(1.0, 0.98, 0.92)
			cl.light_energy = 0.85
			cl.omni_range = 16.0
			cl.shadow_enabled = true
			cf.add_child(cl); cl.owner = r

# Helper para generar una mesa cuadrada con sillas rojas y negras
func _mesa_cafeteria(p: Node, r: Node, y: float, tx: float, tz: float):
	# Mesa blanca/gris
	_caja(p, r, "Mesa_%.1f_%.1f" % [tx, tz], Vector3(tx, y + 0.38, tz), Vector3(2.0, 0.75, 2.0), mp)
	# 2 Sillas rojas (Norte y Sur)
	_caja(p, r, "SillaR1_%.1f_%.1f" % [tx, tz], Vector3(tx, y + 0.22, tz - 1.3), Vector3(0.5, 0.45, 0.45), mcr)
	_caja(p, r, "SillaR1_Resp_%.1f_%.1f" % [tx, tz], Vector3(tx, y + 0.65, tz - 1.5), Vector3(0.5, 0.45, 0.08), mcr)

	_caja(p, r, "SillaR2_%.1f_%.1f" % [tx, tz], Vector3(tx, y + 0.22, tz + 1.3), Vector3(0.5, 0.45, 0.45), mcr)
	_caja(p, r, "SillaR2_Resp_%.1f_%.1f" % [tx, tz], Vector3(tx, y + 0.65, tz + 1.5), Vector3(0.5, 0.45, 0.08), mcr)

	# 2 Sillas negras (Oeste y Este)
	_caja(p, r, "SillaN1_%.1f_%.1f" % [tx, tz], Vector3(tx - 1.3, y + 0.22, tz), Vector3(0.45, 0.45, 0.5), ms)
	_caja(p, r, "SillaN1_Resp_%.1f_%.1f" % [tx, tz], Vector3(tx - 1.5, y + 0.65, tz), Vector3(0.08, 0.45, 0.5), ms)

	_caja(p, r, "SillaN2_%.1f_%.1f" % [tx, tz], Vector3(tx + 1.3, y + 0.22, tz), Vector3(0.45, 0.45, 0.5), ms)
	_caja(p, r, "SillaN2_Resp_%.1f_%.1f" % [tx, tz], Vector3(tx + 1.5, y + 0.65, tz), Vector3(0.08, 0.45, 0.5), ms)

# =====================================================================
# TORRES DE ESCALERAS EN U (DE FRENTE Y POZO CONTINUO SIN TECHOS INTERMEDIOS)
# Escalones individuales + pasamanos metálicos
# =====================================================================
func _escaleras_torres(r: Node):
	var esc = Node3D.new()
	esc.name = "TorresEscaleras"; r.add_child(esc); esc.owner = r

	# Material metálico para pasamanos (gris oscuro metalizado)
	var m_metal = StandardMaterial3D.new()
	m_metal.albedo_color = Color(0.35, 0.35, 0.38)
	m_metal.metallic = 0.8
	m_metal.roughness = 0.3

	var torres = [
		["TorreOeste", -69.5, 30.0],
		["TorreEste", 69.5, 30.0],
		["TorreNorte", 42.0, -49.5]
	]

	var run_len = 6.5
	var rise = H / 2.0       # 2.25m por tramo
	var hyp = sqrt(run_len * run_len + rise * rise) # ~6.88m
	var ang = atan2(rise, run_len)
	var th = H * 3.0          # Altura total de la torre (3 pisos = 13.5m)

	# Parámetros de escalones individuales
	var n_steps = 13                          # Escalones por tramo
	var step_rise = rise / float(n_steps)     # ~0.173m altura por escalón
	var step_going = run_len / float(n_steps) # ~0.5m profundidad por escalón
	var step_h = 0.17                         # Grosor visible del escalón
	var stair_w = 3.8                         # Ancho del tramo

	# Parámetros de pasamanos
	var rail_h = 0.9       # Altura del pasamanos sobre el escalón
	var rail_diam = 0.05   # Diámetro del tubo
	var divider_wall_h = 0.5  # Altura del muro bajo en el lado divisorio

	for t in torres:
		var tn = Node3D.new()
		tn.name = t[0]; esc.add_child(tn); tn.owner = r
		var cx = t[1]; var cz = t[2]

		if t[0] != "TorreNorte":
			# =========================================================
			# Torres Laterales (Oeste / Este) - Escaleras en eje X
			# =========================================================
			var tw = 9.0; var td = 10.0
			var ext_x = cx + (tw/2.0 if cx > 0 else -tw/2.0)

			# Paredes exteriores del hueco de escalera (3 pisos de alto)
			_caja(tn, r, t[0]+"_ParedFondo", Vector3(ext_x, th/2.0, cz), Vector3(G, th, td), mw)
			_caja(tn, r, t[0]+"_ParedNorte", Vector3(cx, th/2.0, cz - td/2.0), Vector3(tw, th, G), mw)
			_caja(tn, r, t[0]+"_ParedSur", Vector3(cx, th/2.0, cz + td/2.0), Vector3(tw, th, G), mw)

			# Ventanal grande exterior en el descanso (como en la foto real)
			_caja(tn, r, t[0]+"_Ventanal", Vector3(ext_x, th/2.0, cz), Vector3(0.08, th - 2.0, 7.0), mg)

			# Muro divisorio central entre los dos tramos de la U
			_caja(tn, r, t[0]+"_Divisorio", Vector3(cx + (0.5 if cx < 0 else -0.5), th/2.0, cz), Vector3(run_len, th, 0.3), mw)

			# Suelo base abajo de todo (PB) y techo ÚNICAMENTE arriba de todo (13.5m)
			_caja(tn, r, t[0]+"_PisoBase", Vector3(cx, -0.1, cz), Vector3(tw, 0.2, td), mp)
			_caja(tn, r, t[0]+"_TechoFinal", Vector3(cx, th + 0.1, cz), Vector3(tw, 0.2, td), mc)

			# Tramos de escaleras para subir PB->P1 y P1->P2
			for p_i in range(2):
				var yb = p_i * H
				var ym = yb + rise
				var sfx = "%s_P%d" % [t[0], p_i]

				if cx < 0:
					# --- TORRE OESTE ---
					# Tramo 1 (Z=27.5): Sube hacia el Oeste (-X)
					# Desde X=-65.0, Y=yb hasta X=-71.5, Y=ym
					var t1_start_x = -65.0
					var t1_z = cz - 2.5

					# Escalones individuales Tramo 1
					for si in range(n_steps):
						var sx = t1_start_x - (si + 1) * step_going  # avanza en -X
						var sy = yb + (si + 1) * step_rise - step_h / 2.0
						_caja(tn, r, sfx+"_T1_S%d" % si,
							Vector3(sx + step_going/2.0, sy, t1_z),
							Vector3(step_going, step_h, stair_w), ms)

					# Larguero/zanca estructural bajo los escalones (Tramo 1)
					var str1 = CSGBox3D.new()
					str1.name = sfx + "_T1_Zanca"; str1.use_collision = true; str1.material = ms
					str1.size = Vector3(hyp, 0.3, stair_w)
					str1.position = Vector3(
						(t1_start_x + t1_start_x - run_len) / 2.0,
						yb + rise / 2.0 - 0.22,
						t1_z)
					str1.rotation.z = -ang
					tn.add_child(str1); str1.owner = r

					# Franja amarilla al inicio del tramo
					_caja(tn, r, sfx+"_Franja1", Vector3(-65.3, yb + 0.02, t1_z), Vector3(0.4, 0.04, stair_w), my)

					# Pasamanos Tramo 1
					_stair_handrails_x(tn, r, sfx+"_T1", t1_start_x, -1, t1_z, yb, n_steps, step_going, step_rise, stair_w, rail_h, rail_diam, divider_wall_h, hyp, ang, m_metal, true)

					# Descanso al fondo oeste (a mitad de piso Y = ym)
					_caja(tn, r, sfx+"_Descanso", Vector3(cx - 3.25, ym - 0.1, cz), Vector3(3.0, 0.2, 9.0), ms)

					# Tramo 2 (Z=32.5): Sube hacia el Este (+X)
					# Desde X=-71.5, Y=ym hasta X=-65.0, Y=yt
					var t2_start_x = -71.5
					var t2_z = cz + 2.5

					# Escalones individuales Tramo 2
					for si in range(n_steps):
						var sx = t2_start_x + (si + 1) * step_going  # avanza en +X
						var sy = ym + (si + 1) * step_rise - step_h / 2.0
						_caja(tn, r, sfx+"_T2_S%d" % si,
							Vector3(sx - step_going/2.0, sy, t2_z),
							Vector3(step_going, step_h, stair_w), ms)

					# Zanca Tramo 2
					var str2 = CSGBox3D.new()
					str2.name = sfx + "_T2_Zanca"; str2.use_collision = true; str2.material = ms
					str2.size = Vector3(hyp, 0.3, stair_w)
					str2.position = Vector3(
						(t2_start_x + t2_start_x + run_len) / 2.0,
						ym + rise / 2.0 - 0.22,
						t2_z)
					str2.rotation.z = ang
					tn.add_child(str2); str2.owner = r

					# Pasamanos Tramo 2
					_stair_handrails_x(tn, r, sfx+"_T2", t2_start_x, 1, t2_z, ym, n_steps, step_going, step_rise, stair_w, rail_h, rail_diam, divider_wall_h, hyp, ang, m_metal, false)

				else:
					# --- TORRE ESTE ---
					# Tramo 1 (Z=27.5): Sube hacia el Este (+X)
					var t1_start_x = 65.0
					var t1_z = cz - 2.5

					# Escalones individuales Tramo 1
					for si in range(n_steps):
						var sx = t1_start_x + (si + 1) * step_going  # avanza en +X
						var sy = yb + (si + 1) * step_rise - step_h / 2.0
						_caja(tn, r, sfx+"_T1_S%d" % si,
							Vector3(sx - step_going/2.0, sy, t1_z),
							Vector3(step_going, step_h, stair_w), ms)

					# Zanca Tramo 1
					var str1 = CSGBox3D.new()
					str1.name = sfx + "_T1_Zanca"; str1.use_collision = true; str1.material = ms
					str1.size = Vector3(hyp, 0.3, stair_w)
					str1.position = Vector3(
						(t1_start_x + t1_start_x + run_len) / 2.0,
						yb + rise / 2.0 - 0.22,
						t1_z)
					str1.rotation.z = ang
					tn.add_child(str1); str1.owner = r

					_caja(tn, r, sfx+"_Franja1", Vector3(65.3, yb + 0.02, t1_z), Vector3(0.4, 0.04, stair_w), my)

					# Pasamanos Tramo 1
					_stair_handrails_x(tn, r, sfx+"_T1", t1_start_x, 1, t1_z, yb, n_steps, step_going, step_rise, stair_w, rail_h, rail_diam, divider_wall_h, hyp, ang, m_metal, true)

					# Descanso al fondo este
					_caja(tn, r, sfx+"_Descanso", Vector3(cx + 3.25, ym - 0.1, cz), Vector3(3.0, 0.2, 9.0), ms)

					# Tramo 2 (Z=32.5): Sube hacia el Oeste (-X)
					var t2_start_x = 71.5
					var t2_z = cz + 2.5

					# Escalones individuales Tramo 2
					for si in range(n_steps):
						var sx = t2_start_x - (si + 1) * step_going  # avanza en -X
						var sy = ym + (si + 1) * step_rise - step_h / 2.0
						_caja(tn, r, sfx+"_T2_S%d" % si,
							Vector3(sx + step_going/2.0, sy, t2_z),
							Vector3(step_going, step_h, stair_w), ms)

					# Zanca Tramo 2
					var str2 = CSGBox3D.new()
					str2.name = sfx + "_T2_Zanca"; str2.use_collision = true; str2.material = ms
					str2.size = Vector3(hyp, 0.3, stair_w)
					str2.position = Vector3(
						(t2_start_x + t2_start_x - run_len) / 2.0,
						ym + rise / 2.0 - 0.22,
						t2_z)
					str2.rotation.z = -ang
					tn.add_child(str2); str2.owner = r

					# Pasamanos Tramo 2
					_stair_handrails_x(tn, r, sfx+"_T2", t2_start_x, -1, t2_z, ym, n_steps, step_going, step_rise, stair_w, rail_h, rail_diam, divider_wall_h, hyp, ang, m_metal, false)

		else:
			# =========================================================
			# TORRE NORTE - Escaleras en eje Z
			# =========================================================
			var tw = 10.0; var td = 9.0
			var ext_z = cz - td/2.0 # -54.0

			_caja(tn, r, t[0]+"_ParedFondo", Vector3(cx, th/2.0, ext_z), Vector3(tw, th, G), mw)
			_caja(tn, r, t[0]+"_ParedOeste", Vector3(cx - tw/2.0, th/2.0, cz), Vector3(G, th, td), mw)
			_caja(tn, r, t[0]+"_ParedEste", Vector3(cx + tw/2.0, th/2.0, cz), Vector3(G, th, td), mw)
			_caja(tn, r, t[0]+"_Ventanal", Vector3(cx, th/2.0, ext_z), Vector3(7.0, th - 2.0, 0.08), mg)

			_caja(tn, r, t[0]+"_Divisorio", Vector3(cx, th/2.0, cz + 0.5), Vector3(0.3, th, run_len), mw)

			_caja(tn, r, t[0]+"_PisoBase", Vector3(cx, -0.1, cz), Vector3(tw, 0.2, td), mp)
			_caja(tn, r, t[0]+"_TechoFinal", Vector3(cx, th + 0.1, cz), Vector3(tw, 0.2, td), mc)

			for p_i in range(2):
				var yb = p_i * H
				var ym = yb + rise
				var sfx = "%s_P%d" % [t[0], p_i]

				# Tramo 1 (X=39.5): Sube hacia el Norte (-Z)
				# Desde Z=-45.0, Y=yb hasta Z=-51.5, Y=ym
				var t1_start_z = -45.0
				var t1_x = cx - 2.5

				# Escalones individuales Tramo 1
				for si in range(n_steps):
					var sz = t1_start_z - (si + 1) * step_going  # avanza en -Z
					var sy = yb + (si + 1) * step_rise - step_h / 2.0
					_caja(tn, r, sfx+"_T1_S%d" % si,
						Vector3(t1_x, sy, sz + step_going/2.0),
						Vector3(stair_w, step_h, step_going), ms)

				# Zanca Tramo 1
				var str1 = CSGBox3D.new()
				str1.name = sfx + "_T1_Zanca"; str1.use_collision = true; str1.material = ms
				str1.size = Vector3(stair_w, 0.3, hyp)
				str1.position = Vector3(
					t1_x,
					yb + rise / 2.0 - 0.22,
					(t1_start_z + t1_start_z - run_len) / 2.0)
				str1.rotation.x = ang
				tn.add_child(str1); str1.owner = r

				_caja(tn, r, sfx+"_Franja1", Vector3(t1_x, yb + 0.02, -45.3), Vector3(stair_w, 0.04, 0.4), my)

				# Pasamanos Tramo 1
				_stair_handrails_z(tn, r, sfx+"_T1", t1_start_z, -1, t1_x, yb, n_steps, step_going, step_rise, stair_w, rail_h, rail_diam, divider_wall_h, hyp, ang, m_metal, true)

				# Descanso al fondo norte
				_caja(tn, r, sfx+"_Descanso", Vector3(cx, ym - 0.1, cz - 3.25), Vector3(9.0, 0.2, 3.0), ms)

				# Tramo 2 (X=44.5): Sube hacia el Sur (+Z)
				# Desde Z=-51.5, Y=ym hasta Z=-45.0, Y=yt
				var t2_start_z = -51.5
				var t2_x = cx + 2.5

				# Escalones individuales Tramo 2
				for si in range(n_steps):
					var sz = t2_start_z + (si + 1) * step_going  # avanza en +Z
					var sy = ym + (si + 1) * step_rise - step_h / 2.0
					_caja(tn, r, sfx+"_T2_S%d" % si,
						Vector3(t2_x, sy, sz - step_going/2.0),
						Vector3(stair_w, step_h, step_going), ms)

				# Zanca Tramo 2
				var str2 = CSGBox3D.new()
				str2.name = sfx + "_T2_Zanca"; str2.use_collision = true; str2.material = ms
				str2.size = Vector3(stair_w, 0.3, hyp)
				str2.position = Vector3(
					t2_x,
					ym + rise / 2.0 - 0.22,
					(t2_start_z + t2_start_z + run_len) / 2.0)
				str2.rotation.x = -ang
				tn.add_child(str2); str2.owner = r

				# Pasamanos Tramo 2
				_stair_handrails_z(tn, r, sfx+"_T2", t2_start_z, 1, t2_x, ym, n_steps, step_going, step_rise, stair_w, rail_h, rail_diam, divider_wall_h, hyp, ang, m_metal, false)

		# Luces en cada nivel de las escaleras
		for p_i in range(3):
			var l = OmniLight3D.new()
			l.name = "%s_Luz_%d" % [t[0], p_i]
			l.position = Vector3(cx, p_i * H + 3.2, cz)
			l.light_color = Color(0.9, 0.95, 1.0)
			l.light_energy = 0.8; l.omni_range = 10.0; l.shadow_enabled = true
			tn.add_child(l); l.owner = r

# Pasamanos para tramos en eje X (Torres Oeste/Este)
# start_x: coordenada X de inicio, dir_x: +1 o -1 (dirección de avance),
# z_center: coordenada Z del centro del tramo, y_base: Y del piso inferior,
# is_tramo1: true para tramo 1 (lado divisorio en +Z), false para tramo 2 (divisorio en -Z)
func _stair_handrails_x(p: Node, r: Node, prefix: String,
		start_x: float, dir_x: int, z_center: float, y_base: float,
		n_steps: int, step_going: float, step_rise: float, stair_w: float,
		rail_h: float, rail_diam: float, div_wall_h: float,
		hyp: float, ang: float, mat: Material, is_tramo1: bool):

	# Longitud del pasamanos (siguiendo la pendiente)
	var run_len = n_steps * step_going
	var rise = n_steps * step_rise
	var rail_len = sqrt(run_len * run_len + rise * rise)

	# Centro del tramo
	var mid_x = start_x + dir_x * run_len / 2.0
	var mid_y = y_base + rise / 2.0

	# Lado divisorio (entre los dos tramos) y lado exterior
	var z_div = z_center + (stair_w / 2.0 if is_tramo1 else -stair_w / 2.0)
	var z_out = z_center - (stair_w / 2.0 if is_tramo1 else -stair_w / 2.0)

	# --- Pasamanos inclinado lado divisorio (tubo superior) ---
	var rail_div = CSGBox3D.new()
	rail_div.name = prefix + "_RailDiv"; rail_div.use_collision = true; rail_div.material = mat
	rail_div.size = Vector3(rail_len, rail_diam, rail_diam)
	rail_div.position = Vector3(mid_x, mid_y + rail_h, z_div)
	rail_div.rotation.z = float(dir_x) * ang
	p.add_child(rail_div); rail_div.owner = r

	# Muro bajo inclinado en el lado divisorio
	var wall_div = CSGBox3D.new()
	wall_div.name = prefix + "_WallDiv"; wall_div.use_collision = true; wall_div.material = mat
	wall_div.size = Vector3(rail_len, div_wall_h, 0.1)
	wall_div.position = Vector3(mid_x, mid_y + div_wall_h / 2.0, z_div)
	wall_div.rotation.z = float(dir_x) * ang
	p.add_child(wall_div); wall_div.owner = r

	# --- Pasamanos inclinado lado exterior (tubo superior) ---
	var rail_out = CSGBox3D.new()
	rail_out.name = prefix + "_RailOut"; rail_out.use_collision = true; rail_out.material = mat
	rail_out.size = Vector3(rail_len, rail_diam, rail_diam)
	rail_out.position = Vector3(mid_x, mid_y + rail_h, z_out)
	rail_out.rotation.z = float(dir_x) * ang
	p.add_child(rail_out); rail_out.owner = r

	# Postes verticales al inicio y final del tramo (lado exterior)
	var post_x_start = start_x + dir_x * step_going / 2.0
	var post_y_start = y_base + step_rise
	var post_x_end = start_x + dir_x * run_len - dir_x * step_going / 2.0
	var post_y_end = y_base + rise

	_caja(p, r, prefix + "_PostOut0",
		Vector3(post_x_start, post_y_start + rail_h / 2.0, z_out),
		Vector3(rail_diam, rail_h, rail_diam), mat)
	_caja(p, r, prefix + "_PostOut1",
		Vector3(post_x_end, post_y_end + rail_h / 2.0, z_out),
		Vector3(rail_diam, rail_h, rail_diam), mat)

# Pasamanos para tramos en eje Z (Torre Norte)
# start_z: coordenada Z de inicio, dir_z: +1 o -1 (dirección de avance),
# x_center: coordenada X del centro del tramo, y_base: Y del piso inferior,
# is_tramo1: true para tramo 1 (lado divisorio en +Z), false para tramo 2 (divisorio en -Z)
func _stair_handrails_z(p: Node, r: Node, prefix: String,
		start_z: float, dir_z: int, x_center: float, y_base: float,
		n_steps: int, step_going: float, step_rise: float, stair_w: float,
		rail_h: float, rail_diam: float, div_wall_h: float,
		hyp: float, ang: float, mat: Material, is_tramo1: bool):

	var run_len = n_steps * step_going
	var rise = n_steps * step_rise
	var rail_len = sqrt(run_len * run_len + rise * rise)

	# Centro del tramo
	var mid_z = start_z + dir_z * run_len / 2.0
	var mid_y = y_base + rise / 2.0

	# Lado divisorio y lado exterior (en X para torre norte)
	# Tramo 1: X=39.5, divisorio está en +X (hacia cx). Tramo 2: X=44.5, divisorio está en -X
	var x_div = x_center + (stair_w / 2.0 if is_tramo1 else -stair_w / 2.0)
	var x_out = x_center - (stair_w / 2.0 if is_tramo1 else -stair_w / 2.0)

	# --- Pasamanos inclinado lado divisorio (tubo superior) ---
	var rail_div = CSGBox3D.new()
	rail_div.name = prefix + "_RailDiv"; rail_div.use_collision = true; rail_div.material = mat
	rail_div.size = Vector3(rail_diam, rail_diam, rail_len)
	rail_div.position = Vector3(x_div, mid_y + rail_h, mid_z)
	rail_div.rotation.x = float(-dir_z) * ang
	p.add_child(rail_div); rail_div.owner = r

	# Muro bajo inclinado en el lado divisorio
	var wall_div = CSGBox3D.new()
	wall_div.name = prefix + "_WallDiv"; wall_div.use_collision = true; wall_div.material = mat
	wall_div.size = Vector3(0.1, div_wall_h, rail_len)
	wall_div.position = Vector3(x_div, mid_y + div_wall_h / 2.0, mid_z)
	wall_div.rotation.x = float(-dir_z) * ang
	p.add_child(wall_div); wall_div.owner = r

	# --- Pasamanos inclinado lado exterior (tubo superior) ---
	var rail_out = CSGBox3D.new()
	rail_out.name = prefix + "_RailOut"; rail_out.use_collision = true; rail_out.material = mat
	rail_out.size = Vector3(rail_diam, rail_diam, rail_len)
	rail_out.position = Vector3(x_out, mid_y + rail_h, mid_z)
	rail_out.rotation.x = float(-dir_z) * ang
	p.add_child(rail_out); rail_out.owner = r

	# Postes verticales al inicio y final del tramo (lado exterior)
	var post_z_start = start_z + dir_z * step_going / 2.0
	var post_y_start = y_base + step_rise
	var post_z_end = start_z + dir_z * run_len - dir_z * step_going / 2.0
	var post_y_end = y_base + rise

	_caja(p, r, prefix + "_PostOut0",
		Vector3(x_out, post_y_start + rail_h / 2.0, post_z_start),
		Vector3(rail_diam, rail_h, rail_diam), mat)
	_caja(p, r, prefix + "_PostOut1",
		Vector3(x_out, post_y_end + rail_h / 2.0, post_z_end),
		Vector3(rail_diam, rail_h, rail_diam), mat)

# =====================================================================
# ILUMINACIÓN GENERAL EN LOS PASILLOS
# =====================================================================
func _luces_completas(r: Node):
	var lu = Node3D.new()
	lu.name = "Iluminacion"; r.add_child(lu); lu.owner = r

	for p_i in range(3):
		var y = p_i * H + 3.8

		# Pasillo Norte (Z = -28.5, corre de X = -45 a 45)
		for lx in [-35.0, -15.0, 5.0, 25.0, 42.0]:
			var l = OmniLight3D.new()
			l.name = "LuzN_%d_%d" % [p_i, int(lx)]
			l.position = Vector3(lx, y, -28.5)
			l.light_color = Color(0.85, 0.9, 1.0)
			l.light_energy = 0.7; l.omni_range = 14.0; l.shadow_enabled = true
			lu.add_child(l); l.owner = r

		# Pasillo Oeste (X = -42.0, corre de Z = -30 a 25)
		for lz in [-20.0, -5.0, 10.0]:
			var l = OmniLight3D.new()
			l.name = "LuzW_%d_%d" % [p_i, int(lz)]
			l.position = Vector3(-42.0, y, float(lz))
			l.light_color = Color(0.85, 0.9, 1.0)
			l.light_energy = 0.7; l.omni_range = 14.0; l.shadow_enabled = true
			lu.add_child(l); l.owner = r

		# Pasillo Este (X = 42.0, corre de Z = -40 a 25)
		for lz in [-35.0, -20.0, -5.0, 10.0]:
			var l = OmniLight3D.new()
			l.name = "LuzE_%d_%d" % [p_i, int(lz)]
			l.position = Vector3(42.0, y, float(lz))
			l.light_color = Color(0.85, 0.9, 1.0)
			l.light_energy = 0.7; l.omni_range = 14.0; l.shadow_enabled = true
			lu.add_child(l); l.owner = r

		# Pasillo Sur (Z = 30.0, corre de X = -60 a 60)
		for lx in [-55.0, -35.0, -15.0, 0.0, 15.0, 35.0, 55.0]:
			var l = OmniLight3D.new()
			l.name = "LuzS_%d_%d" % [p_i, int(lx)]
			l.position = Vector3(lx, y, 30.0)
			l.light_color = Color(0.85, 0.9, 1.0)
			l.light_energy = 0.7; l.omni_range = 14.0; l.shadow_enabled = true
			lu.add_child(l); l.owner = r

	# Luces cálidas en el auditorio
	for ax in [-8.0, 8.0]:
		for az in [50.0, 70.0]:
			var al = OmniLight3D.new()
			al.name = "LuzAud_%d_%d" % [int(ax), int(az)]
			al.position = Vector3(ax, 8.0, az)
			al.light_color = Color(1.0, 0.9, 0.7)
			al.light_energy = 0.9; al.omni_range = 20.0; al.shadow_enabled = true
			lu.add_child(al); al.owner = r

# =====================================================================
# ESCENA PRINCIPAL (main.tscn)
# =====================================================================
func _gen_main():
	var main = Node3D.new()
	main.name = "Main"

	var mic = Node.new()
	mic.name = "MicDetector"
	mic.set_script(load("res://scripts/mic_detector.gd"))
	main.add_child(mic); mic.owner = main

	var hud = load("res://scenes/hud.tscn").instantiate()
	main.add_child(hud); hud.owner = main

	var edif = load("res://scenes/edificio_central.tscn").instantiate()
	main.add_child(edif); edif.owner = main

	# Spawn en el pasillo sur mirando hacia el norte (hacia el patio)
	var pl = load("res://scenes/player.tscn").instantiate()
	pl.position = Vector3(0.0, 0.2, 30.0)
	pl.rotation_degrees = Vector3(0, 0, 0)
	main.add_child(pl); pl.owner = main

	# var scr = GDScript.new()
	# scr.source_code = "..."
	# ResourceSaver.save(scr, "res://scripts/main.gd")
	# main.set_script(scr)

	var env_n = WorldEnvironment.new()
	env_n.name = "WorldEnvironment"
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.01, 0.025)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.04, 0.04, 0.06)
	env.ambient_light_energy = 0.4
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.008
	env_n.environment = env
	main.add_child(env_n); env_n.owner = main

	var moon = DirectionalLight3D.new()
	moon.name = "MoonLight"
	moon.rotation_degrees = Vector3(-60, 25, 0)
	moon.light_color = Color(0.35, 0.45, 0.65)
	moon.light_energy = 0.35; moon.shadow_enabled = true
	main.add_child(moon); moon.owner = main

	var pk = PackedScene.new()
	pk.pack(main)
	ResourceSaver.save(pk, "res://scenes/main.tscn")
	print(">>> main.tscn GUARDADO!")
