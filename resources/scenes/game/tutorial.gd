extends Sprite2D

@onready var page := $Page
@onready var page_corner := $PageCorner
@onready var page_corner_interaction := $PageCorner/Button
@onready var page_flip := $PageFlip
@onready var leave := $Leave

func _ready() -> void:
	page.animation = "Page"
	page.frame = 0
	page_corner.animation = "PageCorner"
	page_corner.frame = 0
	page_corner_interaction.pressed.connect(func():
		var next_frame = (page_corner.frame + 1) % 5
		page.play("Page")
		page.frame = next_frame
		page_corner.frame = next_frame
		page_flip.play()
	)
	page_corner_interaction.mouse_entered.connect(func():
		page_corner.animation = "PageCornerHover"
		page_corner.frame = page.frame
	)
	page_corner_interaction.mouse_exited.connect(func():
		page_corner.animation = "PageCorner"
		page_corner.frame = page.frame
	)
	leave.pressed.connect(func():
		get_parent().get_parent().on_hide_ui("tutorial")
		hide()
		get_tree().create_timer(0.5).timeout.connect(func():
			queue_free()
		)
	)

func _process(_delta: float) -> void:
	if page.frame == 0:
		if Options.controller:
			page.play("PageXB")
		else:
			page.play("Page")
