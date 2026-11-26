extends Node2D

const Arena := preload("res://scripts/arena.gd")
const INK := Color("#17172b")
const WHITE := Color("#fff1e9")
const MUTED := Color("#c7bdd2")
const GOLD := Color("#ffd494")

var arena: Arena
var font := ThemeDB.fallback_font

func _label(value: String, rect: Rect2, size: int, tint: Color = WHITE, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(font, rect.position, value, alignment, rect.size.x, size, tint)

func _draw() -> void:
	if arena == null:
		return
	var first := arena.first
	var second := arena.second
	draw_rect(Rect2(47, 26, 866, 76), Color(0.065, 0.06, 0.12, 0.88))
	draw_rect(Rect2(443, 26, 74, 76), Color("#3c2c48"))
	_label(first.fighter_name, Rect2(65, 53, 354, 0), 22, first.accent)
	_label(second.fighter_name, Rect2(541, 53, 354, 0), 22, second.accent, HORIZONTAL_ALIGNMENT_RIGHT)
	_health_bar(Rect2(65, 62, 354, 13), first.health, first.accent, false)
	_health_bar(Rect2(541, 62, 354, 13), second.health, second.accent, true)
	for index in range(Arena.ROUNDS_TO_WIN):
		_round_marker(Vector2(70 + index * 15, 88), index < arena.first_wins, first.accent)
		_round_marker(Vector2(890 - index * 15, 88), index < arena.second_wins, second.accent)
	_label("%02d" % ceili(arena.time_left), Rect2(443, 64, 74, 0), 30, WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_label("RONDA %d" % arena.round_number, Rect2(443, 86, 74, 0), 12, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	if first.combo_display_left > 0.0:
		_combo(Vector2(47, 111), first.combo_hits, first.accent)
	if second.combo_display_left > 0.0:
		_combo(Vector2(792, 111), second.combo_hits, second.accent)

	draw_rect(Rect2(0, 477, 960, 63), INK)
	draw_line(Vector2(0, 477), Vector2(960, 477), Color("#65516a"), 1)
	_label("J1", Rect2(44, 500, 50, 0), 14, first.accent)
	_label("A D  Mover   W  Saltar   S  Cubrir   F G  Atacar", Rect2(104, 500, 410, 0), 13, WHITE)
	if arena.local_multiplayer:
		_label("J2", Rect2(508, 500, 50, 0), 14, second.accent)
		_label("← →  Mover   ↑  Saltar   ↓  Cubrir   K L  Atacar", Rect2(563, 500, 380, 0), 13, WHITE)
	else:
		_label("%s  /  CPU" % second.fighter_name, Rect2(660, 500, 256, 0), 14, second.accent, HORIZONTAL_ALIGNMENT_RIGHT)
	_label("F1  Contra CPU     F2  Duelo local     Esc  Pausa     R  Reiniciar", Rect2(44, 524, 872, 0), 13, MUTED)

	if arena.spark_time > 0.0:
		_draw_spark()
	if arena.paused:
		_banner("Pausa", "Esc para continuar")
		return
	match arena.phase:
		Arena.Phase.INTRO:
			_banner("Ronda %d" % arena.round_number)
		Arena.Phase.FIGHT:
			if arena.phase_left > 0.0:
				_banner("¡A pelear!")
		Arena.Phase.ROUND_END:
			_banner(arena.result, "Siguiente ronda")
		Arena.Phase.MATCH_END:
			if arena.mode == Arena.Mode.STORY and arena.first_wins == Arena.ROUNDS_TO_WIN:
				_banner("Historia completada", "%s el duelo  ·  R para repetirlo" % arena.result)
			elif arena.mode == Arena.Mode.STORY:
				_banner(arena.result + " el duelo", "R para reintentar")
			else:
				_banner(arena.result + " el duelo", "R para volver a jugar")

func _health_bar(rect: Rect2, health: int, tint: Color, reverse: bool) -> void:
	draw_rect(rect, Color("#544155"))
	var fill := rect
	fill.size.x *= float(health) / arena.first.MAX_HEALTH
	if reverse:
		fill.position.x = rect.end.x - fill.size.x
	if health > 0:
		draw_rect(fill, tint)
		draw_line(fill.position, Vector2(fill.end.x, fill.position.y), tint.lightened(0.4), 2)

func _round_marker(center: Vector2, filled: bool, tint: Color) -> void:
	draw_circle(center, 4.0, tint if filled else Color("#806a81"), filled, -1.0 if filled else 1.2, true)

func _combo(top_left: Vector2, hit_count: int, tint: Color) -> void:
	draw_rect(Rect2(top_left, Vector2(121, 36)), INK)
	draw_rect(Rect2(top_left, Vector2(121, 2)), tint)
	_label("%d GOLPES" % hit_count, Rect2(top_left + Vector2(0, 25), Vector2(121, 0)), 18, tint, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_spark() -> void:
	var progress := 1.0 - arena.spark_time / 0.19
	var tint := arena.spark_color
	tint.a = 1.0 - progress
	var center := arena.spark_position
	for ray in range(8):
		var angle := ray * TAU / 8.0 + 0.28
		var direction := Vector2.from_angle(angle)
		draw_line(center + direction * 5.0, center + direction * (15.0 + progress * 27.0), tint, 3.0, true)

func _banner(title: String, subtitle := "") -> void:
	var panel := Rect2(280, 158, 400, 86)
	draw_rect(panel, Color(0.07, 0.06, 0.13, 0.92))
	draw_line(panel.position, Vector2(panel.end.x, panel.position.y), GOLD, 2)
	var title_y := 210.0 if subtitle.is_empty() else 197.0
	_label(title, Rect2(280, title_y, 400, 0), 30, WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	if not subtitle.is_empty():
		_label(subtitle, Rect2(280, 223, 400, 0), 15, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
