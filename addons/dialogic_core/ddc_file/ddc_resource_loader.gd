@tool
extends ResourceFormatLoader

# TODO DDC文件 ===============>虚方法<===============
#region 常用的虚方法
func _get_recognized_extensions() -> PackedStringArray:
	return ["ddc"]

func _handles_type(type: StringName) -> bool:
	return type == "DDCResource"

func _recognize_path(path: String, type: StringName) -> bool:
	return path.get_extension().to_lower() == "ddc"  # 识别路径

func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int) -> Variant:
	return DDCResource.new()
#endregion
