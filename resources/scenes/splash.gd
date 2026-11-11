extends AnimatedSprite2D

func _ready() -> void:
	show()
	play()
	animation_finished.connect(func():
		hide()
		get_parent().on_splash_disappear()
		queue_free()
	)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("left_click"):
		if frame < 120:
			frame = 120
