extends Camera2D

@onready var player: TopDownCharacter2D = $"../Bfellow"
@onready var game_state = get_parent()

var in_ui := true

func on_show_ui(_id: String) -> void:
	get_node("UI").mouse_filter = Control.MOUSE_FILTER_STOP
	in_ui = true

func on_hide_ui(id: String) -> void:
	get_parent().on_hide_ui(id)
	get_node("UI").mouse_filter = Control.MOUSE_FILTER_IGNORE
	in_ui = false

func _process(_delta: float) -> void:
	if in_ui: return
	position = Vector2(0, 0)
	if game_state.room != null:
		if game_state.room.can_move_x_axis:
			position.x = player.position.x - 960
		if game_state.room.can_move_y_axis:
			position.y = player.position.y - 540
