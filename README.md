# Godot Dialogic Core
  一个对话系统插件
# 路线
- [x] ddc语言(对话脚本语言)
	- [x] ddc语言关键字定义
		"_para", "_role", "_global", "_local", "_signal"
		"condition", "goto", "continue", "end", "time", "event", "choice", "set"
		"emote", "voice", "text"
	- [x] ddc语言自动补全
	- [x] ddc语言的语法规范
	- [x] ddc语言的错误判断
	- [x] ddc语言的语法高亮
	- [x] ddc语言的语法解析
		- [x] 两个变量成员关键字的解析 '_global', '_local'
		- [x] 两个主要成员关键字的解析 '_para', '_role'
		- [x] 文本关键字的解析 'text'
		- [x] 声音播放关键字的解析 'voice'
		- [x] 表情切换关键字的解析 'emote'
		- [x] 结束关键字的解析 'end'
		- [x] 选择关键字的解析 'choice'
		- [x] 条件关键字的解析 "condition"
		- [x] 段落跳转关键字的解析 'goto'
		- [x] 时间关键字的解析 'time'
		- [x] 事件关键字的解析 'event'
		- [x] 角色休止关键字的解析 'continue'
		- [x] 信号关键字的解析 '_signal'
		- [x] 赋值关键字的解析 'set'
- [ ] 对话系统
	- [ ] 基础的对话组件
	- [ ] 根据ddc语言的解析结果显示文字
	- [ ] 完善ddc语言与gds语言之间的对接
	- [ ] 支持富文本
	- [ ] 支持表情切换
- [ ] 可视化的对话编辑
- [ ] 对话与过场动画结合
- [ ] 简单易用的对话系统调用
- [ ] 可自定义的主题
- [ ] 本地化支持
