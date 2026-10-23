# 🎓 UTN FRC - Terror Indie

Juego de terror psicológico y supervivencia en primera persona inspirado en *Fears to Fathom*, ambientado en el edificio central real de la **Universidad Tecnológica Nacional - Facultad Regional Córdoba (UTN FRC)**.

Desarrollado en **Godot Engine 4.7** (Forward Plus).

---

## 📖 Historia y Flujo Completo del Juego

El jugador se encuentra solo de noche en la facultad y debe recorrer el edificio central para rendir sus parciales pendientes, sobrevivir al acecho del implacable Profesor y conseguir su título universitario para escapar del campus:

1. **Exploración Inicial (Planta Baja):**
   * El jugador comienza en la Planta Baja (PB).
   * Los accesos a las escaleras que conducen a los pisos superiores están sellados con barreras energéticas y carteles de advertencia: *"PISO SUPERIOR CERRADO - Aprobá los 4 parciales"*.
   * El objetivo inmediato es recorrer las aulas y sectores de PB buscando los **4 cuadernos de parciales de matemáticas** repartidos estratégicamente (Aula 106, Fotocopiadora, Cafetería y Patio del Estudiante).

2. **El Corte de Luz & Despertar del Profesor:**
   * Al aprobar el **segundo examen**, se produce un apagón general programado: la iluminación del edificio colapsa, la luz ambiental cae a la penumbra total y se habilita la **linterna (`F`)**.
   * Con el corte de energía, hace su aparición en el edificio el **Profesor**, comenzando su patrullaje con su clásica regla de madera en mano.

3. **Desbloqueo de los Pisos Superiores:**
   * Al resolver y aprobar los **4 exámenes de matemáticas**, las barreras de las tres torres de escaleras (Oeste, Este y Norte) se desactivan automáticamente, desbloqueando el acceso al Primer y Segundo Piso.

4. **Búsqueda del Fusible de Alta Tensión (Pisos Superiores):**
   * El jugador debe subir las escaleras y explorar las oficinas superiores (como Bedelía) para hallar el **Fusible de Alta Tensión (30A)** necesario para reanimar la subestación eléctrica.

5. **Restauración Eléctrica & Evento del Tablero:**
   * Con el fusible en la mochila, el jugador debe descender nuevamente a PB y dirigirse al **Departamento de Ingeniería Electrónica**, donde se encuentra el **Tablero Eléctrico General**.
   * Al colocar el fusible, la energía se restablece en el edificio... pero no sin antes desencadenar un momento de máxima tensión con el profesor acechando en las sombras.

6. **La Llave del Auditorio y el Título Universitario:**
   * Con la energía restaurada, se puede obtener la **Llave del Auditorio**.
   * El jugador se dirige al **Auditorio Central de UTN FRC**, abre las puertas con la llave y sube al estrado principal para recoger su ansiado **Título Universitario (Diploma)**.

7. **Escape de la Facultad:**
   * Con el título en su poder, el jugador debe correr a la puerta principal de salida de la facultad, interactuar con ella para exhibir su diploma y escapar victorioso del edificio.

---

## 🎮 Mecánicas de Supervivencia y Sigilo

* 🗑️ **Esconderse en Tachos de Basura:**
  * Repartidos por pasillos y aulas de la facultad, se encuentran los característicos **tachos de basura rectangulares** de la UTN FRC.
  * Al acercarse a un tacho, el jugador puede presionar `E` para meterse adentro y ocultarse del profesor.
  * Mientras está adentro, el profesor no puede ver al jugador, lo que permite despistarlo o esperar a que siga de largo durante su patrullaje.

* 🎙️ **Tensión por Micrófono en Tiempo Real (`scripts/mic_detector.gd`):**
  * La detección del micrófono se activa **únicamente mientras estás escondido dentro de un tacho de basura**.
  * Al ingresar al tacho, aparece en pantalla el medidor de decibelios del micrófono (verde ➔ amarillo ➔ rojo).
  * **¡Mantené silencio absoluto!** Si hacés ruido real en tu habitación (hablar, respirar fuerte o golpear el escritorio) por encima del umbral de peligro, el profesor escuchará el sonido proveniente del tacho, se alertará de inmediato y correrá a arrancarte de tu escondite. Si te mantenés en silencio, el profesor pasará de largo sin advertir tu presencia.

* 🔦 **Linterna y Sigilo (`scripts/player.gd`):**
  * Alternable con la tecla `F` (se activa a partir del corte de luz).
  * Tener la linterna encendida amplía el rango de visión del profesor en un **45%**.
  * Movimiento con aceleración realista, *head bobbing* dinámico, pasos sincronizados y superación automática de pequeños desniveles y escalones.

* 👨‍🏫 **Inteligencia Artificial del Profesor (`scripts/profesor.gd`):**
  * Modelo procedural 3D con CSG (traje gris, anteojos, corbata roja, bigote y regla de madera de 1.05m).
  * **Máquina de estados finitos (FSM):**
    * `PATROL`: Recorrido multinivel a través de Planta Baja, Piso 1 y Piso 2, subiendo y bajando por las 3 cajas de escaleras en 3D.
    * `CHASE`: Persecución activa con visión cónica (105°), raycasts multinivel a ojos y torso, y navegación por pasillos con rodeo de mesadas de laboratorio.
    * `SEARCH`: Búsqueda activa girando e inspeccionando la última posición conocida del jugador.
    * `ATTACK`: Ataque con la regla de madera al alcanzar al jugador, aplicando impulso de retroceso físico y sacudida violenta de cámara.
  * **Rodeo Inteligente de Obstáculos:** Navegación optimizada en aulas y laboratorios mediante waypoints de pasillos laterales y doble chequeo de despeje.

