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

El presente documento sistematiza el proceso integral de diseño y desarrollo de nuestro entorno virtual interactivo, materializado en el videojuego de terror y supervivencia en primera persona **"UTN FRC: Noche de Finales"**, concebido en **Godot Engine 4.7** (Forward Plus).

La concepción de la idea principal se originó a través de dinámicas de creatividad grupal y brainstorming estructurado mediante matrices de viabilidad e ideas (post-its). Dicho proceso nos permitió explorar y contrastar múltiples propuestas de géneros (tales como *tower defense*, cocina interactiva, simulación médica y exploración de trekking). Tras una evaluación crítica, el equipo acordó capitalizar la potencia afectiva y la familiaridad cotidiana del Edificio Central de nuestra propia facultad (**Universidad Tecnológica Nacional - Facultad Regional Córdoba**), transformándolo en un espacio hostil, claustrofóbico y desolado durante un turno nocturno de exámenes finales.

El proyecto articula armónicamente las cuatro dimensiones esenciales de la experiencia interactiva:
1. **Dimensión Técnica:** Motor Godot 4.7, físicas de colisión continua, reconocimiento de voz en tiempo real mediante bus de captura de micrófono, máquina de estados finitos e IA con grafo de 91 waypoints multinivel.
2. **Dimensión Estética:** Realismo arquitectónico brutalista institucional, iluminación penumbrosa PBR, postprocesado con estética analógica VHS / *Found Footage* y diseño sonoro espacializado 3D con drones adaptativos.
3. **Dimensión Narrativa:** *Environmental storytelling*, lore universitario diegético, progresión en cinco actos y simbolismo del examen académico como prueba de supervivencia.
4. **Dimensión Experiencial:** Inmersión sensorial profunda, indefensión psicológica, agencia vinculada al sigilo y al silencio físico en el mundo real, y el recorrido de transformación del alumno pasivo en graduado superviviente.

---

## 2. Organización del Equipo de Diseño (Roles y Responsabilidades)

Para optimizar el flujo de trabajo y responder a las complejidades técnicas y artísticas del proyecto, se asignaron roles especializados basados en las competencias de los integrantes:

* **Liderazgo y Gestión:**
  * **Iván Imwinkelried – Producer:** Planificación general, gestión de cronograma, seguimiento de hitos, coordinación de entregables de cátedra y aseguramiento de objetivos entre las distintas áreas.
* **Dirección Creativa y Técnica:**
  * **Mateo Mottura & Gabriel Schurrer – Creative & Technical Directors:** Definición de la visión conceptual del juego, decisiones críticas sobre la arquitectura técnica en Godot Engine, supervisión del pipeline de integración y coherencia lúdico-narrativa.
* **Diseño de Entornos y Nivel (Level Design):**
  * **Franco Maldonado, Bruno Nóbile & Valentina Ranieri – Level Designers & World Builders:** Estructuración espacial de las 3 plantas del Edificio Central (Planta Baja, Primer Piso, Segundo Piso), distribución de aulas, pasillos, galerías, patio interior y auditorio; balance de rutas de escape, escondites estratégicos y puntos de tensión.
* **Programación y Desarrollo Técnico:**
  * **Carlos Ramírez – Lead Gameplay & Systems Programmer:** Programación del controlador del jugador en primera persona, físicas, sistema de interacción con objetos (`RayCast3D`), lógica de inventario, implementación de la captura de micrófono en tiempo real e integración de recursos dentro del motor.
* **Arte, Estética y Sonido:**
  * **Bruno Nóbile & Valentina Ranieri – Art & Sound Directors:** Dirección de arte visual, modelado y texturizado PBR institucional (granito, maderas, metales cepillados, placas acrílicas), shaders analógicos VHS, así como la captura, mezcla y musicalización procedural de la atmósfera sonora de terror.
* **Narrativa y Construcción de Mundo:**
  * **Equipo Completo – Narrative Designers:** Co-creación del guión, diseño de los acertijos matemáticos de los parciales, redacción de documentos diegéticos (comunicado de clausura de Autoridades FRC, notas de bedelía) y construcción del lore ambiental.
