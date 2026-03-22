import os
import shutil
import glob

base_dir = r"c:\Users\rushe\OneDrive\Desktop\Code\godot-2d-visual-novel-main\godot\Story"
oboyan_dir = os.path.join(base_dir, "01_Oboyan")

# 1. Create 01_Oboyan if it doesn't exist
os.makedirs(oboyan_dir, exist_ok=True)

# 2. Delete all .txt files recursively in Story
for root, dirs, files in os.walk(base_dir):
    for file in files:
        if file.endswith(".txt"):
            os.remove(os.path.join(root, file))
            print(f"Deleted legacy txt: {file}")

# 3. Move prologue.json to 01_Oboyan/01_casino_night.json
prologue_path = os.path.join(base_dir, "prologue.json")
casino_target = os.path.join(oboyan_dir, "01_casino_night.json")
if os.path.exists(prologue_path):
    shutil.move(prologue_path, casino_target)
    print(f"Moved prologue.json to {casino_target}")

# 4. Remove duplicate casino if it was wrongly put in Warsaw
warsaw_casino = os.path.join(base_dir, "00_Warsaw", "03_casino_night.json")
if os.path.exists(warsaw_casino):
    os.remove(warsaw_casino)
    print("Deleted misplaced casino in 00_Warsaw")

print("Cleanup script complete.")
