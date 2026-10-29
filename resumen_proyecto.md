# Solution Design Document (SDD)
## Documento de Sistematización del Proceso Creativo
### Cátedra: Creatividad y Desarrollo de Entornos Virtuales (CDEV)
**Universidad Tecnológica Nacional – Facultad Regional Córdoba**  
**Carrera:** Ingeniería en Sistemas de Información  
**Año:** 2026 | **Curso:** 5K1 | **Grupo Nro:** 7  

**Docentes:**  
* Prof. Franco Mana  
* Prof. Inés Luz Gimenez Zens  
* Prof. Bruno Aresu Barella  

**Integrantes:**  
* Schurrer, Gabriel Nicolás – Legajo: 95046  
* Maldonado, Franco Gabriel – Legajo: 92123  
* Nóbile, Bruno Nicolás – Legajo: 92098  
* Imwinkelried, Iván – Legajo: 97076  
* Ranieri, Valentina – Legajo: 95985  
* Ramírez, Carlos David – Legajo: 401710  
* Grosso, Gaspar – Legajo: 95123  
* Mottura, Mateo – Legajo: 91154  

---

# UTN FRC: Noche de Finales
### *Entorno Virtual Interactivo de Terror Psicológico y Supervivencia*

---

## 1. Introducción

El presente documento sistematiza el proceso integral de diseño y desarrollo de nuestro entorno virtual interactivo, materializado en el videojuego de terror y supervivencia en primera persona **"UTN FRC: Noche de Finales"**, concebido y desarrollado en **Godot Engine 4.7** (Forward Plus).

La concepción de la idea principal surgió a través de una dinámica grupal de brainstorming estructurado con post-its y matrices de decisión realizada durante la cursada. Dicha actividad permitió contrastar múltiples alternativas lúdicas (como simuladores médicos, mecánicas de cocina, *tower defense* o travesías de trekking). Finalmente, el equipo acordó capitalizar la potencia afectiva y la familiaridad cotidiana del Edificio Central de nuestra propia facultad (**Universidad Tecnológica Nacional - Facultad Regional Córdoba**), transformándolo en un espacio hostil, claustrofóbico y desolado durante un turno nocturno de exámenes finales.

El proyecto articula armónicamente las cuatro dimensiones esenciales de la experiencia interactiva:
1. **Dimensión Técnica:** Motor Godot 4.7 Forward+, físicas de colisión continua con lógica de *step-up*, captura de voz en tiempo real mediante bus de micrófono (`AudioEffectCapture`), inteligencia artificial con máquina de estados finitos (`PATROL`, `SEARCH`, `CHASE`, `ATTACK`) y grafo de navegación multinivel con 91 waypoints.
2. **Dimensión Estética:** Realismo arquitectónico brutalista institucional, iluminación penumbrosa PBR, postprocesado analógico VHS con modo **Visión Nocturna infrarroja** (*Found Footage*) y diseño sonoro espacializado 3D con drones binaurales adaptativos.
3. **Dimensión Narrativa:** *Environmental storytelling*, lore universitario diegético, progresión dramática en cinco actos y simbolismo del examen académico como prueba de supervivencia.
4. **Dimensión Experiencial:** Inmersión sensorial profunda, indefensión psicológica, agencia vinculada al sigilo y al silencio físico en el mundo real, y el recorrido de transformación del alumno pasivo en graduado superviviente.

---

## 2. Organización del Equipo de Diseño (Roles y Responsabilidades)

Para responder a las complejidades técnicas y narrativas del entorno virtual, el equipo definió una estructura orgánica asignando responsabilidades puntuales a cada integrante:

* **Liderazgo y Gestión:**
  * **Iván Imwinkelried – Producer:** Encargado de la planificación, coordinación y gestión del proyecto, asegurando que el equipo cumpla con los plazos, cronogramas y objetivos pedagógicos establecidos.
* **Dirección Creativa y Técnica:**
  * **Mateo Mottura & Gabriel Schurrer – Creative & Technical Directors:** Asumen conjuntamente la visión conceptual, dirección general del juego y las decisiones críticas sobre la arquitectura técnica y la integración de sistemas en Godot Engine.
