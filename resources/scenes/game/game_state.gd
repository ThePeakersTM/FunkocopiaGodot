extends Node2D

@onready var player := $Bfellow
@onready var camera := $Camera2D

var room: Room = null

func _ready() -> void:
	if get_child(0) is Room:
		room = get_child(0) as Room
		post_load_room()
	else:
		load_room()

func post_load_room() -> void:
	if room.has_node("PlayerSpawn"):
		player.set_pos(room.get_node("PlayerSpawn").position)
	if room.has_node("CameraPosition"):
		camera.position = room.get_node("CameraPosition").position

func on_hide_ui(id: String) -> void:
	print("on_hide_ui(" + id + ")")
	if id == "tutorial":
		print("on hide ui")
		player.can_process_data = false
		player.play("get_up")

func load_room(id: String = "mellow_room") -> void:
	print("Loading room with id \"" + id + "\"...")
	if room != null:
		room.queue_free()
	room = RoomRegistry.get_room(id)
	room.player = player
	add_child(room)
	move_child(room, 0)
	print("Successfully loaded room with name \"" + room.title + "\".")
	post_load_room()
