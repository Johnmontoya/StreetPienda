# StreetPienda

Juego de peleas 2D para Godot 4.7.2 estable, con dos luchadores y una arena urbana. Se puede jugar contra la CPU o contra otra persona en el mismo teclado.

## Jugar

Importa `project.godot` en Godot y pulsa **F5** para abrir el menú. Puedes elegir con el ratón o con **↑ / ↓** y **Enter**.

- **Historia** abre *La primera noche*, el primer capítulo de Mara, con un duelo contra Nico.
- **VS CPU** inicia un duelo libre contra Nico.
- **Multijugador** inicia un duelo local para dos personas en el mismo teclado.

| Acción | Mara | Nico en duelo local |
| --- | --- | --- |
| Moverse | A / D | ← / → |
| Saltar | W | ↑ |
| Cubrirse | S | ↓ |
| Puñetazo | F | K |
| Patada | G | L |
| Habilidad especial | H | O |

En la arena, **Esc** pausa o reanuda el combate, **R** reinicia el duelo y **M** o el botón **Menú** te devuelven a la pantalla principal. Desde la arena, **F1** cambia a VS CPU y **F2** cambia a multijugador.

Gana quien consiga dos rondas. Si se agotan los 45 segundos de una ronda, gana quien conserve más salud. Si ambos terminan con la misma salud, ninguno suma un punto.

## Combos

| Secuencia | Mara | Nico en duelo local |
| --- | --- | --- |
| Puñetazo → patada | F → G | K → L |
| Puñetazo → puñetazo → patada | F → F → G | K → K → L |
| Patada → puñetazo → patada | G → F → G | L → K → L |

Pulsa cada tecla por separado y rápido, apenas salga el golpe anterior. La cadena avanza si ambos luchadores están en el suelo y el golpe conecta. Un bloqueo o un golpe fallido corta la cadena. El contador aparece desde el segundo impacto consecutivo. La CPU también puede encadenar golpes.

## Habilidades especiales

- **Mara — Paso veloz.** Se impulsa hacia el rival. La habilidad se recarga en 2.4 segundos.
- **Nico — Guardia firme.** Bloquea frontalmente durante un instante, sin retroceder al bloquear. La habilidad se recarga en 3.2 segundos.

La habilidad se activa en el suelo, entre ataques y cuando el luchador puede actuar. El HUD muestra si está lista, activa o en recarga. La CPU decide cuándo usar la habilidad del personaje que controla.

## Agregar un personaje

1. Duplica una escena de `scenes/characters/`. La raíz usa `fighter.gd` y permite editar el nombre, el color del HUD y las velocidades de movimiento y salto desde el Inspector.
2. Asigna la hoja de sprites en `Visual/Sprite2D`. Ajusta la cuadrícula y el origen para que los pies queden sobre el suelo y el personaje mire hacia la derecha.
3. Si el personaje necesita otros fotogramas o tiempos, duplica `fighter_animations.tres` y asigna la copia a su `AnimationPlayer`. Conserva los nombres `idle`, `walk`, `jump`, `guard`, `hurt`, `punch`, `kick`, `cross` y `finisher`. Los tiempos de impacto están definidos en `scripts/fighter.gd`.
4. Abre `scenes/arena.tscn` y asigna la nueva escena a **First Character** o **Second Character** para probarla en VS CPU o Multijugador. Historia usa **Story Player** y **Story Rival** en `scenes/main_menu.tscn`.

Para crear una habilidad, conserva el nodo **Ability** de la plantilla y cambia el script del hijo **Active** por uno que extienda `scripts/abilities/ability_state.gd`. Configura el nombre, la duración y la recarga desde el Inspector. Puedes implementar `_apply(delta)` para el efecto y `should_use(rival, distance)` para que la CPU decida cuándo usarlo. Cada escena usa su propia máquina de LimboAI con los estados **Ready**, **Active** y **Cooldown**.

El proyecto incluye [LimboAI v1.8.1 como GDExtension](https://github.com/limbonaut/limboai/releases/tag/v1.8.1) en `addons/limboai/`. Godot lo carga al importar el proyecto.
