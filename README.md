# 🎓 UTN FRC - Terror Indie

Juego de terror psicológico y supervivencia en primera persona inspirado en *Fears to Fathom*, ambientado en el edificio central real de la **Universidad Tecnológica Nacional - Facultad Regional Córdoba (UTN FRC)**.

Desarrollado en **Godot Engine 4.7** (Forward Plus).

---

## 📖 Sinopsis & Flujo del Juego

El jugador se encuentra solo de noche en la facultad intentando aprobar un parcial de matemáticas para poder escapar del edificio:

1. **Exploración Inicial (Planta Baja):** El jugador recorre las aulas buscando un parcial de matemáticas para resolver.
2. **El Corte de Energía (45s):** Ocurre un apagón general programado. ~95 luces del edificio se apagan y la luz ambiental cae drásticamente.
3. **Restauración Eléctrica:** El jugador debe ir a la cafetería a oscuras a buscar un **Fusible de alta tensión (30A)** y llevarlo al **Tablero Eléctrico** ubicado en el Laboratorio de Electrónica.
4. **Screamer del "Falso Alivio":** Al insertar el fusible, se produce un chispazo, la linterna se apaga y el profesor se posiciona sigilosamente detrás del jugador. Tras un golpe seco de su regla en la oscuridad, la luz regresa revelando su sombra proyectada en la pared antes de iniciar la persecución.
5. **Aprobación del Parcial:** Resolver correctamente el problema matemático otorga la **Llave de Salida**.
6. **Escape:** Correr a la puerta principal del ala sur e interactuar para escapar y ganar la partida.

---

## 🎮 Mecánicas Implementadas

* 🎙️ **Detección de Micrófono en Tiempo Real (`scripts/mic_detector.gd`):**
  * Captura de audio pasiva vía bus `Record` con `AudioEffectCapture`.
  * Medidor de decibelios visual en el HUD (verde ➔ amarillo ➔ rojo).
  * Si el jugador hace ruido por encima del umbral de peligro (`-24 dB`), alerta inmediatamente al Profesor si está en un radio de 35 metros.

* 🔦 **Linterna y Sigilo (`scripts/player.gd`):**
  * Alternable con la tecla `F`.
  * Tener la linterna encendida amplía el rango de visión del profesor en un **45%** (de 18m a ~26m).
  * Sistema de aceleración suave, carrera con `Shift`, *head bobbing* dinámico y subida automática de escalones de hasta 35 cm.

* 👨‍🏫 **Inteligencia Artificial del Profesor (`scripts/profesor.gd`):**
  * Modelo procedural 3D con CSG (traje gris, anteojos, corbata roja, bigote y regla de madera de 1.05m).
  * **Máquina de estados finitos (FSM):**
    * `PATROL`: Recorrido de 21 puntos estratégicos en pasillos de PB y patio central con sistema anti-bloqueo (*watchdog* de colisión).
    * `CHASE`: Persecución activa con visión cónica (80°) y raycasts que respetan paredes.
    * `SEARCH`: Búsqueda activa girando en el lugar si pierde de vista al jugador.
    * `ATTACK`: Azote con la regla de madera al alcanzar al jugador, aplicando impulso de retroceso físico y sacudida de cámara.
  * **Furia acumulativa:** Cada parcial desaprobado aumenta permanentemente la velocidad de patrulla y persecución, encendiendo sus ojos en rojo intenso.

* 🧮 **Exámenes de Matemáticas (`scripts/cuaderno_matematica.gd` y `hud.gd`):**
  * Cuadernos repartidos aleatoriamente entre 8 aulas de Planta Baja.
  * Generación dinámica de fórmulas aritméticas con opciones múltiples (1 correcta y 3 distractores).
  * Acertar otorga la llave de escape; fallar enfurece y atrae al profesor.

* 🔊 **Audio Procedural de Terror (`scripts/horror_audio.gd`):**
  * Generación matemática en tiempo de ejecución de buffers WAV (PCM 16-bit) sin assets externos pesados:
    * Chispazo de arco voltaico y zumbido de 60/120 Hz.
    * Golpe de madera seca resonante (regla contra mesada).
    * *Stinger* orquestal disonante con tritono agudo y frecuencias subgraves.

