extends Node

var use_male_as_surname: float = 0.3

var male_names = [
	"Ahmed", "Mohamed", "Omar", "Ali", "Hassan", "Hussein", "Youssef", 
	"Ibrahim", "Karim", "Mostafa", "Khaled", "Amr", "Tarek", "Ziyad", 
	"Sherif", "Waleed", "Wael", "Ayman", "Hany", "Islam", "Fady", "Mahmoud", "Nour", 
	"Yassin", "Adel", "Essam", "Hossam", "Ramy", "Seif", "Anas", 
	"Moustafa", "Amir", "Shady", "Nader", "Ashraf", 
	"Ezzat", "Galal", "Safwat", "Alaa", "Kareem", "Nabil", "Sameh"
]

var ar_male_names = [
	"أحمد", "محمد", "عمر", "علي", "حسن", "حسين", "يوسف", 
	"إبراهيم", "كريم", "مصطفى", "خالد", "عمر", "طارق", "زياد", 
	"شريف", "وليد", "وائل", "أيمن", "هاني", "إسلام", "فادي", "محمود", "نور", 
	"ياسين", "عادل", "عصام", "حسام", "رامي", "سيف", "أنس", 
	"مصطفى", "أمير", "شادي", "نادر", "أشرف", 
	"عزت", "جلال", "صفوت", "علاء", "كريم", "نبيل", "سامح"
]

var female_names = [
	"Fatma", "Amina", "Mona", "Sara", "Salma", "Yasmin", "Nour", 
	"Hoda", "Reem", "Aya", "Heba", "Doaa", "Rania", "Dina", "Nesma", 
	"Mai", "Esraa", "Marwa", "Laila", "Farah", "Afnan", "Abrar", "Alaa", 
	"Nadia", "Samira", "Eman", "Enas", "Ghada", "Omniya", "Malak", 
	"Amira", "Hana", "Mariam", "Maram", "Nada", "Sama", "Hagar", 
	"Rasha", "Shaimaa", "Noha", "Lamya", "Nermine", "Nagwa", "Mervat", 
	"Talla", "Dai"
]

var ar_female_names = [
	"فاطمة", "أمينة", "منى", "سارة", "سلمى", "ياسمين", "نور", 
	"هدى", "ريم", "آية", "هبة", "دعاء", "رانيا", "دينا", "نسمة", 
	"مي", "إسراء", "مروة", "ليلى", "فرح", "أفنان", "أبرار", "ألاء", 
	"نادية", "سميرة", "إيمان", "إناس", "غادة", "أمنية", "ملك", 
	"أميرة", "هنا", "مريم", "مرام", "ندى", "سما", "هاجر", 
	"رشا", "شيماء", "نها", "لمياء", "نرمين", "نجوى", "مرفت", 
	"طلة", "ضي", 
]

var surnames = [
	"Hassan", "Mahmoud", "Ibrahim", "Ali", "Abdelrahman", "Abdallah", 
	"Sayed", "Salem", "Fouad", "Elmasry", "Saeed", 
	"Zaki", "Mostafa", "Hamdy", "Kamal", "Salah", "Gaber", 
	"Ashraf", "Farouk", "El-Sharkawy", "Rashwan", "Hegazy", 
	"Shaker", "Hanafy", "Mansour", "Shalaby", "Ahmed", 
	"El-Shafei", "El-Husseiny", "El-Ghazaly", "El-Sobky", "El-Gayar", 
]

var ar_surnames = [
	"حسن", "محمود", "إبراهيم", "علي", "عبدالرحمن", "عبدالله", 
	"سيد", "سالم", "فؤاد", "المصري", "سعيد", 
	"زكي", "مصطفى", "حمدى", "كمال", "صلاح", "جابر", 
	"أشرف", "فاروق", "الشرقاوي", "رشوان", "حجازي", 
	"شاكر", "حنفي", "منصور", "شلبي", "أحمد", 
	"الشافعي", "الحسيني", "الغزالي", "السبكي", "الجيار"
]

var christian_male_names = [
	"George", "Peter", "Mark", "Michael", "Mina", "Bishoy", 
	"Samuel", "Girgis", "Boutros", "Kirollos", 
	"Shenouda", "Fady", "Magdy", "Samy", "Maged", "Amgad", 
	"Wagdy", "Farid", "Antony", "Ramzy", "Talaat", "Abanoub", 
	"Markos", "Youhanna", 
]

var ar_christian_male_names = [
	"جورج", "بيتر", "مارك", "مايكل", "مينا", "بيشوي", 
	"سام", "جرجس", "بطرس", "كيرلس", 
	"شنودة", "فادي", "مجدي", "سامي", "ماجد", "أمجد", 
	"وجدي", "فريد", "أنطوني", "رمزي", "طلعت", "أبانوب", 
	"مرقس", "يوحنا", 
]

var christian_female_names = [
	"Mary", "Maria", "Marina", "Mariam", "Hanna", "Rita", "Nadine", 
	"Christine", "Christina", "Magda", "Souzan", "Victoria", 
	"Samia", "Veronica", "Katarina", 
]

var ar_christian_female_names = [
	"ماري", "ماريا", "مارينا", "مريم", "هانا", "ريتا", "نادين", 
	"كريستين", "كريستينا", "ماجدة", "سوزان", "فيكتوريا", 
	"سامية", "فيرونيكا", "كاترينا", 
]

