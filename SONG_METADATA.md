# 歌曲难度信息

每首歌曲的 `song.json` 使用 `master_enabled` 控制大师难度，并用 `difficulties` 对象关联各难度谱面：

```json
"master_enabled": false,
"difficulties": {
  "beginner": {"name": "初级", "constant": 6.0, "chart": "beginner_chart.json"},
  "normal": {"name": "中级", "constant": 7.5, "chart": "normal_chart.json"},
  "advanced": {"name": "高级", "constant": 8.5, "chart": "advanced_chart.json"}
}
```

需要大师难度时，将 `master_enabled` 改为 `true`，并加入：

```json
"master": {"name": "大师", "chart": "master_chart.json"}
```

歌曲共用 `artwork` 曲绘；每个难度使用自己的 chart 文件。

成绩按 `歌曲ID::难度ID` 分开保存；旧版只有歌曲 ID 的成绩会按高级难度兼容读取。
