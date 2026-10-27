extends Node

enum Decision{
	NONE, 
	APPROVE, 
	DENY
}
enum OccupationType{
	OCCUPATION, 
	EDUCATION, 
	UNEMPLOYED
}


enum OccupationHint{
	RANDOM, 
	UNEMPLOYED, 
	YOUNG_STUDENT, 
	UNIVERSITY_STUDENT, 
}
enum CaseType{
	NEW_ID, 
	RENEW_ID, 
	LOST_ID
	}

enum Religion{
	NONE, 
	MUSLIM, 
	CHRISTIAN
}
func case_type_name(index: int) -> String:
	return CaseType.keys()[index]

enum DocumentType{
	BIRTH_CERTIFICATE, 
	OLD_ID, 
	PROOF_OF_RESIDENCE, 
	POLICE_REPORT, 
	MARRIAGE_CERTIFICATE, 
	PROOF_OF_OCCUPATION, 
	DIVORCE_CERTIFICATE, 
	TICKET, 
}
func doc_type_name(index: int) -> String:
	return DocumentType.keys()[index]

enum MistakeType{
	MISSING_DOCUMENT, 
	WRONG_ENTRY, 
	FORGED_STAMP, 
}
func mistake_type_name(index: int) -> String:
	return MistakeType.keys()[index]

enum FormField{
	FULL_NAME, 
	DATE_OF_BIRTH, 
	PLACE_OF_BIRTH, 
	GENDER, 
	ADDRESS, 
	STATUS, 
}
func form_field_name(index: int) -> String:
	return FormField.keys()[index]