* **Control de Calidad (QA) y Pruebas de Usuario:**
  * **Franco Maldonado & Gaspar Grosso – QA Leads & Testers:** Ejecución de pruebas exhaustivas de jugabilidad, detección de colisiones anómalas, balanceo de los umbrales de decibeles del micrófono y verificación de las rutinas anti-atasco de la inteligencia artificial.

---

## 3. Aspectos Generales del Diseño

### 3.1 Reto de Diseño
*¿Cómo convertir un entorno universitario cotidiano y seguro en una experiencia virtual inmersiva de horror psicológico, logrando que las mecánicas académicas (rendir parciales, descifrar planos, obtener el título) y la respuesta biológica del usuario (guardar silencio real en su habitación) sean el eje de la supervivencia?*

### 3.2 Problema, Necesidad o Motivación (Dimensión Emocional)
* **Tensión por resignificación de lo cotidiano:** El terror más efectivo no proviene de monstruos fantásticos ajenos, sino de la distorsión de lo familiar (*lo siniestro* freudiano). Pasillos transitados habitualmente por miles de alumnos se vuelven oscuros, solitarios y opresivos.
* **Paranoia y estrés académico sublimado:** La angustia real que experimenta el estudiante ante los exámenes finales, la exigencia desmedida de las cátedras y el miedo a quedar "atrapado" recursando se convierten en el catalizador metafórico del juego: si no aprobás y no conseguís tu título habilitante, no salís.
* **Vulnerabilidad e indefensión:** Se despoja al jugador de toda mecánica de combate; solo dispone de su capacidad de observación, el manejo austero de sus pilas y el autocontrol corporal (su respiración frente al micrófono).

### 3.3 Público Objetivo
* **Comunidad Universitaria:** Estudiantes, egresados y docentes (principalmente de UTN y carreras universitarias afines) que reconocen al instante la arquitectura, señalética y costumbres del campus.
* **Jugadores de Terror y Supervivencia Indie:** Aficionados a experiencias en primera persona tipo *Fears to Fathom*, *Silent Hill*, *Outlast* y narrativas analógicas de *Found Footage*.

### 3.4 Características Generales
* **Perspectiva:** Primera persona (POV) con balanceo corporal y estética de videocámara personal.
* **Plataforma:** PC (Windows / Linux).
* **Motor:** Godot Engine 4.7 Forward+.
* **Modo de juego:** Un solo jugador, rejugable por rutas de sigilo y aleatorización de patrulla.

### 3.5 Objetivos Alineados con la Estrategia CDEV
* Aplicar metodologías de diseño y creatividad (brainstorming, prototipado rápido, matrices de decisión).
* Implementar interfaces innovadoras y computación física/auditiva (reconocimiento de audio en vivo mediante micrófono).
* Articular rigurosamente el marco teórico de nuevos medios (Janet Murray) con una implementación funcional verificable.

---

## 4. Proceso Creativo y Brainstorming Realizado en Clase

Durante la jornada del **4 de Septiembre**, el equipo llevó a cabo un taller estructurado de creatividad utilizando la técnica de **Brainstorming con Post-Its**, complementado con una **Matriz de Dos Ejes (Viabilidad Técnica vs. Originalidad de la Idea)** para evaluar y clasificar las propuestas.

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

### Registro de Propuestas Evaluadas en los Post-Its:
1. **La Facu del Terror (Ganadora):** Simulación de terror en el edificio de la facultad con objetivos claros, niveles de exploración, aparición paulatina del profesor y riesgo de reprobar y quedar atrapado.
2. **Juego de Cocina por Etapas:** Limpieza, empanado y fritura interactiva paso a paso de langostinos.
3. **Infiltración en Base Militar:** Comienzo con pistola y munición limitada; descubrimiento de un secreto alienígena bajo tierra.
4. **Auto Varado en el Bosque:** Accidente en noche de niebla; cruce del bosque tenebroso para buscar auxilio.
5. **Juego de Apuestas / Gacha:** Objetos con 5% de probabilidad de mejora y toma de decisiones numéricas.
6. **Simulador de Autos Realista:** Prueba de manejo (*drive test*) con aceleraciones y físicas mecánicas fidedignas.
7. **Juego de Experiencias Inversas:** Cambios de roles perceptivos basados en asociaciones visuales opuestas (rojo bueno, verde malo).
8. **Tower Defense Medieval:** Defensa con ambientación mágica de ciencia ficción.
9. **Médico Clínico en Guardia:** Gestión de decisiones éticas y de triaje con consecuencias permanentes.
10. **Trekking por las Sierras de Córdoba:** Recorrido con atajos y senderos con carteles informativos.
11. **Expedición en la Antártida:** Misión científica en terreno gélido con transmisión por podcast.

