// =============================================
// SIPELOR BEDAS — Tournament Module
// Bupati CUP & Event Olahraga Lainnya
// =============================================

/* ── State ─────────────────────────────────── */
let _trn = {
  tournaments: [],
  activeTournament: null,
  activeSport: null,
  teams: [],
  matches: [],
  standings: [],
  sports: [],
  activeTab: 'overview',
};

const SPORT_ICONS = {
  futsal: '⚽', badminton: '🏸', volly: '🏐', basket: '🏀',
  tenis: '🎾', sepakbola: '⚽', bulutangkis: '🏸', renang: '🏊',
  atletik: '🏃', pencaksilat: '🥋', default: '🏆'
};

const SPORT_ICON = (name) => {
  if (!name) return '🏆';
  const n = name.toLowerCase();
  for (const [k, v] of Object.entries(SPORT_ICONS)) if (n.includes(k)) return v;
  return SPORT_ICONS.default;
};

const PHASE_LABELS = {
  group: 'Fase Grup', round_of_16: '16 Besar', quarterfinal: 'Perempat Final',
  semifinal: 'Semi Final', final: 'Final', third_place: 'Perebutan Juara 3'
};
const STATUS_LABELS = {
  draft: 'Draft', open: 'Pendaftaran Buka', ongoing: 'Berlangsung',
  completed: 'Selesai', cancelled: 'Dibatalkan',
};
const STATUS_BADGE = {
  draft:     'badge-gray',   open:      'badge-info',
  ongoing:   'badge-success', completed: 'badge-purple', cancelled: 'badge-danger',
};
const TEAM_STATUS_BADGE = {
  pending: 'badge-warning', approved: 'badge-success', rejected: 'badge-danger',
};
const MATCH_STATUS_BADGE = {
  scheduled: 'badge-info', ongoing: 'badge-warning', completed: 'badge-success',
  cancelled: 'badge-danger', walkover: 'badge-gray',
};

/* ══════════════════════════════════════════
   ENTRY POINT
══════════════════════════════════════════ */
window.renderTournament = async function(api, content) {
  content.innerHTML = _pageLoader();
  const tournaments = await api.getTournaments();
  _trn.tournaments = tournaments;
  _renderTournamentList(api, content);
};

/* ══════════════════════════════════════════
   TOURNAMENT LIST
══════════════════════════════════════════ */
function _renderTournamentList(api, content) {
  const t = _trn.tournaments;
  content.innerHTML = `
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-title">🏆 Turnamen & Kejuaraan</div>
      <div class="page-subtitle">Bupati CUP, Liga, dan Event Olahraga DISPORA Kabupaten Bandung</div>
    </div>
    <div class="flex gap-2">
      <button class="btn btn-gradient" onclick="_openCreateTournament()">
        <svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        Buat Event Baru
      </button>
    </div>
  </div>

  ${t.length === 0 ? `
    <div class="card">
      <div class="empty-state" style="padding:80px 40px;">
        <div class="empty-state-icon">🏆</div>
        <h3>Belum ada event turnamen</h3>
        <p>Klik "Buat Event Baru" untuk membuat Bupati CUP atau liga olahraga pertama.</p>
        <button class="btn btn-gradient" style="margin-top:20px;" onclick="_openCreateTournament()">
          + Buat Event Pertama
        </button>
      </div>
    </div>
  ` : `
    <div class="trn-grid">
      ${t.map(trn => _tournamentCard(trn)).join('')}
    </div>
  `}

  ${_modalCreateTournament()}
  ${_modalSportForm()}
  ${_modalTeamDetail()}
  ${_modalScoreInput()}
  ${_modalGenerateBracket()}
  `;
}

function _tournamentCard(trn) {
  const sportCount = trn._sportCount || 0;
  const teamCount  = trn._teamCount  || 0;
  const now = new Date();
  const start = new Date(trn.start_date);
  const end   = new Date(trn.end_date);
  const daysDiff = Math.ceil((start - now) / 86400000);
  const countdown = trn.status === 'open' && daysDiff > 0
    ? `<span class="trn-countdown">Mulai ${daysDiff} hari lagi</span>` : '';

  return `
  <div class="trn-card" onclick="_openTournamentDetail('${trn.id}')">
    <div class="trn-card-header" style="background:${trn._gradient || 'linear-gradient(135deg,#7C3AED,#D946EF)'};">
      <div class="trn-card-poster">
        ${trn.poster_url
          ? `<img src="${trn.poster_url}" alt="${trn.name}" style="width:100%;height:100%;object-fit:cover;border-radius:inherit;">`
          : `<span style="font-size:52px;">${SPORT_ICON(trn._primarySport)}</span>`}
      </div>
      <div class="trn-card-badge-wrap">
        <span class="badge ${STATUS_BADGE[trn.status] || 'badge-gray'}">${STATUS_LABELS[trn.status] || trn.status}</span>
        ${countdown}
      </div>
    </div>
    <div class="trn-card-body">
      <h3 class="trn-card-title">${trn.name}</h3>
      <div class="trn-card-meta">
        <span>📅 ${fmtDate(trn.start_date)} — ${fmtDate(trn.end_date)}</span>
        ${trn.location ? `<span>📍 ${trn.location}</span>` : ''}
      </div>
      <div class="trn-card-stats">
        <div class="trn-stat"><span class="trn-stat-v">${sportCount}</span><span class="trn-stat-l">Cabang</span></div>
        <div class="trn-stat"><span class="trn-stat-v">${teamCount}</span><span class="trn-stat-l">Tim</span></div>
        <div class="trn-stat"><span class="trn-stat-v">${trn._matchCount || 0}</span><span class="trn-stat-l">Pertandingan</span></div>
      </div>
    </div>
  </div>`;
}

/* ══════════════════════════════════════════
   TOURNAMENT DETAIL
══════════════════════════════════════════ */
window._openTournamentDetail = async function(id) {
  const content = document.getElementById('page-content');
  content.innerHTML = _pageLoader();
  const [trn, sports] = await Promise.all([
    api.getTournamentById(id),
    api.getTournamentSports(id),
  ]);
  if (!trn) { showToast('Event tidak ditemukan', 'error'); return; }
  _trn.activeTournament = trn;
  _trn.sports = sports;
  _trn.activeSport = sports[0] || null;
  _trn.activeTab = 'overview';
  _renderTournamentDetail(content);
};