var christian_surnames = [
	"Habib", "Awad", "Rizk", "Girgis", "Shenouda", 
	"Aziz", "Ghaly", "Hanna", "Labib", "Boutros", 
	"Ramzy", "Wahba", "Shafik", "Naguib", "Sedky", "Anton", 
	"Fawzy", "Farid", "Samaan", "Fahmy", "Kamel", "Mansour", 
	"Mina", "Fakhry", 
]

var ar_christian_surnames = [
	"حبيب", "عوض", "رزق", "جرجس", "شنودة", 
	"عزيز", "غالي", "حنا", "لبيب", "بطرس", 
	"رمزي", "وهبة", "شفيق", "نجيب", "صدقي", "أنطون", 
	"فوزي", "فريد", "سمعان", "فهمي", "كامل", "منصور", 
	"مينا", "فخري", 
]

func _is_christian(religion: int) -> bool:
	return religion == Enums.Religion.CHRISTIAN


func _religion_key(religion: int) -> String:
	return "c" if _is_christian(religion) else "m"


func get_random_male_name(religion: int = Enums.Religion.MUSLIM, language: String = "") -> String:
	language = EffectiveLanguage.resolve(language)
	var is_christian: = _is_christian(religion)
	var list: Array = (ar_christian_male_names if is_christian else ar_male_names) if language == "ar" else (christian_male_names if is_christian else male_names)
	return ShuffledBag.pool_for("name:%s:%s:m" % [language, _religion_key(religion)], list).next()

func get_random_name(gender: String, religion: int = Enums.Religion.MUSLIM, language: String = "") -> String:
	language = EffectiveLanguage.resolve(language)
	return get_random_name_with_language(gender, religion, language)

func get_random_name_with_language(gender: String, religion: int = Enums.Religion.MUSLIM, language: String = "en") -> String:
	var is_christian: = _is_christian(religion)
	var name_list: Array
	var surname_list: Array
	var male_name_list: Array
	if language == "ar":
		if is_christian:
			name_list = ar_christian_male_names if gender == "m" else ar_christian_female_names
			surname_list = ar_christian_surnames
			male_name_list = ar_christian_male_names
		else:
			name_list = ar_male_names if gender == "m" else ar_female_names
			surname_list = ar_surnames
			male_name_list = ar_male_names
	else:
		if is_christian:
			name_list = christian_male_names if gender == "m" else christian_female_names
			surname_list = christian_surnames
			male_name_list = christian_male_names
		else:
			name_list = male_names if gender == "m" else female_names
			surname_list = surnames
			male_name_list = male_names

	var rkey: = _religion_key(religion)
	var full_name: String = ShuffledBag.pool_for("name:%s:%s:%s" % [language, rkey, gender], name_list).next()
	var surname: String
	var attempts: = 0
	var use_male_name: bool = randf() < use_male_as_surname

	while true:
		if use_male_name:
			surname = ShuffledBag.pool_for("male_name:%s:%s" % [language, rkey], male_name_list).next()
		else:
			surname = ShuffledBag.pool_for("surname:%s:%s" % [language, rkey], surname_list).next()

		if surname != full_name or attempts >= 10:
			break
		attempts += 1

	return "%s %s" % [full_name, surname]


func get_random_surname_excluding(excludes: Array, religion: int = Enums.Religion.MUSLIM, language: String = "") -> String:
	language = EffectiveLanguage.resolve(language)
	var rkey: = _religion_key(religion)
	var list: Array = (ar_christian_surnames if _is_christian(religion) else ar_surnames) if language == "ar" else (christian_surnames if _is_christian(religion) else surnames)
	for i in range(list.size()):
		var s: String = ShuffledBag.pool_for("surname:%s:%s" % [language, rkey], list).next()
		if not excludes.has(s):
			return s
	return ShuffledBag.pool_for("surname:%s:%s" % [language, rkey], list).next()


func swap_surname(full_name: String, religion: int = Enums.Religion.MUSLIM, language: String = "") -> String:
	language = EffectiveLanguage.resolve(language)
	var parts: = full_name.split(" ")
	if parts.size() < 2:
		return full_name
	var new_surname: = get_random_surname_excluding([parts[0], parts[1]], religion, language)
	return "%s %s" % [parts[0], new_surname]





func corrupt_letter(text: String) -> String:
	var len: = text.length()
	if len < 2:
		return text
	var indices: Array[int] = []
	for i in range(len):
		var ch: String = text[i]
		if ch == "_" or ch == " ":
			continue
		if ch.is_valid_identifier():
			indices.append(i)
	if indices.is_empty():
		return text
	var idx: int = indices.pick_random()
	var original: String = text[idx]
	var replacement: = _random_letter_like(original)
	var attempts: = 0
	while replacement == original and attempts < 10:
		replacement = _random_letter_like(original)
		attempts += 1
	if replacement == original:
		return text
	return text.substr(0, idx) + replacement + text.substr(idx + 1)


func _random_letter_like(original: String) -> String:
	const letters: = "abcdefghijklmnopqrstuvwxyz"
	var pool: = letters if original == original.to_lower() else letters.to_upper()
	return pool[randi() % pool.length()]
