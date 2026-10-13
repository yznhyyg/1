# 初始伙伴：闻序

- ID：`wenxu`
- 名字：闻序
- 立绘：`assets/characters/wenxu.png`（透明背景）
- 原始插画保留在 `assets/characters/mature_man_fullbody.png`。

登录成功后，`login.gd` 在进入主页前调用 `PartnerSystem.grant_starter()`。
初始伙伴自动加入拥有列表；重复登录不会重复添加。尚无当前伙伴时，默认选择闻序。
伙伴仅用于主页展示，不改变分数、判定或 Rating。

拥有列表及当前伙伴按账号保存在本地 `user://partners_<账号ID的SHA256>.json`，不写入令牌或密码。
目前没有新增云端伙伴表；换设备登录时仍会自动获得初始伙伴。
直接运行主页场景可预览立绘，但没有登录时不会授予伙伴。

主页只保留游戏名、Rating、小号 Enter 按钮、左下角 tip 和右侧伙伴立绘。

验证：

```sh
godot --headless --editor --import --quit
godot --headless --audio-driver Dummy --script res://tests/test_partners.gd
godot --headless --audio-driver Dummy --script res://tests/test_rating.gd
```

## 主页效果

下图为 720 × 1280 的实际运行截图，Rating 示例为 0.000。

![闻序主页](docs/previews/home_wenxu.png)
