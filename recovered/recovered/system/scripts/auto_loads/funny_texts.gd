extends Node







var _gender_regex: RegEx

func _get_gender_regex() -> RegEx:
	if not _gender_regex:
		_gender_regex = RegEx.new()
		_gender_regex.compile("\\{m:([^|{}]*)\\|([^{}]*)\\}")
	return _gender_regex

func genderize(text: String, gender: String) -> String:
	if not text.contains("{m:"):
		return text
	var regex: = _get_gender_regex()
	var is_female: = gender == "f"
	var result: = ""
	var pos: = 0
	for m in regex.search_all(text):
		result += text.substr(pos, m.get_start() - pos)
		result += m.get_string(2) if is_female else m.get_string(1)
		pos = m.get_end()
	result += text.substr(pos)
	return result



func _text_bag(key: String, list: Array) -> ShuffledBag:
	return ShuffledBag.pool_for("%s:%s" % [TranslationServer.get_locale(), key], list)

func _is_ar() -> bool:
	return TranslationServer.get_locale() == "ar"

func _bag_text(key: String, en_list: Array, ar_list: Array, gender: String = "") -> String:
	var list: = ar_list if _is_ar() else en_list
	return genderize(_text_bag(key, list).next(), gender)


var new_id_reasons: Array[String] = [
"Apparently, I am an adult now.", 
"I think I'm old enough for this.", 
"Time to finally have a piece of plastic with my name on it.", 
"I promise I won't lose it… probably.", 
"Mom said I need one.", 
]

var ar_new_id_reasons: Array[String] = [
"كبرت خلاص.", 
"أهو {m:الواحد|الواحدة} {m:كبر|كبرت}.", 
"أبويا جابني غصب.", 
"نفسي يبقى عندي بطاقة باسمي.", 
"{m:عايز|عايزة} أخلص منها وخلاص.", 
"عشان محدش يقولي {m:لسه عيل|لسه عيلة}.", 
"أمي قالتلي مفيش خروج من غيرها.", 
"{m:عايز|عايزة} أبقى {m:مواطن|مواطنة} رسمي.", 
"قالولي مش هعرف أعمل أي حاجة من غيرها.", 
"بيقولو شكلها حلو في {m:المحفظة|البوك}.", 
"أمي قالتلي لو {m:مرجعتش|مرجعتيش} بيها {m:متدخلش|متدخليش} البيت.", 
"كل شوية حد يقولي: فين بطاقتك؟", 
"كل {m:صحابي|صحباتي} طلعوها إلا أنا.", 
"بصراحة مش {m:عارف|عارفة}...", 
]

var renew_id_reasons: Array[String] = [
"I moved. Surprise!", 
"My old ID looked tired.", 
"None of your business!.", 
"Just keeping my papers fresh.", 
"The photo is so old I had hair.", 
"I want a photo where I don't look like a suspect.", 
"The government said 'update or else' so here I am.", 
]

var ar_renew_id_reasons: Array[String] = [
"البطاقة القديمة انتهت.", 
"ملكش دعوة", 
"وانتا مالك؟", 
"أنا {m:حر|حرة}.", 
"أهو بنجدد الورق.", 
"بجدد الورق وخلاص.", 
"محدش بيصدق إن دي صورتي.", 
"{m:عايز|عايزه} صورة مش {m:هبان|هتبان} فيها {m:مجرم|مجرمة}.", 
"اتغسلت مع البنطلون بالغلط.", 
"صرصار لمسها, {m:مقروف|مقروفة} أمسكها تاني.", 
"{m:عايز|عايزه} أحدث بياناتي.", 
"البطاقة عايزة بطاقة.", 
"أمي قالتلي أغير الصورة العفشة دي.", 
"البطاقة من العصر الحجري.", 
]

var lost_id_reasons: Array[String] = [
"It fell into a black hole.", 
"I swear I had it… somewhere.", 
"Lost in mysterious circumstances.", 
"I blame the dog.", 
"The wind stole it.", 
"I think I left it in a taxi. In 2019.", 
"My cousin borrowed it.", 
]

