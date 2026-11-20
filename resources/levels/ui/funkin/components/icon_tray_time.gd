extends Label

func _process(_d: float) -> void:
	var health_bar: RubiconHealthBar = get_parent().get_parent()
	var level: RubiconLevel = health_bar.get_parent().get_parent().get_parent().get_parent()
	var level_clock: RubiconLevelClock = level.get_node("RubiconLevelClock")
	var millis: float = level_clock.time_milliseconds
	var seconds: float = millis / 1000
	var minutes: float = seconds / 60
	text = "%02d:%02d" % [floori(minutes) % 60, floori(seconds) % 60]