function _renderTournamentDetail(content) {
  const trn = _trn.activeTournament;
  const sports = _trn.sports;

  content.innerHTML = `
  <!-- Back + Header -->
  <div class="page-header">
    <div class="page-header-left">
      <button class="btn btn-outline btn-sm" onclick="renderTournament(api, document.getElementById('page-content'))" style="margin-bottom:8px;">
        ← Kembali ke Daftar
      </button>
      <div style="display:flex;align-items:center;gap:12px;">
        <div class="page-title">${trn.name}</div>
        <span class="badge ${STATUS_BADGE[trn.status] || 'badge-gray'}">${STATUS_LABELS[trn.status] || trn.status}</span>
      </div>
      <div class="page-subtitle">📅 ${fmtDate(trn.start_date)} – ${fmtDate(trn.end_date)} ${trn.location ? `&nbsp;·&nbsp; 📍 ${trn.location}` : ''}</div>
    </div>
    <div class="flex gap-2">
      <button class="btn btn-outline btn-sm" onclick="_editTournament('${trn.id}')">
        ✏️ Edit
      </button>
      <select class="form-control" style="width:auto;padding:8px 14px;font-size:13px;" onchange="_changeTournamentStatus('${trn.id}', this.value)">
        <option value="">Ubah Status...</option>
        <option value="draft" ${trn.status==='draft'?'selected':''}>Draft</option>
        <option value="open" ${trn.status==='open'?'selected':''}>Buka Pendaftaran</option>
        <option value="ongoing" ${trn.status==='ongoing'?'selected':''}>Berlangsung</option>
        <option value="completed" ${trn.status==='completed'?'selected':''}>Selesai</option>
        <option value="cancelled" ${trn.status==='cancelled'?'selected':''}>Batalkan</option>
      </select>
    </div>
  </div>

  <!-- Sport Tabs (pilih cabang olahraga) -->
  ${sports.length > 0 ? `
  <div class="trn-sport-tabs" id="sport-tab-bar">
    ${sports.map(s => `
      <button class="trn-sport-tab ${_trn.activeSport?.id === s.id ? 'active' : ''}"
              onclick="_selectSport('${s.id}')">
        ${SPORT_ICON(s.sport_name)} ${s.sport_name}
        <span class="badge badge-gray" style="font-size:10px;margin-left:4px;">${s.status}</span>
      </button>
    `).join('')}
    <button class="trn-sport-tab trn-add-sport" onclick="_openAddSport('${trn.id}')">
      + Cabang Baru
    </button>
  </div>` : `
  <div class="card" style="margin-bottom:20px;">
    <div class="empty-state" style="padding:40px;">
      <div class="empty-state-icon">🏅</div>
      <h3>Belum ada cabang olahraga</h3>
      <p>Tambah cabang olahraga untuk event ini.</p>
      <button class="btn btn-primary" style="margin-top:12px;" onclick="_openAddSport('${trn.id}')">
        + Tambah Cabang Olahraga
      </button>
    </div>
  </div>`}

  <!-- Main Tabs -->
  <div class="tabs" id="trn-main-tabs">
    <button class="tab active" onclick="_switchTab('overview')" id="tab-btn-overview">📋 Informasi</button>
    <button class="tab" onclick="_switchTab('teams')" id="tab-btn-teams">👥 Tim Peserta</button>
    <button class="tab" onclick="_switchTab('matches')" id="tab-btn-matches">📅 Jadwal & Skor</button>
    <button class="tab" onclick="_switchTab('bracket')" id="tab-btn-bracket">🏆 Bracket & Klasemen</button>
  </div>

  <div id="trn-tab-content">
    ${_tabOverview(trn)}
  </div>

  ${_modalCreateTournament(trn)}
  ${_modalSportForm()}
  ${_modalTeamDetail()}
  ${_modalScoreInput()}
  ${_modalGenerateBracket()}
  `;
}

window._selectSport = async function(sportId) {
  _trn.activeSport = _trn.sports.find(s => s.id === sportId) || _trn.activeSport;
  document.querySelectorAll('.trn-sport-tab:not(.trn-add-sport)').forEach(b => b.classList.remove('active'));
  event.target.closest('.trn-sport-tab')?.classList.add('active');
  // Reload active tab content
  _switchTab(_trn.activeTab);
};

window._switchTab = async function(tab) {
  _trn.activeTab = tab;
  document.querySelectorAll('#trn-main-tabs .tab').forEach(b => b.classList.remove('active'));
  document.getElementById(`tab-btn-${tab}`)?.classList.add('active');
  const content = document.getElementById('trn-tab-content');
  if (!content) return;
  content.innerHTML = _pageLoader();

  switch (tab) {
    case 'overview': content.innerHTML = _tabOverview(_trn.activeTournament); break;
    case 'teams':    await _loadAndRenderTeams(content); break;
    case 'matches':  await _loadAndRenderMatches(content); break;
    case 'bracket':  await _loadAndRenderBracket(content); break;
  }
};

/* ── Tab: Overview ──────────────────────────────────────────────────────────── */
function _tabOverview(trn) {
  const sports = _trn.sports;
  return `
  <div class="grid-2" style="gap:20px;">
    <div class="card">
      <div class="card-header"><div class="card-title">📋 Detail Event</div></div>
      <div class="card-body">
        <div class="info-grid">
          <div class="info-item"><div class="info-label">Nama Event</div><div class="info-value">${trn.name}</div></div>
          <div class="info-item"><div class="info-label">Penyelenggara</div><div class="info-value">${trn.organizer_name || 'DISPORA Kabupaten Bandung'}</div></div>
          <div class="info-item"><div class="info-label">Tanggal Mulai</div><div class="info-value">${fmtDate(trn.start_date)}</div></div>
          <div class="info-item"><div class="info-label">Tanggal Selesai</div><div class="info-value">${fmtDate(trn.end_date)}</div></div>
          ${trn.registration_deadline ? `<div class="info-item"><div class="info-label">Batas Pendaftaran</div><div class="info-value">${fmtDate(trn.registration_deadline)}</div></div>` : ''}
          ${trn.location ? `<div class="info-item"><div class="info-label">Lokasi</div><div class="info-value">${trn.location}</div></div>` : ''}
          <div class="info-item"><div class="info-label">Maks Tim/Cabang</div><div class="info-value">${trn.max_teams_per_sport || 'Bebas'}</div></div>
          <div class="info-item"><div class="info-label">Status</div><div class="info-value"><span class="badge ${STATUS_BADGE[trn.status]}">${STATUS_LABELS[trn.status]}</span></div></div>
        </div>
        ${trn.description ? `<div style="margin-top:16px;padding-top:16px;border-top:1px solid var(--border);font-size:14px;color:var(--text-secondary);line-height:1.7;">${trn.description}</div>` : ''}
      </div>
    </div>

    <div class="card">
      <div class="card-header">
        <div class="card-title">🏅 Cabang Olahraga (${sports.length})</div>
        <button class="btn btn-primary btn-sm" onclick="_openAddSport('${trn.id}')">+ Tambah</button>
      </div>
      <div class="card-body" style="padding:0;">
        ${sports.length === 0
          ? '<div class="empty-state" style="padding:30px;"><div class="empty-state-icon">🏅</div><p>Belum ada cabang olahraga</p></div>'
          : `<table style="width:100%;"><thead><tr>
              <th style="padding:10px 16px;">Cabang</th>
              <th>Format</th>
              <th>Tim</th>
              <th>Status</th>
              <th></th>
            </tr></thead><tbody>
            ${sports.map(s => `<tr>
              <td style="padding:12px 16px;font-weight:700;">${SPORT_ICON(s.sport_name)} ${s.sport_name}</td>
              <td style="font-size:12px;color:var(--text-secondary);">${{group_knockout:'Grup + Gugur',single_elimination:'Gugur Langsung',round_robin:'Liga'}[s.format]||s.format}</td>
              <td>${s._teamCount || '—'}</td>
              <td><span class="badge badge-gray" style="font-size:10px;">${{registration:'Registrasi',group_stage:'Fase Grup',knockout:'Gugur',completed:'Selesai'}[s.status]||s.status}</span></td>
              <td>
                <button class="btn btn-ghost btn-sm" onclick="_editSport('${s.id}')" title="Edit">✏️</button>
                <button class="btn btn-ghost btn-sm" style="color:var(--danger);" onclick="_deleteSport('${s.id}')" title="Hapus">🗑️</button>
              </td>
            </tr>`).join('')}
            </tbody></table>`}
      </div>
    </div>
  </div>`;
}

/* ── Tab: Teams ─────────────────────────────────────────────────────────────── */
async function _loadAndRenderTeams(content) {
  if (!_trn.activeSport) {
    content.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🏅</div><h3>Pilih cabang olahraga terlebih dahulu</h3></div>';
    return;
  }
  const teams = await api.getTournamentTeams(_trn.activeTournament.id, _trn.activeSport.id);
  _trn.teams = teams;
  _renderTeamsTab(content, teams);
}

function _renderTeamsTab(content, teams) {
  const s = _trn.activeSport;
  const groups = [...new Set(teams.filter(t => t.group_name).map(t => t.group_name))].sort();
  const ungrouped = teams.filter(t => !t.group_name);

  content.innerHTML = `
  <div class="card">
    <div class="card-header">
      <div>
        <div class="card-title">👥 Tim Peserta — ${s?.sport_name || ''}</div>
        <div class="card-subtitle">${teams.length} tim terdaftar</div>
      </div>
      <div class="flex gap-2">
        ${teams.some(t => t.status === 'approved' && !t.group_name)
          ? `<button class="btn btn-outline btn-sm" onclick="_openGroupAssignment()">🗂️ Atur Grup</button>` : ''}
        <select class="form-control" style="width:auto;font-size:13px;padding:8px 12px;" onchange="_filterTeamStatus(this.value)">
          <option value="">Semua Status</option>
          <option value="pending">Menunggu</option>
          <option value="approved">Disetujui</option>
          <option value="rejected">Ditolak</option>
        </select>
      </div>
    </div>
    <div id="teams-table-wrap">
      ${_renderTeamsTable(teams)}
    </div>
  </div>`;
}

