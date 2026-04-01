// =============================================
// SIPELOR BEDAS — Booking Handler
// Bug fix: goToStep tidak lagi di-override dari luar
// =============================================

const bookingState = {
  step: 1,
  sportType: null,
  field: null,
  date: null,
  startTime: null,
  duration: 1,
  endTime: null,
  totalAmount: 0,
  user: null,
};

const SPORT_TYPES = [
  { id: 'futsal',     name: 'Futsal',     icon: '⚽', color: '#FF5800', types: ['futsal'] },
  { id: 'badminton',  name: 'Badminton',  icon: '🏸', color: '#468FEA', types: ['badminton'] },
  { id: 'basketball', name: 'Basketball', icon: '🏀', color: '#F59E0B', types: ['basketball'] },
  { id: 'volleyball', name: 'Voli',       icon: '🏐', color: '#22C55E', types: ['voli', 'volleyball'] },
];

const TIME_SLOTS = [
  '06:00','07:00','08:00','09:00','10:00','11:00',
  '12:00','13:00','14:00','15:00','16:00','17:00',
  '18:00','19:00','20:00','21:00',
];

const MOCK_BOOKED_MAP = {
  'field-001': ['09:00','10:00'],
  'field-002': ['13:00','14:00','15:00'],
  'field-003': ['18:00','19:00','20:00'],
  'field-004': ['07:00','08:00'],
  'field-005': ['16:00','17:00'],
  'field-006': ['10:00','11:00'],
  'field-007': [],
  'field-008': ['19:00','20:00'],
  'field-009': ['08:00'],
  'field-010': ['14:00','15:00'],
};

