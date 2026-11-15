extends Node2D

@onready var music := $Music
@onready var stars := $Stars
@onready var gf := $GF
@onready var boobs := $GF/Boobs
@onready var titleshit := $TitleShit
@onready var menu := $Menu

var intronothereanymore := false
var has1 := false

var touching_boobs := false

func _ready() -> void:
	boobs.mouse_entered.connect(func():
		touching_boobs = true
	)
	boobs.mouse_exited.connect(func():
		touching_boobs = false
	)

func on_splash_disappear() -> void:
	intronothereanymore = true
	stars.play()
	titleshit.show()
	titleshit.play("appear")
	titleshit.animation_finished.connect(func():
		if titleshit.animation == "click":
			get_tree().create_timer(0.5).timeout.connect(func(): menu.do_menu_shit())
	)
	gf.play()
	music.play()

func _process(_delta: float) -> void:
	if not intronothereanymore: return
	if Input.is_action_just_pressed("left_click"):
		if touching_boobs:
			music.stop()
			BoobExceptionHandler.exception()
		if not has1:
			titleshit.play("click")
			has1 = true
