extends Node

const DWMWA_BORDER_COLOR := 34
const DWMWA_CAPTION_COLOR := 35
const DWMWA_TEXT_COLOR := 36

func convert_color(color: Color) -> int:
	return color.r8 | (color.g8 << 8) | (color.b8 << 16)

func set_dwm_attributes(attrs: Dictionary) -> void:
	if OS.get_name() != "Windows":
		return

	var hwnd := DisplayServer.window_get_native_handle(
		DisplayServer.WINDOW_HANDLE,
		get_window().get_window_id()
	)

	var script := "Add-Type -MemberDefinition '[DllImport(\"dwmapi.dll\")] public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int val, int size);' -Name DwmNative -Namespace Win32\n"
	for attr in attrs:
		script += "$v = %d; $r = [Win32.DwmNative]::DwmSetWindowAttribute([IntPtr]%d, %d, [ref]$v, 4); Write-Output 'attr %d HRESULT:' $r\n" % [attrs[attr], hwnd, attr, attr]

	var path := ProjectSettings.globalize_path("user://dwm.ps1")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(script)
	f.close()

	var output := []
	OS.execute("powershell", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", path], output, true)

func _ready() -> void:
	set_dwm_attributes({
		DWMWA_CAPTION_COLOR: convert_color(Color("6963FF")),
		DWMWA_BORDER_COLOR: convert_color(Color("FFE9D5")),
	})
