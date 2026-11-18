extends Overlay

const _gallery_path = "res://assets/funkocopia/rooms/overlay/compooter/gallery"

func is_file_an_image(file: String) -> bool:
	if not FileAccess.file_exists(file): return false
	return load(file) is Texture2D

var folder_contents: Dictionary[String, Array] = {
	"asfahik": [
		"Doors.exe",
		#"RICHARD.exe"
	],
	"Gallery": (
		func(a: Array):
			a.sort_custom(func(x, y): return x.nocasecmp_to(y) < 0)
			return a).call(Array(DirAccess.get_files_at(
		_gallery_path
	)).filter(func(file): return (
		not file.ends_with(".import")
	) and is_file_an_image("%s/%s" % [_gallery_path, file])))
}

@onready var on_off_button := $OnOffButton
@onready var button_sound := $OnOffButton/Sound

@onready var computer_boot := $ComputerStart

@onready var loading_screen := $ScreenElements/LoadingScreen
@onready var loading_bar := $ScreenElements/LoadingScreen/LoadingBar

@onready var accounts_screen := $ScreenElements/AccountsScreen
@onready var accounts := $ScreenElements/AccountsScreen/Accounts

@onready var desktop_screen := $ScreenElements/DesktopScreen

@onready var file_explorer := $ScreenElements/DesktopScreen/FileExplorer
@onready var file_explorer_scroll_bar := $ScreenElements/DesktopScreen/FileExplorer/ScrollBar
@onready var file_explorer_scroll_bar_up_button := $ScreenElements/DesktopScreen/FileExplorer/ScrollBar/Up
@onready var file_explorer_scroll_bar_down_button := $ScreenElements/DesktopScreen/FileExplorer/ScrollBar/Down
@onready var file_explorer_scroll_bar_center := $ScreenElements/DesktopScreen/FileExplorer/ScrollBar/TextureRect
@onready var file_explorer_disabled_scroller := $ScreenElements/DesktopScreen/FileExplorer/DisabledScroller
@onready var file_explorer_exit := $ScreenElements/DesktopScreen/FileExplorer/CloseButton
@onready var file_explorer_inside_area := $ScreenElements/DesktopScreen/FileExplorer/InsideArea
@onready var file_explorer_items_area := $ScreenElements/DesktopScreen/FileExplorer/InsideArea/ScrollingArea

@onready var image_viewer := $ScreenElements/DesktopScreen/ImageViewer
@onready var image_viewer_exit := $ScreenElements/DesktopScreen/ImageViewer/CloseButton
@onready var image_viewer_image := $ScreenElements/DesktopScreen/ImageViewer/TextureRect
@onready var image_viewer_anim := $ScreenElements/DesktopScreen/ImageViewer/ColorRect

@onready var doors_window := $ScreenElements/DesktopScreen/DoorsWindow
@onready var doors_window_loading := $ScreenElements/DesktopScreen/DoorsWindow/Loading
@onready var doors_window_doors := $ScreenElements/DesktopScreen/DoorsWindow/Doors
@onready var doors_window_exit := $ScreenElements/DesktopScreen/DoorsWindow/CloseButton
@onready var doors_window_door_anim := $ScreenElements/DesktopScreen/DoorsWindow/DoorAnim

var touching_file_explorer_scroll_bar_up_button := false
var touching_file_explorer_scroll_bar_down_button := false

var did_play_button_sound := false

var powered_on := false

func _plug_connected() -> bool:
	return room.plug.modulate.a < 1

func _turn_on() -> void:
	computer_boot.play()
	loading_bar.visible = false
	create_tween().tween_method(
		func(val): loading_screen.modulate = Color(1, 1, 1, val),
		0.0,
		1.0,
		0.75
	).finished.connect(func():
		get_tree().create_timer(0.5).timeout.connect(func():
			loading_bar.visible = true
			create_tween().tween_method(
				func(val):
					loading_bar.position = Vector2(45 + ((val % 10) * 8), 104),
				0,
				26,
				2.7
			).finished.connect(func():
				get_tree().create_timer(1).timeout.connect(func():
					loading_screen.modulate = Color.TRANSPARENT
					get_tree().create_timer(0.5).timeout.connect(func():
						accounts_screen.visible = true
						accounts.play("appear")
					)
				)
			)
		)
	)

func _turn_off() -> void:
	powered_on              = false
	loading_screen.modulate = Color.TRANSPARENT
	loading_screen.visible  = true
	accounts_screen.visible = false
	desktop_screen.visible  = false
	file_explorer.visible   = false
	image_viewer.visible    = false
	doors_window.visible    = false
	accounts.play("invis")

func _load_element_texture(app_name: String) -> Texture2D:
	var full_path = "res://assets/funkocopia/rooms/overlay/compooter/elements/" + app_name + ".tres"
	if not FileAccess.file_exists(full_path):
		push_warning("Failed to load texture with filename of \"%s\"." % full_path)
		return load("res://assets/funkocopia/rooms/overlay/compooter/compooter.png")
	return load(full_path)

