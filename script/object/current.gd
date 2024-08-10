extends Node

@export_node_path("Label") var node_present_name_path: NodePath
@onready var NodePresentName: Label = get_node(node_present_name_path)

@export_node_path("Label") var node_present_timespan_path: NodePath
@onready var NodePresentTimespan: Label = get_node(node_present_timespan_path)

@export_node_path("Label") var node_future_name_path: NodePath
@onready var NodeFutureName: Label = get_node(node_future_name_path)

@export_node_path("Label") var node_future_timespan_path: NodePath
@onready var NodeFutureTimespan: Label = get_node(node_future_timespan_path)


func _on_minute_updated():
	# Early bail
	if not PrayTimes.is_data_available():
		return

	if WidgetDate.gregorian.month == -1 or WidgetDate.gregorian.day == -1:
		return

	var praytimes: Dictionary = PrayTimes.get_praytimes(WidgetDate.gregorian.month, WidgetDate.gregorian.day)
	if not praytimes:
		return

	# Remove uninteresting time
	praytimes.erase("Sunset")
	praytimes.erase("Firstthird")
	praytimes.erase("Midnight")
	praytimes.erase("Imsak")

	# Find closest high low
	var time_minute_base: int = (WidgetTime.time.hour * 60) + WidgetTime.time.minute
	var praytimes_sorted: Array = praytimes.values()
	praytimes_sorted.sort()

	var closest_low: int = 0
	var closest_high: int = 1440

	if time_minute_base < praytimes_sorted[0] or time_minute_base >= praytimes_sorted[-1]:
		closest_low = praytimes_sorted[-1]
		closest_high = praytimes_sorted[0]
	else:
		for pray in praytimes:
			if praytimes[pray] > time_minute_base:
				closest_high = min(closest_high, praytimes[pray])
			else:
				closest_low = max(closest_low, praytimes[pray])

	NodePresentName.text = T.PRAYTIMES_NAME[praytimes.find_key(closest_low)]
	NodeFutureName.text = T.PRAYTIMES_NAME[praytimes.find_key(closest_high)]

	# Jumu'ah prayer
	if WidgetDate.gregorian.weekday == 5:
		if NodePresentName.text == T.PRAYTIMES_NAME["Dhuhr"]:
			NodePresentName.text = T.WEEKDAY_NAME_HIJRI[5]
		if NodeFutureName.text == T.PRAYTIMES_NAME["Dhuhr"]:
			NodeFutureName.text = T.WEEKDAY_NAME_HIJRI[5]

	var present_shift: int = 1440 * int(time_minute_base < praytimes_sorted[0])
	var present_hour: int = (time_minute_base - closest_low + present_shift) / 60
	var present_minute: int = (time_minute_base - closest_low + present_shift) % 60
	NodePresentTimespan.text = tr("T_CURRENT_PRESENT_HOUR" if present_hour else "T_CURRENT_PRESENT_MINUTE").format({
		"value" = present_hour if present_hour else present_minute,
	})

	var future_shift: int = 1440 * int(time_minute_base >= praytimes_sorted[-1])
	var future_hour: int = (closest_high + future_shift - time_minute_base) / 60
	var future_minute: int = (closest_high + future_shift - time_minute_base) % 60
	NodeFutureTimespan.text = tr("T_CURRENT_FUTURE_HOUR" if future_hour else "T_CURRENT_FUTURE_MINUTE").format({
		"value" = future_hour if future_hour else future_minute,
	})
