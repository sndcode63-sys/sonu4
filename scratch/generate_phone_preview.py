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
# PHONE FRAME SPECIFICATIONS
# Phone outer canvas: 920 x 1880
# Screen area inside phone: 800 x 1720, margin (60, 80)
# -------------------------------------------------------------
PW, PH = 920, 1880
canvas = Image.new("RGB", (PW, PH), (241, 245, 249)) # Soft studio background
p_draw = ImageDraw.Draw(canvas)

# Phone outer body (Midnight Titanium frame)
p_x0, p_y0 = 40, 40
p_x1, p_y1 = PW - 40, PH - 40
p_corner = 56

# Subtle device drop shadow
shadow = Image.new("RGBA", (PW, PH), (0, 0, 0, 0))
s_draw = ImageDraw.Draw(shadow)
s_draw.rounded_rectangle([p_x0 - 4, p_y0 + 16, p_x1 + 4, p_y1 + 24], radius=p_corner + 4, fill=(0, 0, 0, 40))
shadow = shadow.filter(ImageFilter.GaussianBlur(18))
canvas.paste(shadow, (0, 0), shadow)

# Outer bezel
p_draw.rounded_rectangle([p_x0, p_y0, p_x1, p_y1], radius=p_corner, fill=(28, 32, 38), outline=(60, 66, 76), width=4)
# Inner screen border
SW, SH = 800, 1720
sx0, sy0 = 60, 80
sx1, sy1 = sx0 + SW, sy0 + SH

# Create Screen Image
screen = Image.new("RGB", (SW, SH), (248, 250, 252))
draw = ImageDraw.Draw(screen)

# Colors matching DigiNiwas brand + reference image 1
C_PRIMARY = (0, 122, 94)       # DigiNiwas Emerald
C_PRIMARY_LIGHT = (232, 247, 242)
C_ACCENT_RED = (225, 29, 72)   # Rose red for badges/buttons like ref image
C_ACCENT_RED_SOFT = (255, 241, 242)
C_INK = (15, 23, 42)
C_BODY = (71, 85, 105)
C_MUTED = (148, 163, 184)
C_CARD_BG = (255, 255, 255)
C_BORDER = (226, 232, 240)
C_CHIP_BG = (241, 245, 249)    # Image 2 style chips

