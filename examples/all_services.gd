extends CanvasLayer

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	var irc = preload("res://addons/twitch-gd/model/irc_message.gd").new()
	
	irc.parse(":cool\tguy foo bar baz")
	print(irc)

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