var ar_lost_id_reasons: Array[String] = [
"كانت معايا وضاعت.", 
"ضاعت في ظروف غامضة.", 
"كلب بلدي بلعها.", 
"ابن عمي استلفها.", 
"وقعت مني.", 
"مش {m:لاقيها|لاقياها} من يومين.", 
"ضاعت... الله أعلم راحت فين.", 
"كانت معايا والله.", 
"أكيد وقعت في تاكسي.", 
"آخر مرة شوفتها كانت في جيب البنطلون.", 
"المحفظة اتسرقت.", 
"أمي شالتها ومش فاكرة حطتها فين.", 
"دورت في البيت كله.", 
"أظن سبتها عند عم عبده بتاع الكشري.", 
"وقعت في الترعة.", 
"آخر مرة شوفتها كانت قبل العيد.", 
"مش لاقيها, يمكن نسيتها فالتلاجة.", 
]

func get_new_id_reason(gender: String = "") -> String:
	return _bag_text("new_id_reason", new_id_reasons, ar_new_id_reasons, gender)
func get_renew_id_reason(gender: String = "") -> String:
	return _bag_text("renew_id_reason", renew_id_reasons, ar_renew_id_reasons, gender)
func get_lost_id_reason(gender: String = "") -> String:
	return _bag_text("lost_id_reason", lost_id_reasons, ar_lost_id_reasons, gender)





func get_case_reason(case: CaseData) -> String:
	var gender: = case.civilian.gender if case.civilian else ""
	if case.special_citizen_id != "":


		if not case.special_reason_line.is_empty():
			return genderize(case.special_reason_line, gender)
		var reason: String = SpecialCitizensDatabase.get_reason(case.special_citizen_id, case.case_type)
		if reason != "":
			return genderize(reason, gender)
	match case.case_type:
		Enums.CaseType.NEW_ID:
			return get_new_id_reason(gender)
		Enums.CaseType.RENEW_ID:
			return get_renew_id_reason(gender)
		Enums.CaseType.LOST_ID:
			return get_lost_id_reason(gender)
	return ""

var marriage_texts: Array[String] = [
	"Union verified. No rollback available.", 
	"Marriage approved 👍", 
	"Commitment recorded permanently.", 
	"Parties voluntarily consented.", 
	"Contract signed. Refunds not accepted.", 
	"Good luck.", 
]

var ar_marriage_texts: Array[String] = [
	"تم الموافقة على الجواز 👍", 
	"الطرفين وافقوا من غير ضغط.", 
	"العقد اتمضي. مفيش استرجاع.", 
	"تم تسجيل عقد الزواج.", 
	"تم التوثيق بنجاح.", 
	"تمت الموافقة. ربنا يستر.", 
	"تم الاتفاق بكامل إرادتهم... على كلامهم.", 
	"نتمنى لكم حياة سعيدة... أو على الأقل هادية.", 
	"تم التوقيع. الشكاوى بعد سنة على الأقل.", 
	"العقد اتختم. خلاص كده.", 
	"العقد إتختم, مفيش زرار رجوع.", 
	"لو غيرت رأيك... متأخر شوية.", 
	"الطرفين بقوا على ذمة بعض.", 
	"مبروك, عقبال الأقساط والمسؤوليات.", 
]

var birth_texts: Array[String] = [
	"Person born successfully 👍", 
	"Bro spawned lmao 🔥", 
	"+1 citizen generated.", 
	"Welcome to the system.", 
	"New human registered.", 
	"Another taxpayer born.", 
]

var ar_birth_texts: Array[String] = [
	"تمت الولادة بنجاح 👍", 
	"+1 {m:مواطن|مواطنة}.", 
	"تم إنتاج {m:مواطن جديد|مواطنة جديدة}.", 
	"تم تسجيل {m:المولود|المولودة} بنجاح.", 
	"تم إضافة {m:مواطن|مواطنة} للنظام.", 
	"تم إصدار إنسان.", 
	"تم تفعيل {m:المواطن|المواطنة}.", 
	"تم انتاج {m:عضو جديد|عضوة جديدة} في المجتمع.", 
	"تم إنشاء {m:مواطن|مواطنة}.", 
]

