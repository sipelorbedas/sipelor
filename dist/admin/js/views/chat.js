// ─────────────────────────────────────────────────────
// CHAT VIEW — Admin ↔ User Messaging
// ─────────────────────────────────────────────────────

let _chatApi             = null;
let _chatActiveUserId    = null;
let _chatActiveUserName  = '';
let _chatMsgChannel      = null;   // realtime subscription for open conversation
let _chatConvChannel     = null;   // realtime subscription for conversation list
let _chatConversations   = [];
let _chatAdminId         = null;
let _chatAdminName       = '';

async function renderChat(api, container) {
  _chatApi       = api;
  _chatAdminId   = window.currentUser?.id   || null;
  _chatAdminName = window.currentUser?.name || 'Admin';

  container.innerHTML = `
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-title">💬 Chat dengan Pengguna</div>
      <div class="page-subtitle">Kirim dan terima pesan langsung dari pengguna aplikasi.</div>
    </div>
    <div id="chat-unread-badge-wrap"></div>
  </div>
  <div class="chat-layout" id="chat-layout">
    <!-- Left: Conversation list -->
    <div class="chat-sidebar" id="chat-sidebar">
      <div class="chat-sidebar-header">
        <div class="chat-sidebar-title">Percakapan</div>
        <div class="chat-search-wrap">
          <svg width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
          <input type="text" id="chat-search" placeholder="Cari pengguna..." oninput="filterChatConversations(this.value)" />
        </div>
      </div>
      <div class="chat-conv-list" id="chat-conv-list">
        <div class="page-loader"><span class="spinner spinner-sm"></span></div>
      </div>
    </div>

    <!-- Right: Message panel -->
    <div class="chat-panel" id="chat-panel">
      <div class="chat-empty-panel">
        <div class="chat-empty-icon">💬</div>
        <div class="chat-empty-title">Pilih percakapan</div>
        <div class="chat-empty-sub">Pilih pengguna di sebelah kiri untuk membuka percakapan.</div>
      </div>
    </div>
  </div>`;

  // Load conversations
  await loadConversations();

  // Subscribe to new messages coming in (refresh list)
  _chatConvChannel = api.subscribeConversations(convs => {
    _chatConversations = convs;
    renderConvList(convs);
  });
}

// ── Load & render conversation list ───────────────────
async function loadConversations() {
  const listEl = document.getElementById('chat-conv-list');
  if (!listEl) return;
  try {
    _chatConversations = await _chatApi.getChatConversations();
    renderConvList(_chatConversations);
  } catch (e) {
    listEl.innerHTML = `<div class="chat-conv-error">Gagal memuat percakapan.</div>`;
  }
}

function renderConvList(convs) {
  const listEl = document.getElementById('chat-conv-list');
  if (!listEl) return;

  if (!convs.length) {
    listEl.innerHTML = `<div class="chat-conv-empty"><span>🗨️</span><p>Belum ada percakapan.</p></div>`;
    // Clear badge when no conversations
    if (typeof window.updateChatUnreadBadge === 'function') window.updateChatUnreadBadge(0);
    return;
  }

  listEl.innerHTML = convs.map(c => {
    const initials  = (c.userName || 'U').split(' ').map(w => w[0]).join('').toUpperCase().substring(0, 2);
    const isActive  = c.userId === _chatActiveUserId;
    const timeLabel = c.lastTime ? _chatFmtTime(c.lastTime) : '';
    const preview   = (c.lastMessage || '').substring(0, 40) + (c.lastMessage?.length > 40 ? '…' : '');
    const unread    = c.unreadCount > 0 ? `<span class="chat-unread-dot">${c.unreadCount}</span>` : '';
    return `
    <div class="chat-conv-item${isActive ? ' active' : ''}" onclick="openChatConversation('${c.userId}', '${escHtml(c.userName)}')">
      <div class="chat-conv-avatar">${initials}</div>
      <div class="chat-conv-info">
        <div class="chat-conv-name-row">
          <span class="chat-conv-name">${escHtml(c.userName)}</span>
          <span class="chat-conv-time">${timeLabel}</span>
        </div>
        <div class="chat-conv-preview-row">
          <span class="chat-conv-preview">${escHtml(preview)}</span>
          ${unread}
        </div>
      </div>
    </div>`;
  }).join('');

  // Update sidebar + topbar badges dengan total unread dari semua percakapan
  const totalUnread = convs.reduce((s, c) => s + (c.unreadCount || 0), 0);
  if (typeof window.updateChatUnreadBadge === 'function') {
    window.updateChatUnreadBadge(totalUnread);
  }
}

