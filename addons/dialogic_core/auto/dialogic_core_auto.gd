extends Node

# TODO 对话核心自动加载 ===============>信 号<===============
#region 信号
signal next_text(_text : String)
signal previous_text(_text : String)
#endregion

# TODO 对话核心自动加载 ===============>常 量<===============
#region 常量
# ENUM 关键字类型枚举
enum CodeKeyType{
	TEXT,
	END = -999,
	CONTINUE = -888
}
const TEXT_IS_FINAL : String = "__text__is__final__"
#endregion

# TODO 对话核心自动加载 ===============>变 量<===============
#region 变量
# VAR 全局属性
var global_value : Dictionary = {}
# VAR 临时属性
var local_value : Dictionary = {}

var last_meta_dic : Dictionary
var dialogic_para : String
var dialogic_role : String
var dialogic_text : String
var dialogic_text_index : int:
	set(v):
		dialogic_text_index =  v
		if dialogic_text_index <= 0:
			dialogic_text_index = 0

var code_arr : Array

var dic : Dictionary
var order_text_dic : Dictionary
var var_dic : Dictionary
var current_para : String = ""
var current_role : String = ""
var current_text : String = ""
var current_choice : String = ""
var current_text_meta_index : int = -1
var current_choice_index : int = -1
var is_choice : bool = false
#endregion

# TODO 对话核心自动加载 ===============>信号链接方法<===============
#region 信号链接方法

#endregion

# TODO 对话核心自动加载 ===============>工具方法<===============
#region 工具方法
# 获取ddc文件第一句文本
func get_frist_text() -> String:
	var _text : String
	dialogic_text_index = 1
	_text = get_dialog_text(dialogic_text_index)
	return _text

# 获取段落第一句文本
func get_para_frist_text_index(para : String) -> int:

	for r in order_text_dic[para]:
		for t in order_text_dic[para][r]:
			last_meta_dic = {}
			return t
	return -1

# FUNC 通过文本索引获取对应文本并处理元数据
func get_dialog_text(text_index : int) -> String:
	for p in order_text_dic:
		if p == "": return ""
		dialogic_para = p
		for r in order_text_dic[p]:
			if r == "": return ""
			dialogic_role = r
			for t in order_text_dic[p][r]:
				if t == text_index:
					dialogic_text_index = t
					dialogic_text = order_text_dic[p][r][t]
					if last_meta_dic != {}:
						process_set(last_meta_dic)
						process_goto(last_meta_dic)
					last_meta_dic = process_metadata(dialogic_para, dialogic_role, dialogic_text)
					return order_text_dic[p][r][t]
	dialogic_para = ""
	dialogic_role = ""
	dialogic_text = ""
	dialogic_text_index = 0
	return ""

# FUNC 通过文本索引获取段落
func get_para_for_text_index(_text_index : int) -> String:
	var _para : String
	for i in dic:
		_para = i
		for r in dic[_para]:
			for t in dic[_para][r]:
				if t.has(order_text_dic[_para][r][_text_index]):
					return _para
	return ""

# FUNC 解析元数据
func process_metadata(_para : String, _role : String, _text : String) -> Dictionary:
	for i in dic[_para][_role]:
		if i.has(_text):
			var meta_list : Array = i[i.keys()[0]]
			print(meta_list)
			#for meta : Dictionary in meta_list:
				#return meta
	return {}

# FUNC 解析选项
func process_choice(meta : Dictionary) -> void:
	if not meta.has("choice"): return
	var meta_arr : Array = meta["choice"]

# FUNC 解析赋值
func process_set(meta : Dictionary) -> void:
	if not meta.has("set"): return
	var meta_str : String = meta["set"]
	var set_var_name : String = meta_str.get_slice(",", 0).erase(0, 1)
	var set_var_value = meta_str.get_slice(",", 1).erase(meta_str.get_slice(",", 1).length()-1, 1)
	var ex : Expression = Expression.new()
	var _global_value : Dictionary = global_value
	ex.parse(str(_global_value[set_var_name]) + set_var_value)
	_global_value[set_var_name] = ex.execute()
	global_value = _global_value

