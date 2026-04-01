#!/usr/bin/env python3
"""
SIPELOR BEDAS – PowerPoint Generator v2 (FULL IMAGE VERSION)
Every slide has a full-bleed photo background + semi-transparent overlay + content.
"""

import os
import sys
import urllib.request
import urllib.error
from io import BytesIO

from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN

# ─── DIMENSIONS ─────────────────────────────────────────────────────────────
SLIDE_W = Inches(13.333)
SLIDE_H = Inches(7.5)

# ─── COLORS ─────────────────────────────────────────────────────────────────
GREEN    = RGBColor(0x00, 0x71, 0x48)
BLUE     = RGBColor(0x00, 0x75, 0xA4)
DARK     = RGBColor(0x00, 0x0E, 0x15)
WHITE    = RGBColor(0xFF, 0xFF, 0xFF)
GOLD     = RGBColor(0xFF, 0xC1, 0x07)
RED_ERR  = RGBColor(0xE5, 0x39, 0x35)
PURPLE   = RGBColor(0x6A, 0x1B, 0x9A)
ORANGE   = RGBColor(0xFF, 0x88, 0x00)
GREEN_L  = RGBColor(0x00, 0x50, 0x35)
BLUE_D   = RGBColor(0x00, 0x30, 0x55)

# ─── IMAGE URLS per slide ────────────────────────────────────────────────────
IMAGES = {
    "stadium_bk":  "https://images.pexels.com/photos/3452544/pexels-photo-3452544.jpeg?auto=compress&cs=tinysrgb&w=1920",
    "courts_top":  "https://images.pexels.com/photos/29821186/pexels-photo-29821186.jpeg?auto=compress&cs=tinysrgb&w=1920",
    "futsal_act":  "https://images.pexels.com/photos/29388472/pexels-photo-29388472.jpeg?auto=compress&cs=tinysrgb&w=1920",
    "smartphone":  "https://images.pexels.com/photos/4428985/pexels-photo-4428985.jpeg?auto=compress&cs=tinysrgb&w=1920",
    "phone_app":   "https://images.pexels.com/photos/32665242/pexels-photo-32665242.jpeg?auto=compress&cs=tinysrgb&w=1920",
    "analytics":   "https://images.pexels.com/photos/3861957/pexels-photo-3861957.jpeg?auto=compress&cs=tinysrgb&w=1920",
    "code_scr":    "https://images.pexels.com/photos/374563/pexels-photo-374563.jpeg?auto=compress&cs=tinysrgb&w=1920",
    "server":      "https://images.pexels.com/photos/17489153/pexels-photo-17489153.jpeg?auto=compress&cs=tinysrgb&w=1920",
    "security":    "https://pixabay.com/get/g62a1ac8d0dc0a72648507c35324a2babbe16b8d309c865d96b4bd237ef795f93846ba6389f57d55b298461c660dc5c4a.jpg",
    "badminton":   "https://images.pexels.com/photos/8007076/pexels-photo-8007076.jpeg?auto=compress&cs=tinysrgb&w=1920",
    "graph_fin":   "https://images.pexels.com/photos/5784807/pexels-photo-5784807.jpeg?auto=compress&cs=tinysrgb&w=1920",
    "growth":      "https://images.pexels.com/photos/5849583/pexels-photo-5849583.jpeg?auto=compress&cs=tinysrgb&w=1920",
    "workspace":   "https://images.pexels.com/photos/8636589/pexels-photo-8636589.jpeg?auto=compress&cs=tinysrgb&w=1920",
    "planning":    "https://images.pexels.com/photos/7413996/pexels-photo-7413996.jpeg?auto=compress&cs=tinysrgb&w=1920",
    "chart_col":   "https://images.pexels.com/photos/7054380/pexels-photo-7054380.jpeg?auto=compress&cs=tinysrgb&w=1920",
    "aerial_sc":   "https://images.pexels.com/photos/9739469/pexels-photo-9739469.jpeg?auto=compress&cs=tinysrgb&w=1920",
    "futsal_girl": "https://images.pexels.com/photos/16378321/pexels-photo-16378321.jpeg?auto=compress&cs=tinysrgb&w=1920",
    "govt_bldg":   "https://images.pexels.com/photos/4267308/pexels-photo-4267308.jpeg?auto=compress&cs=tinysrgb&w=1920",
    "soccer_field":"https://images.unsplash.com/photo-1716745559715-282bb61e3012?crop=entropy&cs=srgb&fm=jpg&w=1920&q=85",
    "badminton2":  "https://images.pexels.com/photos/26238656/pexels-photo-26238656.jpeg?auto=compress&cs=tinysrgb&w=1920",
}

IMG_CACHE = {}  # key -> BytesIO or local path

def download_image(key, url):
    """Download image and cache in-memory."""
    if key in IMG_CACHE:
        return IMG_CACHE[key]
    print(f"    ↓ Downloading {key}...")
    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                          "AppleWebKit/537.36 (KHTML, like Gecko) "
                          "Chrome/120.0.0.0 Safari/537.36"
        })
        with urllib.request.urlopen(req, timeout=20) as r:
            data = r.read()
        buf = BytesIO(data)
        IMG_CACHE[key] = buf
        print(f"    ✓ {key} ({len(data)//1024} KB)")
        return buf
    except Exception as e:
        print(f"    ✗ {key} failed: {e}")
        return None


def prefetch_all():
    """Download all images before building slides."""
    print("\n📥 Downloading background images...")
    for key, url in IMAGES.items():
        download_image(key, url)
    print(f"   Downloaded {len(IMG_CACHE)}/{len(IMAGES)} images.\n")


# ─── HELPERS ─────────────────────────────────────────────────────────────────

def add_slide(prs):
    return prs.slides.add_slide(prs.slide_layouts[6])  # blank


def place_bg(slide, img_key, crop_top=0.0, crop_left=0.0):
    """Place full-bleed background image."""
    buf = IMG_CACHE.get(img_key)
    if buf is None:
        return
    buf.seek(0)
    pic = slide.shapes.add_picture(buf, Inches(-0.1), Inches(-0.1),
                                   SLIDE_W + Inches(0.2), SLIDE_H + Inches(0.2))
    # Send picture to back
    slide.shapes._spTree.remove(pic._element)
    slide.shapes._spTree.insert(2, pic._element)


def overlay(slide, color, transparency=0.45,
            left=0, top=0, w=None, h=None):
    """Add semi-transparent colored overlay."""
    w = w or SLIDE_W
    h = h or SLIDE_H
    shape = slide.shapes.add_shape(1, left, top, w, h)
    shape.fill.solid()
    shape.fill.fore_color.rgb = color
    shape.fill.transparency = transparency
    shape.line.fill.background()
    return shape


def rect(slide, left, top, width, height, color, alpha=0.0):
    shape = slide.shapes.add_shape(1, left, top, width, height)
    shape.fill.solid()
    shape.fill.fore_color.rgb = color
    shape.fill.transparency = alpha
    shape.line.fill.background()
    return shape


def tx(slide, text, left, top, width, height,
       size=18, bold=False, color=WHITE,
       align=PP_ALIGN.LEFT, italic=False, wrap=True, name="Mulish"):
    """Add styled textbox."""
    tb = slide.shapes.add_textbox(left, top, width, height)
    tb.word_wrap = wrap
    tf = tb.text_frame
    tf.word_wrap = wrap
    p = tf.paragraphs[0]
    p.alignment = align
    run = p.add_run()
    run.text = text
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.italic = italic
    run.font.color.rgb = color
    run.font.name = name
    return tb