* **Diseño de Entornos y Nivel (Level Design):**
  * **Franco Maldonado, Bruno Nóbile & Valentina Ranieri – Level Designers:** Encargados de estructurar los espacios cerrados, el flujo de exploración y los desafíos que generarán el terror en el usuario a lo largo de las tres plantas del edificio (PB, P1 y P2).
* **Programación y Desarrollo Técnico:**
  * **Carlos Ramírez – Lead Gameplay Programmer:** A cargo de la programación y el desarrollo técnico general: controles en primera persona, físicas, interacción con objetos del mapa (`RayCast3D`), sistema de inventario, detección de micrófono en tiempo real e integración de recursos dentro del motor.
* **Arte, Estética y Sonido:**
  * **Bruno Nóbile & Valentina Ranieri – Art & Sound Directors:** Responsables de la dirección de arte, texturas PBR institucionales (granito, machimbre, metales cepillados, placas acrílicas), shaders analógicos VHS / Visión Nocturna y diseño sonoro envolvente para transmitir atmósfera de tensión y suspenso.
* **Narrativa y Construcción de Mundo:**
  * **Equipo Completo – Narrative Designers:** Co-creación de la historia, el lore ambiental, los problemas matemáticos dinámicos de los parciales y los documentos diegéticos institucionales.
* **Operaciones, Calidad y Pruebas (QA):**
  * **Franco Maldonado & Gaspar Grosso – QA Leads:** Ejecución de pruebas funcionales en detalle, detección de colisiones anómalas, balanceo de los umbrales de decibeles del micrófono y verificación de las rutinas anti-atascamiento del antagonista.

---

## 3. Aspectos Generales del Diseño

### 3.1 Reto de Diseño
*¿Cómo transformar un edificio universitario real, transitado a diario por miles de estudiantes, en un entorno virtual inmersivo de terror psicológico y supervivencia, logrando que los desafíos académicos (rendir parciales, descifrar esquemas eléctricos, obtener el diploma) y el control corporal del usuario (guardar silencio real en su habitación frente al micrófono) sean los mecanismos determinantes de escape?*

### 3.2 Problema, Necesidad o Motivación (Dimensión Emocional)
* **Resignificación de lo cotidiano:** Generar una experiencia de miedo, tensión y suspenso. Al tomar la facultad como escenario principal, la motivación central radica en transformar un entorno institucional conocido y seguro en un espacio hostil, generando incomodidad e inmersión a través de lo familiar.
* **Sublimación del estrés académico:** La angustia de rendir finales, el desvelo nocturno y la presión por recibirse se transmutan en las reglas de juego: el profesor exigente se convierte en el cazador supremo y el Título Universitario es el único salvoconducto que autoriza la salida.
* **Vulnerabilidad e indefensión:** Se despoja al avatar de armas de fuego; el jugador depende exclusivamente de su sigilo, de la gestión de baterías para la visión nocturna de su cámara, de su estamina física (recargable con snacks *Peronachos*) y de su autocontrol acústico frente al micrófono.

### 3.3 Público Objetivo
* **Comunidad Estudiantil y Universitaria:** Alumnos, docentes y graduados (particularmente de la UTN FRC y carreras tecnológicas) con alta identificación con la arquitectura y el lenguaje del campus.
* **Jugadores de Terror y Supervivencia Indie:** Aficionados a obras de suspenso en primera persona (*Fears to Fathom*, *Silent Hill*, *Outlast*) y estéticas analógicas de metraje encontrado (*Found Footage*).

### 3.4 Características Generales
* **Género:** Psychological Survival Horror / Stealth en primera persona.
* **Perspectiva:** Cámara subjetiva (POV) con balanceo dinámico y estética de videocámara personal.
* **Plataforma:** PC (Windows / Linux).
* **Motor:** Godot Engine 4.7 Forward+.

