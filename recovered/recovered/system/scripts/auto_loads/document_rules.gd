extends Node

func get_required_docs(case_type: Enums.CaseType) -> Array[int]:
	match case_type:
		Enums.CaseType.NEW_ID:
			return [
				Enums.DocumentType.TICKET, 
				Enums.DocumentType.BIRTH_CERTIFICATE, 
				Enums.DocumentType.PROOF_OF_RESIDENCE, 
				Enums.DocumentType.PROOF_OF_OCCUPATION, 
			]

		Enums.CaseType.RENEW_ID:
			return [
				Enums.DocumentType.TICKET, 
				Enums.DocumentType.BIRTH_CERTIFICATE, 
				Enums.DocumentType.OLD_ID, 
				Enums.DocumentType.PROOF_OF_RESIDENCE, 
				Enums.DocumentType.PROOF_OF_OCCUPATION, 
			]

		Enums.CaseType.LOST_ID:
			return [
				Enums.DocumentType.TICKET, 
				Enums.DocumentType.BIRTH_CERTIFICATE, 
				Enums.DocumentType.POLICE_REPORT, 
				Enums.DocumentType.PROOF_OF_RESIDENCE, 
				Enums.DocumentType.PROOF_OF_OCCUPATION, 
			]

	return []
