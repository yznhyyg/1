# 角色系统

目前只有初始伙伴 **闻序**。登录后自动获得；旧版本的拥有记录继续保留。
角色只用于伙伴展示，不修改分数、判定或 Rating。

## 在游戏中使用

- 在主页点击 Enter 下方的 **角色** 按钮、点击人物，或按 **C**，进入角色页。
- 角色页展示立绘、名字、称号、简介、台词和解锁说明。
- 下方收藏列表展示所有配置角色，以及“当前伙伴 / 已拥有 / 未解锁”状态。
- 已拥有的角色可设为主页伙伴；未拥有的角色可以查看资料，但无法选择。
- 返回主页后显示当前选择的角色；**Esc** 返回。
- 直接运行场景可以预览界面，没有登录时不会授予角色或保存选择。

## 添加新角色

1. 把透明 PNG 立绘放进 `assets/characters/`。
2. 在 `characters/catalog.json` 的数组中追加一个对象。数组顺序就是列表顺序。
3. 为角色使用独立且固定的 `id`。不要复用或更改已发布角色的 ID，否则存档无法正确关联。

以下是配置格式示例，**没有加入正式角色列表**：

```json
{
  "id": "new_partner",
  "name": "新角色名字",
  "title": "角色称号",
  "description": "角色简介，建议控制在约 100 字以内。",
  "quote": "角色的一句台词。",
  "portrait": "res://assets/characters/new_partner.png",
  "accent": "#FFA66E",
  "unlock": {
	"type": "manual",
	"description": "完成指定挑战后获得"
  }
}
```

`id` 必须唯一。立绘支持 Godot 的 Texture2D 资源，推荐使用透明 PNG；缺失或无效的立绘显示“立绘待补充”。
名字、称号、简介和台词建议保持简短，长文本会限制行数以保护页面布局。

### 登录赠送与奖励解锁

- `unlock.type` 为 `login`：每次登录自动检查并补发该角色，不会重复添加。
- `unlock.type` 为 `manual`（或省略）：角色默认未解锁，需要在实际任务或奖励逻辑中调用解锁接口。
- `unlock.description` 只是给玩家看的说明文字，不会自动创建任务或检查任务条件。

奖励条件达成时：

```gdscript
const Partners = preload("res://partner_system.gd")

if Partners.unlock_character(get_tree(), "new_partner"):
	# 角色已经获得并保存，可以通知玩家。
	pass
```

也可用 `Partners.select_character(get_tree(), "new_partner")` 选择已拥有角色。
不存在、未拥有或未登录时无法选择；重复解锁不会产生重复记录。
将 JSON 和立绘加入项目后，重新进入角色页即可读取新角色，不需要为每个角色新建场景。

## 存档与兼容

拥有列表及当前角色继续按账号保存在：

```text
user://partners_<账号ID的SHA256>.json
```

- 保留旧版本的 `owned` 和 `active`，以及其他已有字段。
- 账号切换时，不能使用上一账号的内存记录。
- 当前角色不存在或不再属于拥有列表时，回退到第一个可用的已拥有角色。
- 暂时不在当前配置中的拥有记录仍保留，避免移除角色配置时丢失历史解锁。
- 选择保存成功后才更新当前角色，文件通过临时文件替换写入。
- 不保存令牌或密码。

目前角色收藏与选择是**本地按账号存储**，没有新增云端角色表。换设备登录仍会收到所有登录赠送角色；其他奖励解锁及当前选择尚不跨设备同步。

## 验证

```sh
godot --headless --editor --import --quit
godot --headless --audio-driver Dummy --script res://tests/test_characters.gd
godot --headless --audio-driver Dummy --script res://tests/test_partners.gd
godot --headless --audio-driver Dummy --script res://tests/test_rating.gd
python3 tests/check_character_expansion.py
```

角色测试包含旧存档兼容、账号隔离、无效选择拦截、点击入口、C 快捷键、资料显示与返回主页。
扩展验证脚本会在临时项目副本加入手动解锁的第二个角色，验证解锁、选择、重新登录及动态立绘；测试角色不会加入正式配置。

导出游戏时，在导出预设的非资源文件过滤中填写 `*.json`，以包含角色配置 `characters/catalog.json` 和歌曲包 JSON。

## 主页背景

开始界面使用原创深蓝夜景音乐厅背景 `assets/backgrounds/home_midnight_atrium.png`，附加轻微深色遮罩；背景不接收输入。

## 效果图

![角色页](docs/previews/characters_wenxu.png)

![主页](docs/previews/home_wenxu.png)