function _renderTeamsTable(teams) {
  if (teams.length === 0) {
    return '<div class="empty-state" style="padding:50px;"><div class="empty-state-icon">👥</div><h3>Belum ada tim mendaftar</h3><p>Tim mendaftar melalui aplikasi SIPELOR.</p></div>';
  }
  return `
  <div class="table-wrap">
    <table>
      <thead><tr>
        <th>#</th>
        <th>Tim</th>
        <th>Kapten</th>
        <th>Kontak</th>
        <th>Kecamatan</th>
        <th>Grup</th>
        <th>Status</th>
        <th>Aksi</th>
      </tr></thead>
      <tbody>
        ${teams.map((t, i) => `
        <tr>
          <td style="color:var(--text-muted);font-size:12px;">${i+1}</td>
          <td>
            <div style="display:flex;align-items:center;gap:10px;">
              ${t.team_logo_url
                ? `<img src="${t.team_logo_url}" style="width:32px;height:32px;border-radius:50%;object-fit:cover;">`
                : `<div class="avatar-sm" style="font-size:11px;">${(t.team_name||'?')[0].toUpperCase()}</div>`}
              <span style="font-weight:700;">${t.team_name}</span>
            </div>
          </td>
          <td>${t.captain_name || '—'}</td>
          <td style="font-size:12px;">${t.captain_phone || t.captain_email || '—'}</td>
          <td>${t.asal_kecamatan || '—'}</td>
          <td>
            ${t.status === 'approved'
              ? `<select class="form-control" style="width:70px;font-size:12px;padding:4px 6px;" onchange="_assignGroup('${t.id}', this.value)">
                  <option value="">—</option>
                  ${['A','B','C','D','E','F','G','H'].map(g => `<option ${t.group_name===g?'selected':''} value="${g}">${g}</option>`).join('')}
                 </select>`
              : `<span class="text-muted">—</span>`}
          </td>
          <td><span class="badge ${TEAM_STATUS_BADGE[t.status]||'badge-gray'}">${{pending:'Menunggu',approved:'Disetujui',rejected:'Ditolak'}[t.status]||t.status}</span></td>
          <td>
            <div class="flex gap-2">
              ${t.status === 'pending' ? `
                <button class="btn btn-success btn-sm btn-icon" title="Setujui" onclick="_updateTeamStatus('${t.id}','approved')">✓</button>
                <button class="btn btn-danger btn-sm btn-icon" title="Tolak" onclick="_updateTeamStatus('${t.id}','rejected')">✕</button>
              ` : ''}
              <button class="btn btn-ghost btn-sm" onclick="_viewTeamDetail('${t.id}')" title="Detail">👁️</button>
            </div>
          </td>
        </tr>`).join('')}
      </tbody>
    </table>
  </div>`;
}

/* ── Tab: Matches ───────────────────────────────────────────────────────────── */
async function _loadAndRenderMatches(content) {
  if (!_trn.activeSport) {
    content.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🏅</div><h3>Pilih cabang olahraga</h3></div>';
    return;
  }
  const matches = await api.getTournamentMatches(_trn.activeTournament.id, _trn.activeSport.id);
  _trn.matches = matches;
  _renderMatchesTab(content, matches);
}

function _renderMatchesTab(content, matches) {
  const s = _trn.activeSport;
  // Group by phase
  const phases = {};
  matches.forEach(m => {
    if (!phases[m.phase]) phases[m.phase] = [];
    phases[m.phase].push(m);
  });

  const phaseOrder = ['group','round_of_16','quarterfinal','semifinal','third_place','final'];
  const sortedPhases = Object.keys(phases).sort((a,b) => phaseOrder.indexOf(a) - phaseOrder.indexOf(b));

  const approvedTeams = _trn.teams.filter(t => t.status === 'approved').length;
  const hasMatches = matches.length > 0;

  content.innerHTML = `
  <div class="card">
    <div class="card-header">
      <div>
        <div class="card-title">📅 Jadwal & Skor — ${s?.sport_name || ''}</div>
        <div class="card-subtitle">${matches.length} pertandingan</div>
      </div>
      <div class="flex gap-2">
        <button class="btn btn-primary btn-sm" onclick="_openAddMatch()">+ Tambah Pertandingan</button>
        ${hasMatches ? `<button class="btn btn-outline btn-sm" onclick="_syncBracket()" title="Isi otomatis slot TBD dari hasil match yang sudah selesai">🔄 Sinkronkan Pemenang</button>` : ''}
        ${approvedTeams >= 2 && !hasMatches
          ? `<button class="btn btn-gradient btn-sm" onclick="_openGenerateBracket()">⚡ Generate Bracket Otomatis</button>`
          : (hasMatches ? `<button class="btn btn-outline btn-sm" onclick="_openGenerateBracket()">↺ Regenerate Bracket</button>` : '')}
      </div>
    </div>

    ${matches.length === 0 ? `
      <div class="empty-state" style="padding:60px 40px;">
        <div class="empty-state-icon">📅</div>
        <h3>Belum ada jadwal pertandingan</h3>
        <p style="max-width:380px;">Pastikan sudah ada tim yang disetujui, lalu generate bracket otomatis atau tambah pertandingan manual.</p>
        ${approvedTeams >= 2
          ? `<button class="btn btn-gradient" style="margin-top:16px;" onclick="_openGenerateBracket()">⚡ Generate Bracket Otomatis</button>`
          : `<p style="color:var(--warning);margin-top:12px;font-weight:600;">⚠️ Butuh minimal 2 tim yang disetujui</p>`}
      </div>
    ` : sortedPhases.map(phase => `
      <div class="trn-phase-section">
        <div class="trn-phase-header">
          <span class="trn-phase-title">${PHASE_LABELS[phase] || phase}</span>
          <span class="badge badge-gray">${phases[phase].length} pertandingan</span>
        </div>
        ${_renderMatchesPhaseGroup(phases[phase], phase)}
      </div>
    `).join('')}
  </div>`;
}

function _renderMatchesPhaseGroup(matches, phase) {
  // Group by group_name if group phase
  if (phase === 'group') {
    const byGroup = {};
    matches.forEach(m => { const g = m.group_name || '?'; if (!byGroup[g]) byGroup[g] = []; byGroup[g].push(m); });
    return Object.keys(byGroup).sort().map(g => `
      <div style="margin:0 22px 16px;">
        <div style="font-size:12px;font-weight:700;color:var(--text-muted);margin-bottom:8px;text-transform:uppercase;letter-spacing:.5px;">Grup ${g}</div>
        ${_matchTable(byGroup[g])}
      </div>
    `).join('');
  }
  return `<div style="margin:0 22px 16px;">${_matchTable(matches)}</div>`;
}

