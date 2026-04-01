#!/usr/bin/env python3
"""
SIPELOR BEDAS - PowerPoint Presentation Generator
Generates a complete .pptx file for the SIPELOR BEDAS project.
Color Scheme: Primary #007148 (green), Secondary #0075A4 (blue), Accent #000E15 (dark)
"""

from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.util import Inches, Pt
import copy

# ─── COLOR PALETTE ──────────────────────────────────────────────────────────
GREEN_PRIMARY   = RGBColor(0x00, 0x71, 0x48)   # #007148
BLUE_SECONDARY  = RGBColor(0x00, 0x75, 0xA4)   # #0075A4
DARK_ACCENT     = RGBColor(0x00, 0x0E, 0x15)   # #000E15
WHITE           = RGBColor(0xFF, 0xFF, 0xFF)   # #FFFFFF
LIGHT_GRAY      = RGBColor(0xF5, 0xF7, 0xFA)   # #F5F7FA
DARK_TEXT       = RGBColor(0x1A, 0x1A, 0x2E)   # #1A1A2E
GOLD_ACCENT     = RGBColor(0xFF, 0xC1, 0x07)   # #FFC107
GREEN_LIGHT     = RGBColor(0xE8, 0xF5, 0xE9)   # #E8F5E9
BLUE_LIGHT      = RGBColor(0xE3, 0xF2, 0xFD)   # #E3F2FD

# ─── SLIDE DIMENSIONS (16:9) ────────────────────────────────────────────────
SLIDE_W = Inches(13.333)
SLIDE_H = Inches(7.5)

def create_presentation():
    prs = Presentation()
    prs.slide_width  = SLIDE_W
    prs.slide_height = SLIDE_H
    return prs

# ─── HELPERS ────────────────────────────────────────────────────────────────

def add_filled_rect(slide, left, top, width, height, fill_color):
    """Add a solid-filled rectangle shape."""
    shape = slide.shapes.add_shape(
        1,  # MSO_SHAPE_TYPE.RECTANGLE
        left, top, width, height
    )
    shape.line.fill.background()
    shape.fill.solid()
    shape.fill.fore_color.rgb = fill_color
    shape.line.color.rgb = fill_color
    return shape

def add_textbox(slide, text, left, top, width, height,
                font_size=18, bold=False, color=WHITE,
                align=PP_ALIGN.LEFT, italic=False,
                word_wrap=True, font_name="Mulish"):
    """Add a styled textbox."""
    txBox = slide.shapes.add_textbox(left, top, width, height)
    txBox.word_wrap = word_wrap
    tf = txBox.text_frame
    tf.word_wrap = word_wrap
    p = tf.paragraphs[0]
    p.alignment = align
    run = p.add_run()
    run.text = text
    run.font.size = Pt(font_size)
    run.font.bold = bold
    run.font.italic = italic
    run.font.color.rgb = color
    run.font.name = font_name
    return txBox

def add_paragraph(tf, text, font_size=14, bold=False, color=WHITE,
                  align=PP_ALIGN.LEFT, space_before=6, font_name="Mulish", italic=False):
    """Add a paragraph to a text frame."""
    p = tf.add_paragraph()
    p.alignment = align
    p.space_before = Pt(space_before)
    run = p.add_run()
    run.text = text
    run.font.size = Pt(font_size)
    run.font.bold = bold
    run.font.italic = italic
    run.font.color.rgb = color
    run.font.name = font_name
    return p

def set_bg(slide, color):
    """Set slide background color."""
    bg = slide.background
    fill = bg.fill
    fill.solid()
    fill.fore_color.rgb = color

def add_header_bar(slide, title_text, bar_height=Inches(1.2),
                   bar_color=GREEN_PRIMARY, text_color=WHITE,
                   title_size=32, subtitle=None, sub_color=None):
    """Add top header bar with title."""
    add_filled_rect(slide, 0, 0, SLIDE_W, bar_height, bar_color)
    # Title
    add_textbox(slide, title_text,
                Inches(0.5), Inches(0.12), Inches(12.3), bar_height - Inches(0.12),
                font_size=title_size, bold=True, color=text_color,
                align=PP_ALIGN.LEFT)
    if subtitle:
        add_textbox(slide, subtitle,
                    Inches(0.5), Inches(0.75), Inches(12), Inches(0.45),
                    font_size=14, bold=False, color=sub_color or GOLD_ACCENT,
                    align=PP_ALIGN.LEFT)

def add_footer(slide, text="DISPORA Kabupaten Bandung • SIPELOR BEDAS • 2026",
               color=GREEN_PRIMARY, bg=None):
    """Add footer bar."""
    if bg:
        add_filled_rect(slide, 0, SLIDE_H - Inches(0.4), SLIDE_W, Inches(0.4), bg)
    add_textbox(slide, text,
                Inches(0.4), SLIDE_H - Inches(0.38), SLIDE_W - Inches(0.5), Inches(0.35),
                font_size=9, bold=False, color=color, align=PP_ALIGN.CENTER)

def add_slide(prs):
    blank_layout = prs.slide_layouts[6]  # blank layout
    return prs.slides.add_slide(blank_layout)

def add_bullet_box(slide, items, left, top, width, height,
                   bullet="•", item_size=15, color=DARK_TEXT,
                   spacing=8, bold_first=False):
    """Add a bullet list in a textbox."""
    txBox = slide.shapes.add_textbox(left, top, width, height)
    txBox.word_wrap = True
    tf = txBox.text_frame
    tf.word_wrap = True
    for i, item in enumerate(items):
        if i == 0:
            p = tf.paragraphs[0]
        else:
            p = tf.add_paragraph()
        p.space_before = Pt(spacing)
        run = p.add_run()
        run.text = f"{bullet}  {item}" if bullet else item
        run.font.size = Pt(item_size)
        run.font.bold = bold_first and i == 0
        run.font.color.rgb = color
        run.font.name = "Mulish"
    return txBox

def add_card(slide, left, top, width, height, fill_color, border_color=None):
    """Add a colored card (rounded rect-like box)."""
    shape = slide.shapes.add_shape(
        5,  # ROUNDED_RECTANGLE
        left, top, width, height
    )
    shape.fill.solid()
    shape.fill.fore_color.rgb = fill_color
    if border_color:
        shape.line.color.rgb = border_color
        shape.line.width = Pt(1)
    else:
        shape.line.fill.background()
    # Adjust rounding
    shape.adjustments[0] = 0.05
    return shape

def add_card_text(slide, text, left, top, width, height,
                  font_size=14, bold=False, color=WHITE, align=PP_ALIGN.CENTER):
    add_textbox(slide, text, left, top, width, height,
                font_size=font_size, bold=bold, color=color, align=align)

# ════════════════════════════════════════════════════════════════════════════
#  SLIDE BUILDERS
# ════════════════════════════════════════════════════════════════════════════