const MOCK_FIELDS = [
  // FUTSAL
  { id:'field-001', venueName:'Lapangan Futsal A',     venueType:'Futsal',     area:'Zona A', pricePerHour:150000, status:'available', rating:4.8, totalReviews:124, imageUrl:'https://images.pexels.com/photos/16378314/pexels-photo-16378314.jpeg?auto=compress&cs=tinysrgb&w=400', city:'Sumedang', address:'Jl. Prabu Gajah Agung No. 3', fasilitas:['🔒 CCTV','🚗 Parkir','🚿 Ruang Ganti','📶 WiFi'], kapasitas:'10 orang', ukuran:'16.8m × 24.95m' },
  { id:'field-005', venueName:'Lapangan Futsal B',     venueType:'Futsal',     area:'Zona B', pricePerHour:120000, status:'available', rating:4.5, totalReviews:98,  imageUrl:'https://images.pexels.com/photos/16378313/pexels-photo-16378313.jpeg?auto=compress&cs=tinysrgb&w=400', city:'Sumedang', address:'Jl. Suryakancana No. 8',        fasilitas:['🔒 CCTV','🚗 Parkir','📶 WiFi'],          kapasitas:'10 orang', ukuran:'16m × 24m' },
  { id:'field-007', venueName:'Lapangan Futsal C',     venueType:'Futsal',     area:'Zona C', pricePerHour:160000, status:'available', rating:4.7, totalReviews:44,  imageUrl:'https://images.unsplash.com/photo-1552741775-7817c0c85843?crop=entropy&cs=srgb&fm=jpg&ixlib=rb-4.1.0&q=85&w=400', city:'Sumedang', address:'Jl. Ibrahim Adjie No. 5',       fasilitas:['🔒 CCTV','🕌 Mushola','🚗 Parkir','🪑 Tribun'], kapasitas:'12 orang', ukuran:'17m × 25m' },
  // BADMINTON
  { id:'field-002', venueName:'Lapangan Badminton B',  venueType:'Badminton',  area:'Zona B', pricePerHour:80000,  status:'available', rating:4.6, totalReviews:89,  imageUrl:'https://images.pexels.com/photos/26238653/pexels-photo-26238653.jpeg?auto=compress&cs=tinysrgb&w=400', city:'Sumedang', address:'Jl. Mayor Abdurakhman No. 12',  fasilitas:['🔒 CCTV','🚗 Parkir','🕌 Mushola'],       kapasitas:'4 orang',  ukuran:'6.1m × 13.4m' },
  { id:'field-006', venueName:'Lapangan Badminton C',  venueType:'Badminton',  area:'Zona C', pricePerHour:75000,  status:'available', rating:4.5, totalReviews:61,  imageUrl:'https://images.pexels.com/photos/26238671/pexels-photo-26238671.jpeg?auto=compress&cs=tinysrgb&w=400', city:'Sumedang', address:'Jl. Siliwangi No. 17',            fasilitas:['🔒 CCTV','🚗 Parkir','🚿 Ruang Ganti'],   kapasitas:'4 orang',  ukuran:'6.1m × 13.4m' },
  { id:'field-009', venueName:'Lapangan Badminton E',  venueType:'Badminton',  area:'Zona E', pricePerHour:90000,  status:'available', rating:4.4, totalReviews:52,  imageUrl:'https://images.pexels.com/photos/8007500/pexels-photo-8007500.jpeg?auto=compress&cs=tinysrgb&w=400',  city:'Sumedang', address:'Jl. Otista No. 33',               fasilitas:['🔒 CCTV','🚗 Parkir','📶 WiFi'],          kapasitas:'4 orang',  ukuran:'6.1m × 13.4m' },
  // BASKETBALL
  { id:'field-003', venueName:'Lapangan Basketball C', venueType:'Basketball', area:'Zona C', pricePerHour:200000, status:'available', rating:4.9, totalReviews:56,  imageUrl:'https://images.unsplash.com/photo-1503198129995-3f110c24aaa0?crop=entropy&cs=srgb&fm=jpg&ixlib=rb-4.1.0&q=85&w=400', city:'Sumedang', address:'Komplek GOR Sumedang', fasilitas:['🔒 CCTV','🚗 Parkir','🪑 Tribun','🚿 Ruang Ganti'], kapasitas:'20 orang', ukuran:'28m × 15m' },
  { id:'field-008', venueName:'Lapangan Basketball D', venueType:'Basketball', area:'Zona D', pricePerHour:180000, status:'available', rating:4.8, totalReviews:37,  imageUrl:'https://images.unsplash.com/photo-1525973132219-a04334a76080?crop=entropy&cs=srgb&fm=jpg&ixlib=rb-4.1.0&q=85&w=400', city:'Sumedang', address:'Jl. Ahmad Yani No. 21',     fasilitas:['🔒 CCTV','🚗 Parkir','🪑 Tribun'],        kapasitas:'16 orang', ukuran:'28m × 15m' },
  // VOLI
  { id:'field-004', venueName:'Lapangan Voli D',       venueType:'Voli',       area:'Zona D', pricePerHour:100000, status:'available', rating:4.7, totalReviews:73,  imageUrl:'https://images.pexels.com/photos/6203529/pexels-photo-6203529.jpeg?auto=compress&cs=tinysrgb&w=400',  city:'Sumedang', address:'Jl. Pangeran Kornel No. 45',   fasilitas:['🔒 CCTV','🚗 Parkir','🕌 Mushola'],       kapasitas:'14 orang', ukuran:'18m × 9m' },
  { id:'field-010', venueName:'Lapangan Voli F',       venueType:'Voli',       area:'Zona F', pricePerHour:110000, status:'available', rating:4.6, totalReviews:41,  imageUrl:'https://images.pexels.com/photos/6203531/pexels-photo-6203531.jpeg?auto=compress&cs=tinysrgb&w=400',  city:'Sumedang', address:'Jl. Veteran No. 10',              fasilitas:['🔒 CCTV','🕌 Mushola','🚗 Parkir','🪑 Tribun'], kapasitas:'14 orang', ukuran:'18m × 9m' },
];