function _matchTable(matches) {
  // Helper: render a team name cell with double-click-to-edit support
  const _teamCell = (m, slot) => {
    const name    = slot === 'a' ? m.team_a_name : m.team_b_name;
    const isWin   = m.winner_id && (slot === 'a' ? m.winner_id === m.team_a_id : m.winner_id === m.team_b_id);
    const isEmpty = !name || name.trim() === '' || name.trim().toUpperCase() === 'TBD';
    const display = isEmpty ? 'TBD' : name;
    const color   = isWin ? 'color:var(--success);' : (isEmpty ? 'color:var(--text-muted);' : '');
    return `<span
      class="trn-team-name-cell"
      data-match-id="${m.id}"
      data-slot="${slot}"
      style="font-weight:${isWin ? '800' : '600'};${color}cursor:pointer;"
      title="Klik 2x untuk ubah nama tim"
      ondblclick="_editTeamName('${m.id}', '${slot}', this)"
    >${display}</span>`;
  };

  return `
  <table style="width:100%;">
    <thead><tr>
      <th style="padding:8px 12px;">#</th>
      <th>Tim A <span style="font-size:10px;color:var(--text-muted);font-weight:400;">(2x klik untuk edit)</span></th>
      <th style="width:120px;text-align:center;">Skor</th>
      <th>Tim B <span style="font-size:10px;color:var(--text-muted);font-weight:400;">(2x klik untuk edit)</span></th>
      <th>Waktu</th>
      <th>Venue</th>
      <th>Status</th>
      <th>Aksi</th>
    </tr></thead>
    <tbody>
      ${matches.map((m, i) => `
      <tr>
        <td style="color:var(--text-muted);font-size:12px;padding:10px 12px;">${i+1}</td>
        <td>${_teamCell(m, 'a')}</td>
        <td style="text-align:center;">
          ${m.status === 'completed'
            ? `<span class="trn-score">${m.team_a_score ?? '?'} — ${m.team_b_score ?? '?'}</span>`
            : `<span style="color:var(--text-muted);font-size:13px;">vs</span>`}
        </td>
        <td>${_teamCell(m, 'b')}</td>
        <td style="font-size:12px;color:var(--text-secondary);">${m.scheduled_at ? fmtDateTime(m.scheduled_at) : '—'}</td>
        <td style="font-size:12px;">${m.venue_name || '—'}</td>
        <td><span class="badge ${MATCH_STATUS_BADGE[m.status]||'badge-gray'}" style="font-size:10px;">${{scheduled:'Dijadwalkan',ongoing:'Berlangsung',completed:'Selesai',cancelled:'Dibatalkan',walkover:'W.O.'}[m.status]||m.status}</span></td>
        <td>
          <button class="btn btn-primary btn-sm" onclick="_openScoreInput('${m.id}')" title="Input Skor">
            ${m.status === 'completed' ? '✏️ Edit' : '⚽ Skor'}
          </button>
        </td>
      </tr>`).join('')}
    </tbody>
  </table>`;
}

/* ── Inline team name editor ──────────────────────────────────────────────── */
window._editTeamName = function(matchId, slot, spanEl) {
  // Prevent nested triggers
  if (spanEl.querySelector('input')) return;

  const prevText = spanEl.textContent.trim();
  const isEmpty  = prevText === 'TBD' || prevText === '—' || prevText === '';

  const input = document.createElement('input');
  input.type        = 'text';
  input.value       = isEmpty ? '' : prevText;
  input.placeholder = 'Nama pemenang...';
  input.className   = 'form-control';
  input.style.cssText = 'width:130px;height:28px;padding:3px 8px;font-size:12px;font-weight:700;display:inline-block;';

  spanEl.textContent = '';
  spanEl.appendChild(input);
  input.focus();
  input.select();

  let committed = false;
  const commit = async () => {
    if (committed) return;
    committed = true;

    const newName = input.value.trim();
    // Revert if empty or unchanged
    if (!newName || newName === prevText) {
      spanEl.textContent = prevText;
      return;
    }

    spanEl.textContent = '⏳';
    try {
      await api.updateMatchTeamName(matchId, slot, newName);

      // Update local match state so subsequent re-renders use the new name
      const idx = _trn.matches.findIndex(m => m.id === matchId);
      if (idx >= 0) {
        if (slot === 'a') _trn.matches[idx].team_a_name = newName;
        else              _trn.matches[idx].team_b_name = newName;
      }

      // Refresh cell styling
      spanEl.textContent = newName;
      spanEl.style.color  = '';
      spanEl.style.fontWeight = '700';
      showToast(`✓ Nama tim diperbarui: ${newName}`, 'success');
    } catch (e) {
      console.error('[SIPELOR] _editTeamName error:', e);
      spanEl.textContent = prevText;
      showToast('Gagal menyimpan: ' + (e.message || e), 'error');
    }
  };

  input.addEventListener('keydown', (e) => {
    if (e.key === 'Enter')  { e.preventDefault(); commit(); }
    if (e.key === 'Escape') { committed = true; spanEl.textContent = prevText; }
  });
  input.addEventListener('blur', commit);
};

/* ── Tab: Bracket & Standings ───────────────────────────────────────────────── */
async function _loadAndRenderBracket(content) {
  if (!_trn.activeSport) {
    content.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🏅</div><h3>Pilih cabang olahraga</h3></div>';
    return;
  }
  const [matches, standings] = await Promise.all([
    api.getTournamentMatches(_trn.activeTournament.id, _trn.activeSport.id),
    api.getTournamentStandings(_trn.activeTournament.id, _trn.activeSport.id),
  ]);
  _trn.matches = matches;
  _trn.standings = standings;
  _renderBracketTab(content, matches, standings);
}

function _renderBracketTab(content, matches, standings) {
  const s = _trn.activeSport;
  const hasGroups = standings.length > 0;
  const knockoutMatches = matches.filter(m => m.phase !== 'group');
  const groupMatches = matches.filter(m => m.phase === 'group');

  content.innerHTML = `
  ${hasGroups ? `
  <!-- Klasemen Grup -->
  <div class="card" style="margin-bottom:20px;">
    <div class="card-header"><div class="card-title">📊 Klasemen Fase Grup — ${s?.sport_name || ''}</div></div>
    <div class="card-body" style="padding:0;">
      ${_renderStandingsTables(standings)}
    </div>
  </div>` : ''}

  <!-- Bracket Gugur -->
  ${knockoutMatches.length > 0 ? `
  <div class="card">
    <div class="card-header"><div class="card-title">🏆 Bracket Fase Gugur</div></div>
    <div class="card-body" style="overflow-x:auto;">
      ${_renderKnockoutBracket(knockoutMatches)}
    </div>
  </div>` : (matches.length > 0 && !hasGroups ? `
  <div class="card">
    <div class="card-header"><div class="card-title">🏆 Bracket Single Elimination</div></div>
    <div class="card-body" style="overflow-x:auto;">
      ${_renderKnockoutBracket(matches)}
    </div>
  </div>` : '')}

  ${matches.length === 0 ? `
  <div class="card"><div class="empty-state" style="padding:60px;">
    <div class="empty-state-icon">🏆</div>
    <h3>Bracket belum dibuat</h3>
    <p>Buat jadwal pertandingan terlebih dahulu di tab "Jadwal & Skor".</p>
  </div></div>` : ''}`;
}

function _renderStandingsTables(standings) {
  const byGroup = {};
  standings.forEach(s => { if (!byGroup[s.group_name]) byGroup[s.group_name] = []; byGroup[s.group_name].push(s); });
  const sorted = Object.keys(byGroup).sort();

  return `<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(400px,1fr));gap:20px;padding:20px;">
    ${sorted.map(g => {
      const rows = byGroup[g].sort((a, b) => b.points - a.points || b.goal_difference - a.goal_difference || b.goals_for - a.goals_for);
      return `
      <div>
        <div style="font-size:12px;font-weight:800;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px;">Grup ${g}</div>
        <table style="width:100%;">
          <thead><tr>
            <th style="padding:8px 10px;text-align:left;">#</th>
            <th style="padding:8px 10px;text-align:left;">Tim</th>
            <th style="text-align:center;padding:6px;">M</th>
            <th style="text-align:center;padding:6px;">M</th>
            <th style="text-align:center;padding:6px;">S</th>
            <th style="text-align:center;padding:6px;">K</th>
            <th style="text-align:center;padding:6px;">GM</th>
            <th style="text-align:center;padding:6px;">GK</th>
            <th style="text-align:center;padding:6px;">SG</th>
            <th style="text-align:center;padding:8px;font-weight:900;color:var(--primary);">Poin</th>
          </tr></thead>
          <tbody>
            ${rows.map((r, i) => `<tr style="${i < (_trn.activeSport?.teams_advance_per_group || 2) ? 'background:rgba(16,185,129,.06);' : ''}">
              <td style="padding:9px 10px;font-size:12px;color:var(--text-muted);">${i+1}</td>
              <td style="padding:9px 10px;font-weight:700;">${i < (_trn.activeSport?.teams_advance_per_group||2) ? '🟢 ' : ''}${r.team_name}</td>
              <td style="text-align:center;font-size:13px;">${r.played}</td>
              <td style="text-align:center;font-size:13px;color:var(--success);">${r.won}</td>
              <td style="text-align:center;font-size:13px;color:var(--warning);">${r.drawn}</td>
              <td style="text-align:center;font-size:13px;color:var(--danger);">${r.lost}</td>
              <td style="text-align:center;font-size:13px;">${r.goals_for}</td>
              <td style="text-align:center;font-size:13px;">${r.goals_against}</td>
              <td style="text-align:center;font-size:13px;">${r.goal_difference}</td>
              <td style="text-align:center;font-weight:900;font-size:15px;color:var(--primary);">${r.points}</td>
            </tr>`).join('')}
          </tbody>
        </table>
      </div>`;
    }).join('')}
  </div>`;
}