**Conclusión del Brainstorming:** La propuesta de **"La Facu del Terror"** obtuvo la mayor ponderación por su máxima originalidad conceptual, su fuerte vínculo de identidad comunitaria y su alta viabilidad técnica en Godot 4 aprovechando la planimetría real del campus.

---

## 5. Dimensión Técnica y Arquitectura del Entorno

### 5.1 Motor y Pipeline Tecnológico
* **Godot Engine 4.7 (Standard / Forward+):** Seleccionado por su arquitectura ligera, tiempos de compilación inmediatos, robustez en el renderizado 3D moderno (soporte de luces sombreadas PBR, SSAO, niebla volumétrica y reflejos en espacio de pantalla) y desarrollo ágil en GDScript 2.0 orientado a objetos.

### 5.2 Arquitectura del Sistema de Entrada por Micrófono (`scripts/mic_detector.gd`)
* Configuración en `default_bus_layout.tres` de un bus de audio independiente llamado `Record` equipado con el efecto nativo `AudioEffectCapture`.
* Captura de los paquetes PCM del micrófono físico del jugador en tiempo de ejecución.
* Conversión algorítmica del buffer de audio a valores RMS y mapeo a escala de decibeles normalizada (0.0 a 1.0).
* **Lógica reactiva:** El micrófono permanece activo durante el ocultamiento en los tachos de basura. Si el nivel sobrepasa el umbral seguro (`danger_threshold = 0.55`), se notifica a la máquina de estados del Profesor (`profesor.gd`), quien interrumpe su patrullaje e inicia un asalto inmediato al contenedor del jugador.

### 5.3 Inteligencia Artificial del Profesor (`scripts/profesor.gd`)
* **Máquina de Estados Finitos (FSM):**
  * `PATROL`: Recorrido ordenado/aleatorio entre los 91 waypoints 3D del edificio.
  * `SEARCH`: Búsqueda activa con giros angulares de cámara en pasillos y accesos.
  * `CHASE`: Persecución directa con incremento progresivo de aceleración y velocidad al mantener contacto visual directo con el jugador mediante `RayCast3D`.
  * `ATTACK`: Ejecución del ataque cuerpo a cuerpo con la regla de madera al entrar en rango.
  * `INVESTIGATE`: Desplazamiento prioritario hacia fuentes de sonido anómalas (ruido del micrófono o pasos audibles).
* **Grafo de Navegación Multinivel:** Cobertura total de 3 niveles y 3 torres de escaleras (Oeste, Este, Norte) que garantizan que el docente suba y baje pisos sin desorientarse ni atravesar paredes. Incluye temporizador anti-atascamiento (*watchdog timer*) que detecta estancamientos geométricos y redirige al siguiente nodo.

### 5.4 Físicas, Desplazamiento e Interacción
* **Controlador del Jugador (`scripts/player.gd`):** Basado en `CharacterBody3D`, con sistema de inercia y fricción, balanceo de cámara dinámico (*head bobbing*), aceleración por sprint (`Shift`) ligada al consumo de estamina, y lógicas de *step-up* y rampas invisibles en escaleras para un ascenso fluido.
* **Sistema de Interacción Unificado:** Un único `RayCast3D` frontal permite interactuar con cuadernos de examen, tableros, interruptores, pilas AA, snacks Peronachos, puertas y tachos de basura mediante la tecla `E`.

---

## 6. Análisis de Usuarios y Actores del Entorno

### 6.1 Usuarios Primarios
* **Perfil Explorador Lógico:** Observa los detalles del entorno, lee las instrucciones en los pizarrones, memoriza las salidas y gestiona metódicamente las pilas AA y la estamina.
* **Perfil Reactivo / Sigiloso:** Jugador enfocado en la evasión, que aprovecha las esquinas oscuras, calcula los tiempos de paso del profesor y utiliza los tachos de basura controlando conscientemente su respiración real.

