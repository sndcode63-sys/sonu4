import os
from PIL import Image, ImageDraw, ImageFont

brain_dir = r"C:\Users\sk460\.gemini\antigravity\brain\22d11365-799f-4b35-a997-a30b2f31a218"
os.makedirs(brain_dir, exist_ok=True)

# Try font loading with fallback
def get_font(size, bold=False):
    font_names = [
        "C:\\Windows\\Fonts\\segoeuib.ttf" if bold else "C:\\Windows\\Fonts\\segoeui.ttf",
        "C:\\Windows\\Fonts\\arialbd.ttf" if bold else "C:\\Windows\\Fonts\\arial.ttf",
        "C:\\Windows\\Fonts\\tahomabd.ttf" if bold else "C:\\Windows\\Fonts\\tahoma.ttf",
    ]
    for fn in font_names:
        if os.path.exists(fn):
            try:
                return ImageFont.truetype(fn, size)
            except Exception:
                pass
    return ImageFont.load_default()

# 1. GENERATE 8-CARD SHOWCASE GRID (2 columns x 4 rows)
w, h = 900, 1400
img = Image.new("RGB", (w, h), (248, 250, 252))
draw = ImageDraw.Draw(img)

# Title Header
draw.rectangle([0, 0, w, 110], fill=(0, 91, 72))
draw.text((30, 22), "DigiNiwas Partner Digital Cards - 8 Designer Styles", fill=(255, 255, 255), font=get_font(28, True))
draw.text((30, 64), "Custom Phone & WhatsApp Numbers • Office Address • Direct Device Download", fill=(153, 246, 228), font=get_font(16, False))

cards_meta = [
    ("1. Classic Emerald", "Vertical Portrait • Green/Gold Elite", (0, 91, 72), (16, 185, 129), True),
    ("2. Royal Dark Luxury", "Horizontal • Obsidian/Emerald Villa", (9, 41, 33), (245, 158, 11), False),
    ("3. Corporate Minimal", "Horizontal • Crisp Clean White & Slate", (241, 245, 249), (0, 91, 72), False),
    ("4. Midnight Gold Executive", "Horizontal • Obsidian & Gold Foil VIP", (20, 20, 22), (212, 175, 55), False),
    ("5. Sapphire Blue Elite", "Vertical • Royal Blue & Modern Platinum", (29, 78, 216), (37, 99, 235), True),
    ("6. Sunset Amber Prestige", "Horizontal • Warm Terracotta & Amber Glow", (154, 52, 18), (234, 88, 12), False),
    ("7. Slate Titanium Ultra", "Horizontal • Architectural Slate & Neon Teal", (30, 41, 59), (6, 182, 212), False),
    ("8. Royal Ivory & Forest", "Vertical • Matte Ivory & Deep Forest Green", (250, 247, 242), (21, 128, 61), True),
]

col_w = 405
row_h = 295
margin_x = 30
margin_y = 135

