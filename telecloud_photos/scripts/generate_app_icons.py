import os
import math
from PIL import Image, ImageDraw, ImageFilter

def create_master_icon(size=1024):
    # Base image
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    
    # 1. Background Gradient (Rich Deep Space to Electric Cyan/Azure)
    bg = Image.new("RGBA", (size, size))
    for y in range(size):
        # Vertical gradient factor (0 to 1)
        t = y / size
        # Color transition from #0B132B -> #005F73 -> #0A9396 -> #0077B6 -> #0096C7
        r = int(10 * (1 - t) + 0 * t)
        g = int(25 * (1 - t) + 140 * t)
        b = int(60 * (1 - t) + 230 * t)
        for x in range(size):
            # Radial highlight at top-center
            dx = (x - size / 2) / (size / 2)
            dy = (y - size / 3) / (size / 2)
            dist = math.sqrt(dx * dx + dy * dy)
            glow = max(0.0, 1.0 - dist * 0.8) * 45
            
            nr = min(255, int(r + glow * 0.4))
            ng = min(255, int(g + glow * 0.8))
            nb = min(255, int(b + glow * 1.2))
            bg.putpixel((x, y), (nr, ng, nb, 255))
            
    # 2. Draw Subtle Circular Aperture Ring / Shutter Iris in Center
    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    
    center = size / 2
    
    # Outer glowing ring
    radius_outer = size * 0.36
    radius_inner = size * 0.28
    
    # Draw frosted glass photo aperture petals
    num_blades = 8
    for i in range(num_blades):
        angle = i * (2 * math.pi / num_blades)
        # Petal arc points
        p1 = (center + radius_inner * math.cos(angle), center + radius_inner * math.sin(angle))
        p2 = (center + radius_outer * math.cos(angle + 0.4), center + radius_outer * math.sin(angle + 0.4))
        p3 = (center + radius_outer * math.cos(angle + 0.7), center + radius_outer * math.sin(angle + 0.7))
        p4 = (center + radius_inner * math.cos(angle + 0.3), center + radius_inner * math.sin(angle + 0.3))
        
        # Draw translucent white/cyan blade
        blade_color = (255, 255, 255, 28) if i % 2 == 0 else (100, 220, 255, 38)
        draw.polygon([p1, p2, p3, p4], fill=blade_color)
        
    # Draw glossy inner & outer circle rings
    draw.ellipse([center - radius_outer, center - radius_outer, center + radius_outer, center + radius_outer], 
                 outline=(255, 255, 255, 70), width=int(size * 0.006))
    draw.ellipse([center - radius_inner, center - radius_inner, center + radius_inner, center + radius_inner], 
                 outline=(100, 220, 255, 90), width=int(size * 0.005))
    
    # Composite background & aperture
    img = Image.alpha_composite(bg, overlay)
    
    # 3. Draw Telegram Paper Plane Cloud Central Emblem
    emblem_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    edraw = ImageDraw.Draw(emblem_layer)
    
    # Draw Cloud Bubble Background
    cloud_w = size * 0.38
    cloud_h = size * 0.26
    cx = center
    cy = center
    
    # Glow around cloud
    glow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow_layer)
    gdraw.ellipse([cx - cloud_w * 0.6, cy - cloud_h * 0.7, cx + cloud_w * 0.6, cy + cloud_h * 0.7], 
                  fill=(0, 210, 255, 120))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(size * 0.04))
    img = Image.alpha_composite(img, glow_layer)
    
    # Central Telegram Paper Plane (Iconic Crisp Geometry)
    # Scaled coordinates centered at (cx, cy)
    scale = size * 0.0016
    
    # Paper plane points
    nose = (cx + 85 * scale, cy - 65 * scale)
    left_wing = (cx - 105 * scale, cy - 20 * scale)
    bottom_back = (cx - 30 * scale, cy + 65 * scale)
    fold = (cx + 10 * scale, cy + 5 * scale)
    tail = (cx - 50 * scale, cy + 30 * scale)
    
    # Shadow under plane
    plane_shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(plane_shadow)
    sdraw.polygon([nose, left_wing, fold], fill=(0, 0, 0, 90))
    sdraw.polygon([nose, fold, bottom_back], fill=(0, 0, 0, 110))
    plane_shadow = plane_shadow.filter(ImageFilter.GaussianBlur(size * 0.012))
    img = Image.alpha_composite(img, plane_shadow)
    
    # Main Wings (Crisp White & Shaded Azure)
    edraw.polygon([nose, left_wing, fold], fill=(255, 255, 255, 255))
    edraw.polygon([nose, fold, bottom_back], fill=(215, 240, 255, 255))
    edraw.polygon([tail, bottom_back, fold], fill=(160, 215, 250, 255))
    
    # Specular lens glint
    glint_size = size * 0.08
    edraw.ellipse([nose[0] - glint_size/2, nose[1] - glint_size/2, nose[0] + glint_size/2, nose[1] + glint_size/2], 
                  fill=(255, 255, 255, 140))
    
    img = Image.alpha_composite(img, emblem_layer)
    return img

