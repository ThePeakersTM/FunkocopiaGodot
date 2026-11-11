extends RefCounted
class_name CameraCapture

static func capture(viewport: Viewport) -> ImageTexture:
	await RenderingServer.frame_post_draw
	
	var image := viewport.get_texture().get_image()
	
	return ImageTexture.create_from_image(image)
