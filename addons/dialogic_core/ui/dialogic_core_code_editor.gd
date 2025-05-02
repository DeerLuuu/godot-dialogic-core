# INFO 对话核心脚本编辑器
@tool
class_name DialogicCoreCodeEditor extends PanelContainer

# TODO 对话核心代码编辑器 ===============>信 号<===============
#region 信号

#endregion

# TODO 对话核心代码编辑器 ===============>常 量<===============
#region 常量
enum CodeError{
	OK,
	MISSING_END_SYMBOL,
	SPELLING_ERROR
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
		var error : CodeError = code_error_detection(code_rows[i])
		code_edit.set_line_background_color(i, Color("252525"))
		if error == CodeError.OK: continue
		code_edit.set_line_background_color(i, Color("663e3a"))

# FUNC 代码编辑器中触发自动补全时的方法
func _on_code_edit_code_completion_requested() -> void:
	if code_rows.size() == 0: return
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
# FUNC 代码错误检测器
# FIXME 一个烂摊子，后面需要重写这个部分
func code_error_detection(code_row : String) -> CodeError:
	if code_row == "": return CodeError.OK
	if code_row.dedent() == "": return CodeError.OK
	var code_row_num : int = code_rows.find(code_row) + 1
	var code_parts : Array = code_row.split(" ")
	var tab_num : int = 0
	tab_num = code_parts[0].count("\t")
	var has_tab_part : String = code_parts[0]
	code_parts[0] = has_tab_part.split("\t")[-1]

	for i in ["_para", "_role", "if", "else", "elif", "text", "choice"]:
		if code_parts.has(i + ":"): return CodeError.OK
		if code_parts.has(i):
			if code_parts.has("："):
				code_printerr("你可能错误的使用了中文的符号，请检查代码第%s行" % code_row_num)
				return CodeError.SPELLING_ERROR
			if code_parts.has(":"): return CodeError.OK
			if code_parts[-1] != "":
				if code_parts[-1][-1] == ":": return CodeError.OK
				if code_parts[-1][-1] == "：":
					code_printerr("你可能错误的使用了中文的符号，请检查代码第%s行" % code_row_num)
					return CodeError.SPELLING_ERROR
			code_printerr("可能是缺失结尾符号，请检查代码第%s行" % code_row_num)
			return CodeError.MISSING_END_SYMBOL

	for i in ["_global", "_local", "_signal"]:
		if code_parts.has(i): return CodeError.OK

	for i in ["goto", "continue", "end", "time", "event"]:
		if code_parts.has(i): return CodeError.OK

	for i in code_other_completions:
		if code_parts.has(i): return CodeError.OK

	code_printerr("可能是拼写错误，请检查代码第%s行" % code_row_num)
	return CodeError.SPELLING_ERROR


# FUNC 创建脚本高亮解析器
func highlighter_create() -> CodeHighlighter:
	var _highlighter : CodeHighlighter = CodeHighlighter.new()
	_highlighter.clear_color_regions()
	_highlighter.symbol_color = Color.ALICE_BLUE
	_highlighter.number_color = Color.AQUAMARINE
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

func code_printerr(err_str : String) -> void:
	err_label.text = err_str

func code_err_clear() -> void:
	err_label.text = ""
#endregion
