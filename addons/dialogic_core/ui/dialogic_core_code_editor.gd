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

#endregion

# TODO 对话核心代码编辑器 ===============>变 量<===============
#region 变量
# VAR 代码编辑器
var code_edit: CodeEdit
# VAR 高亮解析器
var highlighter : CodeHighlighter
# VAR 代码分行的数组
var code_rows : Array
# VAR 脚本成员关键字
var code_member_completions : Array = ["_para", "_role", "_global", "_local", "_signal"]
# VAR 脚本逻辑关键字
var code_standard_completions : Array = ["if", "else", "elif", "goto", "continue", "end", "time", "event", "choice"]
# VAR 脚本其它关键字
var code_other_completions : Array = ["emote", "voice", "text"]
# VAR 报错文字容器
var err_label: Label
#endregion

# TODO 对话核心代码编辑器 ===============>虚方法<===============
#region 常用的虚方法
func _ready() -> void:
	err_label = %ErrLabel
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
	code_edit.add_theme_font_size_override("font_size", 20)

	# NOTE 信号链接初始化
	code_edit.code_completion_requested.connect(_on_code_edit_code_completion_requested)
	code_edit.text_changed.connect(_on_code_edit_text_changed)
#endregion

# TODO 对话核心代码编辑器 ===============>信号链接方法<===============
#region 信号链接方法
# FUNC 代码编辑器中文本改变时触发的方法
func _on_code_edit_text_changed() -> void:
	code_rows = code_edit.text.split("\n")
	code_edit.request_code_completion()
	code_err_clear()

	for i in code_rows.size():
		code_edit.set_line_background_color(i, Color("252525"))

	for i in code_rows.size():
		var error : CodeError = code_end_or_spell_error_detection(code_rows[i])
		if error == CodeError.OK: continue
		code_edit.set_line_background_color(i, Color("663e3a"))

	for i in code_rows.size():
		var error : CodeError = code_value_error_detection(code_rows[i])
		if error == CodeError.OK: continue
		code_edit.set_line_background_color(i, Color("663e3a"))

# FUNC 代码编辑器中触发自动补全时的方法
func _on_code_edit_code_completion_requested() -> void:
	if code_rows.size() == 0: return
	if code_edit.text == "": return
	var key : String = code_rows[code_edit.get_caret_line()][-1]
	if key in code_edit.code_completion_prefixes:
		for i in code_member_completions:
			if i in ["global", "local", "signal"]:
				code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, i, i + "() ")
			else :
				code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, i, i + " ")
		for i in code_standard_completions:
			if i == "if" or i == "elif":
				code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, i, i + "() ")
			code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, i, i + " ")
		for i in code_other_completions:
			code_edit.add_code_completion_option(CodeEdit.KIND_MEMBER, i, i + " ")
	code_edit.update_code_completion_options(false)
#endregion

