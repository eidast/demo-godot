# GameOfLife2D

Simulador 2D del [Juego de la vida de Conway](https://es.wikipedia.org/wiki/Juego_de_la_vida) en Godot 4.

## Requisitos

- [Godot 4.x](https://godotengine.org/download/) (probado con 4.6.x).

## Cómo ejecutar

1. Abre Godot y en el **Project Manager** importa o escanea esta carpeta (debe existir `project.godot`).
2. Abre el proyecto y pulsa **F5** o **Play**.

Desde terminal (si `godot` está en el PATH):

```bash
godot --path .
```

## Controles

- **Clic izquierdo**: activar o desactivar una célula.
- **Paso**: avanza una generación.
- **Play / Pausar**: simulación continua (intervalo con **Velocidad**).
- **Limpiar** / **Aleatorio**: vacía o rellena la rejilla al azar.
- Teclas: **Espacio** (play/pausa), **N** (paso), **C** (limpiar), **R** (aleatorio).

## Estructura

- `project.godot` — configuración del proyecto.
- `main.tscn` — escena principal (`Node2D` + `Timer`).
- `scripts/GameOfLife.gd` — estado de la rejilla, reglas, dibujo y UI.
