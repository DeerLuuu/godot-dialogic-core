# INFO 对话核心脚本编辑器
@tool
class_name DialogicCoreCodeEditor extends PanelContainer

# TODO 对话核心代码编辑器 ===============>信 号<===============
#region 信号

#endregion

# TODO 对话核心代码编辑器 ===============>常 量<===============
#region 常量
# ENUM 代码错误枚举
enum CodeError{
	OK,
	MISSING_END_SYMBOL,
	SPELLING_ERROR,
	EXPRESSION_ERROR,
	PARAMETER_ERROR,
	ENCODING_ERROR
}
# ENUM 关键字类型枚举
enum CodeKeyType{
	TEXT,
	END = -999,
	CONTINUE = -888
}
const CREATE_SCRIPT_PANEL_CONTAINER = preload("res://addons/dialogic_core/ui/create_script_panel_container.tscn")
#endregion

# TODO 对话核心代码编辑器 ===============>变 量<===============
#region 变量
var editor : EditorPlugin
# VAR 创建代码按钮
var create_script_button: Button
# VAR 侧边栏容器
var slider: VBoxContainer
# VAR 字体大小菜单按钮
var font_size_menu_button: MenuButton
# VAR 代码搜索编辑器
var code_search_edit: LineEdit
# VAR 代码搜索到的结果的行数
var search_code_row : Array[Vector2i]
# VAR 鼠标行列显示容器
var cursor_pos_label: Label
# VAR 显示或隐藏侧边栏按钮
var show_or_hide_slider_button: Button
# VAR 代码编辑器
var code_edit: CodeEdit
# VAR 高亮解析器
var highlighter : CodeHighlighter
# VAR 代码分行的数组
var code_rows : Array
# VAR 脚本成员关键字
var code_member_completions : Array = ["_para", "_role", "_global", "_local", "_signal"]
# VAR 脚本逻辑关键字
var code_standard_completions : Array = ["condition", "else", "elif", "goto", "continue", "end", "time", "event", "choice", "set"]
# VAR 脚本其它关键字
var code_other_completions : Array = ["emote", "voice", "text"]
# VAR 报错文字容器
var err_label: Label
var file_item_list: ItemList

var scripts : Array
var script_dic : Dictionary

var current_edit_ddc_path : String

#endregion

# TODO 对话核心代码编辑器 ===============>虚方法<===============
#region 常用的虚方法
func _ready() -> void:
	create_script_button = %CreateScriptButton
	slider = %Slider
	font_size_menu_button = %FontSizeMenuButton
	code_search_edit = %CodeSearchEdit
	err_label = %ErrLabel
	cursor_pos_label = %CursorPosLabel
	show_or_hide_slider_button = %ShowOrHideSliderButton
	file_item_list = %FileItemList

	highlighter = highlighter_create()
	code_member_completions.sort()
	code_standard_completions.sort()
	code_other_completions.sort()
	code_edit = %CodeEdit
	code_edit.code_completion_prefixes = PackedStringArray(
		[
			"_", "a", "b",
			"c", "d", "e",
			"f", "g", "h",
			"i", "j", "k",
			"l", "n", "m",
			"o", "p", "q",
			"r", "s", "t",
			"u", "v", "w",
			"x", "y", "z"
		]
	)
	code_edit.syntax_highlighter = highlighter
	code_edit.add_theme_font_override("font", load("res://JetBrainsMono-ExtraBoldItalic.ttf"))
	code_edit.add_theme_font_size_override("font_size", 15)

	read_ddc_file()

	# NOTE 信号链接初始化
	font_size_menu_button.get_popup().id_pressed.connect(_on_font_size_menu_button_popup_id_pressed)
	code_search_edit.text_submitted.connect(_on_code_search_edit_text_submitted)
	show_or_hide_slider_button.pressed.connect(_on_show_or_hide_slider_button_pressed)
	file_item_list.item_selected.connect(_on_file_item_list_item_selected)
	create_script_button.pressed.connect(_on_create_script_button_pressed)

	code_edit.code_completion_requested.connect(_on_code_edit_code_completion_requested)
	code_edit.text_changed.connect(_on_code_edit_text_changed)
	code_edit.caret_changed.connect(_on_code_edit_caret_changed)
