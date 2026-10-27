extends Resource
class_name CustomDate

@export var date_dict: Dictionary

const MONTH_NAMES: = [
	"", "January", "February", "March", "April", "May", "June", 
	"July", "August", "September", "October", "November", "December"
]

const WEEKDAY_NAMES: = [
	"Sunday", "Monday", "Tuesday", "Wednesday", 
	"Thursday", "Friday", "Saturday"
]

static func from_unix_time(timestamp: int) -> CustomDate:
	var d: = CustomDate.new()
	d.date_dict = Time.get_datetime_dict_from_unix_time(timestamp)
	return d


static func from_ymd(day: int, month: int, year: int) -> CustomDate:
	var ts: = Time.get_unix_time_from_datetime_dict({"year": year, "month": month, "day": day, "hour": 12, "minute": 0, "second": 0})
	return from_unix_time(ts)

static func generate_random_birth_date(min_age: int, max_age: int) -> CustomDate:
	var now_ts: = Time.get_unix_time_from_system()
	var seconds_in_year: = 365.25 * 24 * 60 * 60

	var youngest_ts: = now_ts - int(min_age * seconds_in_year)
	var oldest_ts: = now_ts - int(max_age * seconds_in_year)

	return from_unix_time(randi_range(oldest_ts, youngest_ts))




static func generate_random_event_date(birth_date: CustomDate, min_event_age: int, max_years_ago: int) -> CustomDate:
	var seconds_in_year: = 365.25 * 24 * 60 * 60
	var now_ts: = Time.get_unix_time_from_system()
	var birth_ts: = Time.get_unix_time_from_datetime_dict(birth_date.date_dict)
	var earliest: = maxi(birth_ts + int(min_event_age * seconds_in_year), now_ts - int(max_years_ago * seconds_in_year))
	if earliest >= now_ts:
		return from_unix_time(now_ts)
	return from_unix_time(randi_range(earliest, now_ts))

func get_short() -> String:
	return ArabicNumbers.localized("%02d/%02d/%d" % [
		date_dict.day, 
		date_dict.month, 
		date_dict.year
	])

func get_long() -> String:
	return ArabicNumbers.localized("%d %s %d" % [
		date_dict.day, 
		MONTH_NAMES[date_dict.month], 
		date_dict.year
	])

func get_full() -> String:
	return ArabicNumbers.localized("%s, %d %s %d" % [
		WEEKDAY_NAMES[date_dict.weekday], 
		date_dict.day, 
		MONTH_NAMES[date_dict.month], 
		date_dict.year
	])

func get_age() -> int:
	var now: = Time.get_datetime_dict_from_system()
	return now.year - date_dict.year




func is_at_least_age(min_age: int) -> bool:
	var now: = Time.get_datetime_dict_from_system()
	var years: int = now.year - date_dict.year
	if now.month < date_dict.month or (now.month == date_dict.month and now.day < date_dict.day):
		years -= 1
	return years >= min_age





func with_corrupted_component(component: String) -> CustomDate:
	if date_dict == null:
		return null
	var copy: = CustomDate.new()
	copy.date_dict = date_dict.duplicate()
	match component:
		"day":
			copy.date_dict["day"] = _altered_component("day")
		"month":
			copy.date_dict["month"] = _altered_component("month")
		"year":
			copy.date_dict["year"] = _altered_component("year")
	return copy


func _altered_component(component: String) -> int:
	match component:
		"day":
			var delta: = randi_range(-3, 3)
			if delta == 0:
				delta = 1
			var d: = clampi(date_dict.day + delta, 1, 28)
			if d == date_dict.day:
				d = clampi(date_dict.day - delta, 1, 28)
			return d
		"month":
			var delta: = randi_range(-3, 3)
			if delta == 0:
				delta = 1
			var m: = wrapi(date_dict.month + delta, 1, 13)
			if m == date_dict.month:
				m = wrapi(date_dict.month - delta, 1, 13)
			return m
		"year":
			var delta: = randi_range(-2, 2)
			if delta == 0:
				delta = 1
			return date_dict.year + delta
	return 0

func _to_string() -> String:
	return get_full()