# -------------------------------------------------------------
# 1. STATUS BAR (9:41, Icons)
# -------------------------------------------------------------
draw.text((36, 14), "9:41", fill=(255, 255, 255), font=get_font(14, True))
# Dynamic Island Pill
draw.rounded_rectangle([SW//2 - 60, 10, SW//2 + 60, 36], radius=13, fill=(0, 0, 0))
# Camera dot & sensor
draw.ellipse([SW//2 + 35, 18, SW//2 + 47, 28], fill=(20, 25, 35))
# Battery / Signal right
draw.text((SW - 110, 14), "📶  5G  🔋", fill=(255, 255, 255), font=get_font(13, True))

# -------------------------------------------------------------
# 2. HERO IMAGE CAROUSEL
# -------------------------------------------------------------
hero_h = 360
try:
    hero_raw = Image.open("assets/images/compare_home.png").convert("RGB")
    rw, rh = hero_raw.size
    target_ratio = SW / hero_h
    raw_ratio = rw / rh
    if raw_ratio > target_ratio:
        new_w = int(rh * target_ratio)
        hero_crop = hero_raw.crop(((rw - new_w) // 2, 0, (rw + new_w) // 2, rh))
    else:
        new_h = int(rw / target_ratio)
        hero_crop = hero_raw.crop((0, (rh - new_h) // 2, rw, (rh + new_h) // 2))
    hero_img = hero_crop.resize((SW, hero_h), Image.Resampling.LANCZOS)
    screen.paste(hero_img, (0, 0))
except Exception:
    draw.rectangle([0, 0, SW, hero_h], fill=(40, 50, 65))

# Top subtle shadow for status bar legibility
top_s = Image.new("RGBA", (SW, 70), (0, 0, 0, 0))
ts_draw = ImageDraw.Draw(top_s)
for y in range(70):
    ts_draw.line([(0, y), (SW, y)], fill=(0, 0, 0, int(120 * (1 - y/70))))
screen.paste(top_s, (0, 0), top_s)

# Re-draw status bar text over hero
draw.text((36, 14), "9:41", fill=(255, 255, 255), font=get_font(14, True))
draw.rounded_rectangle([SW//2 - 60, 10, SW//2 + 60, 36], radius=13, fill=(0, 0, 0))
draw.ellipse([SW//2 + 35, 18, SW//2 + 47, 28], fill=(25, 30, 40))
draw.text((SW - 105, 14), "📶  5G  🔋", fill=(255, 255, 255), font=get_font(12, True))

# Floating Navigation Actions
# Back Button Circle
draw.ellipse([24, 52, 68, 96], fill=(255, 255, 255, 240))
draw.text((38, 62), "←", fill=C_INK, font=get_font(22, True))

# Wishlist Heart Circle
draw.ellipse([SW - 116, 52, SW - 72, 96], fill=(255, 255, 255, 240))
draw.text((SW - 102, 64), "♥", fill=C_ACCENT_RED, font=get_font(19, True))

# Share Circle
draw.ellipse([SW - 66, 52, SW - 22, 96], fill=(255, 255, 255, 240))
draw.text((SW - 52, 64), "↗", fill=C_INK, font=get_font(19, True))

# Hero Bottom Badges
# [📷 1 / 14] Pill (bottom left)
draw.rounded_rectangle([24, hero_h - 48, 110, hero_h - 16], radius=16, fill=(15, 23, 42, 210))
draw.text((38, hero_h - 38), "📷  1 / 14", fill=(255, 255, 255), font=get_font(11, True))

# [▶ View Video / 360°] Pill (bottom right)
draw.rounded_rectangle([SW - 150, hero_h - 48, SW - 24, hero_h - 16], radius=16, fill=(255, 255, 255, 240))
draw.text((SW - 138, hero_h - 38), "▶  View Video", fill=C_INK, font=get_font(11, True))

# -------------------------------------------------------------
# 3. SHEET CONTENT (WHITE OVERLAPPING CARD)
# -------------------------------------------------------------
body_y = hero_h - 10
draw.rounded_rectangle([0, body_y, SW, SH - 90], radius=24, fill=(255, 255, 255))

cur_y = body_y + 20

# Price & Trend Badge
draw.text((24, cur_y), "₹85,00,000", fill=C_PRIMARY, font=get_font(26, True))
draw.text((185, cur_y + 7), "(@ ₹ 5,862 / sq.ft)", fill=C_MUTED, font=get_font(12, False))

# Trend Badge right
draw.rounded_rectangle([SW - 225, cur_y + 2, SW - 24, cur_y + 30], radius=12, fill=C_ACCENT_RED_SOFT)
draw.text((SW - 212, cur_y + 7), "📈 2.5% Higher than last month", fill=C_ACCENT_RED, font=get_font(10.5, True))

cur_y += 42
# Title & For Sale Pill
draw.text((24, cur_y), "Modern 3 BHK Luxury Apartment", fill=C_INK, font=get_font(18, True))
draw.rounded_rectangle([SW - 110, cur_y - 2, SW - 24, cur_y + 26], radius=12, fill=C_PRIMARY_LIGHT)
draw.text((SW - 98, cur_y + 3), "🏠 For Sale", fill=C_PRIMARY, font=get_font(11, True))

cur_y += 28
# Location
draw.text((24, cur_y), "📍 Indiranagar, Bengaluru, Karnataka  •  Near Metro", fill=C_BODY, font=get_font(12, False))

cur_y += 28

# -------------------------------------------------------------
# 4. CHIP CHOICES SPECIFICATIONS (IMAGE 2 STYLE CHIPS AS REQUESTED!)
# -------------------------------------------------------------
# User specifically requested: "jo top bedroom, bathroom wala uske 2nd image me jaise chip choice dikh raha waise dikhna hai bhai"
chips_row1 = [
    ("🛏️", "3 Bedrooms"),
    ("🛁", "2 Bathrooms"),
    ("📐", "1,450 Sq.Ft."),
    ("🏢", "5th Floor"),
]
chips_row2 = [
    ("🧭", "East Facing"),
    ("🚗", "2 Covered Parking"),
    ("🛋️", "Semi-Furnished"),
    ("⚡", "100% Power Backup"),
]

chip_h = 36
chip_r = 18

cx = 24
for icon, label in chips_row1:
    txt = f"{icon}  {label}"
    t_w = int(draw.textlength(txt, font=get_font(11.5, True))) + 24
    draw.rounded_rectangle([cx, cur_y, cx + t_w, cur_y + chip_h], radius=chip_r, fill=C_CHIP_BG, outline=C_BORDER, width=1)
    draw.text((cx + 12, cur_y + 9), txt, fill=C_INK, font=get_font(11.5, True))
    cx += t_w + 10

cur_y += chip_h + 8
cx = 24
for icon, label in chips_row2:
    txt = f"{icon}  {label}"
    t_w = int(draw.textlength(txt, font=get_font(11.5, True))) + 24
    if cx + t_w > SW - 24: break
    draw.rounded_rectangle([cx, cur_y, cx + t_w, cur_y + chip_h], radius=chip_r, fill=C_CHIP_BG, outline=C_BORDER, width=1)
    draw.text((cx + 12, cur_y + 9), txt, fill=C_INK, font=get_font(11.5, True))
    cx += t_w + 10

cur_y += chip_h + 16

# -------------------------------------------------------------
# 5. DYNAMIC INTERACTIVE NAVIGATION TABS STRIP (FROM IMAGE 1)
# User: "dynamic sab tab bhi kaam karna chahiye"
# -------------------------------------------------------------
draw.line([(24, cur_y), (SW - 24, cur_y)], fill=(241, 245, 249), width=1)
cur_y += 8

tabs = [
    ("🏠", "Overview", True),
    ("📍", "Location", False),
    ("⭐", "Amenities", False),
    ("📐", "Floor Plan", False),
    ("💬", "Reviews", False),
]

tx = 24
for icon, tname, isActive in tabs:
    tab_txt = f"{icon} {tname}"
    tw = int(draw.textlength(tab_txt, font=get_font(12, True))) + 26
    if isActive:
        draw.rounded_rectangle([tx, cur_y, tx + tw, cur_y + 36], radius=18, fill=C_PRIMARY_LIGHT, outline=C_PRIMARY, width=1)
        draw.text((tx + 13, cur_y + 8), tab_txt, fill=C_PRIMARY, font=get_font(12, True))
    else:
        draw.rounded_rectangle([tx, cur_y, tx + tw, cur_y + 36], radius=18, fill=(255, 255, 255), outline=C_BORDER, width=1)
        draw.text((tx + 13, cur_y + 8), tab_txt, fill=C_BODY, font=get_font(12, False))
    tx += tw + 8

cur_y += 46

# -------------------------------------------------------------
# 6. ABOUT THIS PROPERTY SECTION (IMAGE 1 STYLE)
# -------------------------------------------------------------
draw.rectangle([24, cur_y + 2, 28, cur_y + 20], fill=C_PRIMARY)
draw.text((36, cur_y), "About This Property", fill=C_INK, font=get_font(16, True))
draw.text((SW - 110, cur_y + 2), "Read More ›", fill=C_PRIMARY, font=get_font(12, True))

cur_y += 26
desc_text = "A beautiful and spacious 3 BHK luxury apartment in the prime location of Indiranagar. This property offers modern imported amenities, verified RERA legal title, excellent connectivity and a peaceful living environment. Perfect for families seeking luxury and convenience."
# Wrap text cleanly
lines = [
    "A beautiful and spacious 3 BHK luxury apartment in the prime location of Indiranagar.",
    "This property offers modern amenities, 100% verified legal title, 24/7 security,",
    "and a peaceful green environment. Perfect for families seeking luxury."
]
for ln in lines:
    draw.text((24, cur_y), ln, fill=C_BODY, font=get_font(12, False))
    cur_y += 18

cur_y += 14

# -------------------------------------------------------------
# 7. AMENITIES SECTION (IMAGE 1 STYLE CIRCLE/ROUNDED CARDS)
# -------------------------------------------------------------
draw.rectangle([24, cur_y + 2, 28, cur_y + 20], fill=C_PRIMARY)
draw.text((36, cur_y), "Amenities", fill=C_INK, font=get_font(16, True))
draw.text((SW - 90, cur_y + 2), "See All ›", fill=C_PRIMARY, font=get_font(12, True))

cur_y += 28
amenities = [
    ("🚗", "Parking"),
    ("🛡️", "24x7 Security"),
    ("🏋️", "Gym"),
    ("🌳", "Garden"),
    ("🛗", "Lift"),
    ("📶", "Wi-Fi"),
]

a_card_w = (SW - 48 - (len(amenities)-1)*10) // len(amenities)
a_card_h = 74

for idx, (a_icon, a_name) in enumerate(amenities):
    ax = 24 + idx * (a_card_w + 10)
    # Icon card
    draw.rounded_rectangle([ax, cur_y, ax + a_card_w, cur_y + 50], radius=14, fill=C_PRIMARY_LIGHT)
    draw.text((ax + a_card_w//2 - 10, cur_y + 12), a_icon, fill=C_PRIMARY, font=get_font(16, False))
    # Label
    draw.text((ax + 2, cur_y + 56), a_name, fill=C_INK, font=get_font(10, True))

cur_y += 82

# -------------------------------------------------------------
# 8. PROPERTY DETAILS & FLOOR PLAN (IMAGE 1 2-COLUMN SECTION)
# -------------------------------------------------------------
card_top = cur_y
card_w = (SW - 48 - 14) // 2
card_h = 210

# Left Card: Property Details Table
draw.rounded_rectangle([24, card_top, 24 + card_w, card_top + card_h], radius=16, fill=(255, 255, 255), outline=C_BORDER)
draw.rectangle([36, card_top + 16, 40, card_top + 34], fill=C_PRIMARY)
draw.text((48, card_top + 14), "Property Details", fill=C_INK, font=get_font(14, True))

specs_table = [
    ("🏠 Type", "Apartment"),
    ("🧭 Facing", "East (Vastu)"),
    ("📐 Built Up Area", "1,450 Sq.Ft."),
    ("🏢 Floor", "5 of 14"),
    ("⏳ Age of Property", "New / Ready"),
    ("⚖️ RERA Status", "Approved ✓"),
]
sy = card_top + 46
for k, v in specs_table:
    draw.text((36, sy), k, fill=C_BODY, font=get_font(10.5, False))
    draw.text((160, sy), f": {v}", fill=C_INK, font=get_font(10.5, True))
    sy += 24

# Right Card: Floor Plan Preview
fx0 = 24 + card_w + 14
draw.rounded_rectangle([fx0, card_top, fx0 + card_w, card_top + card_h], radius=16, fill=(255, 255, 255), outline=C_BORDER)
draw.text((fx0 + 16, card_top + 14), "📐 Floor Plan", fill=C_INK, font=get_font(14, True))
draw.text((fx0 + card_w - 90, card_top + 16), "View Full ›", fill=C_PRIMARY, font=get_font(11, True))

# Simulated Architectural Floor Plan graphic box
draw.rounded_rectangle([fx0 + 16, card_top + 46, fx0 + card_w - 16, card_top + card_h - 16], radius=10, fill=(248, 250, 252), outline=C_BORDER)
# Draw blueprint lines
f_in_x = fx0 + 16
f_in_y = card_top + 46
f_in_w = card_w - 32
f_in_h = card_h - 62
draw.rectangle([f_in_x + 10, f_in_y + 10, f_in_x + f_in_w - 10, f_in_y + f_in_h - 10], outline=(180, 195, 210), width=2)
draw.line([(f_in_x + f_in_w//2, f_in_y + 10), (f_in_x + f_in_w//2, f_in_y + f_in_h - 10)], fill=(180, 195, 210), width=1)
draw.line([(f_in_x + 10, f_in_y + f_in_h//2), (f_in_x + f_in_w - 10, f_in_y + f_in_h//2)], fill=(180, 195, 210), width=1)
draw.text((f_in_x + 20, f_in_y + 25), "Master Bed\n14' x 12'", fill=(120, 135, 150), font=get_font(9.5, True))
draw.text((f_in_x + f_in_w//2 + 15, f_in_y + 25), "Living Room\n18' x 14'", fill=(120, 135, 150), font=get_font(9.5, True))
draw.text((f_in_x + 20, f_in_y + f_in_h//2 + 20), "Bed 2\n12' x 11'", fill=(120, 135, 150), font=get_font(9.5, True))
draw.text((f_in_x + f_in_w//2 + 15, f_in_y + f_in_h//2 + 20), "Kitchen\n10' x 8'", fill=(120, 135, 150), font=get_font(9.5, True))

cur_y = card_top + card_h + 16

# -------------------------------------------------------------
# 9. LOCATION & MINI MAP (IMAGE 1 STYLE)
# -------------------------------------------------------------
draw.rectangle([24, cur_y + 2, 28, cur_y + 20], fill=C_PRIMARY)
draw.text((36, cur_y), "Location & Neighborhood", fill=C_INK, font=get_font(16, True))
cur_y += 28

draw.rounded_rectangle([24, cur_y, SW - 24, cur_y + 100], radius=16, fill=(255, 255, 255), outline=C_BORDER)

# Simulated mini map graphic left
draw.rounded_rectangle([34, cur_y + 10, 200, cur_y + 90], radius=12, fill=(226, 238, 230))
draw.line([(40, cur_y + 35), (190, cur_y + 45)], fill=(255, 255, 255), width=4)
draw.line([(80, cur_y + 15), (110, cur_y + 85)], fill=(255, 255, 255), width=5)
draw.ellipse([110, cur_y + 40, 134, cur_y + 64], fill=C_PRIMARY)
draw.text((118, cur_y + 44), "📍", fill=(255, 255, 255), font=get_font(12, True))
draw.text((50, cur_y + 65), "Indiranagar", fill=C_PRIMARY, font=get_font(9.5, True))

# Map details right
draw.text((215, cur_y + 16), "Indiranagar, Bengaluru", fill=C_INK, font=get_font(14, True))
draw.text((215, cur_y + 38), "📍 2.5 km from MG Road • 450m from Metro", fill=C_BODY, font=get_font(11, False))

# Open in Maps button
draw.rounded_rectangle([215, cur_y + 58, 335, cur_y + 88], radius=15, fill=(255, 255, 255), outline=C_PRIMARY, width=1)
draw.text((228, cur_y + 64), "📍 Open in Maps", fill=C_PRIMARY, font=get_font(11, True))

cur_y += 114

# -------------------------------------------------------------
# 10. REVIEWS & RATINGS (IMAGE 1 STYLE)
# -------------------------------------------------------------
draw.rectangle([24, cur_y + 2, 28, cur_y + 20], fill=C_PRIMARY)
draw.text((36, cur_y), "Reviews & Ratings", fill=C_INK, font=get_font(16, True))
draw.text((SW - 90, cur_y + 2), "See All ›", fill=C_PRIMARY, font=get_font(12, True))
cur_y += 28

draw.rounded_rectangle([24, cur_y, SW - 24, cur_y + 80], radius=16, fill=(255, 255, 255), outline=C_BORDER)
# Big Score
draw.text((40, cur_y + 18), "4.8", fill=C_INK, font=get_font(26, True))
draw.text((88, cur_y + 24), "⭐", fill=(245, 158, 11), font=get_font(16, True))
draw.text((40, cur_y + 50), "(500+ Verified Reviews)", fill=C_MUTED, font=get_font(10.5, False))

draw.line([(185, cur_y + 15), (185, cur_y + 65)], fill=C_BORDER, width=1)

# Review excerpt
draw.text((200, cur_y + 18), "“Excellent property, great ventilation, zero brokerage and", fill=C_INK, font=get_font(11, False))
draw.text((200, cur_y + 34), "peaceful surroundings. DigiNiwas verified agent was helpful.”", fill=C_INK, font=get_font(11, False))
draw.text((200, cur_y + 52), "⭐⭐⭐⭐⭐  •  Amit Patel (Verified Buyer)", fill=(245, 158, 11), font=get_font(10.5, True))

# -------------------------------------------------------------
# 11. STICKY BOTTOM ACTION BAR (IMAGE 1 STYLE WITH DIGINIWAS BRANDING)
# -------------------------------------------------------------
bar_h = 86
bar_y = SH - bar_h

# White container with top divider and subtle shadow
draw.rectangle([0, bar_y, SW, SH], fill=(255, 255, 255))
draw.line([(0, bar_y), (SW, bar_y)], fill=C_BORDER, width=1)

btn_h = 50
btn_y = bar_y + 14
btn_w = (SW - 48 - 14) // 2

# Left Button: [📅 Schedule Visit] (Outlined)
draw.rounded_rectangle([24, btn_y, 24 + btn_w, btn_y + btn_h], radius=14, fill=(255, 255, 255), outline=C_PRIMARY, width=2)
draw.text((24 + btn_w//2 - 62, btn_y + 14), "📅  Schedule Visit", fill=C_PRIMARY, font=get_font(14, True))

# Right Button: [📞 Call Now / WhatsApp] (Filled Solid Primary)
draw.rounded_rectangle([24 + btn_w + 14, btn_y, SW - 24, btn_y + btn_h], radius=14, fill=C_PRIMARY)
draw.text((24 + btn_w + 14 + btn_w//2 - 48, btn_y + 14), "📞  Call Now", fill=(255, 255, 255), font=get_font(14, True))

# Home Indicator bar (iPhone style)
draw.rounded_rectangle([SW//2 - 65, SH - 12, SW//2 + 65, SH - 6], radius=3, fill=(180, 190, 200))

# -------------------------------------------------------------
# PASTE SCREEN INTO PHONE FRAME
# -------------------------------------------------------------
# Mask for rounded screen corners inside the frame
mask = Image.new("L", (SW, SH), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle([0, 0, SW, SH], radius=44, fill=255)

canvas.paste(screen, (sx0, sy0), mask)

phone_mockup_path = os.path.join(brain_dir, "property_details_phone_preview.png")
canvas.save(phone_mockup_path, quality=95)
print("Saved Phone Mockup to:", phone_mockup_path)