window.filterChatConversations = function(query) {
  const q = query.trim().toLowerCase();
  const filtered = q
    ? _chatConversations.filter(c => (c.userName || '').toLowerCase().includes(q))
    : _chatConversations;
  renderConvList(filtered);
};

// ── Open a specific conversation ───────────────────────
window.openChatConversation = async function(userId, userName) {
  _chatActiveUserId   = userId;
  _chatActiveUserName = userName;

  // Update active state in list
  document.querySelectorAll('.chat-conv-item').forEach(el => {
    el.classList.toggle('active', el.dataset.uid === userId || el.getAttribute('onclick')?.includes(userId));
  });

  // Unsubscribe old channel
  if (_chatMsgChannel) { try { _chatMsgChannel.unsubscribe(); } catch (_) {} }

  const panel = document.getElementById('chat-panel');
  if (!panel) return;

  panel.innerHTML = `
  <div class="chat-panel-header">
    <div class="chat-panel-avatar">${(userName || 'U').split(' ').map(w=>w[0]).join('').toUpperCase().substring(0,2)}</div>
    <div class="chat-panel-info">
      <div class="chat-panel-name">${escHtml(userName)}</div>
      <div class="chat-panel-status" id="chat-panel-status">Memuat pesan...</div>
    </div>
    <button class="btn btn-outline btn-sm" onclick="refreshChatMessages()" title="Refresh">
      <svg width="13" height="13" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/></svg>
    </button>
  </div>

  <div class="chat-messages-wrap" id="chat-messages-wrap">
    <div class="page-loader"><span class="spinner"></span></div>
  </div>

  <div class="chat-input-area">
    <div class="chat-input-box">
      <textarea id="chat-textarea" class="chat-textarea" placeholder="Ketik pesan..." rows="1"
        onkeydown="chatInputKeydown(event)"
        oninput="chatTextareaAutoResize(this)"></textarea>
      <button class="chat-send-btn" id="chat-send-btn" onclick="sendChatMessage()" title="Kirim (Enter)">
        <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
      </button>
    </div>
    <div class="chat-input-hint">Tekan <kbd>Enter</kbd> kirim · <kbd>Shift+Enter</kbd> baris baru</div>
  </div>`;

  // Load messages
  await refreshChatMessages();

  // Mark as read
  _chatApi.markChatRead(userId);

  // Refresh conv list unread count
  loadConversations();

  // Subscribe realtime
  _chatMsgChannel = _chatApi.subscribeChatMessages(userId, msgs => {
    renderMessages(msgs);
    _chatApi.markChatRead(userId);
    loadConversations();
  });
};

// ── Load & render messages ──────────────────────────────
window.refreshChatMessages = async function() {
  const wrap = document.getElementById('chat-messages-wrap');
  if (!wrap || !_chatActiveUserId) return;
  try {
    const msgs = await _chatApi.getChatMessages(_chatActiveUserId);
    renderMessages(msgs);
    const statusEl = document.getElementById('chat-panel-status');
    if (statusEl) statusEl.textContent = `${msgs.length} pesan · online`;
  } catch (e) {
    wrap.innerHTML = `<div class="chat-load-error">Gagal memuat pesan.</div>`;
  }
};

