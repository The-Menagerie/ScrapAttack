extends VBoxContainer

var build_DB

func _ready():
	var db_file = FileAccess.open("res://Resources/Utility_Assets/building_database.json", FileAccess.READ)
	var build_DB_json = JSON.new()
	var error = build_DB_json.parse(db_file.get_as_text())
	if error == OK:
		build_DB = build_DB_json.data
		var build_option_base = preload("res://Scenes/ui_scenes/building_option.tscn")
		for i in build_DB:
			var building = build_DB[i]
			var building_op = build_option_base.instantiate()
			building_op.initialize(building)
			add_child(building_op)
			
		
	
	
