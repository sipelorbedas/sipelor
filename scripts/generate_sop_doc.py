"""
Script untuk generate SOP SIPELOR BEDAS dalam format .docx yang rapih
Jalankan: py scripts/generate_sop_doc.py
"""

from docx import Document
from docx.shared import Pt, Cm, RGBColor, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
import copy

# ─── Warna ────────────────────────────────────────────────────────────────────
COLOR_PRIMARY   = RGBColor(0x1A, 0x37, 0x6C)   # Biru tua  (header, judul)
COLOR_ACCENT    = RGBColor(0x00, 0x71, 0x48)   # Hijau     (SOP nomor, aksen)
COLOR_LIGHT_BG  = RGBColor(0xF0, 0xF4, 0xFF)   # Biru muda (header tabel)
COLOR_WHITE     = RGBColor(0xFF, 0xFF, 0xFF)
COLOR_DARK_TEXT = RGBColor(0x1A, 0x1A, 0x2E)
COLOR_GRAY      = RGBColor(0x6B, 0x72, 0x80)

# ─── Helper: shade cell ───────────────────────────────────────────────────────
def shade_cell(cell, hex_color: str):
    """Fill a table cell with a solid background colour (hex, e.g. '1A376C')."""
    tc   = cell._tc
    tcPr = tc.get_or_add_tcPr()
    shd  = OxmlElement('w:shd')
    shd.set(qn('w:val'),   'clear')
    shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:fill'),  hex_color)
    tcPr.append(shd)


def set_cell_border(cell, **kwargs):
    """Set borders on a table cell. kwargs: top, bottom, left, right — each a dict."""
    tc   = cell._tc
    tcPr = tc.get_or_add_tcPr()
    tcBorders = OxmlElement('w:tcBorders')
    for edge in ('top', 'left', 'bottom', 'right', 'insideH', 'insideV'):
        if edge in kwargs:
            tag  = OxmlElement(f'w:{edge}')
            opts = kwargs[edge]
            for key, val in opts.items():
                tag.set(qn(f'w:{key}'), val)
            tcBorders.append(tag)
    tcPr.append(tcBorders)


def add_page_number(paragraph):
    """Insert 'Halaman X dari Y' page numbering in a paragraph."""
    paragraph.clear()
    run = paragraph.add_run('Halaman ')
    run.font.size = Pt(9)
    run.font.color.rgb = COLOR_GRAY

    fld_char = OxmlElement('w:fldChar')
    fld_char.set(qn('w:fldCharType'), 'begin')
    run._r.append(fld_char)

    instr = OxmlElement('w:instrText')
    instr.set(qn('xml:space'), 'preserve')
    instr.text = 'PAGE'
    run._r.append(instr)

    fld_char2 = OxmlElement('w:fldChar')
    fld_char2.set(qn('w:fldCharType'), 'end')
    run._r.append(fld_char2)

    run2 = paragraph.add_run(' dari ')
    run2.font.size = Pt(9)
    run2.font.color.rgb = COLOR_GRAY

    fld_char3 = OxmlElement('w:fldChar')
    fld_char3.set(qn('w:fldCharType'), 'begin')
    run2._r.append(fld_char3)

    instr2 = OxmlElement('w:instrText')
    instr2.set(qn('xml:space'), 'preserve')
    instr2.text = 'NUMPAGES'
    run2._r.append(instr2)

    fld_char4 = OxmlElement('w:fldChar')
    fld_char4.set(qn('w:fldCharType'), 'end')
    run2._r.append(fld_char4)


# ─── Document setup ───────────────────────────────────────────────────────────
doc = Document()

# Margin halaman
for section in doc.sections:
    section.top_margin    = Cm(2.5)
    section.bottom_margin = Cm(2.5)
    section.left_margin   = Cm(3.0)
    section.right_margin  = Cm(2.5)

# Font default
style = doc.styles['Normal']
style.font.name = 'Calibri'
style.font.size = Pt(11)
style.font.color.rgb = COLOR_DARK_TEXT

# ─── Heading styles ───────────────────────────────────────────────────────────
for level, size, color, bold in [
    ('Heading 1', 16, COLOR_PRIMARY, True),
    ('Heading 2', 13, COLOR_PRIMARY, True),
    ('Heading 3', 11, COLOR_ACCENT,  True),
]:
    h = doc.styles[level]
    h.font.name  = 'Calibri'
    h.font.size  = Pt(size)
    h.font.bold  = bold
    h.font.color.rgb = color
    h.paragraph_format.space_before = Pt(14)
    h.paragraph_format.space_after  = Pt(6)

# ─── Helper: add_table ────────────────────────────────────────────────────────
def add_table(doc, headers: list[str], rows: list[list[str]], col_widths: list[float] | None = None):
    """Add a formatted table with colored header row."""
    n_cols = len(headers)
    table  = doc.add_table(rows=1 + len(rows), cols=n_cols)
    table.style = 'Table Grid'
    table.alignment = WD_TABLE_ALIGNMENT.LEFT

    # Header row
    hdr = table.rows[0]
    for i, text in enumerate(headers):
        cell = hdr.cells[i]
        shade_cell(cell, '1A376C')
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run = p.add_run(text)
        run.bold = True
        run.font.color.rgb = COLOR_WHITE
        run.font.size = Pt(10)
        cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER

    # Data rows
    for r_idx, row_data in enumerate(rows):
        row = table.rows[r_idx + 1]
        bg  = 'F0F4FF' if r_idx % 2 == 0 else 'FFFFFF'
        for c_idx, text in enumerate(row_data):
            cell = row.cells[c_idx]
            shade_cell(cell, bg)
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT
            run = p.add_run(str(text))
            run.font.size = Pt(10)
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER

    # Column widths (optional)
    if col_widths:
        for i, w in enumerate(col_widths):
            for row in table.rows:
                row.cells[i].width = Cm(w)

    doc.add_paragraph()  # spacing after table
    return table


# ═══════════════════════════════════════════════════════════════════════════════
#  HALAMAN SAMPUL
# ═══════════════════════════════════════════════════════════════════════════════
# Logo/header bar (simulasikan dengan tabel 1 baris berisi teks besar)
cover_tbl = doc.add_table(1, 1)
cover_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
cell = cover_tbl.cell(0, 0)
shade_cell(cell, '1A376C')
p = cell.paragraphs[0]
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
p.paragraph_format.space_before = Pt(12)
p.paragraph_format.space_after  = Pt(12)
r = p.add_run('PEMERINTAH KABUPATEN BANDUNG\nDINAS KEPEMUDAAN DAN OLAHRAGA (DISPORA)')
r.bold = True
r.font.color.rgb = COLOR_WHITE
r.font.size = Pt(13)
r.font.name = 'Calibri'

doc.add_paragraph()
doc.add_paragraph()

# Judul utama
title_p = doc.add_paragraph()
title_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = title_p.add_run('STANDAR OPERASIONAL PROSEDUR')
r.bold = True; r.font.size = Pt(22); r.font.color.rgb = COLOR_PRIMARY; r.font.name = 'Calibri'

sub_p = doc.add_paragraph()
sub_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = sub_p.add_run('SISTEM PEMESANAN LAPANGAN OLAHRAGA')
r.bold = True; r.font.size = Pt(18); r.font.color.rgb = COLOR_PRIMARY; r.font.name = 'Calibri'

app_p = doc.add_paragraph()
app_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = app_p.add_run('SIPELOR BEDAS')
r.bold = True; r.font.size = Pt(26); r.font.color.rgb = COLOR_ACCENT; r.font.name = 'Calibri'

doc.add_paragraph()

# Garis pemisah
hr = doc.add_paragraph('─' * 65)
hr.alignment = WD_ALIGN_PARAGRAPH.CENTER
hr.paragraph_format.space_before = Pt(0)
hr.paragraph_format.space_after  = Pt(0)

doc.add_paragraph()

