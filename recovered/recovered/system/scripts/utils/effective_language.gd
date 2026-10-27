extends RefCounted
class_name EffectiveLanguage


static func resolve(lang: String) -> String:
	return lang if not lang.is_empty() else TranslationServer.get_locale()
