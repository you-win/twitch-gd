extends Reference

var bailed_out := true

func get_as_dictionary() -> Dictionary:
	var r := {}
	for i in get_property_list():
		if i.name in ["Reference", "script", "Script Variables"]:
			continue
		r[i.name] = get(i.name)
	
	return r

func parse_from_dictionary(data: Dictionary) -> int:
	for key in data.keys():
		if not get(key):
			# All model classes have default values, so there's no chance of
			# accidentally returning an error
			return ERR_DOES_NOT_EXIST
		set(key, data[key])
	
	return OK
	
func _to_string() -> String:
	return JSON.print(get_as_dictionary(), "\t")
