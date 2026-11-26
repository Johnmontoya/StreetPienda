extends Node2D

const MAX_HEALTH := 100
const GRAVITY := 1500.0
const WALK_SPEED := 233.0
const JUMP_SPEED := 525.0
const ATTACKS := {
	&"punch": {"start": 0.09, "end": 0.17, "total": 0.32, "reach": 94.0, "height": 67.0, "damage": 10, "stun": 0.22},
	&"kick": {"start": 0.17, "end": 0.27, "total": 0.52, "reach": 128.0, "height": 42.0, "damage": 17, "stun": 0.31},
}

var fighter_name := ""
var accent := Color.WHITE
var dark := Color.WHITE
var skin := Color.WHITE
var face := 1.0
var health := MAX_HEALTH
var elevation := 0.0
var vertical_speed := 0.0
var movement := 0.0
var clock := 0.0
var stance := &"idle"
var grounded := true
var attack_time := 0.0
var connected := false
var stun_left := 0.0
var knockback := 0.0

func reset_at(x: float, floor_y: float, direction: float) -> void:
	position = Vector2(x, floor_y)
	face = direction
	health = MAX_HEALTH
	elevation = 0.0
	vertical_speed = 0.0
	movement = 0.0
	clock = 0.0
	stance = &"idle"
	grounded = true
	attack_time = 0.0
	connected = false
	stun_left = 0.0
	knockback = 0.0
	queue_redraw()

func step(delta: float, axis: float, jump: bool, guard: bool, strike: StringName, rival_x: float) -> void:
	clock += delta
	movement = 0.0
	if ATTACKS.has(stance):
		attack_time += delta
		if attack_time >= float(ATTACKS[stance]["total"]):
			stance = &"idle"
	elif stun_left > 0.0:
		stun_left = maxf(0.0, stun_left - delta)
		position.x += knockback * delta
		knockback = move_toward(knockback, 0.0, delta * 900.0)
	else:
		if absf(rival_x - position.x) > 1.0:
			face = signf(rival_x - position.x)
		stance = &"idle"
		if grounded and guard:
			stance = &"guard"
		elif strike != &"":
			stance = strike
			attack_time = 0.0
			connected = false
		else:
			movement = axis
			position.x += axis * WALK_SPEED * delta
			if grounded and jump:
				vertical_speed = JUMP_SPEED
				grounded = false

	if not grounded:
		elevation += vertical_speed * delta
		vertical_speed -= GRAVITY * delta
		if elevation <= 0.0:
			elevation = 0.0
			vertical_speed = 0.0
			grounded = true
	queue_redraw()

func contact_with(rival) -> Dictionary:
	if not ATTACKS.has(stance) or connected:
		return {}
	var move: Dictionary = ATTACKS[stance]
	if attack_time < float(move["start"]) or attack_time > float(move["end"]):
		return {}
	var ahead: float = (rival.position.x - position.x) * face
	var height_difference: float = elevation + float(move["height"]) - rival.elevation
	if ahead < 0.0 or ahead > float(move["reach"]) or height_difference < 13.0 or height_difference > 105.0:
		return {}
	connected = true
	var blocked: bool = rival.stance == &"guard" and (position.x - rival.position.x) * rival.face > 0.0
	return {"move": move, "blocked": blocked, "direction": face}

func receive(contact: Dictionary) -> void:
	var move: Dictionary = contact["move"]
	var blocked: bool = contact["blocked"]
	if not blocked:
		health = maxi(0, health - int(move["damage"]))
	stance = &"guard" if blocked else &"hurt"
	stun_left = 0.15 if blocked else float(move["stun"])
	knockback = float(contact["direction"]) * (105.0 if blocked else 220.0)

func _limb(a: Vector2, b: Vector2, c: Vector2, tint: Color, thickness: float) -> void:
	var outline := Color("#121324")
	draw_polyline(PackedVector2Array([a, b, c]), outline, thickness + 6.0, true)
	draw_circle(b, (thickness + 5.0) * 0.5, outline)
	draw_polyline(PackedVector2Array([a, b, c]), tint, thickness, true)
	draw_circle(b, thickness * 0.5, tint)