### 3.5 Objetivos Alineados con la Estrategia CDEV
* Desarrollar un prototipo interactivo funcional en Godot 4 que demuestre la viabilidad de mecánicas inmersivas innovadoras (detección de voz en vivo).
* Consolidar la coherencia diegética eliminando elementos arcade abstractos en favor de señalética y utilería universitaria real.
* Aplicar el marco teórico de Janet Murray articulando Inmersión, Agencia y Transformación.

---

## 4. Proceso Creativo y Brainstorming Realizado en Clase

Durante la clase del **4 de Septiembre**, el equipo realizó la actividad formal de **Brainstorming** para generar ideas originales, explorar temáticas y definir el género del entorno virtual. La dinámica se apoyó en una **Matriz de Dos Ejes (Viabilidad Técnica vs. Originalidad)** y votación democrática con post-its.

```
       ▲ Alta Viabilidad
       │
       │   [Juego Incremental]     ★ [La Facu del Terror] (SELECCIONADA)
       │   [Simulador de Autos]      [Recorrido Trekking Sierras]
       │   [Juego de Cocina]         [Base Militar y Extraterrestre]
       │
───────┼─────────────────────────────────────────────────────────────► Alta Originalidad
       │
       │   [Médicos en Guardia]      [Expedición Antártida]
       │   [Pac-Man del Terror]      [Juego Experiencias Inversas]
       │   [Mundo Animal POV]        [Tower Defense Medieval Fantástico]
       ▼ Baja Viabilidad
```

### Ideas Evaluadas en los Post-Its:
* **La Facu del Terror (Ganadora):** Simulación de terror en el campus de la facultad con progresión por parciales, aparición del profesor, corte de luz y supervivencia con riesgo de reprobar y quedar atrapado.
* **Juego de Cocina por Etapas:** Limpieza, empanado y fritura interactiva de langostinos paso a paso.
* **Base Militar Infiltrada:** Comienzo con pistola y munición limitada; descubrimiento de un secreto alienígena bajo tierra.
* **Auto Varado en el Bosque:** Accidente nocturno en la niebla y búsqueda de rescate cruzando un bosque oscuro.
* **Juego de Gacha / Apuestas:** Objetos con 5% de probabilidad de éxito y decisiones de probabilidad acumulativa.
* **Simulador de Autos Realista:** Prueba de manejo (*drive test*) enfocado en físicas de aceleración reales.
* **Juego de Experiencias Inversas:** Cambios perceptivos donde cada color y objeto se comporta de forma contraria a lo esperado (rojo bueno, verde malo).
* **Tower Defense Medieval:** Defensa estratégica con magia y ciencia ficción.
* **Médico Clínico en Guardia:** Simulación hospitalaria de decisiones éticas y de triaje bajo presión de reloj.
* **Trekking por las Sierras de Córdoba:** Recorrido con atajos, senderos y cartelería informativa.
* **Expedición en la Antártida:** Misión científica en terreno glaciar narrada mediante transmisiones de podcast.

---

## 5. Dimensión Técnica y Arquitectura del Entorno

### 5.1 Motor y Pipeline Tecnológico
Para el desarrollo interactivo se seleccionó **Godot Engine 4 (Standard / Forward+)**, aprovechando su alta compatibilidad, ligereza y el uso de **GDScript 2.0**, lo cual permitió un desarrollo ágil y orientado a objetos.

### 5.2 Diseño de Nivel Híbrido (De 2D a Geometría 3D)
El diseño del nivel comenzó con la elaboración de un plano bidimensional utilizando la herramienta **diagrams.net**. Este esquema estructuró la distribución arquitectónica del Edificio Central (aulas 101 a 115, pasillos perimetrales, patio del estudiante, cafetería, fotocopiadora y auditorio) estableciendo una escala métrica de referencia (**1 celda = 2 metros**). 

Este mapa conceptual sirvió como base para una transición directa a Godot 4, donde se proyectó la geometría 3D mediante nodos de Geometría Sólida Constructiva (**CSG**), respetando estrictamente las proporciones, rutas de escape, líneas de visión y puntos ciegos planificados en la etapa 2D, sobre los cuales se integraron posteriormente modelos `.glb` y utilería institucional.

