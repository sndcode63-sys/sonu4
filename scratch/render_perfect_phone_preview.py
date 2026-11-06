import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

brain_dir = r"C:\Users\sk460\.gemini\antigravity\brain\22d11365-799f-4b35-a997-a30b2f31a218"
os.makedirs(brain_dir, exist_ok=True)

def get_font(size, bold=False):
    font_names = [
        "C:\\Windows\\Fonts\\segoeuib.ttf" if bold else "C:\\Windows\\Fonts\\segoeui.ttf",
        "C:\\Windows\\Fonts\\arialbd.ttf" if bold else "C:\\Windows\\Fonts\\arial.ttf",
    ]
    for fn in font_names:
        if os.path.exists(fn):
            try:
                return ImageFont.truetype(fn, size)
            except Exception:
                pass
    return ImageFont.load_default()

# -------------------------------------------------------------------------
# CONSTANTS & PALETTE (EXACT IMAGE 1 & IMAGE 2 COMPLIANCE)
# -------------------------------------------------------------------------
CW, CH = 2200, 1850
canvas = Image.new("RGB", (CW, CH), (248, 250, 252))
c_draw = ImageDraw.Draw(canvas)

# Phone frame geometry
PW, PH = 860, 1640
SW, SH = 800, 1540
corner_r = 52

# Colors
C_RED = (229, 29, 56)           # Exact Image 1 accent (#E51D38)
C_RED_BG = (254, 236, 238)      # Soft rose tint
C_GREEN = (16, 185, 129)        # Emerald sale pill
C_GREEN_BG = (230, 249, 240)
C_SLATE_900 = (15, 23, 42)      # Primary text
C_SLATE_700 = (51, 65, 85)      # Body text
C_SLATE_500 = (100, 116, 139)   # Subtitle text
C_SLATE_400 = (148, 163, 184)   # Caption text
C_BORDER = (238, 242, 246)      # Subtle border
C_CHIP_BG = (241, 243, 245)     # Image 2 pill chip background (#F1F3F5)
C_CARD_BG = (255, 255, 255)     # Clean white card

# Shimmer colors
C_SHIM_BASE = (233, 238, 242)
C_SHIM_WAVE = (248, 250, 252)

