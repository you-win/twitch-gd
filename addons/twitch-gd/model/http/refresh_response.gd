extends "res://addons/twitch-gd/model/http/base_response.gd"

var access_token := ""
var refresh_token := ""
var expires_in: float = -1.0
var scope := []
var token_type := "bearer"