### 5.3 Mecánica de Reconocimiento de Voz (`scripts/mic_detector.gd`)
A través del bus de audio nativo `Record` configurado con el efecto `AudioEffectCapture`, el sistema capta el audio de entrada del micrófono físico del usuario (ruido ambiente, respiración agitada o gritos) y calcula su nivel RMS traduciéndolo a decibeles.
* **Activación Diegética:** La detección por micrófono se activa **al esconderse dentro de los tachos de basura** de la facultad.
* **Comportamiento Reactivo y Tensión:** Si el Profesor pasa a menos de 7.5 metros de un tacho ocupado, se detiene a inspeccionarlo (*"Sé que estás por acá..."*, *"Puedo oler el miedo a desaprobar..."*). Si durante este momento o en cualquier instante el nivel de ruido en la habitación del jugador supera el umbral de peligro (`danger_threshold`), la barra del HUD se satura en rojo y el Profesor grita (*"¡¡TE ESCUCHÉ EN ESE TACHO, NO TE VAS A ESCAPAR!!"*), corre a máxima velocidad hacia el contenedor, expulsa al jugador a la fuerza (`force_eject`) y descarga su ataque. Si el jugador mantiene silencio absoluto, el docente retoma su patrullaje.

### 5.4 Físicas, Desplazamiento y Escaleras
* Se implementó una lógica de *step-up* y rampas de colisión invisibles (`StaticBody3D`) sobre las 3 torres de escaleras en U (Oeste, Este y Norte), permitiendo un desplazamiento vertical continuo y sin tropiezos.
* Controlador del avatar (`scripts/player.gd`) con inercia física, balanceo de cabeza dinámico, consumo de estamina al correr con `Shift`, raycast frontal de interacción unificada con la tecla `E`, recarga de estamina consumiendo snacks con `Q`, y recarga de batería de la cámara con `R`.

---

## 6. Análisis de Actores del Entorno

### 6.1 Usuario Primario (El Alumno)
Controla al avatar en primera persona, interactuando en las sombras con recursos limitados. Su visión en la oscuridad depende del modo de **Visión Nocturna de su videocámara** (activado con `F` o Click Derecho), cuya batería decae de forma continua y requiere recolectar y colocar **Pilas AA** (`R`). Su capacidad de carrera prolongada depende de su barra de estamina, recargable con paquetes de **Peronachos** (`Q`).

### 6.2 El Profesor (Enemigo e Inteligencia Artificial)
La toma de decisiones del Profesor está gobernada por una Máquina de Estados Finitos (`scripts/profesor.gd`) y un sistema de navegación multinivel con **91 waypoints interconectados**:
* **Momento de Aparición:** **Al aprobar el segundo (2°) examen parcial**, el Profesor se manifiesta en el mapa alertado por el ruido de las hojas (*"¡El profesor escuchó las hojas! Salió a patrullar la Planta Baja..."*). En esta fase, **la iluminación general aún se encuentra encendida**, obligando al jugador a rendir los parciales restantes evitando activamente al docente en los pasillos de Planta Baja.
* **Estados de Comportamiento:**
  1. `[PATROL]` *(Patrulla)*: El enemigo navega metódicamente a velocidad estándar recorriendo la red de waypoints en busca de alumnos.
     * *Transición:* Si capta un ruido fuerte a través del micrófono o detecta al jugador en su campo visual, pasa a Búsqueda o Cacería.
  2. `[SEARCH]` *(Búsqueda)*: El Profesor se dirige a las coordenadas exactas de la anomalía sonora. Al llegar, inspecciona y escanea la zona durante unos segundos.
     * *Transición:* Si no detecta presencia, regresa a Patrulla. Si establece línea de visión directa mediante `RayCast3D`, transiciona a Cacería.
  3. `[CHASE]` *(Cacería / Persecución)*: Fase de persecución agresiva con incremento de velocidad hacia la posición del jugador, acompañada de música de persecución con cuerdas/violines estridentes.
     * *Transición:* Si el jugador dobla una esquina, entra a un tacho de basura y mantiene silencio físico real, la IA pierde el rastro y regresa a Búsqueda en la última ubicación confirmada.
  4. `[ATTACK]` *(Ataque con Regla)*: Al alcanzar al jugador (rango <= 1.8m), descarga un violento golpe con su regla de madera de pizarrón al grito de *"¡¡¡CASTIGO POR COPIARSE!!!"*, aplicando un fuerte impulso de retroceso físico (`velocity push`) y sacudida traumática de cámara, dándole una última oportunidad al jugador para huir y esconderse.