// =========================================================
// INIT
// =========================================================
document.addEventListener('DOMContentLoaded', async () => {
  const user = await getCurrentUser() || JSON.parse(localStorage.getItem('sipelor_demo_user') || 'null');
  bookingState.user = user || null;

  const today = new Date().toISOString().split('T')[0];
  bookingState.date = today;

  document.querySelectorAll('.booking-date-input').forEach(el => {
    el.min = today;
    el.value = today;
    el.addEventListener('change', (e) => {
      bookingState.date = e.target.value;
      document.querySelectorAll('.booking-date-input').forEach(d => { if (d !== el) d.value = e.target.value; });
      renderTimeSlots();
      updateSummary();
    });
  });

  renderSportTypes();
  renderVenueList();
  renderTimeSlots();
  updateSummary();
  updateNavbarAuth();

  // Duration buttons
  document.querySelectorAll('.duration-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.duration-btn').forEach(b => b.classList.remove('selected'));
      btn.classList.add('selected');
      bookingState.duration = parseInt(btn.dataset.hours);
      calculateEndTime();
      updateSummary();
    });
  });

  // Step navigation
  document.getElementById('btn-next-step1')?.addEventListener('click', () => goToStep(2));
  document.getElementById('btn-next-step2')?.addEventListener('click', () => goToStep(3));
  document.getElementById('btn-next-step3')?.addEventListener('click', () => goToStep(4));
  document.getElementById('btn-back-step2')?.addEventListener('click', () => goToStep(1));
  document.getElementById('btn-back-step3')?.addEventListener('click', () => goToStep(2));
  document.getElementById('btn-back-step4')?.addEventListener('click', () => goToStep(3));
  document.getElementById('btn-confirm-booking')?.addEventListener('click', handleConfirmBooking);

  // Pre-select sport dari URL param
  const params = new URLSearchParams(window.location.search);
  const sport = params.get('sport');
  if (sport) {
    setTimeout(() => {
      selectSportType(sport);
      goToStep(2);
    }, 100);
  }
});

// =========================================================
// STEP 1: Sport Types
// =========================================================
function renderSportTypes() {
  const container = document.getElementById('sport-types-grid');
  if (!container) return;
  container.innerHTML = SPORT_TYPES.map(sport => {
    const count = MOCK_FIELDS.filter(f => matchSportType(f.venueType, sport.id)).length;
    return `
      <div class="sport-option" data-id="${sport.id}" onclick="selectSportType('${sport.id}')">
        <span class="sport-option-icon">${sport.icon}</span>
        <div>
          <div class="sport-option-name">${sport.name}</div>
          <div class="sport-option-fields">${count} lapangan tersedia</div>
        </div>
      </div>
    `;
  }).join('');
}

function selectSportType(id) {
  bookingState.sportType = id;
  bookingState.field = null;
  document.querySelectorAll('.sport-option').forEach(el => {
    el.classList.toggle('selected', el.dataset.id === id);
  });
  renderVenueList(id);
  updateSummary();
}

function matchSportType(venueType, sportId) {
  const sport = SPORT_TYPES.find(s => s.id === sportId);
  if (!sport) return false;
  return sport.types.includes(venueType.toLowerCase());
}

// =========================================================
// STEP 2: Venue List
// =========================================================
function renderVenueList(sportType = null) {
  const container = document.getElementById('venue-list');
  if (!container) return;

  let fields = MOCK_FIELDS;
  if (sportType) fields = MOCK_FIELDS.filter(f => matchSportType(f.venueType, sportType));

  if (fields.length === 0) {
    container.innerHTML = `
      <div style="padding:40px;text-align:center;color:var(--color-text-muted)">
        <div style="font-size:3rem;margin-bottom:12px">🏟️</div>
        <p style="font-weight:700">Tidak ada lapangan tersedia</p>
        <p style="font-size:0.85rem;margin-top:8px">Coba pilih jenis olahraga lain</p>
      </div>
    `;
    return;
  }

  container.innerHTML = fields.map(f => {
    const bookedSlots = MOCK_BOOKED_MAP[f.id] || [];
    const availableSlots = TIME_SLOTS.length - bookedSlots.length;
    const statusColor = f.status === 'available' ? 'var(--color-success)' : 'var(--color-warning)';
    return `
      <div class="venue-list-item" data-id="${f.id}" onclick="selectVenue('${f.id}')">
        <img src="${f.imageUrl}" alt="${f.venueName}" class="venue-list-img" onerror="this.src='https://picsum.photos/90/68?grayscale'">
        <div class="venue-list-info">
          <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:4px">
            <div class="venue-list-name">${f.venueName}</div>
            <div style="display:flex;align-items:center;gap:5px;font-size:0.7rem;font-weight:700;color:${statusColor}">
              <span style="width:7px;height:7px;border-radius:50%;background:${statusColor};display:inline-block"></span>
              ${availableSlots} slot
            </div>
          </div>
          <div class="venue-list-location">📍 ${f.address}, ${f.city}</div>
          <div style="display:flex;gap:6px;flex-wrap:wrap;margin-bottom:8px">
            ${f.fasilitas.slice(0, 3).map(fas => `<span style="padding:2px 8px;border-radius:20px;background:var(--color-glass);border:1px solid var(--color-border);font-size:0.65rem;color:var(--color-text-muted)">${fas}</span>`).join('')}
          </div>
          <div class="venue-list-meta">
            <span class="venue-list-price">${formatRupiah(f.pricePerHour)}<span style="font-size:0.7rem;color:var(--color-text-dim);font-family:var(--font-body)">/jam</span></span>
            <span class="venue-list-rating">⭐ ${f.rating} <span style="color:var(--color-text-dim);font-weight:400">(${f.totalReviews})</span></span>
          </div>
        </div>
      </div>
    `;
  }).join('');
}

