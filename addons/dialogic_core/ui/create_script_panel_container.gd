@tool
extends PanelContainer

# TODO 创建文件面板 ===============>信 号<===============
#region 信号
signal close
#endregion

# TODO 创建文件面板 ===============>常 量<===============
#region 常量
const DDC_TYPE : String = ".ddc"
const TYPE_ERR : String = "[ul] 	文件路径必须带有类型后缀[/ul]"
const NAME_ERR : String = "[ul] 	文件名称不能为特殊符号[/ul]"
const SUCCESS : String =  "[ul] 	将创建新文件[/ul]"
const REPEAT : String =   "[ul] 	文件重复，将会重用[/ul]"
#endregion

# TODO 创建文件面板 ===============>变 量<===============
#region 变量
@onready var confirm_button: Button = %ConfirmButton
@onready var file_type_option_button: OptionButton = %FileTypeOptionButton
@onready var file_path_edit: LineEdit = %FilePathEdit
@onready var file_name_edit: LineEdit = %FileNameEdit

var editor : EditorPlugin

var current_file_name : String:
	set(v):
		current_file_name = v
		file_name_edit.text = current_file_name
		if current_file_path != "":
			var file_path_parts : Array = current_file_path.split("/")
			file_path_parts[-1] = current_file_name + current_file_type
			for i in file_path_parts.size() - 1:
				file_path_parts[i] = file_path_parts[i] + "/"
			current_file_path = "".join(file_path_parts)
var current_file_path : String:
	set(v):
		current_file_path = v
		file_path_edit.text = current_file_path
var current_file_type : String
var file_dialog : FileDialog
#endregion

# TODO 创建文件面板 ===============>虚方法<===============
#region 常用的虚方法
func _ready() -> void:
	current_file_name = file_name_edit.text
	file_type_option_button.selected = 0
	file_type_option_button.item_selected.emit(0)
	pass
func _exit_tree() -> void:
	close.emit()
#endregion

# TODO 创建文件面板 ===============>信号链接方法<===============
#region 信号链接方法
# FUNC 文件名称改变的信号方法
func _on_file_name_edit_text_changed(new_text: String) -> void:
	current_file_name = new_text

# FUNC 文件类型改变的信号方法
func _on_file_type_option_button_item_selected(index: int) -> void:
	match index:
		0 :
			current_file_type = DDC_TYPE

# FUNC 文件路径改变的信号方法
func _on_file_path_edit_text_changed(new_text: String) -> void:
	if new_text.get_extension() != "":
		if new_text.get_extension() == "ddc":
			file_type_option_button.selected = 0
	current_file_path = new_text

# FUNC
func _on_file_button_pressed() -> void:
	file_dialog = FileDialog.new()
	file_dialog.confirmed.connect(_on_file_dialog_confirmed)
	file_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.filters = [".ddc"]
	add_child(file_dialog)
	file_dialog.show()

func _on_file_dialog_confirmed() -> void:
	current_file_path = file_dialog.current_dir.path_join(current_file_name) + current_file_type

# FUNC
func _on_confirm_button_pressed() -> void:
	var file = FileAccess.open(current_file_path, FileAccess.WRITE)
	editor.get_editor_interface().get_resource_filesystem().scan()
	queue_free()

# FUNC
func _on_cancel_button_pressed() -> void:
	queue_free()
#endregion

# TODO 创建文件面板 ===============>工具方法<===============
#region 工具方法

#endregion
