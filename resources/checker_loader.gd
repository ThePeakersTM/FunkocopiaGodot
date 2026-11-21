class_name CheckerLoader

static func load_with_checker(
		path: String,
		cell: int = 8,
		light: Color = Color(0.8, 0.8, 0.8),
		dark: Color = Color(0.6, 0.6, 0.6)
) -> Texture2D:
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		push_error("Could not load image: %s" % path)
		return null

	img.convert(Image.FORMAT_RGBA8)  # make sure there's an alpha channel

	var result := _make_checker(img.get_size(), cell, light, dark)
	result.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i.ZERO)

	return ImageTexture.create_from_image(result)


static func _make_checker(size: Vector2i, cell: int, light: Color, dark: Color) -> Image:
	# Build one 2x2-cell tile
	var img := Image.create(cell * 2, cell * 2, false, Image.FORMAT_RGBA8)
	img.fill(light)
	img.fill_rect(Rect2i(cell, 0, cell, cell), dark)
	img.fill_rect(Rect2i(0, cell, cell, cell), dark)

	# Double it horizontally until it's wide enough
	while img.get_width() < size.x:
		var wide := Image.create(img.get_width() * 2, img.get_height(), false, Image.FORMAT_RGBA8)
		var r := Rect2i(Vector2i.ZERO, img.get_size())
		wide.blit_rect(img, r, Vector2i.ZERO)
		wide.blit_rect(img, r, Vector2i(img.get_width(), 0))
		img = wide

	# Then vertically
	while img.get_height() < size.y:
		var tall := Image.create(img.get_width(), img.get_height() * 2, false, Image.FORMAT_RGBA8)
		var r := Rect2i(Vector2i.ZERO, img.get_size())
		tall.blit_rect(img, r, Vector2i.ZERO)
		tall.blit_rect(img, r, Vector2i(0, img.get_height()))
		img = tall

	return img.get_region(Rect2i(Vector2i.ZERO, size))