function selectVenue(id) {
  const field = MOCK_FIELDS.find(f => f.id === id);
  if (!field) return;
  bookingState.field = field;

  document.querySelectorAll('.venue-list-item').forEach(el => {
    if (el.dataset.id === id) {
      el.classList.add('selected');
      el.style.display = 'flex';
    } else {
      el.style.display = 'none';
    }
  });

  const filterBar  = document.querySelector('.filter-bar');
  const countBadge = document.getElementById('venue-count-badge');
  if (filterBar)  filterBar.style.display  = 'none';
  if (countBadge) countBadge.style.display = 'none';

  updateVenuePreview(field);
  renderTimeSlots();
  updateSummary();
}

function clearVenueSelection() {
  bookingState.field = null;
  bookingState.startTime = null;
  document.querySelectorAll('.venue-list-item').forEach(el => {
    el.style.display = 'flex';
    el.classList.remove('selected');
  });
  const filterBar  = document.querySelector('.filter-bar');
  const countBadge = document.getElementById('venue-count-badge');
  if (filterBar)  filterBar.style.display  = '';
  if (countBadge) countBadge.style.display = '';
  const preview = document.getElementById('venue-selected-preview');
  if (preview) preview.style.display = 'none';
  updateSummary();
}

function updateVenuePreview(field) {
  const preview = document.getElementById('venue-selected-preview');
  if (!preview) return;
  preview.style.display = 'block';
  preview.innerHTML = `
    <div style="padding:16px;background:rgba(255,88,0,0.06);border:1.5px solid rgba(255,88,0,0.25);border-radius:var(--radius-lg)">
      <div style="display:flex;gap:12px;align-items:flex-start;margin-bottom:12px">
        <img src="${field.imageUrl}" style="width:80px;height:60px;border-radius:8px;object-fit:cover;flex-shrink:0" onerror="this.src='https://picsum.photos/80/60?grayscale'">
        <div style="flex:1;min-width:0">
          <div style="display:flex;align-items:center;gap:6px;margin-bottom:2px">
            <span style="width:8px;height:8px;border-radius:50%;background:var(--color-success);display:inline-block"></span>
            <span style="font-weight:700;font-size:0.9rem;color:var(--color-text)">${field.venueName}</span>
          </div>
          <div style="font-size:0.75rem;color:var(--color-text-muted);margin-bottom:6px">📍 ${field.address}, ${field.city}</div>
          <div style="display:flex;align-items:center;gap:12px;flex-wrap:wrap">
            <span style="font-family:var(--font-display);font-size:1.15rem;color:var(--color-primary)">${formatRupiah(field.pricePerHour)}/jam</span>
            <span style="font-size:0.72rem;color:var(--color-text-dim)">📐 ${field.ukuran}</span>
            <span style="font-size:0.72rem;color:var(--color-text-dim)">👥 ${field.kapasitas}</span>
          </div>
        </div>
      </div>
      <div style="display:flex;gap:8px;align-items:center">
        <div style="flex:1;font-size:0.78rem;color:var(--color-success);font-weight:700">✅ Lapangan dipilih</div>
        <button onclick="clearVenueSelection()" style="padding:6px 14px;border-radius:var(--radius-full);border:1px solid var(--color-border);background:var(--color-glass);color:var(--color-text-muted);font-size:0.72rem;font-weight:700;cursor:pointer;font-family:var(--font-body);transition:all 0.2s" onmouseover="this.style.borderColor='var(--color-primary)';this.style.color='var(--color-primary)'" onmouseout="this.style.borderColor='var(--color-border)';this.style.color='var(--color-text-muted)'">
          ↺ Ganti Lapangan
        </button>
      </div>
    </div>
  `;
}