def tx_multi(slide, lines, left, top, width, height,
             size=14, bold=False, color=WHITE, align=PP_ALIGN.LEFT,
             spacing=4, name="Mulish"):
    """Multi-line textbox."""
    tb = slide.shapes.add_textbox(left, top, width, height)
    tb.word_wrap = True
    tf = tb.text_frame
    tf.word_wrap = True
    for i, line in enumerate(lines):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = align
        p.space_before = Pt(spacing)
        run = p.add_run()
        run.text = line
        run.font.size = Pt(size)
        run.font.bold = bold
        run.font.color.rgb = color
        run.font.name = name
    return tb


def header(slide, title, subtitle=None,
           bg_color=GREEN, text_color=WHITE, sub_color=GOLD,
           h=Inches(1.35)):
    """Top header bar with translucent background."""
    rect(slide, 0, 0, SLIDE_W, h, bg_color, alpha=0.1)
    # Left accent line
    rect(slide, 0, 0, Inches(0.12), h, GOLD, alpha=0.0)
    tx(slide, title, Inches(0.3), Inches(0.12), Inches(12.5), h - Inches(0.15),
       size=34, bold=True, color=text_color)
    if subtitle:
        tx(slide, subtitle, Inches(0.3), h - Inches(0.38),
           Inches(12.5), Inches(0.35), size=14, color=sub_color)


def footer_bar(slide, text="DISPORA Kabupaten Bandung  •  SIPELOR BEDAS  •  2026"):
    rect(slide, 0, SLIDE_H - Inches(0.42), SLIDE_W, Inches(0.42), DARK, alpha=0.2)
    tx(slide, text, Inches(0.4), SLIDE_H - Inches(0.4), SLIDE_W - Inches(0.5),
       Inches(0.38), size=10, color=WHITE, align=PP_ALIGN.CENTER)


def card(slide, left, top, width, height, fill=WHITE,
         alpha=0.15, border_color=None):
    """Frosted glass-like card."""
    shape = slide.shapes.add_shape(5, left, top, width, height)
    shape.fill.solid()
    shape.fill.fore_color.rgb = fill
    shape.fill.transparency = alpha
    shape.adjustments[0] = 0.04
    if border_color:
        shape.line.color.rgb = border_color
        shape.line.width = Pt(1.5)
    else:
        shape.line.fill.background()
    return shape


def pill_tag(slide, text, left, top, color=GREEN, size=11):
    """Small colored pill label."""
    w = Inches(len(text) * 0.1 + 0.5)
    shape = slide.shapes.add_shape(5, left, top, w, Inches(0.3))
    shape.fill.solid()
    shape.fill.fore_color.rgb = color
    shape.fill.transparency = 0.0
    shape.line.fill.background()
    shape.adjustments[0] = 0.5
    tx(slide, text, left, top, w, Inches(0.3),
       size=size, bold=True, color=WHITE, align=PP_ALIGN.CENTER)


# ════════════════════════════════════════════════════════════════════════════
#  SLIDE BUILDERS
# ════════════════════════════════════════════════════════════════════════════

