@tool
extends ResourceFormatSaver

# TODO DDC文件 ===============>虚方法<===============
#region 常用的虚方法
func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	return ["ddc"]

func _recognize(resource: Resource) -> bool:
	# 根据资源类型判断是否处理
	return resource is DDCResource

func _save(resource: Resource, path: String, flags: int) -> Error:
	return OK
#endregion
