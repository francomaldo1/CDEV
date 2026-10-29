# 🎓 UTN FRC: Noche de Finales

**Juego de terror psicológico y supervivencia en primera persona** desarrollado en **Godot Engine 4.7** (Forward Plus), ambientado en una recreación a escala del Edificio Central de la **Universidad Tecnológica Nacional - Facultad Regional Córdoba (UTN FRC)**.

> 📄 **Documento de Solución de Diseño (SDD) para Cátedra CDEV:**
> Para consultar la sistematización completa del proceso creativo según los lineamientos de la cátedra CDEV (dimensiones técnica, estética, narrativa y experiencial, marco teórico de Janet Murray, guión del trailer y anexos), consultar el archivo [`resumen_proyecto.md`](./resumen_proyecto.md).

---

## 📖 Historia y Flujo Completo del Juego

El jugador encarna a un estudiante rezagado que ha quedado atrapado de noche en el edificio central de la UTN FRC durante el turno de exámenes finales. Para escapar con vida y obtener su libertad, deberá rendir sus parciales pendientes, sobrevivir al acecho de "El Profesor" y conseguir su Título Universitario:

1. **Exploración Inicial (Planta Baja con Luz):**
   * El jugador comienza en el Hall de Entrada de Planta Baja (PB).
   * Los accesos a las escaleras que conducen a los pisos superiores están sellados con barreras energéticas institucionales: *"PISO SUPERIOR CERRADO - Aprobá los 4 parciales"*.
   * El objetivo inmediato es recorrer las aulas y sectores de PB buscando los **4 cuadernos de parciales de matemáticas** repartidos estratégicamente (Aula 106, Fotocopiadora CEIT, Cafetería PB y Patio del Estudiante). Cada examen presenta un desafío de opción múltiple; errar una respuesta enfurece al profesor y acelera su velocidad.

2. **El Despertar del Profesor (Segundo Parcial):**
   * Al aprobar el **segundo examen**, el Profesor escucha el pase de las hojas y sale a patrullar la Planta Baja con su clásica regla de madera en mano (*"¡El profesor escuchó las hojas! Salió a patrullar la Planta Baja..."*).
   * **La luz sigue encendida**: el jugador debe buscar y resolver el 3er y 4to examen con el profesor acechando activamente en los pasillos de PB.

3. **El Corte de Luz & Desbloqueo de Pisos Superiores (Cuarto Parcial):**
   * Al resolver y aprobar los **4 exámenes de matemáticas**, saltan los disyuntores y se produce el **Apagón General**: la iluminación principal colapsa, la luz ambiental cae a la penumbra total y se vuelve indispensable la **Visión Nocturna (`F` o Click Derecho)** de la videocámara.
   * Se ejecuta el susto cinemático de giro de 180° en el pasillo, el profesor entra en fase enfurecida y las barreras de las tres torres de escaleras (Oeste, Este y Norte) se desactivan automáticamente, desbloqueando el acceso al Primer y Segundo Piso.

4. **Búsqueda del Fusible de Alta Tensión (Primer Piso):**
   * El jugador asciende las escaleras, consulta la pizarra didáctica con el esquema de la subestación en el Primer Piso y explora las oficinas (Bedelía) para hallar el **Fusible de Alta Tensión (30A)** necesario para reanimar el sistema eléctrico.

5. **Restauración Eléctrica, Emboscada y Evento del Tablero:**
   * Con el fusible en mano, desciende nuevamente a PB al **Departamento de Ingeniería Electrónica**, donde se encuentra el **Tablero Eléctrico General de 220V**.
   * Al colocar el fusible, se produce un evento de emboscada: las luminarias del laboratorio se encienden secuencialmente y el Profesor carga a toda velocidad por el pasillo con música de violines. El jugador debe esquivarlo y salir del laboratorio para que la luz del edificio quede restablecida.

6. **La Llave del Auditorio y el Título Universitario:**
   * Con la energía restaurada, el jugador sube a la Cafetería del 2do Piso para obtener la **Llave Maestra del Auditorio**.
   * Se dirige al **Auditorio Central**, cuyas puertas están selladas con un entramado tridimensional de cadenas metálicas cruzadas y candados dorados estilo *Silent Hill 4*. Al usar la llave, las cadenas caen y se accede al estrado principal para recoger el ansiado **Título Universitario (Diploma)**, desatando el grito final del docente (*"¡¿QUIÉN TE DIO ESE TÍTULO?! ¡DEVOLVELO!"*).

