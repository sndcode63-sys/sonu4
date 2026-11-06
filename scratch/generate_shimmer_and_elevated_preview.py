import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

brain_dir = r"C:\Users\sk460\.gemini\antigravity\brain\22d11365-799f-4b35-a997-a30b2f31a218"
os.makedirs(brain_dir, exist_ok=True)

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

# -------------------------------------------------------------
# DUAL PHONE SHOWCASE (Phone 1: Deep Elevated White Cards, Phone 2: Shimmer Skeleton Animated)
# Canvas: 1800 x 1920
# -------------------------------------------------------------
CW, CH = 1800, 1920
canvas = Image.new("RGB", (CW, CH), (242, 245, 249))
c_draw = ImageDraw.Draw(canvas)

# Title Header
c_draw.text((CW//2 - 430, 40), "DigiNiwas Buyer Property Details — Luxury Elevation & Shimmer", fill=(15, 23, 42), font=get_font(27, True))
c_draw.text((CW//2 - 380, 84), "Pure White Tactile Elevated Cards  •  Smooth Scroll Tabs  •  Full Screen Skeleton Shimmer State", fill=(71, 85, 105), font=get_font(14, False))

PW, PH = 800, 1680
SW, SH = 740, 1580
corner_r = 50

# Colors
C_PRIMARY = (0, 122, 94)       # DigiNiwas Emerald
C_PRIMARY_LIGHT = (232, 247, 242)
C_INK = (15, 23, 42)
C_BODY = (71, 85, 105)
C_MUTED = (148, 163, 184)
C_CHIP_BG = (248, 250, 252)
C_BORDER = (232, 238, 244)
C_ACCENT_RED = (225, 29, 72)

# Shimmer Colors (from lib/core/utils/shimmer.dart: Color(0xFFE9F1EE) & Color(0xFFFFFFFF))
C_SHIMMER_BASE = (233, 241, 238)
C_SHIMMER_HIGH = (248, 252, 250)

def draw_deep_elevated_card(draw_obj, box, radius=18, fill_color=(255, 255, 255), border_color=(230, 236, 243)):
    x0, y0, x1, y1 = box
    # Multi-layer soft elevation shadow
    draw_obj.rounded_rectangle([x0 - 2, y0 + 3, x1 + 2, y1 + 7], radius=radius + 2, fill=(218, 226, 236))
    draw_obj.rounded_rectangle([x0 - 1, y0 + 1, x1 + 1, y1 + 4], radius=radius + 1, fill=(225, 232, 240))
    draw_obj.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=fill_color, outline=border_color, width=1)

def draw_single_phone(screen_img, x_offset, label_text, badge_color=C_PRIMARY):
    # Shadow
    shadow = Image.new("RGBA", (PW, PH), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.rounded_rectangle([0, 16, PW, PH], radius=corner_r, fill=(15, 23, 42, 45))
    shadow = shadow.filter(ImageFilter.GaussianBlur(20))
    canvas.paste(shadow, (x_offset, 145), shadow)

    # Frame body (Titanium)
    c_draw.rounded_rectangle([x_offset, 145, x_offset + PW, 145 + PH], radius=corner_r, fill=(26, 30, 36), outline=(65, 75, 88), width=4)
    
    # Mask rounded screen
    mask = Image.new("L", (SW, SH), 0)
    m_draw = ImageDraw.Draw(mask)
    m_draw.rounded_rectangle([0, 0, SW, SH], radius=40, fill=255)
    canvas.paste(screen_img, (x_offset + 30, 145 + 50), mask)

    # Label Pill below phone
    c_draw.rounded_rectangle([x_offset + PW//2 - 180, 145 + PH + 20, x_offset + PW//2 + 180, 145 + PH + 62], radius=21, fill=(255, 255, 255), outline=badge_color, width=2)
    c_draw.text((x_offset + PW//2 - 160, 145 + PH + 31), label_text, fill=badge_color, font=get_font(13, True))


# =============================================================
# PHONE 1: LOADED SCREEN WITH DEEP LUXURY ELEVATED CARDS
# =============================================================
s1 = Image.new("RGB", (SW, SH), (242, 245, 249))
d1 = ImageDraw.Draw(s1)

# Status bar
d1.text((32, 12), "9:41", fill=(255, 255, 255), font=get_font(13, True))
d1.rounded_rectangle([SW//2 - 55, 8, SW//2 + 55, 32], radius=12, fill=(0, 0, 0))
d1.text((SW - 100, 12), "📶 5G 🔋", fill=(255, 255, 255), font=get_font(11, True))

# Hero
hero_h = 320
try:
    hero_raw = Image.open("assets/images/compare_home.png").convert("RGB")
    hero_img = hero_raw.resize((SW, hero_h), Image.Resampling.LANCZOS)
    s1.paste(hero_img, (0, 0))
except Exception:
    d1.rectangle([0, 0, SW, hero_h], fill=(45, 55, 72))

# Top gradient
top_s = Image.new("RGBA", (SW, 60), (0, 0, 0, 0))
ts_draw = ImageDraw.Draw(top_s)
for y in range(60): ts_draw.line([(0, y), (SW, y)], fill=(0, 0, 0, int(110 * (1 - y/60))))
s1.paste(top_s, (0, 0), top_s)

# Re-draw status
d1.text((32, 12), "9:41", fill=(255, 255, 255), font=get_font(13, True))
d1.rounded_rectangle([SW//2 - 55, 8, SW//2 + 55, 32], radius=12, fill=(0, 0, 0))
d1.text((SW - 100, 12), "📶 5G 🔋", fill=(255, 255, 255), font=get_font(11, True))

# Floating Navigation
d1.ellipse([20, 48, 60, 88], fill=(255, 255, 255, 245))
d1.text((32, 58), "←", fill=C_INK, font=get_font(20, True))
d1.ellipse([SW - 104, 48, SW - 64, 88], fill=(255, 255, 255, 245))
d1.text((SW - 92, 60), "♥", fill=C_ACCENT_RED, font=get_font(17, True))
d1.ellipse([SW - 56, 48, SW - 16, 88], fill=(255, 255, 255, 245))
d1.text((SW - 44, 60), "↗", fill=C_INK, font=get_font(17, True))

# Floating Badges
d1.rounded_rectangle([20, hero_h - 44, 110, hero_h - 14], radius=15, fill=(15, 23, 42, 220))
d1.text((32, hero_h - 35), "📷 1 / 14 Photos", fill=(255, 255, 255), font=get_font(10.5, True))
d1.rounded_rectangle([SW - 145, hero_h - 44, SW - 20, hero_h - 14], radius=15, fill=(255, 255, 255, 245))
d1.text((SW - 132, hero_h - 35), "▶ View Video • 360°", fill=C_INK, font=get_font(10.5, True))

# DEEP ELEVATED HEADER CARD
y1 = hero_h - 12
draw_deep_elevated_card(d1, [16, y1, SW - 16, y1 + 252], radius=22)

hy = y1 + 18
# Price & Trend Badge
d1.text((32, hy), "₹85,00,000", fill=C_PRIMARY, font=get_font(25, True))
d1.text((195, hy + 6), "(@ ₹ 5,862 / sq.ft)", fill=C_MUTED, font=get_font(11, False))
d1.rounded_rectangle([SW - 215, hy + 2, SW - 32, hy + 28], radius=12, fill=(255, 241, 242), outline=(254, 205, 211))
d1.text((SW - 202, hy + 7), "📈 2.5% Higher than last month", fill=C_ACCENT_RED, font=get_font(9.5, True))

hy += 38
# Title & For Sale Pill
d1.text((32, hy), "Modern 3 BHK Luxury Apartment", fill=C_INK, font=get_font(17.5, True))
d1.rounded_rectangle([SW - 110, hy - 2, SW - 32, hy + 26], radius=12, fill=C_PRIMARY_LIGHT, outline=(167, 243, 208))
d1.text((SW - 98, hy + 3), "🏠 For Sale", fill=C_PRIMARY, font=get_font(10.5, True))

hy += 28
d1.text((32, hy), "📍 Indiranagar, Bengaluru, Karnataka • 450m to Metro", fill=C_BODY, font=get_font(11.5, False))

hy += 26
d1.line([(32, hy), (SW - 32, hy)], fill=(241, 245, 249), width=1)
hy += 12

# TACTILE SPEC CHIPS (Image 2 style)
d1.text((32, hy), "SPECIFICATIONS & HIGHLIGHTS", fill=C_MUTED, font=get_font(9.5, True))
d1.text((SW - 170, hy), "RERA: UPRERAPRJ9921", fill=C_PRIMARY, font=get_font(9.5, True))
hy += 18

chips1 = [("🛏️", "3 Bedrooms"), ("🛁", "2 Bathrooms"), ("📐", "1,450 Sq.Ft."), ("🏢", "5th Floor")]
cx = 32
for icon, label in chips1:
    txt = f"{icon} {label}"
    tw = int(d1.textlength(txt, font=get_font(10.5, True))) + 22
    d1.rounded_rectangle([cx - 1, hy + 1, cx + tw + 1, hy + 32], radius=16, fill=(230, 235, 242)) # micro shadow
    d1.rounded_rectangle([cx, hy, cx + tw, hy + 30], radius=15, fill=C_CHIP_BG, outline=C_BORDER)
    d1.text((cx + 11, hy + 7), txt, fill=C_INK, font=get_font(10.5, True))
    cx += tw + 8

hy += 36
chips2 = [("🧭", "East Facing"), ("🚗", "2 Parking"), ("🛋️", "Semi-Furnished"), ("⚡", "100% Backup")]
cx = 32
for icon, label in chips2:
    txt = f"{icon} {label}"
    tw = int(d1.textlength(txt, font=get_font(10.5, True))) + 22
    if cx + tw > SW - 32: break
    d1.rounded_rectangle([cx - 1, hy + 1, cx + tw + 1, hy + 32], radius=16, fill=(230, 235, 242))
    d1.rounded_rectangle([cx, hy, cx + tw, hy + 30], radius=15, fill=C_CHIP_BG, outline=C_BORDER)
    d1.text((cx + 11, hy + 7), txt, fill=C_INK, font=get_font(10.5, True))
    cx += tw + 8

y1 += 266

# STICKY TABS STRIP
draw_deep_elevated_card(d1, [16, y1, SW - 16, y1 + 46], radius=23)
tabs1 = [("🏠", "Overview", True), ("📍", "Location", False), ("⭐", "Amenities", False), ("📐", "Floor Plan", False), ("💬", "Reviews", False)]
tx = 24
for icon, tname, isAct in tabs1:
    txt = f"{icon} {tname}"
    tw = int(d1.textlength(txt, font=get_font(11, True))) + 22
    if isAct:
        d1.rounded_rectangle([tx, y1 + 7, tx + tw, y1 + 39], radius=16, fill=C_PRIMARY, outline=C_PRIMARY)
        d1.text((tx + 11, y1 + 13), txt, fill=(255, 255, 255), font=get_font(11, True))
    else:
        d1.text((tx + 11, y1 + 14), txt, fill=C_BODY, font=get_font(11, False))
    tx += tw + 8

y1 += 60

# ELEVATED CARD: ABOUT
draw_deep_elevated_card(d1, [16, y1, SW - 16, y1 + 105], radius=20)
d1.rectangle([32, y1 + 16, 36, y1 + 32], fill=C_PRIMARY)
d1.text((44, y1 + 14), "About This Property", fill=C_INK, font=get_font(14, True))
d1.text((SW - 110, y1 + 16), "Read More ›", fill=C_PRIMARY, font=get_font(11, True))
d1.text((32, y1 + 42), "A spacious 3 BHK luxury apartment in prime Indiranagar with double-glazed", fill=C_BODY, font=get_font(11, False))
d1.text((32, y1 + 60), "soundproof balconies, imported Italian marble and 100% verified legal title.", fill=C_BODY, font=get_font(11, False))
d1.text((32, y1 + 78), "Scenic green views and ready for immediate possession.", fill=C_MUTED, font=get_font(10.5, False))

y1 += 120

# ELEVATED CARD: AMENITIES GRID
draw_deep_elevated_card(d1, [16, y1, SW - 16, y1 + 120], radius=20)
d1.rectangle([32, y1 + 16, 36, y1 + 32], fill=C_PRIMARY)
d1.text((44, y1 + 14), "Society Amenities", fill=C_INK, font=get_font(14, True))
d1.text((SW - 110, y1 + 16), "See All (35+) ›", fill=C_PRIMARY, font=get_font(11, True))

amen1 = [("🚗", "Parking"), ("🛡️", "24x7 Safe"), ("🏋️", "Gym"), ("🌳", "Garden"), ("🛗", "High Lift"), ("🏊", "Pool")]
aw = (SW - 64 - 50) // 6
for idx, (ai, an) in enumerate(amen1):
    ax = 32 + idx * (aw + 10)
    d1.rounded_rectangle([ax - 1, y1 + 45, ax + aw + 1, y1 + 94], radius=15, fill=(225, 232, 240))
    d1.rounded_rectangle([ax, y1 + 44, ax + aw, y1 + 92], radius=14, fill=(248, 250, 252), outline=C_BORDER)
    d1.text((ax + aw//2 - 9, y1 + 54), ai, fill=C_PRIMARY, font=get_font(15, False))
    d1.text((ax + 2, y1 + 98), an, fill=C_INK, font=get_font(9.5, True))

y1 += 135

# 2 ELEVATED CARDS: DETAILS & FLOOR PLAN
c_w = (SW - 32 - 12) // 2
c_h = 175
draw_deep_elevated_card(d1, [16, y1, 16 + c_w, y1 + c_h], radius=18)
d1.text((30, y1 + 14), "Property Details", fill=C_INK, font=get_font(13, True))
dt_list = [("🏠 Type", ": Apartment"), ("🧭 Facing", ": East (Vastu)"), ("📐 Built Area", ": 1,450 Sq.Ft."), ("🏢 Floor", ": 5 of 14"), ("⚖️ RERA", ": Verified ✓")]
dy = y1 + 40
for k, v in dt_list:
    d1.text((30, dy), k, fill=C_BODY, font=get_font(9.5, False))
    d1.text((120, dy), v, fill=C_INK, font=get_font(9.5, True))
    dy += 22

fx = 16 + c_w + 12
draw_deep_elevated_card(d1, [fx, y1, fx + c_w, y1 + c_h], radius=18)
d1.text((fx + 14, y1 + 14), "📐 Floor Plan", fill=C_INK, font=get_font(13, True))
d1.text((fx + c_w - 75, y1 + 14), "View Full ›", fill=C_PRIMARY, font=get_font(10, True))
d1.rounded_rectangle([fx + 12, y1 + 40, fx + c_w - 12, y1 + c_h - 14], radius=10, fill=(248, 250, 252), outline=C_BORDER)
d1.rectangle([fx + 22, y1 + 50, fx + c_w - 22, y1 + c_h - 24], outline=(180, 195, 210), width=1)
d1.text((fx + 28, y1 + 60), "Master Bed 14'x12'", fill=(120, 135, 150), font=get_font(8.5, True))
d1.text((fx + 28, y1 + 94), "Living 18'x14'", fill=(120, 135, 150), font=get_font(8.5, True))

# STICKY ELEVATED BOTTOM BAR 1
b_y = SH - 75
d1.rectangle([0, b_y, SW, SH], fill=(255, 255, 255))
d1.line([(0, b_y), (SW, b_y)], fill=(230, 235, 242), width=1)
bw = (SW - 40 - 12) // 2
d1.rounded_rectangle([20, b_y + 12, 20 + bw, b_y + 58], radius=14, fill=(255, 255, 255), outline=C_PRIMARY, width=2)
d1.text((20 + bw//2 - 55, b_y + 24), "📅  Schedule Visit", fill=C_PRIMARY, font=get_font(13, True))
d1.rounded_rectangle([20 + bw + 12, b_y + 12, SW - 20, b_y + 58], radius=14, fill=C_PRIMARY)
d1.text((20 + bw + 12 + bw//2 - 42, b_y + 24), "📞  Call Now", fill=(255, 255, 255), font=get_font(13, True))
d1.rounded_rectangle([SW//2 - 50, SH - 10, SW//2 + 50, SH - 5], radius=2, fill=(180, 190, 200))


# =============================================================
# PHONE 2: SKELETON SHIMMER ANIMATED LOADING STATE
# =============================================================
s2 = Image.new("RGB", (SW, SH), (242, 245, 249))
d2 = ImageDraw.Draw(s2)

# Shimmer Status Bar
d2.text((32, 12), "9:41", fill=(160, 175, 170), font=get_font(13, True))
d2.rounded_rectangle([SW//2 - 55, 8, SW//2 + 55, 32], radius=12, fill=(0, 0, 0))
d2.text((SW - 100, 12), "📶 5G 🔋", fill=(160, 175, 170), font=get_font(11, True))

# Shimmer Hero Block (Simulating gradient wave)
d2.rounded_rectangle([0, 0, SW, 310], radius=24, fill=C_SHIMMER_BASE)
# Shimmer lighter wave strip in center
d2.rounded_rectangle([SW//3, 0, 2*SW//3, 310], radius=24, fill=C_SHIMMER_HIGH)

# Shimmer Floating round action placeholders
d2.ellipse([20, 48, 60, 88], fill=(255, 255, 255, 220))
d2.ellipse([SW - 104, 48, SW - 64, 88], fill=(255, 255, 255, 220))
d2.ellipse([SW - 56, 48, SW - 16, 88], fill=(255, 255, 255, 220))

# Shimmer bottom pills
d2.rounded_rectangle([20, 260, 110, 290], radius=15, fill=(255, 255, 255, 230))
d2.rounded_rectangle([SW - 150, 260, SW - 20, 290], radius=15, fill=(255, 255, 255, 230))

sy = 300
# Shimmer Elevated Header Card
draw_deep_elevated_card(d2, [16, sy, SW - 16, sy + 252], radius=22)

# Shimmer Price Block & Tag
d2.rounded_rectangle([32, sy + 20, 200, sy + 54], radius=10, fill=C_SHIMMER_BASE)
d2.rounded_rectangle([SW - 180, sy + 20, SW - 32, sy + 48], radius=14, fill=C_SHIMMER_BASE)

# Shimmer Title Lines
d2.rounded_rectangle([32, sy + 68, SW - 80, sy + 90], radius=8, fill=C_SHIMMER_BASE)
d2.rounded_rectangle([32, sy + 100, SW - 180, sy + 118], radius=8, fill=C_SHIMMER_HIGH)

d2.line([(32, sy + 130), (SW - 32, sy + 130)], fill=(241, 245, 249), width=1)

# Shimmer Rounded Spec Chips (Image 2 style)
scx = 32
for sw_len in [120, 115, 125, 95]:
    d2.rounded_rectangle([scx, sy + 150, scx + sw_len, sy + 180], radius=15, fill=C_SHIMMER_BASE)
    scx += sw_len + 8

scx = 32
for sw_len in [110, 135, 120]:
    d2.rounded_rectangle([scx, sy + 190, scx + sw_len, sy + 220], radius=15, fill=C_SHIMMER_BASE)
    scx += sw_len + 8

sy += 266

# Shimmer Tabs
draw_deep_elevated_card(d2, [16, sy, SW - 16, sy + 46], radius=23)
stx = 24
for tw_len in [95, 105, 95, 110, 95]:
    d2.rounded_rectangle([stx, sy + 8, stx + tw_len, sy + 38], radius=15, fill=C_SHIMMER_BASE)
    stx += tw_len + 8

sy += 60

# Shimmer Trust Shield Card
draw_deep_elevated_card(d2, [16, sy, SW - 16, sy + 140], radius=20, border_color=(200, 230, 220))
d2.rounded_rectangle([32, sy + 16, 220, sy + 38], radius=8, fill=C_SHIMMER_BASE)
# 4 Shimmer mini boxes
st_w = (SW - 64 - 10) // 2
for bi in range(4):
    bc = bi % 2
    br = bi // 2
    bx = 32 + bc * (st_w + 10)
    by_pos = sy + 50 + br * 40
    d2.rounded_rectangle([bx, by_pos, bx + st_w, by_pos + 34], radius=10, fill=C_SHIMMER_HIGH)

sy += 155

# Shimmer Amenities Card
draw_deep_elevated_card(d2, [16, sy, SW - 16, sy + 120], radius=20)
d2.rounded_rectangle([32, sy + 16, 180, sy + 34], radius=8, fill=C_SHIMMER_BASE)
saw = (SW - 64 - 50) // 6
for si in range(6):
    sx_pos = 32 + si * (saw + 10)
    d2.rounded_rectangle([sx_pos, sy + 44, sx_pos + saw, sy + 92], radius=14, fill=C_SHIMMER_BASE)
    d2.rounded_rectangle([sx_pos + 4, sy + 98, sx_pos + saw - 4, sy + 108], radius=4, fill=C_SHIMMER_HIGH)

sy += 135

# Shimmer 2 Details Cards
draw_deep_elevated_card(d2, [16, sy, 16 + c_w, sy + 175], radius=18)
d2.rounded_rectangle([30, sy + 14, 130, sy + 32], radius=6, fill=C_SHIMMER_BASE)
for l in range(4):
    d2.rounded_rectangle([30, sy + 45 + l*24, 16 + c_w - 30, sy + 57 + l*24], radius=6, fill=C_SHIMMER_HIGH)

draw_deep_elevated_card(d2, [fx, sy, fx + c_w, sy + 175], radius=18)
d2.rounded_rectangle([fx + 14, sy + 14, fx + 120, sy + 32], radius=6, fill=C_SHIMMER_BASE)
d2.rounded_rectangle([fx + 12, sy + 40, fx + c_w - 12, sy + 160], radius=10, fill=C_SHIMMER_BASE)

# Shimmer Fixed Bottom Bar
d2.rectangle([0, b_y, SW, SH], fill=(255, 255, 255))
d2.line([(0, b_y), (SW, b_y)], fill=(230, 235, 242), width=1)
d2.rounded_rectangle([20, b_y + 12, 20 + bw, b_y + 58], radius=14, fill=C_SHIMMER_BASE)
d2.rounded_rectangle([20 + bw + 12, b_y + 12, SW - 20, b_y + 58], radius=14, fill=C_SHIMMER_BASE)
d2.rounded_rectangle([SW//2 - 50, SH - 10, SW//2 + 50, SH - 5], radius=2, fill=(200, 210, 215))

# -------------------------------------------------------------
# PASTE BOTH PHONES INTO DUAL SHOWCASE CANVAS
# -------------------------------------------------------------
draw_single_phone(s1, 60, "📱 Loaded: Deeper 3D Elevated Cards", C_PRIMARY)
draw_single_phone(s2, 940, "🌊 Shimmer: Animated Full Screen Skeleton", (21, 128, 61))

dual_preview_path = os.path.join(brain_dir, "buyer_details_dual_phone_preview.png")
canvas.save(dual_preview_path, quality=95)
print("Saved Luxury Elevated + Shimmer Dual Phone Mockup to:", dual_preview_path)
