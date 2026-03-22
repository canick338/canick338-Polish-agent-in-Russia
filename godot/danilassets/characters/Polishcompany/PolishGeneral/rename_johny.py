import os

base_dir = r"c:\Users\rushe\OneDrive\Desktop\Code\godot-2d-visual-novel-main\godot\danilassets\characters\Polishcompany\PolishGeneral"

# Define the user-provided friendly names and the new clean system names.
# (Usually we want character_mood format)
rename_map = {
    "General crazy guy points his finger.png": "chief_crazy_pointing.png",
    "General stands in a smiling pose.png": "chief_smile.png",
    "General with a Polish flag in the background holding a phone.png": "chief_flag_phone.png",
    "Polish_general_holds_out_the_switched-off_phone.png": "chief_phone_off.png",
    "Polish_general_static_pose.png": "chief_neutral.png",
    "Polish_motivational_general_shouts.png": "chief_shouting.png",
    "The_Polish_man_points_smile.png": "chief_pointing_smile.png",
    "holding a phone with a neural network turned on.png": "chief_phone_on.png",
    "the Polish general shouts that this is the best messenger.png": "chief_shouting_messenger.png"
}

import shutil

for file in os.listdir(base_dir):
    full_path = os.path.join(base_dir, file)
    
    # If the file is a long UUID format, just delete it (the user said they signed the real ones).
    # A UUID has 36 characters e.g., 1288a7e5-ce26-4aeb-ae1f-6418e07d944f
    if len(file) > 32 and file[8] == '-':
        os.remove(full_path)
        print(f"Deleted UUID file: {file}")
        continue

    # If it's one of the signed files, rename it
    if file in rename_map:
        new_name = rename_map[file]
        new_path = os.path.join(base_dir, new_name)
        os.rename(full_path, new_path)
        print(f"Renamed {file} -> {new_name}")

    # Remove the .import files for the deleted or renamed ones so Godot can re-import cleanly
    if file.endswith(".import"):
        os.remove(full_path)

print("Cleanup and rename complete.")