# Info dokumen (tabel)
info_tbl = doc.add_table(6, 2)
info_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
info_data = [
    ('Nomor Dokumen',  'SOP-SIPELOR-2026-001'),
    ('Versi',          '1.0'),
    ('Tanggal Terbit', '3 Maret 2026'),
    ('Berlaku s.d.',   '3 Maret 2027'),
    ('Disusun oleh',   'Tim Pengembang SIPELOR BEDAS'),
    ('Disetujui oleh', 'Kepala DISPORA Kabupaten Bandung'),
]
for i, (label, val) in enumerate(info_data):
    c0 = info_tbl.cell(i, 0)
    c1 = info_tbl.cell(i, 1)
    shade_cell(c0, 'E8EDF8')
    shade_cell(c1, 'FFFFFF')
    p0 = c0.paragraphs[0]; p0.clear()
    r0 = p0.add_run(label); r0.bold = True; r0.font.size = Pt(11); r0.font.color.rgb = COLOR_PRIMARY
    p1 = c1.paragraphs[0]; p1.clear()
    r1 = p1.add_run(val); r1.font.size = Pt(11)
    c0.width = Cm(6); c1.width = Cm(9)

doc.add_paragraph()
doc.add_paragraph()

status_p = doc.add_paragraph()
status_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = status_p.add_run('STATUS: BERLAKU  |  SOR Jalak Harupat, Kabupaten Bandung')
r.bold = True; r.font.size = Pt(11); r.font.color.rgb = COLOR_ACCENT

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  HEADER & FOOTER
# ═══════════════════════════════════════════════════════════════════════════════
section = doc.sections[0]

# Header
header     = section.header
header_p   = header.paragraphs[0]
header_p.clear()
header_p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
hr = header_p.add_run('SOP SIPELOR BEDAS  |  DISPORA Kabupaten Bandung  |  SOP-SIPELOR-2026-001')
hr.font.size = Pt(9)
hr.font.color.rgb = COLOR_GRAY
hr.font.italic = True

# Footer
footer   = section.footer
footer_p = footer.paragraphs[0]
footer_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
add_page_number(footer_p)
run_copy = footer_p.add_run('  |  © 2026 DISPORA Kabupaten Bandung — Dokumen Internal')
run_copy.font.size = Pt(9)
run_copy.font.color.rgb = COLOR_GRAY

# ═══════════════════════════════════════════════════════════════════════════════
#  DAFTAR ISI (manual)
# ═══════════════════════════════════════════════════════════════════════════════
h = doc.add_heading('DAFTAR ISI', level=1)
h.alignment = WD_ALIGN_PARAGRAPH.CENTER

toc_items = [
    ('1',  'Tujuan & Ruang Lingkup'),
    ('2',  'Definisi & Istilah'),
    ('3',  'Peran & Tanggung Jawab'),
    ('4',  'SOP-01 — Registrasi & Verifikasi Akun'),
    ('5',  'SOP-02 — Login & Autentikasi'),
    ('6',  'SOP-03 — Pemesanan Lapangan (Booking)'),
    ('7',  'SOP-04 — Pembayaran & Konfirmasi'),
    ('8',  'SOP-05 — Pembatalan Booking'),
    ('9',  'SOP-06 — Verifikasi & Persetujuan Admin'),
    ('10', 'SOP-07 — Booking OPD / Pimpinan Dinas'),
    ('11', 'SOP-08 — Real-time Chat User–Admin'),
    ('12', 'SOP-09 — Ulasan & Penilaian Lapangan'),
    ('13', 'SOP-10 — Manajemen Lapangan (Admin)'),
    ('14', 'SOP-11 — Jadwal Pemeliharaan Lapangan'),
    ('15', 'SOP-12 — Manajemen Staff & Hak Akses'),
    ('16', 'SOP-13 — Penanganan Insiden Keamanan'),
    ('17', 'SOP-14 — Backup & Pemulihan Data'),
    ('18', 'SOP-15 — Pelaporan & Analitik'),
    ('19', 'SOP-16 — Penanganan Keluhan Pengguna'),
    ('20', 'SOP-17 — Deployment & Rilis Aplikasi'),
    ('21', 'Lampiran'),
]
for num, title in toc_items:
    p = doc.add_paragraph(style='Normal')
    p.paragraph_format.space_before = Pt(3)
    p.paragraph_format.space_after  = Pt(3)
    r = p.add_run(f'{num}.  {title}')
    r.font.size = Pt(11)

doc.add_page_break()


# ═══════════════════════════════════════════════════════════════════════════════
# HELPER: SOP header box
# ═══════════════════════════════════════════════════════════════════════════════
def add_sop_header(doc, nomor, judul, pelaksana, waktu, extra: dict | None = None):
    """Kotak metadata SOP di awal setiap sub-bab SOP."""
    meta = [
        ('Nomor SOP', nomor),
        ('Judul', judul),
        ('Pelaksana', pelaksana),
        ('Waktu', waktu),
    ]
    if extra:
        meta.extend(extra.items())

    tbl = doc.add_table(len(meta), 2)
    tbl.alignment = WD_TABLE_ALIGNMENT.LEFT
    for i, (k, v) in enumerate(meta):
        c0 = tbl.cell(i, 0); c1 = tbl.cell(i, 1)
        shade_cell(c0, 'E8EDF8')
        shade_cell(c1, 'FFFFFF')
        p0 = c0.paragraphs[0]; p0.clear()
        r0 = p0.add_run(k); r0.bold = True; r0.font.size = Pt(10); r0.font.color.rgb = COLOR_PRIMARY
        p1 = c1.paragraphs[0]; p1.clear()
        r1 = p1.add_run(v); r1.font.size = Pt(10)
        c0.width = Cm(4); c1.width = Cm(11)
    doc.add_paragraph()


# ═══════════════════════════════════════════════════════════════════════════════
#  BAB 1 — TUJUAN & RUANG LINGKUP
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('1.  Tujuan & Ruang Lingkup', level=1)

doc.add_heading('1.1  Tujuan', level=2)
tujuan = doc.add_paragraph(style='Normal')
tujuan.paragraph_format.space_after = Pt(4)
tujuan.add_run('Dokumen SOP ini bertujuan untuk:').bold = False
items_tujuan = [
    'Memberikan panduan baku operasional sistem SIPELOR BEDAS bagi seluruh pemangku kepentingan.',
    'Menjamin konsistensi, keamanan, dan kualitas layanan pemesanan lapangan olahraga SOR Jalak Harupat.',
    'Meminimalkan kesalahan operasional dan mempercepat penyelesaian masalah.',
    'Menjadi acuan pelatihan bagi staf baru DISPORA Kabupaten Bandung.',
]
for i, item in enumerate(items_tujuan, 1):
    p = doc.add_paragraph(style='List Number')
    p.add_run(item).font.size = Pt(11)

doc.add_heading('1.2  Ruang Lingkup', level=2)
add_table(doc,
    ['Cakupan', 'Keterangan'],
    [
        ['Pengguna',    'Masyarakat umum yang menggunakan aplikasi mobile SIPELOR BEDAS'],
        ['Admin',       'Admin, Manager, dan Operator DISPORA Kab. Bandung'],
        ['Super Admin', 'Pengelola teknis tertinggi sistem'],
        ['Platform',    'Aplikasi Android, iOS, Web, dan Windows'],
        ['Lokasi',      'SOR Jalak Harupat, Kabupaten Bandung'],
    ],
    col_widths=[4, 11]
)

doc.add_heading('1.3  Referensi', level=2)
refs = [
    'Peraturan Daerah tentang Pengelolaan Sarana Olahraga Kabupaten Bandung',
    'Kebijakan Keamanan Informasi DISPORA Kabupaten Bandung',
    'Terms of Service & Privacy Policy SIPELOR BEDAS v1.0',
]
for ref in refs:
    p = doc.add_paragraph(style='List Bullet')
    p.add_run(ref).font.size = Pt(11)

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  BAB 2 — DEFINISI & ISTILAH
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('2.  Definisi & Istilah', level=1)
add_table(doc,
    ['Istilah', 'Definisi'],
    [
        ['SIPELOR BEDAS', 'Sistem Pemesanan Lapangan Olahraga BEDAS — aplikasi digital resmi DISPORA Kab. Bandung'],
        ['SOR',           'Sarana Olahraga, merujuk pada SOR Jalak Harupat'],
        ['Booking',       'Pemesanan slot waktu penggunaan lapangan olahraga'],
        ['Slot',          'Satu satuan waktu penggunaan lapangan (misal: 08.00–10.00)'],
        ['E-Ticket',      'Tiket elektronik berformat PDF+QR Code sebagai bukti pemesanan'],
        ['OPD',           'Organisasi Perangkat Daerah — instansi pemerintah yang berhak booking via jalur khusus'],
        ['RASP',          'Runtime Application Self-Protection — lapisan keamanan otomatis di dalam aplikasi'],
        ['RLS',           'Row Level Security — keamanan akses data di level database'],
        ['RBAC',          'Role-Based Access Control — kontrol akses berdasarkan peran pengguna'],
        ['Supabase',      'Platform backend (database, autentikasi, penyimpanan) yang digunakan sistem'],
        ['QR Code',       'Kode dua dimensi pada e-ticket untuk verifikasi kehadiran di lapangan'],
        ['Rate Limiting', 'Pembatasan percobaan login maks. 3 kali sebelum akun dikunci 1 jam'],
        ['Auto-logout',   'Logout otomatis setelah 15 menit tidak aktif'],
        ['Pending',       'Status booking menunggu konfirmasi/pembayaran'],
        ['Confirmed',     'Status booking yang telah diverifikasi dan dikonfirmasi admin'],
        ['Cancelled',     'Status booking yang dibatalkan'],
        ['Completed',     'Status booking yang sudah selesai digunakan'],
        ['ID Booking',    'Format unik: SJH-YYYYMMDD-XXXX (misal: SJH-20260303-0001)'],
    ],
    col_widths=[4, 11]
)

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  BAB 3 — PERAN & TANGGUNG JAWAB
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('3.  Peran & Tanggung Jawab', level=1)

