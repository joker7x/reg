extends Node

signal message_added(speaker: String, text: String, number: int)
signal history_cleared

const SPEAKER_PLAYER: = "player"
const SPEAKER_CUSTOMER: = "customer"

const MAX_ENTRIES: = 50

var entries: Array = []

func add_message(speaker: String, text: String) -> void :
	if text.strip_edges() == "":
		return
	var number: = SaveSystem.civilians_served + 1
	entries.append({"speaker": speaker, "text": text, "number": number})
	while entries.size() > MAX_ENTRIES:
		entries.pop_front()
	message_added.emit(speaker, text, number)

func clear() -> void :
	entries.clear()
	history_cleared.emit()
