extends Control

@onready var fade := $Fade
@onready var fade_label := $Fade/Label
@onready var scene_light := $Scenelight

@onready var point_light := $PointLight2D
@onready var canvas_modulate := $CanvasModulate

const LIFT := -24.0
const DURATION := 0.15

var tweens := {}

func _on_launch(game: Button, after: Callable) -> void:
	if game.disabled: return
	var kettei := $Kettei
	kettei.volume_linear = 1
	kettei.play()
	fade.mouse_filter = MOUSE_FILTER_STOP
	create_tween().tween_property(fade, "modulate", Color.WHITE, 1).finished.connect(func():
		get_tree().create_timer(0.5).timeout.connect(after)
	)

func _title(title: String = "") -> void:
	DisplayServer.window_set_title(
			"Fear of Fun" + (
				" - " if title != "" else ""
			) + title + (" (DEBUG)" if OS.is_debug_build() else "")
		)

var game_methods := [
	func():
		print("Launching Fran Bow"),
	func():
		DisplayServer.set_icon(load("res://assets/funkocopia/icon.png").get_image())
		_title("Funkocopia (Endacopia)")
		Cursor.create()
		Dwmapi.funkocopia()
		SaveSystem.load_file()
		BaldiTransition.change_scene(
			"res://resources/funkocopia/scenes/title_screen.tscn",
			func(): pass,
			false
		),
	func():
		print("Launching Omori"),
	func():
		print("Launching Exhibit of Sorrows")
]

var available := [1]

func _ready() -> void:
	point_light.visible = false
	fade.visible = true
	fade_label.visible = false
	fade.modulate = Color.WHITE
	fade.mouse_filter = MOUSE_FILTER_STOP
	get_tree().create_timer(0.85).timeout.connect(func():
		get_tree().create_timer(0.5).timeout.connect(func():
			fade.modulate = Color.TRANSPARENT
			fade.mouse_filter = MOUSE_FILTER_IGNORE
			fade_label.visible = true
			point_light.visible = true
			canvas_modulate.color = Color(0.503, 0.503, 0.503)
			point_light.energy = 1.0
			get_tree().create_timer(0.5).timeout.connect(func():
				create_tween().tween_method(
					func(v: float):
						point_light.energy = 1.0 - v
						var j := v / 2.0
						if v == 0:
							j = 0.0
						var i = j + 0.503
						canvas_modulate.color = Color(i, i, i),
					0.0,
					1.0,
					2
				)
			)
		)
		scene_light.play()
	)
	var games := $Margin/HBoxMargin/HBoxContainer.get_children()
	for i in games.size():
		var game: Button = games[i]
		var polygon: Polygon2D = game.get_node("Polygon2D")
		if i not in available:
			game.mouse_filter = MOUSE_FILTER_IGNORE
			game.mouse_default_cursor_shape = CURSOR_FORBIDDEN
			game.disabled = true
			polygon.color = Color(DISABLED_ALPHA, DISABLED_ALPHA, DISABLED_ALPHA)
		else:
			game.mouse_filter = MOUSE_FILTER_STOP
			game.mouse_default_cursor_shape = CURSOR_ARROW
			polygon.color = Color.WHITE
		var base_z := games.size() - i
		game.mouse_entered.connect(_hover.bind(game, true, base_z))
		game.mouse_exited.connect(_hover.bind(game, false, base_z))
		game.pressed.connect(func(): _on_launch(game, game_methods[i]))
		game.get_node("Polygon2D").offset.y = -675
		game.disabled = true
		get_tree().create_timer((base_z/10.0)+4).timeout.connect(func():
			game.get_node("Whoosh").play()
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(
				game.get_node("Polygon2D"),
				"offset:y",
				0,
				0.5
			).finished.connect(func():
				if game.mouse_filter == MOUSE_FILTER_STOP:
					game.disabled = false
				if not game.disabled:
					game.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			)
		)

const OVERSHOOT := 4.0  # default Godot is ~1.70158; higher = stronger

func _back_out(t: float, s: float) -> float:
	t -= 1.0
	return t * t * ((s + 1.0) * t + s) + 1.0

func _back_out_peak(s: float) -> float:
	return 1.0 - 2.0 * s / (3.0 * (s + 1.0))

const ALPHA_DURATION := 0.4
const DIM_ALPHA := 0.1
const DISABLED_ALPHA := DIM_ALPHA * 5

var alpha_tweens := {}

func _tween_alpha(node: Polygon2D, target: float) -> void:
	if alpha_tweens.has(node) and alpha_tweens[node].is_valid():
		alpha_tweens[node].kill()
	var dist := absf(target - node.color.r) / (1.0 - DIM_ALPHA)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "color", Color(target, target, target), ALPHA_DURATION * dist)
	alpha_tweens[node] = tween

func _hover(game: Button, up: bool, base_z: int) -> void:
	if game.disabled: return
	if up:
		var whoosh: AudioStreamPlayer = game.get_node("Whoosh")
		whoosh.play()
	
	var polygon: Polygon2D = game.get_node("Polygon2D")
	if tweens.has(game) and tweens[game].is_valid():
		tweens[game].kill()
	var from := polygon.offset.y
	var target := LIFT if up else 0.0
	var distance := absf(target - from) / absf(LIFT)
	var new_z := 10 if up else base_z
	var duration := DURATION * distance
	var s := OVERSHOOT * (1 if up else 2)
	var tween := create_tween()
	tween.tween_method(func(t: float):
		polygon.offset.y = lerpf(from, target, _back_out(t, s))
	, 0.0, 1.0, duration)
	tween.parallel().tween_callback(func(): game.z_index = new_z).set_delay(duration * _back_out_peak(s))
	tweens[game] = tween

	for g: Control in $Margin/HBoxMargin/HBoxContainer.get_children():
		var p: Polygon2D = g.get_node("Polygon2D")
		_tween_alpha(p, DIM_ALPHA if (up and g != game) else (
			DISABLED_ALPHA if g.disabled else 1.0
		))