### 6.2 Actores del Entorno
* **El Alumno (Avatar del Jugador):**
  * Estudiante vulnerable que carece de armamento o fuerza bruta. Sus únicas herramientas son su visión, su intelecto para resolver parciales de álgebra y análisis, una linterna con batería recargable y su resistencia física.
* **El Profesor (Antagonista Principal):**
  * Manifestación espectral de la implacabilidad académica. Viste traje gris formal, anteojos y corbata roja, empuñando una clásica regla de madera de pizarrón que azota periódicamente contra su mano. No puede ser destruido; únicamente puede ser evadido o despistado.
* **El Edificio Central de UTN FRC (Entorno Hostil Activo):**
  * La facultad opera como un organismo cerrado: puertas que se bloquean con pesadas cadenas, barreras de paso que exigen aprobación de exámenes y un sistema de iluminación que colapsa como represalia ante el avance del usuario.

---

## 7. Narrativa Inmersiva y Perspectiva del Usuario

### 7.1 Narrativa Digital y Progresión en 5 Actos
El hilo conductor se construye sin cinemáticas invasivas, estructurado en una progresión dramática ascendente:
* **Acto I: La Última Oportunidad (Planta Baja):** El alumno ingresa al Hall de Entrada. Las escaleras están clausuradas por barreras institucionales. Para desbloquear el acceso vertical debe ubicar y resolver 4 exámenes parciales de matemáticas distribuidos en PB (Aula 106, Fotocopiadora CEIT, Cafetería PB y Patio del Estudiante).
* **Acto II: El Apagón y la Aparición:** Al entregar con éxito el segundo parcial, la red eléctrica colapsa. El edificio queda en tinieblas absolutas, se enciende la linterna de emergencia y emerge "El Profesor", iniciando su ronda de caza.
* **Acto III: La Búsqueda del Fusible (Pisos Superiores):** Tras aprobar los 4 parciales, las barreras caen. El jugador sube al Primer Piso, descifra el plano en la pizarra didáctica de Bedelía y recupera un fusible industrial de alta tensión (30A).
* **Acto IV: La Restauración y el Auditorio Encadenado:** El jugador desciende al Departamento de Ingeniería Electrónica para reponer el fusible en el Tablero General de 220V. La energía revive parcialmente el campus, permitiendo recuperar la Llave Maestra en la Cafetería del 2do Piso y liberar las cadenas estilo *Silent Hill 4* de la puerta del Auditorio Central para recoger el **Título Universitario**.
* **Acto V: El Egreso Habilitado:** Con el diploma en mano, el alumno alcanza la Puerta Principal de salida vidriada, rompiendo la clausura impuesta por las Autoridades FRC y logrando su graduación y escape.

### 7.2 Marco Teórico de Janet Murray (*Hamlet en la Holocubierta*)
El diseño del entorno implementa con rigurosidad las tres propiedades definitorias de los medios digitales planteadas por Janet Murray:

* **Inmersión (Sensación de transporte y suspensión de la incredulidad):**
  * *Inmersión espacial:* Reproducción mimética del edificio real de la UTN FRC (proporciones de aulas, ventanales al patio interior, bancos de madera y granito pulido).
  * *Inmersión perceptivo-acústica:* El silencio del edificio y el reconocimiento de voz por micrófono rompen la cuarta pared: el jugador no puede hablar ni gritar en su propia habitación física sin exponer a su avatar virtual.
* **Agencia (Capacidad de ejecutar acciones significativas con impacto directo):**
  * El usuario no transita un túnel pasivo: resuelve libremente qué ruta tomar, en qué orden abordar las aulas, cuándo encender su linterna para preservar batería y cuándo esconderse en un contenedor conteniendo el aliento. Sus decisiones determinan si es capturado o si logra desbloquear el siguiente sector.
* **Transformación (Evolución de roles y del espacio interactivo):**
  * *Del espacio:* La facultad muta de ser una casa de altos estudios familiar y luminosa a convertirse en un laberinto claustrofóbico de supervivencia.
  * *Del sujeto:* El usuario comienza como un estudiante desamparado, angustiado y pasivo ante la autoridad; a través del dominio del entorno, la superación de los exámenes y el restablecimiento de la luz, culmina transformado en un profesional graduado que exhibe su título para abrir las puertas clausuradas.