function renderMessages(msgs) {
  const wrap = document.getElementById('chat-messages-wrap');
  if (!wrap) return;

  if (!msgs.length) {
    wrap.innerHTML = `<div class="chat-msg-empty"><span>👋</span><p>Belum ada pesan. Mulai percakapan!</p></div>`;
    return;
  }

  let lastDate = '';
  const html = msgs.map(m => {
    const isAdmin    = !!m.is_admin;
    const bubbleCls  = isAdmin ? 'chat-bubble admin' : 'chat-bubble user';
    const name       = isAdmin ? (m.sender_name || 'Admin') : (_chatActiveUserName || m.sender_name || 'User');
    const timeStr    = _chatFmtMsgTime(m.created_at);
    const dateLabel  = _chatFmtDateLabel(m.created_at);
    let dateSep = '';
    if (dateLabel !== lastDate) {
      lastDate = dateLabel;
      dateSep = `<div class="chat-date-sep"><span>${dateLabel}</span></div>`;
    }
    return `${dateSep}
    <div class="chat-msg-row ${isAdmin ? 'admin' : 'user'}">
      ${!isAdmin ? `<div class="chat-msg-avatar">${(name || 'U')[0].toUpperCase()}</div>` : ''}
      <div class="${bubbleCls}">
        <div class="chat-bubble-text">${escHtml(m.message || '')}</div>
        <div class="chat-bubble-meta">
          <span>${timeStr}</span>
          ${isAdmin && m.is_read ? '<span class="chat-read-tick">✓✓</span>' : isAdmin ? '<span class="chat-read-tick unread">✓</span>' : ''}
        </div>
      </div>
      ${isAdmin ? `<div class="chat-msg-avatar admin">${(window.currentUser?.avatar || 'A')}</div>` : ''}
    </div>`;
  }).join('');

  wrap.innerHTML = html;
  // Scroll to bottom
  wrap.scrollTop = wrap.scrollHeight;
}

// ── Send message ────────────────────────────────────────
window.sendChatMessage = async function() {
  const textarea = document.getElementById('chat-textarea');
  const btn      = document.getElementById('chat-send-btn');
  if (!textarea || !_chatActiveUserId) return;

  const msg = textarea.value.trim();
  if (!msg) return;

  textarea.value = '';
  chatTextareaAutoResize(textarea);
  btn.disabled = true;

  try {
    await _chatApi.sendChatMessage({
      receiverId: _chatActiveUserId,
      message:    msg,
      senderName: _chatAdminName,
      adminId:    _chatAdminId,
    });
    // Optimistically reload
    await refreshChatMessages();
    await loadConversations();
  } catch (e) {
    showToast('Gagal mengirim pesan: ' + e.message, 'error');
    textarea.value = msg; // restore
  } finally {
    btn.disabled = false;
    textarea.focus();
  }
};

window.chatInputKeydown = function(e) {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault();
    sendChatMessage();
  }
};

window.chatTextareaAutoResize = function(el) {
  el.style.height = 'auto';
  el.style.height = Math.min(el.scrollHeight, 120) + 'px';
};

// ── Helpers ─────────────────────────────────────────────
function _chatFmtTime(iso) {
  if (!iso) return '';
  const d   = new Date(iso);
  const now = new Date();
  const diff = now - d;
  if (diff < 60000)     return 'baru saja';
  if (diff < 3600000)   return `${Math.floor(diff / 60000)} mnt lalu`;
  if (diff < 86400000)  return d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
  if (diff < 604800000) return d.toLocaleDateString('id-ID', { weekday: 'short' });
  return d.toLocaleDateString('id-ID', { day: 'numeric', month: 'short' });
}

function _chatFmtMsgTime(iso) {
  if (!iso) return '';
  return new Date(iso).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
}

function _chatFmtDateLabel(iso) {
  if (!iso) return '';
  const d   = new Date(iso);
  const now = new Date();
  const today    = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const yesterday = new Date(today - 86400000);
  const msgDay   = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  if (+msgDay === +today)     return 'Hari Ini';
  if (+msgDay === +yesterday) return 'Kemarin';
  return d.toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' });
}

function escHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