* **Fase Enfurecida (Apagón):** Al aprobarse el 4to examen y saltar los disyuntores, el profesor entra en fase enfurecida (*Enraged Phase*), aumentando su velocidad, su volumen de pasos y su rango de búsqueda.

### 6.3 El Edificio Central (Entorno Hostil Activo)
Opera como un antagonista silencioso: sus escaleras se encuentran selladas por barreras institucionales hasta aprobar los exámenes, la energía colapsa al completar los cuatro parciales y las puertas de egreso están legalmente clausuradas por las Autoridades FRC.

---

## 7. Narrativa Inmersiva y Perspectiva del Usuario

### 7.1 Storytelling y Recorrido del Usuario en 5 Actos
La narrativa emerge directamente del entorno (*environmental storytelling*) sin cinemáticas invasivas, estructurada en un flujo de tensión creciente:
* **Acto I – La Convocatoria a Examen (Planta Baja con Luz):** El alumno ingresa al Hall de Entrada. Las tres escaleras están selladas con barreras energéticas (*"PISO SUPERIOR CERRADO - Aprobá los 4 parciales"*). El objetivo es explorar PB para rendir 4 parciales de matemáticas distribuidos en Aula 106, Fotocopiadora CEIT, Cafetería PB y Patio del Estudiante. Cada cuaderno plantea problemas matemáticos universitarios de opción múltiple; si el alumno responde mal, el Profesor se enfurece y acelera su velocidad (`boost_speed`).
* **Acto II – El Despertar del Profesor (Segundo Parcial):** Al aprobar el **2do examen**, el Profesor despierta y sale a patrullar la Planta Baja. Con las luces aún encendidas, el alumno debe resolver con sigilo el 3er y 4to examen esquivando al docente.
* **Acto III – El Colapso de la Red y las Escaleras Habilitadas (Cuarto Parcial):** Al aprobar el **4to examen**, saltan los disyuntores y se produce el **Apagón General**. Se ejecuta el susto cinemático del giro de 180° en el pasillo, caen las barreras de las escaleras y se vuelve obligatoria la **Visión Nocturna (`F`)**. El objetivo pasa a ser subir al Primer Piso a buscar el **Fusible de Alta Tensión (30A)** en Bedelía, guiado por la pizarra didáctica de P1.
* **Acto IV – Restauración Eléctrica, Emboscada y Cafetería P2:** El jugador desciende a PB al Departamento de Ingeniería Electrónica y coloca el fusible en el Tablero General de 220V. Al conectarlo, se produce un evento de emboscada: las luces del laboratorio parpadean una a una en fila y el Profesor aparece recortado a contraluz en la puerta de salida cargando a toda velocidad contra el jugador. Tras eludirlo y salir del laboratorio, el nuevo objetivo lo guía a la Cafetería del 2do Piso a recuperar la **Llave Maestra del Auditorio**.
* **Acto V – El Auditorio Encadenado y el Egreso:** Con la llave, el jugador desciende al Auditorio Central (cerrado con cadenas y candados estilo *Silent Hill 4*), libera la puerta y recoge del atril el **Título Universitario (Diploma)**, desatando la furia final del docente (*"¡¿QUIÉN TE DIO ESE TÍTULO?! ¡DEVOLVELO!"*). Con el diploma en mano, corre a la Puerta Principal vidriada, rompe la clausura de las Autoridades FRC y escapa con vida.

