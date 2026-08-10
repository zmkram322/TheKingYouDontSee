class_name SceneWiring
extends RefCounted

# Reads .tscn files as TEXT and answers one question: is every node reference
# in them wired the way the loader actually needs?
#
# Godot only resolves a script property holding a node reference if the
# property's name is listed in node_paths=PackedStringArray(...) on that same
# node's [node ...] header. A bare NodePath("…") that isn't listed there loads
# as null — no error, no warning, nothing in the log. The editor writes the
# header for you; a scene edited by hand does not. That exact trap shipped a
# day/night cycle in this project that never ran, through two commits, and it
# is why "it runs without errors" stopped meaning anything here.
#
# Two more shapes of the same bug:
#   - An Array[NodePath] is resolved by hand with get_node_or_null(), so
#     listing it in node_paths is wrong. (Array[Node] doesn't resolve at all.)
#   - A name can survive in node_paths for a property that was renamed away.
#
# WHY THIS IS A TEXT SCAN AND MUST STAY ONE. At runtime a broken wire and a
# legitimately empty optional are the same `null`, and always will be — there
# is nothing to tell them apart. Workstation.owner is deliberately null on
# common land (unowned land is the king's, which is the same answer as
# nobody's) and would false-positive forever. Reading the text instead means
# the rule is exact, and it sees scenes nothing has loaded.
#
# Static, because it holds nothing. It lives beside probe.gd rather than inside
# it because it is about .tscn files in general, not about any one rung, and
# every rung from here on adds scenes for it to read.

# The node_paths=PackedStringArray("a", "b") clause; group 1 is the raw body.
const NODE_PATHS_CLAUSE_PATTERN := "node_paths\\s*=\\s*PackedStringArray\\(([^)]*)\\)"
const QUOTED_NAME_PATTERN := "\"([^\"]*)\""
const NODE_NAME_ATTRIBUTE_PATTERN := "\\bname\\s*=\\s*\"([^\"]*)\""
const NODE_PARENT_ATTRIBUTE_PATTERN := "\\bparent\\s*=\\s*\"([^\"]*)\""
# An identifier then "=", anchored at line start — Godot allows subproperty
# paths like "material/0". Anchoring is what keeps a continuation line of a
# multi-line value from being misread as a new property.
const PROPERTY_ASSIGNMENT_PATTERN := "^\\s*([A-Za-z_][A-Za-z0-9_/]*)\\s*=\\s*(.*)$"
const SECTION_HEADER_PATTERN := "^\\s*\\["
const NODE_SECTION_HEADER_PATTERN := "^\\s*\\[node\\b"