var police_texts: Array[String] = [
	"Item reported missing. Probably eaten.", 
	"ID was lost. Search efforts: minimal.", 
	"Citizen claims loss. We believe them. Mostly.", 
	"Loss confirmed. Recovery unlikely.", 
	"Loss acknowledged 👍", 
	"Investigation concluded: it's gone.", 
	"Filed under unsolved mysteries.", 
	"Official statement: we looked. It's not there.", 
	"We checked under the couch. Nothing.", 
]

var ar_police_texts: Array[String] = [
	"تم إثبات الفقد. غالباً اتاكلت.", 
	"البطاقة ضاعت. مجهودات البحث: ضعيفة.", 
	"{m:المواطن|المواطنة} {m:بيقول|بتقول} ضاعت. {m:مصدقينه|مصدقينها}. الى حد ما.", 
	"نتيجة التحقيقات: مش لاقينها.", 
	"دورنا تحت الكنبة. مفيش حاجة.", 
	"تم تحرير المحضر بنجاح.", 
	"تم إثبات الفقد. احتمال الرجوع ضعيف.", 
	"المحضر اتكتب... والباقي على الله.", 
	"تم تسجيل البلاغ.", 
	"تم استلام البلاغ 👍", 
	"تم تدوين أقوال {m:المواطن|المواطنة}.", 
	"هنرن {m:عليك|عليكي} لو لقيناها.", 
	"تم إثبات إن البطاقة مش موجودة.", 
	"تم تسجيل الواقعة.", 
	"لو ظهرت هنبقى نكلمك.", 
	"تم البحث... بالعين المجردة.", 
	"ربنا يعوض {m:عليك|عليكي}."
]

func get_police_text(gender: String = "") -> String:
	return _bag_text("police_text", police_texts, ar_police_texts, gender)
func get_birth_text(gender: String = "") -> String:
	return _bag_text("birth_text", birth_texts, ar_birth_texts, gender)
func get_marriage_text(gender: String = "") -> String:
	return _bag_text("marriage_text", marriage_texts, ar_marriage_texts, gender)

func play_arrival_dialogue(case: CaseData) -> String:

	if case and case.special_citizen_id != "":


		if not case.special_arrival_line.is_empty():
			var baked: = genderize(case.special_arrival_line, case.civilian.gender if case.civilian else "")
			DialogueBox.show_message(baked)
			return baked
		if SpecialCitizensDatabase.has_arrival_dialogue(case.special_citizen_id):
			var line: String = SpecialCitizensDatabase.get_arrival_dialogue(case.special_citizen_id)
			if line != "":
				line = genderize(line, case.civilian.gender if case.civilian else "")
				DialogueBox.show_message(line)
				return line
	var case_type = case.case_type
	var list: Array[String]
	var key: = ""
	if randf() >= 0.3:
		list = get_arrival_list(-1)
		key = "arrival_generic"
	else:
		list = get_arrival_list(case_type)
		key = "arrival_%d" % case_type
	var line: String = _text_bag(key, list).next()
	line = genderize(line, case.civilian.gender)
	DialogueBox.show_message(line)
	return line

var new_dialogues: Array[String] = [
	"Hello! I'm here to become officially me.", 
	"I guess I'm old enough for this now.", 
	"Hey there! Time to get an ID, I suppose.", 
	"Hey! My parents said I should come here.", 
	"Hello! I think I finally qualify for an ID.", 
	"Need ID, NOW!", 
	"I'm 16 now!", 
	"My mom is waiting outside. Please be quick.", 
	"Am I in the right place?", 
]
var ar_new_dialogues: Array[String] = [
	"أبويا وأمي قالولي أجي هنا.", 
	"ماما مستنياني برة. بسرعة لو سمحت.", 
	"صباح الخير... دي أول مرة أعمل بطاقة.", 
	"{m:جاي|جاية} أطلع بطاقة لأول مرة.", 
	"قالولي أجي هنا.", 
	"أمي مستنياني برا، ياريت ننجز.", 
	"{m:محتاج|محتاجة} أطلع بطاقة.", 
	"أنا دوري؟", 
	"معايا كل الورق أعتقد.", 
	"جيت بدري عشان الزحمة.", 
	"ربنا يستر من الصورة.", 
	"دي أول بطاقة ليا.", 
	"أهو كبرت وبقى عندي 16 سنة.", 
	"بابا قالي متضيعش الورق.", 
	"لو ناقص ورقة هعيط.", 
	"متقوليش ناقص ختم.", 
	"هي الصورة هتطلع وحشة صح؟", 
]

