import os, glob
files = glob.glob('c:/Users/rushe/OneDrive/Desktop/Code/godot-2d-visual-novel-main/godot/Story/00_Warsaw/**/*.json', recursive=True) + glob.glob('c:/Users/rushe/OneDrive/Desktop/Code/godot-2d-visual-novel-main/godot/Story/00_Warsaw/**/*.py', recursive=True)
for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    if '60' in content:
        content = content.replace('60', '60')
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)
print("Replaced!")
