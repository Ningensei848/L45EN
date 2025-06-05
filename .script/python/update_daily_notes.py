import json
from datetime import datetime
from pathlib import Path


# 設定ファイルのパス
path_to_this_file_itself = Path(__file__).resolve()
base_dir = path_to_this_file_itself.parents[2] # ["python", ".script", "<rootDir>"]
config_daily_notes = base_dir / ".obsidian" / "daily-notes.json"

# 現在の年月を取得
current_year = datetime.now().year
current_month = datetime.now().month
new_folder = base_dir / "Daily" / f"{current_year}" / f"{current_month:02d}"

# フォルダが存在しない場合は作成
new_folder.mkdir(parents=True, exist_ok=True)

# 設定ファイルを読み込んで更新
json_text = config_daily_notes.read_text(encoding="utf-8")
settings = json.loads(json_text)
settings["folder"] = f"Daily/{current_year}/{current_month:02d}"

# 設定ファイルに書き込む
with config_daily_notes.open("w", encoding="utf-8") as f:
    json.dump(settings, f, indent=4)

print(f"Updated daily notes folder to: \n{str(new_folder)}")