var renew_dialogues: Array[String] = [
	"One new ID, please.", 
	"My ID's outdated, can you help?", 
	"Hi! I'm here to renew my ID.", 
	"my old ID needs a refresh.", 
	"Hey, need a replacement ID.", 
	"Yep, expired...", 
	"I looked different 10 years ago. Trust me.", 
	"I want a better photo.", 
	"Same guy, older face.", 
	"The old one has a coffee stain.", 
]
var ar_renew_dialogues: Array[String] = [
	"البطاقة قدمت، ممكن تساعدني؟", 
	"البطاقة القديمة محتاجة تتجدد.", 
	"{m:عايز|عايزه} صورة أحسن.", 
	"صباح الخير، {m:جاي|جاية} أجدد البطاقة.", 
	"{m:محتاج|محتاجة} أجدد البطاقة.", 
	"الصورة بقت قديمة أوي.", 
	"البطاقة دي شافت أيام.", 
	"المرة دي نفسي الصورة تطلع آدمية.", 
	"اتفضل، {m:عايز|عايزه} اجدد البطاقة بقى.", 
	"أنا حافظ المبنى ده أكتر من بيتي.", 
]
var lost_dialogues: Array[String] = [
	"I lost my ID…", 
	"ID gone, need replacement...", 
	"It disappeared, and I definitely need a new one.", 
	"My ID vanished mysteriously.", 
	"Can't find my ID anywhere. Can you look in your pocket?", 
	"ID's gone. Must've been the wind...", 
	"My ID is missing, can you issue a new one?", 
	"Someone stole my ID...", 
	"Hey! I need a replacement ID, it's lost.", 
	"I swear I put it in my other pants.", 
	"It's in the house somewhere. I just don't want to look.", 
]
var ar_lost_dialogues: Array[String] = [
	"ضيعت البطاقة...", 
	"البطاقة ضاعت...", 
	"البطاقة اختفت.", 
	"مش {m:لاقي|لاقية} البطاقة في أي مكان. شوفها في جيبك كدا.", 

	"صباح الخير... ضيعت البطاقة.", 
	"البطاقة ضاعت مني.", 
	"مش {m:لاقي|لاقية} البطاقة خالص.", 
	"والله كانت معايا.", 
	"اختفت... معرفش إزاي.", 
	"آخر مرة شوفتها كانت امبارح.", 
	"دورت عليها في كل حتة.", 
	"يمكن وقعت في تاكسي.", 
	"المحفظة راحت... والبطاقة معاها.", 
	"أمي بتقول هلاقيها لو دورت كويس... مش {m:مقتنع|مقتنعة}.", 
	"متسألنيش ضاعت إزاي.", 
	"اتفضل... ده محضر الفقد.", 
	"{m:عايز|عايزه} أطلع بدل فاقد.", 
	"أنا {m:شاكك|شاككة} في ابن أختي.", 
	"دورت في كل جيوب البنطلونات.", 
	"دي تالت مرة أضيعها... بس متقولش لحد.", 
]
var generic_dialogues: Array[String] = [
	"I sure hope my ID is done today.", 
	"I just need an ID… that's all.", 
	"Hopefully nothing is missing.", 
	"Please don't make me wait too long.", 
	"I'd like my ID before lunch.", 
	"Fingers crossed my papers are okay.", 
	"I'm just here to exist officially.", 
	"Can we make this quick?", 
	"I hope this goes smoothly.", 
	"Because the government insists I exist.", 
	"I really love filling out forms, said no one ever.", 
	"Another day, another ID.", 
	"I'm thrilled to stand in line.", 
	"Just another citizen doing citizen things.", 
	"I need this ID now!", 
	"Can you hurry up? I don't have all day.", 
	"I want my ID and I want it fast.", 
	"Stop wasting my time.", 
	"I'm not leaving without my ID.", 
	"I've waited too long already!", 
	"Is this teller window 23?", 
	"If you say 'come back tomorrow' I'm going to scream.", 
	"Did I fill everything right? I'm bad at forms.", 
	"Let's get this over with. Please.", 
	"I have a good feeling about this.", 
	"I practiced what to say the whole way here.", 
]
var ar_generic_dialogues: Array[String] = [
	"يارب نخلص النهاردة.", 
	"أتمنى ميكونش في حاجة ناقصة.", 
	"{m:عايز|عايزه} البطاقة قبل الغدا.", 
	"إن شاء الله أوراقي تمام.", 
	"مبحبش أكتر من وقوف في طوابير عالصبح.", 
	"{m:عايز|عايزه} البطاقة دلوقتي!", 
	"ممكن تستعجل شوية؟ مش فاضيلك طول اليوم.", 
	"مش همشي من غير بطاقتي.", 
	"استنيت كتير أوي في الطابور...", 
	"ده شباك 3؟", 
	"لو قلتلي ارجع بكرة تاني هصوت.", 
	"شوفلي كدا لو كل حاجة صح.", 

	"صباح الخير.", 
	"يارب الورق كله يبقى تمام.", 
	"إن شاء الله مفيش حاجة ناقصة.", 
	"أنا {m:مستعجل|مستعجلة} حبتين.", 
	"الدنيا زحمة النهارده.", 
	"أنا ماليش في الورق ده.", 
	"يارب ميبقاش ناقص ختم.", 
	"متقوليش ارجع بكرة.", 
	"خلصني بسرعة.", 
	"أنا جيت بدري عشان الزحمة.", 
	"معايا كل الورق... أظن.", 
	"اتأكدلي إن كل حاجة تمام.", 
	"أنا مليش نفس أرجع تاني.", 
	"{m:عايز|عايزه} أخلص وأمشي.", 
	"ربنا يسهل.", 
	"لو كل حاجة تمام هبقى {m:مبسوط|مبسوطة}.", 
	"البطايق هنا ولا الشباك اللي بعده؟", 
	"أنا لفيت عالمبنى كلو.", 
	"كل ده عشان ورقة.", 
	"أنا {m:واخد|واخدة} إذن من الشغل مخصوص.", 
	"هو في موظف بيبتسم هنا؟", 
	"أنا {m:جاي|جاية} من آخر الدنيا.", 
]

