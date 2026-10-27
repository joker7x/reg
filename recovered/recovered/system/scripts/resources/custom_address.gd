extends Resource
class_name CustomAddress

@export var governorate: String
@export var city: String
@export var street_name: String
@export var building_number: int
@export var floor_number: int
@export var apartment_number: int
@export var postal_code: String

const BUILDING_MIN: = 1
const BUILDING_MAX: = 200
const APARTMENT_MIN: = 1
const APARTMENT_MAX: = 50
const FLOOR_MIN: = 1
const FLOOR_MAX: = 10
const POSTAL_MIN: = 10000
const POSTAL_MAX: = 99999

const GOVERNORATES: = {
	"Cairo": ["Maadi", "Nasr City", "Heliopolis", "New Cairo", "El Shorouk", "Boulaq"], 
	"Giza": ["6th of October", "Sheikh Zayed", "Haram", "Imbaba", "El Hawamdeya"], 
	"Alexandria": ["Borg El Arab", "Semoha", "Sidi Bishr", "Agami"], 
	"Qalyubia": ["Banha", "Qalyub", "Shubra El-Kheima"], 
	"Sharqia": ["Zagazig", "10th of Ramadan", "Belbeis", "Abu Hammad", "Minya El Qamh"], 
	"Monufia": ["Shebin El Kom", "Quesna", "Sadat City", "Ashmun"], 
	"Dakahlia": ["Mansoura", "Talkha", "Mit Ghamr", "Sherbin"], 
	"Damietta": ["Ras El Bar", "Faraskour", "Kafr El Bateekh"], 
	"Beheira": ["Damanhour", "Kafr El Dawwar", "Rashid"], 
	"Gharbia": ["Tanta", "El Mahalla", "Kafr El Zayat"], 
	"Kafr El Sheikh": ["Desouk", "Baltim", "Sidi Salem"], 
	"Matrouh": ["Marsa Matrouh", "El Alamein", "Siwa", "El Dabaa"], 
	"Ismailia": ["Fayed", "Qantara"], 
	"Suez": ["Suez", "Al-Arbaeen", "Port Tawfik"], 
	"Port Said": ["Port Said", "Port Foad"], 
	"Minya": ["Mallawi", "Samalut", "Maghagha"], 
	"Fayoum": ["Senuris", "Tamiya"], 
	"North Sinai": ["Al-Arish", "Rafah", "Sheikh Zuweid"], 
	"South Sinai": ["Sharm El-Sheikh", "Dahab"], 
}
const AR_GOVERNORATES: = {
	"القاهرة": ["المعادي", "مدينة نصر", "مصر الجديدة", "القاهرة الجديدة", "الشروق", "بولاق", ], 
	"الجيزة": ["6 أكتوبر", "الشيخ زايد", "الهرم", "إمبابة", "الحوامدية", "الدقي"], 
	"الإسكندرية": ["برج العرب", "سموحة", "سيدي بشر", "العجمي"], 
	"القليوبية": ["بنها", "قليوب", "شبرا الخيمة"], 
	"الشرقية": ["الزقازيق", "العاشر من رمضان", "بلبيس", "أبو حماد", "منيا القمح"], 
	"المنوفية": ["شبين الكوم", "قويسنا", "مدينة السادات", "أشمون"], 
	"الدقهلية": ["المنصورة", "طلخا", "ميت غمر", "شربين"], 
	"دمياط": ["رأس البر", "فارسكور", "كفر البطيخ"], 
	"البحيرة": ["دمنهور", "كفر الدوار", "رشيد"], 
	"الغربية": ["طنطا", "المحلة الكبرى", "كفر الزيات"], 
	"كفر الشيخ": ["دسوق", "بلطيم", "سيدي سالم"], 
	"مطروح": ["مرسى مطروح", "العلمين", "سيوة", "الضبعة"], 
	"الإسماعيلية": ["فايد", "القنطرة"], 
	"السويس": ["السويس", "الأربعين", "بورتوفيق"], 
	"بورسعيد": ["بورسعيد", "بورفؤاد"], 
	"المنيا": ["ملوي", "سمالوط", "مغاغة"], 
	"الفيوم": ["سنورس", "طامية"], 
	"شمال سيناء": ["العريش", "رفح", "الشيخ زويد"], 
	"جنوب سيناء": ["شرم الشيخ", "دهب"], 
}
const STREET_NAMES: = [
	"El-Nasr", "Gomhoria", "Tahrir", "Zaghloul", 
	"A. Orabi", "M. Kamel", "Horreya", 
	"26th of July", "El Geish", "El Salam", "El Galaa", 
	"El Gamaa", "Stadium", "El Salam", "Street 9", 
	"Street 10", "Street 15", "Street 20", "Street 30", 
	"Ramsis", "Sudan", "El Haram", "Port Said", "El Malek", 
	"El Nil", "El Azhar", "El Hegaz", "El Fath", "El Merghany", 
	"El Sawah", "El Gabal", "El Nakhil", "El Montazah", 
	"El Bahr", 
]
const AR_STREET_NAMES: = [
	"النصر", "الجمهورية", "التحرير", "زغلول", 
	"أحمد عرابي", "مصطفى كامل", "الحرية", 
	"26 يوليو", "الجيش", "السلام", "الجلاء", 
	"الجامعة", "الاستاد", "السلام", "شارع 9", 
	"شارع 10", "شارع 15", "شارع 20", "شارع 30", 
	"رمسيس", "السودان", "الهرم", "بورسعيد", "الملك", 
	"النيل", "الأزهر", "الحجاز", "الفتح", "المرغني", 
	"السواح", "الجبل", "النخيل", "المنتزه", 
	"البحر", 
]

