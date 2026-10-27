extends Document
class_name EnrollmentProof

@export var institution_value: Label
@export var name_value: Label
@export var program_value: Label
@export var issue_date_value: Label
@export var registrar_value: Label
@export var body_label: Label
@export var student_label: Label
@export var notes_label: RandEmojiLabel

const SCHOOL_PROGRAMS: Array[String] = [
	"Scientific Track (Science)", 
	"Scientific Track (Math)", 
	"Arts Track", 
	"Languages Track", 
	"Technical Industrial Diploma", 
	"Technical Commercial Diploma", 
	"Technical Agricultural Diploma", 
	"IGCSE Programme", 
	"American Diploma Programme", 
]

const AR_SCHOOL_PROGRAMS: Array[String] = [
	"الشعبة العلمية (علوم)", 
	"الشعبة العلمية (رياضة)", 
	"الشعبة الأدبية", 
	"شعبة اللغات", 
	"دبلوم صناعي", 
	"دبلوم تجاري", 
	"دبلوم زراعي", 
	"برنامج IGCSE", 
	"برنامج الدبلومة الأمريكية", 
]

func populate(case: CaseData):
	var civ_age: int = case.civilian.birth_date.get_age()
	var inst: String
	var lang: = TranslationServer.get_locale()

	if civ_age <= OccupationDatabase.YOUNG_AGE_MAX:
		inst = "مدرسة" if lang == "ar" else "School"
	else:
		inst = "جامعة" if lang == "ar" else "University"

	if lang == "ar":
		institution_value.text = "%s %s" % [inst, case.civilian.address.governorate]
	else:
		institution_value.text = "%s %s" % [case.civilian.address.governorate, inst]

	name_value.text = case.civilian.full_name
	var programs: Array[String] = AR_SCHOOL_PROGRAMS if lang == "ar" else SCHOOL_PROGRAMS
	program_value.text = programs.pick_random()
	issue_date_value.text = CustomDate.generate_random_birth_date(0, 1).get_short()
	registrar_value.text = NameDatabase.get_random_name("m")
	if lang == "ar":
		body_label.text = FunnyTexts.genderize("تشهد بأن {m:الطالب|الطالبة} {m:المذكور|المذكورة} أدناه {m:مسجل|مسجلة} حالياً في مدرستنا.", case.civilian.gender)
		student_label.text = FunnyTexts.genderize("{m:الطالب|الطالبة}:", case.civilian.gender)
	else:
		body_label.text = "This certifies that the below named student is currently enrolled in our school."
		student_label.text = "Student:"
	notes_label.gender = case.civilian.gender
	notes_label.randomize_emoji()
