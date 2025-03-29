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