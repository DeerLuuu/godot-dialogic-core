# INFO 插件核心代码
@tool
extends EditorPlugin

# TODO 对话核心脚本编辑器的预加载
const DIALOGIC_CORE_CODE_EDITOR = preload("res://addons/dialogic_core/ui/dialogic_core_code_editor.tscn")
# TODO 对话核心自动加载
const DialogicCoreAuto = "res://addons/dialogic_core/auto/dialogic_core_auto.gd"

# VAR 对话核心脚本编辑器
var dialogic_core_code_editor : DialogicCoreCodeEditor
# 自定义加载器实例
var ddc_loader: ResourceFormatLoader = preload("res://addons/dialogic_core/ddc_file/ddc_resource_loader.gd").new()
# 自定义保存器实例
#var ddc_saver: ResourceFormatSaver = preload("res://addons/dialogic_core/ddc_file/ddc_resource_saver.gd").new()

func _enter_tree() -> void:
	dialogic_core_code_editor = DIALOGIC_CORE_CODE_EDITOR.instantiate()
	dialogic_core_code_editor.hide()
	get_editor_interface().get_editor_main_screen().add_child(dialogic_core_code_editor)
	add_autoload_singleton("DialogicCore", DialogicCoreAuto)

	dialogic_core_code_editor.editor = self
	scene_saved.connect(dialogic_core_code_editor._on_scene_saved)

	ResourceLoader.add_resource_format_loader(ddc_loader)
	#ResourceSaver.add_resource_format_saver(ddc_saver)

	if not get_editor_interface().get_resource_filesystem().is_scanning():
		get_editor_interface().get_resource_filesystem().scan()

func _exit_tree() -> void:
	dialogic_core_code_editor.queue_free()
	remove_autoload_singleton("DialogicCore")
	ResourceLoader.remove_resource_format_loader(ddc_loader)
	#ResourceSaver.remove_resource_format_saver(ddc_saver)
	ddc_loader = null
	#ddc_saver = null
	get_editor_interface().get_resource_filesystem().scan()

func _make_visible(visible:bool) -> void:
	if not dialogic_core_code_editor:
		return

	if dialogic_core_code_editor.get_parent() is Window:
		if visible:
			get_editor_interface().set_main_screen_editor("Script")
			dialogic_core_code_editor.show()
			dialogic_core_code_editor.get_parent().grab_focus()
	else:
		dialogic_core_code_editor.visible = visible

# FUNC 是否是主屏幕插件
func _has_main_screen() -> bool:
	return true

# FUNC 设置显示的文本内容
func _get_plugin_name() -> String:
	return "Dialogic Core"

# FUNC 设置图标
# TODO 因为还没有图标所以该方法被注释了
#func _get_plugin_icon() -> Texture2D:
	#return load(PLUGIN_ICON_PATH)