// =========================================================
// STEP 3: Time Slots
// =========================================================
function renderTimeSlots() {
  const container = document.getElementById('timeslot-grid');
  if (!container) return;
  const bookedSlots = bookingState.field ? (MOCK_BOOKED_MAP[bookingState.field.id] || []) : [];
  container.innerHTML = TIME_SLOTS.map(slot => {
    const isBooked   = bookedSlots.includes(slot);
    const isSelected = bookingState.startTime === slot;
    const endH    = parseInt(slot.split(':')[0]) + bookingState.duration;
    const endSlot = `${String(endH).padStart(2, '0')}:00`;
    return `
      <div
        class="timeslot ${isBooked ? 'booked' : ''} ${isSelected && !isBooked ? 'selected' : ''}"
        data-time="${slot}"
        onclick="${isBooked ? '' : `selectTimeSlot('${slot}')`}"
        title="${isBooked ? 'Slot ini sudah dipesan' : `${slot} - ${endSlot}`}"
      >
        <span style="font-size:0.8rem;font-weight:700">${slot}</span>
        ${isBooked
          ? '<span style="display:block;font-size:0.58rem;margin-top:2px;opacity:0.7">Penuh</span>'
          : `<span style="display:block;font-size:0.58rem;margin-top:2px;opacity:0.6">s/d ${endSlot}</span>`
        }
      </div>
    `;
  }).join('');
}

function selectTimeSlot(time) {
  bookingState.startTime = time;
  calculateEndTime();
  renderTimeSlots();
  updateSummary();
}

function calculateEndTime() {
  if (!bookingState.startTime) return;
  const h = parseInt(bookingState.startTime.split(':')[0]);
  bookingState.endTime    = `${String(h + bookingState.duration).padStart(2, '0')}:00`;
  bookingState.totalAmount = (bookingState.field?.pricePerHour || 0) * bookingState.duration;
}

// =========================================================
// UPDATE SUMMARY SIDEBAR
// =========================================================
function updateSummary() {
  const sport     = SPORT_TYPES.find(s => s.id === bookingState.sportType);
  const sportText = sport ? `${sport.icon} ${sport.name}` : '-';
  const venueText = bookingState.field?.venueName || '-';
  const dateText  = bookingState.date ? formatDateID(bookingState.date) : '-';
  const timeText  = bookingState.startTime ? `${bookingState.startTime} – ${bookingState.endTime || '?'}` : '-';
  const durText   = `${bookingState.duration} jam`;
  const priceText = bookingState.field ? formatRupiah(bookingState.field.pricePerHour) : '-';
  const totalText = formatRupiah(bookingState.totalAmount);

  const set = (id, val) => { const el = document.getElementById(id); if (el) el.textContent = val; };
  set('summary-sport',    sportText);
  set('summary-venue',    venueText);
  set('summary-date',     dateText);
  set('summary-time',     timeText);
  set('summary-duration', durText);
  set('summary-total',    totalText);
  set('confirm-sport',    sportText);
  set('confirm-venue',    venueText);
  set('confirm-date',     dateText);
  set('confirm-time',     timeText);
  set('confirm-duration', durText);
  set('confirm-price',    priceText);
  set('confirm-total',    totalText);
}

// =========================================================
// UPDATE INFO BAR STEP 3
// (dipanggil dari goToStep — tidak lagi di-override di luar)
// =========================================================
function updateStep3InfoBar() {
  const sport = SPORT_TYPES.find(s => s.id === bookingState.sportType);
  const s3icon  = document.getElementById('step3-sport-icon');
  const s3name  = document.getElementById('step3-venue-name');
  const s3date  = document.getElementById('step3-date-display');
  const s3price = document.getElementById('step3-price');
  if (s3icon)  s3icon.textContent  = sport?.icon || '⚽';
  if (s3name)  s3name.textContent  = bookingState.field?.venueName || '-';
  if (s3date)  s3date.textContent  = bookingState.date ? formatDateID(bookingState.date) : '-';
  if (s3price) s3price.textContent = bookingState.field ? formatRupiah(bookingState.field.pricePerHour) : '-';
}