for idx, (title, desc, bg_color, accent, is_vert) in enumerate(cards_meta):
    c = idx % 2
    r = idx // 2
    x0 = margin_x + c * (col_w + 30)
    y0 = margin_y + r * (row_h + 20)
    x1 = x0 + col_w
    y1 = y0 + row_h

    # Card base
    draw.rounded_rectangle([x0, y0, x1, y1], radius=16, fill=bg_color, outline=(226, 232, 240) if bg_color[0]>200 else (40, 50, 60), width=2)
    
    # Text color
    text_color = (255, 255, 255) if bg_color[0] < 150 else (16, 34, 43)
    muted_color = (200, 215, 220) if bg_color[0] < 150 else (94, 112, 118)

    # Accent Header Strip
    draw.rounded_rectangle([x0 + 16, y0 + 16, x0 + 130, y0 + 38], radius=6, fill=accent)
    draw.text((x0 + 24, y0 + 19), "DIGINIWAS PARTNER", fill=(255, 255, 255), font=get_font(10, True))

    # Title & Subtitle
    draw.text((x0 + 16, y0 + 48), title, fill=text_color, font=get_font(18, True))
    draw.text((x0 + 16, y0 + 74), desc, fill=muted_color, font=get_font(12, False))

    # Partner details demo
    draw.rectangle([x0 + 16, y0 + 102, x1 - 16, y0 + 104], fill=accent)
    draw.text((x0 + 16, y0 + 115), "Rahul Sharma • Sharma Properties", fill=text_color, font=get_font(14, True))
    
    # Phone, WhatsApp, City tags
    draw.text((x0 + 16, y0 + 142), "📞 Call: +91 98765 43210", fill=accent, font=get_font(12, True))
    draw.text((x0 + 16, y0 + 164), "💬 WhatsApp: +91 98765 43210", fill=(37, 211, 102), font=get_font(12, True))
    draw.text((x0 + 16, y0 + 186), "📍 Address: Sector 62, Noida, NCR", fill=text_color, font=get_font(12, False))
    draw.text((x0 + 16, y0 + 208), "🏷️ Code: DNP-8821  •  Residential & Commercial", fill=muted_color, font=get_font(11, False))

    # Mini QR placeholder
    draw.rounded_rectangle([x1 - 76, y1 - 76, x1 - 16, y1 - 16], radius=8, fill=(255, 255, 255), outline=accent, width=2)
    draw.text((x1 - 66, y1 - 54), "QR", fill=(0, 91, 72), font=get_font(18, True))

    # Badge Pill at bottom
    orient_badge = "Vertical Portrait" if is_vert else "Horizontal Landscape"
    draw.rounded_rectangle([x0 + 16, y1 - 42, x0 + 180, y1 - 16], radius=6, fill=(255, 255, 255, 30) if bg_color[0]<150 else (0, 0, 0, 15), outline=accent)
    draw.text((x0 + 24, y1 - 36), orient_badge, fill=text_color, font=get_font(11, True))

showcase_path = os.path.join(brain_dir, "showcase_8_card_styles.png")
img.save(showcase_path, quality=95)
print("Saved showcase to", showcase_path)

# 2. GENERATE SCREEN VIEW WITH EDIT DIALOG PREVIEW
sw, sh = 800, 1000
screen = Image.new("RGB", (sw, sh), (248, 250, 252))
sdraw = ImageDraw.Draw(screen)

# Top Bar
sdraw.rectangle([0, 0, sw, 80], fill=(255, 255, 255))
sdraw.text((25, 28), "←  Share Your Digital Card", fill=(16, 34, 43), font=get_font(20, True))
sdraw.rounded_rectangle([sw - 145, 24, sw - 25, 56], radius=16, fill=(232, 247, 242), outline=(153, 246, 228))
sdraw.text((sw - 132, 31), "✓ Partner Verified", fill=(0, 91, 72), font=get_font(12, True))

# Style selector chips
sdraw.text((25, 100), "Card Styles (8 Options)", fill=(16, 34, 43), font=get_font(14, True))
chips = ["#1 Emerald (Selected)", "#2 Royal Dark", "#3 Minimal", "#4 Midnight Gold", "#5 Sapphire", "#6 Amber", "#7 Titanium", "#8 Ivory"]
cx = 25
for i, ch in enumerate(chips[:4]):
    sel = (i == 0)
    bg = (0, 91, 72) if sel else (255, 255, 255)
    fg = (255, 255, 255) if sel else (16, 34, 43)
    sdraw.rounded_rectangle([cx, 130, cx + 175, 165], radius=18, fill=bg, outline=(0, 91, 72) if sel else (226, 232, 240), width=1)
    sdraw.text((cx + 14, 138), ch, fill=fg, font=get_font(12, True))
    cx += 185

# Edit Info Bar
sdraw.rounded_rectangle([25, 185, sw - 25, 225], radius=12, fill=(241, 245, 249), outline=(226, 232, 240))
sdraw.text((40, 195), "📞 Call: +91 98765 43210  •  💬 WA: +91 98765 43210  •  📍 Noida, NCR", fill=(16, 34, 43), font=get_font(12, True))
sdraw.rounded_rectangle([sw - 110, 191, sw - 35, 219], radius=8, fill=(255, 255, 255), outline=(0, 91, 72))
sdraw.text((sw - 98, 197), "✏️ Edit Info", fill=(0, 91, 72), font=get_font(11, True))

