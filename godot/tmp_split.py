import json
import os

source_path = r"c:\Users\rushe\OneDrive\Desktop\Code\godot-2d-visual-novel-main\godot\Story\Extras\prequel_danila.json"
out_dir = r"c:\Users\rushe\OneDrive\Desktop\Code\godot-2d-visual-novel-main\godot\Story\00_Warsaw"

with open(source_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Find indices for factory and casino chunks
# Factory starts at {"args": ["factory_inside", ""], "name": "background"}
factory_start = 0
for i, node in enumerate(data):
    if node.get("name") == "background" and node.get("args", [])[0] == "factory_inside":
        factory_start = i
        break

# Factory ends right before: "После работы рабочие собираются в углу цеха."
factory_end = 0
for i, node in enumerate(data):
    if node.get("text") and "После работы рабочие собираются в углу цеха" in node.get("text"):
        factory_end = i
        break

# Casino ends right before: "И вот я здесь. Агент. Готов к миссии."
casino_end = 0
for i, node in enumerate(data):
    if node.get("text") and "И вот я здесь. Агент. Готов к миссии." in node.get("text"):
        casino_end = i
        break

factory_data = data[factory_start:factory_end]
casino_data = data[factory_end:casino_end]

# Modify factory data
# Add intro tracking to factory so Bronislav only introduces himself once
intro_nodes = factory_data[1:18] # approx where he explains tasks until "Начну с расфасовки"
# We can just wrap the intro in an IF block or just let him say it every time for simplicity for now. 
# Better: just set warsaw_prologue_stage and system_pass_time at the end of factory_data
factory_data.append({
    "name": "set",
    "args": ["system_pass_time", 1],
    "type": "command"
})
factory_data.append({
    "name": "set",
    "args": ["money", "+80"],
    "type": "command"
})

with open(os.path.join(out_dir, "02_factory_shift.json"), 'w', encoding='utf-8') as f:
    json.dump(factory_data, f, ensure_ascii=False, indent=4)

# Modify casino data
casino_data.append({
    "name": "set",
    "args": ["system_pass_time", 1],
    "type": "command"
})
with open(os.path.join(out_dir, "03_casino_night.json"), 'w', encoding='utf-8') as f:
    json.dump(casino_data, f, ensure_ascii=False, indent=4)

print("Split completed successfully!")
