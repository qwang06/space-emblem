extends Object
class_name Utils

# Utility functions for the game

# Recursive function to find a descendant node by name
func find_descendant_by_name(node: Node, nodeName: String) -> Node:
	if not node:
		return null

	if node.name == nodeName:
		return node
	for child in node.get_children():
		var result = find_descendant_by_name(child, nodeName)
		if result:
			return result
	return null


func get_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()

		if error == OK:
			return json.get_data()
		else:
			print("Error parsing JSON: ", error)
	else:
		print("File does not exist")
	
	return {}