### 7.2 Marco Teórico de Janet Murray (*Hamlet en la Holocubierta*)
* **Inmersión:** Definida como la construcción activa de la creencia y suspensión voluntaria de la incredulidad. Se logra mediante la reproducción a escala del edificio real de la UTN FRC, el diseño sonoro 3D envolvente y la integración biomecánica del micrófono, donde el espacio físico de la habitación del jugador se fusiona con la simulación virtual.
* **Agencia:** Es la posibilidad real de influir en el mundo interactivo y obtener consecuencias inmediatas. El usuario elige sus rutas de escape, administra la batería de su cámara mediante pilas AA (`R`), gestiona su estamina mediante Peronachos (`Q`) y controla conscientemente su propia respiración; cualquier emisión de sonido delata su posición ante la IA.
* **Transformación:** Capacidad del medio interactivo para transformar el espacio y al sujeto. El juego subvierte un espacio educativo diurno y familiar en una pesadilla claustrofóbica. En paralelo, el usuario atraviesa una transformación psicológica: de estudiante vulnerable y temeroso muta a superviviente graduado que conquista su título y su libertad.

### 7.3 Perspectiva del Usuario (Flujo y POV)
* **Cámara en Primera Persona (POV):** A la altura visual humana (1.70 m), con balanceo cefálico realista al caminar y trotar.
* **HUD Diegético de Videocámara con Visión Nocturna:** Interfaz inspirada en cintas VHS / Bodycam con fechador y reloj institucional (`CAM 01 - UTN FRC | 00:02:15`), medidor de batería porcentual, punto de grabación `REC` parpadeante, viñeta analógica y modo de visión nocturna de fósforo verde.

---

## 8. Diseño Multisensorial y Estética Visual

### 8.1 Estética Visual y Fidelidad Institucional
* **Materiales PBR:** Texturas que replican los materiales característicos del edificio: pisos de mosaico granítico pulido, zócalos de machimbre barnizado en el tercio inferior de los muros, marcos de aluminio y cielorrasos técnicos.
* **Diegesis Visual Absoluta:**
  * Reemplazo de textos flotantes arcade por **50 placas institucionales acrílico-metálicas** atornilladas en las paredes al lado del marco de cada aula y oficina, con sombreado real y bisel reflectivo (`shaded = true`).
  * Puerta del Auditorio bloqueada por un entramado tridimensional procedural de **cadenas metálicas oxidadas y candados dorados macizos** inspirados en *Silent Hill 4: The Room*.
  * Cartel de clausura en la puerta de salida principal diseñado como una hoja blanca de papel institucional A4 con tipografía sobria y firma al pie de las "AUTORIDADES FRC".

### 8.2 Diseño Sonoro Híbrido
* **Sintetizador Procedural de Terror (`scripts/horror_audio.gd`):** Módulo de audio que genera drones sub-graves de baja frecuencia (30-60 Hz) que inducen una sensación física de angustia e inquietud.
* **Audio Espacial 3D:** Pasos sobre granito con atenuación cuadrática, crujido de puertas de chapa, zumbido de balasto de 50 Hz en luminarias fluorescentes y los chasquidos rítmicos de la regla de madera del profesor azotando pupitres.
* **Latidos Cardíacos Dinámicos:** Modulados en frecuencia y volumen según la cercanía y el nivel de agresividad del enemigo.

### 8.3 Dispositivos de Interacción y Consumibles
* **Esquema de Control:** Teclado (`W`, `A`, `S`, `D`) y ratón para locomoción y vista; tecla `Shift` para sprint administrando la estamina física; tecla `F` (o Click Derecho) para Visión Nocturna; tecla `R` para recargar batería de cámara con Pilas AA; tecla `Q` para comer Peronachos y tecla `E` para interactuar.
* **Pilas AA:** Dispersas en escritorios de docentes y estantes para recargar la batería de la videocámara y evitar la oscuridad absoluta.
* **Snacks "Peronachos":** Bolsas de chips modeladas en 3D sobre repisas y buffets que regeneran de forma instantánea la barra de estamina tras persecuciones intensas.

---

## 9. Proceso de Prototipado y Evolución

