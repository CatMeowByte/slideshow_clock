extends Control

@export_node_path("Label") var node_time_path: NodePath
@onready var NodeTime: Label = get_node(node_time_path)

@export_node_path("Label") var node_name_path: NodePath
@onready var NodeName: Label = get_node(node_name_path)

@export var duration: int = 5 * 60 if not Main.debug else 5

const MARKER_SKIPPED: PackedStringArray = [
	"Firstthird",
	"Midnight",
	"Lastthird",
	"Imsak",
	"Sunrise",
	"Sunset",
]

func _ready():
	visible = true
	modulate.a = 0.0

func _on_marker_triggered(marker: String):
	if marker in MARKER_SKIPPED:
		return

	NodeName.text = T.PRAYTIMES_NAME[marker]

	# Jumu'ah prayer
	if WidgetDate.gregorian.weekday == 5 and marker == "Dhuhr":
		NodeName.text = T.WEEKDAY_NAME_HIJRI[5]

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)
	tween.tween_interval(duration)
	tween.parallel().tween_callback(_blink)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)


func _on_minute_updated():
	NodeTime.text = "{hour} : {minute}".format({
		"hour" = str(WidgetTime.time.hour % 12),
		"minute" = str(WidgetTime.time.minute).pad_zeros(2),
	})

	NodeTime.text += " " + ("AM" if WidgetTime.time.hour < 12 else "PM")

func _blink():
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_EXPO)
	tween.tween_property(NodeName, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	tween.tween_property(NodeName, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_OUT)
