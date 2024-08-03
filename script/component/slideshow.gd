class_name Slideshow
extends MarginContainer

# MarginContainer makes the child expands to the size of the parent

## Path to image files
@export_global_dir var image_path: String

@export_group("Duration", "duration_")
## Pan movement duration
@export var duration_slide: float = 6.0
## Crossfade duration, capped to be less than half of `duration_slide`
@export var duration_fade: float = 1.0

# List of image files
var _image_files: Array

func _ready():
	# Clean nodes
	for child in get_children():
		child.queue_free()

	# Create nodes
	for i in range(2):
		var scroll: ScrollContainer = ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		scroll.modulate.a = 0
		add_child(scroll)

		var texture: TextureRect = TextureRect.new()
		texture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texture.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.add_child(texture)

	await get_tree().process_frame
	slideshow_start()


func slideshow_start():
	if not image_path:
		return

	var dir = DirAccess.open(image_path)

	# Early bail
	if not dir:
		printerr("An error occurred when trying to access the path: ", image_path)
		return

	# Scan files
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if not dir.current_is_dir():
			if file.get_extension().to_lower() in ["png", "jpg", "jpeg", "bmp"]:
				print("Found image: " + file)
				_image_files.append(file)
		file = dir.get_next()

	_image_files.shuffle()

	# Start
	_slide()


func _slide(index: int = 0):
	var file = image_path + ("" if image_path.ends_with("/") else "/") + _image_files[index]

	# Early bail
	if not FileAccess.file_exists(file):
		printerr("An error occurred when trying to access the file: ", file)
		return

	var node_scroll: Node = get_child(1)
	var node_texture: Node = node_scroll.get_child(0)
	var image: ImageTexture = ImageTexture.create_from_image(
		Image.load_from_file(file)
	)
	var image_size: Vector2 = image.get_size()
	var scroll_direction: int = 0 if image_size.x > image_size.y else 1
	var ratio: float = float(maxi(image_size.x, image_size.y)) / float(mini(image_size.x, image_size.y))
	var scroll_amount: int = node_scroll.size[scroll_direction] * (ratio - 1.0)
	var string_direction = "scroll_vertical" if scroll_direction else "scroll_horizontal"
	node_texture.texture = image
	node_texture.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL if scroll_direction else TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	node_scroll.set(string_direction, 0 if randi() % 2 == 0 else scroll_amount)
	node_scroll.create_tween().tween_property(node_scroll, string_direction, 0 if node_scroll.get(string_direction) else scroll_amount, duration_slide)

	duration_fade = min(duration_fade, duration_slide / 2)
	var tween = node_scroll.create_tween()
	tween.tween_property(node_scroll, "modulate:a", 1.0, duration_fade)
	tween.tween_interval(duration_slide - (duration_fade * 2))
	tween.tween_callback(move_child.bind(node_scroll, 0))
	tween.parallel().tween_property(get_child(0), "modulate:a", 0.0, 0.0)
	tween.parallel().tween_callback(_slide.bind(wrapi(index + 1, 0, _image_files.size())))