# Live Card Simulation
sdraw.rounded_rectangle([150, 245, sw - 150, 520], radius=18, fill=(0, 91, 72), outline=(153, 246, 228), width=2)
sdraw.text((180, 275), "DIGINIWAS VERIFIED PARTNER", fill=(153, 246, 228), font=get_font(12, True))
sdraw.text((180, 305), "Rahul Sharma", fill=(255, 255, 255), font=get_font(24, True))
sdraw.text((180, 340), "Sharma Properties  •  DNP-8821", fill=(255, 215, 0), font=get_font(14, True))
sdraw.text((180, 385), "📞 Call: +91 98765 43210", fill=(255, 255, 255), font=get_font(13, False))
sdraw.text((180, 412), "💬 WhatsApp: +91 98765 43210", fill=(153, 246, 228), font=get_font(13, True))
sdraw.text((180, 439), "📍 Sector 62, Noida, Uttar Pradesh, NCR", fill=(200, 220, 215), font=get_font(13, False))
sdraw.rounded_rectangle([sw - 235, 425, sw - 170, 495], radius=8, fill=(255, 255, 255))
sdraw.text((sw - 215, 450), "QR", fill=(0, 91, 72), font=get_font(20, True))

# Quick Share Circles
sdraw.text((25, 545), "Choose how you want to share", fill=(16, 34, 43), font=get_font(15, True))
actions = [
    ("WhatsApp", (37, 211, 102)),
    ("Facebook", (24, 119, 242)),
    ("Copy Link", (0, 91, 72)),
    ("More", (71, 85, 105))
]
sx = 70
for name, color in actions:
    sdraw.ellipse([sx, 580, sx + 55, 635], fill=color)
    sdraw.text((sx + 6, 645), name, fill=(16, 34, 43), font=get_font(12, True))
    sx += 180

# Primary Direct Download Button
sdraw.rounded_rectangle([25, 695, sw - 25, 750], radius=16, fill=(10, 60, 50))
sdraw.text((230, 712), "⬇  Download Card (Direct to Device)", fill=(255, 255, 255), font=get_font(16, True))

# Modal Overlay: Edit Card Details Sheet
sdraw.rectangle([0, 770, sw, sh], fill=(255, 255, 255))
sdraw.rounded_rectangle([sw//2 - 25, 778, sw//2 + 25, 783], radius=3, fill=(200, 200, 200))
sdraw.text((30, 795), "Edit Card Details (Phone, WhatsApp, Address)", fill=(16, 34, 43), font=get_font(17, True))
sdraw.text((30, 825), "Instant preview update • Saves directly to downloaded card", fill=(94, 112, 118), font=get_font(12, False))

# Input 1 & 2 demo
sdraw.rounded_rectangle([30, 855, sw//2 - 15, 905], radius=10, fill=(248, 250, 252), outline=(0, 91, 72), width=2)
sdraw.text((45, 872), "📞 +91 98765 43210 (Calling)", fill=(16, 34, 43), font=get_font(13, True))

sdraw.rounded_rectangle([sw//2 + 15, 855, sw - 30, 905], radius=10, fill=(248, 250, 252), outline=(37, 211, 102), width=2)
sdraw.text((sw//2 + 30, 872), "💬 +91 98765 43210 (WhatsApp)", fill=(16, 34, 43), font=get_font(13, True))

# Save Button inside sheet
sdraw.rounded_rectangle([30, 925, sw - 30, 975], radius=14, fill=(0, 91, 72))
sdraw.text((290, 942), "Save & Update Card Details", fill=(255, 255, 255), font=get_font(15, True))

screen_path = os.path.join(brain_dir, "preview_interactive_flow.png")
screen.save(screen_path, quality=95)
print("Saved screen preview to", screen_path)
