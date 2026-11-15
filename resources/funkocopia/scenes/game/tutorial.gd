extends Overlay

@onready var page := $Page
@onready var page_corner := $PageCorner
@onready var page_corner_interaction := $PageCorner/Button
@onready var page_flip := $PageFlip

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
	
	super._ready()

func _process(delta: float) -> void:
	if page.frame == 0:
		if Options.controller:
			page.play("PageXB")
		else:
			page.play("Page")
	super._process(delta)