doc.add_heading('3.1  Hierarki Peran', level=2)
add_table(doc,
    ['Peran', 'Deskripsi Akses'],
    [
        ['Super Admin', 'Akses penuh sistem, konfigurasi, audit log, manajemen semua peran'],
        ['Admin',       'Kelola booking, verifikasi pembayaran, manajemen lapangan, laporan'],
        ['Manager',     'Analitik, laporan, pengaturan operasional, manajemen staff'],
        ['Operator',    'Verifikasi e-ticket, layanan chat, data entry'],
        ['User',        'Browse lapangan, booking, pembayaran, ulasan'],
    ],
    col_widths=[4, 11]
)

doc.add_heading('3.2  Matriks Tanggung Jawab (RACI)', level=2)
add_table(doc,
    ['Proses', 'User', 'Operator', 'Admin', 'Manager', 'Super Admin'],
    [
        ['Registrasi akun',             'R', '—', 'I',  '—', '—'],
        ['Booking lapangan',            'R', 'I', 'C',  '—', '—'],
        ['Upload bukti pembayaran',     'R', '—', '—',  '—', '—'],
        ['Verifikasi pembayaran',       '—', 'C', 'R',  'I', '—'],
        ['Konfirmasi booking',          '—', '—', 'R',  'I', '—'],
        ['Pembatalan booking',          'R/C','—', 'R', '—', '—'],
        ['Manajemen lapangan',          '—', '—', 'R',  'C', 'A'],
        ['Jadwal maintenance',          '—', 'C', 'R',  'A', '—'],
        ['Manajemen staff',             '—', '—', 'C',  'R', 'A'],
        ['Laporan & analitik',          '—', '—', 'C',  'R', 'A'],
        ['Insiden keamanan',            'I', 'I', 'C',  'C', 'R'],
        ['Deployment aplikasi',         '—', '—', '—',  'C', 'R'],
        ['Moderasi konten',             '—', 'C', 'R',  'A', '—'],
    ],
    col_widths=[5, 1.8, 1.8, 1.8, 1.8, 2.8]
)

note_p = doc.add_paragraph()
note_p.add_run('Keterangan: ').bold = True
note_p.add_run('R = Responsible (pelaksana)  •  A = Accountable (penanggung jawab)  •  C = Consulted  •  I = Informed')
note_p.runs[-1].italic = True
note_p.runs[-1].font.size = Pt(10)

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  SOP-01 — REGISTRASI & VERIFIKASI AKUN
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('4.  SOP-01 — Registrasi & Verifikasi Akun', level=1)
add_sop_header(doc, 'SOP-01', 'Registrasi dan Verifikasi Akun Pengguna', 'Pengguna (User)', '±5 menit')

doc.add_heading('4.1  Tujuan', level=2)
doc.add_paragraph('Memastikan setiap pengguna terdaftar secara sah dengan identitas yang terverifikasi melalui email.')

doc.add_heading('4.2  Prasyarat', level=2)
for p in ['Perangkat dengan koneksi internet aktif', 'Alamat email yang valid dan dapat diakses', 'Aplikasi SIPELOR BEDAS telah terinstall']:
    doc.add_paragraph(p, style='List Bullet').runs[0].font.size = Pt(11)

doc.add_heading('4.3  Langkah-langkah', level=2)
add_table(doc,
    ['#', 'Langkah', 'Pelaksana', 'Keterangan'],
    [
        ['1', 'Buka aplikasi SIPELOR BEDAS', 'User', 'Muncul layar onboarding (pertama kali)'],
        ['2', 'Tap "Daftar" / "Buat Akun"', 'User', '—'],
        ['3', 'Isi formulir: Nama Lengkap, Email, Password', 'User', 'Password min. 8 karakter, kombinasi huruf besar, kecil, angka, simbol'],
        ['4', 'Baca & centang persetujuan Terms of Service dan Privacy Policy', 'User', 'Wajib disetujui, tidak bisa lanjut jika belum dicentang'],
        ['5', 'Tap "Daftar"', 'User', 'Sistem kirim email verifikasi otomatis'],
        ['6', 'Buka email, klik link verifikasi', 'User', 'Link berlaku 24 jam'],
        ['7', 'Aplikasi redirect ke halaman sukses verifikasi', 'Sistem', 'Akun aktif, user dapat login'],
    ],
    col_widths=[0.8, 5.5, 3, 5.7]
)

doc.add_heading('4.4  Ketentuan Password', level=2)
add_table(doc,
    ['Ketentuan', 'Detail'],
    [
        ['Minimal 8 karakter', 'Wajib dipenuhi'],
        ['Minimal 1 huruf besar (A–Z)', 'Wajib dipenuhi'],
        ['Minimal 1 huruf kecil (a–z)', 'Wajib dipenuhi'],
        ['Minimal 1 angka (0–9)', 'Wajib dipenuhi'],
        ['Minimal 1 karakter khusus (!@#$%^&*)', 'Wajib dipenuhi'],
        ['Tidak boleh sama dengan email', 'Password akan ditolak sistem'],
        ['Tidak boleh password umum (password, 12345678)', 'Password akan ditolak sistem'],
    ],
    col_widths=[8, 7]
)

doc.add_heading('4.5  Penanganan Error', level=2)
add_table(doc,
    ['Kondisi Error', 'Pesan', 'Tindakan'],
    [
        ['Email sudah terdaftar', '"Email sudah digunakan"', 'Gunakan fitur "Lupa Password"'],
        ['Link verifikasi kadaluarsa', '"Link tidak valid"', 'Minta kirim ulang dari halaman login'],
        ['Password tidak memenuhi syarat', '"Password terlalu lemah"', 'Perkuat password sesuai ketentuan'],
        ['Koneksi internet mati', '"Gagal terhubung"', 'Periksa koneksi dan coba lagi'],
    ],
    col_widths=[5, 4, 6]
)

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  SOP-02 — LOGIN & AUTENTIKASI
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('5.  SOP-02 — Login & Autentikasi', level=1)
add_sop_header(doc, 'SOP-02', 'Login dan Autentikasi Pengguna', 'Semua peran', '±1 menit')

doc.add_heading('5.1  Metode Login', level=2)
add_table(doc,
    ['Metode', 'Status', 'Keterangan'],
    [
        ['Email + Password',          'Aktif',            'Metode utama'],
        ['Biometrik (Sidik Jari / Face ID)', 'Aktif',    'Setelah login pertama kali'],
        ['Google OAuth',              'Dalam Pengembangan','Belum diaktifkan untuk produksi'],
    ],
    col_widths=[5.5, 3.5, 6]
)

doc.add_heading('5.2  Langkah Login Email & Password', level=2)
add_table(doc,
    ['#', 'Langkah', 'Keterangan'],
    [
        ['1', 'Buka aplikasi → layar Login', '—'],
        ['2', 'Masukkan Email dan Password', '—'],
        ['3', 'Tap "Login"', 'Sistem memvalidasi kredensial'],
        ['4', 'Jika berhasil → redirect ke Home', 'Berdasarkan role: User → Home, Admin → Admin Panel'],
        ['5', 'Jika gagal 3 kali → akun dikunci 1 jam', 'Rate limiting aktif'],
    ],
    col_widths=[0.8, 5.5, 8.7]
)

