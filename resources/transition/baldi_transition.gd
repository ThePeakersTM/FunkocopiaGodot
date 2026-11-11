extends CanvasLayer
class_name BaldiTransitionScript

@export var overlay: TextureRect

var material: ShaderMaterial
var transitioning := false

func _ready() -> void:
	layer = 100

	material = overlay.material as ShaderMaterial
	overlay.visible = false

func transition(post_transition: Callable = func(): pass) -> void:
	change_scene("", post_transition)

func change_scene(scene_path: String, post_transition: Callable = func(): pass) -> void:
	if transitioning:
		return

	transitioning = true

	var snapshot := await CameraCapture.capture(get_viewport())

	overlay.texture = snapshot
	overlay.visible = true

	material.set_shader_parameter("progress", 0.0)
	
	if scene_path != "":
		var error := get_tree().change_scene_to_file(scene_path)

		if error != OK:
			overlay.visible = false
			transitioning = false
			return
	
	post_transition.call()

	await get_tree().process_frame

	var tween := create_tween()

	tween.tween_method(
		func(value: float):
			material.set_shader_parameter("progress", value),
		0.0,
		1.0,
		0.5
	)

	await tween.finished

	overlay.visible = false
	overlay.texture = null

	transitioning = false