def s01_title(prs):
    slide = add_slide(prs)
    place_bg(slide, "stadium_bk")
    # Full dark overlay
    overlay(slide, DARK, transparency=0.25)
    # Left panel – semi green
    overlay(slide, GREEN, transparency=0.55,
            left=0, top=0, w=Inches(7.5), h=SLIDE_H)
    # Gold accent bar left edge
    rect(slide, 0, 0, Inches(0.18), SLIDE_H, GOLD)

    # Logo circle
    circ = slide.shapes.add_shape(9, Inches(0.5), Inches(0.7),
                                  Inches(1.4), Inches(1.4))
    circ.fill.solid(); circ.fill.fore_color.rgb = WHITE
    circ.fill.transparency = 0.15; circ.line.fill.background()
    tx(slide, "🏟️", Inches(0.5), Inches(0.82), Inches(1.4), Inches(1.0),
       size=38, align=PP_ALIGN.CENTER)

    # Title text
    tx(slide, "SIPELOR BEDAS",
       Inches(0.5), Inches(2.3), Inches(7.0), Inches(1.35),
       size=52, bold=True, color=WHITE)
    # Thin gold divider
    rect(slide, Inches(0.5), Inches(3.62), Inches(5.5), Inches(0.06), GOLD)

    tx(slide, "Sistem Informasi Penyewaan Lapangan Olahraga",
       Inches(0.5), Inches(3.75), Inches(7.0), Inches(0.6),
       size=18, color=GOLD)
    tx(slide, "Kabupaten Bandung",
       Inches(0.5), Inches(4.3), Inches(7.0), Inches(0.5),
       size=18, color=GOLD, bold=True)

    tx(slide, "DISPORA Kabupaten Bandung  •  2026",
       Inches(0.5), Inches(5.3), Inches(7.0), Inches(0.45),
       size=13, color=RGBColor(0xCC, 0xFF, 0xDD))

    # Right panel stats
    stats = [("42", "Screens"), ("32", "Services"), ("15K+", "Lines of Code"), ("3", "Platforms")]
    for i, (v, l) in enumerate(stats):
        cx = Inches(8.2 + (i % 2) * 2.4)
        cy = Inches(2.3 + (i // 2) * 2.1)
        card(slide, cx, cy, Inches(2.0), Inches(1.75), fill=DARK, alpha=0.2)
        tx(slide, v, cx, cy + Inches(0.28), Inches(2.0), Inches(0.75),
           size=32, bold=True, color=GOLD, align=PP_ALIGN.CENTER)
        tx(slide, l, cx, cy + Inches(1.0), Inches(2.0), Inches(0.45),
           size=13, color=WHITE, align=PP_ALIGN.CENTER)

    tx(slide, "Flutter  ×  Supabase  ×  Dart",
       Inches(7.8), Inches(5.5), Inches(5.3), Inches(0.45),
       size=14, color=RGBColor(0xAA, 0xDD, 0xFF), align=PP_ALIGN.CENTER)

    footer_bar(slide)


def s02_agenda(prs):
    slide = add_slide(prs)
    place_bg(slide, "courts_top")
    overlay(slide, DARK, transparency=0.3)
    header(slide, "Agenda", "Gambaran Umum Presentasi")

    items = [
        ("01", "Latar Belakang & Permasalahan", GREEN),
        ("02", "Solusi SIPELOR BEDAS", BLUE),
        ("03", "Fitur Utama – Pengguna", GREEN),
        ("04", "Fitur Utama – Admin", BLUE),
        ("05", "Teknologi & Keamanan", GREEN),
        ("06", "User Journey & Flow", BLUE),
        ("07", "Dashboard & Revenue Analytics", GREEN),
        ("08", "Roadmap, KPI & Dampak Bisnis", BLUE),
    ]

    cols = 2
    for i, (num, label, clr) in enumerate(items):
        col = i % cols; row = i // cols
        cx = Inches(0.5 + col * 6.4)
        cy = Inches(1.55 + row * 1.35)
        card(slide, cx, cy, Inches(6.0), Inches(1.1), fill=DARK, alpha=0.25)
        rect(slide, cx, cy, Inches(0.85), Inches(1.1), clr, alpha=0.1)
        tx(slide, num, cx, cy, Inches(0.85), Inches(1.1),
           size=26, bold=True, color=GOLD, align=PP_ALIGN.CENTER)
        rect(slide, cx + Inches(0.85), cy, Inches(0.04), Inches(1.1), GOLD)
        tx(slide, label, cx + Inches(1.0), cy + Inches(0.3),
           Inches(4.8), Inches(0.55), size=16, bold=False, color=WHITE)

    footer_bar(slide)


def s03_problems(prs):
    slide = add_slide(prs)
    place_bg(slide, "futsal_girl")
    overlay(slide, DARK, transparency=0.3)
    overlay(slide, RED_ERR, transparency=0.7)
    header(slide, "Permasalahan Saat Ini",
           "Sistem manual yang tidak efisien menyebabkan berbagai masalah",
           bg_color=RED_ERR, sub_color=GOLD)

    problems = [
        ("📞", "Booking via telepon / datang langsung"),
        ("📝", "Pencatatan tidak terstruktur & manual"),
        ("❌", "Tidak ada cek ketersediaan real-time"),
        ("💰", "Proses pembayaran tidak transparan"),
        ("📊", "Tidak ada data analytics & pelaporan"),
        ("⏰", "Sulit tracking & monitoring status"),
        ("🤝", "Komunikasi admin-user tidak efisien"),
        ("📈", "Laporan revenue masih serba manual"),
    ]

    cols = 2
    for i, (icon, text) in enumerate(problems):
        col = i % cols; row = i // cols
        cx = Inches(0.4 + col * 6.5)
        cy = Inches(1.5 + row * 1.3)
        card(slide, cx, cy, Inches(6.0), Inches(1.1), fill=DARK, alpha=0.2)
        rect(slide, cx, cy, Inches(0.07), Inches(1.1), RED_ERR, alpha=0.0)
        tx(slide, icon, cx + Inches(0.15), cy + Inches(0.22),
           Inches(0.65), Inches(0.65), size=24, color=WHITE)
        tx(slide, text, cx + Inches(0.9), cy + Inches(0.3),
           Inches(4.9), Inches(0.55), size=15, color=WHITE)

    rect(slide, 0, SLIDE_H - Inches(1.1), SLIDE_W, Inches(0.65), RED_ERR, alpha=0.2)
    tx(slide, "⚠️  Dampak: Inefisiensi, pengalaman buruk, dan potensi kehilangan pendapatan",
       Inches(0.4), SLIDE_H - Inches(1.05), SLIDE_W - Inches(0.5), Inches(0.6),
       size=14, bold=True, color=GOLD, align=PP_ALIGN.CENTER)

    footer_bar(slide)


def s04_solution(prs):
    slide = add_slide(prs)
    place_bg(slide, "futsal_act")
    overlay(slide, GREEN, transparency=0.25)
    overlay(slide, DARK, transparency=0.45)

    tx(slide, "SOLUSI", Inches(0.5), Inches(0.5), Inches(12.3), Inches(0.55),
       size=14, bold=True, color=GOLD, align=PP_ALIGN.CENTER)
    tx(slide, "SIPELOR BEDAS",
       Inches(0.5), Inches(0.95), Inches(12.3), Inches(1.35),
       size=56, bold=True, color=WHITE, align=PP_ALIGN.CENTER)
    rect(slide, Inches(3), Inches(2.2), Inches(7.3), Inches(0.06), GOLD)
    tx(slide, "Platform digital terintegrasi untuk manajemen pemesanan lapangan olahraga",
       Inches(1), Inches(2.35), Inches(11.3), Inches(0.65),
       size=17, italic=True, color=GOLD, align=PP_ALIGN.CENTER)

    goals = [
        ("🔄", "Digitalisasi\nProses Booking"),
        ("⚡", "Efisiensi\nPengelolaan"),
        ("🔍", "Transparansi\nPembayaran"),
        ("📊", "Data-Driven\nDecisions"),
        ("💹", "Optimalisasi\nRevenue"),
    ]
    cw = Inches(2.28)
    for i, (icon, label) in enumerate(goals):
        cx = Inches(0.35 + i * (cw + Inches(0.22)))
        card(slide, cx, Inches(3.3), cw, Inches(3.0), fill=GREEN, alpha=0.35)
        rect(slide, cx, Inches(3.3), cw, Inches(0.06), GOLD, alpha=0.0)
        tx(slide, icon, cx, Inches(3.55), cw, Inches(0.9),
           size=38, color=WHITE, align=PP_ALIGN.CENTER)
        tx(slide, label, cx, Inches(4.55), cw, Inches(0.95),
           size=15, bold=True, color=GOLD, align=PP_ALIGN.CENTER)

    footer_bar(slide)


def s05_user_features(prs):
    slide = add_slide(prs)
    place_bg(slide, "smartphone")
    overlay(slide, DARK, transparency=0.3)
    overlay(slide, BLUE, transparency=0.65)
    header(slide, "Fitur untuk Pengguna",
           "Kemudahan booking dari genggaman tangan – kapan saja, di mana saja",
           bg_color=BLUE)

    sections = [
        ("🎯 Browse & Booking", GREEN, [
            "🏟️  Lihat daftar venue & lapangan",
            "📅  Cek ketersediaan real-time",
            "💳  Upload bukti transfer",
            "🎫  E-ticket dengan QR code",
        ]),
        ("💬 Komunikasi", BLUE, [
            "💬  Real-time chat dengan admin",
            "🔔  Push notifications status",
            "⭐  Review & rating venue",
        ]),
        ("🔒 Keamanan", PURPLE, [
            "🔒  Biometric authentication",
            "🔐  Data encryption AES-256",
            "🛡️  SSL certificate pinning",
        ]),
    ]

    for i, (title, clr, items) in enumerate(sections):
        cx = Inches(0.4 + i * 4.3)
        cw = Inches(4.0)
        card(slide, cx, Inches(1.38), cw, Inches(5.72), fill=DARK, alpha=0.2)
        rect(slide, cx, Inches(1.38), cw, Inches(0.62), clr, alpha=0.25)
        rect(slide, cx, Inches(1.38), Inches(0.07), Inches(0.62), GOLD, alpha=0.0)
        tx(slide, title, cx + Inches(0.15), Inches(1.42), cw, Inches(0.55),
           size=16, bold=True, color=WHITE)
        for j, item in enumerate(items):
            tx(slide, item, cx + Inches(0.2), Inches(2.2 + j * 0.88),
               cw - Inches(0.3), Inches(0.75), size=14, color=WHITE)

    footer_bar(slide)


def s06_admin_features(prs):
    slide = add_slide(prs)
    place_bg(slide, "analytics")
    overlay(slide, DARK, transparency=0.3)
    overlay(slide, GREEN, transparency=0.65)
    header(slide, "Dashboard Admin",
           "Kontrol penuh manajemen venue, laporan & analitik real-time",
           bg_color=GREEN)

    sections = [
        ("📊 Analytics & Monitoring", GREEN, [
            "Real-time KPI dashboard",
            "Revenue analytics & trends",
            "Booking insights & peaks",
            "Performance metrics per venue",
        ]),
        ("✅ Management", BLUE, [
            "Approve / reject bookings",
            "Staff management (RBAC)",
            "Maintenance scheduling",
            "Chat management dengan user",
        ]),
        ("📋 Reporting", PURPLE, [
            "Laporan otomatis harian/mingguan",
            "Export ke PDF & CSV",
            "Custom date range analytics",
            "Venue performance comparison",
        ]),
    ]

    for i, (title, clr, items) in enumerate(sections):
        cx = Inches(0.4 + i * 4.3)
        cw = Inches(4.05)
        card(slide, cx, Inches(1.38), cw, Inches(5.72), fill=DARK, alpha=0.2)
        rect(slide, cx, Inches(1.38), cw, Inches(0.62), clr, alpha=0.25)
        rect(slide, cx, Inches(1.38), Inches(0.07), Inches(0.62), GOLD)
        tx(slide, title, cx + Inches(0.15), Inches(1.42), cw, Inches(0.55),
           size=15, bold=True, color=WHITE)
        for j, item in enumerate(items):
            rect(slide, cx + Inches(0.22), Inches(2.25 + j * 1.08),
                 Inches(0.2), Inches(0.2), clr)
            tx(slide, item, cx + Inches(0.55), Inches(2.18 + j * 1.08),
               cw - Inches(0.65), Inches(0.7), size=14, color=WHITE)

    footer_bar(slide)


def s07_tech(prs):
    slide = add_slide(prs)
    place_bg(slide, "code_scr")
    overlay(slide, DARK, transparency=0.2)
    overlay(slide, BLUE, transparency=0.6)

    tx(slide, "TEKNOLOGI", Inches(0.5), Inches(0.25), Inches(12.3), Inches(0.5),
       size=13, bold=True, color=GOLD, align=PP_ALIGN.CENTER)
    tx(slide, "Technology Stack",
       Inches(0.5), Inches(0.65), Inches(12.3), Inches(0.9),
       size=40, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

    stacks = [
        ("Frontend", GREEN, [
            "Flutter 3.38.4  –  Cross-platform",
            "Dart 3.x  –  Modern language",
            "Material Design 3  –  Beautiful UI",
            "FL Chart  –  Analytics charts",
            "Riverpod  –  State management",
        ]),
        ("Backend", BLUE, [
            "Supabase  –  BaaS (PostgreSQL)",
            "Realtime WebSocket  –  Live data",
            "Supabase Auth  –  Authentication",
            "Supabase Storage  –  File storage",
            "Sentry  –  Error tracking",
        ]),
        ("Security", PURPLE, [
            "SSL Certificate Pinning (MITM)",
            "AES-256 Data Encryption",
            "Biometric Authentication",
            "Rate Limiting & Audit Logs",
            "RASP Runtime Protection",
        ]),
    ]

    for i, (title, clr, items) in enumerate(stacks):
        cx = Inches(0.35 + i * 4.35)
        cw = Inches(4.1)
        card(slide, cx, Inches(1.75), cw, Inches(5.35), fill=DARK, alpha=0.2)
        rect(slide, cx, Inches(1.75), cw, Inches(0.62), clr, alpha=0.3)
        rect(slide, cx, Inches(1.75), Inches(0.07), Inches(0.62), GOLD)
        tx(slide, title, cx + Inches(0.15), Inches(1.79),
           cw, Inches(0.55), size=20, bold=True, color=WHITE)
        for j, item in enumerate(items):
            tx(slide, f"▸  {item}",
               cx + Inches(0.2), Inches(2.55 + j * 0.85),
               cw - Inches(0.3), Inches(0.75), size=13, color=WHITE)

    # Bottom stat pills
    for i, (v, l) in enumerate([("30+","Dependencies"),("15,000+","Lines"),("3","Platforms")]):
        cx = Inches(1.2 + i * 4.0)
        tx(slide, v, cx, Inches(7.05), Inches(3.5), Inches(0.45),
           size=22, bold=True, color=GOLD, align=PP_ALIGN.CENTER)
        tx(slide, l, cx, Inches(7.32), Inches(3.5), Inches(0.28),
           size=11, color=WHITE, align=PP_ALIGN.CENTER)


def s08_architecture(prs):
    slide = add_slide(prs)
    place_bg(slide, "server")
    overlay(slide, DARK, transparency=0.25)
    overlay(slide, BLUE, transparency=0.6)
    header(slide, "Arsitektur Sistem",
           "End-to-end platform architecture – scalable & secure", bg_color=BLUE)

    layers = [
        ("📱  User Devices", "Android  •  iOS  •  Web Browser",
         GREEN, Inches(1.45)),
        ("⚙️  Flutter Application",
         "42 Screens  •  32 Services  •  15 Models  •  Riverpod",
         BLUE, Inches(2.75)),
        ("☁️  Supabase Backend",
         "PostgreSQL  •  Realtime WebSocket  •  Auth  •  Storage",
         RGBColor(0x3E, 0xCF, 0x8E), Inches(4.05)),
        ("🔗  External Services",
         "Sentry  •  Google OAuth  •  Firebase Push Notification",
         PURPLE, Inches(5.35)),
    ]

    bw = Inches(10.5); bx = Inches(1.4)
    for i, (title, sub, clr, cy) in enumerate(layers):
        card(slide, bx, cy, bw, Inches(1.0), fill=DARK, alpha=0.2)
        rect(slide, bx, cy, Inches(0.1), Inches(1.0), clr)
        tx(slide, title, bx + Inches(0.25), cy + Inches(0.18),
           Inches(4.5), Inches(0.65), size=18, bold=True, color=WHITE)
        tx(slide, sub, bx + Inches(4.6), cy + Inches(0.25),
           Inches(5.8), Inches(0.6), size=13, color=WHITE, align=PP_ALIGN.RIGHT)
        if i < len(layers) - 1:
            tx(slide, "↕", Inches(7.0), cy + Inches(1.0),
               Inches(0.5), Inches(0.35), size=18, bold=True, color=GOLD)

    # Side facts
    facts = [("10+","DB Tables"),("3","Buckets"),("WebSocket","Realtime"),("RLS","Security")]
    for i, (v, l) in enumerate(facts):
        cy = Inches(1.45 + i * 1.3)
        card(slide, Inches(12.15), cy, Inches(1.0), Inches(1.08), fill=GREEN, alpha=0.3)
        tx(slide, v, Inches(12.15), cy + Inches(0.1), Inches(1.0), Inches(0.55),
           size=13, bold=True, color=GOLD, align=PP_ALIGN.CENTER)
        tx(slide, l, Inches(12.15), cy + Inches(0.65), Inches(1.0), Inches(0.38),
           size=9, color=WHITE, align=PP_ALIGN.CENTER)

    footer_bar(slide)


def s09_security(prs):
    slide = add_slide(prs)
    place_bg(slide, "security")
    overlay(slide, DARK, transparency=0.22)
    overlay(slide, PURPLE, transparency=0.62)
    header(slide, "Keamanan Multi-Layer",
           "Security-first approach untuk perlindungan data pengguna",
           bg_color=PURPLE, sub_color=GOLD)

    sections = [
        ("🔐 Authentication", DARK, [
            "Email verification wajib",
            "Password kuat (min 8 char)",
            "Google OAuth / SSO",
            "Biometric fingerprint/face ID",
            "Rate limiting 5 percobaan",
            "Auto-logout 15 menit",
        ]),
        ("🛡️ Data Protection", BLUE, [
            "At Rest: AES-256 encryption",
            "In Transit: SSL/TLS + pinning",
            "Password: Bcrypt hashing",
            "Secure local storage",
            "File encryption (payment)",
            "No plaintext credentials",
        ]),
        ("🔍 Monitoring", GREEN, [
            "Comprehensive audit logs",
            "Security event notifications",
            "Sentry error tracking",
            "Failed login tracking",
            "RASP runtime protection",
            "Real-time security alerts",
        ]),
    ]

    for i, (title, clr, items) in enumerate(sections):
        cx = Inches(0.35 + i * 4.35)
        cw = Inches(4.1)
        card(slide, cx, Inches(1.38), cw, Inches(5.72), fill=DARK, alpha=0.2)
        rect(slide, cx, Inches(1.38), cw, Inches(0.58), [PURPLE, BLUE, GREEN][i], alpha=0.35)
        rect(slide, cx, Inches(1.38), Inches(0.07), Inches(0.58), GOLD)
        tx(slide, title, cx + Inches(0.15), Inches(1.42), cw, Inches(0.5),
           size=15, bold=True, color=WHITE)
        for j, item in enumerate(items):
            tx(slide, f"  ✓  {item}", cx + Inches(0.15), Inches(2.15 + j * 0.82),
               cw - Inches(0.25), Inches(0.7), size=13, color=WHITE)

    footer_bar(slide)


def s10_journey(prs):
    slide = add_slide(prs)
    place_bg(slide, "futsal_act")
    overlay(slide, DARK, transparency=0.28)
    overlay(slide, GREEN, transparency=0.6)
    header(slide, "User Journey – Booking Flow",
           "Proses booking yang mudah & cepat  —  rata-rata < 5 menit",
           bg_color=GREEN)

    steps = [
        ("1", "Browse\nVenues"),
        ("2", "Lihat\nDetail"),
        ("3", "Pilih\nWaktu"),
        ("4", "Konfirmasi\nHarga"),
        ("5", "Upload\nBukti"),
        ("6", "Tunggu\nApprove"),
        ("7", "E-Ticket\nQR Code"),
        ("8", "Check-in\nScan QR"),
        ("9", "Review\n& Rating"),
    ]

    sw = Inches(1.32); sx = Inches(0.35)
    for i, (num, title) in enumerate(steps):
        cx = sx + i * (sw + Inches(0.1))
        cy = Inches(2.0)

        # Circle
        circ = slide.shapes.add_shape(9, cx + Inches(0.21), cy,
                                       Inches(0.9), Inches(0.9))
        circ.fill.solid(); circ.fill.fore_color.rgb = GREEN
        circ.fill.transparency = 0.1; circ.line.fill.background()
        rect(slide, cx + Inches(0.21), cy, Inches(0.9), Inches(0.9),
             GOLD, alpha=0.7)
        tx(slide, num, cx + Inches(0.21), cy, Inches(0.9), Inches(0.9),
           size=22, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

        # Arrow
        if i < len(steps) - 1:
            tx(slide, "›", cx + sw + Inches(0.01), cy + Inches(0.2),
               Inches(0.1), Inches(0.5), size=18, bold=True, color=GOLD)

        # Card below
        card(slide, cx, Inches(3.1), sw, Inches(2.35), fill=DARK, alpha=0.22)
        rect(slide, cx, Inches(3.1), sw, Inches(0.07), GREEN)
        tx(slide, title, cx, Inches(3.25), sw, Inches(0.85),
           size=12, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

    # Timer bar
    rect(slide, Inches(0.35), Inches(5.8), SLIDE_W - Inches(0.35), Inches(0.72),
         GREEN, alpha=0.3)
    rect(slide, Inches(0.35), Inches(5.8), Inches(0.1), Inches(0.72), GOLD)
    tx(slide, "⏱️  Average Time: < 5 menit dari browse hingga booking dikonfirmasi",
       Inches(0.65), Inches(5.82), SLIDE_W - Inches(1.0), Inches(0.65),
       size=16, bold=True, color=GOLD, align=PP_ALIGN.CENTER)

    footer_bar(slide)


def s11_dashboard(prs):
    slide = add_slide(prs)
    place_bg(slide, "graph_fin")
    overlay(slide, DARK, transparency=0.25)
    overlay(slide, BLUE, transparency=0.55)
    header(slide, "Admin Dashboard Overview",
           "Real-time KPI monitoring & manajemen terpusat", bg_color=BLUE)

    kpis = [
        ("245", "Total Bookings", "↑ +12%", GREEN),
        ("Rp 12.5M", "Revenue Hari Ini", "↑ +8.5%", BLUE),
        ("8", "Pending Payments", "↓ -2", ORANGE),
        ("1,234", "Pengguna Aktif", "↑ +45", PURPLE),
    ]

    kw = Inches(2.95)
    for i, (val, lbl, ch, clr) in enumerate(kpis):
        cx = Inches(0.4 + i * 3.1)
        card(slide, cx, Inches(1.4), kw, Inches(1.7), fill=clr, alpha=0.3)
        rect(slide, cx, Inches(1.4), kw, Inches(0.06), GOLD)
        tx(slide, val, cx, Inches(1.5), kw, Inches(0.82),
           size=30, bold=True, color=WHITE, align=PP_ALIGN.CENTER)
        tx(slide, lbl, cx, Inches(2.25), kw, Inches(0.42),
           size=12, color=WHITE, align=PP_ALIGN.CENTER)
        tx(slide, ch, cx, Inches(2.62), kw, Inches(0.38),
           size=13, bold=True, color=GOLD, align=PP_ALIGN.CENTER)

    visuals = [
        ("📈", "Booking Trends", "Grafik 30 hari terakhir", GREEN),
        ("💰", "Revenue by Venue", "Pie chart per lapangan", BLUE),
        ("⏰", "Peak Hours Analysis", "Analisis jam ramai", ORANGE),
        ("🏆", "Top Venues Ranking", "Performa terbaik", PURPLE),
    ]

    for i, (icon, title, desc, clr) in enumerate(visuals):
        cx = Inches(0.4 + (i % 2) * 6.5)
        cy = Inches(3.35 + (i // 2) * 1.75)
        card(slide, cx, cy, Inches(6.1), Inches(1.55), fill=DARK, alpha=0.2)
        rect(slide, cx, cy, Inches(0.1), Inches(1.55), clr)
        tx(slide, icon, cx + Inches(0.2), cy + Inches(0.35),
           Inches(0.75), Inches(0.8), size=28)
        tx(slide, title, cx + Inches(1.1), cy + Inches(0.22),
           Inches(4.7), Inches(0.58), size=17, bold=True, color=WHITE)
        tx(slide, desc, cx + Inches(1.1), cy + Inches(0.82),
           Inches(4.7), Inches(0.45), size=12, color=GOLD)

    footer_bar(slide)


def s12_revenue(prs):
    slide = add_slide(prs)
    place_bg(slide, "growth")
    overlay(slide, DARK, transparency=0.25)
    overlay(slide, GREEN, transparency=0.6)
    header(slide, "Revenue Analytics",
           "Data pendapatan & performa keuangan venue", bg_color=GREEN)

    # Big metrics
    card(slide, Inches(0.4), Inches(1.42), Inches(5.6), Inches(2.7),
         fill=GREEN, alpha=0.3)
    rect(slide, Inches(0.4), Inches(1.42), Inches(5.6), Inches(0.07), GOLD)
    tx(slide, "Total Revenue", Inches(0.5), Inches(1.55),
       Inches(5.4), Inches(0.45), size=14, color=GOLD, align=PP_ALIGN.CENTER)
    tx(slide, "Rp 125.4M", Inches(0.5), Inches(1.9),
       Inches(5.4), Inches(1.0), size=42, bold=True, color=WHITE,
       align=PP_ALIGN.CENTER)
    tx(slide, "↑ +12.5% vs periode sebelumnya",
       Inches(0.5), Inches(2.85), Inches(5.4), Inches(0.45),
       size=14, bold=True, color=GOLD, align=PP_ALIGN.CENTER)

    mets = [("Rp 512K", "Avg / Booking", BLUE),
            ("+12.5%", "Growth Rate", ORANGE)]
    for i, (v, l, clr) in enumerate(mets):
        cx = Inches(0.4 + i * 2.95)
        card(slide, cx, Inches(4.35), Inches(2.6), Inches(1.45),
             fill=clr, alpha=0.35)
        tx(slide, v, cx, Inches(4.48), Inches(2.6), Inches(0.72),
           size=26, bold=True, color=WHITE, align=PP_ALIGN.CENTER)
        tx(slide, l, cx, Inches(5.12), Inches(2.6), Inches(0.45),
           size=12, color=WHITE, align=PP_ALIGN.CENTER)

    # Breakdown bars right
    breakdown = [
        ("⚽ Futsal",    36, "Rp 45.2M", GREEN),
        ("🏸 Badminton", 26, "Rp 32.1M", BLUE),
        ("🏀 Basket",    23, "Rp 28.3M", ORANGE),
        ("🎾 Tenis",     15, "Rp 19.8M", PURPLE),
    ]
    bx = Inches(6.4)
    tx(slide, "Revenue per Venue", bx, Inches(1.45),
       Inches(6.5), Inches(0.5), size=18, bold=True, color=WHITE)
    for i, (label, pct, amount, clr) in enumerate(breakdown):
        cy = Inches(2.1 + i * 1.17)
        tx(slide, label, bx, cy, Inches(2.3), Inches(0.42), size=14, color=WHITE)
        bar_full = Inches(6.5)
        bar_filled = bar_full * pct / 100
        rect(slide, bx, cy + Inches(0.46), bar_full, Inches(0.42),
             RGBColor(0x33,0x33,0x33), alpha=0.3)
        rect(slide, bx, cy + Inches(0.46), bar_filled, Inches(0.42), clr, alpha=0.15)
        tx(slide, f"{pct}%  |  {amount}",
           bx + Inches(0.1), cy + Inches(0.5),
           bar_filled - Inches(0.1), Inches(0.35),
           size=12, bold=True, color=GOLD)

    rect(slide, Inches(6.4), Inches(6.6), Inches(6.5), Inches(0.65),
         GREEN, alpha=0.3)
    tx(slide, "⏰  Peak Hours: 14:00–16:00  (35% of all bookings)",
       Inches(6.55), Inches(6.62), Inches(6.3), Inches(0.6),
       size=15, bold=True, color=GOLD)

    footer_bar(slide)


def s13_stats(prs):
    slide = add_slide(prs)
    place_bg(slide, "workspace")
    overlay(slide, DARK, transparency=0.22)
    overlay(slide, BLUE, transparency=0.58)

    tx(slide, "STATISTIK PROYEK", Inches(0.5), Inches(0.3),
       Inches(12.3), Inches(0.55), size=13, bold=True, color=GOLD,
       align=PP_ALIGN.CENTER)
    tx(slide, "Project Statistics",
       Inches(0.5), Inches(0.75), Inches(12.3), Inches(0.9),
       size=40, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

    stats = [
        ("15,000+", "Lines of Code", GREEN),
        ("42",       "Screens",        BLUE),
        ("32",       "Services",       PURPLE),
        ("15",       "Data Models",    ORANGE),
        ("30+",      "Dependencies",   GREEN),
        ("17+",      "Dokumentasi",    BLUE),
    ]

    for i, (val, lbl, clr) in enumerate(stats):
        col = i % 3; row = i // 3
        cx = Inches(0.9 + col * 4.0)
        cy = Inches(1.95 + row * 2.3)
        card(slide, cx, cy, Inches(3.5), Inches(2.0), fill=DARK, alpha=0.22)
        rect(slide, cx, cy, Inches(3.5), Inches(0.07), clr)
        tx(slide, val, cx, cy + Inches(0.2), Inches(3.5), Inches(0.98),
           size=40, bold=True, color=GOLD, align=PP_ALIGN.CENTER)
        tx(slide, lbl, cx, cy + Inches(1.12), Inches(3.5), Inches(0.55),
           size=16, color=WHITE, align=PP_ALIGN.CENTER)

    tx(slide, "Screens: Auth 6  •  User 11  •  Admin 10  •  Venue 2  •  Settings 3  •  Debug 4",
       Inches(0.5), Inches(6.82), Inches(12.3), Inches(0.4),
       size=13, color=GOLD, align=PP_ALIGN.CENTER)

    footer_bar(slide)


def s14_roadmap(prs):
    slide = add_slide(prs)
    place_bg(slide, "planning")
    overlay(slide, DARK, transparency=0.25)
    overlay(slide, GREEN, transparency=0.58)
    header(slide, "Development Roadmap",
           "Perencanaan pengembangan jangka pendek & panjang", bg_color=GREEN)

    phases = [
        ("✅ Phase 1 – COMPLETED", "2025-2026", GREEN, [
            "User authentication & profiles",
            "Booking & payment verification",
            "Admin dashboard & analytics",
            "Real-time chat & notifications",
            "Security multi-layer features",
            "Revenue analytics & reports",
        ]),
        ("🚧 Phase 2 – PLANNED", "2026", BLUE, [
            "iOS app deployment",
            "Payment gateway integration",
            "Advanced analytics & BI",
            "QR scanner untuk staff",
            "Multi-language support",
            "Dark mode",
        ]),
        ("🔮 Phase 3 – FUTURE", "2027+", PURPLE, [
            "AI booking recommendations",
            "IoT field sensors",
            "Dynamic pricing algorithm",
            "Loyalty program",
            "Advanced user analytics",
        ]),
    ]

    for i, (title, period, clr, items) in enumerate(phases):
        cx = Inches(0.35 + i * 4.35)
        cw = Inches(4.1)
        card(slide, cx, Inches(1.38), cw, Inches(5.72), fill=DARK, alpha=0.22)
        rect(slide, cx, Inches(1.38), cw, Inches(0.6), clr, alpha=0.3)
        rect(slide, cx, Inches(1.38), Inches(0.07), Inches(0.6), GOLD)
        tx(slide, title, cx + Inches(0.15), Inches(1.42), cw, Inches(0.52),
           size=14, bold=True, color=WHITE)
        rect(slide, cx, Inches(1.98), cw, Inches(0.32), BLUE, alpha=0.4)
        tx(slide, f"📅 Target: {period}",
           cx + Inches(0.15), Inches(2.0), cw, Inches(0.3),
           size=11, bold=True, color=GOLD)
        for j, item in enumerate(items):
            rect(slide, cx + Inches(0.22), Inches(2.48 + j * 0.8),
                 Inches(0.18), Inches(0.18), clr)
            tx(slide, item, cx + Inches(0.55), Inches(2.4 + j * 0.8),
               cw - Inches(0.65), Inches(0.68), size=13, color=WHITE)

    footer_bar(slide)


def s15_kpi(prs):
    slide = add_slide(prs)
    place_bg(slide, "chart_col")
    overlay(slide, DARK, transparency=0.25)
    overlay(slide, BLUE, transparency=0.6)
    header(slide, "Target KPI – Year 1",
           "Key Performance Indicators untuk tahun pertama implementasi",
           bg_color=BLUE)

    cats = [
        ("👥 User Adoption", GREEN, [
            ("5,000+", "Registered Users"),
            ("70%+",   "Monthly Active Users"),
            ("4.5+ ⭐", "Star Rating"),
        ]),
        ("💼 Business", ORANGE, [
            ("10,000+", "Bookings / Month"),
            ("85%+",    "Completion Rate"),
            ("50%+",    "Revenue Increase"),
        ]),
        ("⚙️ Operational", PURPLE, [
            ("< 2 min",  "Booking Time"),
            ("< 1 hour", "Payment Approval"),
            ("95%+",     "System Uptime"),
        ]),
    ]

    for i, (cat, clr, items) in enumerate(cats):
        cx = Inches(0.35 + i * 4.35)
        cw = Inches(4.1)
        card(slide, cx, Inches(1.38), cw, Inches(0.6), fill=clr, alpha=0.3)
        rect(slide, cx, Inches(1.38), Inches(0.07), Inches(0.6), GOLD)
        tx(slide, cat, cx + Inches(0.15), Inches(1.42), cw, Inches(0.52),
           size=16, bold=True, color=WHITE)
        for j, (val, lbl) in enumerate(items):
            cy = Inches(2.18 + j * 1.62)
            card(slide, cx, cy, cw, Inches(1.45), fill=DARK, alpha=0.22)
            rect(slide, cx, cy, Inches(0.07), Inches(1.45), clr)
            tx(slide, val, cx + Inches(0.15), cy + Inches(0.12),
               cw - Inches(0.2), Inches(0.78), size=30, bold=True, color=GOLD,
               align=PP_ALIGN.CENTER)
            tx(slide, lbl, cx + Inches(0.15), cy + Inches(0.9),
               cw - Inches(0.2), Inches(0.42), size=13, color=WHITE,
               align=PP_ALIGN.CENTER)

    rect(slide, Inches(0.35), Inches(7.05), SLIDE_W - Inches(0.35), Inches(0.65),
         GREEN, alpha=0.3)
    tx(slide, "🎯  80%+ User Satisfaction Score",
       Inches(0.5), Inches(7.07), SLIDE_W - Inches(0.6), Inches(0.58),
       size=17, bold=True, color=GOLD, align=PP_ALIGN.CENTER)


def s16_impact(prs):
    slide = add_slide(prs)
    place_bg(slide, "aerial_sc")
    overlay(slide, DARK, transparency=0.28)
    header(slide, "Expected Business Impact",
           "Manfaat nyata bagi DISPORA dan masyarakat Kabupaten Bandung",
           bg_color=DARK)

    # Left – DISPORA
    card(slide, Inches(0.4), Inches(1.38), Inches(6.0), Inches(5.82),
         fill=DARK, alpha=0.22)
    rect(slide, Inches(0.4), Inches(1.38), Inches(6.0), Inches(0.6), GREEN, alpha=0.3)
    rect(slide, Inches(0.4), Inches(1.38), Inches(0.07), Inches(0.6), GOLD)
    tx(slide, "🏛️  Untuk DISPORA", Inches(0.55), Inches(1.42),
       Inches(5.8), Inches(0.52), size=18, bold=True, color=WHITE)
    dis = ["Data-driven decision making",
           "Optimalisasi pendapatan venue",
           "Peningkatan layanan publik",
           "Transparansi & akuntabilitas",
           "Pengurangan beban kerja manual"]
    for i, item in enumerate(dis):
        rect(slide, Inches(0.6), Inches(2.2 + i * 1.0),
             Inches(0.3), Inches(0.3), GREEN)
        tx(slide, item, Inches(1.1), Inches(2.15 + i * 1.0),
           Inches(5.0), Inches(0.58), size=16, color=WHITE)

    # Right – Masyarakat
    card(slide, Inches(7.0), Inches(1.38), Inches(6.0), Inches(5.82),
         fill=DARK, alpha=0.22)
    rect(slide, Inches(7.0), Inches(1.38), Inches(6.0), Inches(0.6), BLUE, alpha=0.3)
    rect(slide, Inches(7.0), Inches(1.38), Inches(0.07), Inches(0.6), GOLD)
    tx(slide, "👥  Untuk Masyarakat", Inches(7.15), Inches(1.42),
       Inches(5.8), Inches(0.52), size=18, bold=True, color=WHITE)
    mas = ["Booking 24/7 kapan & di mana saja",
           "Hemat waktu & lebih efisien",
           "Kemudahan via mobile app",
           "Pembayaran aman & terlacak",
           "Pengalaman pengguna modern"]
    for i, item in enumerate(mas):
        rect(slide, Inches(7.2), Inches(2.2 + i * 1.0),
             Inches(0.3), Inches(0.3), BLUE)
        tx(slide, item, Inches(7.7), Inches(2.15 + i * 1.0),
           Inches(5.0), Inches(0.58), size=16, color=WHITE)

    footer_bar(slide)


def s17_advantages(prs):
    slide = add_slide(prs)
    place_bg(slide, "badminton")
    overlay(slide, DARK, transparency=0.25)
    overlay(slide, GREEN, transparency=0.58)

    tx(slide, "KEUNGGULAN KOMPETITIF",
       Inches(0.5), Inches(0.28), Inches(12.3), Inches(0.52),
       size=13, bold=True, color=GOLD, align=PP_ALIGN.CENTER)
    tx(slide, "Why SIPELOR BEDAS?",
       Inches(0.5), Inches(0.72), Inches(12.3), Inches(0.9),
       size=40, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

    advs = [
        ("1️⃣", "Government-Backed",
         "Platform resmi DISPORA – terpercaya & sah"),
        ("2️⃣", "Comprehensive Solution",
         "End-to-end: booking, payment, chat & analytics"),
        ("3️⃣", "Security-First",
         "Multi-layer: biometrik, AES-256, SSL pinning"),
        ("4️⃣", "Data-Driven",
         "Real-time analytics untuk keputusan bisnis"),
        ("5️⃣", "Modern Technology",
         "Flutter + Supabase – scalable & cross-platform"),
        ("6️⃣", "User-Centric Design",
         "Alur booking < 5 menit, desain intuitif"),
    ]

    cw = Inches(5.9)
    for i, (num, title, desc) in enumerate(advs):
        col = i % 2; row = i // 2
        cx = Inches(0.5 + col * 6.4)
        cy = Inches(1.88 + row * 1.65)
        card(slide, cx, cy, cw, Inches(1.45), fill=DARK, alpha=0.22)
        rect(slide, cx, cy, Inches(0.07), Inches(1.45), GOLD)
        tx(slide, num, cx + Inches(0.2), cy + Inches(0.35),
           Inches(0.65), Inches(0.75), size=26, color=GOLD)
        tx(slide, title, cx + Inches(0.9), cy + Inches(0.18),
           cw - Inches(1.0), Inches(0.55), size=18, bold=True, color=WHITE)
        tx(slide, desc, cx + Inches(0.9), cy + Inches(0.72),
           cw - Inches(1.0), Inches(0.58), size=13, color=RGBColor(0xCC,0xFF,0xDD))

    tx(slide,
       "\"One platform for booking, payment, analytics, and management\"",
       Inches(0.5), Inches(6.92), Inches(12.3), Inches(0.5),
       size=15, bold=True, italic=True, color=GOLD, align=PP_ALIGN.CENTER)

    footer_bar(slide)


def s18_implementation(prs):
    slide = add_slide(prs)
    place_bg(slide, "planning")
    overlay(slide, DARK, transparency=0.22)
    overlay(slide, BLUE, transparency=0.6)
    header(slide, "Rencana Implementasi",
           "Langkah-langkah peluncuran, onboarding & optimasi",
           bg_color=BLUE)

    phases = [
        ("🚀 Bulan 1: Launch", GREEN, [
            "Deploy ke production server",
            "Pelatihan staff DISPORA",
            "Soft launch terbatas",
            "Monitoring & bug fixing",
        ]),
        ("📢 Bulan 2: Onboarding", ORANGE, [
            "User onboarding & tutorial",
            "Kampanye marketing digital",
            "Pengumpulan feedback awal",
            "Analisis data penggunaan",
        ]),
        ("📈 Bulan 3+: Optimasi", PURPLE, [
            "Monitor KPI & target",
            "Integrasi feedback user",
            "Peningkatan UX & fitur",
            "Persiapan Phase 2",
        ]),
    ]

    for i, (title, clr, items) in enumerate(phases):
        cx = Inches(0.35 + i * 4.35)
        cw = Inches(4.1)

        # Number circle
        circ = slide.shapes.add_shape(
            9, cx + cw/2 - Inches(0.45), Inches(1.42), Inches(0.9), Inches(0.9))
        circ.fill.solid(); circ.fill.fore_color.rgb = clr
        circ.fill.transparency = 0.15; circ.line.fill.background()
        tx(slide, str(i + 1),
           cx + cw/2 - Inches(0.45), Inches(1.42),
           Inches(0.9), Inches(0.9), size=24, bold=True, color=WHITE,
           align=PP_ALIGN.CENTER)

        card(slide, cx, Inches(2.5), cw, Inches(4.6), fill=DARK, alpha=0.22)
        rect(slide, cx, Inches(2.5), cw, Inches(0.55), clr, alpha=0.3)
        rect(slide, cx, Inches(2.5), Inches(0.07), Inches(0.55), GOLD)
        tx(slide, title, cx + Inches(0.15), Inches(2.54), cw, Inches(0.48),
           size=14, bold=True, color=WHITE)
        for j, item in enumerate(items):
            rect(slide, cx + Inches(0.22), Inches(3.22 + j * 0.95),
                 Inches(0.2), Inches(0.2), clr)
            tx(slide, item, cx + Inches(0.58), Inches(3.15 + j * 0.95),
               cw - Inches(0.68), Inches(0.7), size=14, color=WHITE)

    # Timeline strip
    rect(slide, Inches(0.35), Inches(7.0), SLIDE_W - Inches(0.35), Inches(0.22), GOLD, alpha=0.4)
    for i, lbl in enumerate(["Bulan 1", "Bulan 2", "Bulan 3+"]):
        tx(slide, lbl, Inches(0.4 + i * 4.3), Inches(7.02),
           Inches(4.1), Inches(0.2), size=11, bold=True, color=WHITE,
           align=PP_ALIGN.CENTER)

    footer_bar(slide)


def s19_contact(prs):
    slide = add_slide(prs)
    place_bg(slide, "govt_bldg")
    overlay(slide, DARK, transparency=0.28)
    header(slide, "Dukungan & Kontak",
           "Kami siap membantu – hubungi kami melalui kanal di bawah")

    card(slide, Inches(0.4), Inches(1.42), Inches(5.9), Inches(5.75),
         fill=DARK, alpha=0.22)
    rect(slide, Inches(0.4), Inches(1.42), Inches(5.9), Inches(0.58), GREEN, alpha=0.3)
    rect(slide, Inches(0.4), Inches(1.42), Inches(0.07), Inches(0.58), GOLD)
    tx(slide, "🛠️  Dukungan Teknis", Inches(0.55), Inches(1.46),
       Inches(5.7), Inches(0.5), size=18, bold=True, color=WHITE)
    tech = [("📧","dev-team@sipelor-bedas.com"),
            ("💬","In-app chat support"),
            ("🌐","www.sipelor-bedas.com"),
            ("📁","Dokumentasi di folder /docs")]
    for i, (icon, val) in enumerate(tech):
        tx(slide, icon, Inches(0.65), Inches(2.2 + i * 1.0),
           Inches(0.6), Inches(0.65), size=24)
        tx(slide, val, Inches(1.35), Inches(2.25 + i * 1.0),
           Inches(4.7), Inches(0.58), size=15, color=WHITE)

    card(slide, Inches(7.0), Inches(1.42), Inches(5.9), Inches(5.75),
         fill=DARK, alpha=0.22)
    rect(slide, Inches(7.0), Inches(1.42), Inches(5.9), Inches(0.58), BLUE, alpha=0.3)
    rect(slide, Inches(7.0), Inches(1.42), Inches(0.07), Inches(0.58), GOLD)
    tx(slide, "🏛️  Kontak DISPORA", Inches(7.15), Inches(1.46),
       Inches(5.7), Inches(0.5), size=18, bold=True, color=WHITE)
    dis = [("📧","dispora@bandungkab.go.id"),
           ("📧","admin@sipelor-bedas.com"),
           ("📱","(022) xxxx-xxxx"),
           ("🏢","Dinas Pemuda dan Olahraga")]
    for i, (icon, val) in enumerate(dis):
        tx(slide, icon, Inches(7.25), Inches(2.2 + i * 1.0),
           Inches(0.6), Inches(0.65), size=24)
        tx(slide, val, Inches(7.95), Inches(2.25 + i * 1.0),
           Inches(4.7), Inches(0.58), size=15, color=WHITE)

    rect(slide, Inches(0.4), Inches(6.2), SLIDE_W - Inches(0.45), Inches(0.92),
         GREEN, alpha=0.35)
    rect(slide, Inches(0.4), Inches(6.2), Inches(0.1), Inches(0.92), GOLD)
    tx(slide, "🕐  Jam Operasional:", Inches(0.7), Inches(6.28),
       Inches(3.2), Inches(0.42), size=14, bold=True, color=GOLD)
    tx(slide, "Senin–Jumat: 08:00–17:00 WIB     |     Sabtu: 08:00–12:00 WIB",
       Inches(3.8), Inches(6.28), Inches(9), Inches(0.42), size=14, color=WHITE)

    footer_bar(slide)


def s20_thankyou(prs):
    slide = add_slide(prs)
    place_bg(slide, "stadium_bk")
    overlay(slide, DARK, transparency=0.2)
    overlay(slide, GREEN, transparency=0.55)

    # Side bars
    rect(slide, 0, 0, Inches(0.18), SLIDE_H, GOLD)
    rect(slide, SLIDE_W - Inches(0.18), 0, Inches(0.18), SLIDE_H, GOLD)
    # Bottom bar
    rect(slide, 0, SLIDE_H - Inches(1.6), SLIDE_W, Inches(1.6), DARK, alpha=0.2)
    rect(slide, 0, SLIDE_H - Inches(1.6), SLIDE_W, Inches(0.06), GOLD)

    tx(slide, "🏟️", Inches(5.4), Inches(0.4), Inches(2.5), Inches(1.7),
       size=64, align=PP_ALIGN.CENTER)

    tx(slide, "Terima Kasih",
       Inches(0.5), Inches(2.15), Inches(12.3), Inches(1.45),
       size=58, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

    rect(slide, Inches(3.5), Inches(3.55), Inches(6.3), Inches(0.06), GOLD)

    tx(slide, "SIPELOR BEDAS",
       Inches(0.5), Inches(3.65), Inches(12.3), Inches(0.85),
       size=34, bold=True, color=GOLD, align=PP_ALIGN.CENTER)

    tx(slide, "Sistem Informasi Penyewaan Lapangan Olahraga  •  Kabupaten Bandung",
       Inches(0.5), Inches(4.45), Inches(12.3), Inches(0.55),
       size=17, color=RGBColor(0xCC,0xFF,0xDD), align=PP_ALIGN.CENTER)

    tx(slide, "DISPORA Kabupaten Bandung  •  Dinas Pemuda dan Olahraga  •  Version 1.0.0  •  © 2026",
       Inches(0.5), SLIDE_H - Inches(1.48), Inches(12.3), Inches(0.55),
       size=14, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

    tx(slide, "Built with ❤️ for DISPORA",
       Inches(0.5), SLIDE_H - Inches(0.92), Inches(12.3), Inches(0.55),
       size=13, italic=True, color=GOLD, align=PP_ALIGN.CENTER)


# ════════════════════════════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════════════════════════════

def main():
    print("🎨 SIPELOR BEDAS – PowerPoint Generator v2 (FULL IMAGE)")
    print("=" * 58)

    prefetch_all()

    prs = Presentation()
    prs.slide_width  = SLIDE_W
    prs.slide_height = SLIDE_H

    builders = [
        ("Title & Cover",            s01_title),
        ("Agenda",                   s02_agenda),
        ("Permasalahan",             s03_problems),
        ("Solusi",                   s04_solution),
        ("Fitur Pengguna",           s05_user_features),
        ("Fitur Admin",              s06_admin_features),
        ("Technology Stack",         s07_tech),
        ("Arsitektur Sistem",        s08_architecture),
        ("Keamanan Multi-Layer",     s09_security),
        ("User Journey",             s10_journey),
        ("Admin Dashboard",          s11_dashboard),
        ("Revenue Analytics",        s12_revenue),
        ("Project Statistics",       s13_stats),
        ("Roadmap",                  s14_roadmap),
        ("Target KPI",               s15_kpi),
        ("Business Impact",          s16_impact),
        ("Competitive Advantages",   s17_advantages),
        ("Implementation Plan",      s18_implementation),
        ("Support & Contact",        s19_contact),
        ("Thank You",                s20_thankyou),
    ]

    print("\n🏗️  Building slides...")
    for i, (name, builder) in enumerate(builders, 1):
        print(f"  [{i:02d}/20] {name}")
        try:
            builder(prs)
        except Exception as e:
            print(f"         ⚠️  Error: {e}")
            import traceback; traceback.print_exc()

    output = "SIPELOR_BEDAS_Presentation_v2.pptx"
    prs.save(output)
    import os
    size_mb = os.path.getsize(output) / (1024 * 1024)
    print(f"\n✅ Saved: {output}  ({size_mb:.1f} MB)")
    print(f"   Slides : {len(prs.slides)}")
    print(f"   Format : 16:9 Widescreen (13.33\" × 7.5\")")
    print(f"   Colors : #007148 Green · #0075A4 Blue · #000E15 Dark")
    print(f"   Images : {len(IMG_CACHE)} background photos embedded")


if __name__ == "__main__":
    main()