doc.add_heading('5.3  Login dengan Biometrik', level=2)
add_table(doc,
    ['#', 'Langkah', 'Keterangan'],
    [
        ['1', 'Buka aplikasi — muncul prompt biometrik (jika sudah diaktifkan)', '—'],
        ['2', 'Autentikasi dengan sidik jari atau Face ID', '—'],
        ['3', 'Berhasil → langsung masuk tanpa input password', 'Sesi dipulihkan dari secure storage'],
    ],
    col_widths=[0.8, 7.5, 6.7]
)

doc.add_heading('5.4  Kebijakan Sesi', level=2)
add_table(doc,
    ['Kebijakan', 'Nilai'],
    [
        ['Auto-logout inactivity',              '15 menit'],
        ['Session timeout total',               '30 menit'],
        ['Percobaan login gagal maks.',          '3 kali'],
        ['Durasi lockout setelah maks. gagal',   '1 jam'],
    ],
    col_widths=[8, 7]
)

doc.add_heading('5.5  Reset Password', level=2)
add_table(doc,
    ['#', 'Langkah', 'Keterangan'],
    [
        ['1', 'Tap "Lupa Password" di halaman login', '—'],
        ['2', 'Masukkan email terdaftar', '—'],
        ['3', 'Sistem kirim link reset ke email', 'Link berlaku 1 jam'],
        ['4', 'Klik link → masukkan password baru', 'Harus memenuhi ketentuan password'],
        ['5', 'Login ulang dengan password baru', '—'],
    ],
    col_widths=[0.8, 7, 7.2]
)

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  SOP-03 — PEMESANAN LAPANGAN
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('6.  SOP-03 — Pemesanan Lapangan (Booking)', level=1)
add_sop_header(doc, 'SOP-03', 'Proses Pemesanan Lapangan Olahraga', 'User (Pengguna)', '±10 menit')

doc.add_heading('6.1  Tujuan', level=2)
doc.add_paragraph('Mengatur proses pemesanan lapangan secara tertib, transparan, dan bebas dari double-booking.')

doc.add_heading('6.2  Prasyarat', level=2)
for p in ['Akun terverifikasi dan status login aktif', 'Lapangan tersedia pada tanggal dan jam yang dipilih', 'Saldo/metode pembayaran tersedia']:
    doc.add_paragraph(p, style='List Bullet').runs[0].font.size = Pt(11)

doc.add_heading('6.3  Langkah Pemesanan', level=2)
add_table(doc,
    ['#', 'Langkah', 'Pelaksana', 'Keterangan'],
    [
        ['1', 'Dari Home, pilih kategori olahraga atau cari lapangan', 'User', 'Filter: jenis olahraga, tanggal, jam'],
        ['2', 'Pilih lapangan yang diinginkan', 'User', 'Lihat detail: foto, fasilitas, harga, ulasan'],
        ['3', 'Pilih tanggal booking', 'User', 'Kalender menampilkan hari yang tersedia'],
        ['4', 'Pilih slot waktu yang tersedia', 'User', 'Slot yang sudah dipesan ditampilkan abu-abu'],
        ['5', 'Periksa ringkasan booking: lapangan, tanggal, jam, harga', 'User', '—'],
        ['6', 'Pilih tipe booking: Umum / OPD / Pimpinan', 'User', 'OPD/Pimpinan memerlukan dokumen tambahan'],
        ['7', 'Tap "Pesan Sekarang"', 'User', 'Sistem cek ketersediaan via RPC (real-time lock)'],
        ['8', 'Jika slot masih tersedia → booking dibuat dengan status Pending', 'Sistem', 'ID Booking dibuat: SJH-YYYYMMDD-XXXX'],
        ['9', 'Pengguna diarahkan ke halaman Konfirmasi Pembayaran', 'Sistem', '—'],
    ],
    col_widths=[0.8, 5.5, 2.5, 6.2]
)

doc.add_heading('6.4  Status Booking', level=2)
add_table(doc,
    ['Status', 'Keterangan'],
    [
        ['Pending',   'Booking dibuat, menunggu pembayaran & verifikasi admin'],
        ['Confirmed', 'Admin sudah verifikasi pembayaran, booking aktif'],
        ['Completed', 'Sesi penggunaan lapangan selesai'],
        ['Cancelled', 'Booking dibatalkan oleh user atau admin'],
    ],
    col_widths=[3.5, 11.5]
)

doc.add_heading('6.5  Batas Waktu Pembayaran', level=2)
note = doc.add_paragraph()
note.paragraph_format.left_indent = Cm(0.5)
r = note.add_run('PERHATIAN: ')
r.bold = True; r.font.color.rgb = RGBColor(0xCC, 0x00, 0x00)
note.add_run('Booking yang tidak dibayar dalam 24 jam akan otomatis dibatalkan oleh sistem. Notifikasi pengingat dikirim ke pengguna 2 jam sebelum batas waktu.')

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  SOP-04 — PEMBAYARAN & KONFIRMASI
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('7.  SOP-04 — Pembayaran & Konfirmasi', level=1)
add_sop_header(doc, 'SOP-04', 'Proses Pembayaran dan Konfirmasi Booking', 'User & Admin', 'User ±5 menit  •  Admin ±10 menit')

doc.add_heading('7.1  Tujuan', level=2)
doc.add_paragraph('Memastikan proses pembayaran terdokumentasi dengan aman dan booking dikonfirmasi setelah verifikasi.')

doc.add_heading('7.2  Metode Pembayaran', level=2)
add_table(doc,
    ['Metode', 'Keterangan'],
    [
        ['Transfer Bank', 'Transfer ke rekening resmi DISPORA Kabupaten Bandung'],
        ['Upload Bukti',  'Foto/screenshot bukti transfer diunggah via aplikasi'],
    ],
    col_widths=[4, 11]
)

doc.add_heading('7.3  Langkah Pembayaran (User)', level=2)
add_table(doc,
    ['#', 'Langkah', 'Keterangan'],
    [
        ['1', 'Setelah booking dibuat, lihat detail pembayaran', 'Tampil nomor rekening, nominal, kode unik'],
        ['2', 'Lakukan transfer ke rekening yang tertera', 'Sertakan kode unik booking pada keterangan transfer'],
        ['3', 'Kembali ke aplikasi → tap "Upload Bukti Pembayaran"', '—'],
        ['4', 'Pilih foto bukti transfer dari galeri / kamera', 'Format: JPG, PNG, PDF — maks. 5 MB'],
        ['5', 'Tap "Kirim"', 'File dienkripsi AES-256 sebelum diunggah ke server'],
        ['6', 'Status booking berubah menjadi "Menunggu Verifikasi"', 'Notifikasi dikirim ke admin'],
    ],
    col_widths=[0.8, 6.5, 7.7]
)

doc.add_heading('7.4  Penerbitan E-Ticket', level=2)
add_table(doc,
    ['#', 'Langkah', 'Keterangan'],
    [
        ['1', 'Sistem otomatis generate e-ticket (PDF + QR Code)', '—'],
        ['2', 'Push notification dikirim ke user: "Booking dikonfirmasi!"', '—'],
        ['3', 'User buka menu "Riwayat Booking" → pilih booking', '—'],
        ['4', 'Tap "Lihat E-Ticket"', '—'],
        ['5', 'E-ticket dapat diunduh (PDF) atau dibagikan', '—'],
    ],
    col_widths=[0.8, 8, 6.2]
)

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  SOP-05 — PEMBATALAN BOOKING
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('8.  SOP-05 — Pembatalan Booking', level=1)
add_sop_header(doc, 'SOP-05', 'Prosedur Pembatalan Booking', 'User / Admin', '±5 menit')

doc.add_heading('8.1  Pembatalan oleh User', level=2)
add_table(doc,
    ['#', 'Langkah', 'Keterangan'],
    [
        ['1', 'Buka "Riwayat Booking"', '—'],
        ['2', 'Pilih booking yang ingin dibatalkan', 'Hanya booking berstatus Pending atau Confirmed yang bisa dibatalkan'],
        ['3', 'Tap "Batalkan Booking"', '—'],
        ['4', 'Konfirmasi pembatalan dengan tap "Ya, Batalkan"', '—'],
        ['5', 'Status booking berubah menjadi Cancelled', 'Notifikasi dikirim ke user dan admin'],
        ['6', 'Proses refund (jika berlaku) diproses secara manual oleh admin', '—'],
    ],
    col_widths=[0.8, 6.5, 7.7]
)