func _open_file_explorer(folder: String) -> void:
	for i in file_explorer_items_area.get_children():
		i.queue_free()
	
	file_explorer.visible = true
	file_explorer_scroll_bar.value = 0
	file_explorer_items_area.position.y = 0
	var inside_folder: Array = folder_contents[folder]
	var row := 1.0
	var col := 1.0
	for i: int in inside_folder.size():
		var item: String = inside_folder[i]
		var item_texture = _load_element_texture(item)
		
		var element := TextureButton.new()
		element.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		element.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		element.texture_normal = item_texture
		element.size.x = item_texture.get_width()
		element.size.y = item_texture.get_height()
		element.position = Vector2(row, col)
		element.pressed.connect(func():
			if desktop_screen.visible:
				if file_explorer.visible and not (image_viewer.visible or doors_window.visible):
					if Options.double_pressed("left_click"):
						_on_open_app(element.name.replace("#", "."))
		)
		file_explorer_items_area.add_child(element)
		element.name = item.replace(".", "#")
		
		if i != inside_folder.size() - 1:
			row += element.size.x + 3
			if row > file_explorer.texture.get_width() - 48:
				row = 1
				col += 37
	
	var height: float = col + 36.0
	
	if height > 90:
		file_explorer_disabled_scroller.visible = false
		file_explorer_scroll_bar.visible = true
		file_explorer_scroll_bar.max_value = height / 90.0
	else:
		file_explorer_disabled_scroller.visible = true
		file_explorer_scroll_bar.visible = false
		

func _on_open_app(app_name: String) -> void:
	var irl_name = app_name.replace("#", ".").rstrip("2")
	var app_name_ext := irl_name.rsplit(".", true, 1)
	var app_ext := "" if app_name_ext.size() == 1 else app_name_ext[1]
	var is_folder := app_ext == "" and not app_name.contains("@")
	if is_folder:
		_open_file_explorer(irl_name)
	else:
		var img := "%s/%s" % [_gallery_path, irl_name]
		if is_file_an_image(img):
			image_viewer.visible = true
			var image: Texture2D = load(img)
			image_viewer_image.texture = image
			image_viewer_image.size = image.get_size()
			var scale_thing := maxf(image.get_width(), image.get_height()) / 24.5
			image_viewer_image.scale = Vector2(
				5 / scale_thing,
				5 / scale_thing
			)
			image_viewer_anim.size = Vector2(
				(image.get_width()  * image_viewer_image.scale.x),
				(image.get_height() * image_viewer_image.scale.y)
			)
			image_viewer.size = Vector2(
				(image.get_width()  * image_viewer_image.scale.x) + 12,
				(image.get_height() * image_viewer_image.scale.y) + 22
			)
			image_viewer.position = Vector2(
				(203.0 - image_viewer.size.x) / 2.0,
				((154.0 - image_viewer.size.y) / 2.0) - 2
			)
			image_viewer_anim.visible = true
			create_tween().tween_method(
				func(val: float):
					var v := snappedi(roundf(val), 15)
					image_viewer_anim.position.y = (
						image.get_height() * image_viewer_image.scale.y
					) - v + 17
					image_viewer_anim.size.y = v,
				image.get_height() * image_viewer_image.scale.y,
				0.0,
				1.5
			).finished.connect(func():
				image_viewer_anim.visible = false
			)
		elif app_ext == "exe":
			if irl_name == "Doors.exe":
				doors_window_door_anim.visible = false
				doors_window.visible = true
				doors_window_loading.visible = true
				for door in doors_window_doors.get_children():
					door.modulate = Color.TRANSPARENT
				get_tree().create_timer(2).timeout.connect(func():
					doors_window_loading.visible = false
					var doors = doors_window_doors.get_children()
					for i in doors.size():
						var door: TextureButton = doors[i]
						get_tree().create_timer((i+1)/8.0).timeout.connect(func():
							if i not in got_doors:
								door.modulate = Color.WHITE
						)
				)

var got_doors: Array[int] = []

const _arrow_change_value := 0.1

