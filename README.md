# Godot Dialogic Core
  一个对话系统插件
# 路线
- [ ] ddc语言(对话脚本语言)
	- [x] ddc语言关键字定义
		"_para", "_role", "_global", "_local", "_signal"
		"if", "else", "elif", "goto", "continue", "end", "time", "event", "choice"
		"emote", "voice", "text"
	- [x] ddc语言自动补全
	- [x] ddc语言的语法规范
	- [x] ddc语言的错误判断
	- [x] ddc语言的语法高亮
	- [ ] ddc语言的语法解析
		- [x] 两个变量成员关键字的解析 '_global', '_local'
		- [x] 两个主要成员关键字的解析 '_para', '_role'
		- [x] 文本关键字的解析 'text'
		- [x] 声音播放关键字的解析 'voice'
		- [x] 表情切换关键字的解析 'emote'
		- [x] 结束关键字的解析 'end'
		- [ ] 选择关键字的解析 'choice'
		- [ ] 条件关键字的解析 'if', 'elif', 'else'
		- [ ] 段落跳转关键字的解析 'goto'
		- [ ] 时间关键字的解析 'time'
		- [ ] 事件关键字的解析 'event'
		- [ ] 角色休止关键字的解析 'continue'
		- [ ] 信号关键字的解析 '_signal'
- [ ] 可视化的对话编辑
- [ ] 对话与过场动画结合
- [ ] 简单易用的对话系统调用
- [ ] 可自定义的主题
- [ ] 本地化支持