# Top Title Header on Canvas
c_draw.rounded_rectangle([CW//2 - 220, 35, CW//2 + 220, 75], radius=20, fill=(238, 242, 246))
c_draw.text((CW//2 - 180, 46), "DIGINIWAS REAL ESTATE UI PREVIEW", fill=C_SLATE_700, font=get_font(14, True))
c_draw.text((CW//2 - 390, 88), "Pixel-Perfect Redesign Matching Image 1 & Image 2", fill=C_SLATE_900, font=get_font(30, True))
c_draw.text((CW//2 - 370, 134), "Pure White Continuous Surface  •  Image 2 Pill Chips  •  Vertical Accent Bars  •  Smooth Skeleton Shimmer", fill=C_SLATE_500, font=get_font(15, False))


def draw_phone_case(x_pos, y_pos):
    # Outer drop shadow
    shadow = Image.new("RGBA", (PW + 40, PH + 40), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.rounded_rectangle([20, 26, PW + 20, PH + 26], radius=corner_r + 4, fill=(15, 23, 42, 40))
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    canvas.paste(shadow, (x_pos - 20, y_pos - 10), shadow)

    # iPhone Titanium bezel
    c_draw.rounded_rectangle([x_pos, y_pos, x_pos + PW, y_pos + PH], radius=corner_r, fill=(28, 32, 38), outline=(60, 68, 78), width=4)
    # Inner metallic edge
    c_draw.rounded_rectangle([x_pos + 4, y_pos + 4, x_pos + PW - 4, y_pos + PH - 4], radius=corner_r - 4, fill=(15, 17, 21))


# =========================================================================
# PHONE 1: 100% IMAGE 1 LAYOUT + IMAGE 2 PILL CHIPS
# =========================================================================
s1 = Image.new("RGB", (SW, SH), (255, 255, 255))
d1 = ImageDraw.Draw(s1)

# 1. Hero Carousel (height 340)
hero_h = 340
try:
    if os.path.exists("scratch/hero_building_crop.png"):
        h_crop = Image.open("scratch/hero_building_crop.png").convert("RGB")
        h_resized = h_crop.resize((SW, hero_h), Image.Resampling.LANCZOS)
        s1.paste(h_resized, (0, 0))
    else:
        d1.rectangle([0, 0, SW, hero_h], fill=(45, 55, 72))
except Exception:
    d1.rectangle([0, 0, SW, hero_h], fill=(45, 55, 72))

# Top dark gradient overlay for status bar readability
top_grad = Image.new("RGBA", (SW, 75), (0, 0, 0, 0))
tg_draw = ImageDraw.Draw(top_grad)
for y in range(75):
    tg_draw.line([(0, y), (SW, y)], fill=(0, 0, 0, int(115 * (1 - y/75))))
s1.paste(top_grad, (0, 0), top_grad)

# Status bar
d1.text((36, 14), "9:41", fill=(255, 255, 255), font=get_font(13.5, True))
# Dynamic Island
d1.rounded_rectangle([SW//2 - 62, 10, SW//2 + 62, 36], radius=13, fill=(0, 0, 0))
d1.text((SW - 110, 14), "📶 5G  🔋", fill=(255, 255, 255), font=get_font(12, True))

# Floating Navigation Buttons (Top)
# Back Button (Circle white)
d1.ellipse([22, 52, 66, 96], fill=(255, 255, 255))
d1.text((36, 62), "←", fill=C_SLATE_900, font=get_font(21, True))
# Favorite Button
d1.ellipse([SW - 118, 52, SW - 74, 96], fill=(255, 255, 255))
d1.text((SW - 105, 65), "♥", fill=C_RED, font=get_font(18, True))
# Share Button
d1.ellipse([SW - 66, 52, SW - 22, 96], fill=(255, 255, 255))
d1.text((SW - 53, 64), "↗", fill=C_SLATE_900, font=get_font(18, True))

# Floating Carousel Pills (Bottom of Hero)
# [ 📷 1/12 ]
d1.rounded_rectangle([22, hero_h - 48, 115, hero_h - 16], radius=16, fill=(15, 23, 42, 210))
d1.text((34, hero_h - 38), "📷  1 / 12", fill=(255, 255, 255), font=get_font(11, True))
# Carousel Dots in center
dot_x = SW // 2 - 20
d1.ellipse([dot_x, hero_h - 34, dot_x + 8, hero_h - 26], fill=C_RED)
d1.ellipse([dot_x + 14, hero_h - 33, dot_x + 20, hero_h - 27], fill=(255, 255, 255, 180))
d1.ellipse([dot_x + 26, hero_h - 33, dot_x + 32, hero_h - 27], fill=(255, 255, 255, 180))
# [ ▶ View Video ]
d1.rounded_rectangle([SW - 146, hero_h - 48, SW - 22, hero_h - 16], radius=16, fill=(255, 255, 255, 240))
d1.text((SW - 132, hero_h - 38), "▶  View Video", fill=C_SLATE_900, font=get_font(11, True))


# -------------------------------------------------------------------------
# CONTINUOUS WHITE SHEET (Exact Image 1 Structure & Spacing)
# -------------------------------------------------------------------------
cur_y = hero_h + 16

# Row 1: Price and Trend Badge
d1.text((24, cur_y), "₹85,00,000", fill=C_RED, font=get_font(28, True))
# Trend Badge on right: [ 📈 2.5% Higher than last month ]
badge_w = 210
badge_h = 28
d1.rounded_rectangle([SW - 24 - badge_w, cur_y + 4, SW - 24, cur_y + 4 + badge_h], radius=14, fill=C_RED_BG)
d1.text((SW - 24 - badge_w + 14, cur_y + 10), "📈 2.5% Higher than last month", fill=C_RED, font=get_font(10.5, True))

cur_y += 42

# Row 2: Title and For Sale Pill
d1.text((24, cur_y), "Modern 3 BHK Apartment", fill=C_SLATE_900, font=get_font(19, True))
# For Sale Pill on right: [ 🏠 For Sale ]
sale_w = 100
sale_h = 28
d1.rounded_rectangle([SW - 24 - sale_w, cur_y - 2, SW - 24, cur_y - 2 + sale_h], radius=14, fill=C_GREEN_BG)
d1.text((SW - 24 - sale_w + 14, cur_y + 4), "🏠 For Sale", fill=C_GREEN, font=get_font(11, True))

cur_y += 30

# Row 3: Location Subtitle
d1.text((24, cur_y), "📍  Indiranagar, Bengaluru, Karnataka", fill=C_SLATE_500, font=get_font(12, False))

cur_y += 28

# -------------------------------------------------------------------------
# ROW 4: SPEC CHIPS (STRICT IMAGE 2 SPECIFICATION)
# -------------------------------------------------------------------------
# In Image 2: rounded-full pill chips with light grey background (#F1F3F5)
chips_line1 = [("🛏️", "3 Bedrooms"), ("🛁", "2 Bathrooms"), ("📐", "1,450 Sq.Ft."), ("🏢", "5th Floor")]
cx = 24
for icon, label in chips_line1:
    txt = f"{icon}  {label}"
    tw = int(d1.textlength(txt, font=get_font(11, True))) + 26
    # Soft pill container
    d1.rounded_rectangle([cx, cur_y, cx + tw, cur_y + 34], radius=17, fill=C_CHIP_BG, outline=C_BORDER, width=1)
    d1.text((cx + 13, cur_y + 9), txt, fill=C_SLATE_900, font=get_font(11, True))
    cx += tw + 10

cur_y += 44

chips_line2 = [("🧭", "East Facing"), ("🚗", "2 Parking"), ("🛋️", "Semi-Furnished"), ("⚡", "100% Backup")]
cx = 24
for icon, label in chips_line2:
    txt = f"{icon}  {label}"
    tw = int(d1.textlength(txt, font=get_font(11, True))) + 26
    if cx + tw > SW - 24: break
    d1.rounded_rectangle([cx, cur_y, cx + tw, cur_y + 34], radius=17, fill=C_CHIP_BG, outline=C_BORDER, width=1)
    d1.text((cx + 13, cur_y + 9), txt, fill=C_SLATE_900, font=get_font(11, True))
    cx += tw + 10

cur_y += 50

# Thin separator line
d1.line([(24, cur_y), (SW - 24, cur_y)], fill=(241, 245, 249), width=1)
cur_y += 14

# -------------------------------------------------------------------------
# HORIZONTAL SCROLLING TABS STRIP (Exact Image 1 Style)
# -------------------------------------------------------------------------
tabs = [
    ("🏠", "Overview", True),
    ("📍", "Location", False),
    ("⭐", "Amenities", False),
    ("📐", "Floor Plan", False),
    ("💬", "Reviews", False)
]
tx = 24
for icon, title, is_active in tabs:
    t_text = f"{icon} {title}"
    t_width = int(d1.textlength(t_text, font=get_font(11.5, True))) + 26
    if is_active:
        # Active red pill outline + text
        d1.rounded_rectangle([tx, cur_y, tx + t_width, cur_y + 34], radius=17, fill=C_RED_BG, outline=C_RED, width=1)
        d1.text((tx + 13, cur_y + 8), t_text, fill=C_RED, font=get_font(11.5, True))
    else:
        d1.text((tx + 13, cur_y + 8), t_text, fill=C_SLATE_700, font=get_font(11.5, False))
    tx += t_width + 8

cur_y += 48

# -------------------------------------------------------------------------
# SECTION 1: ABOUT THIS PROPERTY (With Red Vertical Accent Bar)
# -------------------------------------------------------------------------
# Red vertical accent bar |
d1.rounded_rectangle([24, cur_y + 2, 28, cur_y + 20], radius=2, fill=C_RED)
d1.text((36, cur_y), "About This Property", fill=C_SLATE_900, font=get_font(15, True))
d1.text((SW - 110, cur_y + 2), "Read More  ›", fill=C_RED, font=get_font(11.5, True))

cur_y += 26
d1.text((24, cur_y), "A beautiful and spacious 3 BHK apartment in the prime location of Indiranagar. This property", fill=C_SLATE_700, font=get_font(11.5, False))
cur_y += 20
d1.text((24, cur_y), "offers modern amenities, excellent connectivity and a peaceful living environment. Perfect", fill=C_SLATE_700, font=get_font(11.5, False))
cur_y += 20
d1.text((24, cur_y), "for families looking for comfort, luxury, and long-term appreciation.", fill=C_SLATE_700, font=get_font(11.5, False))

cur_y += 34

# -------------------------------------------------------------------------
# SECTION 2: AMENITIES (6 Icon Tiles in Soft Rose Tint)
# -------------------------------------------------------------------------
d1.rounded_rectangle([24, cur_y + 2, 28, cur_y + 20], radius=2, fill=C_RED)
d1.text((36, cur_y), "Amenities", fill=C_SLATE_900, font=get_font(15, True))
d1.text((SW - 85, cur_y + 2), "See All  ›", fill=C_RED, font=get_font(11.5, True))

cur_y += 30
amen_list = [
    ("🚗", "Parking"),
    ("🛡️", "24×7 Security"),
    ("🏋️", "Gym"),
    ("🌳", "Garden"),
    ("🛗", "Lift"),
    ("📶", "Wi-Fi")
]
tile_gap = 12
tile_w = (SW - 48 - (5 * tile_gap)) // 6
for i, (a_icon, a_name) in enumerate(amen_list):
    ax = 24 + i * (tile_w + tile_gap)
    # Light rose rounded square tile
    d1.rounded_rectangle([ax, cur_y, ax + tile_w, cur_y + tile_w], radius=15, fill=C_RED_BG)
    d1.text((ax + tile_w//2 - 9, cur_y + 16), a_icon, fill=C_RED, font=get_font(17, False))
    # Label below tile
    tw_lbl = int(d1.textlength(a_name, font=get_font(9.5, True)))
    d1.text((ax + (tile_w - tw_lbl)//2, cur_y + tile_w + 8), a_name, fill=C_SLATE_900, font=get_font(9.5, True))

cur_y += tile_w + 38

# -------------------------------------------------------------------------
# SECTION 3: PROPERTY DETAILS & FLOOR PLAN (2 Side-by-Side Cards)
# -------------------------------------------------------------------------
split_w = (SW - 48 - 14) // 2
split_h = 190

# Left Card: Property Details
d1.rounded_rectangle([24, cur_y, 24 + split_w, cur_y + split_h], radius=16, fill=(255, 255, 255), outline=C_BORDER, width=1)
d1.rounded_rectangle([36, cur_y + 16, 40, cur_y + 32], radius=2, fill=C_RED)
d1.text((46, cur_y + 14), "Property Details", fill=C_SLATE_900, font=get_font(13.5, True))

details = [
    ("🏠  Property Type", ": Apartment"),
    ("🧭  Facing", ": East"),
    ("📐  Built Up Area", ": 1,450 Sq.Ft."),
    ("🏢  Floor", ": 5 of 7"),
    ("⏱️  Age of Property", ": 2 Years")
]
dy = cur_y + 44
for lbl, val in details:
    d1.text((36, dy), lbl, fill=C_SLATE_700, font=get_font(10, False))
    d1.text((150, dy), val, fill=C_SLATE_900, font=get_font(10, True))
    dy += 25

# Right Card: Floor Plan
fx = 24 + split_w + 14
d1.rounded_rectangle([fx, cur_y, fx + split_w, cur_y + split_h], radius=16, fill=(255, 255, 255), outline=C_BORDER, width=1)
d1.text((fx + 14, cur_y + 14), "📐  Floor Plan", fill=C_SLATE_900, font=get_font(13.5, True))
d1.text((fx + split_w - 90, cur_y + 15), "View Full ›", fill=C_RED, font=get_font(10.5, True))

# Render Floor Plan Image or schematic
try:
    if os.path.exists("scratch/floor_plan_crop.png"):
        fp_im = Image.open("scratch/floor_plan_crop.png").convert("RGB")
        fp_res = fp_im.resize((split_w - 24, split_h - 52), Image.Resampling.LANCZOS)
        s1.paste(fp_res, (fx + 12, cur_y + 40))
        d1.rounded_rectangle([fx + 12, cur_y + 40, fx + split_w - 12, cur_y + split_h - 12], radius=10, outline=C_BORDER, width=1)
    else:
        d1.rounded_rectangle([fx + 12, cur_y + 40, fx + split_w - 12, cur_y + split_h - 12], radius=10, fill=C_CHIP_BG)
except Exception:
    d1.rounded_rectangle([fx + 12, cur_y + 40, fx + split_w - 12, cur_y + split_h - 12], radius=10, fill=C_CHIP_BG)

cur_y += split_h + 24

# -------------------------------------------------------------------------
# SECTION 4: LOCATION (Mini Map + Address + Open in Maps Button)
# -------------------------------------------------------------------------
loc_h = 100
d1.rounded_rectangle([24, cur_y, SW - 24, cur_y + loc_h], radius=16, fill=(255, 255, 255), outline=C_BORDER, width=1)
# Map preview on left
try:
    if os.path.exists("scratch/map_crop.png"):
        map_im = Image.open("scratch/map_crop.png").convert("RGB")
        map_res = map_im.resize((150, loc_h - 20), Image.Resampling.LANCZOS)
        s1.paste(map_res, (36, cur_y + 10))
        d1.rounded_rectangle([36, cur_y + 10, 186, cur_y + loc_h - 10], radius=10, outline=C_BORDER, width=1)
    else:
        d1.rounded_rectangle([36, cur_y + 10, 186, cur_y + loc_h - 10], radius=10, fill=C_CHIP_BG)
except Exception:
    d1.rounded_rectangle([36, cur_y + 10, 186, cur_y + loc_h - 10], radius=10, fill=C_CHIP_BG)

# Location text on right
d1.text((200, cur_y + 18), "Indiranagar, Bengaluru", fill=C_SLATE_900, font=get_font(13.5, True))
d1.text((200, cur_y + 40), "📍  2.5 km from MG Road", fill=C_SLATE_500, font=get_font(11, False))
# Open in Maps button
d1.rounded_rectangle([200, cur_y + 62, 330, cur_y + 90], radius=14, outline=C_RED, width=1)
d1.text((214, cur_y + 68), "📍  Open in Maps", fill=C_RED, font=get_font(10.5, True))

cur_y += loc_h + 20

# -------------------------------------------------------------------------
# SECTION 5: REVIEWS & RATINGS (4.8 Stars + Testimonial)
# -------------------------------------------------------------------------
rev_h = 86
d1.rounded_rectangle([24, cur_y, SW - 24, cur_y + rev_h], radius=16, fill=(255, 255, 255), outline=C_BORDER, width=1)
d1.rounded_rectangle([36, cur_y + 14, 40, cur_y + 28], radius=2, fill=C_RED)
d1.text((46, cur_y + 12), "Reviews & Ratings", fill=C_SLATE_900, font=get_font(13.5, True))
d1.text((SW - 95, cur_y + 14), "See All  ›", fill=C_RED, font=get_font(10.5, True))

# Score
d1.text((36, cur_y + 40), "4.8", fill=C_SLATE_900, font=get_font(20, True))
d1.text((75, cur_y + 44), "⭐  (500+ Reviews)", fill=C_SLATE_500, font=get_font(10.5, False))

# User quote
d1.ellipse([230, cur_y + 38, 262, cur_y + 70], fill=(225, 235, 245))
d1.text((240, cur_y + 44), "👤", fill=C_SLATE_700, font=get_font(14, False))
d1.text((272, cur_y + 38), "\"Excellent property, prime location and spacious layout.\"", fill=C_SLATE_700, font=get_font(10, False))
d1.text((272, cur_y + 56), "⭐⭐⭐⭐⭐  •  Rahul V., Verified Buyer", fill=(245, 158, 11), font=get_font(9.5, True))

# -------------------------------------------------------------------------
# STICKY BOTTOM BAR (Fixed at bottom)
# -------------------------------------------------------------------------
bot_h = 85
by = SH - bot_h
d1.rectangle([0, by, SW, SH], fill=(255, 255, 255))
d1.line([(0, by), (SW, by)], fill=C_BORDER, width=1)

btn_w = (SW - 48 - 14) // 2
btn_h = 52
# Left: [ 📅  Schedule Visit ] (Outlined red)
d1.rounded_rectangle([24, by + 16, 24 + btn_w, by + 16 + btn_h], radius=14, outline=C_RED, width=2)
d1.text((24 + btn_w//2 - 62, by + 32), "📅  Schedule Visit", fill=C_RED, font=get_font(13.5, True))

# Right: [ 📞  Call Now ] (Solid Red)
d1.rounded_rectangle([24 + btn_w + 14, by + 16, SW - 24, by + 16 + btn_h], radius=14, fill=C_RED)
d1.text((24 + btn_w + 14 + btn_w//2 - 45, by + 32), "📞  Call Now", fill=(255, 255, 255), font=get_font(13.5, True))


# =========================================================================
# PHONE 2: FULL-SCREEN ANIMATED SKELETON SHIMMER STATE
# =========================================================================
s2 = Image.new("RGB", (SW, SH), (255, 255, 255))
d2 = ImageDraw.Draw(s2)

# Shimmer helper with soft wave effect
def draw_shimmer_rect(d_obj, box, radius=8):
    x0, y0, x1, y1 = box
    d_obj.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=C_SHIM_BASE)
    # soft sweep highlight line in center
    hw = (x1 - x0) // 3
    hx0 = x0 + hw
    hx1 = hx0 + hw
    d_obj.rounded_rectangle([hx0, y0, hx1, y1], radius=radius, fill=C_SHIM_WAVE)

# Top Hero Shimmer
draw_shimmer_rect(d2, [0, 0, SW, hero_h], radius=0)

# Status bar on Phone 2
d2.text((36, 14), "9:41", fill=(180, 190, 200), font=get_font(13.5, True))
d2.rounded_rectangle([SW//2 - 62, 10, SW//2 + 62, 36], radius=13, fill=(180, 190, 200))
d2.text((SW - 110, 14), "📶 5G  🔋", fill=(180, 190, 200), font=get_font(12, True))

# Floating nav shimmer
d2.ellipse([22, 52, 66, 96], fill=(255, 255, 255, 220))
d2.ellipse([SW - 118, 52, SW - 74, 96], fill=(255, 255, 255, 220))
d2.ellipse([SW - 66, 52, SW - 22, 96], fill=(255, 255, 255, 220))

# Hero pill shimmers
draw_shimmer_rect(d2, [22, hero_h - 48, 115, hero_h - 16], radius=16)
draw_shimmer_rect(d2, [SW - 146, hero_h - 48, SW - 22, hero_h - 16], radius=16)

# Content Shimmers
sy = hero_h + 16

# Row 1: Price & trend skeleton
draw_shimmer_rect(d2, [24, sy + 4, 210, sy + 38], radius=8)
draw_shimmer_rect(d2, [SW - 24 - 190, sy + 4, SW - 24, sy + 32], radius=14)

sy += 50
# Row 2: Title & For sale skeleton
draw_shimmer_rect(d2, [24, sy, 320, sy + 28], radius=8)
draw_shimmer_rect(d2, [SW - 24 - 100, sy, SW - 24, sy + 28], radius=14)

sy += 38
# Row 3: Subtitle
draw_shimmer_rect(d2, [24, sy, 260, sy + 18], radius=6)

sy += 30
# Row 4: Image 2 Pill Chips Shimmer
cx = 24
for w in [110, 115, 120, 95]:
    draw_shimmer_rect(d2, [cx, sy, cx + w, sy + 34], radius=17)
    cx += w + 10

sy += 44
cx = 24
for w in [110, 105, 130]:
    draw_shimmer_rect(d2, [cx, sy, cx + w, sy + 34], radius=17)
    cx += w + 10

sy += 50
d2.line([(24, sy), (SW - 24, sy)], fill=(241, 245, 249), width=1)
sy += 14

# Tab bar Shimmer
tx = 24
for w in [100, 95, 105, 105, 90]:
    draw_shimmer_rect(d2, [tx, sy, tx + w, sy + 34], radius=17)
    tx += w + 8

sy += 48
# Section 1: About Shimmer
draw_shimmer_rect(d2, [24, sy, 180, sy + 20], radius=4)
sy += 28
draw_shimmer_rect(d2, [24, sy, SW - 48, sy + 16], radius=4)
sy += 22
draw_shimmer_rect(d2, [24, sy, SW - 100, sy + 16], radius=4)

sy += 36
# Section 2: Amenities Shimmer (6 Tiles)
draw_shimmer_rect(d2, [24, sy, 130, sy + 20], radius=4)
sy += 30
for i in range(6):
    ax = 24 + i * (tile_w + tile_gap)
    draw_shimmer_rect(d2, [ax, sy, ax + tile_w, sy + tile_w], radius=15)
    draw_shimmer_rect(d2, [ax + 8, sy + tile_w + 8, ax + tile_w - 8, sy + tile_w + 20], radius=4)

sy += tile_w + 38
# Section 3: Split Details & Floor Plan Shimmer
draw_shimmer_rect(d2, [24, sy, 24 + split_w, sy + split_h], radius=16)
draw_shimmer_rect(d2, [fx, sy, fx + split_w, sy + split_h], radius=16)

sy += split_h + 24
# Section 4: Location Shimmer
draw_shimmer_rect(d2, [24, sy, SW - 24, sy + loc_h], radius=16)

# Bottom Bar Shimmer
d2.rectangle([0, by, SW, SH], fill=(255, 255, 255))
d2.line([(0, by), (SW, by)], fill=C_BORDER, width=1)
draw_shimmer_rect(d2, [24, by + 16, 24 + btn_w, by + 16 + btn_h], radius=14)
draw_shimmer_rect(d2, [24 + btn_w + 14, by + 16, SW - 24, by + 16 + btn_h], radius=14)


# =========================================================================
# PASTE BOTH PHONES ONTO CANVAS
# =========================================================================
# Phone 1 (Left: Loaded State)
x1_offset = 160
y_offset = 175
draw_phone_case(x1_offset, y_offset)

mask = Image.new("L", (SW, SH), 0)
m_draw = ImageDraw.Draw(mask)
m_draw.rounded_rectangle([0, 0, SW, SH], radius=42, fill=255)

canvas.paste(s1, (x1_offset + 30, y_offset + 50), mask)

# Phone 1 Label Pill
lbl_y = y_offset + PH + 24
c_draw.rounded_rectangle([x1_offset + PW//2 - 180, lbl_y, x1_offset + PW//2 + 180, lbl_y + 44], radius=22, fill=(255, 255, 255), outline=C_RED, width=2)
c_draw.text((x1_offset + PW//2 - 155, lbl_y + 12), "✓  PHONE 1: LOADED REDESIGN", fill=C_RED, font=get_font(13.5, True))


# Phone 2 (Right: Shimmer State)
x2_offset = CW - 160 - PW
draw_phone_case(x2_offset, y_offset)
canvas.paste(s2, (x2_offset + 30, y_offset + 50), mask)

# Phone 2 Label Pill
c_draw.rounded_rectangle([x2_offset + PW//2 - 190, lbl_y, x2_offset + PW//2 + 190, lbl_y + 44], radius=22, fill=(255, 255, 255), outline=C_SLATE_700, width=2)
c_draw.text((x2_offset + PW//2 - 165, lbl_y + 12), "⚡  PHONE 2: SKELETON SHIMMER", fill=C_SLATE_700, font=get_font(13.5, True))


# Save Canvas Image
dual_out = os.path.join(brain_dir, "buyer_details_dual_phone_preview.png")
canvas.save(dual_out, quality=95)
print(f"Dual phone preview saved successfully to {dual_out}")

# Also save standalone single phone image
single_out = os.path.join(brain_dir, "property_details_phone_preview.png")
single_canvas = Image.new("RGB", (PW + 80, PH + 120), (248, 250, 252))
sc_draw = ImageDraw.Draw(single_canvas)
# shadow
sh_box = Image.new("RGBA", (PW + 40, PH + 40), (0, 0, 0, 0))
ImageDraw.Draw(sh_box).rounded_rectangle([20, 26, PW + 20, PH + 26], radius=corner_r + 4, fill=(15, 23, 42, 40))
sh_box = sh_box.filter(ImageFilter.GaussianBlur(22))
single_canvas.paste(sh_box, (20, 20), sh_box)
# case
sc_draw.rounded_rectangle([40, 30, 40 + PW, 30 + PH], radius=corner_r, fill=(28, 32, 38), outline=(60, 68, 78), width=4)
single_canvas.paste(s1, (70, 80), mask)
single_canvas.save(single_out, quality=95)
print(f"Single phone preview saved successfully to {single_out}")