### 7.3 Perspectiva del Usuario (Flujo y POV)
* **Cámara Subjetiva (POV):** Ajustada a la altura de los ojos (1.70 m), con ligero bamboleo al caminar y oscilación marcada al esprintar.
* **HUD Diegético de Videocámara:** Indicador de grabación (`REC`), nivel de batería, timestamp institucional (`CAM 01 - UTN FRC`) y estampa visual sin elementos arcade flotantes que rompan la ambientación.

---

## 8. Diseño Multisensorial e Interacción

### 8.1 Estética Visual y Fidelidad Institucional
* **Materiales PBR y Texturizado:** Pisos de mosaico granítico pulido con reflejos rugosos, friso inferior de machimbre barnizado, marcos de aluminio y cielorrasos técnicos.
* **Diegesis Visual Absoluta:**
  * Eliminación de carteles con texto brillante o flotante. En su lugar, se desarrollaron **50 placas institucionales acrílico-metálicas** montadas con tornillos cromados en muros junto a los marcos de cada aula, reaccionando de forma natural a la iluminación física (`shaded = true`).
  * Puerta del Auditorio sellada con un sistema procedural tridimensional de **cadenas metálicas oxidadas y candados dorados** que caen físicamente al usar la llave.
  * Cartel de clausura oficial en la salida principal modelado como un pliego de papel A4 institucional con tipografía formal y firma al pie de las "AUTORIDADES FRC".
* **Filtro de Cámara Analógica:** Post-procesado con grano fino, viñeteado CRT y sutil aberración cromática en bordes.

### 8.2 Inmersión y Dispositivos de Interacción
* **Dispositivos de Entrada:** Teclado y ratón ergonómicos para navegación espacial fluida.
* **Dispositivo Sensorial de Micrófono:** Auriculares con micrófono integrado, empleados como sensor de silencio involuntario.
* **Dispositivo de Salida Acústica:** Auriculares estéreo con espacialización posicional binaural 3D.

### 8.3 Diseño Sonoro Híbrido
* **Sintetizador Procedural de Terror (`scripts/horror_audio.gd`):** Motor de audio que genera drones armónicos sub-graves de baja frecuencia (30-60 Hz), generando tensión visceral inconsciente en el jugador.
* **Efectos Diegéticos y Espaciales:** Pasos sobre granito, crujido de puertas de chapa, zumbido eléctrico de 50 Hz de reactancias fluorescentes y el eco aterrador de la regla del profesor azotando escritorios vacíos.
* **Efectos de Alerta:** Sonidos metálicos pesados al ingresar a tachos de basura y aumento progresivo de latidos cardíacos según la distancia al peligro.

### 8.4 Consumibles y Apoyos Diegéticos
* **Pilas AA:** Distribuibles en escritorios y estantes para reabastecer la linterna y evitar la ceguera técnica.
* **Paquetes de Peronachos:** Snacks en bolsas 3D distribuidos en buffet y estantes para recargar instantáneamente la barra de estamina tras persecuciones intensas.

---

## 9. Proceso de Prototipado y Evolución

### 9.1 Fases Cronológicas del Desarrollo
1. **Fase I (Brainstorming & Greyboxing en CSG):** Levantamiento volumétrico del Edificio Central a escala real con CSGBoxes para validar dimensiones de aulas, pasillos y escaleras.
2. **Fase II (Gameplay Loop Básico & Parciales):** Programación de los 4 cuadernos de matemáticas con formularios interactivos y activación del corte de luz.
3. **Fase III (IA Multinivel & Waypoints):** Creación del modelo 3D del Profesor y tendido de los 91 nodos de patrulla conectando los tres pisos mediante escaleras en U.
4. **Fase IV (Innovación con Micrófono):** Implementación del bus de captura y afinación del umbral de decibeles al ocultarse en tachos de basura.
5. **Fase V (Limpieza Diegética e Identidad Visual):** Sustitución de carteles flotantes por placas acrílico-metálicas institucionales, implementación del encadenado de *Silent Hill 4* y cartel de papel formal en salida.
6. **Fase VI (UX/UI y Menús Profesionales):** Integración del Menú Principal 3D en vivo, Menú de Pausa, pantalla de carga minimalista y gestión de configuraciones de audio independientes.

