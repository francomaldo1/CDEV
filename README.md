# 🎓 UTN FRC: Noche de Finales

**Juego de terror psicológico y supervivencia en primera persona** desarrollado en **Godot Engine 4.7** (Forward Plus), ambientado en una recreación a escala del Edificio Central de la **Universidad Tecnológica Nacional - Facultad Regional Córdoba (UTN FRC)**.

> 📄 **Documento de Solución de Diseño (SDD) para Cátedra CDEV:**
> Para consultar la sistematización completa del proceso creativo según los lineamientos de la cátedra CDEV (dimensiones técnica, estética, narrativa y experiencial, marco teórico de Janet Murray y guión de trailer), consultar el archivo [`resumen_proyecto.md`](./resumen_proyecto.md).

---

## 📖 Historia y Flujo Completo del Juego

El jugador encarna a un estudiante rezagado que ha quedado atrapado de noche en el edificio central de la UTN FRC durante el turno de exámenes finales. Para escapar con vida y obtener su libertad, deberá rendir sus parciales pendientes, sobrevivir al acecho de "El Profesor" y conseguir su Título Universitario:

1. **Exploración Inicial (Planta Baja):**
   * El jugador comienza en el Hall de Entrada de Planta Baja (PB).
   * Los accesos a las escaleras que conducen a los pisos superiores están sellados con barreras energéticas institucionales: *"PISO SUPERIOR CERRADO - Aprobá los 4 parciales"*.
   * El objetivo inmediato es recorrer las aulas y sectores de PB buscando los **4 cuadernos de parciales de matemáticas** repartidos estratégicamente (Aula 106, Fotocopiadora CEIT, Cafetería PB y Patio del Estudiante).

2. **El Corte de Luz & Despertar del Profesor:**
   * Al aprobar el **segundo examen**, se produce un apagón general programado: la iluminación principal colapsa, la luz ambiental cae a la penumbra total y se habilita la **linterna (`F`)**.
   * Con el corte de energía, hace su aparición en el edificio el temible **Profesor**, comenzando su patrullaje implacable con su clásica regla de madera en mano.

3. **Desbloqueo de los Pisos Superiores:**
   * Al resolver y aprobar los **4 exámenes de matemáticas**, las barreras de las tres torres de escaleras (Oeste, Este y Norte) se desactivan automáticamente, desbloqueando el acceso al Primer y Segundo Piso.

4. **Búsqueda del Fusible de Alta Tensión (Primer Piso):**
   * El jugador asciende las escaleras, consulta la pizarra didáctica con el esquema de la subestación en el Primer Piso y explora las oficinas (Bedelía) para hallar el **Fusible de Alta Tensión (30A)** necesario para reanimar el sistema eléctrico.

5. **Restauración Eléctrica & Evento del Tablero:**
   * Con el fusible en mano, desciende nuevamente a PB al **Departamento de Ingeniería Electrónica**, donde se encuentra el **Tablero Eléctrico General de 220V**.
   * Al colocar el fusible, la energía se restablece en el edificio, desencadenando tensión y alertas sonoras.

6. **La Llave del Auditorio y el Título Universitario:**
   * Con la energía restaurada, el jugador sube a la Cafetería del 2do Piso para obtener la **Llave Maestra del Auditorio**.
   * Se dirige al **Auditorio Central**, cuyas puertas están fuertemente aseguradas con cadenas metálicas cruzadas y candados estilo *Silent Hill 4*. Al usar la llave, las cadenas caen y se accede al estrado principal para recoger el ansiado **Título Universitario (Diploma)**.

7. **Escape de la Facultad:**
   * Con el título en su poder, el jugador debe correr a la puerta principal vidriada de salida (clausurada con el comunicado oficial de las Autoridades FRC), exhibir su diploma y escapar victorioso del campus.

---

## 🎮 Mecánicas de Supervivencia, Sigilo y Diegesis

* 🗑️ **Esconderse en Tachos de Basura:**
  * Repartidos por pasillos y aulas de la facultad, se encuentran los característicos **tachos de basura rectangulares** de la UTN FRC.
  * Al pulsar `E` frente a un contenedor, el jugador se introduce en él, cambiando la cámara a una vista estrecha e invisible para el profesor.

* 🎙️ **Tensión por Micrófono en Tiempo Real (`scripts/mic_detector.gd`):**
  * La detección del micrófono se activa **únicamente mientras estás escondido dentro de un tacho de basura**.
  * Al ingresar al tacho, aparece en pantalla el medidor de decibelios del micrófono (verde ➔ amarillo ➔ rojo).
  * **¡Silencio absoluto!** Si el jugador hace ruido real en su habitación (respirar fuerte, hablar o toser), el profesor escuchará el sonido proveniente del contenedor y correrá a atacarlo. Si permanece en silencio, el docente pasará de largo.

