@tool
extends Node2D

@export var spoopy: bool = false:
	set(val):
		if spoopy == val: return
		if val == true:
			$Bg.texture = load("res://assets/levels/maps/roomStage-spook/bg.png")
			$PcOnThing.sprite_frames = load("res://assets/levels/maps/roomStage-spook/pc_on_thing.tres")
		else:
			$Bg.texture = load("res://assets/levels/maps/roomStage/bg.png")
			$PcOnThing.sprite_frames = load("res://assets/levels/maps/roomStage/pc_on_thing.tres")
		$PcOnThing.play("default")
		$Godray.visible = val
		spoopy = val

func _ready() -> void:
	$PcOnThing.play("default")
