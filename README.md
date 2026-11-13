# UTN FRC: Noche de Finales

Videojuego de terror y supervivencia en primera persona desarrollado en **Godot Engine 4** (Forward+), ambientado en una recreación a escala del Edificio Central de la **Universidad Tecnológica Nacional - Facultad Regional Córdoba (UTN FRC)**.

Proyecto realizado para la cátedra **Creatividad y Desarrollo en Entornos Virtuales (CDEV)**.

---

## Informacion Academica

* **Institucion:** Universidad Tecnologica Nacional - Facultad Regional Cordoba (UTN FRC)
* **Carrera:** Ingenieria en Sistemas de Informacion
* **Catedra:** Creatividad y Desarrollo en Entornos Virtuales (CDEV)
* **Curso:** 5K1
* **Grupo:** Nro. 7
* **Ano:** 2026

### Docentes
* Franco Mana
* Ines Luz Gimenez Zens
* Bruno Aresu Barella

### Integrantes
* Schurrer, Gabriel Nicolas - Legajo: 95046
* Maldonado, Franco Gabriel - Legajo: 92123
* Nobile, Bruno Nicolas - Legajo: 92098
* Imwinkelried, Ivan - Legajo: 97076
* Reineri, Valentina - Legajo: 95985
* Ramirez, Carlos David - Legajo: 401710
* Grosso, Gaspar - Legajo: 95123
* Mottura, Mateo - Legajo: 91154

---

## Descripcion del Proyecto

El juego propone una experiencia de terror y sigilo en primera persona. El jugador encarna a un estudiante rezagado que queda atrapado de noche dentro del edificio central de la facultad durante el turno de examenes finales.

Para lograr escapar del establecimiento y obtener el titulo universitario, el jugador debe recorrer las distintas areas del edificio, aprobar los parciales distribuidos en las aulas, restaurar el suministro electrico tras un corte de energia general y evadir al profesor que patrulla y persigue activamente por los pasillos.

La propuesta integra mecanicas diegeticas de inmersion, destacandose la deteccion de ruido en tiempo real a traves del microfono fisico del usuario al esconderse, obligando al jugador a mantener silencio real en su entorno para no ser descubierto.

---

## Como Ejecutar el Proyecto

### Requisitos
* **Godot Engine:** version 4.2 o superior (probado y optimizado en Godot 4.7 Standard x86_64).
* **Renderizador:** Forward+ o Mobile.
* **Microfono:** Conectado y habilitado en el sistema operativo (necesario para la mecanica de sigilo en tachos).

### Pasos
1. Clonar el repositorio:
   ```bash
   git clone https://github.com/francomaldo1/CDEV.git
   ```
2. Abrir **Godot Engine**.
3. Seleccionar **Importar**, navegar hasta la carpeta clonada y abrir el archivo `project.godot`.
4. Ejecutar el proyecto presionando `F5` o el boton de reproducir en la esquina superior derecha.
5. La escena principal inicial es `scenes/main_menu.tscn`.

---

## Mecanicas y Caracteristicas Tecnicas

### 1. Deteccion de Audio por Microfono (AudioEffectCapture)
* Implementado en `scripts/mic_detector.gd` mediante el bus de audio `Record`.
* La deteccion se activa unicamente cuando el jugador se encuentra oculto dentro de un tacho de basura (`tacho_basura.tscn`).
* El sistema mide en tiempo real los decibeles de entrada. Si el jugador hace ruido fisico en su habitacion (respiracion fuerte, hablar o toser) superando el umbral de calibracion, la IA del profesor es alertada de inmediato y se dirige al contenedor.

### 2. Videocamara y Vision Nocturna
* El jugador cuenta con una camara de video diegetica que incluye interfaz con contador de bateria, indicador de grabacion y timecode.
* Al presionar `F` o `Click Derecho`, se activa la vision nocturna.
* El uso continuo agota la bateria. Se pueden recolectar pilas AA distribuidas por el mapa para recargarla (`R`).

### 3. Inteligencia Artificial del Enemigo
* Implementada en `scripts/profesor.gd` mediante una maquina de estados finitos (`PATROL`, `SEARCH`, `CHASE`, `ATTACK`).
* Navegacion sobre un grafo de 91 waypoints multinivel interconectados que cubren Planta Baja, Primer Piso, Segundo Piso y las tres torres de escaleras.
* Sistema de vision con conos de deteccion, oido direccional y rutinas de recuperacion ante colisiones o bloqueos de ruta.