static func _is_ar() -> bool:
	return TranslationServer.get_locale() == "ar"

static func _locale_tables() -> Dictionary:
	var ar: = _is_ar()
	return {
		"governorates": AR_GOVERNORATES if ar else GOVERNORATES, 
		"streets": AR_STREET_NAMES if ar else STREET_NAMES, 
	}

static func generate_random() -> CustomAddress:
	var addr: = CustomAddress.new()
	var tables: = _locale_tables()
	addr.governorate = tables["governorates"].keys().pick_random()
	addr.city = tables["governorates"][addr.governorate].pick_random()
	addr.street_name = addr.random_street_name(tables["streets"])

	addr.building_number = randi_range(BUILDING_MIN, BUILDING_MAX)
	addr.apartment_number = randi_range(APARTMENT_MIN, APARTMENT_MAX)
	addr.floor_number = randi_range(FLOOR_MIN, FLOOR_MAX)

	addr.postal_code = str(randi_range(POSTAL_MIN, POSTAL_MAX))
	return addr

static func get_random_city() -> String:
	var govs: Dictionary = _locale_tables()["governorates"]
	var gov: String = govs.keys().pick_random()
	return govs[gov].pick_random()

static func get_random_city_excluding_city(exclude: String) -> String:
	for i in range(20):
		var city: = get_random_city()
		if city != exclude:
			return city
	return get_random_city()

static func generate_random_in_city(city: String) -> CustomAddress:
	var addr: = generate_random()
	var found: = false
	for govs in [GOVERNORATES, AR_GOVERNORATES]:
		for gov in govs:
			if govs[gov].has(city):
				addr.governorate = gov
				addr.city = city
				found = true
				break
		if found:
			break
	return addr

func random_street_name(streets) -> String:
	var st_name: String = streets.pick_random()

	if st_name.contains("شارع") or st_name.contains("Street"):
		return st_name

	if _is_ar():
		return "شارع %s" % st_name if randf() < 0.5 else "ش %s" % st_name
	else:
		return "%s St." % st_name


func with_shifted_building_number() -> CustomAddress:
	var copy: = duplicate() as CustomAddress
	var delta: = 1 if randf() < 0.5 else -1
	copy.building_number = clampi(building_number + delta, BUILDING_MIN, BUILDING_MAX)
	if copy.building_number == building_number:
		copy.building_number = clampi(building_number - delta, BUILDING_MIN, BUILDING_MAX)
	return copy


func with_swapped_street() -> CustomAddress:
	var copy: = duplicate() as CustomAddress
	var streets: Array = _locale_tables()["streets"]
	for i in range(streets.size()):
		var candidate: = random_street_name(streets)
		if candidate != street_name:
			copy.street_name = candidate
			return copy
	return null


func with_swapped_city() -> CustomAddress:
	var copy: = duplicate() as CustomAddress
	var govs: Dictionary = _locale_tables()["governorates"]
	var cities: Array = govs.get(governorate, [])
	if cities.size() < 2:
		return null
	for i in range(cities.size()):
		var candidate: String = cities.pick_random()
		if candidate != city:
			copy.city = candidate
			return copy
	return null


func with_corrupted_postal_code() -> CustomAddress:
	var copy: = duplicate() as CustomAddress
	if postal_code.length() < 2:
		return null
	var idx: int = randi_range(0, postal_code.length() - 1)
	var new_digit: = str(randi_range(0, 9))
	while new_digit == postal_code[idx]:
		new_digit = str(randi_range(0, 9))
	copy.postal_code = postal_code.substr(0, idx) + new_digit + postal_code.substr(idx + 1)
	return copy

func get_standard() -> String:
	if _is_ar():
		return ArabicNumbers.localized("%d، %s، %s، %s" % [building_number, street_name, city, governorate])
	return "%d, %s, %s, %s" % [building_number, street_name, city, governorate]

func get_long() -> String:
	if _is_ar():
		return ArabicNumbers.localized("مبنى %d، شقة %d، شارع %s، %s، %s، مصر %s" % [
			building_number, apartment_number, street_name, city, governorate, postal_code
		])
	return "Building %d, Apartment %d, %s Street, %s, %s, Egypt %s" % [
		building_number, apartment_number, street_name, city, governorate, postal_code
	]

func _to_string() -> String:
	return get_long()