* 🧮 **Exámenes de Matemáticas (`scripts/cuaderno_matematica.gd` y `hud.gd`):**
  * Desafíos de cálculo y álgebra con opciones múltiples interactivos.
  * Cada examen aprobado suma progreso para desbloquear los pisos superiores.
  * Fallar una respuesta enfurece al profesor, aumentando permanentemente su velocidad de desplazamiento.

* 🔊 **Audio Procedural de Terror & Paisaje Sonoro (`scripts/horror_audio.gd`):**
  * Generación en tiempo real de audio PCM (16-bit) sin assets pesados:
    * **Dron Ambiental Continuo:** Atmósfera densa y envolvente que se vuelve más oscura y tétrica durante el apagón.
    * **Pasos 3D del Profesor:** Taconeo espacializado que permite ubicar en qué piso o pasillo se encuentra.
    * **Latidos Cardíacos Dinámicos:** Pulso acelerado proporcional a la cercanía y peligro del profesor.
    * **Resonancia de Tachos de Basura:** Sonidos metálicos al ingresar, salir o recibir impactos en los contenedores.
    * **Jumpscare & Efectos Eléctricos:** Chispazos, golpes de regla y stingers de alto impacto sonoro.

* 🏛️ **Entorno 3D Arquitectónico de la UTN FRC (`scenes/edificio_central.tscn`):**
  * Recreación fiel de la Facultad Regional Córdoba:
    * **Planta Baja:** Aulas 101 a 115 con pupitres y pizarrones, Laboratorio de Electrónica con mesadas de 14m, fotocopiadoras, cafetería y heladeras de bebidas.
    * **Patio del Estudiante:** A cielo abierto con canteros perimetrales, vegetación, bancos contra la pared y fuente central interactiva.
    * **Auditorio Principal:** Espacio de doble altura con escenario, atril para el título y 64 butacas individuales.
    * **Pisos 1 y 2:** Departamentos (Sistemas, Electrónica, Bedelía, Biblioteca, CETRA), cafetería superior y monumento conmemorativo.
    * **Escaleras en U:** 3 torres de escaleras con escalones individuales de granito negro, barandas metálicas y barreras de control de acceso.

---

## ⌨️ Controles

| Acción | Tecla |
|---|---|
| Moverse | `W`, `A`, `S`, `D` |
| Correr | `Shift` (mientras se avanza) |
| Linterna | `F` (disponible tras el corte de luz) |
| Interactuar (parciales, fusible, tacho de basura, puertas) | `E` |
| Esconderse / Salir del tacho de basura | `E` (frente al contenedor) |
| Ver / Ocultar Coordenadas de depuración | `F3` |
| Copiar Coordenadas actuales al portapapeles | `F2` |
| Pausar / Liberar ratón | `Escape` |

---

## 🐛 Registro de Errores y Tareas Pendientes (Issue Tracker)

### 🔴 Críticos / Prioritarios
- [x] **Sobrescritura peligrosa en `tools/generate_level.gd`:** Resuelto, desactivada la llamada a `_gen_main()` y el guardado destructivo de `main.gd`.
- [x] **Alineación de barreras en las 3 torres de escaleras:** Bloqueos perfectamente sellados de pared a pared en Planta Baja.
- [x] **Desatasco de navegación del profesor en Laboratorio de Electrónica:** Resuelto el oscilamiento en el borde de las mesadas.
- [ ] **Sin Muerte / Game Over al ser atrapado:**
  * Cuando el profesor alcanza al jugador, lo golpea con la regla y lo empuja, pero el jugador no muere ni pierde vida. No existe pantalla de derrota ("Game Over").
  * *Solución recomendada:* Implementar sistema de salud/vidas o captura directa con cinemática corta y reinicio de nivel.

### 🟡 Medios / Jugabilidad
- [x] **Ruteo del profesor en 3 pisos:** Resuelto con 91 waypoints multinivel y watchdog anti-stuck.
- [x] **Mecánica de escondite en tachos de basura con tensión de micrófono:** Implementada.
- [ ] **Doble disparo en interacción por tecla `E`:**
  * Varios scripts evalúan `Input.is_key_pressed(KEY_E)` en lugar de `Input.is_action_just_pressed("interact")`.
- [ ] **Acción de salto sin implementar:**
  * La acción `jump` está definida en `project.godot` pero no está programada en `player.gd`.

---

## 📁 Estructura del Repositorio

```text
├── default_bus_layout.tres     # Configuración de buses de audio (Master y Record con Capture)
├── project.godot               # Configuración del motor, entradas y render
├── materials/                  # Materiales PBR (pisos, paredes, profesor, patio, tachos, etc.)
├── scenes/
│   ├── main.tscn               # Nivel principal ensamblado
│   ├── edificio_central.tscn   # Modelo completo de 3 plantas de la facultad
│   ├── player.tscn             # Jugador en primera persona con linterna
│   ├── profesor.tscn           # Antagonista modelado en CSG con IA
│   ├── tacho_basura.tscn       # Contenedores de basura interactivos para esconderse
│   ├── hud.tscn                # UI: micrófono reactivo al esconderse, inventario, examen, alertas
│   ├── tablero_electrico.tscn  # Tablero del laboratorio con fusible y screamer
│   ├── fusible.tscn            # Ítem fusible de 30A
│   ├── cuaderno_matematica.tscn# Parcial interactivo con lógica matemática
│   ├── puerta_auditorio.tscn   # Puerta con cerradura para el auditorio
│   ├── titulo_universitario.tscn# Diploma de graduación en el atril
│   └── puerta_salida.tscn      # Puerta vidriada para escapar con el título
├── scripts/                    # Lógica de juego en GDScript
└── tools/
    └── generate_level.gd       # Generador procedural del edificio
```