#endregion

# TODO 对话核心代码编辑器 ===============>信号链接方法<===============
#region 信号链接方法
# FUNC 创建脚本按钮的方法
func _on_create_script_button_pressed() -> void:
	var create_script_panel_container = CREATE_SCRIPT_PANEL_CONTAINER.instantiate()
	create_script_panel_container.editor = editor
	var window : Window = Window.new()
	window.transient = true
	window.transparent = true
	window.add_child(create_script_panel_container)
	add_child(window)
	create_script_panel_container.close.connect(func(): window.queue_free())
	window.close_requested.connect(func(): window.queue_free())
	window.popup_centered(create_script_panel_container.size)

# FUNC 保存ddc文件
func _on_scene_saved(filepath: String) -> void:
	if current_edit_ddc_path != "":
		var file = FileAccess.open(current_edit_ddc_path, FileAccess.WRITE)
		file.store_string(code_edit.text)
	read_ddc_file()

# FUNC 文件列表中的文件被点击时的方法
func _on_file_item_list_item_selected(index: int) -> void:
	var file_path : String = script_dic[file_item_list.get_item_text(index)]
	current_edit_ddc_path = file_path
	var file = FileAccess.open(file_path, FileAccess.READ)
	code_edit.text = file.get_as_text()
	code_edit.show()

# FUNC 显示或隐藏侧边栏按钮激活方法
func _on_show_or_hide_slider_button_pressed() -> void:
	if show_or_hide_slider_button.text == "<":
		slider.hide()
		show_or_hide_slider_button.text = ">"
	elif show_or_hide_slider_button.text == ">":
		slider.show()
		show_or_hide_slider_button.text = "<"

# FUNC 修改代码字体大小
func _on_font_size_menu_button_popup_id_pressed(id: int) -> void:
	match id:
		0:
			font_size_menu_button.text = "50 %"
			code_edit.add_theme_font_size_override("font_size", 7)
		1:
			font_size_menu_button.text = "75 %"
			code_edit.add_theme_font_size_override("font_size", 11)
		2:
			font_size_menu_button.text = "100 %"
			code_edit.add_theme_font_size_override("font_size", 15)
		3:
			font_size_menu_button.text = "125 %"
			code_edit.add_theme_font_size_override("font_size", 19)
		4:
			font_size_menu_button.text = "150 %"
			code_edit.add_theme_font_size_override("font_size", 22)

# FUNC 光标改变位子的方法
func _on_code_edit_caret_changed() -> void:
	cursor_pos_label.text = "%s : %s" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1]

# FUNC 代码编辑器中文本改变时触发的方法
func _on_code_edit_text_changed() -> void:
	var not_err : bool = true

	code_rows = code_edit.text.split("\n")
	code_edit.request_code_completion()

	for i in code_rows.size():
		code_edit.set_line_background_color(i, Color("252525"))

	code_err_clear()
	not_err = code_err_parser(code_end_or_spell_error_detection)
	not_err = code_err_parser(code_value_error_detection)


# FUNC 代码编辑器中触发自动补全时的方法
func _on_code_edit_code_completion_requested() -> void:
	if code_rows.size() == 0: return
	if code_edit.text == "": return
	var key : String = code_rows[code_edit.get_caret_line()][-1]
	if key in code_edit.code_completion_prefixes:
		for i in code_member_completions:
			if i in ["_global", "_local", "_signal"]:
				code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, i, i + " []")
				continue
			code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, i, i + " ")
		for i in code_standard_completions:
			if i in ["event", "set"]:
				code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, i, i + " []")
				continue
			code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, i, i + " ")
		for i in code_other_completions:
			code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, i, i + " ")
	code_edit.update_code_completion_options(false)