doc.add_heading('8.2  Pembatalan oleh Admin', level=2)
add_table(doc,
    ['#', 'Langkah', 'Keterangan'],
    [
        ['1', 'Buka Admin Panel (web) → menu Booking Management', '—'],
        ['2', 'Cari booking berdasarkan ID atau nama pemesan', '—'],
        ['3', 'Buka detail booking → tap "Batalkan"', '—'],
        ['4', 'Isi alasan pembatalan', 'Wajib diisi untuk keperluan audit'],
        ['5', 'Konfirmasi pembatalan', '—'],
        ['6', 'Sistem kirim notifikasi ke user dengan alasan pembatalan', '—'],
    ],
    col_widths=[0.8, 6.5, 7.7]
)

doc.add_heading('8.3  Kebijakan Pembatalan', level=2)
add_table(doc,
    ['Waktu Pembatalan', 'Ketentuan'],
    [
        ['> 24 jam sebelum jadwal', 'Dapat dibatalkan, refund diproses sesuai kebijakan'],
        ['< 24 jam sebelum jadwal', 'Pembatalan tetap bisa dilakukan, namun refund tidak dijamin'],
        ['Setelah jadwal selesai',  'Tidak dapat dibatalkan'],
    ],
    col_widths=[5, 10]
)

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  SOP-06 — VERIFIKASI & PERSETUJUAN ADMIN
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('9.  SOP-06 — Verifikasi & Persetujuan Admin', level=1)
add_sop_header(doc, 'SOP-06', 'Verifikasi Pembayaran dan Persetujuan Booking oleh Admin', 'Admin / Operator', '±10 menit per booking')

doc.add_heading('9.1  Langkah Verifikasi', level=2)
add_table(doc,
    ['#', 'Langkah', 'Pelaksana', 'Keterangan'],
    [
        ['1',  'Terima notifikasi: "Ada pembayaran baru menunggu verifikasi"', 'Admin', 'Via push notification / dashboard web'],
        ['2',  'Buka Admin Panel (web) → Booking Management', 'Admin', '—'],
        ['3',  'Filter booking berstatus "Menunggu Verifikasi"', 'Admin', '—'],
        ['4',  'Pilih booking → lihat detail dan bukti pembayaran', 'Admin', 'File diakses dari Supabase private storage'],
        ['5',  'Periksa kesesuaian: nama, nominal, nomor rekening tujuan, kode unik', 'Admin', 'Cocokkan dengan bukti mutasi rekening DISPORA'],
        ['6a', 'Jika valid → tap "Konfirmasi Pembayaran"', 'Admin', 'Status berubah ke Confirmed'],
        ['6b', 'Jika tidak valid → tap "Tolak" + isi alasan', 'Admin', 'Status tetap Pending, notifikasi ke user'],
        ['7',  'Sistem otomatis terbitkan e-ticket (jika dikonfirmasi)', 'Sistem', '—'],
        ['8',  'Notifikasi otomatis dikirim ke user', 'Sistem', '"Booking Anda telah dikonfirmasi"'],
    ],
    col_widths=[0.8, 5.5, 2.5, 6.2]
)

doc.add_heading('9.2  Checklist Verifikasi', level=2)
for item in [
    'Nama pemesan sesuai dengan nama di akun',
    'Nominal transfer sesuai dengan harga booking',
    'Rekening tujuan transfer adalah rekening resmi DISPORA',
    'Kode unik booking tertera pada keterangan transfer',
    'Tanggal transfer tidak melebihi batas waktu pembayaran',
    'Bukti pembayaran jelas, tidak blur, dan tidak terlihat diedit',
]:
    doc.add_paragraph(item, style='List Bullet').runs[0].font.size = Pt(11)

doc.add_heading('9.3  Target Waktu Verifikasi', level=2)
add_table(doc,
    ['Prioritas', 'Target'],
    [
        ['Booking hari yang sama',    'Maks. 2 jam setelah upload'],
        ['Booking hari berikutnya',   'Maks. 4 jam kerja'],
        ['Booking > 2 hari ke depan', 'Maks. 1 hari kerja'],
    ],
    col_widths=[6, 9]
)

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  SOP-07 — BOOKING OPD / PIMPINAN DINAS
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('10.  SOP-07 — Booking OPD / Pimpinan Dinas', level=1)
add_sop_header(doc, 'SOP-07', 'Pemesanan Lapangan untuk OPD dan Pimpinan Dinas', 'Staff OPD / Pimpinan / Admin', '±1–2 hari kerja')

doc.add_heading('10.1  Ketentuan Booking OPD/Pimpinan', level=2)
for p in [
    'Booking OPD diprioritaskan atas booking umum pada waktu yang sama.',
    'Dokumen surat tugas/undangan resmi wajib dilampirkan.',
    'Pembayaran menggunakan mekanisme keuangan daerah (invoice/SPJ).',
]:
    doc.add_paragraph(p, style='List Bullet').runs[0].font.size = Pt(11)

doc.add_heading('10.2  Langkah Booking OPD', level=2)
add_table(doc,
    ['#', 'Langkah', 'Pelaksana', 'Keterangan'],
    [
        ['1', 'Login dengan akun yang telah didaftarkan sebagai OPD', 'Staff OPD', 'Akun OPD harus diverifikasi terlebih dahulu oleh Admin'],
        ['2', 'Pilih lapangan → pilih tanggal dan slot', 'Staff OPD', '—'],
        ['3', 'Pada tipe booking, pilih "OPD" atau "Pimpinan"', 'Staff OPD', '—'],
        ['4', 'Isi nama instansi, nama kegiatan, nomor surat', 'Staff OPD', '—'],
        ['5', 'Upload surat tugas / undangan (PDF)', 'Staff OPD', '—'],
        ['6', 'Submit booking', 'Staff OPD', 'Status: Pending — menunggu verifikasi admin'],
        ['7', 'Admin verifikasi kelengkapan dokumen', 'Admin', 'Maks. 1 hari kerja'],
        ['8', 'Jika disetujui → booking Confirmed', 'Admin', 'Tidak memerlukan bukti transfer untuk OPD resmi'],
        ['9', 'E-ticket diterbitkan', 'Sistem', '—'],
    ],
    col_widths=[0.8, 5, 2.5, 6.7]
)

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  SOP-08 — REAL-TIME CHAT
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('11.  SOP-08 — Real-time Chat User–Admin', level=1)
add_sop_header(doc, 'SOP-08', 'Layanan Chat Real-time antara Pengguna dan Admin', 'User & Admin/Operator', 'Respons maks. 2 jam di jam kerja')

doc.add_heading('11.1  Ketentuan Chat', level=2)
add_table(doc,
    ['Ketentuan', 'Keterangan'],
    [
        ['Jam layanan',    'Senin–Jumat 08.00–16.00 WIB'],
        ['Target respons', 'Maks. 2 jam di jam kerja'],
        ['Retensi pesan',  'Pesan otomatis dihapus setelah 24 jam (menjaga privasi & storage)'],
        ['Bahasa',         'Indonesia'],
    ],
    col_widths=[4, 11]
)

doc.add_heading('11.2  Langkah Memulai Chat (User)', level=2)
add_table(doc,
    ['#', 'Langkah', 'Keterangan'],
    [
        ['1', 'Buka aplikasi → tap ikon "Chat" di bottom navigation', '—'],
        ['2', 'Tap "Mulai Chat Baru" atau pilih percakapan yang ada', '—'],
        ['3', 'Ketik pesan dan tap "Kirim"', '—'],
        ['4', 'Tunggu balasan dari admin', 'Notifikasi push saat ada balasan'],
    ],
    col_widths=[0.8, 7, 7.2]
)

doc.add_heading('11.3  Panduan Admin Merespons Chat', level=2)
add_table(doc,
    ['#', 'Langkah', 'Keterangan'],
    [
        ['1', 'Terima notifikasi chat masuk', '—'],
        ['2', 'Buka Admin Chat List di aplikasi Flutter atau web admin panel', '—'],
        ['3', 'Pilih percakapan pengguna', 'Tampil nama user, waktu pesan, preview pesan'],
        ['4', 'Ketik dan kirim balasan', '—'],
        ['5', 'Tandai percakapan sebagai Selesai jika masalah terselesaikan', '—'],
    ],
    col_widths=[0.8, 7.5, 6.7]
)