def slide_01_title(prs):
    """SLIDE 1: Title / Cover"""
    slide = add_slide(prs)
    set_bg(slide, DARK_ACCENT)

    # Left green panel
    add_filled_rect(slide, 0, 0, Inches(7.2), SLIDE_H, GREEN_PRIMARY)

    # Diagonal accent stripe
    from pptx.util import Pt as _Pt
    stripe = slide.shapes.add_shape(1, Inches(7.0), 0, Inches(0.3), SLIDE_H, )
    stripe.fill.solid()
    stripe.fill.fore_color.rgb = BLUE_SECONDARY
    stripe.line.fill.background()

    # App icon placeholder circle
    circle = slide.shapes.add_shape(
        9,  # OVAL
        Inches(0.8), Inches(0.9), Inches(1.6), Inches(1.6)
    )
    circle.fill.solid()
    circle.fill.fore_color.rgb = WHITE
    circle.line.fill.background()

    # Logo text inside circle
    add_textbox(slide, "🏟️", Inches(0.98), Inches(1.05), Inches(1.2), Inches(1.2),
                font_size=36, bold=True, color=GREEN_PRIMARY, align=PP_ALIGN.CENTER)

    # SIPELOR BEDAS title
    add_textbox(slide, "SIPELOR BEDAS",
                Inches(0.6), Inches(2.8), Inches(6.3), Inches(1.2),
                font_size=44, bold=True, color=WHITE, align=PP_ALIGN.LEFT)

    # Subtitle
    add_textbox(slide, "Sistem Informasi Penyewaan Lapangan Olahraga",
                Inches(0.6), Inches(4.05), Inches(6.3), Inches(0.6),
                font_size=18, bold=False, color=GOLD_ACCENT, align=PP_ALIGN.LEFT)

    add_textbox(slide, "Kabupaten Bandung",
                Inches(0.6), Inches(4.65), Inches(6.3), Inches(0.5),
                font_size=18, bold=False, color=GOLD_ACCENT, align=PP_ALIGN.LEFT)

    # Divider line
    add_filled_rect(slide, Inches(0.6), Inches(5.25), Inches(5.5), Inches(0.06), GOLD_ACCENT)

    # Footer left
    add_textbox(slide, "DISPORA Kabupaten Bandung  •  2026",
                Inches(0.6), Inches(5.45), Inches(6), Inches(0.5),
                font_size=13, color=RGBColor(0xCC, 0xFF, 0xDD), align=PP_ALIGN.LEFT)

    # Right side - info
    add_textbox(slide, "Version 1.0.0",
                Inches(7.8), Inches(2.8), Inches(5), Inches(0.5),
                font_size=16, bold=False, color=RGBColor(0xCC, 0xCC, 0xFF), align=PP_ALIGN.CENTER)

    add_textbox(slide, "Flutter  ×  Supabase  ×  Dart",
                Inches(7.5), Inches(3.5), Inches(5.5), Inches(0.5),
                font_size=14, color=RGBColor(0xAA, 0xDD, 0xFF), align=PP_ALIGN.CENTER)

    add_textbox(slide, "Cross-Platform Mobile & Web",
                Inches(7.5), Inches(4.1), Inches(5.5), Inches(0.5),
                font_size=14, color=RGBColor(0xAA, 0xDD, 0xFF), align=PP_ALIGN.CENTER)

    # Stats row right panel
    stats = [("42", "Screens"), ("32", "Services"), ("15K+", "Lines of Code")]
    for i, (num, lbl) in enumerate(stats):
        cx = Inches(7.8 + i * 1.7)
        add_card(slide, cx, Inches(5.2), Inches(1.5), Inches(1.6),
                 RGBColor(0x00, 0x30, 0x55))
        add_textbox(slide, num, cx, Inches(5.3), Inches(1.5), Inches(0.65),
                    font_size=24, bold=True, color=GOLD_ACCENT, align=PP_ALIGN.CENTER)
        add_textbox(slide, lbl, cx, Inches(5.95), Inches(1.5), Inches(0.5),
                    font_size=11, color=WHITE, align=PP_ALIGN.CENTER)


def slide_02_agenda(prs):
    """SLIDE 2: Agenda"""
    slide = add_slide(prs)
    set_bg(slide, LIGHT_GRAY)
    add_header_bar(slide, "Agenda", subtitle="Gambaran Umum Presentasi")

    items = [
        ("01", "Latar Belakang & Permasalahan"),
        ("02", "Solusi SIPELOR BEDAS"),
        ("03", "Fitur Utama (Pengguna & Admin)"),
        ("04", "Teknologi & Keamanan"),
        ("05", "User Journey & Flow"),
        ("06", "Dashboard Admin & Analytics"),
        ("07", "Statistik & Roadmap"),
        ("08", "Dampak Bisnis & KPI"),
    ]

    cols = 2
    col_w = Inches(5.8)
    for i, (num, label) in enumerate(items):
        col = i % cols
        row = i // cols
        cx = Inches(0.5 + col * 6.4)
        cy = Inches(1.4 + row * 1.35)

        add_card(slide, cx, cy, col_w, Inches(1.1), WHITE)
        add_filled_rect(slide, cx, cy, Inches(0.9), Inches(1.1), GREEN_PRIMARY)
        add_textbox(slide, num, cx, cy, Inches(0.9), Inches(1.1),
                    font_size=22, bold=True, color=WHITE, align=PP_ALIGN.CENTER)
        add_textbox(slide, label, cx + Inches(1.0), cy + Inches(0.25),
                    col_w - Inches(1.1), Inches(0.6),
                    font_size=15, bold=False, color=DARK_TEXT, align=PP_ALIGN.LEFT)

    add_footer(slide, color=GREEN_PRIMARY)


def slide_03_problems(prs):
    """SLIDE 3: Permasalahan"""
    slide = add_slide(prs)
    set_bg(slide, LIGHT_GRAY)
    add_header_bar(slide, "Permasalahan Saat Ini",
                   subtitle="Sistem manual yang tidak efisien")

    problems = [
        ("📞", "Booking via telepon atau datang langsung"),
        ("📝", "Pencatatan tidak terstruktur & rentan kesalahan"),
        ("❌", "Tidak ada validasi ketersediaan real-time"),
        ("💰", "Proses pembayaran tidak transparan"),
        ("📊", "Tidak ada data analytics & pelaporan"),
        ("⏰", "Sulit tracking status booking"),
        ("🤝", "Komunikasi admin & pengguna tidak efisien"),
        ("📈", "Laporan revenue dilakukan secara manual"),
    ]

    cols = 2
    for i, (icon, text) in enumerate(problems):
        col = i % cols
        row = i // cols
        cx = Inches(0.4 + col * 6.5)
        cy = Inches(1.4 + row * 1.3)

        add_filled_rect(slide, cx, cy, Inches(5.9), Inches(1.1),
                        RGBColor(0xFF, 0xEB, 0xEE))
        add_filled_rect(slide, cx, cy, Inches(0.08), Inches(1.1),
                        RGBColor(0xE5, 0x39, 0x35))
        add_textbox(slide, icon, cx + Inches(0.15), cy + Inches(0.22),
                    Inches(0.7), Inches(0.65), font_size=22, color=DARK_TEXT)
        add_textbox(slide, text, cx + Inches(0.85), cy + Inches(0.27),
                    Inches(4.8), Inches(0.6), font_size=14, color=DARK_TEXT)

    # Impact box
    add_filled_rect(slide, Inches(0.4), Inches(6.8), Inches(12.5), Inches(0.45),
                    RGBColor(0xE5, 0x39, 0x35))
    add_textbox(slide, "⚠️  Dampak: Inefisiensi operasional, pengalaman pengguna buruk, dan potensi kehilangan pendapatan",
                Inches(0.6), Inches(6.8), Inches(12.2), Inches(0.45),
                font_size=13, bold=True, color=WHITE, align=PP_ALIGN.LEFT)
    add_footer(slide, color=GREEN_PRIMARY)