func get_arrival_list(case_type: int) -> Array[String]:
	var is_ar: = _is_ar()
	match case_type:
		Enums.CaseType.NEW_ID: return ar_new_dialogues if is_ar else new_dialogues
		Enums.CaseType.RENEW_ID: return ar_renew_dialogues if is_ar else renew_dialogues
		Enums.CaseType.LOST_ID: return ar_lost_dialogues if is_ar else lost_dialogues
		_: return ar_generic_dialogues if is_ar else generic_dialogues

func get_green_correct(gender: String = "") -> String:
	return _bag_text("green_correct", green_correct, ar_green_correct, gender)
func get_red_correct(gender: String = "") -> String:
	return _bag_text("red_correct", red_correct, ar_red_correct, gender)
func get_red_wrong(gender: String = "") -> String:
	return _bag_text("red_wrong", red_wrong, ar_red_wrong, gender)

func get_perfect_day_banner() -> String:
	if _is_ar():
		return "ولا غلطة. السجل فخور بيك."
	return "No mistakes. The Registry is proud of you."

var green_correct: Array[String] = [
	"Thank you! That was surprisingly fast.", 
	"Finally.", 
	"Impressive work, all done correctly!", 
	"Wow, that was painless. Thanks!", 
	"Great!", 
	"Thanks", 
	"You're my favorite clerk. Don't tell the others.", 
	"I knew I picked the right window!", 
	"I will name my firstborn after you.", 
	"Amazing!", 
	"Excellent. Good day to you.", 
]
var ar_green_correct: Array[String] = [
	"إنت أحسن موظف هنا. متقولش للتانيين.", 
	"هو كده فعلًا؟ خلصت؟", 
	"أنا كنت {m:مجهز|مجهزة} نفسي لخناقة.", 
	"ربنا يرزقك ترقية.", 
	"تستاهل كوباية شاي.", 
	"أحسن موظف في المبنى.", 
	"تمام، شكرًا.", 
	"ربنا يباركلك.", 
	"الله يكرمك.", 
	"الله ينور.", 
	"ممتاز، يومك جميل.", 
	"كتر خيرك.", 
	"تسلم!", 
	"شكرًا.", 
]
var red_correct: Array[String] = [
	"Aww shucks...", 
	"Don't tell me I'll have to wait in line again...", 
	"I'll come back later, I guess.", 
	"Sigh...", 
	"I guess rules are rules.", 
	"Whatever...", 
	"How could I have missed that...", 
	"Heeeee7...", 
	"I knew I should've let my mom handle this.", 
	"Well. That's embarrassing.", 
	"Ah yes. I remember reading that. I chose to ignore it.", 
	"Of course this happened.", 
	"I'll just... go fix this. Maybe cry a little.", 
	"Ouch.", 
]
var ar_red_correct: Array[String] = [
	"متقوليش هارجع أقف في الطابور تاني...", 
	"إزاي {m:فاتني|فاتتني} دي...", 
	"يوووووووه...", 
	"هروح... أعيط شوية.", 

	"ماشي... هرجع أظبطها.", 
	"أصلحها وأرجع.", 
	"يا نهار أبيض...", 
	"كنت {m:حاسس|حاسة} إن في حاجة ناقصة.", 
	"أهو نرجع للطابور تاني.", 
	"يوم باين من أوله.", 
	"يا ريتني اتأكدت.", 
	"نسيت دي إزاي؟", 
	"ربنا يصبرني.", 
	"شكلي هقضي اليوم هنا.", 
	"هو أنا ليه كل مرة؟", 
	"النهارده مش يومي.", 
	"أنا كنت {m:عامل|عاملة} نفسي مش {m:شايف|شايفة}."
]
var red_wrong: Array[String] = [
	"Hey! That was valid!", 
	"I'm gonna tell someone about this!", 
	">:| Are you serious?", 
	"Wait... this can't be right!", 
	"This is wrong!", 
	"Come ooon! it was correct!!!", 
	"Are you even reading the papers?", 
	"I want to speak to the manager. No, the manager's manager.", 
	"THIS IS OUTRAGIOUS! Sorry. That was loud.", 
	"I'll remember this. I have a great memory for grudges.", 
	"Unbelievable. Absolutely unbelievable.", 
	"How could you..."
]
var ar_red_wrong: Array[String] = [
	"يا عم! دي كانت صح!", 
	"دي كانت صح!!!", 
	"أنت أصلاً قريت الأوراق؟", 
	"{m:عايز|عايزه} أكلم المدير. و مدير المدير.", 
	"هصوت وافضح الدنيا!", 
	"إزاي تعمل فيا كده...", 

	"إيه ده؟ الورق سليم!", 
	"في حاجة غلط.", 
	"إزاي يعني؟", 
	"بس كل حاجة تمام!", 
	"ده ظلم والله.", 
	"هشتكي.", 
	"حرام عليك الورق صح!", 
	"فين المدير؟", 
	"هاتلي الموظف اللي جنبك.", 
	"أنا {m:دافع|دافعة} دم قلبي في المواصلات.", 
	"هو إحنا هنهزر؟ الورق كان صح!", 
	"ثانية واحدة... إزاي؟", 
	"أنا هشتكيك... مش {m:عارف|عارفة} لمين بس هشتكيك.", 
]