# FUNC 解析跳转
func process_goto(meta : Dictionary) -> void:
	if not meta.has("goto"): return
	var meta_str : String = meta["goto"]
	get_dialog_text(get_para_frist_text_index(meta_str))

# FUNC 获取下一句文本
func get_next_text() -> String:
	var _text : String
	dialogic_text_index += 1
	_text = get_dialog_text(dialogic_text_index)
	next_text.emit(_text)
	return _text

# FUNC 获取上一句文本
func get_previous_text() -> String:
	var _text : String
	dialogic_text_index -= 1
	_text = get_dialog_text(dialogic_text_index)
	previous_text.emit(_text)
	return _text

# FUNC 解析并声明全局变量
func declare_global_var() -> void:
	for i : String in var_dic:
		if i == "_global":
			for _global_var : String in var_dic["_global"]:
				var global_var_parts : Array = _global_var.split(",")
				global_value[global_var_parts[0].erase(0, 1)] = float(global_var_parts[1])

# FUNC 读取ddc文件
func read_ddc_file(file_path : String) -> void:
	if file_path.get_extension() != "ddc":
		push_error("读取的文件必须是ddc文件")

	var file = FileAccess.open(file_path, FileAccess.READ)
	var code : String = file.get_as_text()
	var code_rows : Array = code.split("\n")
	code_arr = code_parser(code_rows)
	dic = code_arr[0]
	var_dic = code_arr[1]

	order_text_dic = get_order_text_dic(code_rows)

# FUNC 过滤:的方法
func erase_end(code_part : String) -> String:
	if code_part.ends_with(":"):
		code_part = code_part.erase(code_part.length()-1)
	return code_part

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

# FUNC 成员关键字解析方法
func member_key_parser(code_parts : Array, var_part : Dictionary) -> Array:
	var is_paser : bool = false
	for i in ["_global", "_local", "_signal"]:
		if not code_parts.has(i): continue
		is_paser = true
		var code_part : String
		code_part = get_full_value_in_code_part(code_parts, i)
		if not var_part.has(i):
			var_part[i] = []
		var_part[i].append(code_part)
		return [var_part, is_paser]
	return [var_part, is_paser]

# FUNC 主要关键字解析方法
func main_key_parser(code_parts : Array, code_part_index : int) -> Array:
	var is_paser : bool = false
	var code_part : String
	for i in ["_role", "_para"]:
		if not code_parts.has(i): continue
		is_paser = true
		code_part_index = code_parts.find(i) + 1
		code_part = code_parts[code_part_index]
		code_part = erase_end(code_part)
		return [code_part, is_paser, i]
	return [code_part, is_paser, "null"]

# FUNC 子成员关键字解析方法
func child_key_parser(code_parts : Array, code_part_index : int) -> bool:
	var is_paser : bool = false
	for i in ["set", "emote", "goto", "time", "voice", "condition", "event", "continue", "end"]:
		if not code_parts.has(i): continue
		is_paser = true
		code_part_index = code_parts.find(i) + 1
		var code_part : String
		code_part = get_full_value_in_code_part(code_parts, i)
		for index in dic[current_para][current_role].size():
			if dic[current_para][current_role][index].keys()[0] != current_text: continue
			if is_choice:
				if i in ["continue", "end"]:
					dic[current_para][current_role][index][current_text][-1]["choice"][current_choice_index][current_choice].append(CodeKeyType.CONTINUE if i == "continue" else CodeKeyType.END)
					continue
				dic[current_para][current_role][index][current_text][-1]["choice"][current_choice_index][current_choice].append({i : code_part})
				continue
			if i in ["continue", "end"]:
				dic[current_para][current_role][index][current_text].append(CodeKeyType.CONTINUE if i == "continue" else CodeKeyType.END)
				continue
			dic[current_para][current_role][index][current_text].append({i : code_part})
			break
		return is_paser
	return is_paser