func _draw() -> void:
	var shadow_scale := 1.0 - clampf(elevation / 160.0, 0.0, 0.55)
	draw_set_transform(Vector2(0, 4), 0.0, Vector2(shadow_scale, 0.24 * shadow_scale))
	draw_circle(Vector2.ZERO, 45, Color(0.02, 0.02, 0.08, 0.48))
	draw_set_transform(Vector2(0, -elevation), 0.0, Vector2(face, 1))
	var walk := sin(clock * 17.0) * 15.0 * absf(movement)
	var bob := sin(clock * 8.0) * 2.0
	var lean := -12.0 if stance == &"hurt" else 0.0
	var hip := Vector2(lean * 0.4, -48 + bob)
	var shoulder := Vector2(lean + 3, -91 + bob)
	var back_foot := Vector2(-23 - walk, -2)
	var front_foot := Vector2(22 + walk, -2)
	if not grounded:
		back_foot.y = -15
		front_foot.y = -22
	var extended := 0.0
	if ATTACKS.has(stance):
		var move: Dictionary = ATTACKS[stance]
		extended = clampf(attack_time / float(move["start"]), 0.0, 1.0)
		if attack_time > float(move["end"]):
			extended = clampf((float(move["total"]) - attack_time) / (float(move["total"]) - float(move["end"])), 0.0, 1.0)
	var front_knee := Vector2(16 + walk * 0.5, -27)
	if stance == &"kick":
		front_foot = front_foot.lerp(Vector2(97, -45), extended)
		front_knee = front_knee.lerp(Vector2(51, -41), extended)
	_limb(hip, Vector2(-17 - walk * 0.5, -25), back_foot, dark.darkened(0.22), 14)
	_limb(hip, front_knee, front_foot, dark, 17)
	draw_line(back_foot - Vector2(5, 1), back_foot + Vector2(11, 1), Color("#101020"), 9, true)
	draw_line(front_foot - Vector2(5, 1), front_foot + Vector2(12, 1), Color("#101020"), 10, true)
	var back_hand := shoulder + Vector2(25, 3)
	if stance == &"guard":
		back_hand = shoulder + Vector2(15, -19)
	_limb(shoulder + Vector2(-7, 2), shoulder + Vector2(-3, 20), back_hand, skin.darkened(0.28), 10)
	draw_circle(back_hand, 8, dark)
	var torso := PackedVector2Array([
		shoulder + Vector2(-17, -5), shoulder + Vector2(13, -4),
		hip + Vector2(14, 2), hip + Vector2(-17, 4),
	])
	draw_colored_polygon(torso, accent)
	var border := torso.duplicate()
	border.append(torso[0])
	draw_polyline(border, Color("#121324"), 4, true)
	draw_line(shoulder + Vector2(-11, 1), hip + Vector2(-5, -3), accent.lightened(0.35), 3, true)
	draw_line(hip + Vector2(-16, 1), hip + Vector2(14, -2), dark, 6, true)
	var head := shoulder + Vector2(3, -19)
	draw_circle(head, 17, Color("#121324"))
	draw_circle(head, 14, skin)
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(-14, 3), head + Vector2(-17, -8), head + Vector2(-9, -17),
		head + Vector2(12, -16), head + Vector2(16, -7), head + Vector2(-4, -7),
		head + Vector2(-7, 3),
	]), Color("#19182b"))
	draw_line(head + Vector2(-12, -8), head + Vector2(14, -8), accent, 3, true)
	draw_line(head + Vector2(6, -2), head + Vector2(12, -2), Color("#19182b"), 2, true)
	var elbow := shoulder + Vector2(9, 26)
	var fist := shoulder + Vector2(30, 13)
	if stance == &"punch":
		elbow = elbow.lerp(shoulder + Vector2(39, 11), extended)
		fist = fist.lerp(Vector2(76, -77), extended)
	elif stance == &"guard":
		elbow = shoulder + Vector2(13, 22)
		fist = shoulder + Vector2(26, -9)
	_limb(shoulder + Vector2(4, 7), elbow, fist, skin, 11)
	draw_circle(fist, 10, Color("#121324"))
	draw_circle(fist, 7, accent.lightened(0.12))
