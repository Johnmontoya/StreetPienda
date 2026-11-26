@tool
extends Node2D

func _draw() -> void:
	var top := Color("#18132f")
	var horizon := Color("#8b4669")
	draw_primitive(
		PackedVector2Array([Vector2.ZERO, Vector2(960, 0), Vector2(960, 363), Vector2(0, 363)]),
		PackedColorArray([top, top, horizon, horizon]), PackedVector2Array()
	)
	draw_circle(Vector2(730, 168), 79, Color("#ad617e"), true, -1, true)
	draw_circle(Vector2(730, 168), 64, Color("#e68b93"), true, -1, true)
	for index in range(6):
		var y := 166 + index * 12
		var half_width := sqrt(64.0 * 64.0 - pow(y - 168.0, 2.0))
		draw_line(Vector2(730 - half_width, y), Vector2(730 + half_width, y), Color("#ad617e"), 2)
	var heights := [96, 147, 116, 160, 104, 80, 131, 103, 149, 102, 121, 80, 131, 95, 130, 110]
	for index in range(heights.size()):
		var x := float(index * 64)
		var y := 343.0 - float(heights[index])
		draw_rect(Rect2(x, y, 50, heights[index]), Color("#372743"))
		for window in range(3):
			draw_rect(Rect2(x + 9 + window * 12, y + 15 + (index % 3) * 9, 4, 7), Color("#7e587b"))
	draw_rect(Rect2(0, 337, 960, 31), Color("#1c1b32"))
	draw_line(Vector2(0, 340), Vector2(960, 340), Color("#c57792"), 2)
	for index in range(31):
		var x := float(index * 33)
		draw_line(Vector2(x, 318), Vector2(x, 360), Color("#2c253e"), 3)
	draw_line(Vector2(0, 318), Vector2(960, 318), Color("#352940"), 4)
	draw_rect(Rect2(0, 366, 960, 174), Color("#24263c"))
	draw_rect(Rect2(0, 367, 960, 3), Color("#55516d"))
	for row in [390, 422, 472, 539]:
		draw_line(Vector2(0, row), Vector2(960, row), Color("#393950"), 1)
	for index in range(-6, 7):
		draw_line(Vector2(480 + index * 105, 540), Vector2(480 + index * 55, 369), Color("#393950"), 1)
	for x in [86, 874]:
		draw_line(Vector2(x, 345), Vector2(x, 160), Color("#19192d"), 7)
		draw_line(Vector2(x - 22, 159), Vector2(x + 22, 159), Color("#19192d"), 8)
		draw_line(Vector2(x - 18, 161), Vector2(x + 18, 161), Color("#ffc192"), 3)
	draw_rect(Rect2(112, 226, 167, 50), Color("#231b35"))
	draw_rect(Rect2(116, 230, 159, 42), Color("#ff7894"), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(132, 258), "CALLE  PIENDA", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffb3bb"))
	draw_line(Vector2(54, 452), Vector2(906, 452), Color("#ce7a75"), 2)
	for x in range(76, 900, 35):
		draw_line(Vector2(x, 455), Vector2(x - 8, 462), Color("#92585c"), 2)
