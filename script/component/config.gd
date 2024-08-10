class_name Config
extends Node
## Configuration

signal config_updated

static var config = ConfigFile.new()

const CONFIG_PATH = "user://settings.config"

#region Setting Variable
# Display
static var image_path: String
static var language: String

# Praytimes
static var location: String
static var calculation_method: int
static var latitude_method: int
static var shafaq: int
static var hanafi: bool
static var jafari: bool
#endregion


func _ready():
	config_set()

static func config_load():
	if not config.load(CONFIG_PATH) == OK:
		printerr("Unable to load configuration file")

	var section: String

	# Display
	section = "Display"
	image_path = config.get_value(section, "image_path", OS.get_executable_path())
	language = config.get_value(section, "language", "en")

	# Praytimes
	section = "Praytimes"
	location = config.get_value(section, "location", "London")
	calculation_method = config.get_value(section, "calculation_method", 0)
	latitude_method = config.get_value(section, "latitude_method", 3)
	shafaq = config.get_value(section, "shafaq", 0)
	hanafi = config.get_value(section, "hanafi", false)
	jafari = config.get_value(section, "jafari", false)

	print_verbose("Configuration loaded.")


static func config_save():
	var section: String

	# Display
	section = "Display"
	config.set_value(section, "image_path", image_path)
	config.set_value(section, "language", language)

	# Praytimes
	section = "Praytimes"
	config.set_value(section, "location", location)
	config.set_value(section, "calculation_method", calculation_method)
	config.set_value(section, "latitude_method", latitude_method)
	config.set_value(section, "shafaq", shafaq)
	config.set_value(section, "hanafi", hanafi)
	config.set_value(section, "jafari", jafari)

	if not config.save(CONFIG_PATH) == OK:
		printerr("Unable to save configuration file.")

	print_verbose("Configuration saved.")


func config_set(reset: bool = false):
	if reset:
		config.clear()
		config.save(CONFIG_PATH)
	Config.config_load()
	Config.config_save() # Precaution if no file exist
	await get_tree().process_frame # Wait next frame
	config_updated.emit()