# FUNC 代码搜索提交方法
# FIXME 还有点不是很好用，后面修复
func _on_code_search_edit_text_submitted(new_text: String) -> void:
	var search_pos : Vector2 = code_edit.search(new_text, CodeEdit.SEARCH_WHOLE_WORDS, code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1)
	code_edit.set_caret_line(search_pos.y)
	code_edit.set_caret_column(search_pos.x)
	code_edit.select_word_under_caret()
#endregion

# TODO 对话核心代码编辑器 ===============>工具方法<===============
#region 工具方法
# FUNC 读取项目中的ddc文件
func read_ddc_file() -> void:
	scripts = get_scripte_list("res://")
	file_item_list.clear()
	for i : String in scripts:
		var file_name_parts : Array = i.split("/")
		var file_name : String = file_name_parts[-1]
		script_dic[file_name] = i
		file_item_list.add_item(file_name)

# TODO 插件脚本列表的方法
func get_scripte_list(root_path : String) -> Array:
	var scripts := []
	var dir = DirAccess.open(root_path)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var full_path = root_path.path_join(file_name)

			if dir.current_is_dir():
				# 递归处理子目录
				scripts.append_array(get_scripte_list(full_path))
			else:
				if file_name.get_extension() == "ddc":
					scripts.append(full_path)

			file_name = dir.get_next()
	return scripts

# FUNC 代码错误解析器
func code_err_parser(err_func : Callable) -> bool:
	for i in code_rows.size():
		var error : CodeError = err_func.call(code_rows[i])
		if error == CodeError.OK: continue
		code_edit.set_line_background_color(i, Color("663e3a"))
		return false
	return true

func get_full_value_in_code_part(code_parts : Array, key : String, end_code : String = "", interval_code : String = "") -> String:
	var code_part : String
	for i : String in code_parts:
		if i == "": continue
		if i == "\t": continue
		if i == key: continue
		code_part += i + interval_code
		if end_code != "":
			if i == end_code: break
			if i.ends_with(end_code): break
	return code_part

