extends Reference

"""
Heavily based on https://github.com/gempir/go-twitch-irc

A copy of the license is provided at <repo_root>/licenses/
"""

const TAG_ESCAPE_CHARACTERS := [
	["\\s", " "],
	["\\n", ""],
	["\\r", ""],
	["\\:", ";"],
	["\\\\", "\\"]
]

class MessageSource:
	var nickname := ""
	var username := ""
	var host := ""
	
	func get_as_dict() -> Dictionary:
		var r := {}
		for i in get_property_list():
			if i.name in ["Reference", "script", "Script Variables"]:
				continue
			r[i.name] = get(i.name)
		
		return r
	
	func _to_string() -> String:
		var r := {}
		for i in get_property_list():
			if i.name in ["Reference", "script", "Script Variables"]:
				continue
			r[i.name] = get(i.name)
		
		return JSON.print(r, "\t")

var raw := ""
var tags := {}
var source := MessageSource.new()
var command := ""
var params := []

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _to_string() -> String:
	var r := {}
	for i in get_property_list():
		if i.name in ["Reference", "script", "Script Variables"]:
			continue
		r[i.name] = get(i.name) if i.name != "source" else get(i.name).get_as_dict()
	
	return JSON.print(r, "\t")

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

static func _parse_tags(text: String) -> Dictionary:
	var r := {}
	
	text = text.trim_prefix("@")
	
	for tag in text.split(";"):
		var pair: PoolStringArray = tag.split("=", 2)
		var key := pair[0]
		
		var value := ""
		if pair.size() == 2:
			value = _parse_tag_value(pair[1])
		
		r[key] = value
	
	return r

static func _parse_tag_value(text: String) -> String:
	for i in TAG_ESCAPE_CHARACTERS:
		text = text.replace(i[0], i[1])
	
	text = text.strip_edges()
	
	return text

static func _parse_message_source(text: String) -> MessageSource:
	var r := MessageSource.new()
	
	text = text.trim_prefix(":")
	
	var regex := RegEx.new()
	regex.compile("([^!|@]?[\\w\\.\\\\u\\d\\ta-zA-Z]+)")
	
	var split := regex.search_all(text)
	if split.size() == 0:
		return r
	
	match split.size():
		1:
			r.host = split[0].get_string()
		2:
			r.nickname = split[0].get_string()
			r.host = split[1].get_string()
		_:
			r.nickname = split[0].get_string()
			r.username = split[1].get_string()
			r.host = split[2].get_string()
	
	return r

###############################################################################
# Public functions                                                            #
###############################################################################

func parse(text: String) -> int:
	raw = text
	
	var split_text: Array = text.split(" ")
	var index: int = 0
	
	if split_text[index].left(1) == "@":
		tags = _parse_tags(split_text[index])
		index += 1
	
	if index >= split_text.size():
		printerr("Partial IRC message: %s" % text)
		return ERR_INVALID_DATA
	
	if split_text[index].left(1) == ":":
		source = _parse_message_source(split_text[index])
		index += 1
	
	if index >= split_text.size():
		printerr("IRC message has no command")
		return ERR_INVALID_DATA
	
	command = split_text[index]
	index += 1
	
	var slice: Array = split_text.slice(index, split_text.size())
	for i in slice.size():
		var t: String = slice[i]
		if t.left(1) == ":":
			t = PoolStringArray(split_text.slice(index + i, split_text.size())).join(" ")
			t = t.trim_prefix(":")
			params.append(t)
			break
		
		params.append(t)
	
	return OK
