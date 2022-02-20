extends Reference

const POLL_DELAY: int = 500
const USER_AGENT := "User-Agent: twitch-gd/1.0 (Godot)"
const ACCEPT_ALL_HEADER := "Accept: */*"

const TWITCH_REFRESH_BASE_URL := "www.id.twitch.tv"
const TWITCH_REFRESH_TOKEN_URI_FORMAT := "/oauth2/token?grant_type=refresh_token&refresh_token=%s&client_id=%s&client_secret=%s"

const HttpResponse = preload("res://addons/twitch-gd/model/http/http_response.gd")
const RefreshResponse = preload("res://addons/twitch-gd/model/http/refresh_response.gd")

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init() -> void:
	pass

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

func _send_request(base_url: String, uri: String, http_method: int, headers: Array = []) -> HttpResponse:
	var r := HttpResponse.new()
	
	var http := HTTPClient.new()
	
	var err := http.connect_to_host(base_url)
	if err != OK:
		printerr("Unable to connect to Twitch refresh url host: %s" % base_url)
		return r
	
	print_debug("Connecting")
	while http.get_status() == HTTPClient.STATUS_CONNECTING or \
			http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		print_debug("...")
		if not OS.has_feature("web"):
			OS.delay_msec(POLL_DELAY)
		else:
			yield(Engine.get_main_loop(), "idle_frame")
	
	if http.get_status() != HTTPClient.STATUS_CONNECTED:
		printerr("Unable to connect to Twitch refresh url: %s" % base_url)
		return r
	
	err = http.request(http_method,uri,headers)
	if err != OK:
		printerr("Unable to send POST request to %s%s" % [base_url, uri])
		return r
	
	print_debug("Requesting")
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		http.poll()
		print_debug("...")
		if not OS.has_feature("web"):
			OS.delay_msec(POLL_DELAY)
		else:
			yield(Engine.get_main_loop(), "idle_frame")
	
	if not http.get_status() == HTTPClient.STATUS_BODY or \
			not http.get_status() == HTTPClient.STATUS_CONNECTED:
		printerr("Unexpected response from %s%s" % [base_url, uri])
	
	r.bailed_out = false
	r.code = http.get_response_code()
	r.headers = http.get_response_headers_as_dictionary()
	
	if not http.has_response():
		printerr("No response received from %s%s" % [base_url, uri])
		return r
	
	var rb := PoolByteArray()
	
	print_debug("Reading response")
	while http.get_status() == HTTPClient.STATUS_BODY:
		http.poll()
		print_debug("...")
		var chunk: PoolByteArray = http.read_response_body_chunk()
		if chunk.size() == 0:
			if not OS.has_feature("web"):
				OS.delay_msec(POLL_DELAY)
			else:
				yield(Engine.get_main_loop(), "idle_frame")
		else:
			rb.append_array(chunk)
	
	# TODO can response bodies by encoded in utf8?
	r.body = rb.get_string_from_ascii()
	
	print_debug("Done!")
	
	return r

###############################################################################
# Public functions                                                            #
###############################################################################

func refresh_token(client_id: String, client_secret: String, refresh: String) -> RefreshResponse:
	print_debug("Refreshing token")
	
	var r := RefreshResponse.new()
	
	var response: HttpResponse = _send_request(
		TWITCH_REFRESH_BASE_URL,
		TWITCH_REFRESH_TOKEN_URI_FORMAT % [refresh, client_id, client_secret],
		HTTPClient.METHOD_POST,
		[USER_AGENT, ACCEPT_ALL_HEADER]
	)
	
	if response.bailed_out:
		printerr("Request bailed out early")
		return r
	
	if not response.code >= 200 and not response.code <= 299:
		printerr("Bad response code %d with body %s" % [response.code, response.body])
		return r
	
	var json_response := JSON.parse(response.body)
	if json_response.error != OK:
		printerr("Unable to parse body: %s\nParse error: %s" % [response.body, json_response.error_string])
		return r
	
	var json = json_response.result
	if typeof(json) != TYPE_DICTIONARY:
		printerr("Unexpected response: %s" % str(json))
		return r
	
	if r.parse_from_dictionary(json) != OK:
		return r
	
	r.bailed_out = false
	
	return r

func refresh_token_dict(client_id: String, client_secret: String, refresh: String) -> Dictionary:
	"""
	Simple wrapper around refresh_token
	"""
	var rr := refresh_token(client_id, client_secret, refresh)
	if rr.bailed_out:
		return {}
	
	return rr.get_as_dictionary()