# FUNC 代码结尾、拼写错误检测器
func code_end_or_spell_error_detection(code_row : String) -> CodeError:
	if code_row.dedent() == "": return CodeError.OK

	code_row = code_row.strip_edges(false, true)

	var code_row_num : int = code_rows.find(code_row) + 1
	var code_parts : Array = code_row.split(" ")
	var tab_num : int = 0
	var has_tab_part : String = code_parts[0]
	var not_end_keys : Array = ["continue", "end", "goto", "time", "event", "emote", "voice", "_global", "_local", "_signal", "text", "set", "choice", "condition"]
	var has_end_keys : Array = ["_para", "_role"]

	tab_num = code_parts[0].count("\t")
	code_parts[0] = has_tab_part.split("\t")[-1]

	for i in has_end_keys:
		if code_parts.has(i + ":"):
			code_printerr("你可能缺失了参数，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
			return CodeError.PARAMETER_ERROR
		if code_parts.has(i):
			if code_parts.has("："):
				code_printerr("你可能错误的使用了中文的符号，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
				return CodeError.ENCODING_ERROR
			if code_parts.has(":"):
				if code_parts[code_parts.find(i) + 1] == ":":
					code_printerr("你可能缺失了参数，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
					return CodeError.PARAMETER_ERROR
				return CodeError.OK
			if code_parts[-1] != "":
				if code_parts[-1][-1] == ":": return CodeError.OK
				if code_parts[-1][-1] == "：":
					code_printerr("你可能错误的使用了中文的符号，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
					return CodeError.ENCODING_ERROR
			code_printerr("可能是缺失结尾符号，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
			return CodeError.MISSING_END_SYMBOL

	for i in not_end_keys:
		if code_parts.has(i): return CodeError.OK

	code_printerr("可能是拼写错误，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
	return CodeError.SPELLING_ERROR

# FUNC 代码值错误检查器
func code_value_error_detection(code_row : String) -> CodeError:
	if code_row.dedent() == "": return CodeError.OK

	var code_row_num : int = code_rows.find(code_row) + 1
	var code_parts : Array = code_row.split(" ")
	var tab_num : int = 0
	var has_tab_part : String = code_parts[0]

	var float_value_keys : Array = ["time"]
	var string_value_keys : Array = ["goto", "emote", "text", "_para", "_role", "voice", "choice"]
	var dictionary_value_keys : Array = ["event", "_global", "_local", "_signal", "set"]
	var condition_value_keys : Array = ["condition"]

	tab_num = code_parts[0].count("\t")
	code_parts[0] = has_tab_part.split("\t", false)[-1]

	# NOTE 浮点数关键字错误检测
	for i in float_value_keys:
		if code_parts.has(i):
			var code_part_index : int = code_parts.find(i) + 1
			if code_parts.size() == 1:
				code_printerr("你可能缺失了参数，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
				return CodeError.PARAMETER_ERROR

			var code_part : String = code_parts[code_part_index]
			if code_part == "":
				code_printerr("你可能缺失了参数，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
				return CodeError.PARAMETER_ERROR
			if not code_part.is_valid_float():
				code_printerr("你可能使用了错误的参数，正确参数应为浮点值，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
				return CodeError.PARAMETER_ERROR

	# NOTE 字符串关键字错误检测
	for i in string_value_keys:
		if code_parts.has(i):
			var code_part_index : int = code_parts.find(i) + 1
			if code_parts.size() == 1:
				code_printerr("你可能缺失了参数，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
				return CodeError.PARAMETER_ERROR

			var code_part : String = code_parts[code_part_index]
			if code_part == "":
				code_printerr("你可能缺失了参数，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
				return CodeError.PARAMETER_ERROR

			if i == "voice":
				if not code_part.is_absolute_path():
					code_printerr("你可能使用了错误的参数，正确参数应为文件路径，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
					return CodeError.PARAMETER_ERROR

	# NOTE 字典关键字错误检测
	for i in dictionary_value_keys:
		if code_parts.has(i):
			var code_part_index : int = code_parts.find(i) + 1
			if code_parts.size() == 1:
				code_printerr("你可能缺失了参数，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
				return CodeError.PARAMETER_ERROR

			var code_part : String

			code_part = get_full_value_in_code_part(code_parts, i, "]")

			if code_part == "":
				code_printerr("你可能缺失了参数，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
				return CodeError.PARAMETER_ERROR
			if not is_valid_format(code_part):
				code_printerr("你可能使用了错误的参数，正确示例[字符串, 参数1, 参数2, 参数...]，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
				return CodeError.PARAMETER_ERROR

	# NOTE 条件关键字错误检测
	for i in condition_value_keys:
		if code_parts.has(i):
			var code_part_index : int = code_parts.find(i) + 1
			if code_parts.size() == 1:
				code_printerr("你可能缺失了参数，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
				return CodeError.PARAMETER_ERROR

			var code_part : String

			code_part = get_full_value_in_code_part(code_parts, i, "", " ")

			if code_part.contains(":"):
				code_part = code_part.left(code_part.length() - 2)

			if code_part == "":
				code_printerr("你可能缺失了参数，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
				return CodeError.PARAMETER_ERROR

			if not is_logic_expression(code_part):
				code_printerr("请输入正确的条件格式，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
				return CodeError.EXPRESSION_ERROR

	for i in ["emote", "voice", "time", "event", "choice", "end", "continue", "condition"]:
		if code_parts.has(i):
			if tab_num < 3:
				code_printerr("一些关键字的位置不正确，正确位置应该为三个以上的制表符后，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
				return CodeError.PARAMETER_ERROR

	if code_parts.has("_para"):
		if tab_num != 0:
			code_printerr("一些关键字的位置不正确，正确位置应该为无制表符在前，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
			return CodeError.PARAMETER_ERROR

	if code_parts.has("_role"):
		if tab_num != 1:
			code_printerr("一些关键字的位置不正确，正确位置应该为一个制表符后，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
			return CodeError.PARAMETER_ERROR

	if code_parts.has("text"):
		if tab_num != 2:
			code_printerr("一些关键字的位置不正确，正确位置应该为两个制表符后，请检查代码第%s行%s列" % [code_edit.get_caret_line() + 1, code_edit.get_caret_column() + 1])
			return CodeError.PARAMETER_ERROR

	return CodeError.OK

# FUNC 创建脚本高亮解析器
func highlighter_create() -> CodeHighlighter:
	var _highlighter : CodeHighlighter = CodeHighlighter.new()
	_highlighter.clear_color_regions()
	_highlighter.symbol_color = Color.ALICE_BLUE
	_highlighter.number_color = Color.AQUAMARINE
	_highlighter.member_variable_color = Color.ALICE_BLUE
	_highlighter.add_color_region("[", "]", Color.SPRING_GREEN)
	_highlighter.add_color_region("\'", "\'", Color.ALICE_BLUE)
	_highlighter.add_color_region("\"", "\"", Color("ffeda1"))
	for i in code_member_completions:
		_highlighter.add_keyword_color(i, Color("57b3ff"))
	for i in code_standard_completions:
		_highlighter.add_keyword_color(i, Color("ff8ccc"))
	for i in code_other_completions:
		_highlighter.add_keyword_color(i, Color("abc9ff"))
	return _highlighter

# FUNC 代码错误信息显示
func code_printerr(err_str : String) -> void:
	err_label.text = err_str

# FUNC 代码报错信息清除
func code_err_clear() -> void:
	err_label.text = ""

# FUNC 条件格式判断方法
func is_logic_expression(s: String) -> bool:
	const pattern = "^\\s*((not\\s+)?(((?:[a-zA-Z_]\\w*|[-+]?\\d+(?:\\.\\d+)?|[\"'].+?[\"'])(?:\\s*[+\\-*/]\\s*(?:[a-zA-Z_]\\w*|[-+]?\\d+(?:\\.\\d+)?|[\"'].+?[\"']))*|\\(.+?\\))\\s*(==|!=|>|<|>=|<=)\\s*((?:[a-zA-Z_]\\w*|[-+]?\\d+(?:\\.\\d+)?|[\"'].+?[\"'])(?:\\s*[+\\-*/]\\s*(?:[a-zA-Z_]\\w*|[-+]?\\d+(?:\\.\\d+)?|[\"'].+?[\"']))*|\\(.+?\\)))(\\s+(and|or)\\s+(not\\s+)?(((?:[a-zA-Z_]\\w*|[-+]?\\d+(?:\\.\\d+)?|[\"'].+?[\"'])(?:\\s*[+\\-*/]\\s*(?:[a-zA-Z_]\\w*|[-+]?\\d+(?:\\.\\d+)?|[\"'].+?[\"']))*|\\(.+?\\))\\s*(==|!=|>|<|>=|<=)\\s*.+?))*)\\s*$"
	var reg_ex : RegEx = RegEx.new()
	reg_ex.compile(pattern)
	return reg_ex.search(s) != null

# FUNC 数据规范判断方法
func is_valid_format(s : String) -> bool:
	const pattern = "^\\[\\s*(\"?[\\p{Han}a-zA-Z0-9_.+*\\/-]+\"?|\\d+|\'.+?\')(\\s*,\\s*(\"?[\\p{Han}a-zA-Z0-9_.+*\\/-]+\"?|\\d+|\\'.+?\'))*\\s*\\]$"
	var regex = RegEx.new()
	regex.compile(pattern)
	return regex.search(s.strip_edges()) != null
#endregion
