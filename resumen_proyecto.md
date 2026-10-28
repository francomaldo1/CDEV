# Solution Design Document (SDD) & Resumen Exhaustivo del Proyecto
## Cátedra CDEV (Creatividad y Desarrollo de Entornos Virtuales)
### UTN - Facultad Regional Córdoba | Ingeniería en Sistemas de Información

---

# UTN FRC: Noche de Finales (Terror Indie)
**Documento de Sistematización del Proceso Creativo y Arquitectura de Diseño**

---

## 1. Introducción

**UTN FRC: Noche de Finales** es un entorno virtual interactivo de terror psicológico y supervivencia en primera persona, desarrollado en **Godot Engine 4.7** (Forward Plus). La experiencia se ambienta en una recreación a escala del emblemático Edificio Central de la **Universidad Tecnológica Nacional - Facultad Regional Córdoba (UTN FRC)**, situada en la Ciudad Universitaria de Córdoba.

El proyecto fusiona la atmósfera opresiva del terror analógico (*analog horror* / estética VHS) popularizado por obras como *Fears to Fathom* y *The Mortuary Assistant*, con el arraigo cultural e identitario de la vida universitaria tecnológica argentina. En este espacio liminal nocturno, los miedos cotidianos del estudiante de ingeniería (la frustración académica, el desamparo institucional, el terror a no graduarse) se transmutan en una pesadilla diegética donde el usuario debe rendir exámenes reales, evadir a un implacable docente espectral ("El Profesor"), restaurar la red eléctrica del campus y obtener su Título Universitario para escapar.

---

## 2. Organización del Equipo de Diseño (Roles y Descripción)

El desarrollo del entorno virtual se estructuró siguiendo metodologías ágiles adaptadas a entornos interactivos, distribuyendo las responsabilidades en los siguientes roles clave:

* **Director de Proyecto & Game Designer (Diseño Lúdico y Narrativo):**
  * Definición del concepto central, mecánicas de juego (*gameplay loop*), progresión por actos y diseño narrativo ambiental (*environmental storytelling*).
  * Coordinación de la visión estética, coherencia diegética y articulación del documento de solución de diseño (SDD).
* **Arquitecto Técnico & Programador de Sistemas (Gameplay & AI Developer):**
  * Implementación de la arquitectura de escenas y scripts en GDScript sobre Godot 4.7.
  * Programación del controlador del jugador en primera persona, sistema de inventario, detección de interacción y medidor de estamina.
  * Desarrollo del árbol de estados y sistema de navegación por waypoints del antagonista (*El Profesor*), con visión por rayos (*RayCast3D*) y rutinas de desatasco (*watchdog*).
* **Diseñador de Entornos & Artista Técnico (Environment & Level Design):**
  * Modelado volumétrico y espacial del Edificio Central de UTN FRC (Planta Baja, Primer Piso y Segundo Piso), patios interiores, aulas, laboratorios y auditorio.
  * Configuración de iluminación física PBR, mapas de sombras, materiales dieléctricos y metálicos, y generación procedural de accesorios diegéticos (placas institucionales acrílicas, cadenas de Silent Hill 4, pizarras).
* **Diseñador Sonoro & Audio Engineer (Audio & Inmersión Háptica/Acústica):**
  * Creación y mezcla del espacio sonoro binaural/3D, drones de baja frecuencia, crujidos y ruidos de equipamiento eléctrico.
  * Implementación del bus de captura en tiempo real (`Record` / `AudioEffectCapture`) para la mecánica de detección de ruido del micrófono físico del usuario.
* **Diseñador UI/UX & Artista de Shaders:**
  * Diseño de interfaces diegéticas (HUD tipo cámara de seguridad VHS / Bodycam con timestamps, batería y viñeta CRT).
  * Diseño e implementación del Menú Principal cinematográfico en 3D, menú de pausa interactivo y pantallas de carga minimalistas.

---

## 3. Aspectos Generales del Diseño

### 3.1 Reto de Diseño
*¿Cómo transformar un edificio universitario real, transcurrido a diario por miles de estudiantes, en un entorno virtual inmersivo capaz de generar auténtica indefensión, tensión psicológica y horror diegético sin recurrir a monstruos genéricos, sino potenciando el folclore, las vivencias y la arquitectura propia de la UTN FRC?*

