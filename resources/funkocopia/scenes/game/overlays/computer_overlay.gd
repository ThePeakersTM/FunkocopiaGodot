extends Overlay

const _gallery_path = "res://assets/funkocopia/rooms/overlay/compooter/gallery"

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
	) and load(_gallery_path + "/" + file) is Texture2D))
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
	var inside_folder: Array = folder_contents[folder]
	var row := 1.0
	var col := 0.0
	for item: String in inside_folder:
		var item_texture = _load_element_texture(item)
		
		var element := TextureButton.new()
		element.name = item.replace(".", "#")
		element.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		element.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		element.texture_normal = item_texture
		element.size.x = item_texture.get_width()
		element.size.y = item_texture.get_height()
		element.position = Vector2(row, col)
		element.pressed.connect(func():
			if desktop_screen.visible:
				if file_explorer.visible:
					if Options.double_pressed("left_click"):
						_on_open_app(element.name)
		)
		file_explorer_items_area.add_child(element)
		
		row += element.size.x + 3
		if row > file_explorer.texture.get_width() - 48:
			row = 1
			col += 37
	
	var height := col + 35
	
	if height > 90:
		file_explorer_disabled_scroller.visible = false
		file_explorer_scroll_bar.visible = true
		file_explorer_scroll_bar.max_value = height / 90.0
	else:
		file_explorer_disabled_scroller.visible = true
		file_explorer_scroll_bar.visible = false
		

func _on_open_app(app_name: String) -> void:
	var app_name_ext := app_name.rsplit(".", true, 1)
	var app_ext := "" if app_name_ext.size() == 1 else app_name_ext[1]
	var is_folder := app_ext == ""
	if is_folder:
		_open_file_explorer(app_name)

const _arrow_change_value := 0.1

func _ready() -> void:
	print(folder_contents["Gallery"])
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
			if file_explorer.visible and not (false):
				file_explorer.visible = false
	)
	
	file_explorer_scroll_bar_up_button.mouse_entered.connect(func(): touching_file_explorer_scroll_bar_up_button = true )
	file_explorer_scroll_bar_up_button.mouse_exited.connect( func(): touching_file_explorer_scroll_bar_up_button = false)
	
	file_explorer_scroll_bar_down_button.mouse_entered.connect(func(): touching_file_explorer_scroll_bar_down_button = true )
	file_explorer_scroll_bar_down_button.mouse_exited.connect( func(): touching_file_explorer_scroll_bar_down_button = false)
	
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
		if file_explorer:
			if file_explorer_scroll_bar.visible:
				file_explorer_scroll_bar_center.position.y = floor(get_grabber_y(
					file_explorer_scroll_bar,
					1
				) - 3)
				file_explorer_items_area.position.y = (
					file_explorer_scroll_bar.value * -90
				)
				if Options.das("left_click"):
					if touching_file_explorer_scroll_bar_down_button:
						file_explorer_scroll_bar.value += _arrow_change_value
						if file_explorer_scroll_bar.value > file_explorer_scroll_bar.max_value:
							file_explorer_scroll_bar.value = file_explorer_scroll_bar.max_value
					if touching_file_explorer_scroll_bar_up_button:
						file_explorer_scroll_bar.value -= _arrow_change_value
						if file_explorer_scroll_bar.value < file_explorer_scroll_bar.min_value:
							file_explorer_scroll_bar.value = file_explorer_scroll_bar.min_value
	super._process(delta)
