import os
from PIL import Image, ImageDraw

def add_corners(im, rad):
    # Ensure image size is larger than 2*rad
    rad = min(rad, im.width // 2, im.height // 2)
    circle = Image.new('L', (rad * 2, rad * 2), 0)
    draw = ImageDraw.Draw(circle)
    # Using antialiasing
    draw.ellipse((0, 0, rad * 2 - 1, rad * 2 - 1), fill=255)
    
    alpha = Image.new('L', im.size, 255)
    w, h = im.size
    alpha.paste(circle.crop((0, 0, rad, rad)), (0, 0))
    alpha.paste(circle.crop((0, rad, rad, rad * 2)), (0, h - rad))
    alpha.paste(circle.crop((rad, 0, rad * 2, rad)), (w - rad, 0))
    alpha.paste(circle.crop((rad, rad, rad * 2, rad * 2)), (w - rad, h - rad))
    
    im.putalpha(alpha)
    return im

base_dir = "c:/Users/rushe/OneDrive/Desktop/Code/godot-2d-visual-novel-main/godot/Assets/Textures/Phone"
files = ['icon_bank', 'icon_gov', 'icon_mail', 'icon_shop']

for f in files:
    jpg_path = os.path.join(base_dir, f + ".jpg")
    png_path = os.path.join(base_dir, f + ".png")
    
    if os.path.exists(jpg_path):
        try:
            im = Image.open(jpg_path).convert('RGBA')
            # Determine a good corner radius, roughly 18-20% of image size for iOS style
            radius = int(min(im.size) * 0.22)
            im_rounded = add_corners(im, radius)
            im_rounded.save(png_path, "PNG")
            print(f"Processed and saved: {png_path}")
        except Exception as e:
            print(f"Error processing {f}: {e}")
    else:
        print(f"Missing file: {jpg_path}")
