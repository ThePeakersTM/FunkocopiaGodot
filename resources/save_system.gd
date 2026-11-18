extends Node

enum Games {
	FUNKOCOPIA
}

const ALL_GAMES = [Games.FUNKOCOPIA]

func get_game_save_path(game: Games) -> String:
	match game:
		Games.FUNKOCOPIA: return "user://fof/funkocopia.json"
		_: return ""

var funkocopia_save: Dictionary[String, Variant]
var has_funkocopia_save: bool = false

func _get_game_save_data(game: Games) -> Dictionary[String, Variant]:
	match game:
		Games.FUNKOCOPIA: return funkocopia_save
		_: return {}

func clear_data() -> void:
	clear_game_data(_save_game)

func clear_game_data(game: Games) -> void:
	_get_game_save_data(game).clear()

var _save_game: Games

func set_save_game(game: Games) -> void:
	_save_game = game

func get_save_game() -> Games:
	return _save_game

func pass_data(key: String, value: Variant) -> void:
	_get_game_save_data(_save_game)[key] = value

func has_data(key: String) -> bool:
	return _get_game_save_data(_save_game).has(key)

func get_data(key: String, default: Variant = null) -> Variant:
	return _get_game_save_data(_save_game).get(key, default)

func has_save() -> bool:
	match _save_game:
		Games.FUNKOCOPIA: return has_funkocopia_save
		_: return false

func save_file() -> void:
	for game in ALL_GAMES:
		var save_path := get_game_save_path(game)
		DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
		
		var file := FileAccess.open(save_path, FileAccess.WRITE)
		if file == null:
			push_error("Couldn't open %s: %s" % [save_path, error_string(FileAccess.get_open_error())])
			continue
		
		file.store_line(JSON.stringify(_get_game_save_data(game)))
		file.close()

func load_file() -> void:
	for game in ALL_GAMES:
		var save_path := get_game_save_path(game)
		if not FileAccess.file_exists(save_path):
			continue
		var file := FileAccess.open(save_path, FileAccess.READ)
		if file == null:
			continue
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			if game == Games.FUNKOCOPIA:
				has_funkocopia_save = true
			clear_game_data(game)
			for key in parsed:
				_get_game_save_data(game)[key] = parsed[key]
