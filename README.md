# StreetPienda

Juego de peleas 2D para Godot 4.7.2 estable, con dos luchadores y una arena urbana. Se puede jugar contra la CPU o contra otra persona en el mismo teclado.

## Jugar

Importa `project.godot` en Godot y pulsa **F6** con `scenes/arena.tscn` abierta, o **F5** para ejecutar el proyecto.

| Acción | Mara | Nico en duelo local |
| --- | --- | --- |
| Moverse | A / D | ← / → |
| Saltar | W | ↑ |
| Cubrirse | S | ↓ |
| Puñetazo | F | K |
| Patada | G | L |

**F1** inicia un duelo contra la CPU y **F2** inicia un duelo local. **Esc** pausa o reanuda el combate y **R** reinicia el duelo en el modo actual.

Gana quien consiga dos rondas. Si se agotan los 45 segundos de una ronda, gana quien conserve más salud. Si ambos terminan con la misma salud, ninguno suma un punto.

## Combos

| Secuencia | Mara | Nico en duelo local |
| --- | --- | --- |
| Puñetazo → patada | F → G | K → L |
| Puñetazo → puñetazo → patada | F → F → G | K → K → L |
| Patada → puñetazo → patada | G → F → G | L → K → L |

Pulsa cada tecla por separado y rápido, apenas salga el golpe anterior. La cadena avanza si ambos luchadores están en el suelo y el golpe conecta. Un bloqueo o un golpe fallido corta la cadena. El contador aparece desde el segundo impacto consecutivo. La CPU también puede encadenar golpes.
