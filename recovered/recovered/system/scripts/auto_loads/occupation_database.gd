extends Node



const YOUNG_AGE_MAX: int = 18
const UNIVERSITY_AGE_MAX: int = 24


var occupations = [
	"Driver", "Doctor", "Pharmacist", "Nurse", "Lab Technician", 
	"Graphic Designer", "Architect", "Journalist", "Photographer", "Police Officer", 
	"Teacher", "Accountant", "HR Officer", "Office Administrator", 
	"Project Manager", "Sales Rep.", "Marketing Specialist", "Software Developer", 
	"Mechanical Engineer", "Civil Engineer", "Electrical Engineer", 
	"Microbus Driver", "Government Worker", "Customs Officer", 
	"Lawyer", "Judge", "Army Officer", "Tour Guide", 
	"Entrepreneur", "Farmer", "Fisherman", "Carpenter", "Plumber", 
	"Electrician", "Tailor", "Baker", "Butcher", "Blacksmith", 
	"Construction Worker", "Waiter", "Doorman", "Professor", 
	"School Principal", "Ferry Captain", "Telecom Technician", 
	"Tuk-tuk Operator", "Car Thief", "Unlicensed Doctor", "Money Launderer", "Smuggler"
]

var ar_occupations = [
	"{m:سواق|سواقة}", "{m:دكتور|دكتورة}", "{m:صيدلي|صيدلانية}", "{m:ممرض|ممرضة}", "{m:فني معمل|فنية معمل}", 
	"{m:مصمم جرافيك|مصممة جرافيك}", "{m:مهندس معماري|مهندسة معمارية}", "{m:صحفي|صحفية}", "{m:مصور|مصورة}", "{m:ظابط شرطة|ظابطة شرطة}", 
	"{m:مدرس|مدرسة}", "{m:محاسب|محاسبة}", "{m:موظف موارد بشرية|موظفة موارد بشرية}", "{m:موظف إداري|موظفة إدارية}", 
	"{m:مدير مشروعات|مديرة مشروعات}", "{m:مندوب مبيعات|مندوبة مبيعات}", "{m:أخصائي تسويق|أخصائية تسويق}", "{m:مطور برمجيات|مطورة برمجيات}", 
	"{m:مهندس ميكانيكا|مهندسة ميكانيكا}", "{m:مهندس مدني|مهندسة مدنية}", "{m:مهندس كهربا|مهندسة كهربا}", 
	"{m:سواق ميكروباص|سواقة ميكروباص}", "{m:موظف حكومي|موظفة حكومية}", "{m:موظف جمارك|موظفة جمارك}", 
	"{m:محامي|محامية}", "{m:قاضي|قاضية}", "{m:ظابط جيش|ظابطة جيش}", "{m:مرشد سياحي|مرشدة سياحية}", 
	"{m:رائد أعمال|رائدة أعمال}", "{m:فلاح|فلاحة}", 
	"{m:كهربائي|كهربائية}", "{m:خياط|خياطة}", "{m:خباز|خبازة}", 
	"{m:عامل بناء|عاملة بناء}", "{m:جرسون|جرسونة}", "{m:أستاذ جامعي|أستاذة جامعية}", 
	"{m:مدير مدرسة|مديرة مدرسة}", "كابتن معدية", "{m:فني اتصالات|فنية اتصالات}", 
	"{m:سواق توك توك|سواقة توك توك}", "حرامي عربيات", "{m:دكتور من غير ترخيص|دكتورة من غير ترخيص}", "{m:غاسل أموال|غاسلة أموال}", "{m:مهرب|مهربة}"
]

func get_random_occupation(age: int, language: String = "", gender: String = "") -> String:
	language = EffectiveLanguage.resolve(language)
	var is_ar: = language == "ar"
	if age <= UNIVERSITY_AGE_MAX:
		return FunnyTexts.genderize("{m:طالب|طالبة}" if is_ar else "Student", gender)
	var list: Array = ar_occupations if is_ar else occupations
	return FunnyTexts.genderize(
		ShuffledBag.pool_for("occ:%s:%s" % [language, "adult"], list).next(), gender)

func is_police_officer(occupation: String, language: String = "") -> bool:
	language = EffectiveLanguage.resolve(language)
	if language == "ar":
		return occupation == "ظابط شرطة" or occupation == "ظابطة شرطة"
	return occupation.to_lower() == "police officer"

func get_unemployed_label(language: String = "", gender: String = "") -> String:
	language = EffectiveLanguage.resolve(language)
	if language == "ar":
		return FunnyTexts.genderize("{m:عاطل|عاطلة}", gender)
	return "Unemployed"





@export var syndicates: Array[SyndicateData] = []



func is_syndicated(occupation: String, language: String = "") -> bool:
	return get_syndicate_for(occupation, language) != null



func get_syndicate_for(occupation: String, language: String = "") -> SyndicateData:
	for syndicate: SyndicateData in syndicates:
		if syndicate.matches(occupation, language):
			return syndicate
	return null
