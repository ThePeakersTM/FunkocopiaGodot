extends CharacterBody2D
class_name TopDownCharacter2D

@export_group("Animations", "anim_")
## The [AnimatedSprite2D] for playing all the animations. If the sprite is not passed,
## it will not play the animation with printing a warning. If an animation is not found in
## the [member AnimatedSprite2D.sprite_frames], it will also print a warning.
@export var anim_sprite: AnimatedSprite2D
## Prefix for all the playing animations, e.g. when it's set to [code]Bfellow[/code],
## on every animation play it will add the prefix [code]Bfellow[/code] to
## the beginning of the played animation name.
@export var anim_prefix: String = ""
## An array with all the animations that have variants per direction.
@export var anim_for_dir_anims: Array[String] = [
	"Idle",
	"Walk",
	"Talk",
	"Blink"
]
## A dictionary if all the possible normals and their corresponding animation names.
## If a normal isn't in this list for a specific direction, it will give a warning
## for the first time and it will not play the direction at all.
@export var anim_direction_names: Dictionary[Vector2i, String] = {
	Vector2i( 0,  1): "DD",
	Vector2i(-1,  1): "DL",
	Vector2i( 1,  1): "DR",
	Vector2i( 1,  0): "RR",
	Vector2i(-1,  0): "LL",
	Vector2i(-1, -1): "UL",
	Vector2i( 1, -1): "UR",
	Vector2i( 0, -1): "UU"
}
## A dictionary with all the animations, that you want to change a specific name,
## e.g. when the [member TopDownCharacter2D.anim_prefix] is set to [code]Bfellow[/code]
## and in the dictionary, there is an entry added with key [code]plug[/code]
## and value [code]ConnectPlug[/code], when you will use the method
## [method TopDownCharacter2D.play] with passing in [code]plug[/code], it will play
## the animation with name [code]BfellowConnectPlug[/code].
@export var anim_animation_names: Dictionary[String, String] = {}
## The current direction of facing. You can either change it in paramaters, in script
## or by calculating it with the method [method TopDownCharacter2D.calculate_normals].
@export var anim_facing_direction: String = "DD"

#region navigation
@export_group("Navigation", "navigation_")
@export var navigation_offset := Vector2.ZERO
@onready var nav: NavigationAgent2D = $NavigationAgent2D
var navigating := false
var navigation_velocity: Vector2
var nav_dir_override: String = ""
#endregion

var anim_animation := ""
var moving := false
var moonwalk := false

#region warnings
var _pushed_null_sprite_warning = false
var _pushed_anim_warnings: Array[String] = []
#endregion

func _get_lfd() -> Array[String]:
	var a: Array[String] = []
	for i in anim_for_dir_anims:
		a.append(i.to_lower())
	return a

func play(animation: StringName, speed: float = 1.0):
	anim_animation = animation
	var animToPlay = animation
	if anim_animation_names.has(animation):
		animToPlay = anim_animation_names[animation]
	elif animation.to_lower() in _get_lfd():
		for i in anim_for_dir_anims:
			if i.to_lower() == animation.to_lower(): animToPlay = anim_facing_direction + i
	
	if anim_sprite == null:
		if not _pushed_null_sprite_warning:
			push_warning("The animation sprite is nullable, cannot play the animation.")
			_pushed_null_sprite_warning = true
		return
	
	if not animToPlay.begins_with("|-|"):
		animToPlay = anim_prefix + animToPlay
	else:
		animToPlay = animToPlay.lstrip("|-|")
	
	if not anim_sprite.sprite_frames.has_animation(animToPlay):
		if not animToPlay in _pushed_anim_warnings:
			push_warning(
				'Sprite does not have an animation with the name "%".' % animToPlay
			)
			_pushed_anim_warnings.append(animToPlay)
		return
	
	anim_sprite.play(animToPlay, speed)

func calculate_normals() -> void:
	var vel = velocity.sign()
	if moonwalk:
		vel *= Vector2(-1, -1)
	var normal = Vector2i(vel)
	if normal == Vector2i.ZERO:
		moving = false
		return
	moving = true
	if navigating and nav_dir_override != "":
		anim_facing_direction = nav_dir_override
	else:
		anim_facing_direction = anim_direction_names[normal]

func _get_navpos(pos: Vector2) -> Vector2:
	return pos - navigation_offset

func navigate_to(pos: Vector2, direction_override: String = "") -> void:
	if nav.target_position != _get_navpos(pos):
		nav.target_position = _get_navpos(pos)
	navigating = true
	nav_dir_override = direction_override

func _physics_process(_delta: float) -> void:
	if navigating:
		if nav.is_target_reached() or nav.target_position.distance_to(_get_navpos(global_position)) < 5:
			navigating = false
		else:
			navigation_velocity = to_local(
				nav.get_next_path_position()
			).normalized()