// =========================================================
// NAVIGATION — FIX: goToStep tidak di-override dari luar
// =========================================================
function goToStep(step) {
  if (step === 2 && !bookingState.sportType) {
    showToast('Pilih jenis olahraga terlebih dahulu!', 'warning');
    return;
  }
  if (step === 3 && !bookingState.field) {
    showToast('Pilih lapangan terlebih dahulu!', 'warning');
    return;
  }
  if (step === 3 && !bookingState.date) {
    showToast('Pilih tanggal terlebih dahulu!', 'warning');
    return;
  }
  if (step === 4 && !bookingState.startTime) {
    showToast('Pilih jam mulai terlebih dahulu!', 'warning');
    return;
  }

  bookingState.step = step;

  // Update panels
  document.querySelectorAll('.booking-panel').forEach(el => el.classList.remove('active'));
  const panel = document.getElementById(`booking-panel-${step}`);
  if (panel) { panel.classList.add('active'); panel.scrollIntoView({ behavior: 'smooth', block: 'start' }); }

  // Update step indicators
  document.querySelectorAll('.booking-step-item').forEach((el, i) => {
    el.classList.toggle('active',    i + 1 === step);
    el.classList.toggle('completed', i + 1 <  step);
  });

  // Sync date inputs when moving to step 3
  if (step === 3) {
    const dateVal = bookingState.date;
    document.querySelectorAll('.booking-date-input').forEach(el => { el.value = dateVal; });
    updateStep3InfoBar();
    renderTimeSlots();
  }

  // Populate confirmation on step 4
  if (step === 4) {
    calculateEndTime();
    updateSummary();
  }
}

// =========================================================
// CONFIRM BOOKING
// =========================================================
async function handleConfirmBooking() {
  if (!bookingState.sportType || !bookingState.field || !bookingState.date || !bookingState.startTime) {
    showToast('Lengkapi semua data booking terlebih dahulu!', 'error');
    return;
  }

  const user = bookingState.user;
  const btn = document.getElementById('btn-confirm-booking');
  if (btn) {
    btn.disabled = true;
    btn.innerHTML = '<span style="display:inline-block;width:16px;height:16px;border:2px solid rgba(255,255,255,0.3);border-top-color:#fff;border-radius:50%;animation:spin 0.8s linear infinite;vertical-align:middle;margin-right:8px"></span>Memproses...';
  }

  const bookingData = {
    sport:      bookingState.sportType,
    field_id:   bookingState.field.id,
    field_name: bookingState.field.venueName,
    date:       bookingState.date,
    start_time: bookingState.startTime,
    end_time:   bookingState.endTime,
    duration:   bookingState.duration,
    total:      bookingState.totalAmount,
    notes:      document.getElementById('booking-notes')?.value || '',
    user_id:    user?.id || 'demo-user',
    user_email: user?.email || 'demo@sipelor.com',
    status:     'pending_payment',
    created_at: new Date().toISOString(),
    booking_code: 'SPL-' + Date.now(),
  };

  try {
    // Simpan ke Supabase jika tersedia
    if (supabaseClient) {
      const { error } = await supabaseClient.from('bookings').insert([bookingData]);
      if (error) throw error;
    } else {
      // Mode demo: simpan ke localStorage
      await simulateDelay(1500);
      localStorage.setItem('sipelor_booking_draft', JSON.stringify(bookingData));
    }

    showToast('Booking berhasil! Mengarahkan ke halaman pembayaran... 🎉', 'success', 2500);

    // Redirect ke payment dengan booking_code sebagai query param
    setTimeout(() => {
      const params = new URLSearchParams({
        booking_code: bookingData.booking_code,
        field:        bookingData.field_name,
        date:         bookingData.date,
        time:         `${bookingData.start_time} – ${bookingData.end_time}`,
        duration:     bookingData.duration,
        total:        bookingData.total,
      });
      window.location.href = `/payment?${params.toString()}`;
    }, 2000);

  } catch (err) {
    console.error('[SIPELOR] Booking error:', err);
    showToast('Gagal menyimpan booking. Coba lagi.', 'error');
    if (btn) { btn.disabled = false; btn.innerHTML = '🎯 Konfirmasi & Lanjut Bayar'; }
  }
}