### 3.2 Problema, Necesidad o Motivación (Dimensión Emocional)
* **Emociones núcleo buscadas:** Vulnerabilidad, claustrofobia, paranoia acústica, soledad abrumadora y urgencia de supervivencia.
* **Resonancia cultural:** La vida universitaria en carreras exigentes suele vivenciarse con ansiedad por el rendimiento, exámenes nocturnos agotadores y pasillos infinitos cuando la facultad queda vacía. El proyecto toma esa carga afectiva real y la sublima en un artefacto lúdico-narrativo donde el docente exigente se transforma en el cazador supremo y el diploma es el único salvoconducto de salida.

### 3.3 Público Objetivo
* Jóvenes estudiantes y graduados universitarios (especialmente de la UTN y carreras STEM) con afinidad por las referencias culturales y geográficas locales.
* Aficionados a los videojuegos de terror independiente, experiencias inmersivas en primera persona, juegos de sigilo (*stealth horror*) y narrativas de terror analógico (*Found Footage / VHS*).

### 3.4 Características Generales del Entorno
* **Género:** Survival Horror / Psychological Stealth Horror en primera persona.
* **Perspectiva:** Cámara subjetiva (POV) estilo Bodycam / Videocámara digital estudiantil.
* **Motor:** Godot Engine 4.7 (Render Forward+ con soporte de reflejos de pantalla, oclusión ambiental y niebla volumétrica).
* **Plataforma:** PC (Windows / Linux).
* **Duración estimada por sesión:** 20 - 35 minutos.

### 3.5 Objetivos Alineados con la Estrategia CDEV
* Sistematizar un entorno virtual completo articulando dimensiones técnicas, estéticas, narrativas y experienciales.
* Aplicar metodologías de diseño inmersivo y teorías consagradas de nuevos medios (Janet Murray).
* Desarrollar interacciones no convencionales que rompan la cuarta pared (uso del micrófono como sensor físico de silencio).

---

## 4. Análisis de Usuarios y Actores

### 4.1 Usuarios Primarios
* **Perfil Explorador-Superviviente:** Jugador que analiza el entorno en penumbras, memoriza salidas, gestiona los recursos escasos (pilas AA, Peronachos para estamina) y disfruta de la lectura de carteles, pistas y pizarras.
* **Perfil Reactivo:** Jugador propenso al pánico ante la persecución, que utiliza el sigilo, se esconde en tachos de basura y debe controlar activamente su propia respiración para no ser delatado por su micrófono.

### 4.2 Actores del Entorno
* **El Estudiante (El Jugador):**
  * Protagonista innominado. No posee armas de fuego ni capacidades sobrenaturales; su única defensa es el sigilo, la velocidad de carrera limitada por su estamina física, su linterna con batería finita y su capacidad de razonamiento lógico.
* **El Profesor (Antagonista Espectral):**
  * Representación física de la exigencia académica desmedida y la condena a recursar.
  * Se desplaza con paso implacable portando una regla de madera. Posee percepción visual cónica, audición a ruidos repentinos y una ruta de patrullaje multi-piso de 91 nodos que abarca pasillos, escaleras y aulas.
* **El Edificio Central (El Sistema Opresivo / Entorno Vivo):**
  * El edificio actúa como un personaje antagonista pasivo: sus puertas se clausuran mediante candados y cadenas, la energía colapsa al resolver exámenes, las luces parpadean y las barreras impiden la salida hasta cumplir con los requisitos académicos del decanato.

---

## 5. Narrativa Inmersiva y Perspectiva del Usuario

### 5.1 Narrativa Digital (Storytelling)
El argumento no se transmite mediante extensas cinemáticas pasivas, sino a través de **narrativa ambiental (*environmental storytelling*)** y progresión por hitos:
1. **Acto I (El Aislamiento y los Exámenes):** El jugador está varado de noche en la facultad. Para desbloquear el acceso a los pisos superiores debe resolver 4 parciales de matemáticas distribuidos en Planta Baja (Aula 106, Fotocopiadora CEIT, Cafetería y Patio del Estudiante).
2. **Acto II (El Colapso de la Red y el Acecho):** Al entregar el segundo parcial, se produce un corte general de suministro eléctrico. La facultad queda a oscuras, se activa la linterna de la cámara y emerge "El Profesor" a cazar al intruso.
3. **Acto III (La Subestación y el Fusible):** Con los 4 exámenes aprobados, caen las barreras de las escaleras. El jugador asciende al Primer Piso, consulta la pizarra técnica de Bedelía y localiza un fusible de alta tensión de 30A para restaurar la luz en el Laboratorio de Electrónica.
4. **Acto IV (El Auditorio Sellado y el Diploma):** La energía reactivada permite ingresar a la Cafetería del 2do Piso a buscar la Llave Maestra. Con ella se desbloquean las cadenas del Auditorio Central, donde espera el Título Universitario en el atril.
5. **Acto V (El Egreso o la Condena):** Con el diploma en mano, el jugador corre a la Puerta de Salida vidriada para romper el protocolo de clausura nocturna y escapar.

