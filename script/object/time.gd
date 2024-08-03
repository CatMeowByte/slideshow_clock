class_name WidgetTime
extends Node

@export_node_path("Label") var node_hour_path: NodePath
@onready var NodeHour: Label = get_node(node_hour_path)

@export_node_path("Label") var node_minute_path: NodePath
@onready var NodeMinute: Label = get_node(node_minute_path)

@export_node_path("Control") var node_second_path: NodePath
@onready var NodeSecond: Control = get_node(node_second_path)

@export_node_path("Label") var node_period_path: NodePath
@onready var NodePeriod: Label = get_node(node_period_path)

signal hour_updated
signal minute_updated
signal second_updated
signal marker_triggered

var debug_unix_time: float = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system())

static var time: Dictionary = {
	"hour" : -1,
	"minute" : -1,
	"second" : -1,
}

var time_minute_base: int = -1


func _ready():
	hour_updated.connect(_on_hour_updated)
	minute_updated.connect(_on_minute_updated)
	second_updated.connect(_on_second_updated)


func _process(delta):
	var system_time: Dictionary = Time.get_time_dict_from_system()

	# Debug
	if Main.debug:
		debug_unix_time += 1800 * (int(Input.is_key_pressed(KEY_RIGHT)) - int(Input.is_key_pressed(KEY_LEFT)))
		debug_unix_time += 60 * (int(Input.is_key_pressed(KEY_DOWN)) - int(Input.is_key_pressed(KEY_UP)))
		system_time = Time.get_time_dict_from_unix_time(int(debug_unix_time))

	if not time.hour == system_time.hour:
		time.hour = system_time.hour
		hour_updated.emit()
	if not time.minute == system_time.minute:
		time.minute = system_time.minute
		minute_updated.emit()
	if not time.second == system_time.second:
		time.second = system_time.second
		second_updated.emit()


func _on_hour_updated():
	NodeHour.text = str(_hour_12(time.hour))
	NodePeriod.text = "AM" if time.hour < 12 else "PM"


func _on_minute_updated():
	NodeMinute.text = str(time.minute).pad_zeros(2)


	var praytimes = PrayTimes.get_praytimes(WidgetDate.gregorian.month, WidgetDate.gregorian.day)
	if not praytimes:
		return

	for marker in praytimes:
		if praytimes[marker] == (time.hour * 60) + time.minute:
			marker_triggered.emit(marker)


func _on_second_updated():
	NodeSecond.modulate.a = time.second % 2


# Convert to 12H format
func _hour_12(hour: int):
	return (hour + 11) % 12 + 1


# Convert string time (e.g. "08:25") into minute base integer (1440)
func _string_to_minute_base(text: String):
	var split = text.split(":")
	return (60 * int(split[0])) + int(split[1])