# TODO 对话核心代码编辑器 ===============>工具方法<===============
#region 工具方法
# FUNC 代码结尾、拼写错误检测器
func code_end_or_spell_error_detection(code_row : String) -> CodeError:
	if code_row.dedent() == "": return CodeError.OK

	var code_row_num : int = code_rows.find(code_row) + 1
	var code_parts : Array = code_row.split(" ")
	var tab_num : int = 0
	var has_tab_part : String = code_parts[0]
	var not_end_keys : Array = ["continue", "end", "goto", "time", "event", "emote", "voice", "_global", "_local", "_signal", "text"]
	var has_end_keys : Array = ["if", "else", "elif", "choice", "_para", "_role"]

	tab_num = code_parts[0].count("\t")
	code_parts[0] = has_tab_part.split("\t")[-1]

	for i in has_end_keys:
		if code_parts.has(i + ":"): return CodeError.OK
		if code_parts.has(i):
			if code_parts.has("："):
				code_printerr("你可能错误的使用了中文的符号，请检查代码第%s行" % code_row_num)
				return CodeError.ENCODING_ERROR
			if code_parts.has(":"): return CodeError.OK
			if code_parts[-1] != "":
				if code_parts[-1][-1] == ":": return CodeError.OK
				if code_parts[-1][-1] == "：":
					code_printerr("你可能错误的使用了中文的符号，请检查代码第%s行" % code_row_num)
					return CodeError.ENCODING_ERROR
			code_printerr("可能是缺失结尾符号，请检查代码第%s行" % code_row_num)
			return CodeError.MISSING_END_SYMBOL

	for i in not_end_keys:
		if code_parts.has(i): return CodeError.OK

	code_printerr("可能是拼写错误，请检查代码第%s行" % code_row_num)
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
	var dictionary_value_keys : Array = ["event", "_global", "_local", "_signal"]
	var condition_value_keys : Array = ["if", "elif"]

	tab_num = code_parts[0].count("\t")
	code_parts[0] = has_tab_part.split("\t", false)[-1]

	# NOTE 浮点数关键字错误检测
	for i in float_value_keys:
		if code_parts.has(i):
			var code_part_index : int = code_parts.find(i) + 1
			if code_parts.size() == 1:
				code_printerr("你可能在一个需要参数的关键字后面缺失了参数，请检查代码第%s行" % code_row_num)
				return CodeError.PARAMETER_ERROR

			var code_part : String = code_parts[code_part_index]
			if code_part == "":
				code_printerr("你可能在一个需要参数的关键字后面缺失了参数，请检查代码第%s行" % code_row_num)
				return CodeError.PARAMETER_ERROR
			if not code_part.is_valid_float():
				code_printerr("你可能在一个需要参数的关键字后面使用了错误的参数，请检查代码第%s行" % code_row_num)
				return CodeError.PARAMETER_ERROR

	# NOTE 字符串关键字错误检测
	for i in string_value_keys:
		if code_parts.has(i):
			var code_part_index : int = code_parts.find(i) + 1
			if code_parts.size() == 1:
				code_printerr("你可能在一个需要参数的关键字后面缺失了参数，请检查代码第%s行" % code_row_num)
				return CodeError.PARAMETER_ERROR

			var code_part : String = code_parts[code_part_index]
			if code_part == "":
				code_printerr("你可能在一个需要参数的关键字后面缺失了参数，请检查代码第%s行" % code_row_num)
				return CodeError.PARAMETER_ERROR

			if i == "voice":
				if not code_part.is_absolute_path():
					code_printerr("你可能在一个需要参数的关键字后面使用了错误的参数，请检查代码第%s行" % code_row_num)
					return CodeError.PARAMETER_ERROR

	# NOTE 字典关键字错误检测
	for i in dictionary_value_keys:
		if code_parts.has(i):
			var code_part_index : int = code_parts.find(i) + 1
			if code_parts.size() == 1:
				code_printerr("你可能在一个需要参数的关键字后面缺失了参数，请检查代码第%s行" % code_row_num)
				return CodeError.PARAMETER_ERROR

			var code_part : String

			for key : String in code_parts:
				if key == "": continue
				if key == "\t": continue
				if key == i: continue
				code_part += key
				if key.ends_with("]"): break

			if code_part == "":
				code_printerr("你可能在一个需要参数的关键字后面缺失了参数，请检查代码第%s行" % code_row_num)
				return CodeError.PARAMETER_ERROR
			if not is_valid_format(code_part):
				code_printerr("你可能在一个需要参数的关键字后面使用了错误的参数，请检查代码第%s行" % code_row_num)
				return CodeError.PARAMETER_ERROR

	# NOTE 条件关键字错误检测
	for i in condition_value_keys:
		if code_parts.has(i):
			var code_part_index : int = code_parts.find(i) + 1
			if code_parts.size() == 1:
				code_printerr("你可能在一个需要参数的关键字后面缺失了参数，请检查代码第%s行" % code_row_num)
				return CodeError.PARAMETER_ERROR

			var code_part : String

			for key : String in code_parts:
				if key == "": continue
				if key == "\t": continue
				if key == i: continue
				if key == ":": continue
				code_part += key + " "

			if code_part.contains(":"):
				code_part = code_part.left(code_part.length() - 2)

			if code_part == "":
				code_printerr("你可能在一个需要参数的关键字后面缺失了参数，请检查代码第%s行" % code_row_num)
				return CodeError.PARAMETER_ERROR

			if not is_logic_expression(code_part):
				code_printerr("请输入正确的条件格式，请检查代码第%s行" % code_row_num)
				return CodeError.EXPRESSION_ERROR

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
	const pattern = "^\\s*([a-zA-Z_][\\w]*|\\d+)\\s*(==|!=|>|<|>=|<=|&&|\\|\\|| and | or )\\s*([a-zA-Z_][\\w]*|\\d+|\\s*((\\d+)|(['\"]).+?\\5))\\s*$"

	var clauses : Array
	if s.contains("and"):
		clauses = s.split("and", false)
	elif s.contains("or"):
		clauses = s.split("or", false)
	else :
		clauses = [s]

	for clause : String in clauses:
		var reg_ex : RegEx = RegEx.new()
		reg_ex.compile(pattern)
		if !reg_ex.search(clause.strip_edges()):
			return false

	return clauses.size()  > 0

# FUNC 数据规范判断方法
func is_valid_format(s : String) -> bool:
	const pattern = "^\\[\\s*(\"?[\\p{Han}a-zA-Z0-9_.-]+\"?|\\d+|\'.+?\')(\\s*,\\s*(\"?[\\p{Han}a-zA-Z0-9_.-]+\"?|\\d+))*\\s*\\]$"
	var regex = RegEx.new()
	# 编译正则表达式（忽略空白和注释）
	regex.compile(pattern.strip_edges())
	return regex.search(s)  != null
#endregion