* 🔦 **Linterna y Gestión de Batería:**
  * Se activa con la tecla `F`. El uso continuado consume la carga de la batería.
  * Por las aulas y oficinas se encuentran **Pilas AA** recolectables para recargar la linterna.
  * Mantener la linterna encendida aumenta el rango de detección visual del profesor.

* ⚡ **Sistema de Estamina y Snacks "Peronachos":**
  * Correr con `Shift` consume la barra de estamina del jugador.
  * En estantes y buffets de la facultad se encuentran paquetes 3D de **Peronachos** que restauran de inmediato la energía física del estudiante.

* 🏢 **Señalética Institucional y Diegesis Total:**
  * Se reemplazaron todos los textos flotantes arcade por **placas institucionales acrílico-metálicas** atornilladas a las paredes con sombreado real (`shaded = true`), respetando la estética universitaria.
  * Puerta del Auditorio bloqueada por un entramado tridimensional procedural de **cadenas metálicas oxidadas y candados dorados**.
  * Puerta de salida con un comunicado oficial en hoja de papel A4 firmado al pie por "AUTORIDADES FRC".

* 📹 **Estética VHS / Bodycam (`scripts/hud.gd`):**
  * Postprocesado analógico con grano fílmico, aberración cromática, viñeta CRT, indicador de batería, parpadeo de grabación REC y reloj con timestamp oficial.

* 👨‍🏫 **Inteligencia Artificial del Profesor (`scripts/profesor.gd`):**
  * Máquina de estados (`PATROL`, `SEARCH`, `CHASE`, `ATTACK`, `INVESTIGATE`).
  * Grafo de navegación multinivel con **91 waypoints** interconectados en Planta Baja, Primer Piso, Segundo Piso y las 3 torres de escaleras en U.
  * Rutinas de prevención de atascamiento (*watchdog*), visión por conos de sombra y audición direccional.

* 🎵 **Diseño Sonoro Procedural de Terror (`scripts/horror_audio.gd`):**
  * Sintetizador dinámico de drones de baja frecuencia, estruendos de puertas, pisadas espaciales 3D, chasquidos de la regla de madera y música adaptativa según la cercanía del antagonista.

* 🖥️ **Menús y Experiencia de Usuario:**
  * **Menú Principal 3D:** Con paneo de cámara cinemático en tiempo real sobre el hall de ingreso, selección de opciones, ajustes de volumen independientes (Master, SFX, Música), panel de controles y créditos.
  * **Pantalla de Carga Minimalista:** Transición suave con barra de progreso y fundido sin cortes visuales.
  * **Menú de Pausa Diegético (`Escape`):** Permite revisar objetivos actuales, reanudar o ajustar configuración sin romper la inmersión.

---

## ⌨️ Controles

| Acción | Tecla / Dispositivo | Descripción |
|---|---|---|
| **Moverse** | `W`, `A`, `S`, `D` | Desplazamiento en primera persona |
| **Girar Vista** | Ratón | Orientación de cámara y linterna |
| **Correr (Sprint)** | `Shift` (sostenido) | Aumenta la velocidad consumiendo estamina |
| **Linterna** | `F` | Alterna encendido/apagado (requiere corte de luz) |
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
│   ├── player.tscn             # Jugador en 1ra persona con cámara, linterna y raycasts
│   ├── profesor.tscn           # Antagonista modelado en CSG con IA y regla
│   ├── tacho_basura.tscn       # Contenedor interactivo para ocultamiento
│   ├── hud.tscn                # UI: medidor de mic, batería, estamina, postproceso VHS
│   ├── main_menu.tscn          # Menú principal con fondo 3D en vivo
│   ├── pause_menu.tscn         # Menú de pausa interactivo
│   ├── tablero_electrico.tscn  # Subestación del Departamento de Electrónica
│   ├── puerta_auditorio.tscn   # Puerta con sistema de cadenas y candados
│   ├── puerta_salida.tscn      # Salida de vidrio con cartel institucional de clausura
│   ├── cuaderno_matematica.tscn# Exámenes con lógica de evaluación matemática
│   ├── fusible.tscn            # Fusible de 30A recolectable
│   ├── pila_aa.tscn            # Pila AA para la linterna
│   └── titulo_universitario.tscn# Diploma de graduación en el atril
├── scripts/                    # Scripts en GDScript 2.0 (lógica del juego e IA)
└── tools/                      # Herramientas de generación y utilidades
```

---

## 🏛️ Créditos y Cátedra

* **Cátedra:** CDEV (Creatividad y Desarrollo de Entornos Virtuales).
* **Carrera:** Ingeniería en Sistemas de Información.
* **Institución:** Universidad Tecnológica Nacional - Facultad Regional Córdoba (UTN FRC).