# Every .tscn under root_dir, walked by hand rather than read off any project
# index, so this works on a stripped checkout too. Skips generated directories
# and anything called "addons" — third-party scenes are not ours to lint.
static func find_scene_files(root_dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	_gather_scene_files(root_dir, found)
	return found


static func _gather_scene_files(dir_path: String, found: PackedStringArray) -> void:
	var directory := DirAccess.open(dir_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry_name := directory.get_next()
	while entry_name != "":
		if entry_name != "." and entry_name != "..":
			var entry_path := dir_path.path_join(entry_name)
			if directory.current_is_dir():
				if entry_name != ".godot" and entry_name != ".import" and entry_name != "addons":
					_gather_scene_files(entry_path, found)
			elif entry_name.ends_with(".tscn"):
				found.append(entry_path)
		entry_name = directory.get_next()
	directory.list_dir_end()


# One plain-English message per violation, empty if every file is clean.
static func find_node_path_violations(scene_paths: PackedStringArray) -> Array[String]:
	var violations: Array[String] = []
	for scene_path: String in scene_paths:
		var file_text := FileAccess.get_file_as_string(scene_path)
		var open_error := FileAccess.get_open_error()
		if open_error != OK:
			violations.append("%s: could not be opened (error %d)" % [scene_path, open_error])
			continue
		_collect_violations_in_file(scene_path, file_text, violations)
	return violations


# Walks one file line by line, accumulating a node block and judging it once
# the block closes. Blocks and assignments are plain Dictionaries; an empty one
# stands in for "nothing open".
#
# Most of the care here is the multi-line value case: a property's value can
# run across several lines (a long array is the common one), and a line belongs
# to the previous property only if it neither looks like a new assignment nor
# opens a section. Get that test wrong and either a continuation line becomes a
# bogus property, or a real value gets cut off before the part that decides
# everything — Array[NodePath] vs NodePath — even appears.
static func _collect_violations_in_file(scene_path: String, file_text: String, violations: Array[String]) -> void:
	var node_paths_regex := RegEx.create_from_string(NODE_PATHS_CLAUSE_PATTERN)
	var quoted_name_regex := RegEx.create_from_string(QUOTED_NAME_PATTERN)
	var node_name_regex := RegEx.create_from_string(NODE_NAME_ATTRIBUTE_PATTERN)
	var node_parent_regex := RegEx.create_from_string(NODE_PARENT_ATTRIBUTE_PATTERN)
	var property_regex := RegEx.create_from_string(PROPERTY_ASSIGNMENT_PATTERN)
	var section_header_regex := RegEx.create_from_string(SECTION_HEADER_PATTERN)
	var node_section_header_regex := RegEx.create_from_string(NODE_SECTION_HEADER_PATTERN)

	var current_block := {}
	var pending := {}

	for line: String in file_text.split("\n"):
		if line.strip_edges().begins_with(";"):
			continue

		var is_section_header := section_header_regex.search(line) != null
		var property_match: RegExMatch = null if is_section_header else property_regex.search(line)

		if is_section_header or property_match != null:
			# Whatever value was being accumulated is now complete.
			if not current_block.is_empty() and not pending.is_empty():
				var open_assignments: Array[Dictionary] = current_block["assignments"]
				open_assignments.append(pending)
			pending = {}

		if is_section_header:
			if not current_block.is_empty():
				_check_one_node_block(scene_path, current_block, violations)
			current_block = {}
			# Only [node …] opens a block. [gd_scene …], [ext_resource …],
			# [sub_resource …], [connection …] and [editable …] all close one
			# without opening another, so their properties are never
			# attributed to a node.
			if node_section_header_regex.search(line) != null:
				current_block = _build_node_block(
					line, node_name_regex, node_parent_regex, node_paths_regex, quoted_name_regex)
			continue

		if property_match != null:
			pending = {"name": property_match.get_string(1), "value": property_match.get_string(2)}
			continue

		if not pending.is_empty():
			var value_so_far: String = pending["value"]
			pending["value"] = value_so_far + "\n" + line

	if not current_block.is_empty() and not pending.is_empty():
		var trailing_assignments: Array[Dictionary] = current_block["assignments"]
		trailing_assignments.append(pending)
	if not current_block.is_empty():
		_check_one_node_block(scene_path, current_block, violations)


# A node block from its header line: a label good enough to find it by, and
# whatever it declares in node_paths.
static func _build_node_block(
	header_line: String,
	node_name_regex: RegEx,
	node_parent_regex: RegEx,
	node_paths_regex: RegEx,
	quoted_name_regex: RegEx
) -> Dictionary:
	var name_match := node_name_regex.search(header_line)
	var node_name: String = name_match.get_string(1) if name_match != null else "(unnamed)"
	var parent_match := node_parent_regex.search(header_line)
	var label: String = "node \"%s\"" % node_name
	if parent_match != null:
		label = "node \"%s\" (parent \"%s\")" % [node_name, parent_match.get_string(1)]

	var declared_names: Array[String] = []
	var paths_match := node_paths_regex.search(header_line)
	if paths_match != null:
		for quoted: RegExMatch in quoted_name_regex.search_all(paths_match.get_string(1)):
			declared_names.append(quoted.get_string(1))

	var empty_assignments: Array[Dictionary] = []
	return {"label": label, "declared": declared_names, "assignments": empty_assignments}


# Three rules, each checked independently so one node can report more than one
# problem: a bare NodePath must be declared, an Array[NodePath] must not be,
# and every declared name must actually be assigned something.
static func _check_one_node_block(scene_path: String, block: Dictionary, violations: Array[String]) -> void:
	var label: String = block["label"]
	var declared_names: Array[String] = block["declared"]
	var assignments: Array[Dictionary] = block["assignments"]

	var assigned_names: Array[String] = []
	for assignment: Dictionary in assignments:
		var assigned_name: String = assignment["name"]
		assigned_names.append(assigned_name)

	for assignment: Dictionary in assignments:
		var property_name: String = assignment["name"]
		var value_text: String = assignment["value"]
		var trimmed: String = value_text.strip_edges()
		var is_array_form := trimmed.begins_with("Array[NodePath]")
		var is_bare_form := not is_array_form and trimmed.contains("NodePath(")
		if not is_array_form and not is_bare_form:
			continue
		var is_declared := declared_names.has(property_name)
		if is_bare_form and not is_declared:
			violations.append("%s: %s, \"%s\" is a bare NodePath but is not in node_paths — it loads as null" % [
				scene_path, label, property_name])
		elif is_array_form and is_declared:
			violations.append("%s: %s, \"%s\" is an Array[NodePath] but is in node_paths — those are resolved by hand, not by the loader" % [
				scene_path, label, property_name])

	for declared_name: String in declared_names:
		if not assigned_names.has(declared_name):
			violations.append("%s: %s, \"%s\" is in node_paths but nothing assigns it — a renamed or removed property" % [
				scene_path, label, declared_name])