doc.add_heading('11.4  Konten yang Dilarang di Chat', level=2)
for p in [
    'Informasi pribadi yang tidak relevan (nomor KTP, dll.)',
    'Bahasa kasar atau tidak sopan',
    'Link mencurigakan atau phishing',
    'Pertanyaan/topik di luar layanan SIPELOR BEDAS',
]:
    doc.add_paragraph(p, style='List Bullet').runs[0].font.size = Pt(11)

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  SOP-09 — ULASAN & PENILAIAN
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('12.  SOP-09 — Ulasan & Penilaian Lapangan', level=1)
add_sop_header(doc, 'SOP-09', 'Pemberian Ulasan dan Penilaian Lapangan oleh Pengguna', 'User', '±3 menit')

doc.add_heading('12.1  Syarat Memberikan Ulasan', level=2)
note = doc.add_paragraph()
r = note.add_run('Hanya pengguna yang memiliki booking berstatus COMPLETED yang dapat memberikan ulasan.')
r.bold = True; r.font.color.rgb = COLOR_ACCENT

doc.add_heading('12.2  Langkah Memberikan Ulasan', level=2)
add_table(doc,
    ['#', 'Langkah', 'Keterangan'],
    [
        ['1', 'Buka "Riwayat Booking"', '—'],
        ['2', 'Pilih booking berstatus Completed', '—'],
        ['3', 'Tap "Beri Ulasan"', '—'],
        ['4', 'Beri bintang (1–5)', '—'],
        ['5', 'Tulis komentar (opsional)', 'Maks. 500 karakter'],
        ['6', 'Tap "Kirim Ulasan"', '—'],
    ],
    col_widths=[0.8, 6.5, 7.7]
)

doc.add_heading('12.3  Moderasi Ulasan', level=2)
doc.add_paragraph('Ulasan ditampilkan secara publik di halaman detail lapangan. Admin dapat menghapus ulasan yang:')
for p in ['Mengandung konten tidak pantas (SARA, kata kasar, dll.)', 'Tidak relevan dengan layanan', 'Terindikasi spam atau palsu']:
    doc.add_paragraph(p, style='List Bullet').runs[0].font.size = Pt(11)

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  SOP-10 — MANAJEMEN LAPANGAN
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('13.  SOP-10 — Manajemen Lapangan (Admin)', level=1)
add_sop_header(doc, 'SOP-10', 'Pengelolaan Data Lapangan Olahraga', 'Admin', '±15 menit per lapangan')

doc.add_heading('13.1  Langkah Menambah Lapangan Baru', level=2)
add_table(doc,
    ['#', 'Langkah', 'Keterangan'],
    [
        ['1', 'Buka Admin Panel Web → menu Manajemen Lapangan', '—'],
        ['2', 'Tap "Tambah Lapangan"', '—'],
        ['3', 'Isi data: Nama, Venue, Jenis Olahraga, Kapasitas, Harga/Jam', '—'],
        ['4', 'Upload foto lapangan (min. 3 foto, maks. 10 foto)', 'Format: JPG/PNG, maks. 5 MB per foto'],
        ['5', 'Atur status: Aktif / Nonaktif / Maintenance', '—'],
        ['6', 'Atur jam operasional dan hari buka', '—'],
        ['7', 'Simpan', 'Data langsung tampil di aplikasi pengguna'],
    ],
    col_widths=[0.8, 6.5, 7.7]
)

doc.add_heading('13.2  Status Lapangan', level=2)
add_table(doc,
    ['Status', 'Keterangan', 'Dampak di Aplikasi'],
    [
        ['Aktif',       'Lapangan beroperasi normal',        'Dapat di-booking oleh user'],
        ['Nonaktif',    'Lapangan tidak beroperasi',         'Tidak tampil di daftar booking'],
        ['Maintenance', 'Sedang dalam perawatan',            'Tampil dengan label "Sedang dalam Perawatan"'],
    ],
    col_widths=[3, 5.5, 6.5]
)

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  SOP-11 — JADWAL PEMELIHARAAN
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('14.  SOP-11 — Jadwal Pemeliharaan Lapangan', level=1)
add_sop_header(doc, 'SOP-11', 'Penjadwalan dan Pelaksanaan Pemeliharaan Lapangan', 'Admin / Operator', 'Perencanaan ±15 menit')

doc.add_heading('14.1  Langkah Penjadwalan Maintenance', level=2)
add_table(doc,
    ['#', 'Langkah', 'Keterangan'],
    [
        ['1', 'Buka Admin Panel → Jadwal Maintenance', '—'],
        ['2', 'Pilih lapangan yang akan dirawat', '—'],
        ['3', 'Tentukan tanggal dan jam maintenance', 'Sistem cek apakah ada booking aktif pada waktu tersebut'],
        ['4', 'Jika ada booking → sistem beri peringatan', 'Admin harus batalkan booking dan notifikasi user'],
        ['5', 'Isi deskripsi pekerjaan maintenance', '—'],
        ['6', 'Simpan jadwal', 'Slot otomatis diblokir, tidak dapat di-booking'],
        ['7', 'Status lapangan otomatis berubah ke Maintenance pada waktu dijadwalkan', '—'],
        ['8', 'Setelah selesai → ubah status kembali ke Aktif', '—'],
    ],
    col_widths=[0.8, 6.5, 7.7]
)

doc.add_heading('14.2  Jenis Pemeliharaan', level=2)
add_table(doc,
    ['Jenis', 'Frekuensi', 'Keterangan'],
    [
        ['Rutin harian', 'Setiap hari',   'Kebersihan, pengecekan fasilitas'],
        ['Mingguan',     'Setiap minggu', 'Perawatan rumput, net, garis lapangan'],
        ['Bulanan',      'Setiap bulan',  'Pengecatan, perbaikan minor'],
        ['Insidental',   'Sesuai kebutuhan', 'Kerusakan mendadak, bencana, dll.'],
    ],
    col_widths=[3.5, 3.5, 8]
)

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  SOP-12 — MANAJEMEN STAFF & HAK AKSES
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('15.  SOP-12 — Manajemen Staff & Hak Akses', level=1)
add_sop_header(doc, 'SOP-12', 'Pengelolaan Akun Staff dan Hak Akses Sistem', 'Manager / Super Admin', '±10 menit per staff')

doc.add_heading('15.1  Langkah Menambah Staff Baru', level=2)
add_table(doc,
    ['#', 'Langkah', 'Keterangan'],
    [
        ['1', 'Buka Admin Panel Web → Manajemen Staff', 'Hanya Manager/Super Admin'],
        ['2', 'Tap "Tambah Staff"', '—'],
        ['3', 'Isi: Nama, Email, Jabatan, Nomor HP', '—'],
        ['4', 'Pilih peran: Admin / Manager / Operator', '—'],
        ['5', 'Sistem kirim email undangan ke staff', 'Berisi link untuk aktivasi akun'],
        ['6', 'Staff aktivasi akun dan set password', '—'],
    ],
    col_widths=[0.8, 6.5, 7.7]
)

doc.add_heading('15.2  Matriks Hak Akses Detail', level=2)
add_table(doc,
    ['Fitur', 'Operator', 'Admin', 'Manager', 'Super Admin'],
    [
        ['Lihat daftar booking',          'Ya', 'Ya', 'Ya', 'Ya'],
        ['Verifikasi pembayaran',          'Tidak', 'Ya', 'Ya', 'Ya'],
        ['Konfirmasi/tolak booking',       'Tidak', 'Ya', 'Ya', 'Ya'],
        ['Kelola lapangan (CRUD)',         'Tidak', 'Ya', 'Ya', 'Ya'],
        ['Jadwal maintenance',             'Ya', 'Ya', 'Ya', 'Ya'],
        ['Kelola staff',                   'Tidak', 'Tidak', 'Ya', 'Ya'],
        ['Lihat analytics & laporan',      'Tidak', 'Ya', 'Ya', 'Ya'],
        ['Export laporan',                 'Tidak', 'Ya', 'Ya', 'Ya'],
        ['Moderasi ulasan',                'Ya', 'Ya', 'Ya', 'Ya'],
        ['Kelola banner/promo',            'Tidak', 'Ya', 'Ya', 'Ya'],
        ['Lihat audit log',                'Tidak', 'Ya', 'Ya', 'Ya'],
        ['Konfigurasi sistem',             'Tidak', 'Tidak', 'Tidak', 'Ya'],
        ['Debug menu',                     'Tidak', 'Tidak', 'Tidak', 'Ya'],
    ],
    col_widths=[5.5, 2.5, 2, 2.5, 2.5]
)

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  SOP-13 — PENANGANAN INSIDEN KEAMANAN
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('16.  SOP-13 — Penanganan Insiden Keamanan', level=1)
add_sop_header(doc, 'SOP-13', 'Prosedur Respons terhadap Insiden Keamanan Sistem', 'Super Admin / Tim Teknis', '—',
               {'Prioritas': 'KRITIS'})