function _renderKnockoutBracket(matches) {
  const phaseOrder = ['round_of_16','quarterfinal','semifinal','final'];
  const knMatches = matches.filter(m => m.phase !== 'group');
  const thirdPlace = knMatches.find(m => m.phase === 'third_place');
  const mainMatches = knMatches.filter(m => m.phase !== 'third_place');
  const phases = [...new Set(mainMatches.map(m => m.phase))].sort((a,b) => phaseOrder.indexOf(a) - phaseOrder.indexOf(b));

  if (phases.length === 0 && !thirdPlace) {
    return '<div class="empty-state" style="padding:40px;"><div class="empty-state-icon">🏆</div><p>Belum ada pertandingan gugur</p></div>';
  }

  return `
  <div class="trn-bracket-wrap">
    <div class="trn-bracket">
      ${phases.map((phase, pi) => {
        const pMatches = mainMatches.filter(m => m.phase === phase).sort((a,b) => a.match_number - b.match_number);
        const isFinal = phase === 'final';
        return `
        <div class="trn-bracket-round">
          <div class="trn-bracket-round-title">${PHASE_LABELS[phase] || phase}</div>
          <div class="trn-bracket-matches" style="${isFinal ? 'justify-content:center;' : ''}">
            ${pMatches.map(m => `
            <div class="trn-bracket-match ${m.status === 'completed' ? 'completed' : ''}">
              <div class="trn-bm-team ${m.winner_id === m.team_a_id ? 'winner' : m.status==='completed'?'loser':''}">
                <span class="trn-bm-name ${!m.team_a_name ? 'tbd' : ''}">${m.team_a_name || 'Menunggu…'}</span>
                ${m.status === 'completed' ? `<span class="trn-bm-score">${m.team_a_score ?? ''}</span>` : ''}
              </div>
              <div class="trn-bm-team ${m.winner_id === m.team_b_id ? 'winner' : m.status==='completed'?'loser':''}">
                <span class="trn-bm-name ${!m.team_b_name ? 'tbd' : ''}">${m.team_b_name || 'Menunggu…'}</span>
                ${m.status === 'completed' ? `<span class="trn-bm-score">${m.team_b_score ?? ''}</span>` : ''}
              </div>
              ${m.scheduled_at ? `<div class="trn-bm-meta">${fmtDateTime(m.scheduled_at)}</div>` : ''}
              <button class="trn-bm-edit-btn" onclick="_openScoreInput('${m.id}')">
                ${m.status === 'completed' ? '✏️' : '⚽'}
              </button>
            </div>`).join('')}
          </div>
        </div>`;
      }).join('')}
    </div>
    ${thirdPlace ? `
    <div style="margin-top:20px;padding-top:20px;border-top:1px dashed var(--border);">
      <div style="font-size:12px;font-weight:700;color:var(--text-muted);text-align:center;margin-bottom:12px;text-transform:uppercase;letter-spacing:.5px;">Perebutan Juara 3</div>
      <div style="display:flex;justify-content:center;">
        <div class="trn-bracket-match ${thirdPlace.status==='completed'?'completed':''}">
          <div class="trn-bm-team ${thirdPlace.winner_id===thirdPlace.team_a_id?'winner':thirdPlace.status==='completed'?'loser':''}">
            <span class="trn-bm-name ${!thirdPlace.team_a_name?'tbd':''}">${thirdPlace.team_a_name||'Menunggu…'}</span>
            ${thirdPlace.status==='completed'?`<span class="trn-bm-score">${thirdPlace.team_a_score??''}</span>`:''}
          </div>
          <div class="trn-bm-team ${thirdPlace.winner_id===thirdPlace.team_b_id?'winner':thirdPlace.status==='completed'?'loser':''}">
            <span class="trn-bm-name ${!thirdPlace.team_b_name?'tbd':''}">${thirdPlace.team_b_name||'Menunggu…'}</span>
            ${thirdPlace.status==='completed'?`<span class="trn-bm-score">${thirdPlace.team_b_score??''}</span>`:''}
          </div>
          <button class="trn-bm-edit-btn" onclick="_openScoreInput('${thirdPlace.id}')">⚽</button>
        </div>
      </div>
    </div>` : ''}

    ${matches.find(m => m.phase==='final' && m.status==='completed' && m.winner_id) ? `
    <div class="trn-champion-banner">
      🏆 JUARA: <strong>${matches.find(m=>m.phase==='final'&&m.winner_id)?.winner_id === matches.find(m=>m.phase==='final')?.team_a_id
        ? matches.find(m=>m.phase==='final')?.team_a_name
        : matches.find(m=>m.phase==='final')?.team_b_name}</strong>
    </div>` : ''}
  </div>`;
}

/* ══════════════════════════════════════════
   MODALS
══════════════════════════════════════════ */

/* ── Modal: Create / Edit Tournament ─────────────────────────────────────────── */
function _modalCreateTournament(trn = null) {
  const id = 'modal-create-tournament';
  const isEdit = !!trn;
  return `
  <div class="modal-overlay" id="${id}">
    <div class="modal modal-lg">
      <div class="modal-header">
        <div class="modal-title">${isEdit ? '✏️ Edit Event' : '🏆 Buat Event Turnamen Baru'}</div>
        <button class="btn btn-ghost btn-icon" onclick="closeModal('${id}')">✕</button>
      </div>
      <div class="modal-body">
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Nama Event <span class="req">*</span></label>
            <input id="trn-f-name" class="form-control" placeholder="Contoh: Bupati CUP 2026" value="${isEdit?trn.name:''}" />
          </div>
          <div class="form-group">
            <label class="form-label">Penyelenggara</label>
            <input id="trn-f-org" class="form-control" placeholder="DISPORA Kabupaten Bandung" value="${isEdit?trn.organizer_name||'DISPORA Kabupaten Bandung':'DISPORA Kabupaten Bandung'}" />
          </div>
        </div>
        <div class="form-group">
          <label class="form-label">Deskripsi</label>
          <textarea id="trn-f-desc" class="form-control" rows="3" placeholder="Deskripsi singkat event...">${isEdit?trn.description||'':''}</textarea>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Tanggal Mulai <span class="req">*</span></label>
            <input id="trn-f-start" type="date" class="form-control" value="${isEdit?trn.start_date:''}" />
          </div>
          <div class="form-group">
            <label class="form-label">Tanggal Selesai <span class="req">*</span></label>
            <input id="trn-f-end" type="date" class="form-control" value="${isEdit?trn.end_date:''}" />
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Batas Pendaftaran</label>
            <input id="trn-f-reg" type="date" class="form-control" value="${isEdit?trn.registration_deadline||'':''}" />
          </div>
          <div class="form-group">
            <label class="form-label">Lokasi Utama</label>
            <input id="trn-f-loc" class="form-control" placeholder="GOR Sabilulungan, Bandung" value="${isEdit?trn.location||'':''}" />
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Maks Tim per Cabang</label>
            <input id="trn-f-maxteam" type="number" class="form-control" placeholder="0 = bebas" value="${isEdit?trn.max_teams_per_sport||0:0}" min="0" />
          </div>
          <div class="form-group">
            <label class="form-label">URL Poster (opsional)</label>
            <input id="trn-f-poster" class="form-control" placeholder="https://..." value="${isEdit?trn.poster_url||'':''}" />
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn btn-outline" onclick="closeModal('${id}')">Batal</button>
        <button class="btn btn-gradient" onclick="_saveTournament(${isEdit?`'${trn.id}'`:'null'})">
          ${isEdit ? 'Simpan Perubahan' : '🏆 Buat Event'}
        </button>
      </div>
    </div>
  </div>`;
}

