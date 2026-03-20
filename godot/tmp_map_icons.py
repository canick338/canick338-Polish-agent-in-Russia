import os
from PIL import Image, ImageDraw

def process_map_icon(img_path, out_path, size=(160, 160), radius=80):
    try:
        img = Image.open(img_path).convert("RGBA")
        img = img.resize(size, Image.Resampling.LANCZOS)
        
        # Create circular mask
        mask = Image.new("L", size, 0)
        draw = ImageDraw.Draw(mask)
        draw.ellipse((0, 0, size[0], size[1]), fill=255)
        
        # Apply mask
        img.putalpha(mask)
        
        # Optional: Add thick border to make it pop like a pin
        border = ImageDraw.Draw(img)
        border.ellipse((0, 0, size[0]-1, size[1]-1), outline=(230, 230, 230, 255), width=4)
        
        img.save(out_path, "PNG")
        print(f"Processed {out_path}")
    except Exception as e:
        print(f"Failed {img_path}: {e}")

base_dir = "c:/Users/rushe/OneDrive/Desktop/Code/godot-2d-visual-novel-main/godot/Assets/Textures/MapIcons/"
files = ["icon_academy", "icon_factory", "icon_home", "icon_casino"]

for f in files:
    process_map_icon(base_dir + f + "_raw.png", base_dir + f + ".png")

