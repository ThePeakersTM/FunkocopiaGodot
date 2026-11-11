extends Control

@export_group("References", "reference_")
@export var reference_health_bar: RubiconHealthBar
@export var reference_opponent_strumline: Control
@export var reference_player_strumline: Control

func _ready() -> void:
	if Options.downscroll:
		reference_health_bar.position.y = 75
		reference_opponent_strumline.position.y = 950
		reference_player_strumline.position.y = 950