### 9.1 Fases Evolutivas del Prototipo
1. **Fase I – Prototipado 2D (diagrams.net):** Planimetría del Edificio Central a escala métrica (1 celda = 2 m) delimitando pasillos, aulas, patio y accesos.
2. **Fase II – Greyboxing en Godot 4 (CSG):** Levantamiento tridimensional con CSGBoxes para validar distancias de carrera, líneas de visión y escaleras.
3. **Fase III – Progresión de Exámenes y Aparición de la IA:** Programación de los 4 cuadernos de matemáticas; activación de la patrulla del Profesor al 2do parcial y corte general de luz al 4to parcial con susto de giro 180°.
4. **Fase IV – Mecánica Innovadora de Micrófono & Tachos:** Integración del bus `AudioEffectCapture`, suspensión de respiración y calibración del umbral de decibeles al esconderse en contenedores.
5. **Fase V – Limpieza Diegética Institucional:** Eliminación de carteles flotantes; creación de las 50 placas metálicas fijadas a muro, cadenas tridimensionales de auditorio y cartel de clausura formal.
6. **Fase VI – UX/UI y Menús Profesionales:** Implementación del Menú Principal 3D con paneo de cámara cinemático en tiempo real, Menú de Pausa diegético, gestión de Pilas AA / Peronachos y pantalla de carga minimalista.

### 9.2 Guión del Trailer Promocional ("Publicidad del Futuro")
* **Duración:** 60 segundos | **Estilo:** Metraje Encontrado (*Found Footage*) con distorsión VHS y Visión Nocturna.
* **0:00 - 0:12 | Escena 1 (La Calma Nocturna):**  
  * *Visual:* Cámara estática en el Hall de Entrada desierto. El fechador digital titila: `CAM 01 - UTN FRC | 23:48:12`. Viento suave agitando los árboles del Patio del Estudiante a través de los ventanales.  
  * *Audio:* Zumbido sordo de transformador. Voz en off ahogada: *"Cerraron las rejas... dijeron que nadie sale sin rendir..."*
* **0:12 - 0:26 | Escena 2 (El Pasillo de las Aulas):**  
  * *Visual:* Haz de visión nocturna verde barriendo las placas metálicas de las aulas 104, 105, 106. Una silueta alta de espaldas con traje gris y corbata roja se perfila al final del pasillo.  
  * *Audio:* El chasquido rítmico e inconfundible de una regla de madera: *CLAC... CLAC... CLAC...*
* **0:26 - 0:42 | Escena 3 (El Asedio y el Silencio):**  
  * *Visual:* El jugador corre desesperado escaleras arriba hacia el Primer Piso. Se mete en un tacho de basura. En pantalla, el medidor de decibeles del micrófono sube peligrosamente mientras se escuchan pasos pesados deteniéndose exactamente frente al contenedor. El profesor asoma su rostro por la rendija susurrando: *"Sé que estás por acá..."*.  
  * *Audio:* Respiración agitada, crujido de metal y estática violenta.
* **0:42 - 0:54 | Escena 4 (El Clímax en el Auditorio):**  
  * *Visual:* Las cadenas de la puerta del Auditorio caen al piso. El jugador sube al escenario y levanta el Diploma Universitario. Al girar bruscamente la cámara hacia la salida, el Profesor se abalanza en carrera con el rostro desencajado.  
  * *Audio:* Alarido distorsionado, golpe estridente de regla y corte abrupto de señal a pantalla negra.
* **0:54 - 1:00 | Cierre:**  
  * *Visual:* Logotipo institucional en blanco sobre negro: **UTN FRC: NOCHE DE FINALES**.  
  * *Texto:* *"En la facultad a oscuras... nadie aprueba, nadie sale"*.

---

## 10. Conclusión

El desarrollo de **"UTN FRC: Noche de Finales"** demuestra cómo la articulación planificada entre creatividad, rigor técnico y teoría de nuevos medios permite transformar una vivencia cotidiana en una experiencia virtual inmersiva de alto impacto emocional. 

La utilización del propio espacio universitario no funcionó como mero decorado estético, sino como el núcleo de la tensión dramática: la familiaridad del edificio potenció el extrañamiento y la indefensión. La introducción de dinámicas no convencionales —como la necesidad de guardar silencio físico real frente al micrófono de la computadora— desdibujó los límites entre el entorno del usuario y el mundo simulado, consolidando un entorno interactivo original, técnicamente eficiente y plenamente coherente con los objetivos pedagógicos y creativos de la cátedra CDEV.