### 5.2 Inmersión, Agencia y Transformación (Marco Teórico de Janet Murray)
Siguiendo las tres categorías fundamentales de Janet Murray en *Hamlet en la Holocubierta*:

* **Inmersión (La sensación de ser transportado a un espacio virtual envolvente):**
  * *Inmersión espacial y sensorial:* Reproducción arquitectónica verosímil de la UTN FRC (pasillos largos, ventanas al patio interno, aulas numeradas, señalética oficial). La estética de videocámara personal (batería, timestamp, grano analógico, aberración cromática) sitúa al usuario dentro de un registro testimonial vivido en carne propia.
  * *Inmersión psicológica:* El silencio claustrofóbico solo interrumpido por el eco de pasos distantes y zumbidos eléctricos crea un estado constante de alerta.
* **Agencia (La capacidad de realizar acciones significativas y ver los resultados inmediatos en el mundo):**
  * El usuario no es un mero espectador: responde preguntas matemáticas reales en los cuadernos para avanzar, decide cuándo encender o apagar la linterna para no agotar la pila AA, decide si huir o meterse en un tacho de basura, y debe guardar silencio físico real en su habitación porque su micrófono transmite el sonido al juego.
* **Transformación (La mutación del estado del sujeto dentro de la experiencia):**
  * El protagonista inicia como un alumno rezagado, vulnerable, desorientado y perseguido; a través de su esfuerzo intelectual (resolver exámenes) y físico (evadir al profesor, reparar el sistema eléctrico), se transforma en un **Graduado Habilitado** que con su título en mano vence al sistema institucional que lo mantenía cautivo.

### 5.3 Perspectiva del Usuario (Flujo y POV)
* **Cámara en primera persona (POV):** Con micro-balanceo cefálico (*head bobbing*) al caminar y correr, acentuando la corporalidad física del personaje.
* **Conos de visibilidad y oclusión:** La visión está deliberadamente acotada al haz cónico de la linterna y a las fuentes tenues de luz de emergencia.
* **Flujo interactivo continuo:** Transición sin cortes entre el movimiento libre, la inspección cercana de objetos, el ocultamiento en contenedores y la interacción con tableros.

---

## 6. Diseño Multisensorial e Interacción

### 6.1 Estética Visual
* **Realismo Institucional Brutalista:** Texturas de mosaico granítico en pisos, paredes divididas con zócalos de madera y revoque superior, aberturas metálicas y puertas acristaladas institucionales.
* **Señalética Diegética:**
  * Reemplazo de textos flotantes por **placas institucionales acrílico-metálicas** atornilladas a las paredes con marco biselado y acabado cepillado que reaccionan a la luz real (`shaded = true`).
  * Puerta del Auditorio clausurada con **cadenas metálicas oxidadas cruzadas proceduralmente y candados dorados macizos** con acabado metálico rugoso (inspirados en *Silent Hill 4*).
  * Comunicado oficial de clausura en papel blanco A4 pegado sobre el cristal de salida con firma institucional de "AUTORIDADES FRC".
* **Filtro VHS / Found Footage:** Shader de postprocesado con bandas de tracking, aberración cromática, distorsión de lente y viñeteado.

### 6.2 Inmersión y Dispositivos de Hardware
* **Visual:** Monitor / Pantalla panorámica con tasa de refresco a 60 fps.
* **Auditivo:** Auriculares estéreo o envolventes (vitales para la localización espacial 3D de las pisadas y la regla del profesor).
* **Entrada Motriz:** Teclado y ratón para locomoción, orientación y acciones de interacción.
* **Sensor Biomecánico / Acústico (Micrófono):** Micrófono de entrada de la PC del jugador utilizado como sensor del mundo real dentro del espacio virtual.