7. **Escape de la Facultad:**
   * Con el título en su poder, el jugador corre a la puerta principal vidriada de salida (clausurada por las Autoridades FRC), exhibe su diploma y escapa victorioso del campus.

---

## 🎮 Mecánicas de Supervivencia, Sigilo y Diegesis

* 🗑️ **Esconderse en Tachos de Basura:**
  * Repartidos por pasillos y aulas de la facultad, se encuentran los característicos **tachos de basura rectangulares** de la UTN FRC.
  * Al pulsar `E` frente a un contenedor, el jugador se introduce en él, cambiando la cámara a una vista estrecha e invisible para el profesor.
  * Si el profesor pasa cerca del tacho (<= 7.5 m), se detiene a inspeccionarlo susurrando frases intimidantes (*"Sé que estás por acá..."*, *"Puedo oler el miedo a desaprobar..."*).

* 🎙️ **Tensión por Micrófono en Tiempo Real (`scripts/mic_detector.gd`):**
  * La detección del micrófono se activa **únicamente mientras estás escondido dentro de un tacho de basura**.
  * Al ingresar al tacho, aparece en pantalla el medidor de decibelios del micrófono (verde ➔ amarillo ➔ rojo).
  * **¡Silencio absoluto!** Si el jugador hace ruido real en su habitación (respirar fuerte, hablar o toser), el profesor grita (*"¡¡TE ESCUCHÉ EN ESE TACHO, NO TE VAS A ESCAPAR!!"*), corre a toda velocidad hacia el contenedor, expulsa al jugador a la fuerza y lo golpea. Si permanece en silencio, el docente pasa de largo.

* 📹 **Videocámara con Visión Nocturna y Pilas AA (`scripts/player.gd`):**
  * Se activa con la tecla `F`, `Click Derecho` o `N`. Enciende el modo de fósforo verde infrarrojo estilo *Found Footage / Outlast*.
  * El uso continuado consume la carga de batería de la videocámara.
  * En escritorios y aulas se encuentran **Pilas AA** recolectables; presionar `R` recarga un +50% de batería.

* ⚡ **Sistema de Estamina y Snacks "Peronachos":**
  * Correr con `Shift` consume la barra de estamina del jugador.
  * En estantes y buffets de la facultad se encuentran paquetes 3D de **Peronachos**; presionar `Q` consume un paquete y restaura de inmediato la energía física del estudiante.

* 🏢 **Señalética Institucional y Diegesis Total:**
  * Se reemplazaron todos los textos flotantes arcade por **50 placas institucionales acrílico-metálicas** atornilladas a las paredes con sombreado real (`shaded = true`), respetando la estética universitaria.
  * Puerta del Auditorio bloqueada por un entramado tridimensional procedural de **cadenas metálicas oxidadas y candados dorados**.
  * Puerta de salida con un comunicado oficial en hoja de papel A4 firmado al pie por "AUTORIDADES FRC".

* 👨‍🏫 **Inteligencia Artificial del Profesor (`scripts/profesor.gd`):**
  * Máquina de 4 estados (`PATROL`, `SEARCH`, `CHASE`, `ATTACK`).
  * Grafo de navegación multinivel con **91 waypoints** interconectados en Planta Baja, Primer Piso, Segundo Piso y las 3 torres de escaleras en U.
  * Ataque con regla de madera (*"¡¡¡CASTIGO POR COPIARSE!!!"*), empuje físico y sacudida de cámara.
  * Rutinas de prevención de atascamiento (*watchdog*), visión por conos de sombra y audición direccional.

* 🎵 **Diseño Sonoro Procedural de Terror (`scripts/horror_audio.gd`):**
  * Sintetizador dinámico de drones de baja frecuencia (30-60 Hz), estruendos de puertas, pisadas espaciales 3D, chasquidos de la regla de madera y música adaptativa según la cercanía del antagonista.

