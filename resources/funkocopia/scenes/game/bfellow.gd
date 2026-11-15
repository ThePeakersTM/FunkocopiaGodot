extends TopDownCharacter2D

const DEFAULT_OFFSET := Vector2(0, -27)
const SPEED := 350

var _true_pos: Vector2 = Vector2.ZERO
var can_process_data := true
var blink_timer: int = 0

func _ready() -> void:
	_true_pos = position

func set_pos(pos: Vector2) -> void:
	position = pos.snapped(Vector2(5, 5))
	_true_pos = position

var velocity_dist := 1.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	blink_timer += 1
	
	if get_parent().get_node("Camera2D").in_ui == true: return
	if not can_process_data:
		var complete_anim := false
		if anim_animation == "plug":
			anim_sprite.position = Vector2(-6, -20)
			if anim_sprite.frame == (0 if last_played_backwards else 18):
				get_parent().room.on_plug()
				complete_anim = true
		if anim_animation == "jump":
			anim_sprite.position = Vector2(-1, -57)
			if anim_sprite.frame == 11:
				complete_anim = true
		if anim_animation == "get_up":
			if anim_sprite.frame == (0 if last_played_backwards else 8):
				complete_anim = true
				if last_played_backwards:
					get_parent().load_overlay("tutorial")
		if complete_anim:
			play("idle")
			can_process_data = true
			anim_sprite.position = DEFAULT_OFFSET
		return
	else:
		anim_sprite.position = DEFAULT_OFFSET
		
	
	position = _true_pos
	velocity.x = 0
	velocity.y = 0
	if not navigating:
		if Input.is_key_pressed(KEY_W):
			velocity.y -= SPEED
		if Input.is_key_pressed(KEY_S):
			velocity.y += SPEED
		if Input.is_key_pressed(KEY_A):
			velocity.x -= SPEED
		if Input.is_key_pressed(KEY_D):
			velocity.x += SPEED
		if Options.controller:
			var gx := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
			var gy := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
			
			if abs(gx) < Options.controller_deadzone:
				gx = 0
			if abs(gy) < Options.controller_deadzone:
				gy = 0
			gx = signf(gx)
			gy = signf(gy)
			velocity.x += gx * SPEED
			velocity.y += gy * SPEED
		velocity_dist = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
		if velocity_dist > 1:
			velocity_dist = 1.25
		if velocity.x != 0 and velocity.y != 0:
			velocity = Vector2(
				velocity.x / velocity_dist,
				velocity.y / velocity_dist
			)
	else:
		velocity = navigation_velocity * SPEED
	calculate_normals()
	if moving:
		play("walk", (max(abs(velocity.x), abs(velocity.y)) / SPEED) * 1.25)
	else:
		if anim_animation != "blink":
			play("idle", 1)
		if blink_timer > 5000:
			blink_timer = 0
			play("blink", 1)
		if anim_animation == "blink" and anim_sprite.frame == 2:
			play("idle", 1)
	move_and_slide()
	_true_pos = position
	position = position.snapped(Vector2(5, 5))