window._openCreateTournament = function() { openModal('modal-create-tournament'); };
window._editTournament = function(id) { openModal('modal-create-tournament'); };

window._saveTournament = async function(id) {
  const payload = {
    name:                  document.getElementById('trn-f-name')?.value?.trim(),
    organizer_name:        document.getElementById('trn-f-org')?.value?.trim() || 'DISPORA Kabupaten Bandung',
    description:           document.getElementById('trn-f-desc')?.value?.trim() || null,
    start_date:            document.getElementById('trn-f-start')?.value,
    end_date:              document.getElementById('trn-f-end')?.value,
    registration_deadline: document.getElementById('trn-f-reg')?.value || null,
    location:              document.getElementById('trn-f-loc')?.value?.trim() || null,
    max_teams_per_sport:   parseInt(document.getElementById('trn-f-maxteam')?.value || '0'),
    poster_url:            document.getElementById('trn-f-poster')?.value?.trim() || null,
  };
  if (!payload.name || !payload.start_date || !payload.end_date) {
    showToast('Nama, tanggal mulai, dan tanggal selesai wajib diisi', 'error'); return;
  }
  try {
    if (id) {
      await api.updateTournament(id, payload);
      showToast('Event berhasil diperbarui', 'success');
      _trn.activeTournament = { ..._trn.activeTournament, ...payload };
    } else {
      const newT = await api.createTournament(payload);
      showToast('Event berhasil dibuat! 🎉', 'success');
      closeModal('modal-create-tournament');
      await _openTournamentDetail(newT.id);
      return;
    }
    closeModal('modal-create-tournament');
    const content = document.getElementById('page-content');
    if (id && _trn.activeTournament) _renderTournamentDetail(content);
    else renderTournament(api, content);
  } catch (e) {
    showToast('Error: ' + (e.message || 'Terjadi kesalahan'), 'error');
  }
};

/* ── Modal: Sport Form ─────────────────────────────────────────────────────── */
let _editingSportId = null;
function _modalSportForm() {
  return `
  <div class="modal-overlay" id="modal-sport-form">
    <div class="modal">
      <div class="modal-header">
        <div class="modal-title" id="sport-modal-title">+ Tambah Cabang Olahraga</div>
        <button class="btn btn-ghost btn-icon" onclick="closeModal('modal-sport-form')">✕</button>
      </div>
      <div class="modal-body">
        <div class="form-group">
          <label class="form-label">Nama Cabang <span class="req">*</span></label>
          <input id="sport-f-name" class="form-control" placeholder="Futsal, Badminton, Volly, dll" />
        </div>
        <div class="form-group">
          <label class="form-label">Format Turnamen <span class="req">*</span></label>
          <select id="sport-f-format" class="form-control" onchange="_onFormatChange()">
            <option value="group_knockout">Fase Grup + Fase Gugur</option>
            <option value="single_elimination">Gugur Langsung (Single Elimination)</option>
            <option value="round_robin">Liga (Round Robin)</option>
          </select>
          <div class="form-hint">Pilih "Fase Grup + Gugur" untuk format Bupati CUP standar</div>
        </div>
        <div id="sport-group-config">
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Jumlah Grup</label>
              <select id="sport-f-groupcount" class="form-control">
                ${[2,3,4,6,8].map(n=>`<option value="${n}">${n} Grup</option>`).join('')}
              </select>
            </div>
            <div class="form-group">
              <label class="form-label">Tim Lolos per Grup</label>
              <select id="sport-f-advance" class="form-control">
                ${[1,2,3,4].map(n=>`<option value="${n}" ${n===2?'selected':''}>${n} Tim</option>`).join('')}
              </select>
            </div>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn btn-outline" onclick="closeModal('modal-sport-form')">Batal</button>
        <button class="btn btn-primary" onclick="_saveSport()">Simpan Cabang</button>
      </div>
    </div>
  </div>`;
}

window._onFormatChange = function() {
  const fmt = document.getElementById('sport-f-format')?.value;
  const gc = document.getElementById('sport-group-config');
  if (gc) gc.style.display = fmt === 'group_knockout' ? '' : 'none';
};

window._openAddSport = function(tournamentId) {
  _editingSportId = null;
  document.getElementById('sport-modal-title').textContent = '+ Tambah Cabang Olahraga';
  document.getElementById('sport-f-name').value = '';
  document.getElementById('sport-f-format').value = 'group_knockout';
  _onFormatChange();
  openModal('modal-sport-form');
};

window._editSport = function(sportId) {
  const s = _trn.sports.find(x => x.id === sportId);
  if (!s) return;
  _editingSportId = sportId;
  document.getElementById('sport-modal-title').textContent = '✏️ Edit Cabang Olahraga';
  document.getElementById('sport-f-name').value = s.sport_name;
  document.getElementById('sport-f-format').value = s.format;
  document.getElementById('sport-f-groupcount').value = s.group_count || 2;
  document.getElementById('sport-f-advance').value = s.teams_advance_per_group || 2;
  _onFormatChange();
  openModal('modal-sport-form');
};

window._saveSport = async function() {
  const payload = {
    tournament_id:          _trn.activeTournament.id,
    sport_name:             document.getElementById('sport-f-name')?.value?.trim(),
    format:                 document.getElementById('sport-f-format')?.value,
    group_count:            parseInt(document.getElementById('sport-f-groupcount')?.value||'2'),
    teams_advance_per_group: parseInt(document.getElementById('sport-f-advance')?.value||'2'),
  };
  if (!payload.sport_name) { showToast('Nama cabang wajib diisi', 'error'); return; }
  try {
    if (_editingSportId) {
      await api.updateTournamentSport(_editingSportId, payload);
      showToast('Cabang olahraga diperbarui', 'success');
    } else {
      await api.createTournamentSport(payload);
      showToast('Cabang olahraga ditambahkan! 🏅', 'success');
    }
    closeModal('modal-sport-form');
    _trn.sports = await api.getTournamentSports(_trn.activeTournament.id);
    _trn.activeSport = _trn.sports[0] || null;
    const content = document.getElementById('page-content');
    _renderTournamentDetail(content);
  } catch (e) {
    showToast('Error: ' + (e.message || 'Gagal menyimpan'), 'error');
  }
};

window._deleteSport = async function(sportId) {
  if (!confirm('Hapus cabang olahraga ini? Semua data tim dan pertandingan dalam cabang ini akan ikut terhapus.')) return;
  try {
    await api.deleteTournamentSport(sportId);
    showToast('Cabang dihapus', 'success');
    _trn.sports = await api.getTournamentSports(_trn.activeTournament.id);
    _trn.activeSport = _trn.sports[0] || null;
    const content = document.getElementById('page-content');
    _renderTournamentDetail(content);
  } catch (e) {
    showToast('Error: ' + e.message, 'error');
  }
};