def create_adaptive_foreground(size=432):
    # 432x432 foreground for Android adaptive icon
    # Safe zone is the central 66% (circle of radius ~ size * 0.33 = 142px)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    
    center = size / 2
    
    # Aperture Ring
    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    
    radius_outer = size * 0.28
    radius_inner = size * 0.21
    
    num_blades = 8
    for i in range(num_blades):
        angle = i * (2 * math.pi / num_blades)
        p1 = (center + radius_inner * math.cos(angle), center + radius_inner * math.sin(angle))
        p2 = (center + radius_outer * math.cos(angle + 0.4), center + radius_outer * math.sin(angle + 0.4))
        p3 = (center + radius_outer * math.cos(angle + 0.7), center + radius_outer * math.sin(angle + 0.7))
        p4 = (center + radius_inner * math.cos(angle + 0.3), center + radius_inner * math.sin(angle + 0.3))
        
        blade_color = (255, 255, 255, 45) if i % 2 == 0 else (100, 220, 255, 60)
        draw.polygon([p1, p2, p3, p4], fill=blade_color)
        
    draw.ellipse([center - radius_outer, center - radius_outer, center + radius_outer, center + radius_outer], 
                 outline=(255, 255, 255, 90), width=int(size * 0.007))
    draw.ellipse([center - radius_inner, center - radius_inner, center + radius_inner, center + radius_inner], 
                 outline=(100, 220, 255, 110), width=int(size * 0.006))
    
    img = Image.alpha_composite(img, overlay)
    
    # Glow
    glow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow_layer)
    gdraw.ellipse([center - radius_inner*1.2, center - radius_inner*1.2, center + radius_inner*1.2, center + radius_inner*1.2], 
                  fill=(0, 210, 255, 140))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(size * 0.035))
    img = Image.alpha_composite(img, glow_layer)
    
    # Plane
    emblem_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    edraw = ImageDraw.Draw(emblem_layer)
    
    scale = size * 0.0012
    cx = center
    cy = center
    nose = (cx + 85 * scale, cy - 65 * scale)
    left_wing = (cx - 105 * scale, cy - 20 * scale)
    bottom_back = (cx - 30 * scale, cy + 65 * scale)
    fold = (cx + 10 * scale, cy + 5 * scale)
    tail = (cx - 50 * scale, cy + 30 * scale)
    
    edraw.polygon([nose, left_wing, fold], fill=(255, 255, 255, 255))
    edraw.polygon([nose, fold, bottom_back], fill=(215, 240, 255, 255))
    edraw.polygon([tail, bottom_back, fold], fill=(160, 215, 250, 255))
    
    img = Image.alpha_composite(img, emblem_layer)
    return img

def create_adaptive_background(size=432):
    bg = Image.new("RGBA", (size, size))
    for y in range(size):
        t = y / size
        r = int(10 * (1 - t) + 0 * t)
        g = int(25 * (1 - t) + 130 * t)
        b = int(60 * (1 - t) + 220 * t)
        for x in range(size):
            dx = (x - size / 2) / (size / 2)
            dy = (y - size / 3) / (size / 2)
            dist = math.sqrt(dx * dx + dy * dy)
            glow = max(0.0, 1.0 - dist * 0.8) * 40
            nr = min(255, int(r + glow * 0.4))
            ng = min(255, int(g + glow * 0.8))
            nb = min(255, int(b + glow * 1.2))
            bg.putpixel((x, y), (nr, ng, nb, 255))
    return bg

if __name__ == "__main__":
    base_dir = "/home/nandha/Desktop/photos_app/telecloud_photos"
    
    # 1. Master Icon (1024x1024)
    master = create_master_icon(1024)
    os.makedirs(f"{base_dir}/assets/icon", exist_ok=True)
    master.save(f"{base_dir}/assets/icon/app_icon.png")
    print("Generated master icon: assets/icon/app_icon.png")
    
    # 2. Android Legacy Mipmap Icons
    densities = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }
    
    for folder, dim in densities.items():
        res_dir = f"{base_dir}/android/app/src/main/res/mipmap-{folder}"
        os.makedirs(res_dir, exist_ok=True)
        
        # Legacy full-bleed squircle icon
        resized = master.resize((dim, dim), Image.Resampling.LANCZOS)
        resized.save(f"{res_dir}/ic_launcher.png")
        resized.save(f"{res_dir}/ic_launcher_round.png")
        print(f"Generated {folder}: {dim}x{dim}")
        
    # 3. Android Adaptive Foreground & Background Icons
    adaptive_densities = {
        "mdpi": 108,
        "hdpi": 162,
        "xhdpi": 216,
        "xxhdpi": 324,
        "xxxhdpi": 432,
    }
    
    master_fg = create_adaptive_foreground(432)
    master_bg = create_adaptive_background(432)
    
    for folder, dim in adaptive_densities.items():
        res_dir = f"{base_dir}/android/app/src/main/res/mipmap-{folder}"
        os.makedirs(res_dir, exist_ok=True)
        
        fg_resized = master_fg.resize((dim, dim), Image.Resampling.LANCZOS)
        fg_resized.save(f"{res_dir}/ic_launcher_foreground.png")
        
        bg_resized = master_bg.resize((dim, dim), Image.Resampling.LANCZOS)
        bg_resized.save(f"{res_dir}/ic_launcher_background.png")
        print(f"Generated adaptive fg/bg for {folder}: {dim}x{dim}")
        
    # 4. Create mipmap-anydpi-v26 XML files
    v26_dir = f"{base_dir}/android/app/src/main/res/mipmap-anydpi-v26"
    os.makedirs(v26_dir, exist_ok=True)
    
    xml_content = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
"""
    with open(f"{v26_dir}/ic_launcher.xml", "w") as f:
        f.write(xml_content)
        
    with open(f"{v26_dir}/ic_launcher_round.xml", "w") as f:
        f.write(xml_content)
        
    print("Created mipmap-anydpi-v26 adaptive icon XML definitions.")