func _ready() -> void:
	_turn_off()
	on_off_button.pressed.connect(func():
		if _plug_connected():
			powered_on = not powered_on
			if powered_on:
				_turn_on()
			else:
				_turn_off()
	)
	accounts.get_node("Bfellow").pressed.connect(func():
		if accounts.animation == "idle":
			accounts.play("disappear")
	)
	accounts.get_node("Henry").pressed.connect(func():
		if accounts.animation == "idle":
			accounts.play("henry")
			accounts.get_node("Sound").play()
	)
	var desktop_icons = desktop_screen.get_node("Elements").get_children()
	for icon: TextureButton in desktop_icons:
		icon.pressed.connect(func():
			if Options.double_pressed("left_click"):
				if not (file_explorer.visible):
					_on_open_app(icon.name.replace("#", "."))
		)
	file_explorer_exit.pressed.connect(func():
		if desktop_screen.visible:
			if file_explorer.visible and not (image_viewer.visible or doors_window.visible):
				file_explorer.visible = false
	)
	
	file_explorer_scroll_bar_up_button.mouse_entered.connect(func(): touching_file_explorer_scroll_bar_up_button = true )
	file_explorer_scroll_bar_up_button.mouse_exited.connect( func(): touching_file_explorer_scroll_bar_up_button = false)
	
	file_explorer_scroll_bar_down_button.mouse_entered.connect(func(): touching_file_explorer_scroll_bar_down_button = true )
	file_explorer_scroll_bar_down_button.mouse_exited.connect( func(): touching_file_explorer_scroll_bar_down_button = false)
	
	image_viewer_exit.pressed.connect(func():
		if desktop_screen.visible:
			if image_viewer.visible:
				image_viewer.visible = false
	)
	
	doors_window_exit.pressed.connect(func():
		if desktop_screen.visible:
			if doors_window.visible:
				doors_window.visible = false
	)
	
	var doors = doors_window_doors.get_children()
	for i in doors.size():
		var door: TextureButton = doors[i]
		door.pressed.connect(func():
			if desktop_screen.visible:
				if doors_window.visible:
					if door.modulate == Color.WHITE:
						if not door.disabled:
							door.modulate = Color.TRANSPARENT
							door.mouse_default_cursor_shape = Control.CURSOR_ARROW
							doors_window_door_anim.global_position = door.global_position
							doors_window_door_anim.visible = true
							doors_window_door_anim.play()
							if not i in got_doors:
								got_doors.append(i)
		)
	
	super._ready()

const ICON_SUMMON_DELAY := 0.25
const ICON_FOR_EACH_DELAY := 0.125

func _show_desktop() -> void:
	desktop_screen.visible  = true
	var desktop_icons = desktop_screen.get_node("Elements").get_children()
	for i in desktop_icons.size():
		var icon: TextureButton = desktop_icons[i]
		icon.visible = false
		get_tree().create_timer(ICON_SUMMON_DELAY + (ICON_FOR_EACH_DELAY * i)).timeout.connect(func():
			icon.visible = true
		)

func get_grabber_y(vscroll: VScrollBar, alignment: int = 0) -> float:
	var scroll_style: StyleBox = vscroll.get_theme_stylebox("scroll")
	var margin_top: float = scroll_style.get_margin(SIDE_TOP)
	var margin_bottom: float = scroll_style.get_margin(SIDE_BOTTOM)
	
	var track_height: float = vscroll.size.y - (margin_top + margin_bottom)
	
	var total_range: float = vscroll.max_value - vscroll.min_value
	if total_range <= 0.0:
		return margin_top
		
	var grabber_height: float = (vscroll.page / total_range) * track_height
	var grabber_style: StyleBox = vscroll.get_theme_stylebox("grabber")
	grabber_height = max(grabber_height, grabber_style.get_minimum_size().y)
	
	var travel_distance: float = track_height - grabber_height
	
	var max_scroll: float = total_range - vscroll.page
	if max_scroll <= 0.0:
		return margin_top
		
	var progress: float = (vscroll.value - vscroll.min_value) / max_scroll
	
	return margin_top + (progress * travel_distance) + grabber_height * (alignment * 0.5)

func _process(delta: float) -> void:
	if not _plug_connected():
		_turn_off()
	if on_off_button.button_pressed:
		if not did_play_button_sound:
			button_sound.play()
		did_play_button_sound = true
	else:
		did_play_button_sound = false
	if (
		accounts.frame == 2 and accounts.animation == "appear"
	) or (
		accounts.frame == 5 and accounts.animation == "henry"
	):
		accounts.play("idle")
	if accounts.frame == 3 and accounts.animation == "disappear" and accounts_screen.visible:
		accounts_screen.visible = false
		_show_desktop()
	if desktop_screen.visible:
		if file_explorer.visible and not (image_viewer.visible or doors_window.visible):
			if file_explorer_scroll_bar.visible:
				file_explorer_scroll_bar_center.position.y = floor(get_grabber_y(
					file_explorer_scroll_bar,
					1
				) - 3)
				file_explorer_items_area.position.y = (
					file_explorer_scroll_bar.value * -90
				)
				var scroll_up := false
				var scroll_down := false
				if Options.das("left_click"):
					if touching_file_explorer_scroll_bar_down_button:
						scroll_down = true
					if touching_file_explorer_scroll_bar_up_button:
						scroll_up = true
				
				if Input.is_action_just_pressed("scroll_up"):
					scroll_up = true
				
				if Input.is_action_just_pressed("scroll_down"):
					scroll_down = true
				
				if scroll_up and scroll_down:
					scroll_up = false
					scroll_down = false
				
				if scroll_up:
					file_explorer_scroll_bar.value -= _arrow_change_value
					if file_explorer_scroll_bar.value < file_explorer_scroll_bar.min_value:
						file_explorer_scroll_bar.value = file_explorer_scroll_bar.min_value
				if scroll_down:
					file_explorer_scroll_bar.value += _arrow_change_value
					if file_explorer_scroll_bar.value > file_explorer_scroll_bar.max_value:
						file_explorer_scroll_bar.value = file_explorer_scroll_bar.max_value
	if doors_window_door_anim.frame == 5:
		doors_window_door_anim.visible = false
	
	super._process(delta)

func _on_exit() -> void:
	if 0 in got_doors:
		room.door.play("appear")
		room.door.visible = true
