extends Node

var rooms: Array[String] = [
	"mellow_room"
]

func get_rooms() -> Array[Room]:
	var rooms_list: Array[Room] = []
	for room in rooms:
		rooms_list.append(
			load(
				"res://resources/scenes/game/rooms/" + room + ".tscn"
			).instantiate()
		)
	return rooms_list

func get_room(id: String) -> Room:
	for room in get_rooms():
		if room.id == id:
			return room
	push_warning("Couldn't find room with id \"" + id + "\".")
	return get_room("mellow_room")
