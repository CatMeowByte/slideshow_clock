extends Control

@export_node_path("FileDialog") var node_file_dialog_path: NodePath
@onready var NodeFileDialog: FileDialog = get_node(node_file_dialog_path)

@export_node_path("Button") var node_file_buttons_path: NodePath
@onready var NodeFileButtons: Button = get_node(node_file_buttons_path)

@export_node_path("Slideshow") var node_slideshow_path: NodePath
@onready var NodeSlideshow: Slideshow = get_node(node_slideshow_path)

@export_node_path("RichTextLabel") var node_about_path: NodePath
@onready var NodeAbout: RichTextLabel = get_node(node_about_path)

@export_group("Praytimes Settings Node", "node_praytimes_path_")

@export_node_path("LineEdit") var node_praytimes_path_location: NodePath
@onready var NodePraytimesLocation: LineEdit = get_node(node_praytimes_path_location)

@export_node_path("OptionButton") var node_praytimes_path_calculation: NodePath
@onready var NodePraytimesCalculation: OptionButton = get_node(node_praytimes_path_calculation)

@export_node_path("OptionButton") var node_praytimes_path_latitude: NodePath
@onready var NodePraytimesLatitude: OptionButton = get_node(node_praytimes_path_latitude)

@export_node_path("OptionButton") var node_praytimes_path_shafaq: NodePath
@onready var NodePraytimesShafaq: OptionButton = get_node(node_praytimes_path_shafaq)

@export_node_path("OptionButton") var node_praytimes_path_hanafi: NodePath
@onready var NodePraytimesHanafi: OptionButton = get_node(node_praytimes_path_hanafi)

@export_node_path("OptionButton") var node_praytimes_path_jafari: NodePath
@onready var NodePraytimesJafari: OptionButton = get_node(node_praytimes_path_jafari)

@export_group("Display Settings Node", "node_display_")

@export_node_path("Button") var node_display_image_path: NodePath
@onready var NodeDisplayImagePath: Button = get_node(node_display_image_path)

@export_node_path("OptionButton") var node_display_language: NodePath
@onready var NodeDisplayLanguage: OptionButton = get_node(node_display_language)


func _ready():
	if not PrayTimes.is_data_available():
		PrayTimes.download_data(2000, "London", 0, 1, 0, false, false)

	_about_format()
	close()


func _input(event: InputEvent):
	if Input.is_action_just_released("ui_cancel"):
		if visible:
			close()
		else:
			open()


func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.is_pressed() and event.get_button_index() == MOUSE_BUTTON_LEFT:
		close()


func close():
	visible = false


func open():
	_read_config()
	visible = true


#region Menu
func _on_button_return_pressed():
	close()


func _on_button_fullscreen_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_button_quit_pressed():
	get_tree().quit()
#endregion


#region About
func _on_meta_clicked(meta):
	OS.shell_open(str(meta))

func _about_format():
	NodeAbout.text = NodeAbout.text.format({
		"version" = ProjectSettings.get_setting("application/config/version"),
	})
#endregion


func _read_config():
	Config.config_load()

	# Praytimes
	NodePraytimesLocation.text = Config.location
	NodePraytimesCalculation.select(Config.calculation_method)
	NodePraytimesLatitude.select(Config.latitude_method)
	NodePraytimesShafaq.select(Config.shafaq)
	NodePraytimesHanafi.select(int(Config.hanafi))
	NodePraytimesJafari.select(int(Config.jafari))

	# Display
	NodeDisplayImagePath.text = Config.image_path
	NodeDisplayLanguage.select(["en", "id"].find(Config.language))


#region Praytimes
func _on_button_praytimes_update_pressed():
	var year: int = WidgetDate.gregorian.year - int(WidgetDate.gregorian.year % 4 == 0 and (WidgetDate.gregorian.year % 100 != 0 or WidgetDate.gregorian.year % 400 == 0))
	Config.location = NodePraytimesLocation.text
	Config.calculation_method = NodePraytimesCalculation.get_selected_id()
	Config.latitude_method = NodePraytimesLatitude.get_selected_id()
	Config.shafaq = NodePraytimesShafaq.get_selected_id()
	Config.hanafi = bool(NodePraytimesHanafi.get_selected_id())
	Config.jafari = bool(NodePraytimesJafari.get_selected_id())
	Config.config_save()
	PrayTimes.download_data(year, Config.location, Config.calculation_method, Config.latitude_method, Config.shafaq, Config.hanafi, Config.jafari)
#endregion


#region Settings
func _on_button_setting_file_pressed():
	NodeFileDialog.visible = true


func _on_file_dir_selected(dir: String):
	NodeFileButtons.text = dir
	NodeFileButtons.tooltip_text = dir

	Config.image_path = dir
	Config.config_save()

	NodeSlideshow.image_path = dir
	NodeSlideshow.slideshow_start()


func _on_setting_language_selected(index: int):
	var language = ["en", "id"][index]
	TranslationServer.set_locale(language)

	Config.language = language
	Config.config_save()
#endregion