doc.add_heading('16.1  Klasifikasi Insiden', level=2)
add_table(doc,
    ['Level', 'Deskripsi', 'Contoh', 'Respons Maks.'],
    [
        ['KRITIS', 'Kompromi data, pelanggaran akses besar', 'Kebocoran data user, akses ilegal DB', '1 jam'],
        ['TINGGI', 'Gangguan layanan signifikan', 'Sistem tidak bisa diakses, serangan DDoS', '4 jam'],
        ['SEDANG', 'Anomali keamanan', 'Login mencurigakan berulang, abuse rate limit', '24 jam'],
        ['RENDAH', 'Potensi risiko minor', 'Vulnerability kecil, peringatan konfigurasi', '72 jam'],
    ],
    col_widths=[2, 4, 6, 3]
)

doc.add_heading('16.2  Langkah Respons Insiden Kritis', level=2)
add_table(doc,
    ['#', 'Langkah', 'Pelaksana', 'Target Waktu'],
    [
        ['1',  'Terima alert dari Sentry / sistem monitoring',             'Super Admin', 'T+0'],
        ['2',  'Identifikasi scope dan dampak insiden',                    'Tim Teknis',  'T+15 menit'],
        ['3',  'Isolasi sistem yang terdampak (jika perlu)',               'Super Admin', 'T+30 menit'],
        ['4',  'Laporkan ke Kepala DISPORA',                              'Super Admin', 'T+30 menit'],
        ['5',  'Investigasi akar masalah (root cause)',                    'Tim Teknis',  'T+1 jam'],
        ['6',  'Implementasi mitigasi darurat',                            'Tim Teknis',  'T+2 jam'],
        ['7',  'Notifikasi pengguna yang terdampak (jika perlu)',          'Admin',       'T+2 jam'],
        ['8',  'Implementasi perbaikan permanen',                          'Tim Teknis',  'T+24 jam'],
        ['9',  'Buat laporan insiden lengkap',                             'Super Admin', 'T+48 jam'],
        ['10', 'Review dan perbaikan prosedur',                            'Tim',         'T+7 hari'],
    ],
    col_widths=[0.8, 6.5, 3, 3.7]
)

doc.add_heading('16.3  Trigger Otomatis Keamanan', level=2)
for p in [
    'Memblokir akun setelah 3 kali login gagal (1 jam)',
    'Alert via Sentry jika ada exception tidak normal',
    'RASP menghentikan aplikasi jika deteksi root/jailbreak di production',
    'SSL pinning memblokir koneksi jika sertifikat tidak cocok',
    'Audit log mencatat semua aksi admin secara otomatis',
]:
    doc.add_paragraph(p, style='List Bullet').runs[0].font.size = Pt(11)

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  SOP-14 — BACKUP & PEMULIHAN DATA
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('17.  SOP-14 — Backup & Pemulihan Data', level=1)
add_sop_header(doc, 'SOP-14', 'Prosedur Backup dan Pemulihan Data Sistem', 'Super Admin / Tim Teknis', 'Backup otomatis harian')

doc.add_heading('17.1  Kebijakan Backup', level=2)
add_table(doc,
    ['Jenis', 'Frekuensi', 'Retensi', 'Penyimpanan'],
    [
        ['Database PostgreSQL',     'Otomatis oleh Supabase',          '30 hari',   'Supabase Cloud'],
        ['Storage Bucket',          'Otomatis oleh Supabase',          '30 hari',   'Supabase Cloud'],
        ['Konfigurasi Aplikasi',    'Manual setiap rilis',             'Indefinite','Git Repository'],
        ['Audit Logs',              'Otomatis',                        '90 hari',   'Database'],
    ],
    col_widths=[4, 4, 2.5, 4.5]
)

doc.add_heading('17.2  Prosedur Point-in-Time Recovery (PITR)', level=2)
add_table(doc,
    ['#', 'Langkah', 'Keterangan'],
    [
        ['1', 'Login ke dashboard Supabase', '—'],
        ['2', 'Pilih project SIPELOR BEDAS', '—'],
        ['3', 'Settings → Database → Backups', '—'],
        ['4', 'Pilih titik waktu yang ingin dipulihkan', '—'],
        ['5', 'Konfirmasi restore', 'Proses berlangsung 10–30 menit'],
        ['6', 'Verifikasi integritas data setelah restore', 'Cek jumlah record, status booking, dll.'],
        ['7', 'Aktifkan kembali layanan', '—'],
    ],
    col_widths=[0.8, 6.5, 7.7]
)

note = doc.add_paragraph()
r = note.add_run('PERHATIAN: ')
r.bold = True; r.font.color.rgb = RGBColor(0xCC, 0x00, 0x00)
note.add_run('Restore database akan menimpa data saat ini. Pastikan backup terbaru aman sebelum restore.')

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  SOP-15 — PELAPORAN & ANALITIK
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('18.  SOP-15 — Pelaporan & Analitik', level=1)
add_sop_header(doc, 'SOP-15', 'Pelaporan Data dan Analitik Operasional', 'Manager / Admin', 'Harian / Mingguan / Bulanan')

doc.add_heading('18.1  Jenis Laporan', level=2)
add_table(doc,
    ['Laporan', 'Frekuensi', 'Isi', 'Penerima'],
    [
        ['Laporan Harian',   'Setiap hari (otomatis)',     'Total booking, pendapatan, booking baru',      'Admin, Manager'],
        ['Laporan Mingguan', 'Setiap Senin (otomatis)',    'Tren mingguan, lapangan tersibuk, user aktif', 'Manager'],
        ['Laporan Bulanan',  'Setiap tgl 1 (otomatis)',   'Analisis bulanan, komparasi, proyeksi',         'Manager, Kepala DISPORA'],
        ['Laporan Ad-hoc',   'Sesuai kebutuhan',           'Custom berdasarkan filter',                    'Admin, Manager'],
    ],
    col_widths=[3, 3.5, 5.5, 3]
)

doc.add_heading('18.2  Metrik Utama yang Dipantau', level=2)
for p in [
    'Total booking (per hari/minggu/bulan)',
    'Total pendapatan (per periode)',
    'Lapangan tersibuk / teramai',
    'Jumlah user aktif baru vs. returning',
    'Tingkat konversi (browse → booking → bayar)',
    'Rata-rata rating lapangan',
    'Tingkat pembatalan booking',
    'Volume chat dan rata-rata waktu respons',
]:
    doc.add_paragraph(p, style='List Bullet').runs[0].font.size = Pt(11)

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  SOP-16 — PENANGANAN KELUHAN
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('19.  SOP-16 — Penanganan Keluhan Pengguna', level=1)
add_sop_header(doc, 'SOP-16', 'Prosedur Penanganan Keluhan dan Pengaduan Pengguna', 'Operator / Admin', 'Selesai dalam 1 hari kerja')

doc.add_heading('19.1  Saluran Keluhan', level=2)
add_table(doc,
    ['Saluran', 'Cara', 'Waktu Respons'],
    [
        ['In-App Chat', 'Fitur chat di aplikasi', 'Maks. 2 jam (jam kerja)'],
        ['Email',       'Email resmi DISPORA',    'Maks. 1 hari kerja'],
        ['Langsung',    'Datang ke kantor DISPORA','Segera'],
    ],
    col_widths=[3.5, 6, 5.5]
)

