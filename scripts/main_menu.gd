extends Control

const Arena := preload("res://scripts/arena.gd")
const ARENA_SCENE := preload("res://scenes/arena.tscn")

@export var story_player: PackedScene
@export var story_rival: PackedScene

@onready var modes: VBoxContainer = $Modes
@onready var story: VBoxContainer = $Story
@onready var story_button: Button = $Modes/StoryButton
@onready var fight_button: Button = $Story/FightButton
@onready var navigation_hint: Label = $NavigationHint

func _ready() -> void:
	story_button.pressed.connect(_show_story)
	$Modes/CpuButton.pressed.connect(_start.bind(Arena.Mode.CPU))
	$Modes/LocalButton.pressed.connect(_start.bind(Arena.Mode.LOCAL))
	fight_button.pressed.connect(_start.bind(Arena.Mode.STORY))
	$Story/BackButton.pressed.connect(_show_modes)
	_show_modes()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and story.visible:
		_show_modes()
		get_viewport().set_input_as_handled()

func _show_story() -> void:
	modes.hide()
	story.show()
	navigation_hint.text = "↑ ↓  Elegir     Enter  Confirmar     Esc  Volver"
	fight_button.grab_focus()

func _show_modes() -> void:
	story.hide()
	modes.show()
	navigation_hint.text = "↑ ↓  Elegir     Enter  Confirmar"
	story_button.grab_focus()

func _start(mode: Arena.Mode) -> void:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.mode = mode
	if mode == Arena.Mode.STORY:
		arena.first_character = story_player
		arena.second_character = story_rival
	var error := get_tree().change_scene_to_node(arena)
	if error != OK:
		arena.free()
		push_error("No se pudo abrir la arena: %s" % error_string(error))