### 9.2 Guión del Trailer Promocional ("Publicidad del Futuro")
* **Duración:** 60 segundos | **Estilo:** Metraje Encontrado (*Found Footage*) con distorsión VHS.
* **0:00 - 0:12 | Escena 1 (La Calma Nocturna):**  
  * *Visual:* Cámara fija en el Hall de Entrada desierto. El timestamp digital marca `CAM 01 - UTN FRC | 23:48:12`. Viento suave agitando los árboles del Patio del Estudiante a través de los ventanales.  
  * *Audio:* Zumbido sordo de transformador. Voz en off ahogada: *"Cerraron las rejas... dijeron que nadie sale sin rendir..."*
* **0:12 - 0:26 | Escena 2 (El Pasillo de las Aulas):**  
  * *Visual:* Luz de linterna temblorosa barriendo las placas metálicas de las aulas 104, 105, 106. Una silueta con traje gris y corbata roja se perfila al final del pasillo.  
  * *Audio:* El chasquido rítmico e inconfundible de una regla de madera: *CLAC... CLAC... CLAC...*
* **0:26 - 0:42 | Escena 3 (El Asedio):**  
  * *Visual:* El jugador corre desesperado escaleras arriba hacia el Primer Piso. Se mete en un tacho de basura. En pantalla, el medidor de decibeles del micrófono sube peligrosamente mientras se escuchan pasos pesados deteniéndose exactamente frente al contenedor.  
  * *Audio:* Respiración agitada, crujido de metal y estática violenta.
* **0:42 - 0:54 | Escena 4 (El Clímax en el Auditorio):**  
  * *Visual:* Las cadenas de la puerta del Auditorio caen al piso. El jugador sube al escenario y levanta el Diploma Universitario. Al girar la cámara hacia la salida, el Profesor se abalanza en carrera.  
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
  * Rayll (2021-2023). *Fears to Fathom: Ironbark Lookout & Norwood Hitchhike* (Estética VHS y horror cotidiano).
  * Konami / Team Silent (2004). *Silent Hill 4: The Room* (Mecánica y atmósfera de puertas selladas con cadenas).
  * Red Barrels (2013). *Outlast* (Uso de visión nocturna/baterías limitadas y vulnerabilidad del protagonista).
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
| **Control de Mirada** | Ratón | Orientación de cámara y cono de linterna |
| **Esprintar (Correr)** | `Shift` (mantenido) | Incremento de velocidad con consumo de estamina |
| **Linterna (On/Off)** | `F` | Alterna iluminación (consume batería de la cámara) |
| **Interacción General** | `E` | Recoger exámenes, pilas, fusibles, Peronachos y puertas |
| **Ocultamiento** | `E` (frente a tacho) | Ingresar al contenedor / salir del escondite |
| **Sensor de Silencio** | Micrófono físico | Medición de decibeles en tiempo real mientras se está oculto |
| **Pausa y Objetivos** | `Escape` | Despliega menú de pausa con lista de objetivos y audio |
| **Debug: Ver Coordenadas** | `F3` | Muestra posición espacial Vector3 en pantalla |
| **Debug: Copiar Coords** | `F2` | Copia coordenadas actuales al portapapeles |

### Anexo B: Catálogo de Ítems e Interacciones Diegéticas

1. **Cuadernos de Examen (x4):** Formularios de parciales matemáticos ubicados en Aula 106, Fotocopiadora CEIT, Cafetería PB y Patio del Estudiante.
2. **Fusible de Alta Tensión (30A):** Componente industrial situado en el Primer Piso (Bedelía) indispensable para alimentar el Tablero de 220V del Laboratorio de Electrónica.
3. **Llave Maestra del Auditorio:** Llave de cerradura antigua ubicada en la Cafetería del 2do Piso para desbloquear los candados de las cadenas.
4. **Pilas AA:** Baterías cilíndricas que reabastecen la energía de la linterna y cámara del jugador.
5. **Snacks "Peronachos":** Alimentos energéticos de cafetería que restablecen instantáneamente la barra de estamina.
6. **Título Universitario (Diploma):** Artefacto final sobre el estrado del Auditorio que autoriza el egreso legal del campus en la puerta principal de salida.