/* ── Modal: Score Input ──────────────────────────────────────────────────────── */
function _modalScoreInput() {
  return `
  <div class="modal-overlay" id="modal-score-input">
    <div class="modal">
      <div class="modal-header">
        <div class="modal-title">⚽ Input Skor Pertandingan</div>
        <button class="btn btn-ghost btn-icon" onclick="closeModal('modal-score-input')">✕</button>
      </div>
      <div class="modal-body">
        <div id="score-match-info" style="margin-bottom:20px;"></div>
        <div style="display:grid;grid-template-columns:1fr auto 1fr;gap:16px;align-items:center;">
          <div style="text-align:center;">
            <div id="score-team-a-name" style="font-size:16px;font-weight:800;margin-bottom:8px;"></div>
            <input id="score-a" type="number" class="form-control" min="0" placeholder="0" style="font-size:28px;font-weight:900;text-align:center;height:64px;" />
          </div>
          <div style="font-size:24px;font-weight:900;color:var(--text-muted);text-align:center;">VS</div>
          <div style="text-align:center;">
            <div id="score-team-b-name" style="font-size:16px;font-weight:800;margin-bottom:8px;"></div>
            <input id="score-b" type="number" class="form-control" min="0" placeholder="0" style="font-size:28px;font-weight:900;text-align:center;height:64px;" />
          </div>
        </div>
        <div class="form-group" style="margin-top:16px;">
          <label class="form-label">Status Pertandingan</label>
          <select id="score-status" class="form-control" onchange="_onScoreStatusChange()">
            <option value="scheduled">Dijadwalkan</option>
            <option value="ongoing">Berlangsung</option>
            <option value="completed">Selesai</option>
            <option value="walkover">Walkover (W.O.)</option>
            <option value="cancelled">Dibatalkan</option>
          </select>
        </div>
        <!-- Muncul hanya saat status = walkover -->
        <div class="form-group" id="wo-winner-wrap" style="display:none;">
          <label class="form-label" style="color:var(--warning);">⚠️ Tim Pemenang W.O.</label>
          <select id="wo-winner-id" class="form-control">
            <option value="">-- Pilih tim yang menang --</option>
          </select>
          <div class="form-hint">Tim yang dipilih akan otomatis maju ke babak berikutnya</div>
        </div>
        <div class="form-group">
          <label class="form-label">Jadwal (opsional)</label>
          <input id="score-schedule" type="datetime-local" class="form-control" />
        </div>
        <div class="form-group">
          <label class="form-label">Venue / Lapangan</label>
          <input id="score-venue" class="form-control" placeholder="GOR Sabilulungan, Lapangan Futsal A..." />
        </div>
        <div class="form-group">
          <label class="form-label">Catatan</label>
          <textarea id="score-notes" class="form-control" rows="2" placeholder="Catatan tambahan..."></textarea>
        </div>
        <input type="hidden" id="score-match-id" />
      </div>
      <div class="modal-footer">
        <button class="btn btn-outline" onclick="closeModal('modal-score-input')">Batal</button>
        <button class="btn btn-gradient" onclick="_saveScore()">💾 Simpan Hasil</button>
      </div>
    </div>
  </div>`;
}

window._onScoreStatusChange = function() {
  const status = document.getElementById('score-status')?.value;
  const woWrap = document.getElementById('wo-winner-wrap');
  if (woWrap) woWrap.style.display = status === 'walkover' ? '' : 'none';
};

window._openScoreInput = function(matchId) {
  const match = _trn.matches.find(m => m.id === matchId);
  if (!match) { showToast('Data pertandingan tidak ditemukan', 'error'); return; }

  document.getElementById('score-match-id').value = matchId;
  document.getElementById('score-team-a-name').textContent = match.team_a_name || 'Tim A';
  document.getElementById('score-team-b-name').textContent = match.team_b_name || 'Tim B';
  document.getElementById('score-a').value = match.team_a_score ?? '';
  document.getElementById('score-b').value = match.team_b_score ?? '';
  document.getElementById('score-status').value = match.status || 'scheduled';
  document.getElementById('score-venue').value = match.venue_name || '';
  document.getElementById('score-notes').value = match.notes || '';
  if (match.scheduled_at) {
    const dt = new Date(match.scheduled_at);
    document.getElementById('score-schedule').value = dt.toISOString().slice(0,16);
  } else {
    document.getElementById('score-schedule').value = '';
  }

  // Populate W.O. winner dropdown
  const woSelect = document.getElementById('wo-winner-id');
  if (woSelect) {
    woSelect.innerHTML = `
      <option value="">-- Pilih tim yang menang --</option>
      ${match.team_a_id ? `<option value="${match.team_a_id}">${match.team_a_name || 'Tim A'}</option>` : ''}
      ${match.team_b_id ? `<option value="${match.team_b_id}">${match.team_b_name || 'Tim B'}</option>` : ''}
    `;
    if (match.status === 'walkover' && match.winner_id) {
      woSelect.value = match.winner_id;
    }
  }
  _onScoreStatusChange();

  const infoEl = document.getElementById('score-match-info');
  if (infoEl) {
    infoEl.innerHTML = `<div class="badge badge-info" style="margin-right:8px;">${PHASE_LABELS[match.phase]||match.phase}</div>
      ${match.group_name ? `<div class="badge badge-gray">Grup ${match.group_name}</div>` : ''}
      <div style="margin-top:8px;font-size:12px;color:var(--text-muted);">Pertandingan #${match.match_number}</div>`;
  }
  openModal('modal-score-input');
};

window._saveScore = async function() {
  const matchId    = document.getElementById('score-match-id')?.value;
  const scoreA     = document.getElementById('score-a')?.value;
  const scoreB     = document.getElementById('score-b')?.value;
  const status     = document.getElementById('score-status')?.value;
  const venue      = document.getElementById('score-venue')?.value?.trim();
  const notes      = document.getElementById('score-notes')?.value?.trim();
  const sched      = document.getElementById('score-schedule')?.value;
  const woWinnerId = document.getElementById('wo-winner-id')?.value;

  if (!matchId) return;
  const match = _trn.matches.find(m => m.id === matchId);
  if (!match) return;

  // Validasi: W.O. wajib memilih pemenang
  if (status === 'walkover' && !woWinnerId) {
    showToast('Pilih tim pemenang untuk pertandingan W.O.', 'error'); return;
  }

  try {
    await api.updateMatchScore(matchId, {
      team_a_score: scoreA !== '' ? parseInt(scoreA) : null,
      team_b_score: scoreB !== '' ? parseInt(scoreB) : null,
      status,
      venue_name:         venue || null,
      notes:              notes || null,
      scheduled_at:       sched ? new Date(sched).toISOString() : null,
      inputted_by:        currentUser?.id || null,
      walkover_winner_id: status === 'walkover' ? woWinnerId : undefined,
    });
    showToast('Skor berhasil disimpan! Pemenang otomatis maju ke babak berikutnya. ⚽', 'success');
    closeModal('modal-score-input');
    await _loadAndRenderMatches(document.getElementById('trn-tab-content'));
  } catch (e) {
    console.error('[SIPELOR] _saveScore error:', e);
    showToast('Error: ' + (e.message || 'Gagal menyimpan skor'), 'error');
    // Still refresh so any partial save is reflected
    await _loadAndRenderMatches(document.getElementById('trn-tab-content'));
  }
};

/* ── Sync bracket: re-advance winners for all completed knockout matches ────── */
window._syncBracket = async function() {
  if (!_trn.activeTournament || !_trn.activeSport) return;
  const btn = event?.target;
  if (btn) { btn.disabled = true; btn.textContent = '🔄 Menyinkronkan...'; }
  try {
    const count = await api.syncBracketAdvancement(_trn.activeTournament.id, _trn.activeSport.id);
    showToast(`Sinkronisasi selesai! ${count} pemenang berhasil dimajukan ke babak berikutnya.`, 'success');
    await _loadAndRenderMatches(document.getElementById('trn-tab-content'));
  } catch (e) {
    console.error('[SIPELOR] _syncBracket error:', e);
    showToast('Gagal sinkronisasi: ' + (e.message || e), 'error');
  } finally {
    if (btn) { btn.disabled = false; btn.textContent = '🔄 Sinkronkan Pemenang'; }
  }
};