### 4. Sistema de Salud y Danio
* Sistema de resistencia de 2 impactos: el primer golpe hiere al jugador, aplicando un retroceso fisico, desaceleracion temporal del 15% y efecto visual de sangre periferica con latidos cardiacos. Un segundo golpe consecutivo resulta en la derrota definitiva.
* Consumo de items de recuperacion ("Peronachos") con la tecla `Q` para restaurar estamina y curar el estado de herido.

### 5. Progresion Narrativa y Espacial
* **Fase 1 (Planta Baja):** Resolucion de 4 parciales de matematicas en aulas y sectores de PB. Al aprobar el segundo parcial, el profesor inicia su patrullaje.
* **Fase 2 (Apagon General):** Al completar los 4 parciales, se produce un corte general de energia y se desbloquean los accesos a los pisos superiores.
* **Fase 3 (Subestacion Electrica):** Busqueda del fusible de 30A en el Primer Piso y colocacion en el tablero del Departamento de Electronica en PB.
* **Fase 4 (Auditorio y Escape):** Obtencion de la llave en la cafeteria del Segundo Piso, apertura de las cadenas del Auditorio Central, toma del diploma universitario y escape por la puerta principal.

---

## Controles

| Accion | Tecla / Entrada | Descripcion |
|---|---|---|
| Moverse | W, A, S, D | Desplazamiento del avatar en primera persona |
| Mirar / Orientar | Raton | Control de camara en ejes X e Y |
| Correr | Shift (mantener) | Aumenta la velocidad consumiendo barra de estamina |
| Vision Nocturna | F / Click Derecho / N | Activa o desactiva el visor nocturno de la camara |
| Recargar Batería | R | Consume una Pila AA del inventario (+50% carga) |
| Consumir Snack | Q | Consume Peronachos para reponer estamina |
| Interactuar | E | Recoger examenes, objetos, accionar tablero y puertas |
| Esconderse / Salir | E (frente a contenedor) | Ingresar o salir del tacho de basura |
| Ruido de Voz | Microfono fisico | Genera alertas al enemigo al estar oculto |
| Pausa | Escape | Abre el menu de pausa y objetivos |
| Coordenadas (Debug) | F3 | Alterna la visualizacion de coordenadas |

---

## Estructura del Proyecto

```text
├── default_bus_layout.tres     # Configuracion de buses de audio (Master, Sfx, Music, Record)
├── project.godot               # Archivo raiz de configuracion del motor Godot 4
├── resumen_proyecto.md         # Documento de Solucion de Diseno (SDD) segun pautas CDEV
├── README.md                   # Documentacion tecnica del repositorio
├── materials/                  # Materiales PBR y shaders espaciales
├── textures/                   # Texturas del entorno y elementos graficos
├── models/                     # Modelos tridimensionales (.glb / .tscn)
├── scenes/
│   ├── main.tscn               # Escena principal ensamblada del juego
│   ├── edificio_central.tscn   # Estructura arquitectonica del Edificio Central UTN FRC
│   ├── player.tscn             # Nodo del jugador, camara, linterna y colisiones
│   ├── profesor.tscn           # Nodo del enemigo principal con logica de navegacion
│   ├── tacho_basura.tscn       # Contenedor interactivo para la mecanica de sigilo
│   ├── hud.tscn                # Interfaz de usuario (bateria, estamina, microfono, REC)
│   ├── main_menu.tscn          # Menu de inicio con fondo 3D en tiempo real
│   ├── pause_menu.tscn         # Menu de pausa y opciones
│   ├── tablero_electrico.tscn  # Subestacion electrica interactiva
│   ├── puerta_auditorio.tscn   # Sistema de acceso cerrado con cadenas tridimensionales
│   ├── puerta_salida.tscn      # Puerta de egreso con comunicados institucionales
│   ├── cuaderno_matematica.tscn# Objetos interactivos de evaluacion matematica
│   ├── fusible.tscn            # Item de progreso (fusible de alta tension)
│   ├── pila_aa.tscn            # Item consumible de bateria
│   └── titulo_universitario.tscn# Item final de victoria
└── scripts/                    # Scripts en GDScript con la logica del juego
```

---

## Documentacion de Diseno (SDD)

Para una revision exhaustiva de los fundamentos teoricos, la aplicacion del marco de Janet Murray (inmersion, agencia, transformacion), las dimensiones de diseno (experiencial, estetica, tecnica y narrativa) y la planimetria 2D/3D del nivel, consultar el archivo [`resumen_proyecto.md`](./resumen_proyecto.md).
