class_name WidgetDate
extends Node

@export_node_path("Label") var node_weekday_g_path: NodePath
@onready var NodeWeekdayG: Label = get_node(node_weekday_g_path)

@export_node_path("Label") var node_weekday_h_path: NodePath
@onready var NodeWeekdayH: Label = get_node(node_weekday_h_path)

@export_node_path("Label") var node_day_g_path: NodePath
@onready var NodeDayG: Label = get_node(node_day_g_path)

@export_node_path("Label") var node_day_h_path: NodePath
@onready var NodeDayH: Label = get_node(node_day_h_path)

@export_node_path("Label") var node_month_g_path: NodePath
@onready var NodeMonthG: Label = get_node(node_month_g_path)

@export_node_path("Label") var node_month_h_path: NodePath
@onready var NodeMonthH: Label = get_node(node_month_h_path)

@export_node_path("Label") var node_year_g_path: NodePath
@onready var NodeYearG: Label = get_node(node_year_g_path)

@export_node_path("Label") var node_year_h_path: NodePath
@onready var NodeYearH: Label = get_node(node_year_h_path)

static var gregorian: Dictionary = {
	"year" : -1,
	"month" : -1,
	"day" : -1,
	"weekday" : -1,
}

static var hijri: Dictionary = {
	"year" : -1,
	"month" : -1,
	"day" : -1,
}


func _on_minute_updated():
	# Early bail
	if not PrayTimes.is_data_available():
		return

	var system_date = Time.get_date_dict_from_system()
	if not gregorian.year == system_date.year:
		gregorian.year = system_date.year
	if not gregorian.month == system_date.month:
		gregorian.month = system_date.month
	if not gregorian.day == system_date.day:
		gregorian.day = system_date.day
		gregorian.weekday = system_date.weekday

	# Hijri date changes at sunset
	var is_beyond_sunset: bool = ((WidgetTime.time.hour * 60) + WidgetTime.time.minute) >= PrayTimes.get_praytimes(gregorian.month, gregorian.day)["Sunset"]
	var gregorian_shift = Time.get_date_dict_from_unix_time(Time.get_unix_time_from_system() + (86400 * int(is_beyond_sunset)))
	var hijri_date: Dictionary = Hijri.get_hijri(gregorian_shift.year, gregorian_shift.month, gregorian_shift.day)
	hijri.year = hijri_date.year
	hijri.month = hijri_date.month
	hijri.day = hijri_date.day

	# Set text
	NodeWeekdayG.text = T.WEEKDAY_NAME_GREGORIAN[gregorian.weekday]
	NodeWeekdayH.text = T.WEEKDAY_NAME_HIJRI[wrapi(gregorian.weekday + int(is_beyond_sunset), 0, T.WEEKDAY_NAME_HIJRI.size())]

	NodeDayG.text = str(gregorian.day)
	NodeDayH.text = str(hijri.day)

	NodeMonthG.text = T.MONTH_NAME_GREGORIAN[gregorian.month - 1]
	NodeMonthH.text = T.MONTH_NAME_HIJRI[hijri.month - 1]

	NodeYearG.text = str(gregorian.year)
	NodeYearH.text = str(hijri.year)