/* ── Modal: Generate Bracket ─────────────────────────────────────────────────── */
function _modalGenerateBracket() {
  return `
  <div class="modal-overlay" id="modal-generate-bracket">
    <div class="modal">
      <div class="modal-header">
        <div class="modal-title">⚡ Generate Bracket Otomatis</div>
        <button class="btn btn-ghost btn-icon" onclick="closeModal('modal-generate-bracket')">✕</button>
      </div>
      <div class="modal-body">
        <div style="background:var(--warning-bg);border:1px solid var(--warning);border-radius:var(--radius);padding:14px 16px;margin-bottom:20px;font-size:13px;color:#92400E;">
          ⚠️ Generate bracket akan membuat jadwal pertandingan berdasarkan tim yang <strong>disetujui</strong>.
          Jika sudah ada pertandingan, akan ditimpa. Pastikan semua tim sudah diatur grupnya (untuk format Grup + Gugur).
        </div>
        <div id="bracket-gen-info" style="margin-bottom:16px;"></div>
        <div class="form-group">
          <label class="form-label">Metode Seeding</label>
          <select id="gen-seeding" class="form-control">
            <option value="random">Acak (Random Undian)</option>
            <option value="manual">Gunakan Urutan Saat Ini</option>
          </select>
        </div>
        <div class="form-group" id="gen-group-assign-wrap">
          <label class="form-label">Pembagian Grup</label>
          <select id="gen-group-assign" class="form-control">
            <option value="auto">Otomatis (acak)</option>
            <option value="manual">Manual (sesuai pengaturan saat ini)</option>
          </select>
          <div class="form-hint">Pilih "Manual" jika sudah mengatur grup tiap tim di tab Tim Peserta</div>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn btn-outline" onclick="closeModal('modal-generate-bracket')">Batal</button>
        <button class="btn btn-gradient" onclick="_executeBracketGeneration()">⚡ Generate Sekarang</button>
      </div>
    </div>
  </div>`;
}

window._openGenerateBracket = function() {
  const s = _trn.activeSport;
  const infoEl = document.getElementById('bracket-gen-info');
  const approvedTeams = _trn.teams.filter(t => t.status === 'approved');
  if (infoEl) {
    infoEl.innerHTML = `
    <div class="trn-gen-info">
      <div class="trn-gen-stat"><span>${approvedTeams.length}</span><label>Tim Disetujui</label></div>
      <div class="trn-gen-stat"><span>${s?.group_count || '—'}</span><label>Grup</label></div>
      <div class="trn-gen-stat"><span>${{group_knockout:'Grup+Gugur',single_elimination:'Gugur',round_robin:'Liga'}[s?.format]||'—'}</span><label>Format</label></div>
    </div>`;
  }
  // Show/hide group config based on format
  const gcWrap = document.getElementById('gen-group-assign-wrap');
  if (gcWrap) gcWrap.style.display = s?.format === 'group_knockout' ? '' : 'none';
  openModal('modal-generate-bracket');
};

window._executeBracketGeneration = async function() {
  const seeding = document.getElementById('gen-seeding')?.value;
  const groupAssign = document.getElementById('gen-group-assign')?.value;
  try {
    await api.generateTournamentBracket(_trn.activeTournament.id, _trn.activeSport.id, { seeding, groupAssign });
    showToast('Bracket berhasil di-generate! 🎉', 'success');
    closeModal('modal-generate-bracket');
    await _loadAndRenderMatches(document.getElementById('trn-tab-content'));
  } catch (e) {
    showToast('Error: ' + (e.message || 'Gagal generate bracket'), 'error');
  }
};

/* ── Modal: Team Detail ─────────────────────────────────────────────────────── */
function _modalTeamDetail() {
  return `
  <div class="modal-overlay" id="modal-team-detail">
    <div class="modal modal-lg">
      <div class="modal-header">
        <div class="modal-title" id="team-detail-title">Detail Tim</div>
        <button class="btn btn-ghost btn-icon" onclick="closeModal('modal-team-detail')">✕</button>
      </div>
      <div class="modal-body" id="team-detail-body">
        <div class="page-loader"><div class="spinner"></div></div>
      </div>
    </div>
  </div>`;
}

window._viewTeamDetail = function(teamId) {
  const team = _trn.teams.find(t => t.id === teamId);
  if (!team) return;
  const titleEl = document.getElementById('team-detail-title');
  const bodyEl  = document.getElementById('team-detail-body');
  if (titleEl) titleEl.textContent = team.team_name;
  if (bodyEl) bodyEl.innerHTML = `
    <div class="info-grid" style="margin-bottom:16px;">
      <div class="info-item"><div class="info-label">Nama Tim</div><div class="info-value">${team.team_name}</div></div>
      <div class="info-item"><div class="info-label">Kapten</div><div class="info-value">${team.captain_name||'—'}</div></div>
      <div class="info-item"><div class="info-label">Telepon</div><div class="info-value">${team.captain_phone||'—'}</div></div>
      <div class="info-item"><div class="info-label">Email</div><div class="info-value">${team.captain_email||'—'}</div></div>
      <div class="info-item"><div class="info-label">Asal Kecamatan</div><div class="info-value">${team.asal_kecamatan||'—'}</div></div>
      <div class="info-item"><div class="info-label">Jumlah Pemain</div><div class="info-value">${team.jumlah_pemain||'—'}</div></div>
      <div class="info-item"><div class="info-label">Grup</div><div class="info-value">${team.group_name||'Belum ditentukan'}</div></div>
      <div class="info-item"><div class="info-label">Status</div><div class="info-value"><span class="badge ${TEAM_STATUS_BADGE[team.status]}">${{pending:'Menunggu',approved:'Disetujui',rejected:'Ditolak'}[team.status]}</span></div></div>
    </div>
    ${team.notes ? `<div style="padding:12px;background:var(--bg-page);border-radius:var(--radius);font-size:13px;color:var(--text-secondary);">📝 ${team.notes}</div>` : ''}
    <div style="display:flex;gap:10px;margin-top:20px;">
      ${team.status !== 'approved' ? `<button class="btn btn-success" onclick="_updateTeamStatus('${team.id}','approved');closeModal('modal-team-detail');">✓ Setujui Tim</button>` : ''}
      ${team.status !== 'rejected' ? `<button class="btn btn-danger" onclick="_updateTeamStatus('${team.id}','rejected');closeModal('modal-team-detail');">✕ Tolak Tim</button>` : ''}
    </div>`;
  openModal('modal-team-detail');
};

/* ══════════════════════════════════════════
   ACTIONS
══════════════════════════════════════════ */
window._updateTeamStatus = async function(teamId, status) {
  try {
    await api.updateTournamentTeamStatus(teamId, status);
    showToast(status === 'approved' ? 'Tim disetujui ✓' : 'Tim ditolak', status === 'approved' ? 'success' : 'warning');
    await _loadAndRenderTeams(document.getElementById('trn-tab-content'));
  } catch (e) {
    showToast('Error: ' + e.message, 'error');
  }
};

window._assignGroup = async function(teamId, groupName) {
  try {
    await api.updateTournamentTeam(teamId, { group_name: groupName || null });
    showToast(`Grup ${groupName || 'dihapus'}`, 'success');
    const idx = _trn.teams.findIndex(t => t.id === teamId);
    if (idx >= 0) _trn.teams[idx].group_name = groupName || null;
  } catch (e) {
    showToast('Error: ' + e.message, 'error');
  }
};

window._changeTournamentStatus = async function(id, status) {
  if (!status) return;
  if (!confirm(`Ubah status event ke "${STATUS_LABELS[status]}"?`)) {
    event.target.value = ''; return;
  }
  try {
    await api.updateTournament(id, { status });
    showToast(`Status berhasil diubah ke ${STATUS_LABELS[status]}`, 'success');
    _trn.activeTournament.status = status;
    const content = document.getElementById('page-content');
    _renderTournamentDetail(content);
  } catch (e) {
    showToast('Error: ' + e.message, 'error');
    event.target.value = '';
  }
};

window._filterTeamStatus = function(status) {
  const filtered = status ? _trn.teams.filter(t => t.status === status) : _trn.teams;
  const wrap = document.getElementById('teams-table-wrap');
  if (wrap) wrap.innerHTML = _renderTeamsTable(filtered);
};

window._openAddMatch = function() {
  showToast('Gunakan "Generate Bracket Otomatis" atau input skor pertandingan yang sudah ada', 'info', 5000);
};

/* ── Helpers ─────────────────────────────────────────────────────────────────── */
function _pageLoader() {
  return '<div class="page-loader"><div class="spinner spinner-lg"></div><span>Memuat...</span></div>';
}
