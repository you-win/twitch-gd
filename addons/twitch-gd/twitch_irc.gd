extends "res://addons/twitch-gd/twitch_websocket_base.gd"

const TWITCH_CHAT_URL := "wss://irc-ws.chat.twitch.tv:443"

const PING := "PING"
const PONG := "PONG :tmi.twitch.tv"

const AUTH_PASS := "PASS oauth:%s"
const AUTH_USER := "NICK %s"

const REQUEST_MEMBERSHIP := "CAP REQ :twitch.tv/membership"
const REQUEST_TAGS := "CAP REQ :twitch.tv/tags"
const REQUEST_COMMANDS := "CAP REQ :twitch.tv/commands"

const JOIN_CHANNEL := "JOIN #%s"

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init() -> void:
	connect("connection_closed", self, "_on_connection_closed")
	connect("connection_error", self, "_on_connection_error")
	connect("connection_established", self, "_on_connection_established")
	connect("data_received", self, "_on_data_received")
	connect("server_close_request", self, "_on_server_close_request")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_connection_closed(was_clean_close: bool) -> void:
	if was_clean_close:
		print_debug("Connection closed cleanly")
	else:
		printerr("Connection not closed cleanly")

func _on_connection_error() -> void:
	printerr("Connection error")

func _on_connection_established(protocol: String) -> void:
	print_debug("Connection established using protocol: %s" % protocol)

func _on_data_received() -> void:
	var message := _get_message()
	
	if message.empty():
		print_debug("Empty message received")
		return
	
	# Chat messages come in the following format
	# :<optional user>!<optional user>@<optional user>.tmi.twitch.tv <num/IRC command> #<user/channel> :<message>
	# Reference https://dev.twitch.tv/docs/irc/guide
	var split_message := message.split(" ", true, 3)
	
	# We must respond to pings otherwise we will get disconnected
	if split_message[0] == PING:
		_send_message(PONG)

func _on_server_close_request(code: int, reason: String) -> void:
	print_debug("Server close request received with code %d and reason %s" % [code, reason])
	disconnect_from_host()

###############################################################################
# Private functions                                                           #
###############################################################################

func _parse_message(text: String) -> void:
	pass

###############################################################################
# Public functions                                                            #
###############################################################################

func establish_connection() -> int:
	return connect_to_url(TWITCH_CHAT_URL)

func authenticate(username: String, password: String) -> int:
	_set_text_write_mode()
	
	var password_err: int = _send_message(AUTH_PASS % password)
	if password_err != OK:
		return password_err
	var username_err: int = _send_message(AUTH_USER % username)
	if username_err != OK:
		return username_err
	
	return OK

func join_channel(username: String) -> int:
	return _send_message(JOIN_CHANNEL % username)

func request_membership() -> int:
	return _send_message(REQUEST_MEMBERSHIP)

func request_tags() -> int:
	return _send_message(REQUEST_TAGS)

func request_commands() -> int:
	return _send_message(REQUEST_COMMANDS)
