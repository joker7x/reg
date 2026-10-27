class_name RadioStream
extends Node
## Live Icecast/Shoutcast MP3 into AudioStreamPlayer.
##
## Godot has no network AudioStream (godotengine/godot-proposals#11782), so the
## stream is cut on whole MPEG frame boundaries and each piece becomes its own
## AudioStreamMP3. Two players alternate: the next piece is decoded while the
## current one still plays and the handoff happens on `finished`, which keeps the
## seam under one audio frame instead of restarting playback on every buffer write.

enum State{IDLE, CONNECTING, REQUESTING, READING, STALLED}

signal started
signal stalled

const CHUNK_SECONDS := 4.0
const PREBUFFER_CHUNKS := 2
const MAX_QUEUED_CHUNKS := 8
const STALL_TIMEOUT_MS := 8000
const RETRY_STEPS := [1.0, 2.0, 4.0, 8.0, 15.0]
const DEFAULT_BITRATE_KBPS := 128

const BITRATE_V1_L3 := [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0]
const BITRATE_V2_L3 := [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0]
const SAMPLERATES := [[11025, 12000, 8000], [44100, 48000, 32000], [22050, 24000, 16000]]
const VERSION_TO_SR_TABLE := [0, -1, 2, 1]

var url: String = ""
var volume_db: float = -6.0
var _playing: bool = false

## Assigning `playing` from inside its own setter recurses in GDScript.
var playing: bool:
	get:
		return _playing
	set(v):
		if _playing == v:
			return
		_playing = v
		_apply_playing(v)

var _client := HTTPClient.new()
var _pending := PackedByteArray()
var _queue: Array[AudioStreamMP3] = []
var _players: Array[AudioStreamPlayer] = []
var _active: int = -1
var _state: State = State.IDLE
var _bitrate_kbps: int = DEFAULT_BITRATE_KBPS
var _last_byte_ms: int = 0
var _retry_at_ms: int = 0
var _retry_index: int = 0
var _redirects_left: int = 4
var _host := ""
var _port := 80
var _tls := false
var _path := "/"


func _ready() -> void :
	var bus := "Radio"
	if AudioServer.get_bus_index(bus) < 0:
		bus = "Master"
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = bus
		p.volume_db = volume_db
		p.finished.connect(_on_chunk_finished.bind(i))
		add_child(p)
		_players.append(p)


func _process(_delta: float) -> void :
	if not playing:
		return
	match _state:
		State.IDLE:
			_open(url)
		State.CONNECTING:
			_poll_connect()
		State.REQUESTING:
			_poll_request()
		State.READING:
			_read_stream()
		State.STALLED:
			if Time.get_ticks_msec() >= _retry_at_ms:
				_open(url)


func _apply_playing(v: bool) -> void :
	for p in _players:
		p.stop()
	_client.close()
	_active = -1
	if not v:
		_state = State.IDLE
		_reset_buffer()
		return
	_retry_index = 0
	_retry_at_ms = 0
	_state = State.IDLE


func _reset_buffer() -> void :
	_pending.resize(0)
	_queue.clear()


func _open(target: String) -> void :
	var parsed := _parse_url(target)
	if parsed.is_empty():
		push_warning("RadioStream: cannot parse url: " + target)
		_schedule_retry()
		return
	_tls = parsed["tls"]
	_host = parsed["host"]
	_port = parsed["port"]
	_path = parsed["path"]
	_client.close()
	_reset_buffer()
	_active = -1
	_redirects_left = 4
	_bitrate_kbps = DEFAULT_BITRATE_KBPS
	if _connect_host() != OK:
		_schedule_retry()
		return
	_state = State.CONNECTING


## HTTPS needs TLSOptions.client(); plain HTTP must take the no-tls overload.
func _connect_host() -> Error:
	if _tls:
		return _client.connect_to_host(_host, _port, TLSOptions.client())
	return _client.connect_to_host(_host, _port)


func _poll_connect() -> void :
	_client.poll()
	match _client.get_status():
		HTTPClient.STATUS_CONNECTED:
			var headers := PackedStringArray(["Accept: */*", "User-Agent: TheRegistry/1.0"])
			if _client.request(HTTPClient.METHOD_GET, _path, headers) != OK:
				_schedule_retry()
				return
			_state = State.REQUESTING
		HTTPClient.STATUS_CANT_CONNECT, HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
			_schedule_retry()
		_:
			pass


func _poll_request() -> void :
	_client.poll()
	match _client.get_status():
		HTTPClient.STATUS_BODY:
			if _handle_response_headers():
				_state = State.READING
				_last_byte_ms = Time.get_ticks_msec()
		HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_CANT_CONNECT:
			_schedule_retry()
		_:
			pass


## Returns false when the response needs a retry instead of a body read.
func _handle_response_headers() -> bool:
	var code := _client.get_response_code()
	if code in [301, 302, 303, 307, 308]:
		if _redirects_left <= 0:
			return false
		var location := _header("location")
		if location == "":
			return false
		_redirects_left -= 1
		_follow_location(location)
		return false
	if code != 200:
		push_warning("RadioStream: server answered %d for %s" % [code, url])
		return false
	var br := _header("icy-br").to_int()
	if br > 0:
		_bitrate_kbps = br
	return true


func _header(name: String) -> String:
	var prefix := name.to_lower() + ":"
	for h in _client.get_response_headers():
		if h.to_lower().begins_with(prefix):
			return h.substr(prefix.length()).strip_edges()
	return ""


