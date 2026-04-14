# GameOfLife2D

Simulador 2D del [Juego de la vida de Conway](https://es.wikipedia.org/wiki/Juego_de_la_vida) en Godot 4 con menu de bienvenida, configuracion de idioma y una base adaptada a pruebas moviles.

## Requisitos

- [Godot 4.x](https://godotengine.org/download/) (probado con 4.6.x).

## Estado actual

El proyecto ahora tiene estas piezas principales:

- Pantalla de bienvenida.
- Pantalla de configuracion con selector de idioma.
- Escena principal del juego.
- Tablero dinamico: mantiene un tamano de celda estable y calcula cuantas columnas y filas caben en el espacio disponible.
- Patrones iniciales fijos para depuracion visual del tablero.
- Soporte basico para export Android y prueba en emulador.

## Cómo ejecutar y ver el juego

### Opción A: desde el editor de Godot (recomendado)

1. Abre la aplicación **Godot** (descarga desde [godotengine.org](https://godotengine.org/download/) si aún no la tienes).
2. En el **Project Manager** (pantalla inicial):
   - Pulsa **Import** y elige la carpeta del clon (la que contiene `project.godot`), o
   - Pulsa **Scan** y añade el directorio padre para que aparezca este proyecto en la lista.
3. Selecciona **GameOfLife2D** y pulsa **Edit** para abrir el editor.
4. Para **ejecutar el juego**, usa una de estas acciones:
   - Tecla **F5**, o
   - Botón **Play** (triángulo verde) arriba a la derecha, o
   - menú **Project → Run Project**.

Se abrirá una **ventana del juego** (no solo el editor). Ahí es donde “corre” la simulación.

### Qué deberías ver

- Primero, una **pantalla de bienvenida** con botones para comenzar, abrir configuracion o salir.
- Al entrar al juego, una **rejilla** de celdas con patrones iniciales visibles.
- Arriba, un **panel** con botones: Paso, Play/Pausar, Limpiar, Aleatorio, Patron, Menu, el deslizador **Velocidad**, el texto **Gen: N** y **Vivas: N**.

### Probar que funciona en unos segundos

1. Pulsa **Comenzar** en la bienvenida.
2. Verifica que el tablero muestra celdas vivas desde el inicio.
3. Pulsa **Paso** varias veces: la rejilla cambia según las reglas del Juego de la vida.
4. Pulsa **Play** o **Pausar** para controlar la simulación. Ajusta **Velocidad** si va muy rápido o lento.
5. Usa **Patron** para restaurar un conjunto fijo de patrones visibles.
6. **Limpiar** deja el tablero vacío; **Aleatorio** rellena celdas al azar.

Para **cerrar** la ventana del juego, cierra esa ventana o vuelve al editor y pulsa el botón cuadrado **Stop** (o **F8**).

### Opción B: desde la terminal

Con Godot instalado y el comando `godot` en el `PATH` (por ejemplo tras `brew install --cask godot` en macOS), puedes abrir el proyecto así:

```bash
cd /ruta/al/demo-godot
godot --path .
```

Eso abre el **editor** con este proyecto; luego pulsa **F5** para ver correr el juego, igual que en la opción A.

Durante el desarrollo, la forma habitual de **ver la simulación en marcha** es **F5** (o **Play**) en el editor: Godot lanza la ventana del juego y puedes depurarla desde ahí. Un ejecutable independiente requiere **exportar** el proyecto (menú **Project → Export**), que es un paso aparte.

## Controles

- **Clic izquierdo**: activar o desactivar una célula.
- **Paso**: avanza una generación.
- **Play / Pausar**: simulación continua (intervalo con **Velocidad**).
- **Limpiar** / **Aleatorio**: vacía o rellena la rejilla al azar.
- **Patron**: vuelve a sembrar patrones fijos de prueba.
- **Menu**: regresa a la bienvenida.
- Teclas: **Espacio** (play/pausa), **N** (paso), **C** (limpiar), **R** (aleatorio).

## Tablero

La implementacion del tablero sigue estas ideas:

- El tamano visual de cada celda se mantiene estable.
- El numero de filas y columnas se calcula dinamicamente segun el espacio libre del viewport.
- El tablero se vuelve a construir cuando cambia el tamano disponible.
- La simulacion usa dos buffers:
  - `current_grid` para la generacion actual.
  - `next_grid` para calcular la siguiente.
- El arranque usa patrones fijos para que el tablero sea verificable visualmente.

Esto evita depender solo de aleatoriedad cuando se depura el dibujo o la logica.

## Android / movil

El proyecto se probo en emulador Android.

Puntos importantes:

- El proyecto usa `gl_compatibility` para evitar pantalla negra en emulador.
- La orientacion actual es vertical.
- Hay una utilidad de export local en `scripts/ExportAndroid.gd` que genera un APK debug desde el editor de Godot.

Comando usado para export local:

```bash
godot --headless --editor --path . --script res://scripts/ExportAndroid.gd
```

El APK resultante se genera en:

```bash
build/android/demo-godot-debug.apk
```

## Estructura

- `project.godot` — configuración del proyecto.
- `welcome.tscn` — pantalla de bienvenida y entrada al juego.
- `settings.tscn` — pantalla de configuracion para idioma.
- `main.tscn` — escena del juego (`Node2D` + `Timer`).
- `scripts/GameSettings.gd` — estado global simple para idioma y textos.
- `scripts/GameOfLife.gd` — estado de la rejilla, reglas, dibujo, input y HUD.
- `scripts/WelcomeScreen.gd` — navegación desde la bienvenida a la escena del juego.
- `scripts/SettingsScreen.gd` — selector de idioma y regreso al menu principal.
- `scripts/ExportAndroid.gd` — export utilitario de APK debug para pruebas Android locales.
