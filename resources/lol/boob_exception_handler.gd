extends Node

@onready var scream := $Screm

func exception() -> void:
	get_tree().paused = true
	scream.play()
	scream.volume_linear = 0.5
	scream.finished.connect(func():
		assert(false, "Why did you touch her boobs ;-;")
	)
