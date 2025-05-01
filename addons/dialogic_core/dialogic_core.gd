@tool
extends EditorPlugin

const DIALOGIC_CORE_CODE_EDITOR = preload("res://addons/dialogic_core/ui/dialogic_core_code_editor.tscn")

var dialogic_core_code_editor

func _enter_tree() -> void:
	dialogic_core_code_editor = DIALOGIC_CORE_CODE_EDITOR.instantiate()
	add_control_to_bottom_panel(dialogic_core_code_editor, "对话系统")
	pass


func _exit_tree() -> void:
	remove_control_from_bottom_panel(dialogic_core_code_editor)
	dialogic_core_code_editor.queue_free()
	pass
