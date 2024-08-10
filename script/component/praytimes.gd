class_name PrayTimes
extends Node

signal download_completed

enum CalculationMethod {
	SHIA_ITHNA_ASHARI,
	UNIVERSITY_OF_ISLAMIC_SCIENCES_KARACHI,
	ISLAMIC_SOCIETY_OF_NORTH_AMERICA,
	MUSLIM_WORLD_LEAGUE,
	UMM_AL_QURA_UNIVERSITY_MAKKAH,
	EGYPTIAN_GENERAL_AUTHORITY_OF_SURVEY,
	INSTITUTE_OF_GEOPHYSICS_UNIVERSITY_OF_TEHRAN,
	GULF_REGION,
	KUWAIT,
	QATAR,
	MAJLIS_UGAMA_ISLAM_SINGAPURA_SINGAPORE,
	UNION_ORGANIZATION_ISLAMIC_DE_FRANCE,
	DIYANET_ISLERI_BASKANLIGI_TURKEY,
	SPIRITUAL_ADMINISTRATION_OF_MUSLIMS_OF_RUSSIA,
	MOONSIGHTING_COMMITTEE_WORLDWIDE,
	DUBAI,
}

enum LatitudeMethod {
	MIDDLE_OF_THE_NIGHT = 1,
	ONE_SEVENTH = 2,
	ANGLE_BASED = 3,
}

enum Shafaq {
	GENERAL,
	AHMER,
	ABYAD,
}

# Al Adhan API
# Use human-readable geocode instead of coordinate
const API_URL: String = "https://api.aladhan.com/v1/calendarByAddress/{year}?address={geocode}&method={calculation_method}&latitudeAdjustmentMethod={latitude_method}&shafaq={shafaq}&school={hanafi}&midnightMode={jafari}"
const FILE_DIR: String = "user://praytimes"
const FILE_DATA: String = "praytimes.dictionary"

static var HTTP: HTTPRequest

static var input_year: int = 0
static var input_geocode: String = "London"
static var input_calculation_method: CalculationMethod = 0
static var input_latitude_method: LatitudeMethod = 0
static var input_shafaq: Shafaq = 0
static var input_hanafi: bool = false
static var input_jafari: bool = false


static func is_data_available():
	return FileAccess.file_exists(FILE_DIR + "/" + FILE_DATA)


static func download_data(year: int, geocode: String, calculation_method: CalculationMethod, latitude_method: LatitudeMethod, shafaq: Shafaq, hanafi: bool, jafari: bool):
	input_year = year
	input_geocode = geocode
	input_calculation_method = calculation_method
	input_latitude_method = clamp(latitude_method, 1, 3) # Mistakes makes it 0
	input_shafaq = shafaq
	input_hanafi = hanafi
	input_jafari = jafari

	# Print
	print("Downloading data...")

	_do_request()


static func get_data_info():
	if not is_data_available():
		printerr("Data unavailable.")
		return

	var file = FileAccess.open(FILE_DIR + "/" + FILE_DATA, FileAccess.READ)
	var data = str_to_var(file.get_as_text())["data"]["1"][0]


	var info = {
		"year": data.date.gregorian.year,
		"latitude": data.meta.latitude,
		"longitude": data.meta.longitude,
		"timezone": data.meta.timezone,
		"calculation_method": data.meta.method.id,
		"latitude_method": LatitudeMethod[data.meta.latitudeAdjustmentMethod],
		"hanafi": data.meta.school == "HANAFI",
		"jafari": data.meta.midnightMode == "JAFARI",
	}

	return info


static func get_praytimes(month: int, day: int):
	if not is_data_available():
		printerr("Data unavailable.")
		return

	if month == 2 and day > 28:
		day = 28

	var file = FileAccess.open(FILE_DIR + "/" + FILE_DATA, FileAccess.READ)
	var data0 = str_to_var(file.get_as_text())

	# Check if data is correct
	if not data0.code == 200:
		printerr(data0.status)
		print_verbose(data0.data)
		return

	var data1 = data0["data"]
	var data2 = data1[str(month)]
	var data3 = data2[int(day - 1)]
	var data4 = data3["timings"]
	var data = data4
	#var data = str_to_var(file.get_as_text())["data"][str(month)][int(day - 1)]["timings"]
	for key in data:
		var time_array = data[key].left(5).split(":")
		data[key] = (int(time_array[0]) * 60) + int(time_array[1])
	return data


func _ready():
	# Create HTTP request node
	HTTP = HTTPRequest.new()
	HTTP.set_timeout(10)
	add_child(HTTP)
	HTTP.request_completed.connect(_on_request_completed)

	# Setup
	DirAccess.make_dir_recursive_absolute(FILE_DIR)


static func _do_request():
	var url: String = API_URL.format({
			"year": str(input_year),
			"geocode": str(input_geocode),
			"calculation_method": str(input_calculation_method),
			"latitude_method": str(input_latitude_method),
			"shafaq": str({0: "general", 1: "ahmer", 2: "abyad"}[input_shafaq]),
			"hanafi": str(int(input_hanafi)),
			"jafari": str(int(input_jafari)),
		})
	var request = HTTP.request(url)

	print_verbose("Requesting:")
	print_verbose(url)

	if not request == OK:
		printerr("Attempt to request failed.")


func _on_request_completed(result, _response_code, _headers, body):
	var request_retry: Callable = func (message: String):
		printerr(message)
		print("Retrying request...")
		await get_tree().create_timer(5).timeout
		_do_request()
		return

	if not result == HTTPRequest.RESULT_SUCCESS:
		request_retry.call("Request failed.")

	var data = JSON.parse_string(body.get_string_from_utf8())
	if not data:
		request_retry.call("JSON parse failed.")

	if not data.code == 200:
		printerr(data.status)
		print_verbose(data.data)
		request_retry.call("Data failed.")

	var file = FileAccess.open(FILE_DIR + "/" + FILE_DATA, FileAccess.WRITE)
	file.store_string(var_to_str(data))

	print("Download completed.")
	download_completed.emit()
