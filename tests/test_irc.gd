extends "res://tests/base_test.gd"

const IrcMessage = preload("res://addons/twitch-gd/model/irc_message.gd")

var irc: IrcMessage

func before_each():
	irc = IrcMessage.new()

func test_twitch_message_pass():
	irc.parse(":leppunen@tmi.twitch.tv PRIVMSG #pajlada :LUL")
	
	assert_eq(irc.raw, ":leppunen@tmi.twitch.tv PRIVMSG #pajlada :LUL")
	assert_eq(irc.source.nickname, "leppunen")
	assert_eq(irc.source.username, "")
	assert_eq(irc.source.host, "tmi.twitch.tv")
	assert_eq(irc.command, "PRIVMSG")
	assert_eq(irc.params, ["#pajlada", "LUL"])

func test_irc_message_tab_pass():
	irc.parse(":cool\tguy foo bar baz")
	
	assert_eq(irc.raw, ":cool\tguy foo bar baz")
	assert_eq(irc.source.host, "cool\tguy")
	assert_eq(irc.command, "foo")
	assert_has(irc.params, "bar")
	assert_has(irc.params, "baz")

func test_hex_escape_pass():
	irc.parse(":coolguy!ag@net\\u00035w\\u0003ork.admin PRIVMSG foo :bar baz")
	
	assert_eq(irc.raw, ":coolguy!ag@net\\u00035w\\u0003ork.admin PRIVMSG foo :bar baz")
	assert_eq(irc.source.nickname, "coolguy")
	assert_eq(irc.source.username, "ag")
	assert_eq(irc.source.host, "net\\u00035w\\u0003ork.admin")
	assert_eq(irc.command, "PRIVMSG")
	assert_has(irc.params, "foo")
	assert_has(irc.params, "bar baz")

func test_tags_pass():
	irc.parse("@tag1=value1;tag2;vendor1/tag3=value2;vendor2/tag4 :irc.example.com COMMAND param1 param2 :param3 param3")
	
	assert_eq(irc.raw, "@tag1=value1;tag2;vendor1/tag3=value2;vendor2/tag4 :irc.example.com COMMAND param1 param2 :param3 param3")
	assert_eq(irc.tags.tag1, "value1")
	assert_eq(irc.tags.tag2, "")
	assert_eq(irc.tags["vendor1/tag3"], "value2")
	assert_eq(irc.tags["vendor2/tag4"], "")
	assert_eq(irc.source.host, "irc.example.com")
	assert_eq(irc.command, "COMMAND")
	assert_eq(irc.params[2], "param3 param3")
