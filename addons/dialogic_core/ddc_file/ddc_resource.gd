@tool
class_name DDCResource extends Resource

# TODO DDC文件 ===============>虚方法<===============
#region 常用的虚方法
func _get_import_path(path : String):
	return path.get_basename()  + ".ddc.import"   # 声明关联的导入文件  extends Node
#endregion
