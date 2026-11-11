extends Node2D
class_name Room

@export var id := "room_id"
@export var title := "Room Name"

@export_subgroup("Can Camera Move", "can_move_")
@export var can_move_x_axis = true
@export var can_move_y_axis = true
@export_group("")
@export var player: TopDownCharacter2D