# FUNC 代码解析器
func code_parser(code_rows : Array) -> Array:
	var current_row_index : int = 0
	for code_row in code_rows:
		if code_row.dedent() == "": continue
		var code_parts : Array = code_row.split(" ")
		var code_part_index : int

		var tab_num : int = 0
		tab_num = code_parts[0].count("\t")
		code_parts[0] = code_parts[0].split("\t")[-1]

		if tab_num < 3:
			is_choice = false

		# NOTE 解析成员关键字 global local signal
		var member_parser_arr : Array = member_key_parser(code_parts, var_dic)
		var_dic = member_parser_arr[0]
		if member_parser_arr[1]: continue

		# NOTE 解析段落关键字与角色关键字
		var main_parser_arr : Array = main_key_parser(code_parts, code_part_index)
		match main_parser_arr[2]:
			"_para" :
				current_para = main_parser_arr[0]
			"_role" :
				current_role = main_parser_arr[0]
		if main_parser_arr[1]: continue

		# NOTE 解析文本关键字
		if code_parts.has("text"):
			code_part_index = code_parts.find("text") + 1
			var code_part : String = code_parts[code_part_index]
			code_part = erase_end(code_part)
			current_text = code_part
			if not dic.has(current_para):
				dic[current_para] = {current_role : []}
			if not dic[current_para].has(current_role):
				dic[current_para][current_role] = []
			dic[current_para][current_role].append({current_text : [{"cls" : CodeKeyType.TEXT}]})
			continue

		# NOTE 解析选择关键字
		if code_parts.has("choice"):
			is_choice = false
			code_part_index = code_parts.find("choice") + 1
			var code_part : String = code_parts[code_part_index]
			code_part = erase_end(code_part)
			current_choice = code_part
			for i in dic[current_para][current_role].size():
				if dic[current_para][current_role][i].keys()[0] == current_text:
					var _choice : bool = false
					for y in dic[current_para][current_role][i][current_text].size():
						if dic[current_para][current_role][i][current_text][y].keys().has("choice"):
							_choice = true
							break
					if not _choice:
						dic[current_para][current_role][i][current_text].append({"choice" : []})
					for y in dic[current_para][current_role][i][current_text].size():
						current_text_meta_index = y + 1
						dic[current_para][current_role][i][current_text][-1]["choice"].append({code_part : []})
						is_choice = true
						break
					break
				break
			continue

		# NOTE 解析子成员关键字
		if child_key_parser(code_parts, code_part_index): continue
	return [dic, var_dic]

func get_order_text_dic(code_rows : Array) -> Dictionary:
	var para : String = ""
	var role : String = ""
	var text : String = ""
	var text_index : int = 0

	var _order_text_dic : Dictionary
	for row : String in code_rows:
		row = row.strip_edges(false)
		var code_parts : Array = row.split(" ")
		code_parts[0] = code_parts[0].split("\t")[-1]
		if code_parts[-1] == ":":
			code_parts.pop_back()
		if code_parts.has("_para"):
			para = erase_end(code_parts[-1])
			continue
		if  code_parts.has("_role"):
			role = erase_end(code_parts[-1])
			continue
		if not code_parts.has("text"): continue
		text_index += 1
		var _text : String = code_parts[-1]
		_text = erase_end(_text).strip_edges(false, true)
		if not _order_text_dic.has(para):
			_order_text_dic[para] = {role : {text_index : _text}}
			continue
		if not _order_text_dic[para].has(role):
			_order_text_dic[para][role] = {text_index : _text}
			continue
		if not _order_text_dic[para][role].size() > 0:
			_order_text_dic[para][role][text_index] = _text
			continue
		_order_text_dic[para][role][text_index] = _text
	return _order_text_dic
#endregion