def slide_04_solution(prs):
    """SLIDE 4: Solusi"""
    slide = add_slide(prs)
    set_bg(slide, GREEN_PRIMARY)

    # Big title
    add_textbox(slide, "SOLUSI", Inches(0.5), Inches(0.5), Inches(12), Inches(0.9),
                font_size=14, bold=True, color=GOLD_ACCENT, align=PP_ALIGN.CENTER)
    add_textbox(slide, "SIPELOR BEDAS",
                Inches(0.5), Inches(1.1), Inches(12.3), Inches(1.3),
                font_size=52, bold=True, color=WHITE, align=PP_ALIGN.CENTER)
    add_textbox(slide, "Platform digital terintegrasi untuk manajemen pemesanan lapangan olahraga",
                Inches(1), Inches(2.4), Inches(11.3), Inches(0.65),
                font_size=17, color=GOLD_ACCENT, align=PP_ALIGN.CENTER)

    # 5 goal cards
    goals = [
        ("🔄", "Digitalisasi\nProses Booking"),
        ("⚡", "Efisiensi\nPengelolaan"),
        ("🔍", "Transparansi\nPembayaran"),
        ("📊", "Data-Driven\nDecision"),
        ("💹", "Optimalisasi\nRevenue"),
    ]
    card_w = Inches(2.3)
    start_x = Inches(0.35)
    for i, (icon, label) in enumerate(goals):
        cx = start_x + i * (card_w + Inches(0.22))
        add_card(slide, cx, Inches(3.3), card_w, Inches(2.8),
                 RGBColor(0x00, 0x50, 0x35))
        add_textbox(slide, icon, cx, Inches(3.55), card_w, Inches(0.8),
                    font_size=34, color=GOLD_ACCENT, align=PP_ALIGN.CENTER)
        add_textbox(slide, label, cx, Inches(4.45), card_w, Inches(0.9),
                    font_size=14, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

    add_footer(slide, text="DISPORA Kabupaten Bandung • SIPELOR BEDAS • 2026",
               color=GOLD_ACCENT)


def slide_05_user_features(prs):
    """SLIDE 5: Fitur Pengguna"""
    slide = add_slide(prs)
    set_bg(slide, LIGHT_GRAY)
    add_header_bar(slide, "Fitur untuk Pengguna",
                   subtitle="Kemudahan booking dari genggaman tangan")

    sections = [
        ("Browse & Booking", GREEN_PRIMARY, [
            "🏟️  Lihat daftar venue & lapangan",
            "📅  Cek ketersediaan real-time",
            "💳  Upload bukti transfer",
            "🎫  E-ticket dengan QR code",
        ]),
        ("Komunikasi", BLUE_SECONDARY, [
            "💬  Real-time chat dengan admin",
            "🔔  Push notifications",
            "⭐  Review & rating venue",
        ]),
        ("Keamanan", DARK_ACCENT, [
            "🔒  Biometric authentication",
            "🔐  Enkripsi data AES-256",
            "🛡️  SSL certificate pinning",
        ]),
    ]

    col_w = Inches(4.0)
    for i, (title, color, items) in enumerate(sections):
        cx = Inches(0.4 + i * 4.3)
        # Header
        add_filled_rect(slide, cx, Inches(1.35), col_w, Inches(0.55), color)
        add_textbox(slide, title, cx + Inches(0.1), Inches(1.37),
                    col_w - Inches(0.1), Inches(0.5),
                    font_size=16, bold=True, color=WHITE)
        # Body
        add_filled_rect(slide, cx, Inches(1.9), col_w, Inches(5.1), WHITE)
        for j, item in enumerate(items):
            add_textbox(slide, item,
                        cx + Inches(0.18), Inches(2.1 + j * 0.75),
                        col_w - Inches(0.25), Inches(0.65),
                        font_size=14, color=DARK_TEXT)

    add_footer(slide, color=GREEN_PRIMARY)


def slide_06_admin_features(prs):
    """SLIDE 6: Fitur Admin"""
    slide = add_slide(prs)
    set_bg(slide, LIGHT_GRAY)
    add_header_bar(slide, "Dashboard Admin",
                   subtitle="Kontrol penuh manajemen venue dan laporan")

    sections = [
        ("📊 Analytics & Monitoring", [
            "Real-time KPI dashboard",
            "Revenue analytics & trends",
            "Booking insights",
            "Performance metrics",
        ]),
        ("✅ Management", [
            "Approve / reject bookings",
            "Staff management (RBAC)",
            "Maintenance scheduling",
            "Chat management",
        ]),
        ("📋 Reporting", [
            "Laporan otomatis harian/mingguan",
            "Export ke PDF & CSV",
            "Custom date range analytics",
            "Venue performance metrics",
        ]),
    ]

    for i, (title, items) in enumerate(sections):
        cx = Inches(0.4 + i * 4.3)
        col_w = Inches(4.1)
        add_card(slide, cx, Inches(1.35), col_w, Inches(5.7), WHITE)
        add_filled_rect(slide, cx, Inches(1.35), col_w, Inches(0.65),
                        [GREEN_PRIMARY, BLUE_SECONDARY, DARK_ACCENT][i])
        add_textbox(slide, title, cx + Inches(0.1), Inches(1.37),
                    col_w - Inches(0.1), Inches(0.6),
                    font_size=14, bold=True, color=WHITE)
        for j, item in enumerate(items):
            # bullet line
            add_filled_rect(slide, cx + Inches(0.18),
                            Inches(2.25 + j * 1.1),
                            Inches(0.06), Inches(0.5),
                            [GREEN_PRIMARY, BLUE_SECONDARY, DARK_ACCENT][i])
            add_textbox(slide, item,
                        cx + Inches(0.35), Inches(2.2 + j * 1.1),
                        col_w - Inches(0.45), Inches(0.6),
                        font_size=13, color=DARK_TEXT)

    add_footer(slide, color=GREEN_PRIMARY)


def slide_07_tech_stack(prs):
    """SLIDE 7: Technology Stack"""
    slide = add_slide(prs)
    set_bg(slide, DARK_ACCENT)

    add_textbox(slide, "TEKNOLOGI", Inches(0.5), Inches(0.2),
                Inches(12.3), Inches(0.5),
                font_size=13, bold=True, color=GOLD_ACCENT, align=PP_ALIGN.CENTER)
    add_textbox(slide, "Technology Stack",
                Inches(0.5), Inches(0.6), Inches(12.3), Inches(0.9),
                font_size=38, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

    stacks = [
        ("Frontend", GREEN_PRIMARY, [
            "Flutter 3.38.4  –  Cross-platform UI",
            "Dart 3.x  –  Modern language",
            "Material Design 3  –  Beautiful UI",
            "FL Chart  –  Analytics charts",
            "Riverpod  –  State management",
        ]),
        ("Backend", BLUE_SECONDARY, [
            "Supabase  –  BaaS (PostgreSQL)",
            "Realtime WebSocket  –  Live data",
            "Supabase Auth  –  Authentication",
            "Supabase Storage  –  File storage",
            "Sentry  –  Error tracking",
        ]),
        ("Security", RGBColor(0x6A, 0x1B, 0x9A), [
            "SSL Certificate Pinning",
            "AES-256 Data Encryption",
            "Biometric Authentication",
            "Rate Limiting & Audit Logs",
            "RASP Runtime Protection",
        ]),
    ]

    for i, (title, color, items) in enumerate(stacks):
        cx = Inches(0.35 + i * 4.35)
        col_w = Inches(4.1)
        add_filled_rect(slide, cx, Inches(1.7), col_w, Inches(0.6), color)
        add_textbox(slide, title, cx + Inches(0.15), Inches(1.73),
                    col_w, Inches(0.55), font_size=18, bold=True, color=WHITE)
        add_filled_rect(slide, cx, Inches(2.3), col_w, Inches(4.5),
                        RGBColor(0x0A, 0x1A, 0x25))
        for j, item in enumerate(items):
            add_textbox(slide, f"▸  {item}",
                        cx + Inches(0.2), Inches(2.5 + j * 0.82),
                        col_w - Inches(0.3), Inches(0.75),
                        font_size=13, color=RGBColor(0xCC, 0xEE, 0xFF))

    # Bottom stats
    stats = [("30+", "Dependencies"), ("15,000+", "Lines of Code"), ("3", "Platforms")]
    for i, (val, lbl) in enumerate(stats):
        cx = Inches(0.9 + i * 4.2)
        add_textbox(slide, val, cx, Inches(7.0), Inches(3), Inches(0.45),
                    font_size=22, bold=True, color=GOLD_ACCENT, align=PP_ALIGN.CENTER)
        add_textbox(slide, lbl, cx, Inches(7.25), Inches(3), Inches(0.3),
                    font_size=11, color=WHITE, align=PP_ALIGN.CENTER)

    add_footer(slide, color=RGBColor(0x88, 0xCC, 0xFF))


def slide_08_architecture(prs):
    """SLIDE 8: System Architecture"""
    slide = add_slide(prs)
    set_bg(slide, LIGHT_GRAY)
    add_header_bar(slide, "Arsitektur Sistem",
                   subtitle="End-to-end platform architecture")

    layers = [
        ("📱  User Devices", "Android  •  iOS  •  Web Browser",
         GREEN_PRIMARY, Inches(1.3)),
        ("⚙️  Flutter Application",
         "42 Screens  •  32 Services  •  15 Models  •  Riverpod State",
         BLUE_SECONDARY, Inches(2.7)),
        ("☁️  Supabase Backend",
         "PostgreSQL  •  Realtime  •  Auth  •  Storage",
         RGBColor(0x3E, 0xCF, 0x8E), Inches(4.1)),
        ("🔗  External Services",
         "Sentry Error Tracking  •  Google OAuth  •  Firebase Push Notif.",
         RGBColor(0x6A, 0x1B, 0x9A), Inches(5.5)),
    ]

    box_w = Inches(10.5)
    cx = Inches(1.4)
    for i, (title, sub, color, cy) in enumerate(layers):
        add_filled_rect(slide, cx, cy, box_w, Inches(0.95), color)
        add_textbox(slide, title, cx + Inches(0.3), cy + Inches(0.12),
                    Inches(4), Inches(0.65), font_size=17, bold=True, color=WHITE)
        add_textbox(slide, sub, cx + Inches(4.2), cy + Inches(0.18),
                    Inches(6), Inches(0.6), font_size=14, color=WHITE,
                    align=PP_ALIGN.RIGHT)
        if i < len(layers) - 1:
            add_textbox(slide, "↕", Inches(6.9), cy + Inches(0.95),
                        Inches(0.6), Inches(0.35),
                        font_size=18, bold=True, color=GREEN_PRIMARY,
                        align=PP_ALIGN.CENTER)

    # Right column facts
    facts = [
        ("10+", "Database Tables"),
        ("3", "Storage Buckets"),
        ("WebSocket", "Realtime Chat"),
        ("RLS", "Row-Level Security"),
    ]
    rx = Inches(12.0)
    for i, (val, lbl) in enumerate(facts):
        cy = Inches(1.4 + i * 1.4)
        add_filled_rect(slide, rx, cy, Inches(1.15), Inches(1.1),
                        GREEN_PRIMARY)
        add_textbox(slide, val, rx, cy + Inches(0.12), Inches(1.15), Inches(0.55),
                    font_size=14, bold=True, color=WHITE, align=PP_ALIGN.CENTER)
        add_textbox(slide, lbl, rx, cy + Inches(0.62), Inches(1.15), Inches(0.4),
                    font_size=9, color=WHITE, align=PP_ALIGN.CENTER)

    add_footer(slide, color=GREEN_PRIMARY)


def slide_09_security(prs):
    """SLIDE 9: Security"""
    slide = add_slide(prs)
    set_bg(slide, LIGHT_GRAY)
    add_header_bar(slide, "Keamanan Multi-Layer",
                   subtitle="Security-first approach untuk perlindungan data pengguna",
                   bar_color=DARK_ACCENT)

    sections = [
        ("🔐 Authentication", [
            "Email verification wajib",
            "Password kuat (min 8 karakter)",
            "Google OAuth / SSO",
            "Biometric (fingerprint / face ID)",
            "Rate limiting: 5 percobaan",
            "Auto-logout 15 menit",
        ]),
        ("🛡️ Data Protection", [
            "At Rest: AES-256 encryption",
            "In Transit: SSL/TLS + pinning",
            "Password: Bcrypt hashing",
            "Secure local storage",
            "File encryption (payment)",
        ]),
        ("🔍 Monitoring", [
            "Comprehensive audit logs",
            "Security event notifications",
            "Sentry error tracking",
            "Failed login tracking",
            "RASP runtime protection",
            "Real-time security alerts",
        ]),
    ]

    for i, (title, items) in enumerate(sections):
        cx = Inches(0.35 + i * 4.35)
        col_w = Inches(4.1)
        color = [DARK_ACCENT, BLUE_SECONDARY, GREEN_PRIMARY][i]
        add_filled_rect(slide, cx, Inches(1.35), col_w, Inches(0.55), color)
        add_textbox(slide, title, cx + Inches(0.1), Inches(1.38),
                    col_w, Inches(0.5), font_size=15, bold=True, color=WHITE)
        add_filled_rect(slide, cx, Inches(1.9), col_w, Inches(5.2), WHITE)
        for j, item in enumerate(items):
            add_filled_rect(slide, cx + Inches(0.2), Inches(2.08 + j * 0.83),
                            Inches(0.25), Inches(0.25), color)
            add_textbox(slide, item,
                        cx + Inches(0.6), Inches(2.0 + j * 0.83),
                        col_w - Inches(0.7), Inches(0.7),
                        font_size=13, color=DARK_TEXT)

    add_footer(slide, color=DARK_ACCENT)


def slide_10_user_journey(prs):
    """SLIDE 10: User Journey"""
    slide = add_slide(prs)
    set_bg(slide, LIGHT_GRAY)
    add_header_bar(slide, "User Journey – Booking Flow",
                   subtitle="Proses booking yang mudah & cepat — rata-rata < 5 menit")

    steps = [
        ("1", "Browse\nVenues", "Lihat & filter"),
        ("2", "Venue\nDetail", "Foto & ulasan"),
        ("3", "Pilih\nWaktu", "Tanggal & jam"),
        ("4", "Konfirmasi", "Review harga"),
        ("5", "Upload\nBukti", "Transfer"),
        ("6", "Tunggu\nApprove", "Verifikasi"),
        ("7", "E-Ticket", "QR Code"),
        ("8", "Check-in", "Scan QR"),
        ("9", "Review", "Rating"),
    ]

    step_w = Inches(1.32)
    start_x = Inches(0.35)

    for i, (num, title, sub) in enumerate(steps):
        cx = start_x + i * (step_w + Inches(0.12))
        cy = Inches(2.2)

        # Circle
        circle = slide.shapes.add_shape(9, cx + Inches(0.21), cy, Inches(0.9), Inches(0.9))
        circle.fill.solid()
        circle.fill.fore_color.rgb = GREEN_PRIMARY
        circle.line.fill.background()
        add_textbox(slide, num, cx + Inches(0.21), cy,
                    Inches(0.9), Inches(0.9),
                    font_size=22, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

        # Arrow between steps
        if i < len(steps) - 1:
            add_textbox(slide, "→",
                        cx + step_w + Inches(0.02), cy + Inches(0.22),
                        Inches(0.1), Inches(0.5),
                        font_size=14, bold=True, color=GREEN_PRIMARY)

        # Step card
        add_filled_rect(slide, cx, Inches(3.35), step_w, Inches(2.2), WHITE)
        add_filled_rect(slide, cx, Inches(3.35), step_w, Inches(0.08), GREEN_PRIMARY)
        add_textbox(slide, title, cx, Inches(3.5), step_w, Inches(0.8),
                    font_size=13, bold=True, color=DARK_TEXT, align=PP_ALIGN.CENTER)
        add_textbox(slide, sub, cx, Inches(4.35), step_w, Inches(0.55),
                    font_size=11, color=BLUE_SECONDARY, align=PP_ALIGN.CENTER)

    # Time indicator
    add_filled_rect(slide, Inches(0.35), Inches(5.9), Inches(12.6), Inches(0.7),
                    GREEN_PRIMARY)
    add_textbox(slide, "⏱️  Average Time: < 5 menit dari browse hingga konfirmasi booking",
                Inches(0.5), Inches(5.9), Inches(12.3), Inches(0.7),
                font_size=16, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

    add_footer(slide, color=GREEN_PRIMARY)


def slide_11_admin_dashboard(prs):
    """SLIDE 11: Admin Dashboard Overview"""
    slide = add_slide(prs)
    set_bg(slide, LIGHT_GRAY)
    add_header_bar(slide, "Admin Dashboard Overview",
                   subtitle="Real-time monitoring & manajemen terpusat")

    # KPI Cards
    kpis = [
        ("245", "Total Bookings", "+12%", GREEN_PRIMARY),
        ("Rp 12.5M", "Revenue Hari Ini", "+8.5%", BLUE_SECONDARY),
        ("8", "Pembayaran Pending", "-2", RGBColor(0xFF, 0x88, 0x00)),
        ("1,234", "Pengguna Aktif", "+45", RGBColor(0x6A, 0x1B, 0x9A)),
    ]

    kpi_w = Inches(2.9)
    for i, (val, lbl, change, color) in enumerate(kpis):
        cx = Inches(0.4 + i * 3.1)
        add_filled_rect(slide, cx, Inches(1.35), kpi_w, Inches(1.5), color)
        add_textbox(slide, val, cx, Inches(1.45), kpi_w, Inches(0.75),
                    font_size=28, bold=True, color=WHITE, align=PP_ALIGN.CENTER)
        add_textbox(slide, lbl, cx, Inches(2.1), kpi_w, Inches(0.5),
                    font_size=12, color=WHITE, align=PP_ALIGN.CENTER)
        add_textbox(slide, change, cx, Inches(2.55), kpi_w, Inches(0.35),
                    font_size=12, bold=True, color=GOLD_ACCENT, align=PP_ALIGN.CENTER)

    # Visualizations
    visuals = [
        ("📈", "Booking Trends", "Grafik 30 hari terakhir"),
        ("💰", "Revenue by Venue", "Pie chart per lapangan"),
        ("⏰", "Peak Hours", "Analisis jam ramai"),
        ("🏆", "Top Venues", "Performa terbaik"),
    ]
    for i, (icon, title, desc) in enumerate(visuals):
        cx = Inches(0.4 + (i % 2) * 6.5)
        cy = Inches(3.15 + (i // 2) * 1.7)
        add_filled_rect(slide, cx, cy, Inches(6.0), Inches(1.5), WHITE)
        add_textbox(slide, icon, cx + Inches(0.2), cy + Inches(0.35),
                    Inches(0.7), Inches(0.75), font_size=26, color=GREEN_PRIMARY)
        add_textbox(slide, title, cx + Inches(1.0), cy + Inches(0.25),
                    Inches(4.5), Inches(0.55), font_size=16, bold=True, color=DARK_TEXT)
        add_textbox(slide, desc, cx + Inches(1.0), cy + Inches(0.8),
                    Inches(4.5), Inches(0.4), font_size=12, color=BLUE_SECONDARY)

    add_footer(slide, color=GREEN_PRIMARY)


def slide_12_revenue(prs):
    """SLIDE 12: Revenue Analytics"""
    slide = add_slide(prs)
    set_bg(slide, LIGHT_GRAY)
    add_header_bar(slide, "Revenue Analytics",
                   subtitle="Data pendapatan & performa bisnis")

    # Big metric
    add_filled_rect(slide, Inches(0.4), Inches(1.4), Inches(5.5), Inches(2.5),
                    GREEN_PRIMARY)
    add_textbox(slide, "Total Revenue", Inches(0.5), Inches(1.55),
                Inches(5.3), Inches(0.5), font_size=14, color=GOLD_ACCENT,
                align=PP_ALIGN.CENTER)
    add_textbox(slide, "Rp 125.4M", Inches(0.5), Inches(1.9),
                Inches(5.3), Inches(1.0), font_size=40, bold=True, color=WHITE,
                align=PP_ALIGN.CENTER)
    add_textbox(slide, "↑ +12.5% vs periode sebelumnya",
                Inches(0.5), Inches(2.85), Inches(5.3), Inches(0.5),
                font_size=14, bold=True, color=GOLD_ACCENT, align=PP_ALIGN.CENTER)

    # Avg metric
    add_filled_rect(slide, Inches(0.4), Inches(4.1), Inches(2.6), Inches(1.4),
                    BLUE_SECONDARY)
    add_textbox(slide, "Rp 512K", Inches(0.5), Inches(4.25),
                Inches(2.4), Inches(0.65), font_size=24, bold=True, color=WHITE,
                align=PP_ALIGN.CENTER)
    add_textbox(slide, "Rata-rata / Booking", Inches(0.5), Inches(4.85),
                Inches(2.4), Inches(0.45), font_size=11, color=WHITE,
                align=PP_ALIGN.CENTER)

    # Growth
    add_filled_rect(slide, Inches(3.2), Inches(4.1), Inches(2.6), Inches(1.4),
                    RGBColor(0xFF, 0x88, 0x00))
    add_textbox(slide, "+12.5%", Inches(3.3), Inches(4.25),
                Inches(2.4), Inches(0.65), font_size=28, bold=True, color=WHITE,
                align=PP_ALIGN.CENTER)
    add_textbox(slide, "Growth Rate", Inches(3.3), Inches(4.85),
                Inches(2.4), Inches(0.45), font_size=11, color=WHITE,
                align=PP_ALIGN.CENTER)

    # Breakdown bars
    breakdown = [
        ("⚽ Futsal",    36, "Rp 45.2M", GREEN_PRIMARY),
        ("🏸 Badminton", 26, "Rp 32.1M", BLUE_SECONDARY),
        ("🏀 Basket",    23, "Rp 28.3M", RGBColor(0xFF, 0x88, 0x00)),
        ("🎾 Tenis",     15, "Rp 19.8M", RGBColor(0x6A, 0x1B, 0x9A)),
    ]
    bx = Inches(6.3)
    add_textbox(slide, "Revenue per Venue", bx, Inches(1.4),
                Inches(6.5), Inches(0.5), font_size=18, bold=True, color=DARK_TEXT)
    for i, (label, pct, amount, color) in enumerate(breakdown):
        cy = Inches(2.1 + i * 1.15)
        add_textbox(slide, label, bx, cy, Inches(2.2), Inches(0.4),
                    font_size=13, color=DARK_TEXT)
        bar_full = Inches(5.5)
        bar_filled = bar_full * pct / 100
        add_filled_rect(slide, bx, cy + Inches(0.45), bar_full, Inches(0.45),
                        RGBColor(0xE0, 0xE0, 0xE0))
        add_filled_rect(slide, bx, cy + Inches(0.45), bar_filled, Inches(0.45), color)
        add_textbox(slide, f"{pct}%  |  {amount}",
                    bx + bar_filled + Inches(0.1), cy + Inches(0.48),
                    Inches(2), Inches(0.4), font_size=12, bold=True, color=color)

    # Peak hours
    add_filled_rect(slide, Inches(6.3), Inches(6.55), Inches(6.5), Inches(0.65),
                    GREEN_PRIMARY)
    add_textbox(slide, "⏰  Peak Hours: 14:00–16:00  (35% of bookings)",
                Inches(6.4), Inches(6.57), Inches(6.3), Inches(0.6),
                font_size=14, bold=True, color=WHITE)

    add_footer(slide, color=GREEN_PRIMARY)


def slide_13_stats(prs):
    """SLIDE 13: Project Statistics"""
    slide = add_slide(prs)
    set_bg(slide, DARK_ACCENT)

    add_textbox(slide, "STATISTIK PROYEK",
                Inches(0.5), Inches(0.3), Inches(12.3), Inches(0.55),
                font_size=13, bold=True, color=GOLD_ACCENT, align=PP_ALIGN.CENTER)
    add_textbox(slide, "Project Statistics",
                Inches(0.5), Inches(0.75), Inches(12.3), Inches(0.9),
                font_size=38, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

    stats = [
        ("15,000+", "Lines of Code"),
        ("42",       "Screens"),
        ("32",       "Services"),
        ("15",       "Data Models"),
        ("30+",      "Dependencies"),
        ("17+",      "Dokumentasi"),
    ]

    cols = 3
    for i, (val, lbl) in enumerate(stats):
        col = i % cols
        row = i // cols
        cx = Inches(1.0 + col * 3.9)
        cy = Inches(1.9 + row * 2.2)
        add_filled_rect(slide, cx, cy, Inches(3.4), Inches(1.8),
                        RGBColor(0x00, 0x30, 0x45))
        add_textbox(slide, val, cx, cy + Inches(0.2), Inches(3.4), Inches(0.95),
                    font_size=38, bold=True, color=GOLD_ACCENT, align=PP_ALIGN.CENTER)
        add_textbox(slide, lbl, cx, cy + Inches(1.1), Inches(3.4), Inches(0.55),
                    font_size=15, color=WHITE, align=PP_ALIGN.CENTER)

    # Screens breakdown
    breakdown_items = [
        "Auth: 6", "User: 11", "Admin: 10",
        "Venue: 2", "Settings: 3", "Debug: 4",
    ]
    add_textbox(slide, "Screens Breakdown:",
                Inches(0.5), Inches(6.42), Inches(3), Inches(0.4),
                font_size=12, bold=True, color=GOLD_ACCENT)
    add_textbox(slide, "  •  ".join(breakdown_items),
                Inches(3.0), Inches(6.42), Inches(9.8), Inches(0.4),
                font_size=12, color=WHITE)

    add_footer(slide, color=RGBColor(0x88, 0xCC, 0xFF))


def slide_14_roadmap(prs):
    """SLIDE 14: Roadmap"""
    slide = add_slide(prs)
    set_bg(slide, LIGHT_GRAY)
    add_header_bar(slide, "Development Roadmap",
                   subtitle="Perencanaan pengembangan jangka pendek & panjang")

    phases = [
        ("✅ Phase 1 – COMPLETED", "2025-2026", GREEN_PRIMARY, [
            "User authentication & profiles",
            "Booking & payment verification",
            "Admin dashboard & analytics",
            "Real-time chat & notifications",
            "Security multi-layer features",
            "Revenue analytics & reporting",
        ]),
        ("🚧 Phase 2 – PLANNED", "2026", BLUE_SECONDARY, [
            "iOS app deployment",
            "Payment gateway integration",
            "Advanced analytics & BI",
            "QR scanner for staff",
            "Multi-language support",
            "Dark mode",
        ]),
        ("🔮 Phase 3 – FUTURE", "2027+", RGBColor(0x6A, 0x1B, 0x9A), [
            "AI booking recommendations",
            "IoT field sensors",
            "Dynamic pricing algorithms",
            "Loyalty program",
            "Advanced user analytics",
        ]),
    ]

    for i, (title, period, color, items) in enumerate(phases):
        cx = Inches(0.35 + i * 4.35)
        col_w = Inches(4.1)
        add_filled_rect(slide, cx, Inches(1.35), col_w, Inches(0.65), color)
        add_textbox(slide, title, cx + Inches(0.1), Inches(1.38),
                    col_w, Inches(0.5), font_size=14, bold=True, color=WHITE)
        add_filled_rect(slide, cx, Inches(2.0), col_w, Inches(0.35),
                        RGBColor(0xE0, 0xE8, 0xFF))
        add_textbox(slide, f"📅  Target: {period}",
                    cx + Inches(0.2), Inches(2.02), col_w, Inches(0.32),
                    font_size=11, bold=True, color=DARK_TEXT)
        add_filled_rect(slide, cx, Inches(2.35), col_w, Inches(4.85), WHITE)
        for j, item in enumerate(items):
            add_filled_rect(slide, cx + Inches(0.2),
                            Inches(2.55 + j * 0.78),
                            Inches(0.18), Inches(0.18), color)
            add_textbox(slide, item,
                        cx + Inches(0.5), Inches(2.48 + j * 0.78),
                        col_w - Inches(0.6), Inches(0.65),
                        font_size=13, color=DARK_TEXT)

    add_footer(slide, color=GREEN_PRIMARY)


def slide_15_kpi(prs):
    """SLIDE 15: KPI Targets"""
    slide = add_slide(prs)
    set_bg(slide, LIGHT_GRAY)
    add_header_bar(slide, "Target KPI – Year 1",
                   subtitle="Key Performance Indicators untuk tahun pertama")

    categories = [
        ("👥 User Adoption", GREEN_PRIMARY, [
            ("5,000+", "Registered Users"),
            ("70%+", "Monthly Active Users"),
            ("4.5+", "Star Rating"),
        ]),
        ("💼 Business", BLUE_SECONDARY, [
            ("10,000+", "Bookings / Month"),
            ("85%+", "Completion Rate"),
            ("50%+", "Revenue Increase"),
        ]),
        ("⚙️ Operational", DARK_ACCENT, [
            ("< 2 min", "Booking Time"),
            ("< 1 hour", "Payment Approval"),
            ("95%+", "System Uptime"),
        ]),
    ]

    for i, (cat_title, color, items) in enumerate(categories):
        cx = Inches(0.35 + i * 4.35)
        col_w = Inches(4.1)
        add_filled_rect(slide, cx, Inches(1.35), col_w, Inches(0.6), color)
        add_textbox(slide, cat_title, cx + Inches(0.15), Inches(1.38),
                    col_w, Inches(0.55), font_size=16, bold=True, color=WHITE)
        for j, (val, lbl) in enumerate(items):
            cy = Inches(2.2 + j * 1.55)
            add_filled_rect(slide, cx, cy, col_w, Inches(1.35), WHITE)
            add_filled_rect(slide, cx, cy, Inches(0.1), Inches(1.35), color)
            add_textbox(slide, val, cx + Inches(0.2), cy + Inches(0.12),
                        col_w - Inches(0.25), Inches(0.75),
                        font_size=28, bold=True, color=color, align=PP_ALIGN.CENTER)
            add_textbox(slide, lbl, cx + Inches(0.2), cy + Inches(0.85),
                        col_w - Inches(0.25), Inches(0.4),
                        font_size=13, color=DARK_TEXT, align=PP_ALIGN.CENTER)

    # Satisfaction
    add_filled_rect(slide, Inches(0.35), Inches(6.85), Inches(12.6), Inches(0.55),
                    GREEN_PRIMARY)
    add_textbox(slide, "🎯  80%+ User Satisfaction Score",
                Inches(0.5), Inches(6.87), Inches(12.3), Inches(0.5),
                font_size=16, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

    add_footer(slide, color=GREEN_PRIMARY)


def slide_16_impact(prs):
    """SLIDE 16: Business Impact"""
    slide = add_slide(prs)
    set_bg(slide, LIGHT_GRAY)
    add_header_bar(slide, "Expected Business Impact",
                   subtitle="Manfaat nyata bagi DISPORA dan masyarakat Kabupaten Bandung")

    # Left: DISPORA benefits
    add_filled_rect(slide, Inches(0.4), Inches(1.35), Inches(5.9), Inches(0.55),
                    GREEN_PRIMARY)
    add_textbox(slide, "🏛️  Untuk DISPORA", Inches(0.5), Inches(1.38),
                Inches(5.7), Inches(0.5), font_size=16, bold=True, color=WHITE)

    dispora_items = [
        "Data-driven decision making",
        "Optimalisasi pendapatan venue",
        "Peningkatan layanan publik",
        "Transparansi & akuntabilitas",
        "Pengurangan beban kerja manual",
    ]
    add_filled_rect(slide, Inches(0.4), Inches(1.9), Inches(5.9), Inches(5.35), WHITE)
    for i, item in enumerate(dispora_items):
        add_filled_rect(slide, Inches(0.55), Inches(2.1 + i * 1.0),
                        Inches(0.3), Inches(0.3), GREEN_PRIMARY)
        add_textbox(slide, item, Inches(1.0), Inches(2.05 + i * 1.0),
                    Inches(5.0), Inches(0.55), font_size=15, color=DARK_TEXT)

    # Right: Masyarakat benefits
    add_filled_rect(slide, Inches(7.0), Inches(1.35), Inches(5.9), Inches(0.55),
                    BLUE_SECONDARY)
    add_textbox(slide, "👥  Untuk Masyarakat", Inches(7.1), Inches(1.38),
                Inches(5.7), Inches(0.5), font_size=16, bold=True, color=WHITE)

    masyarakat_items = [
        "Booking 24/7 kapan & di mana saja",
        "Hemat waktu & lebih efisien",
        "Kemudahan via mobile app",
        "Pembayaran aman & terlacak",
        "Pengalaman pengguna modern",
    ]
    add_filled_rect(slide, Inches(7.0), Inches(1.9), Inches(5.9), Inches(5.35), WHITE)
    for i, item in enumerate(masyarakat_items):
        add_filled_rect(slide, Inches(7.15), Inches(2.1 + i * 1.0),
                        Inches(0.3), Inches(0.3), BLUE_SECONDARY)
        add_textbox(slide, item, Inches(7.6), Inches(2.05 + i * 1.0),
                    Inches(5.0), Inches(0.55), font_size=15, color=DARK_TEXT)

    add_footer(slide, color=GREEN_PRIMARY)


def slide_17_advantages(prs):
    """SLIDE 17: Competitive Advantages"""
    slide = add_slide(prs)
    set_bg(slide, GREEN_PRIMARY)

    add_textbox(slide, "KEUNGGULAN KOMPETITIF",
                Inches(0.5), Inches(0.25), Inches(12.3), Inches(0.5),
                font_size=13, bold=True, color=GOLD_ACCENT, align=PP_ALIGN.CENTER)
    add_textbox(slide, "Why SIPELOR BEDAS?",
                Inches(0.5), Inches(0.7), Inches(12.3), Inches(0.9),
                font_size=38, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

    advantages = [
        ("1️⃣", "Government-Backed",
         "Platform resmi DISPORA Kab. Bandung – terpercaya & sah"),
        ("2️⃣", "Comprehensive",
         "Solusi end-to-end booking, payment, chat & analytics"),
        ("3️⃣", "Security-First",
         "Multi-layer protection: biometrik, AES-256, SSL pinning"),
        ("4️⃣", "Data-Driven",
         "Real-time analytics & laporan untuk keputusan bisnis"),
        ("5️⃣", "Modern Tech",
         "Flutter + Supabase – scalable, cross-platform, cepat"),
        ("6️⃣", "User-Centric",
         "Desain intuitif, alur booking < 5 menit, rating tinggi"),
    ]

    cols = 2
    card_w = Inches(5.9)
    for i, (num, title, desc) in enumerate(advantages):
        col = i % cols
        row = i // cols
        cx = Inches(0.5 + col * 6.4)
        cy = Inches(1.85 + row * 1.65)
        add_filled_rect(slide, cx, cy, card_w, Inches(1.45),
                        RGBColor(0x00, 0x55, 0x35))
        add_textbox(slide, num, cx + Inches(0.15), cy + Inches(0.35),
                    Inches(0.65), Inches(0.7), font_size=24, color=GOLD_ACCENT)
        add_textbox(slide, title, cx + Inches(0.85), cy + Inches(0.18),
                    card_w - Inches(1.0), Inches(0.55),
                    font_size=17, bold=True, color=WHITE)
        add_textbox(slide, desc, cx + Inches(0.85), cy + Inches(0.72),
                    card_w - Inches(1.0), Inches(0.55),
                    font_size=13, color=RGBColor(0xCC, 0xFF, 0xDD))

    add_textbox(slide,
                "\"One platform for booking, payment, analytics, and management\"",
                Inches(0.5), Inches(6.85), Inches(12.3), Inches(0.5),
                font_size=15, bold=True, italic=True, color=GOLD_ACCENT,
                align=PP_ALIGN.CENTER)

    add_footer(slide, color=GOLD_ACCENT)


def slide_18_implementation(prs):
    """SLIDE 18: Implementation Plan"""
    slide = add_slide(prs)
    set_bg(slide, LIGHT_GRAY)
    add_header_bar(slide, "Rencana Implementasi",
                   subtitle="Langkah-langkah peluncuran & onboarding")

    phases = [
        ("🚀 Bulan 1: Launch", GREEN_PRIMARY, [
            "Deploy ke production server",
            "Pelatihan staff DISPORA",
            "Soft launch terbatas",
            "Monitoring awal & bug fixing",
        ]),
        ("📢 Bulan 2: Onboarding", BLUE_SECONDARY, [
            "User onboarding & tutorial",
            "Kampanye marketing digital",
            "Pengumpulan feedback awal",
            "Analisis data penggunaan",
        ]),
        ("📈 Bulan 3+: Optimasi", DARK_ACCENT, [
            "Monitor KPI & target",
            "Integrasi feedback pengguna",
            "Perbaikan & peningkatan UX",
            "Persiapan Phase 2",
        ]),
    ]

    for i, (title, color, items) in enumerate(phases):
        cx = Inches(0.35 + i * 4.35)
        col_w = Inches(4.1)

        # Phase indicator
        circle = slide.shapes.add_shape(9, cx + col_w / 2 - Inches(0.45),
                                         Inches(1.35), Inches(0.9), Inches(0.9))
        circle.fill.solid()
        circle.fill.fore_color.rgb = color
        circle.line.fill.background()
        add_textbox(slide, str(i + 1),
                    cx + col_w / 2 - Inches(0.45), Inches(1.35),
                    Inches(0.9), Inches(0.9),
                    font_size=22, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

        add_filled_rect(slide, cx, Inches(2.4), col_w, Inches(0.55), color)
        add_textbox(slide, title, cx + Inches(0.1), Inches(2.43),
                    col_w, Inches(0.5), font_size=14, bold=True, color=WHITE)

        add_filled_rect(slide, cx, Inches(2.95), col_w, Inches(4.35), WHITE)
        for j, item in enumerate(items):
            add_filled_rect(slide, cx + Inches(0.2),
                            Inches(3.15 + j * 1.0),
                            Inches(0.2), Inches(0.2), color)
            add_textbox(slide, item,
                        cx + Inches(0.55), Inches(3.08 + j * 1.0),
                        col_w - Inches(0.65), Inches(0.65),
                        font_size=14, color=DARK_TEXT)

    # Timeline arrow
    add_filled_rect(slide, Inches(0.35), Inches(6.75), Inches(12.6), Inches(0.18),
                    GREEN_PRIMARY)
    add_textbox(slide, "▶",
                Inches(12.7), Inches(6.7), Inches(0.5), Inches(0.35),
                font_size=16, bold=True, color=GREEN_PRIMARY)
    for i, lbl in enumerate(["Bulan 1", "Bulan 2", "Bulan 3+"]):
        add_textbox(slide, lbl,
                    Inches(0.4 + i * 4.3), Inches(6.9), Inches(4.1), Inches(0.3),
                    font_size=12, bold=True, color=GREEN_PRIMARY, align=PP_ALIGN.CENTER)

    add_footer(slide, color=GREEN_PRIMARY)


def slide_19_contact(prs):
    """SLIDE 19: Contact"""
    slide = add_slide(prs)
    set_bg(slide, LIGHT_GRAY)
    add_header_bar(slide, "Dukungan & Kontak",
                   subtitle="Kami siap membantu")

    # Left: Tech Support
    add_filled_rect(slide, Inches(0.4), Inches(1.4), Inches(5.8), Inches(0.55),
                    GREEN_PRIMARY)
    add_textbox(slide, "🛠️  Dukungan Teknis", Inches(0.5), Inches(1.43),
                Inches(5.6), Inches(0.5), font_size=16, bold=True, color=WHITE)
    add_filled_rect(slide, Inches(0.4), Inches(1.95), Inches(5.8), Inches(3.85), WHITE)
    tech_items = [
        ("📧", "dev-team@sipelor-bedas.com"),
        ("💬", "In-app chat support"),
        ("🌐", "www.sipelor-bedas.com"),
        ("📁", "Dokumentasi di folder /docs"),
    ]
    for i, (icon, text) in enumerate(tech_items):
        add_textbox(slide, icon, Inches(0.65), Inches(2.15 + i * 0.9),
                    Inches(0.55), Inches(0.6), font_size=22, color=GREEN_PRIMARY)
        add_textbox(slide, text, Inches(1.3), Inches(2.2 + i * 0.9),
                    Inches(4.6), Inches(0.55), font_size=14, color=DARK_TEXT)

    # Right: DISPORA Contact
    add_filled_rect(slide, Inches(7.0), Inches(1.4), Inches(5.8), Inches(0.55),
                    BLUE_SECONDARY)
    add_textbox(slide, "🏛️  Kontak DISPORA", Inches(7.1), Inches(1.43),
                Inches(5.6), Inches(0.5), font_size=16, bold=True, color=WHITE)
    add_filled_rect(slide, Inches(7.0), Inches(1.95), Inches(5.8), Inches(3.85), WHITE)
    dispora_items = [
        ("📧", "dispora@bandungkab.go.id"),
        ("📧", "admin@sipelor-bedas.com"),
        ("📱", "(022) xxxx-xxxx"),
        ("🏢", "Dinas Pemuda dan Olahraga"),
    ]
    for i, (icon, text) in enumerate(dispora_items):
        add_textbox(slide, icon, Inches(7.25), Inches(2.15 + i * 0.9),
                    Inches(0.55), Inches(0.6), font_size=22, color=BLUE_SECONDARY)
        add_textbox(slide, text, Inches(7.9), Inches(2.2 + i * 0.9),
                    Inches(4.6), Inches(0.55), font_size=14, color=DARK_TEXT)

    # Office hours
    add_filled_rect(slide, Inches(0.4), Inches(6.0), Inches(12.5), Inches(1.0),
                    RGBColor(0xE8, 0xF5, 0xE9))
    add_filled_rect(slide, Inches(0.4), Inches(6.0), Inches(0.1), Inches(1.0),
                    GREEN_PRIMARY)
    add_textbox(slide, "🕐  Jam Operasional:",
                Inches(0.65), Inches(6.08), Inches(3), Inches(0.45),
                font_size=14, bold=True, color=DARK_TEXT)
    add_textbox(slide,
                "Senin – Jumat: 08:00 – 17:00 WIB     |     Sabtu: 08:00 – 12:00 WIB",
                Inches(3.5), Inches(6.08), Inches(9.2), Inches(0.45),
                font_size=14, color=DARK_TEXT)

    add_footer(slide, color=GREEN_PRIMARY)


def slide_20_thankyou(prs):
    """SLIDE 20: Thank You"""
    slide = add_slide(prs)
    set_bg(slide, DARK_ACCENT)

    # Left green side bar
    add_filled_rect(slide, 0, 0, Inches(0.5), SLIDE_H, GREEN_PRIMARY)
    add_filled_rect(slide, Inches(0.5), 0, Inches(0.08), SLIDE_H, GOLD_ACCENT)

    # Right side decoration
    add_filled_rect(slide, SLIDE_W - Inches(0.5), 0, Inches(0.5), SLIDE_H, GREEN_PRIMARY)

    # Bottom bar
    add_filled_rect(slide, 0, SLIDE_H - Inches(1.6), SLIDE_W, Inches(1.6),
                    GREEN_PRIMARY)

    # Stadium icon
    add_textbox(slide, "🏟️", Inches(5.5), Inches(0.6), Inches(2.3), Inches(1.8),
                font_size=64, color=GREEN_PRIMARY, align=PP_ALIGN.CENTER)

    # Terima Kasih
    add_textbox(slide, "Terima Kasih",
                Inches(0.8), Inches(2.4), Inches(11.7), Inches(1.4),
                font_size=56, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

    add_textbox(slide, "SIPELOR BEDAS",
                Inches(0.8), Inches(3.75), Inches(11.7), Inches(0.85),
                font_size=32, bold=True, color=GOLD_ACCENT, align=PP_ALIGN.CENTER)

    add_textbox(slide, "Sistem Informasi Penyewaan Lapangan Olahraga",
                Inches(0.8), Inches(4.55), Inches(11.7), Inches(0.55),
                font_size=18, color=RGBColor(0xCC, 0xFF, 0xDD), align=PP_ALIGN.CENTER)

    add_textbox(slide, "Kabupaten Bandung",
                Inches(0.8), Inches(5.05), Inches(11.7), Inches(0.55),
                font_size=18, color=RGBColor(0xCC, 0xFF, 0xDD), align=PP_ALIGN.CENTER)

    # Bottom bar content
    add_textbox(slide,
                "DISPORA Kabupaten Bandung  •  Dinas Pemuda dan Olahraga  •  Version 1.0.0  •  © 2026",
                Inches(0.8), SLIDE_H - Inches(1.45), Inches(11.7), Inches(0.55),
                font_size=14, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

    add_textbox(slide, "Built with ❤️ for DISPORA",
                Inches(0.8), SLIDE_H - Inches(0.9), Inches(11.7), Inches(0.55),
                font_size=13, color=GOLD_ACCENT, align=PP_ALIGN.CENTER)


# ════════════════════════════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════════════════════════════

def main():
    print("🎯 Generating SIPELOR BEDAS PowerPoint presentation...")
    prs = create_presentation()

    builders = [
        slide_01_title,
        slide_02_agenda,
        slide_03_problems,
        slide_04_solution,
        slide_05_user_features,
        slide_06_admin_features,
        slide_07_tech_stack,
        slide_08_architecture,
        slide_09_security,
        slide_10_user_journey,
        slide_11_admin_dashboard,
        slide_12_revenue,
        slide_13_stats,
        slide_14_roadmap,
        slide_15_kpi,
        slide_16_impact,
        slide_17_advantages,
        slide_18_implementation,
        slide_19_contact,
        slide_20_thankyou,
    ]

    for i, builder in enumerate(builders, 1):
        print(f"  ▸ Building slide {i:02d}/20 — {builder.__name__.replace('slide_', '').replace('_', ' ').title()}")
        builder(prs)

    output_path = "SIPELOR_BEDAS_Presentation.pptx"
    prs.save(output_path)
    print(f"\n✅ Presentation saved: {output_path}")
    print(f"   Total slides: {len(prs.slides)}")
    print(f"   Format: 16:9 Widescreen (13.33\" × 7.5\")")
    print(f"   Color scheme: #007148 Green • #0075A4 Blue • #000E15 Dark")


if __name__ == "__main__":
    main()