* 🏛️ **Entorno 3D Arquitectónico (`scenes/edificio_central.tscn`):**
  * Recreación de 3 niveles del edificio central de la UTN FRC:
    * **Planta Baja:** Aulas 101 a 115 con pupitres y pizarrones, Laboratorio de Electrónica, fotocopiadoras, cafetería.
    * **Patio del Estudiante:** A cielo abierto con canteros, árboles, faroles, pasarelas balconadas y fuente de agua con reflejos oscilantes (`scripts/patio_estudiante.gd`).
    * **Auditorio Principal:** Doble altura (9m) con escenario, atril y 64 butacas individuales rojas.
    * **Pisos 1 y 2:** Departamentos (Sistemas, Electrónica, Bedelía, Biblioteca, CETRA), aulas 201-219, cafetería piso 2 con monumento/escultura UTN.
    * **Escaleras:** 3 cajas de escaleras en U completamente transitables.

---

## ⌨️ Controles

| Acción | Tecla |
|---|---|
| Moverse | `W`, `A`, `S`, `D` |
| Correr | `Shift` (mientras se avanza) |
| Linterna | `F` |
| Interactuar (tablero, parciales, fusible, puerta) | `E` |
| Pausar / Liberar ratón | `Escape` |

---

## 🐛 Registro de Errores y Tareas Pendientes (Issue Tracker)

A continuación se detallan los bugs detectados y características faltantes para seguimiento del equipo:

### 🔴 Críticos / Prioritarios
- [ ] **Sobrescritura peligrosa en `tools/generate_level.gd` (Líneas 995-998):**
  * La función `_gen_main()` crea un `scripts/main.gd` básico de 8 líneas y lo guarda en disco.
  * **Riesgo:** Si se llega a ejecutar el generador para modificar o regenerar el mapa, sobrescribirá el `main.gd` completo del juego, perdiendo toda la lógica de apagón, screamer y ciclo de vida.
  * *Solución recomendada:* Eliminar o comentar la llamada a guardar `main.gd` dentro de `generate_level.gd`.

- [ ] **Sin Muerte / Game Over al ser atrapado:**
  * Cuando el profesor alcanza al jugador, lo golpea con la regla y lo empuja, pero el jugador no muere ni pierde vida. No existe pantalla de derrota ("Game Over").
  * *Solución recomendada:* Implementar sistema de salud/vidas o captura directa con cinemática corta y reinicio de nivel.

### 🟡 Medios / Jugabilidad
- [ ] **Pisos 1 y 2 sin objetivos de gameplay:**
  * Toda la experiencia interactiva (fusibles, parciales, tablero, salida y patrulla del profesor) ocurre en Planta Baja. Los pisos superiores están vacíos a nivel de juego y el profesor no tiene waypoints allí.
  * *Mejora planeada:* Distribuir parciales o llaves secundarias en los pisos 1 y 2, y extender la red de waypoints de la IA.

- [ ] **Doble disparo en interacción por tecla `E`:**
  * Varios scripts evalúan `Input.is_key_pressed(KEY_E)` en lugar de `Input.is_action_just_pressed("interact")`. Al mantener apretada la tecla un milisegundo de más, se dispara en múltiples frames consecutivos.
  * *Archivos afectados:* `cuaderno_matematica.gd`, `fusible.gd`, `puerta_salida.gd`, `tablero_electrico.gd`.

- [ ] **Reapertura de exámenes ya resueltos:**
  * En `cuaderno_matematica.gd`, `_open_challenge()` no valida si `is_solved == true`, permitiendo volver a abrir la interfaz de parcial aunque ya haya sido aprobado.

- [ ] **Acción de salto sin implementar:**
  * La acción `jump` (barra espaciadora) está definida en `project.godot` pero no está programada en `player.gd`.

---

## 📁 Estructura del Repositorio

```text
├── default_bus_layout.tres     # Configuración de buses de audio (Master y Record con Capture)
├── project.godot               # Configuración del motor, entradas y render
├── materials/                  # Materiales PBR (pisos, paredes, profesor, patio, etc.)
├── scenes/
│   ├── main.tscn               # Nivel principal ensamblado
│   ├── edificio_central.tscn   # Modelo completo de 3 plantas de la facultad
│   ├── player.tscn             # Jugador en primera persona con linterna
│   ├── profesor.tscn           # Antagonista modelado en CSG con IA
│   ├── hud.tscn                # UI: micrófono, inventario, examen, alertas
│   ├── tablero_electrico.tscn  # Tablero del laboratorio con fusible y screamer
│   ├── fusible.tscn            # Ítem fusible de 30A
│   ├── cuaderno_matematica.tscn# Parcial interactivo con lógica matemática
│   └── puerta_salida.tscn      # Puerta vidriada con cadenas y candado
├── scripts/                    # Lógica de juego en GDScript
└── tools/
    └── generate_level.gd       # Generador procedural del edificio
```
