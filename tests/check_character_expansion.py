"""Validate adding a second character without changing the real project or catalog."""
import json
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    godot = shutil.which("godot") or shutil.which("godot4")
    if not godot:
        raise SystemExit("Godot executable not found on PATH")
    project = Path(__file__).resolve().parents[1]
    with tempfile.TemporaryDirectory(prefix="rg-character-expansion-") as directory:
        fixture = Path(directory) / "project"
        shutil.copytree(project, fixture, ignore=shutil.ignore_patterns(".git", ".godot", "docs"))
        catalog_path = fixture / "characters" / "catalog.json"
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
        catalog.append({
            "id": "fixture_partner", "name": "测试伙伴", "title": "仅用于验证扩展",
            "description": "临时测试角色，不加入正式仓库。", "quote": "测试切换与存档。",
            "portrait": "res://icon.svg", "accent": "#FFA66E",
            "unlock": {"type": "manual", "description": "测试解锁"},
        })
        catalog_path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2), encoding="utf-8")
        base = [godot, "--headless", "--audio-driver", "Dummy", "--path", str(fixture)]
        installation = subprocess.run(base + ["--editor", "--import", "--quit"], capture_output=True, text=True)
        if installation.returncode:
            print(installation.stdout)
            print(installation.stderr)
            raise SystemExit(installation.returncode)
        result = subprocess.run(base + ["--script", "res://tests/test_characters.gd"])
        raise SystemExit(result.returncode)


if __name__ == "__main__":
    main()