### 6.3 Tipos y Diseño de Dispositivos de Interacción
* **Contenedores de Basura Interactivos:**
  * Al pulsar `E` frente a un tacho de basura UTN, el jugador entra en él. La cámara se restringe y aparece en pantalla el **indicador de decibeles del micrófono**.
  * Si el usuario tose, habla o respira fuerte en su habitación, la barra sobrepasa el umbral rojo y el Profesor golpea y abre el tacho.
* **Linterna y Gestión de Batería:**
  * Activación con tecla `F`. El porcentaje de batería decae de forma continua. Encontrar pilas AA en las aulas o mesas es indispensable para no quedar a oscuras total.
* **Alacenas de Consumibles (Peronachos):**
  * Paquetes de snacks "Peronachos" modelados en 3D sobre repisas y máquinas expendedoras que restauran instantáneamente la barra de estamina del jugador.

### 6.4 Diseño Sonoro
* **Audio 3D Espacial:** Implementado con atenuación cuadrática real. Las pisadas del profesor sobre el mosaico granítico indican su piso y distancia relativa.
* **Efectos Diegéticos Específicos:** Chasquido de la regla de madera contra la mano del docente, estruendo metálico de puertas que se cierran, zumbido de balasto de 50 Hz en los fluorescentes, chisporroteo del fusible de alta tensión.
* **Diseño Procedural de Terror (`horror_audio.gd`):** Sintetizador dinámico que reproduce drones armónicos profundos y acordes disonantes en momentos de proximidad y persecución.

### 6.5 Diseño Narrativo del Entorno
* Mobiliario típico universitario: pupitres dobles de caño estructural con tablas de fórmica verde, bancos de hormigón en el patio, canteros con vegetación interna y pizarrones con anotaciones previas de cátedras reales.

---

## 7. Arquitectura Técnica

### 7.1 Tecnologías y Pipeline
* **Motor:** Godot Engine v4.7.2 stable official (Windows 64-bit console / GUI).
* **Lenguaje:** GDScript 2.0 (fuertemente tipado en sistemas críticos de IA y audio).
* **Render Pipeline:** Forward+ (Clustered Forward) con filtrado anisotrópico x8, sombras direccionales en cascada y materiales StandardMaterial3D PBR (albedo, roughness, metallic, normal map, emission).

### 7.2 Estructura de Escenas Principales
```text
res://
├── scenes/
│   ├── main.tscn               # Ensamblado del nivel y orquestador de lógica
│   ├── edificio_central.tscn   # Malla arquitectónica y colisiones de 3 niveles
│   ├── player.tscn             # Nodo CharacterBody3D, cámara, linterna, raycasts
│   ├── profesor.tscn           # Antagonista con IA, colisión y mesh CSG/PBR
│   ├── hud.tscn                # CanvasLayer con postproceso VHS, stamina, mic y batería
│   ├── main_menu.tscn          # Menú principal con cámara 3D en vivo
│   ├── pause_menu.tscn         # Menú de pausa diegético sobre el gameplay
│   ├── tacho_basura.tscn       # Contenedor interactivo para ocultamiento
│   ├── tablero_electrico.tscn  # Subestación del Laboratorio de Electrónica
│   ├── puerta_auditorio.tscn   # Puerta con sistema procedural de cadenas y candados
│   ├── puerta_salida.tscn      # Abertura vidriada con cartel de clausura oficial
│   ├── cuaderno_matematica.tscn# Examen interactivo con formulario
│   ├── fusible.tscn            # Ítem recolectable de alta tensión (30A)
│   ├── pila_aa.tscn            # Consumible para recargar batería de la linterna
│   └── titulo_universitario.tscn# Ítem final de graduación en el atril
```

### 7.3 Arquitectura de Scripts (`scripts/`)
* `main.gd`: Administra el flujo macro de la partida, registro de exámenes aprobados, corte de energía, desbloqueo de barreras de escaleras, generación estética de placas institucionales y control de victoria.
* `player.gd`: Físicas del usuario, caminata/carrera con consumo y regeneración de estamina, balanceo de cámara, audio de pasos, interacción `RayCast3D` y estado de ocultamiento.
* `profesor.gd`: Máquina de estados finitos (`PATROL`, `SEARCH`, `CHASE`, `ATTACK`, `INVESTIGATE`). Navegación por grafo de waypoints (91 nodos 3D interconectados) con prevención de atascamiento.
* `mic_detector.gd`: Interfaz con el bus de audio `Record`, muestreo de buffer del `AudioEffectCapture` y cálculo del nivel RMS en decibelios.
* `hud.gd`: Control de la interfaz gráfica, shaders de pantalla analógica, reloj REC, slots de inventario y retroalimentación de interacción.
* `horror_audio.gd`: Controlador de audio adaptativo, drones tonales, stingers de sobresalto (*jump scare*) y música de persecución.
* `main_menu.gd` & `pause_menu.gd`: Gestión de interfaz de usuario, ajuste de buses de volumen (`Master`, `Sfx`, `Music`), panel de controles y créditos.

