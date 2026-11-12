extends Node2D

@onready var player := $Bfellow
@onready var camera := $Camera2D

var room: Room = null
var overlay: Overlay = null

func _ready() -> void:
	Cursor.can_change_cursor = true
	
	if get_child(0) is Room:
		room = get_child(0) as Room
		post_load_room()
	else:
		load_room()

func load_overlay(path: String) -> void:
	var loaded: Overlay = (
		load(
			"res://resources/scenes/game/overlays/" + path + "_overlay.tscn"
		) as PackedScene
	).instantiate()
	overlay = loaded
	camera.get_node("UI").add_child(overlay)
	on_show_ui("overlay")
	Cursor.can_change_cursor = false

func post_load_room() -> void:
	print("Successfully loaded room with name \"" + room.title + "\".")
	if room.has_node("PlayerSpawn"):
		player.set_pos(room.get_node("PlayerSpawn").position)
	if room.has_node("CameraPosition"):
		camera.position = room.get_node("CameraPosition").position

func on_show_ui(id: String) -> void:
	camera.on_show_ui(id)

func on_hide_ui(id: String) -> void:
	if id == "tutorial":
		player.can_process_data = false
		player.play("get_up")
	elif id == "overlay":
		Cursor.can_change_cursor = true

func load_room(id: String = "mellow_room") -> void:
	print("Loading room with id \"" + id + "\"...")
	if room != null:
		room.queue_free()
	room = RoomRegistry.get_room(id)
	room.player = player
	add_child(room)
	move_child(room, 0)
	post_load_room()