doc.add_heading('19.2  Langkah Penanganan Keluhan', level=2)
add_table(doc,
    ['#', 'Langkah', 'Pelaksana', 'Keterangan'],
    [
        ['1',  'Terima keluhan dari user via chat/email',       'Operator', 'Catat: nama, ID booking, deskripsi masalah'],
        ['2',  'Konfirmasi penerimaan keluhan kepada user',     'Operator', 'Berikan estimasi waktu penyelesaian'],
        ['3',  'Investigasi masalah',                           'Operator/Admin', 'Cek data booking, log sistem, bukti'],
        ['4',  'Identifikasi solusi',                           'Admin', '—'],
        ['5a', 'Jika dapat diselesaikan → laksanakan solusi',   'Admin', '—'],
        ['5b', 'Jika perlu eskalasi → teruskan ke Manager/Super Admin', 'Admin', '—'],
        ['6',  'Informasikan solusi kepada user',               'Operator', '—'],
        ['7',  'Dokumentasikan keluhan dan resolusi',           'Admin', 'Untuk perbaikan ke depan'],
    ],
    col_widths=[0.8, 5.5, 2.5, 6.2]
)

doc.add_heading('19.3  Jenis Keluhan Umum & Solusi', level=2)
add_table(doc,
    ['Keluhan', 'Solusi Cepat'],
    [
        ['Tidak bisa login',                     'Cek status akun, reset password, cek rate limit'],
        ['Pembayaran tidak dikonfirmasi',         'Verifikasi manual oleh admin, cek bukti ulang'],
        ['E-ticket tidak muncul',                'Cek status booking, generate ulang e-ticket'],
        ['Slot yang dipesan tidak tersedia',      'Investigasi double-booking, kompensasi jika terbukti kesalahan sistem'],
        ['Aplikasi error/crash',                  'Minta screenshot error, laporkan ke tim teknis via Sentry'],
        ['Data profil tidak tersimpan',           'Cek koneksi internet, coba lagi, eskalasi ke teknis jika berulang'],
    ],
    col_widths=[5.5, 9.5]
)

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  SOP-17 — DEPLOYMENT & RILIS
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('20.  SOP-17 — Deployment & Rilis Aplikasi', level=1)
add_sop_header(doc, 'SOP-17', 'Prosedur Deployment dan Rilis Versi Aplikasi Baru', 'Super Admin / Tim Developer', '±2–4 jam')

doc.add_heading('20.1  Checklist Pre-Deployment', level=2)
for p in [
    'Semua fitur baru telah melewati unit testing (target coverage 70%+)',
    'flutter analyze — tidak ada error di folder lib/',
    'Manual testing checklist selesai (400+ test cases)',
    'Security audit checklist selesai',
    'Versi pubspec.yaml diperbarui',
    'CHANGELOG diperbarui',
    'Dokumen SOP/PROBIS diperbarui jika ada perubahan proses',
    'Supabase RLS policy diverifikasi',
    'Sentry DSN dikonfigurasi untuk lingkungan produksi',
    'SSL certificate pins diperbarui (jika perlu)',
    'Tanda tangan APK/IPA menggunakan keystore resmi',
]:
    doc.add_paragraph(p, style='List Bullet').runs[0].font.size = Pt(11)

doc.add_heading('20.2  Langkah Build & Release (Android APK)', level=2)
add_table(doc,
    ['#', 'Perintah / Langkah', 'Keterangan'],
    [
        ['1', 'flutter clean',  'Bersihkan build cache'],
        ['2', 'flutter pub get','Update dependencies'],
        ['3', 'flutter analyze','Pastikan 0 error'],
        ['4', 'flutter test',   'Jalankan semua unit test'],
        ['5', 'flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...', 'Build APK produksi'],
        ['6', 'Test APK di perangkat fisik Android', 'Minimal 2 perangkat berbeda'],
        ['7', 'Upload ke Google Play / distribusi internal', '—'],
    ],
    col_widths=[0.8, 8, 6.2]
)

doc.add_heading('20.3  Rollback Plan', level=2)
add_table(doc,
    ['#', 'Langkah', 'Target Waktu'],
    [
        ['1', 'Identifikasi masalah dan dampak',                    'T+0'],
        ['2', 'Keputusan rollback oleh Super Admin',                'T+15 menit'],
        ['3', 'Publikasikan kembali versi sebelumnya',              'T+30 menit'],
        ['4', 'Notifikasi pengguna via push notification',          'T+30 menit'],
        ['5', 'Investigasi dan perbaikan',                          'T+24 jam'],
    ],
    col_widths=[0.8, 8.5, 3.7]
)

doc.add_page_break()

# ═══════════════════════════════════════════════════════════════════════════════
#  LAMPIRAN
# ═══════════════════════════════════════════════════════════════════════════════
doc.add_heading('21.  Lampiran', level=1)

doc.add_heading('Lampiran A — Kode Status Booking', level=2)
add_table(doc,
    ['Kode', 'Status', 'Keterangan'],
    [
        ['pending',   'Menunggu',    'Booking dibuat, menunggu pembayaran'],
        ['confirmed', 'Dikonfirmasi','Pembayaran diverifikasi, booking aktif'],
        ['completed', 'Selesai',     'Sesi penggunaan lapangan selesai'],
        ['cancelled', 'Dibatalkan',  'Booking dibatalkan'],
    ],
    col_widths=[3, 3.5, 8.5]
)

doc.add_heading('Lampiran B — Format ID Booking', level=2)
p = doc.add_paragraph()
p.add_run('Format: ').bold = True
p.add_run('SJH - YYYYMMDD - XXXX')
p2 = doc.add_paragraph()
p2.add_run('Contoh: SJH-20260303-0001\n'
           '  SJH  = Kode venue Jalak Harupat\n'
           '  20260303 = Tanggal booking (3 Maret 2026)\n'
           '  0001 = Nomor urut 4 digit')
p2.runs[0].font.name = 'Courier New'
p2.runs[0].font.size = Pt(10)

doc.add_heading('Lampiran C — Jam Operasional Layanan', level=2)
add_table(doc,
    ['Layanan', 'Jam', 'Hari'],
    [
        ['Pemesanan lapangan',     '06.00 – 22.00 WIB', 'Setiap hari'],
        ['Customer service (chat)','08.00 – 16.00 WIB', 'Senin – Jumat'],
        ['Verifikasi pembayaran',  '08.00 – 16.00 WIB', 'Senin – Jumat'],
        ['Lapangan (operasional)', '06.00 – 22.00 WIB', 'Setiap hari'],
    ],
    col_widths=[5, 4, 6]
)

doc.add_heading('Lampiran D — Dokumen Terkait', level=2)
add_table(doc,
    ['Dokumen', 'Lokasi'],
    [
        ['PROBIS SIPELOR BEDAS',              'docs/PROBIS_SIPELOR_BEDAS.md'],
        ['Manual Testing Checklist',          'docs/MANUAL_TESTING_CHECKLIST.md'],
        ['Security Audit Checklist',          'docs/SECURITY_AUDIT_CHECKLIST.md'],
        ['User Manual',                       'docs/USER_MANUAL.md'],
        ['Troubleshooting Guide',             'docs/TROUBLESHOOTING.md'],
        ['Analisis Project Komprehensif',     'docs/ANALISIS_PROJECT_KOMPREHENSIF_2026-03-03.md'],
    ],
    col_widths=[6, 9]
)

doc.add_paragraph()
doc.add_paragraph()

# ─── Footer dokumen ───────────────────────────────────────────────────────────
closing_tbl = doc.add_table(1, 1)
closing_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
cell = closing_tbl.cell(0, 0)
shade_cell(cell, '1A376C')
p = cell.paragraphs[0]
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
p.paragraph_format.space_before = Pt(10)
p.paragraph_format.space_after  = Pt(10)
r = p.add_run(
    'SOP-SIPELOR-2026-001  •  Versi 1.0  •  3 Maret 2026  •  Berlaku s.d. 3 Maret 2027\n'
    '© 2026 DISPORA Kabupaten Bandung — Dokumen Internal\n'
    'Dilarang memperbanyak atau menyebarluaskan tanpa izin tertulis.'
)
r.font.color.rgb = COLOR_WHITE
r.font.size = Pt(10)
r.font.name = 'Calibri'

# ─── Simpan ───────────────────────────────────────────────────────────────────
output_path = 'docs/SOP_SIPELOR_BEDAS.docx'
doc.save(output_path)
print(f'✅ File berhasil dibuat: {output_path}')
