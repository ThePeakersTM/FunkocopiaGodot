extends Room

@onready var gf_chair := $GFChair
@onready var gf_chair_interaction := $GFChair/Control
@onready var camera := $"../Camera2D"

@onready var dart_cake := $FunnyThings/DartCake
@onready var dart_cake_interaction := $FunnyThings/DartCake/Control
@onready var dart_cake_sound := $FunnyThings/DartCake/Sound

@onready var fih := $FunnyThings/Fih
@onready var fih_interaction := $FunnyThings/Fih/Control
@onready var fih_sound := $FunnyThings/Fih/Sound

@onready var outlet := $FunnyThings/Outlet
@onready var outlet_interaction := $FunnyThings/Outlet/Control
@onready var outlet_sound := $FunnyThings/Outlet/Sound

@onready var clockey := $Clockey

var touching_boobs := false

var touching_dart_cake := false
var touching_fih := false
var touching_outlet := false

var blink_timer := 25

func _ready() -> void:
	gf_chair.play("spin")
	gf_chair_interaction.mouse_entered.connect(func(): touching_boobs = true )
	gf_chair_interaction.mouse_exited.connect( func(): touching_boobs = false)
	
	dart_cake.play("idle")
	dart_cake_interaction.mouse_entered.connect(func(): touching_dart_cake = true )
	dart_cake_interaction.mouse_exited.connect( func(): touching_dart_cake = false)
	
	fih.play("idle")
	fih_interaction.mouse_entered.connect(func(): touching_fih = true )
	fih_interaction.mouse_exited.connect( func(): touching_fih = false)
	
	outlet.play("idle")
	outlet_interaction.mouse_entered.connect(func(): touching_outlet = true )
	outlet_interaction.mouse_exited.connect( func(): touching_outlet = false)

func _process(_delta: float) -> void:
	blink_timer += 1
	if camera.in_ui: return
	if player.position.y <= 595:
		var y_factor = (player.position.y - 315) / 280
		var thing = round(((y_factor * 1.5) + 3.5) * 5) / 5
		player.scale = Vector2(thing, thing)
		player.anim_sprite.offset.y = -(y_factor / 35) - 28
	else:
		player.scale = Vector2(5, 5)
		player.anim_sprite.offset.y = -32
	var clockey_cx = clockey.position.x + 80
	var player_cx = player.position.x
	var clockey_dir = ""
	if abs(Vector2(clockey_cx, 0).distance_to(Vector2(player_cx, 0))) < 200:
		clockey_dir = "front"
	elif player_cx < clockey_cx:
		clockey_dir = "left"
	else:
		clockey_dir = "right"
	if clockey.animation != clockey_dir + "_blink":
		clockey.play(clockey_dir + "_idle")
	if blink_timer > 3500:
		blink_timer = 0
		clockey.play(clockey_dir + "_blink")
	if clockey.animation == clockey_dir + "_blink" and clockey.frame == 2:
		clockey.play(clockey_dir + "_idle")
	if dart_cake.animation == "anim" and dart_cake.frame == 23:
		dart_cake.play("idle")
	if fih.animation == "anim" and fih.frame == 8:
		fih.play("idle")
	if outlet.animation == "anim" and outlet.frame == 15:
		outlet.play("idle")
	if Input.is_action_just_pressed("left_click"):
		if touching_boobs:
			BoobExceptionHandler.exception()
		if touching_dart_cake:
			dart_cake.play("anim")
			dart_cake_sound.play()
		if touching_fih:
			fih.play("anim")
			fih_sound.play()
		if touching_outlet:
			outlet.play("anim")
			outlet_sound.play()