### 7.4 Grafo de Navegación del Antagonista
* 91 waypoints estratégicos distribuidos en:
  * Planta Baja: pasillos norte, sur, este y oeste, hall de entrada, buffet y patio.
  * Torres de Escaleras: nodos de transición vertical entre plantas (Oeste, Este, Norte).
  * Primer y Segundo Piso: circulación perimetral completa frente a las aulas 101-115 y 201-219.

---

## 8. Proceso de Prototipado y Evolución

### 8.1 Fases del Proceso Creativo
1. **Fase 1 - Greyboxing & Arquitectura (CSG):** Modelado a escala del edificio central de la UTN FRC para validar distancias de carrera, líneas de visión y proporciones de aulas y patios.
2. **Fase 2 - Loop de Jugabilidad Básico:** Implementación de la recolección de los 4 exámenes de matemática y la IA básica del profesor patrullando la planta baja.
3. **Fase 3 - El Apagón y la Navegación Vertical:** Integración del corte de luz tras el segundo parcial, activación de linternas y habilitación de las tres escaleras hacia P1 y P2.
4. **Fase 4 - Mecánica Innovadora de Micrófono & Tachos:** Creación de los escondites en contenedores de basura con el medidor de decibeles por micrófono real.
5. **Fase 5 - Transición Diegética Total:** Eliminación de carteles flotantes y carteles estilo texto brillante. Creación de placas institucionales de acrílico/aluminio fijas en muros, cadenas tridimensionales de Silent Hill 4 y cartel de clausura en papel formal.
6. **Fase 6 - Pulido UX/UI & Menús:** Incorporación de menú principal 3D cinematográfico, menú de pausa, gestión de pilas AA, Peronachos y pantalla de carga minimalista.

### 8.2 Guión del Trailer ("Publicidad del Futuro" / Pitch Audiovisual)

* **Duración:** 60 segundos.
* **Estilo:** Metraje encontrado (*Found Footage*), grabado desde una videocámara digital de un estudiante con glitches y estática intermitente.
* **Escena 1 (0:00 - 0:10):**
  * *Visual:* Cámara estática en el Hall Central a oscuras. La estampa "CAM 01 - UTN FRC" parpadea. Afuera se escucha el viento en la Avenida Cruz Roja.
  * *Audio:* Zumbido sordo de transformador. Una voz jadeante susurra: *"Me quedé estudiando en el laboratorio... cerraron todas las salidas..."*
* **Escena 2 (0:10 - 0:25):**
  * *Visual:* El jugador camina por el pasillo del Aula 106. La linterna parpadea. Al fondo, a la luz de una farola de emergencia, se distingue una figura alta de espaldas con saco gris.
  * *Audio:* Un golpe seco de madera contra una mano (*CLAC... CLAC...*).
* **Escena 3 (0:25 - 0:42):**
  * *Visual:* Montaje vertiginoso: el jugador corriendo por las escaleras hacia el Primer Piso; vista desde el interior de un tacho de basura mientras la barra de decibeles sube al rojo; las cadenas oxidadas del Auditorio vibrando fuertemente.
  * *Texto en pantalla con tipografía VHS:* **NOCHE DE EXÁMENES. LA FACULTAD ESTÁ CLAUSURADA. SOLO HAY UNA FORMA DE SALIR.**
* **Escena 4 (0:42 - 0:55):**
  * *Visual:* El jugador toma el diploma del atril del Auditorio. Se da vuelta bruscamente: el Profesor está parado en la puerta tapando la salida. El rostro se distorsiona con estática violenta.
  * *Audio:* Grito distorsionado / regla partiéndose y corte abrupto a negro.
* **Cierre (0:55 - 1:00):**
  * *Visual:* Logotipo oficial en blanco y negro: **UTN FRC: NOCHE DE FINALES**. Subtítulo: *"En la facultad a oscuras... nadie aprueba, nadie sale"*.

---

