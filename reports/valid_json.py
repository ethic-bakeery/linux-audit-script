import json
import os

JSON_DIR = "/home/server/linux-audit-script/reports"  # Change this to your JSON files directory

def check_json_files():
    json_files = [f for f in os.listdir(JSON_DIR) if f.endswith(".json")]

    for json_file in json_files:
        file_path = os.path.join(JSON_DIR, json_file)
        try:
            with open(file_path, "r") as file:
                json.load(file)  # Try to load the file
            print(f"✅ {json_file} is valid.")
        except json.JSONDecodeError as e:
            print(f"❌ {json_file} has an issue: {e}")

check_json_files()