* 🖥️ **Menús y Experiencia de Usuario:**
  * **Menú Principal 3D:** Con paneo de cámara cinemático en tiempo real sobre el hall de ingreso, selección de opciones, ajustes de volumen independientes (Master, SFX, Música), panel de controles y créditos.
  * **Pantalla de Carga Minimalista:** Transición suave con barra de progreso y fundido sin cortes visuales.
  * **Menú de Pausa Diegético (`Escape`):** Permite revisar objetivos actuales, reanudar o ajustar configuración sin romper la inmersión.

---

## ⌨️ Controles

| Acción | Tecla / Dispositivo | Descripción |
|---|---|---|
| **Moverse** | `W`, `A`, `S`, `D` | Desplazamiento en primera persona |
| **Girar Vista** | Ratón | Orientación de cámara y dirección de visión nocturna |
| **Correr (Sprint)** | `Shift` (sostenido) | Aumenta la velocidad consumiendo estamina |
| **Visión Nocturna** | `F` / Click Der / `N` | Activa/desactiva la visión nocturna de la videocámara |
| **Recargar Batería**| `R` | Consume una Pila AA para recargar la videocámara (+50%) |
| **Comer Peronachos** | `Q` | Consume un paquete para regenerar la estamina al 100% |
| **Interactuar** | `E` | Recoger exámenes, pilas, snacks, fusibles y usar puertas |
| **Esconderse / Salir** | `E` (frente al tacho) | Ingresar al contenedor o salir de él |
| **Voz / Silencio** | Micrófono físico | Detección de ruido real dentro del escondite |
| **Pausar Partida** | `Escape` | Abre el menú de pausa |
| **Ver Coordenadas (Debug)** | `F3` | Muestra posición Vector3 en pantalla |
| **Copiar Coordenadas (Debug)**| `F2` | Copia coordenadas al portapapeles |

---

## 📁 Estructura del Repositorio

```text
├── default_bus_layout.tres     # Configuración de buses de audio (Master, Sfx, Music, Record con Capture)
├── project.godot               # Configuración del motor, render Forward+ y keybindings
├── resumen_proyecto.md         # Documento exhaustivo de diseño (SDD CDEV)
├── README.md                   # Documentación general del repositorio
├── materials/                  # Materiales PBR (granito, maderas, metales cepillados, papel)
├── textures/                   # Texturas oficiales (Peronachos, metales, vidrios UTN)
├── models/                     # Modelos 3D (pizarras, heladeras, árboles, barbijos/máscaras)
├── scenes/
│   ├── main.tscn               # Nivel principal ensamblado con todos los módulos
│   ├── edificio_central.tscn   # Modelo arquitectónico de 3 pisos con colisiones
│   ├── player.tscn             # Jugador en 1ra persona con cámara, visión nocturna y raycasts
│   ├── profesor.tscn           # Antagonista modelado en CSG con IA y regla de madera
│   ├── tacho_basura.tscn       # Contenedor interactivo para ocultamiento
│   ├── hud.tscn                # UI: medidor de mic, batería, estamina, postproceso VHS
│   ├── main_menu.tscn          # Menú principal con fondo 3D en vivo
│   ├── pause_menu.tscn         # Menú de pausa interactivo
│   ├── tablero_electrico.tscn  # Subestación del Departamento de Electrónica
│   ├── puerta_auditorio.tscn   # Puerta con sistema de cadenas y candados
│   ├── puerta_salida.tscn      # Salida de vidrio con cartel institucional de clausura
│   ├── cuaderno_matematica.tscn# Exámenes con lógica de evaluación matemática
│   ├── fusible.tscn            # Fusible de 30A recolectable
│   ├── pila_aa.tscn            # Pila AA para la videocámara
│   └── titulo_universitario.tscn# Diploma de graduación en el atril
├── scripts/                    # Scripts en GDScript 2.0 (lógica del juego e IA)
└── tools/                      # Herramientas de generación y utilidades
```

---

## 🏛️ Créditos y Cátedra

* **Cátedra:** CDEV (Creatividad y Desarrollo de Entornos Virtuales).
* **Carrera:** Ingeniería en Sistemas de Información.
* **Institución:** Universidad Tecnológica Nacional - Facultad Regional Córdoba (UTN FRC).