func _follow_location(location: String) -> void :
	if location.begins_with("http://") or location.begins_with("https://"):
		url = location
		_open(url)
		return
	if location.begins_with("/"):
		_path = location
	else:
		_path = _path.trim_suffix("/") + "/" + location
	_client.close()
	if _connect_host() == OK:
		_state = State.CONNECTING
	else:
		_schedule_retry()


func _read_stream() -> void :
	_client.poll()
	match _client.get_status():
		HTTPClient.STATUS_BODY:
			var chunk := _client.read_response_body_chunk()
			if chunk.size() > 0:
				_pending.append_array(chunk)
				_last_byte_ms = Time.get_ticks_msec()
				_pack()
			elif Time.get_ticks_msec() - _last_byte_ms > STALL_TIMEOUT_MS:
				push_warning("RadioStream: stream stalled, reconnecting")
				_schedule_retry()
		HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_CANT_CONNECT, HTTPClient.STATUS_CONNECTED:
			_schedule_retry()
		_:
			pass


func _pack() -> void :
	if _frame_size(_pending, 0) <= 0:
		var head := _next_frame_at(_pending, 1)
		if head < 0:
			return
		_pending = _pending.slice(head)
	var target := int(CHUNK_SECONDS * _bitrate_kbps * 1000.0 / 8.0)
	if _pending.size() < target:
		return
	var end := _frame_end(_pending, target)
	if end <= 0:
		if _pending.size() > target * 8:
			push_warning("RadioStream: no frame boundary found, dropping bytes")
			_pending = _pending.slice(target)
		return
	var mp3 := AudioStreamMP3.new()
	mp3.data = _pending.slice(0, end)
	_pending = _pending.slice(end)
	_queue.append(mp3)
	if _queue.size() > MAX_QUEUED_CHUNKS:
		_queue.pop_front()
	if _active == -1 and _queue.size() >= PREBUFFER_CHUNKS:
		_active = 0
		_play_queued()


func _play_queued() -> void :
	var mp3: AudioStreamMP3 = _queue.pop_front()
	var p := _players[_active]
	p.stream = mp3
	p.volume_db = volume_db
	p.play()
	started.emit()


func _on_chunk_finished(index: int) -> void :
	if index != _active or not playing:
		return
	if _queue.is_empty():
		push_warning("RadioStream: ran ahead of the buffer")
		_schedule_retry()
		return
	_active = 1 - _active
	_play_queued()


func _schedule_retry() -> void :
	_client.close()
	_reset_buffer()
	_active = -1
	stalled.emit()
	if not playing:
		_state = State.IDLE
		return
	_state = State.STALLED
	var wait: float = RETRY_STEPS[min(_retry_index, RETRY_STEPS.size() - 1)]
	_retry_index += 1
	_retry_at_ms = Time.get_ticks_msec() + int(wait * 1000.0)
	for p in _players:
		p.stop()


func set_volume_db(v: float) -> void :
	volume_db = v
	for p in _players:
		p.volume_db = v


## First byte offset at or after `from` where a complete frame ends, or -1.
static func _frame_end(buf: PackedByteArray, from: int) -> int:
	var i := from
	while i + 4 <= buf.size():
		var s := _frame_size(buf, i)
		if s > 0 and i + s <= buf.size():
			return i + s
		i += 1
	return -1


static func _next_frame_at(buf: PackedByteArray, from: int) -> int:
	var i := from
	while i + 4 <= buf.size():
		if _frame_size(buf, i) > 0:
			return i
		i += 1
	return -1


## MPEG audio frame header at i, returning the full frame length in bytes.
## Only Layer III is accepted - that is all Icecast/Shoutcast serve.
static func _frame_size(buf: PackedByteArray, i: int) -> int:
	if i < 0 or i + 4 > buf.size():
		return 0
	if buf[i] != 0xFF or (buf[i + 1] & 0xE0) != 0xE0:
		return 0
	var version := (buf[i + 1] >> 3) & 0x03
	var layer := (buf[i + 1] >> 1) & 0x03
	if version == 0x01 or layer != 0x01:
		return 0
	var sr_slot: int = VERSION_TO_SR_TABLE[version]
	if sr_slot < 0:
		return 0
	var br_index := (buf[i + 2] >> 4) & 0x0F
	var sr_index := (buf[i + 2] >> 2) & 0x03
	var padding := (buf[i + 2] >> 1) & 0x01
	if br_index == 0 or br_index == 15 or sr_index > 2:
		return 0
	var table := BITRATE_V1_L3 if version == 0x03 else BITRATE_V2_L3
	var bitrate: int = table[br_index] * 1000
	var rate: int = SAMPLERATES[sr_slot][sr_index]
	if rate == 0:
		return 0
	var coef := 144 if version == 0x03 else 72
	return int(float(coef * bitrate) / float(rate)) + padding


static func _parse_url(u: String) -> Dictionary:
	var tls := true
	var rest := ""
	if u.begins_with("https://"):
		rest = u.substr(8)
	elif u.begins_with("http://"):
		rest = u.substr(7)
		tls = false
	else:
		return {}
	var slash := rest.find("/")
	var authority := rest if slash < 0 else rest.substr(0, slash)
	var path := "/" if slash < 0 else rest.substr(slash)
	if authority == "":
		return {}
	var port := 443 if tls else 80
	var host := authority
	if authority.contains(":"):
		host = authority.get_slice(":", 0)
		port = authority.get_slice(":", 1).to_int()
	if host == "":
		return {}
	return {"tls": tls, "host": host, "port": port, "path": path}