---

## 11. Referencias

* **Videojuegos y Obras de Referencia:**
  * Rayll (2021-2023). *Fears to Fathom: Ironbark Lookout & Norwood Hitchhike* (Terror analógico y horror cotidiano).
  * Konami / Team Silent (2004). *Silent Hill 4: The Room* (Mecánica y atmósfera de puertas selladas con cadenas).
  * Red Barrels (2013). *Outlast* (Uso de videocámara con visión nocturna, baterías limitadas y vulnerabilidad del protagonista).
* **Entorno Arquitectónico de Base:**
  * Edificio Central de la Universidad Tecnológica Nacional - Facultad Regional Córdoba (Avenida Cruz Roja Argentina 200, Ciudad Universitaria, Córdoba, Argentina).

---

## 12. Bibliografía

* **Murray, Janet H.** (1997). *Hamlet on the Holodeck: The Future of Narrative in Cyberspace*. The MIT Press.
* **Schell, Jesse** (2019). *The Art of Game Design: A Book of Lenses*. CRC Press / Taylor & Francis Group.
* **Perron, Bernard** (2009). *Horror Video Games: Essays on the Fusion of Fear and Play*. McFarland & Company.
* **Godot Engine Community & Contributors** (2024). *Godot Engine 4.7 Documentation: 3D Rendering, Audio Busses & Physics Architecture*.

---

## 13. Anexos

### Anexo A: Mapeo de Controles del Usuario

| Acción | Dispositivo / Tecla | Función en el Entorno |
|---|---|---|
| **Desplazamiento** | `W`, `A`, `S`, `D` | Movimiento omnidireccional en primera persona |
| **Control de Mirada** | Ratón | Orientación de cámara y dirección de visión nocturna |
| **Esprintar (Correr)** | `Shift` (mantenido) | Incremento de velocidad con consumo de estamina |
| **Visión Nocturna** | `F` / Click Der / `N` | Activa/desactiva la visión nocturna infrarroja de la cámara |
| **Recargar Batería Cámara**| `R` | Consume una Pila AA para recargar la videocámara (+50%) |
| **Consumir Peronachos** | `Q` | Consume un snack para regenerar estamina al 100% al instante |
| **Interacción General** | `E` | Recoger exámenes, pilas, fusibles, Peronachos y puertas |
| **Ocultamiento** | `E` (frente a tacho) | Ingresar al contenedor / salir del escondite |
| **Sensor de Silencio** | Micrófono físico | Medición de decibeles en tiempo real mientras se está oculto |
| **Pausa y Objetivos** | `Escape` | Despliega menú de pausa con lista de objetivos y audio |
| **Debug: Ver Coordenadas** | `F3` | Muestra posición espacial Vector3 en pantalla |
| **Debug: Copiar Coords** | `F2` | Copia coordenadas actuales al portapapeles |

### Anexo B: Catálogo de Ítems e Interacciones Diegéticas

1. **Cuadernos de Examen (x4):** Formularios matemáticos de opción múltiple en Aula 106, Fotocopiadora CEIT, Cafetería PB y Patio del Estudiante. Errar la respuesta acelera al docente.
2. **Pilas AA:** Baterías cilíndricas en escritorios y estantes; recargan la batería de la videocámara con la tecla `R`.
3. **Snacks "Peronachos":** Bolsas de chips 3D en buffets y repisas; se consumen con la tecla `Q` para restaurar la estamina.
4. **Fusible de Alta Tensión (30A):** Componente industrial en Bedelía (P1) para alimentar el Tablero de 220V del Laboratorio de Electrónica.
5. **Llave Maestra del Auditorio:** Llave antigua en la Cafetería del 2do Piso para liberar las cadenas del Auditorio.
6. **Título Universitario (Diploma):** Artefacto final en el estrado del Auditorio que autoriza legalmente la salida del campus en la puerta principal.
