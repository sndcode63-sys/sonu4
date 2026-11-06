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
# DUAL PHONE SHOWCASE (CLEAN WHITE CARDS WITH SOFT LUXURY ELEVATIONS)
# Canvas: 1800 x 1920
# -------------------------------------------------------------
CW, CH = 1800, 1920
canvas = Image.new("RGB", (CW, CH), (243, 246, 250)) # Studio ambient light grey
c_draw = ImageDraw.Draw(canvas)

# Title Header
c_draw.text((CW//2 - 420, 42), "DigiNiwas Buyer Property Details — Professional Edition", fill=(15, 23, 42), font=get_font(27, True))
c_draw.text((CW//2 - 340, 85), "Pristine White Background  •  Elevated Floating Cards  •  Image-2 Spec Chips  •  Trust Shield", fill=(71, 85, 105), font=get_font(14, False))

PW, PH = 800, 1680
SW, SH = 740, 1580
corner_r = 50

# Colors
C_PRIMARY = (0, 122, 94)       # DigiNiwas signature
C_PRIMARY_LIGHT = (232, 247, 242)
C_INK = (15, 23, 42)
C_BODY = (71, 85, 105)
C_MUTED = (148, 163, 184)
C_CHIP_BG = (248, 250, 252)    # Image 2 style chips
C_BORDER = (235, 240, 245)
C_ACCENT_RED = (225, 29, 72)

def draw_elevated_card(draw_obj, box, radius=16, fill_color=(255, 255, 255), border_color=(235, 240, 245)):
    x0, y0, x1, y1 = box
    # Soft drop shadow simulation: 2 subtle outer lines
    draw_obj.rounded_rectangle([x0 - 1, y0 + 1, x1 + 1, y1 + 3], radius=radius + 1, fill=(230, 235, 242))
    draw_obj.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=fill_color, outline=border_color, width=1)

def draw_single_phone(screen_img, x_offset, label_text):
    # Shadow
    shadow = Image.new("RGBA", (PW, PH), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.rounded_rectangle([0, 14, PW, PH], radius=corner_r, fill=(15, 23, 42, 40))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    canvas.paste(shadow, (x_offset, 145), shadow)

    # Frame body (Titanium)
    c_draw.rounded_rectangle([x_offset, 145, x_offset + PW, 145 + PH], radius=corner_r, fill=(28, 32, 38), outline=(70, 78, 92), width=4)
    
    # Mask rounded screen
    mask = Image.new("L", (SW, SH), 0)
    m_draw = ImageDraw.Draw(mask)
    m_draw.rounded_rectangle([0, 0, SW, SH], radius=40, fill=255)
    canvas.paste(screen_img, (x_offset + 30, 145 + 50), mask)

    # Label Pill below phone
    c_draw.rounded_rectangle([x_offset + PW//2 - 180, 145 + PH + 20, x_offset + PW//2 + 180, 145 + PH + 62], radius=21, fill=(255, 255, 255), outline=C_PRIMARY, width=2)
    c_draw.text((x_offset + PW//2 - 160, 145 + PH + 31), label_text, fill=C_PRIMARY, font=get_font(13, True))


# =============================================================
# SCREEN 1: (OVERVIEW VIEW - WHITE ELEVATED CARDS + SPEC CHIPS)
# =============================================================
s1 = Image.new("RGB", (SW, SH), (244, 246, 249)) # Clean off-white canvas
d1 = ImageDraw.Draw(s1)

# Status bar
d1.text((32, 12), "9:41", fill=(255, 255, 255), font=get_font(13, True))
d1.rounded_rectangle([SW//2 - 55, 8, SW//2 + 55, 32], radius=12, fill=(0, 0, 0))
d1.text((SW - 100, 12), "📶 5G 🔋", fill=(255, 255, 255), font=get_font(11, True))

# Hero 1
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

# Re-draw status text
d1.text((32, 12), "9:41", fill=(255, 255, 255), font=get_font(13, True))
d1.rounded_rectangle([SW//2 - 55, 8, SW//2 + 55, 32], radius=12, fill=(0, 0, 0))
d1.text((SW - 100, 12), "📶 5G 🔋", fill=(255, 255, 255), font=get_font(11, True))

# Floating Navigation
d1.ellipse([20, 48, 60, 88], fill=(255, 255, 255, 240))
d1.text((32, 58), "←", fill=C_INK, font=get_font(20, True))
d1.ellipse([SW - 104, 48, SW - 64, 88], fill=(255, 255, 255, 240))
d1.text((SW - 92, 60), "♥", fill=C_ACCENT_RED, font=get_font(17, True))
d1.ellipse([SW - 56, 48, SW - 16, 88], fill=(255, 255, 255, 240))
d1.text((SW - 44, 60), "↗", fill=C_INK, font=get_font(17, True))

# Floating Badges
d1.rounded_rectangle([20, hero_h - 44, 110, hero_h - 14], radius=15, fill=(15, 23, 42, 220))
d1.text((32, hero_h - 35), "📷 1 / 14 Photos", fill=(255, 255, 255), font=get_font(10.5, True))
d1.rounded_rectangle([SW - 145, hero_h - 44, SW - 20, hero_h - 14], radius=15, fill=(255, 255, 255, 240))
d1.text((SW - 132, hero_h - 35), "▶ View Video • 360°", fill=C_INK, font=get_font(10.5, True))

# ------------------------------------------------------------------
# MAIN HEADER CARD: PURE WHITE WITH SOFT ELEVATION
# ------------------------------------------------------------------
y1 = hero_h - 10
draw_elevated_card(d1, [16, y1, SW - 16, y1 + 250], radius=20)

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

# IMAGE 2 STYLE CHIPS INSIDE ELEVATED CARD
d1.text((32, hy), "SPECIFICATIONS & HIGHLIGHTS", fill=C_MUTED, font=get_font(9.5, True))
d1.text((SW - 170, hy), "RERA: UPRERAPRJ9921", fill=C_PRIMARY, font=get_font(9.5, True))
hy += 18

chips1 = [("🛏️", "3 Bedrooms"), ("🛁", "2 Bathrooms"), ("📐", "1,450 Sq.Ft."), ("🏢", "5th Floor")]
cx = 32
for icon, label in chips1:
    txt = f"{icon} {label}"
    tw = int(d1.textlength(txt, font=get_font(10.5, True))) + 22
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
    d1.rounded_rectangle([cx, hy, cx + tw, hy + 30], radius=15, fill=C_CHIP_BG, outline=C_BORDER)
    d1.text((cx + 11, hy + 7), txt, fill=C_INK, font=get_font(10.5, True))
    cx += tw + 8

y1 += 264

# STICKY DYNAMIC TABS STRIP (Overview Active)
d1.rounded_rectangle([16, y1, SW - 16, y1 + 46], radius=23, fill=(255, 255, 255), outline=C_BORDER)
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

# ELEVATED CARD: ABOUT THIS PROPERTY
draw_elevated_card(d1, [16, y1, SW - 16, y1 + 105], radius=18)
d1.rectangle([32, y1 + 16, 36, y1 + 32], fill=C_PRIMARY)
d1.text((44, y1 + 14), "About This Property", fill=C_INK, font=get_font(14, True))
d1.text((SW - 110, y1 + 16), "Read More ›", fill=C_PRIMARY, font=get_font(11, True))
d1.text((32, y1 + 42), "A spacious 3 BHK luxury apartment in prime Indiranagar with double-glazed", fill=C_BODY, font=get_font(11, False))
d1.text((32, y1 + 60), "soundproof balconies, imported Italian marble and 100% verified legal title.", fill=C_BODY, font=get_font(11, False))
d1.text((32, y1 + 78), "Scenic green views and ready for immediate possession.", fill=C_MUTED, font=get_font(10.5, False))

y1 += 118

# ELEVATED CARD: AMENITIES GRID
draw_elevated_card(d1, [16, y1, SW - 16, y1 + 120], radius=18)
d1.rectangle([32, y1 + 16, 36, y1 + 32], fill=C_PRIMARY)
d1.text((44, y1 + 14), "Society Amenities", fill=C_INK, font=get_font(14, True))
d1.text((SW - 110, y1 + 16), "See All (35+) ›", fill=C_PRIMARY, font=get_font(11, True))

amen1 = [("🚗", "Parking"), ("🛡️", "24x7 Safe"), ("🏋️", "Gym"), ("🌳", "Garden"), ("🛗", "High Lift"), ("🏊", "Pool")]
aw = (SW - 64 - 50) // 6
for idx, (ai, an) in enumerate(amen1):
    ax = 32 + idx * (aw + 10)
    d1.rounded_rectangle([ax, y1 + 44, ax + aw, y1 + 92], radius=14, fill=(248, 250, 252), outline=C_BORDER)
    d1.text((ax + aw//2 - 9, y1 + 54), ai, fill=C_PRIMARY, font=get_font(15, False))
    d1.text((ax + 2, y1 + 98), an, fill=C_INK, font=get_font(9.5, True))

y1 += 135

# 2 ELEVATED CARDS: PROPERTY DETAILS & FLOOR PLAN
c_w = (SW - 32 - 12) // 2
c_h = 175
draw_elevated_card(d1, [16, y1, 16 + c_w, y1 + c_h], radius=16)
d1.text((30, y1 + 14), "Property Details", fill=C_INK, font=get_font(13, True))
dt_list = [("🏠 Type", ": Apartment"), ("🧭 Facing", ": East (Vastu)"), ("📐 Built Area", ": 1,450 Sq.Ft."), ("🏢 Floor", ": 5 of 14"), ("⚖️ RERA", ": Verified ✓")]
dy = y1 + 40
for k, v in dt_list:
    d1.text((30, dy), k, fill=C_BODY, font=get_font(9.5, False))
    d1.text((120, dy), v, fill=C_INK, font=get_font(9.5, True))
    dy += 22

fx = 16 + c_w + 12
draw_elevated_card(d1, [fx, y1, fx + c_w, y1 + c_h], radius=16)
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
# SCREEN 2: (SCROLLED VIEW - TRUST SHIELD + LOCATION + AGENT + REVIEWS)
# =============================================================
s2 = Image.new("RGB", (SW, SH), (244, 246, 249))
d2 = ImageDraw.Draw(s2)

# Sticky App Bar 2 (Scrolled)
d2.rectangle([0, 0, SW, 90], fill=(255, 255, 255))
d2.line([(0, 90), (SW, 90)], fill=(230, 235, 242), width=1)
d2.text((32, 12), "9:41", fill=C_INK, font=get_font(13, True))
d2.rounded_rectangle([SW//2 - 55, 8, SW//2 + 55, 32], radius=12, fill=(0, 0, 0))
d2.text((SW - 100, 12), "📶 5G 🔋", fill=C_INK, font=get_font(11, True))

# App bar row
d2.ellipse([20, 42, 58, 80], fill=(241, 245, 249))
d2.text((32, 50), "←", fill=C_INK, font=get_font(18, True))
d2.text((70, 48), "Modern 3 BHK Luxury Apartment", fill=C_INK, font=get_font(14, True))
d2.text((70, 68), "₹85,00,000 • Indiranagar", fill=C_PRIMARY, font=get_font(11, True))
d2.ellipse([SW - 90, 42, SW - 54, 80], fill=(241, 245, 249))
d2.text((SW - 78, 52), "♥", fill=C_ACCENT_RED, font=get_font(15, True))
d2.ellipse([SW - 46, 42, SW - 10, 80], fill=(241, 245, 249))
d2.text((SW - 34, 52), "↗", fill=C_INK, font=get_font(15, True))

y2 = 104

# DYNAMIC TABS STRIP (Location / Trust Active)
d2.rounded_rectangle([16, y2, SW - 16, y2 + 46], radius=23, fill=(255, 255, 255), outline=C_BORDER)
tabs2 = [("🏠", "Overview", False), ("📍", "Location", True), ("🛡️", "Trust Shield", False), ("📐", "Floor Plan", False), ("💬", "Reviews", False)]
tx = 24
for icon, tname, isAct in tabs2:
    txt = f"{icon} {tname}"
    tw = int(d2.textlength(txt, font=get_font(11, True))) + 22
    if isAct:
        d2.rounded_rectangle([tx, y2 + 7, tx + tw, y2 + 39], radius=16, fill=C_PRIMARY, outline=C_PRIMARY)
        d2.text((tx + 11, y2 + 13), txt, fill=(255, 255, 255), font=get_font(11, True))
    else:
        d2.text((tx + 11, y2 + 14), txt, fill=C_BODY, font=get_font(11, False))
    tx += tw + 8

y2 += 58

# 1. 🛡️ ELEVATED DIGINIWAS 100% BUYER TRUST SHIELD CARD
draw_elevated_card(d2, [16, y2, SW - 16, y2 + 160], radius=20, border_color=(167, 243, 208))
d2.rounded_rectangle([32, y2 + 16, 155, y2 + 38], radius=11, fill=C_PRIMARY)
d2.text((42, y2 + 20), "DIGINIWAS CERTIFIED", fill=(255, 255, 255), font=get_font(8.5, True))
d2.text((168, y2 + 20), "100% Buyer Trust & Legal Shield", fill=C_INK, font=get_font(12, True))

t_items = [
    ("⚖️ 100% Clear Title", "Occupancy Certificate (OC) Verified"),
    ("🛡️ Zero Brokerage", "Direct verified seller, no hidden fees"),
    ("🔍 Civil Inspected", "Civil Engineer on-site verified"),
    ("🏦 Bank Approved", "SBI & HDFC Home Loans ready"),
]
for idx, (th, ts) in enumerate(t_items):
    col = idx % 2
    row = idx // 2
    ix = 32 + col * ((SW - 64) // 2)
    iy = y2 + 54 + row * 48
    d2.rounded_rectangle([ix, iy, ix + (SW - 80)//2, iy + 42], radius=12, fill=(248, 250, 252), outline=C_BORDER)
    d2.text((ix + 10, iy + 6), th, fill=C_INK, font=get_font(11, True))
    d2.text((ix + 10, iy + 24), ts, fill=C_BODY, font=get_font(9.5, False))

y2 += 175

# 2. ELEVATED LOCATION & MAP CARD
draw_elevated_card(d2, [16, y2, SW - 16, y2 + 155], radius=20)
d2.rectangle([32, y2 + 16, 36, y2 + 32], fill=C_PRIMARY)
d2.text((44, y2 + 14), "Location & Neighborhood Index", fill=C_INK, font=get_font(14, True))
d2.rounded_rectangle([SW - 150, y2 + 12, SW - 32, y2 + 36], radius=12, fill=(240, 253, 244), outline=C_PRIMARY)
d2.text((SW - 140, y2 + 16), "⭐ 9.2 / 10 Score", fill=C_PRIMARY, font=get_font(10, True))

# Simulated Map
d2.rounded_rectangle([32, y2 + 46, 200, y2 + 138], radius=14, fill=(226, 238, 230), outline=C_BORDER)
d2.line([(40, y2 + 75), (190, y2 + 85)], fill=(255, 255, 255), width=4)
d2.line([(80, y2 + 55), (100, y2 + 130)], fill=(255, 255, 255), width=5)
d2.ellipse([100, y2 + 78, 126, y2 + 104], fill=C_PRIMARY)
d2.text((107, y2 + 82), "📍", fill=(255, 255, 255), font=get_font(11, True))
d2.text((45, y2 + 115), "Indiranagar", fill=C_PRIMARY, font=get_font(9, True))

d2.text((215, y2 + 50), "Indiranagar, Bengaluru", fill=C_INK, font=get_font(13.5, True))
d2.text((215, y2 + 72), "📍 2.5 km from MG Road • 450m from Metro", fill=C_BODY, font=get_font(10.5, False))
d2.text((215, y2 + 90), "🏫 DPS School: 1.1 km  |  🏥 Fortis: 1.4 km", fill=C_MUTED, font=get_font(9.5, False))
d2.rounded_rectangle([215, y2 + 110, 345, y2 + 138], radius=14, fill=(255, 255, 255), outline=C_PRIMARY)
d2.text((228, y2 + 116), "📍 Open in Google Maps", fill=C_PRIMARY, font=get_font(10, True))

y2 += 170

# 3. ELEVATED VERIFIED SPECIALIST CARD
draw_elevated_card(d2, [16, y2, SW - 16, y2 + 110], radius=20)
d2.ellipse([32, y2 + 18, 96, y2 + 82], fill=C_PRIMARY)
d2.text((48, y2 + 32), "RS", fill=(255, 255, 255), font=get_font(21, True))

d2.text((110, y2 + 18), "Rahul Sharma", fill=C_INK, font=get_font(15, True))
d2.rounded_rectangle([220, y2 + 18, 335, y2 + 38], radius=6, fill=C_PRIMARY_LIGHT)
d2.text((228, y2 + 21), "✓ Verified Partner", fill=C_PRIMARY, font=get_font(9.5, True))

d2.text((110, y2 + 42), "Senior Real Estate Specialist • Indiranagar Hub", fill=C_BODY, font=get_font(10.5, False))
d2.text((110, y2 + 62), "⭐ 4.95 (64 Deals Closed)  •  Responds in <5 mins", fill=(217, 119, 6), font=get_font(10, True))

d2.rounded_rectangle([SW - 165, y2 + 18, SW - 32, y2 + 52], radius=10, fill=(37, 211, 102))
d2.text((SW - 150, y2 + 26), "💬 WhatsApp", fill=(255, 255, 255), font=get_font(11, True))
d2.rounded_rectangle([SW - 165, y2 + 58, SW - 32, y2 + 92], radius=10, fill=C_PRIMARY_LIGHT, outline=C_PRIMARY)
d2.text((SW - 145, y2 + 66), "📞 Call Direct", fill=C_PRIMARY, font=get_font(11, True))

y2 += 125

# 4. ELEVATED REVIEWS CARD
draw_elevated_card(d2, [16, y2, SW - 16, y2 + 85], radius=18)
d2.text((36, y2 + 18), "4.8", fill=C_INK, font=get_font(24, True))
d2.text((78, y2 + 24), "⭐", fill=(245, 158, 11), font=get_font(14, True))
d2.text((36, y2 + 48), "(500+ Reviews)", fill=C_MUTED, font=get_font(9.5, False))
d2.line([(165, y2 + 14), (165, y2 + 70)], fill=(235, 240, 245), width=1)
d2.text((180, y2 + 20), "“Spacious floor plan, verified clear papers and great sunlight.”", fill=C_INK, font=get_font(10.5, False))
d2.text((180, y2 + 46), "⭐⭐⭐⭐⭐  •  Amit Patel (Verified Buyer)", fill=(245, 158, 11), font=get_font(10, True))

# STICKY ELEVATED BOTTOM BAR 2
b_y = SH - 75
d2.rectangle([0, b_y, SW, SH], fill=(255, 255, 255))
d2.line([(0, b_y), (SW, b_y)], fill=(230, 235, 242), width=1)
bw = (SW - 40 - 12) // 2
d2.rounded_rectangle([20, b_y + 12, 20 + bw, b_y + 58], radius=14, fill=(255, 255, 255), outline=C_PRIMARY, width=2)
d2.text((20 + bw//2 - 55, b_y + 24), "📅  Schedule Visit", fill=C_PRIMARY, font=get_font(13, True))
d2.rounded_rectangle([20 + bw + 12, b_y + 12, SW - 20, b_y + 58], radius=14, fill=C_PRIMARY)
d2.text((20 + bw + 12 + bw//2 - 42, b_y + 24), "📞  Call Now", fill=(255, 255, 255), font=get_font(13, True))
d2.rounded_rectangle([SW//2 - 50, SH - 10, SW//2 + 50, SH - 5], radius=2, fill=(180, 190, 200))

# -------------------------------------------------------------
# PASTE INTO CANVAS
# -------------------------------------------------------------
draw_single_phone(s1, 60, "📱 View 1: Elevated White Cards + Spec Chips")
draw_single_phone(s2, 940, "📱 View 2: Scrolled Tabs + Trust Shield Card")

dual_preview_path = os.path.join(brain_dir, "buyer_details_dual_phone_preview.png")
canvas.save(dual_preview_path, quality=95)
print("Saved Pro White Elevated Dual Phone Mockup to:", dual_preview_path)
