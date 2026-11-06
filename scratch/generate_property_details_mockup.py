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

# Screen Dimensions (High-Res Mobile Mockup: 840 x 2200)
W, H = 840, 2150
img = Image.new("RGB", (W, H), (248, 250, 252))
draw = ImageDraw.Draw(img)

# Colors
C_TEAL = (0, 122, 94)          # #007A5E - DigiNiwas signature
C_DARK_TEAL = (8, 48, 38)      # Deep luxury
C_GOLD = (212, 160, 23)        # Trust gold
C_GOLD_SOFT = (254, 247, 230)
C_MINT_SOFT = (232, 247, 242)
C_INK = (15, 23, 42)           # #0F172A slate 900
C_BODY = (71, 85, 105)         # slate 600
C_MUTED = (148, 163, 184)      # slate 400
C_CARD_BG = (255, 255, 255)
C_BORDER = (226, 232, 240)
C_BLUE = (37, 99, 235)

# -------------------------------------------------------------
# 1. TOP HERO SECTION (PHOTO CAROUSEL & FLOATING ACTIONS)
# -------------------------------------------------------------
hero_h = 440

# Load background photo if available
try:
    hero_raw = Image.open("assets/images/compare_home.png").convert("RGB")
    # Crop to 840x440
    rw, rh = hero_raw.size
    target_ratio = W / hero_h
    raw_ratio = rw / rh
    if raw_ratio > target_ratio:
        new_w = int(rh * target_ratio)
        hero_crop = hero_raw.crop(((rw - new_w) // 2, 0, (rw + new_w) // 2, rh))
    else:
        new_h = int(rw / target_ratio)
        hero_crop = hero_raw.crop((0, (rh - new_h) // 2, rw, (rh + new_h) // 2))
    hero_img = hero_crop.resize((W, hero_h), Image.Resampling.LANCZOS)
    img.paste(hero_img, (0, 0))
except Exception as e:
    draw.rectangle([0, 0, W, hero_h], fill=(30, 41, 59))

# Dark gradient overlay on top & bottom of hero for legibility
top_grad = Image.new("RGBA", (W, 110), (0, 0, 0, 0))
t_draw = ImageDraw.Draw(top_grad)
for y in range(110):
    alpha = int(140 * (1 - y / 110))
    t_draw.line([(0, y), (W, y)], fill=(0, 0, 0, alpha))
img.paste(top_grad, (0, 0), top_grad)

bot_grad = Image.new("RGBA", (W, 140), (0, 0, 0, 0))
b_draw = ImageDraw.Draw(bot_grad)
for y in range(140):
    alpha = int(180 * (y / 140))
    b_draw.line([(0, y), (W, y)], fill=(0, 0, 0, alpha))
img.paste(bot_grad, (0, hero_h - 140), bot_grad)

# Top Bar Floating Navigation Buttons
# Back button
draw.rounded_rectangle([24, 44, 72, 92], radius=24, fill=(255, 255, 255, 230), outline=(255, 255, 255))
draw.text((38, 54), "←", fill=C_INK, font=get_font(24, True))

# Right actions: Share, Favorite, 360 Tour
draw.rounded_rectangle([W - 170, 44, W - 122, 92], radius=24, fill=(255, 255, 255, 230))
draw.text((W - 156, 56), "↗", fill=C_INK, font=get_font(20, True))

draw.rounded_rectangle([W - 114, 44, W - 66, 92], radius=24, fill=(255, 255, 255, 230))
draw.text((W - 100, 56), "♥", fill=(239, 68, 68), font=get_font(20, True))

draw.rounded_rectangle([W - 58, 44, W - 24, 92], radius=17, fill=(255, 255, 255, 230))
draw.text((W - 47, 56), "⋮", fill=C_INK, font=get_font(20, True))

# Floating Badges on Hero Image (Bottom Left & Right)
# Verified Pill
draw.rounded_rectangle([24, hero_h - 58, 220, hero_h - 20], radius=19, fill=(0, 122, 94, 240), outline=(153, 246, 228))
draw.text((40, hero_h - 48), "🛡️ Verified Property", fill=(255, 255, 255), font=get_font(13, True))

# 360 Virtual Tour Pill
draw.rounded_rectangle([230, hero_h - 58, 380, hero_h - 20], radius=19, fill=(15, 23, 42, 220), outline=(255, 255, 255))
draw.text((246, hero_h - 48), "🔄 360° Tour", fill=(255, 255, 255), font=get_font(13, True))

# Photo Count Pill (Bottom Right)
draw.rounded_rectangle([W - 130, hero_h - 58, W - 24, hero_h - 20], radius=19, fill=(15, 23, 42, 220))
draw.text((W - 114, hero_h - 48), "📷 1 / 18", fill=(255, 255, 255), font=get_font(13, True))

# Carousel Thumbnail Peek Bar
t_y = hero_h + 10
draw.text((24, t_y), "Photos & Floor Plans", fill=C_BODY, font=get_font(12, True))
draw.text((W - 120, t_y), "View All (18) →", fill=C_TEAL, font=get_font(12, True))

thumb_w = 140
thumb_h = 75
for i in range(5):
    tx = 24 + i * (thumb_w + 12)
    if tx + thumb_w > W: break
    draw.rounded_rectangle([tx, t_y + 24, tx + thumb_w, t_y + 24 + thumb_h], radius=10, fill=(226, 232, 240), outline=C_TEAL if i==0 else C_BORDER, width=2 if i==0 else 1)
    label = ["Living Room", "Master Bed", "Modular Kit", "Balcony View", "Floor Plan"][i]
    draw.text((tx + 12, t_y + 50), label, fill=C_INK if i==0 else C_BODY, font=get_font(11, True))

# -------------------------------------------------------------
# 2. TITLE, PRICE & FINANCIAL TRANSPARENCY CARD
# -------------------------------------------------------------
p_y = t_y + 125
draw.rounded_rectangle([20, p_y, W - 20, p_y + 185], radius=18, fill=C_CARD_BG, outline=C_BORDER, width=1)

# Status Pill & RERA ID
draw.rounded_rectangle([40, p_y + 18, 150, p_y + 44], radius=13, fill=C_MINT_SOFT)
draw.text((54, p_y + 24), "● Ready to Move", fill=C_TEAL, font=get_font(11, True))

draw.rounded_rectangle([158, p_y + 18, 280, p_y + 44], radius=13, fill=(241, 245, 249))
draw.text((170, p_y + 24), "RERA: UPRERAPRJ9921", fill=C_BODY, font=get_font(11, False))

draw.text((W - 120, p_y + 24), "ID: DNP-8821", fill=C_MUTED, font=get_font(11, False))

# Property Title
draw.text((40, p_y + 54), "Mahagun Moderne 3 BHK Luxury Penthouse", fill=C_INK, font=get_font(21, True))
draw.text((40, p_y + 84), "📍 Sector 78, Noida, Expressway Corridor, NCR", fill=C_BODY, font=get_font(13, False))

# Price & EMI Section
draw.line([(40, p_y + 115), (W - 40, p_y + 115)], fill=(241, 245, 249), width=1)
draw.text((40, p_y + 128), "₹ 1.45 Cr", fill=C_TEAL, font=get_font(28, True))
draw.text((195, p_y + 138), "@ ₹ 7,837 / sq.ft", fill=C_BODY, font=get_font(13, False))

# EMI Pill with Calculator Trigger
draw.rounded_rectangle([W - 270, p_y + 128, W - 40, p_y + 168], radius=12, fill=C_GOLD_SOFT, outline=(245, 215, 140))
draw.text((W - 256, p_y + 138), "Est. EMI: ₹78.4K/mo 🧮", fill=(161, 98, 7), font=get_font(12, True))

# -------------------------------------------------------------
# 3. 🛡️ DIGINIWAS 100% BUYER TRUST SHIELD (THE WOW FACTOR)
# -------------------------------------------------------------
t_box_y = p_y + 205
draw.rounded_rectangle([20, t_box_y, W - 20, t_box_y + 175], radius=18, fill=(250, 255, 253), outline=(167, 243, 208), width=2)

# Header
draw.rounded_rectangle([36, t_box_y + 16, 175, t_box_y + 40], radius=12, fill=C_TEAL)
draw.text((46, t_box_y + 20), "DIGINIWAS TRUST SHIELD", fill=(255, 255, 255), font=get_font(9.5, True))

draw.text((188, t_box_y + 20), "100% Verified & Protected Buying Process", fill=C_TEAL, font=get_font(13, True))

# 4 Trust Pillars Grid
trust_items = [
    ("⚖️ 100% Legal Title Clear", "Occupancy Cert (OC) & Registry Ready"),
    ("🛡️ Zero Brokerage Guarantee", "Direct Verified Seller, no hidden fees"),
    ("🔍 On-Site Physical Inspection", "Inspected by DigiNiwas Engg (25 Oct)"),
    ("🏦 Instant Bank Pre-Approval", "Pre-approved by SBI, HDFC & ICICI Bank"),
]

for idx, (head, sub) in enumerate(trust_items):
    col = idx % 2
    row = idx // 2
    ix = 40 + col * ((W - 80) // 2)
    iy = t_box_y + 55 + row * 52
    draw.text((ix, iy), head, fill=C_INK, font=get_font(13, True))
    draw.text((ix, iy + 20), sub, fill=C_BODY, font=get_font(11, False))

# -------------------------------------------------------------
# 4. KEY SPECIFICATIONS (ELEVATED 6-CARD GRID)
# -------------------------------------------------------------
spec_y = t_box_y + 195
draw.text((24, spec_y), "Property Configuration & Specs", fill=C_INK, font=get_font(17, True))

specs = [
    ("🛏️ Bedrooms", "3 BHK Luxury", "1,850 sq.ft (Super Built)"),
    ("🛁 Bathrooms", "3 Baths", "Attached Western Fittings"),
    ("🧭 Direction", "East Facing", "100% Vastu Compliant"),
    ("🏢 Floor Level", "14th of 26", "Pool & Green View"),
    ("🚗 Parking", "2 Covered", "Basement Reserved Slots"),
    ("🛋️ Furnishing", "Semi-Furnished", "Modular Kitchen + Woodwork"),
]

card_w = (W - 40 - 20) // 3
card_h = 100

for i, (cat, val, extra) in enumerate(specs):
    c = i % 3
    r = i // 3
    cx0 = 20 + c * (card_w + 10)
    cy0 = spec_y + 30 + r * (card_h + 10)
    cx1 = cx0 + card_w
    cy1 = cy0 + card_h

    draw.rounded_rectangle([cx0, cy0, cx1, cy1], radius=14, fill=C_CARD_BG, outline=C_BORDER)
    draw.text((cx0 + 12, cy0 + 12), cat, fill=C_BODY, font=get_font(11, False))
    draw.text((cx0 + 12, cy0 + 36), val, fill=C_INK, font=get_font(15, True))
    draw.text((cx0 + 12, cy0 + 64), extra, fill=C_MUTED, font=get_font(10, False))

# -------------------------------------------------------------
# 5. ASSIGNED DIGINIWAS CERTIFIED PARTNER (HUMAN TRUST)
# -------------------------------------------------------------
agent_y = spec_y + 265
draw.rounded_rectangle([20, agent_y, W - 20, agent_y + 140], radius=18, fill=C_CARD_BG, outline=C_BORDER)

# Agent Avatar placeholder circle
draw.ellipse([40, agent_y + 22, 115, agent_y + 97], fill=C_TEAL)
draw.text((57, agent_y + 40), "RS", fill=(255, 255, 255), font=get_font(24, True))

# Agent Info
draw.text((130, agent_y + 22), "Rahul Sharma", fill=C_INK, font=get_font(17, True))
draw.rounded_rectangle([260, agent_y + 24, 390, agent_y + 46], radius=8, fill=C_MINT_SOFT)
draw.text((270, agent_y + 27), "✓ Verified Partner", fill=C_TEAL, font=get_font(10.5, True))

draw.text((130, agent_y + 50), "Senior Area Specialist • Sector 78 & Expressway", fill=C_BODY, font=get_font(12, False))
draw.text((130, agent_y + 72), "⭐ 4.95 Rating (64 Successful Closings)  •  Fast Response (<10 mins)", fill=C_GOLD, font=get_font(11.5, True))

# Agent Quick Buttons
draw.rounded_rectangle([W - 190, agent_y + 24, W - 40, agent_y + 64], radius=10, fill=(37, 211, 102))
draw.text((W - 170, agent_y + 34), "💬 WhatsApp", fill=(255, 255, 255), font=get_font(12, True))

draw.rounded_rectangle([W - 190, agent_y + 74, W - 40, agent_y + 114], radius=10, fill=C_MINT_SOFT, outline=C_TEAL)
draw.text((W - 164, agent_y + 84), "📞 Call Direct", fill=C_TEAL, font=get_font(12, True))

# -------------------------------------------------------------
# 6. NEIGHBORHOOD & CONNECTIVITY SCORE (DIGINIWAS AI)
# -------------------------------------------------------------
loc_y = agent_y + 160
draw.rounded_rectangle([20, loc_y, W - 20, loc_y + 170], radius=18, fill=C_CARD_BG, outline=C_BORDER)

# Score header
draw.text((40, loc_y + 18), "Locality & Connectivity Index", fill=C_INK, font=get_font(16, True))
draw.rounded_rectangle([W - 180, loc_y + 16, W - 40, loc_y + 46], radius=10, fill=(240, 253, 244), outline=C_TEAL)
draw.text((W - 168, loc_y + 22), "⭐ 9.2 / 10 Excellent", fill=C_TEAL, font=get_font(11.5, True))

places = [
    ("🚇 Sector 76 Metro Station", "600m • 7 min walk", "Blue Line Direct to CP"),
    ("🏥 Fortis Hospital Noida", "2.1 km • 6 min drive", "24/7 Multi-specialty"),
    ("🎓 DPS & Shiv Nadar School", "1.4 km • 4 min drive", "Top Ranked CBSE"),
    ("🛒 Spectrum Metro Mall", "800m • 3 min drive", "Cinema, Food Court & Retail"),
]

for idx, (p_title, p_dist, p_desc) in enumerate(places):
    col = idx % 2
    row = idx // 2
    px = 40 + col * ((W - 80) // 2)
    py = loc_y + 60 + row * 48
    draw.text((px, py), p_title, fill=C_INK, font=get_font(12.5, True))
    draw.text((px, py + 18), f"{p_dist}  |  {p_desc}", fill=C_MUTED, font=get_font(10.5, False))

# -------------------------------------------------------------
# 7. TOP AMENITIES STRIP
# -------------------------------------------------------------
amen_y = loc_y + 190
draw.text((24, amen_y), "Premium Society Amenities (35+)", fill=C_INK, font=get_font(16, True))

amen_list = ["🏊 Clubhouse & Olympic Pool", "🎾 Tennis & Badminton", "🏋️ 24/7 Gym & Spa", "🌳 75% Lush Green Park", "🛡️ 3-Tier Smart Security"]
for i, a_text in enumerate(amen_list):
    ax = 20 + i * 160
    if ax + 150 > W: break
    draw.rounded_rectangle([ax, amen_y + 30, ax + 150, amen_y + 85], radius=12, fill=C_CARD_BG, outline=C_BORDER)
    draw.text((ax + 12, amen_y + 45), a_text.split(" ")[0], fill=C_INK, font=get_font(18, False))
    draw.text((ax + 12, amen_y + 65), " ".join(a_text.split(" ")[1:]), fill=C_INK, font=get_font(10.5, True))

# -------------------------------------------------------------
# 8. STICKY FLOATING LUXURY BOTTOM ACTION BAR
# -------------------------------------------------------------
foot_h = 110
foot_y = H - foot_h

# Backdrop blur simulation
draw.rectangle([0, foot_y - 20, W, H], fill=(255, 255, 255))
draw.line([(0, foot_y - 20), (W, foot_y - 20)], fill=(226, 232, 240), width=2)

# Left Price + EMI
draw.text((28, foot_y - 5), "₹ 1.45 Cr", fill=C_TEAL, font=get_font(24, True))
draw.text((28, foot_y + 28), "EMI from ₹78,400/mo  •  All-incl.", fill=C_BODY, font=get_font(11.5, False))

# Action Buttons on Right
# 1. WhatsApp icon button
draw.rounded_rectangle([W - 390, foot_y - 5, W - 325, foot_y + 55], radius=16, fill=(37, 211, 102))
draw.text((W - 365, foot_y + 12), "💬", fill=(255, 255, 255), font=get_font(22, True))

# 2. Free Site Visit Primary CTA (High Conversion)
draw.rounded_rectangle([W - 315, foot_y - 5, W - 24, foot_y + 55], radius=16, fill=C_TEAL)
draw.text((W - 275, foot_y + 8), "📅 Schedule Site Visit", fill=(255, 255, 255), font=get_font(14, True))
draw.text((W - 248, foot_y + 32), "Free Cab Pickup & Tour", fill=(153, 246, 228), font=get_font(10.5, False))

out_path = os.path.join(brain_dir, "buyer_property_details_redesign.png")
img.save(out_path, quality=95)
print("Saved premium mockup to:", out_path)