## 9. Conclusión y Reflexión Crítica

El desarrollo de este entorno virtual demostró que el diseño de experiencias inmersivas no depende exclusivamente de presupuestos multimillonarios o fotogrametría hiperrealista, sino de la **coherencia diegética, la ambientación multisensorial y la resonancia afectiva del espacio**. 

Al arraigar la experiencia en una locación tangible y cotidiana como la UTN FRC, el entorno virtual adquiere una dimensión emocional única: el espacio de estudio y progreso se subvierte en una trampa kafkiana. La integración de la teoría de nuevos medios (inmersión, agencia y transformación) permitió estructurar una jugabilidad sólida donde el jugador no es un mero consumidor de sustos, sino un agente que debe dominar activamente sus sentidos, su voz y su pensamiento lógico para alcanzar la graduación y la libertad.

---

## 10. Referencias

* **Videojuegos de Referencia:**
  * Rayll (2021). *Fears to Fathom: Ironbark Lookout & Norwood Hitchhike*.
  * Konami / Team Silent (2004). *Silent Hill 4: The Room* (Diseño de puertas encadenadas y claustrofobia espacial).
  * Red Barrels (2013). *Outlast* (Uso de videocámara como interfaz subjetiva y gestión de baterías).
* **Entorno Real Modelado:**
  * Edificio Central de la Universidad Tecnológica Nacional - Facultad Regional Córdoba (Avenida Cruz Roja Argentina 200, Ciudad Universitaria, Córdoba, Argentina).

---

## 11. Bibliografía

* **Murray, Janet H.** (1997). *Hamlet on the Holodeck: The Future of Narrative in Cyberspace*. MIT Press. (Capítulos sobre Inmersión, Agencia y Transformación).
* **Schell, Jesse** (2019). *The Art of Game Design: A Book of Lenses*. CRC Press.
* **Godot Engine Documentation** (2024). *Godot 4 3D Scene Architecture, Audio Capture Buses & Shading Reference*.
* **Perron, Bernard** (2009). *Horror Video Games: Essays on the Fusion of Fear and Play*. McFarland & Company.

---

## 12. Anexos

### Anexo A: Tabla Completa de Controles del Usuario

| Acción | Tecla / Control | Descripción Lúdica |
|---|---|---|
| **Moverse** | `W`, `A`, `S`, `D` | Desplazamiento omnidireccional en primera persona |
| **Girar Cámara** | Movimiento de Ratón | Control de orientación y dirección de la linterna |
| **Correr (Sprint)** | `Shift` (sostenido) | Incrementa la velocidad a costa de consumir la barra de estamina |
| **Linterna (Toggle)** | `F` | Enciende / apaga la linterna (consume energía de batería) |
| **Interactuar** | `E` | Recoger exámenes, fusibles, pilas, peronachos y abrir puertas |
| **Ocultarse / Salir** | `E` (frente a tacho) | Ingresar al tacho de basura / abandonar el escondite |
| **Control por Voz** | Micrófono Físico | Detecta ruido ambiente del jugador mientras está oculto |
| **Pausar Partida** | `Escape` | Despliega el menú de pausa con objetivos y opciones |
| **Debug: Ver Coords** | `F3` | Alterna la visualización de coordenadas de depuración 3D |
| **Debug: Copiar Coords** | `F2` | Copia la posición Vector3 actual al portapapeles |

### Anexo B: Catálogo de Ítems e Interacciones Diegéticas

1. **Cuadernos de Parciales de Matemáticas (x4):** Ubicados en Aula 106, Fotocopiadora CEIT, Cafetería PB y Patio del Estudiante. Cada uno presenta un ejercicio de álgebra / análisis matemático que desbloquea el progreso.
2. **Pilas AA:** Dispersas en escritorios de docentes y estantes. Recargan la batería de la linterna y cámara de seguridad.
3. **Paquetes de Peronachos:** Snacks de emergencia en repisas y buffet que regeneran al instante la estamina del jugador.
4. **Fusible de Alta Tensión (30A):** Ubicado en el Primer Piso (Bedelía). Restaura la energía en el Tablero de 220V del Laboratorio de Electrónica.
5. **Llave Maestra del Auditorio:** Obtenida en la Cafetería del 2do Piso para liberar las cadenas del Auditorio.
6. **Título Universitario (Diploma):** Artefacto final situado en el estrado del Auditorio que autoriza legalmente el egreso de la facultad en la puerta de salida.
