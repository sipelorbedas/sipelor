// =============================================
// SIPELOR BEDAS — Admin API Layer
// Semua panggilan Supabase ada di sini
// =============================================

/**
 * Detect MIME type from the first bytes of a buffer using file magic bytes.
 * Returns null if the buffer doesn't match any known format.
 * @param {Uint8Array} b
 * @returns {string|null}
 */
function detectMimeFromMagicBytes(b) {
  if (!b || b.length < 4) return null;
  if (b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4E && b[3] === 0x47) return 'image/png';
  if (b[0] === 0xFF && b[1] === 0xD8)                                    return 'image/jpeg';
  if (b[0] === 0x47 && b[1] === 0x49 && b[2] === 0x46)                  return 'image/gif';
  if (b[0] === 0x52 && b[1] === 0x49 && b[2] === 0x46 && b[3] === 0x46) return 'image/webp';
  if (b[0] === 0x25 && b[1] === 0x50 && b[2] === 0x44 && b[3] === 0x46) return 'application/pdf';
  return null;
}

class AdminAPI {
  constructor(supabaseClient) {
    this.db = supabaseClient;
  }

  // ── Dashboard ───────────────────────────────────────────

  async getDashboardStats() {
    if (!this.db) return this._mockStats();
    try {
      const [bookings, revenue, fields, users, pendingPay] = await Promise.all([
        this.db.from('bookings').select('id', { count: 'exact', head: true }),
        this.db.from('bookings').select('total_amount').eq('payment_status', 'verified'),
        this.db.from('fields').select('id', { count: 'exact', head: true }),
        this.db.from('profiles').select('id', { count: 'exact', head: true }),
        this.db.from('bookings').select('id', { count: 'exact', head: true })
             .eq('payment_status', 'pending'),
      ]);
      const totalRevenue = (revenue.data || []).reduce((s, b) => s + (b.total_amount || 0), 0);
      return {
        totalBookings:  bookings.count  || 0,
        totalRevenue,
        totalFields:    fields.count    || 0,
        totalUsers:     users.count     || 0,
        pendingPayments: pendingPay.count || 0,
      };
    } catch { return this._mockStats(); }
  }

  async getRecentBookings(limit = 8) {
    if (!this.db) return this._mockRecentBookings();
    try {
      const { data } = await this.db
        .from('bookings')
        .select('*, fields(venue_name, venue_type, area)')
        .order('created_at', { ascending: false })
        .limit(limit);
      const rows = data || [];

      // Enrich user names via separate profiles query (same pattern as getBookings)
      const userIds = [...new Set(rows.map(b => b.user_id).filter(Boolean))];
      if (userIds.length) {
        try {
          const { data: profiles, error: profilesErr } = await this.db.from('profiles')
            .select('id, full_name, email').in('id', userIds);
          if (profilesErr) {
            console.warn(
              '[SIPELOR] ⚠️ getRecentBookings() profiles query gagal:', profilesErr.message,
              '\n→ RLS profiles kemungkinan memblokir admin membaca data user lain.',
              '\n→ Solusi: Jalankan website/admin/sql/fix_profiles_rls_v2.sql di Supabase SQL Editor.'
            );
          }
          const pm = Object.fromEntries((profiles || []).map(p => [p.id, p]));
          rows.forEach(b => {
            const p = pm[b.user_id];
            if (p) b.user_name = b.user_name || p.full_name || p.email || null;
          });
        } catch (e) {
          console.warn(
            '[SIPELOR] ⚠️ getRecentBookings() profiles enrichment error:', e?.message,
            '\n→ Jalankan fix_profiles_rls_v2.sql di Supabase SQL Editor.'
          );
        }
      }

      // Prioritize name from notes (landing page) or booked_for_label (OPD bookings)
      rows.forEach(b => {
        const notesName = this._parseBookerName(b.notes);
        if (notesName) {
          b.user_name = notesName;
        } else if (b.booked_for_label) {
          b.user_name = b.booked_for_label; // nama OPD / pimpinan
        } else if (!b.user_name) {
          b.user_name = null; // biarkan UI menampilkan fallback yang sesuai
        }
      });

      return rows;
    } catch { return this._mockRecentBookings(); }
  }

  async getMonthlyRevenue(months = 6) {
    if (!this.db) return this._mockMonthlyRevenue(months);
    try {
      const since = new Date();
      since.setMonth(since.getMonth() - months);
      const { data } = await this.db
        .from('bookings')
        .select('total_amount, created_at')
        .eq('payment_status', 'verified')
        .gte('created_at', since.toISOString());
      return this._groupByMonth(data || [], months);
    } catch { return this._mockMonthlyRevenue(months); }
  }

  async getBookingsByStatus() {
    if (!this.db) return { pending: 12, confirmed: 34, completed: 45, cancelled: 9 };
    try {
      const statuses = ['pending','confirmed','completed','cancelled'];
      const results = {};
      for (const s of statuses) {
        const { count } = await this.db.from('bookings')
          .select('id', { count: 'exact', head: true }).eq('status', s);
        results[s] = count || 0;
      }
      return results;
    } catch { return { pending: 12, confirmed: 34, completed: 45, cancelled: 9 }; }
  }

  // ── Bookings ─────────────────────────────────────────────

  async getBookings({ page = 1, limit = 10, status = '', paymentStatus = '', search = '', dateFrom = '', dateTo = '' } = {}) {
    if (!this.db) return { data: this._mockBookings(), count: 20 };
    try {
      // NOTE: bookings.user_id → auth.users(id), NOT profiles.id directly.
      // PostgREST cannot auto-infer the bookings → profiles join, so we query
      // profiles separately to avoid a PGRST200 "relationship not found" error
      // that Supabase JS v2 returns as { data: null, error } (no exception thrown).
      let q = this.db.from('bookings')
        .select(
          '*, fields(venue_name, venue_type, area), payment_proofs(id, file_path, status, created_at)',
          { count: 'exact' }
        )
        .order('created_at', { ascending: false })
        .range((page - 1) * limit, page * limit - 1);
      if (status)        q = q.eq('status', status);
      if (paymentStatus) q = q.eq('payment_status', paymentStatus);
      if (search)        q = q.or(`booking_id.ilike.%${search}%`);
      if (dateFrom)      q = q.gte('booking_date', dateFrom);
      if (dateTo)        q = q.lte('booking_date', dateTo);
      const { data, error, count } = await q;
      // Explicitly throw on error so the catch fallback can handle it
      if (error) throw error;
      const rows = data || [];
      // Enrich user names via separate profiles query (no direct FK needed)
      const userIds = [...new Set(rows.map(b => b.user_id).filter(Boolean))];
      if (userIds.length) {
        try {
          const { data: profiles } = await this.db.from('profiles')
            .select('id, full_name, email').in('id', userIds);
          const pm = Object.fromEntries((profiles || []).map(p => [p.id, p]));
          rows.forEach(b => {
            const p = pm[b.user_id];
            if (p) b.user_name = b.user_name || p.full_name || p.email || '—';
          });
        } catch (_) { /* profiles enrichment is optional */ }
      }
      // Prioritaskan nama dari kolom notes (diisi customer saat booking di landing page).
      // Format: "Pemesan: Nama | HP: 08xxx | ..."
      // Ini mencegah nama admin muncul ketika booking dibuat saat admin sedang login
      // di browser yang sama dengan landing page.
      rows.forEach(b => {
        const notesName = this._parseBookerName(b.notes);
        if (notesName) {
          b.user_name = notesName; // nama customer selalu jadi prioritas
        } else if (!b.user_name || b.user_name === '—') {
          b.user_name = '—';
        }
      });
      // Normalize: expose first proof and resolved user name
      const normalized = rows.map(b => ({
        ...b,
        user_name: b.user_name || '—',
        proof: Array.isArray(b.payment_proofs) && b.payment_proofs.length > 0
          ? b.payment_proofs[0]
          : null,
      }));
      return { data: normalized, count: count || 0 };
    } catch (primaryErr) {
      // Log error — jangan sampai admin mengira data sudah dimuat padahal masih mock
      console.warn(
        '[SIPELOR] ⚠️ getBookings() query utama gagal. Mencoba fallback...\n',
        '→ Error:', primaryErr?.message || primaryErr,
        '\n→ Kemungkinan penyebab: RLS tabel bookings/payment_proofs tidak mengizinkan admin baca semua data.',
        '\n→ Solusi: Jalankan website/admin/sql/fix_rls_fields_and_bookings.sql di Supabase SQL Editor'
      );
      // Fallback: bare bookings + fields join only, enrich separately
      try {
        let q2 = this.db.from('bookings')
          .select('*, fields(venue_name, venue_type, area)', { count: 'exact' })
          .order('created_at', { ascending: false })
          .range((page - 1) * limit, page * limit - 1);
        if (status)        q2 = q2.eq('status', status);
        if (paymentStatus) q2 = q2.eq('payment_status', paymentStatus);
        if (search)        q2 = q2.or(`booking_id.ilike.%${search}%`);
        const { data, error: e2, count } = await q2;
        if (e2) throw e2;
        const rows = data || [];
        // Enrich user names via separate profiles fetch
        const userIds = [...new Set(rows.map(b => b.user_id).filter(Boolean))];
        if (userIds.length) {
          try {
            const { data: profiles } = await this.db.from('profiles')
              .select('id, full_name, email').in('id', userIds);
            const pm = Object.fromEntries((profiles || []).map(p => [p.id, p]));
            rows.forEach(b => {
              const p = pm[b.user_id];
              if (p) b.user_name = b.user_name || p.full_name || p.email || '—';
            });
          } catch (_) {}
        }
        // Prioritaskan nama dari notes (customer input) seperti pada query utama
        rows.forEach(b => {
          const notesName = this._parseBookerName(b.notes);
          if (notesName) b.user_name = notesName;
          else if (!b.user_name || b.user_name === '—') b.user_name = '—';
        });
        // Fallback path: payment_proofs tidak disertakan di query ini.
        // Coba fetch proofs secara terpisah agar kolom Bukti Bayar tetap muncul.
        try {
          const bookingUUIDs = rows.map(r => r.id).filter(Boolean);
          if (bookingUUIDs.length) {
            const { data: proofs } = await this.db
              .from('payment_proofs')
              .select('id, booking_id, file_path, status, created_at')
              .in('booking_id', bookingUUIDs)
              .order('created_at', { ascending: false });
            if (proofs && proofs.length) {
              // Map first proof per booking
              const proofMap = {};
              proofs.forEach(p => { if (!proofMap[p.booking_id]) proofMap[p.booking_id] = p; });
              rows.forEach(b => { b.proof = proofMap[b.id] || null; });
            }
          }
        } catch (_proofErr) {
          // Bukti pembayaran tidak bisa dimuat — kemungkinan policy SELECT payment_proofs
          // belum dijalankan. Admin perlu menjalankan fix_payment_proofs_select_rls.sql.
          console.warn(
            '[SIPELOR] ⚠️ Gagal fetch payment_proofs (fallback). Jalankan fix_payment_proofs_select_rls.sql di Supabase SQL Editor.\n',
            '→ Error:', _proofErr?.message
          );
        }
        return { data: rows, count: count || 0 };
      } catch (fallbackErr) {
        console.error(
          '[SIPELOR] ❌ getBookings() semua query gagal — menampilkan data DEMO!\n',
          '→ Error fallback:', fallbackErr?.message || fallbackErr,
          '\n→ SOLUSI WAJIB: Jalankan website/admin/sql/fix_rls_fields_and_bookings.sql',
          '\n   di Supabase Dashboard → SQL Editor'
        );
        return { data: this._mockBookings(), count: 20 };
      }
    }
  }

  async getBookingById(id) {
    if (!this.db) return this._mockBookings().find(b => b.id === id) || null;
    try {
      // profiles join omitted — no direct FK from bookings to profiles (see getBookings note)
      const { data, error } = await this.db
        .from('bookings')
        .select('*, fields(venue_name, venue_type, area, price_per_hour), payment_proofs(id, file_path, status, created_at)')
        .eq('id', id).single();
      if (error) throw error;
      if (!data) return null;
      // Enrich user name from profiles separately
      let userName = data.user_name || '—';
      if (data.user_id) {
        try {
          const { data: profile } = await this.db.from('profiles')
            .select('full_name, email').eq('id', data.user_id).maybeSingle();
          if (profile) userName = profile.full_name || profile.email || userName;
        } catch (_) {}
      }
      // Prioritaskan nama dari notes (customer input) — override nama profil
      // agar nama admin tidak muncul pada booking dari landing page
      if (data.notes) {
        const fromNotes = this._parseBookerName(data.notes);
        if (fromNotes) userName = fromNotes;
      }
      return {
        ...data,
        user_name: userName,
        proof: Array.isArray(data.payment_proofs) && data.payment_proofs.length > 0
          ? data.payment_proofs[0]
          : null,
      };
    } catch { return null; }
  }

  async updateBookingStatus(id, status) {
    if (!this.db) return true;
    const { error } = await this.db.from('bookings')
      .update({ status, updated_at: new Date().toISOString() }).eq('id', id);
    if (error) throw error;
    return true;
  }

  async updatePaymentStatus(id, paymentStatus) {
    if (!this.db) return true;
    const status = paymentStatus === 'verified' ? 'confirmed' : undefined;
    const upd = { payment_status: paymentStatus, updated_at: new Date().toISOString() };
    if (status) upd.status = status;
    const { error } = await this.db.from('bookings').update(upd).eq('id', id);
    if (error) throw error;
    return true;
  }

  /**
   * Update the status of a payment proof record in payment_proofs table.
   * @param {string} proofId  UUID of the proof record (payment_proofs.id)
   * @param {string} status   'verified' | 'approved' | 'rejected' | 'pending'
   */
  async updateProofStatus(proofId, status) {
    if (!this.db) return true;
    const { error } = await this.db
      .from('payment_proofs')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', proofId);
    if (error) throw error;
    return true;
  }

  /**
   * Get the payment proof record for a booking (from payment_proofs table).
   * @param {string} bookingId  UUID of the booking (bookings.id)
   */
  async getPaymentProof(bookingId) {
    if (!this.db) return null;
    const { data, error } = await this.db
      .from('payment_proofs')
      .select('id, booking_id, file_path, status, created_at')
      .eq('booking_id', bookingId)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();
    // Jangan swallow error — lempar agar caller bisa tampilkan pesan yang tepat
    if (error) throw error;
    return data || null;
  }

  /**
   * Get a viewable URL for the payment proof image.
   * Handles two formats of file_path:
   *   A) Full public URL  – Flutter app stores the full URL directly
   *      e.g. "https://xxx.supabase.co/storage/v1/object/public/payment-proofs/uid/file.jpg"
   *   B) Storage path only (legacy)
   *      e.g. "uid/booking_123.jpg"
   * Returns { url, proof } or null if no proof exists.
   * @param {string} bookingId  UUID of the booking
   */
  async getPaymentProofUrl(bookingId) {
    if (!this.db) return null;
    try {
      const proof = await this.getPaymentProof(bookingId);
      if (!proof?.file_path) return null;

      const fp = proof.file_path;

      // ── CASE 0: data: URL (base64 stored directly from website) ──────────
      if (fp.startsWith('data:')) {
        return { url: fp, proof };
      }

      // ── CASE A: file_path is a full URL (Flutter stores full public URL) ──────
      if (fp.startsWith('http://') || fp.startsWith('https://')) {
        // Extract the storage path from the URL, then try to generate a signed URL.
        // URL format: .../storage/v1/object/public/payment-proofs/<storagePath>
        try {
          const u        = new URL(fp);
          const parts    = u.pathname.split('/');
          const bktIdx   = parts.indexOf('payment-proofs');
          if (bktIdx !== -1 && bktIdx < parts.length - 1) {
            const storagePath = decodeURIComponent(
              parts.slice(bktIdx + 1).join('/')
            );
            const { data, error } = await this.db.storage
              .from('payment-proofs')
              .createSignedUrl(storagePath, 3600);
            if (!error && data?.signedUrl) return { url: data.signedUrl, proof };
          }
        } catch (_) { /* fall through — use the URL directly */ }

        // Fallback: return the public URL as-is
        return { url: fp, proof };
      }

      // ── CASE B: file_path is a bare storage path (old format) ────────────────
      try {
        const { data, error } = await this.db.storage
          .from('payment-proofs')
          .createSignedUrl(fp, 3600);
        if (!error && data?.signedUrl) return { url: data.signedUrl, proof };
      } catch (_) { /* fall through */ }

      // Last resort: public URL from storage path
      const { data: pubData } = this.db.storage
        .from('payment-proofs')
        .getPublicUrl(fp);
      return pubData?.publicUrl ? { url: pubData.publicUrl, proof } : null;
    } catch { return null; }
  }

  /**
   * Get a decrypted blob URL for the payment proof image.
   *
   * Flutter's FileEncryptionService encrypts every file before upload using:
   *   Algorithm : AES-256-CTR (SIC mode in PointyCastle / encrypt ^5.0.3)
   *   Key       : SHA-256( "SIPELOR_FILE_ENCRYPTION_2026" )
   *   Format    : iv_bytes[16] | ciphertext_bytes
   *
   * This method:
   *   1. Fetches the encrypted bytes from Supabase Storage (via signed URL or
   *      the Supabase storage SDK so auth headers are handled automatically).
   *   2. Decrypts using the Web Crypto API (AES-CTR, length=128 → full-block
   *      counter, matching Bouncy Castle SIC behaviour).
   *   3. Detects the MIME type from magic bytes, wraps the result in a Blob
   *      URL, and returns { url: blobUrl, proof, mimeType }.
   *   4. Falls back to the raw URL if decryption fails (handles legacy
   *      unencrypted uploads gracefully).
   *
   * @param {string} bookingId  UUID of the booking
   */
  async getDecryptedPaymentProofBlobUrl(bookingId) {
    const result = await this.getPaymentProofUrl(bookingId);
    if (!result) return null;
    const { url, proof } = result;

    // ── data: URL (base64 dari website) — tidak perlu decrypt ────────────
    if (url && url.startsWith('data:')) {
      const mimeType = url.split(';')[0].replace('data:', '') || 'image/jpeg';
      return { url, proof, mimeType, isDecrypted: false };
    }

    try {
      // ── Step 1: Download the raw (encrypted) bytes ───────────────────────
      let encryptedBlob = null;

      // Prefer Supabase SDK download() — it attaches the auth token automatically
      // so it works for private buckets too.
      if (this.db && proof?.file_path) {
        const storagePath = this._extractStoragePath(proof.file_path);
        if (storagePath) {
          const { data, error } = await this.db.storage
            .from('payment-proofs')
            .download(storagePath);
          if (!error && data) encryptedBlob = data;
        }
      }

      // Fallback: fetch the signed / public URL directly
      if (!encryptedBlob) {
        const res = await fetch(url);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        encryptedBlob = await res.blob();
      }

      // ── Step 2: Detect if file is already a plain image (website upload) ─
      const encryptedBytes = new Uint8Array(await encryptedBlob.arrayBuffer());
      const plainMime = detectMimeFromMagicBytes(encryptedBytes);
      if (plainMime) {
        // File is NOT encrypted (uploaded from website) — use raw bytes directly.
        const blobUrl = URL.createObjectURL(new Blob([encryptedBytes], { type: plainMime }));
        return { url: blobUrl, proof, mimeType: plainMime, isDecrypted: false };
      }

      // ── Step 3: Decrypt (Flutter-encrypted upload) ───────────────────────
      const { blobUrl, mimeType } = await this._decryptToBlob(encryptedBytes);
      return { url: blobUrl, proof, mimeType, isDecrypted: true };

    } catch (e) {
      console.warn('[SIPELOR] Proof decrypt failed, using raw URL:', e.message);
      // Graceful fallback for unencrypted files (website upload) or when crypto fails.
      // Infer mimeType from file extension so isImage check in loadProofSection works.
      const ext = (proof?.file_path || url || '').split('?')[0].split('.').pop().toLowerCase();
      const extMime = {
        jpg: 'image/jpeg', jpeg: 'image/jpeg', png: 'image/png',
        webp: 'image/webp', gif: 'image/gif', pdf: 'application/pdf',
      }[ext] || null;
      return { url, proof, mimeType: extMime };
    }
  }

  /**
   * Extract the Supabase storage path from a file_path value which may be
   * either a full public URL or a bare storage path.
   * @param {string} filePath
   * @returns {string|null}
   */
  _extractStoragePath(filePath) {
    if (!filePath) return null;
    if (!filePath.startsWith('http')) return filePath; // already a bare path
    try {
      const parts = new URL(filePath).pathname.split('/');
      const idx = parts.indexOf('payment-proofs');
      if (idx !== -1 && idx < parts.length - 1) {
        return decodeURIComponent(parts.slice(idx + 1).join('/'));
      }
    } catch (_) { /* ignore malformed URLs */ }
    return null;
  }

  /**
   * AES-CTR decryption using the Web Crypto API.
   * Matches Flutter's FileEncryptionService (encrypt ^5.0.3, AESMode.sic).
   *
   * Key    = SHA-256("SIPELOR_FILE_ENCRYPTION_2026")
   * Format = iv[16] | ciphertext
   * Mode   = AES-CTR, full-block counter (length=128 bits)
   *
   * @param {Uint8Array} encryptedData
   * @returns {{ blobUrl: string, mimeType: string }}
   */
  async _decryptToBlob(encryptedData) {
    const IV_LEN = 16;
    if (encryptedData.length <= IV_LEN) throw new Error('Encrypted data too short');

    // Derive key: SHA-256 of the shared app salt (same constant as Flutter)
    const keyBytes = await crypto.subtle.digest(
      'SHA-256',
      new TextEncoder().encode('SIPELOR_FILE_ENCRYPTION_2026')
    );
    const key = await crypto.subtle.importKey(
      'raw', keyBytes, { name: 'AES-CTR' }, false, ['decrypt']
    );

    // Split IV and ciphertext
    const counter   = encryptedData.slice(0, IV_LEN);
    const ciphertext = encryptedData.slice(IV_LEN);

    // Decrypt — length:128 means the entire 16-byte block is the counter,
    // matching Bouncy Castle SIC (full-block big-endian increment).
    const decrypted = await crypto.subtle.decrypt(
      { name: 'AES-CTR', counter, length: 128 },
      key,
      ciphertext
    );

    // Detect MIME type from magic bytes of decrypted data.
    const mimeType = detectMimeFromMagicBytes(new Uint8Array(decrypted));

    if (!mimeType) {
      // Decrypted bytes don't match any known format — key mismatch or corrupt data.
      throw new Error('Unknown format after decryption — decryption key mismatch or corrupt file');
    }

    const blobUrl = URL.createObjectURL(new Blob([decrypted], { type: mimeType }));
    return { blobUrl, mimeType };
  }

  // ── Fields ───────────────────────────────────────────────

  async getFields({ page = 1, limit = 10, status = '', search = '' } = {}) {
    if (!this.db) return { data: this._mockFields(), count: 6 };
    try {
      let q = this.db.from('fields')
        .select('*', { count: 'exact' })
        .order('created_at', { ascending: false })
        .range((page - 1) * limit, page * limit - 1);
      if (status) q = q.eq('status', status);
      if (search) q = q.or(`venue_name.ilike.%${search}%,venue_type.ilike.%${search}%`);
      const { data, count } = await q;
      return { data: data || [], count: count || 0 };
    } catch { return { data: this._mockFields(), count: 6 }; }
  }

  async createField(payload) {
    if (!this.db) return { id: Date.now().toString(), ...payload };
    const { data, error } = await this.db.from('fields').insert(payload).select().single();
    if (error) throw error;
    return data;
  }

  async updateField(id, payload) {
    if (!this.db) return true;
    const { error } = await this.db.from('fields')
      .update({ ...payload, updated_at: new Date().toISOString() }).eq('id', id);
    if (error) throw error;
    return true;
  }

  async deleteField(id) {
    if (!this.db) return true;
    const { error } = await this.db.from('fields').delete().eq('id', id);
    if (error) throw error;
    return true;
  }

  /**
   * Upload satu foto lapangan ke bucket `field-images` (public).
   * @param {File} file  File dari input[type=file]
   * @returns {{ publicUrl: string, storagePath: string }}
   */
  async uploadFieldImage(file) {
    if (!this.db) throw new Error('Supabase tidak terhubung');
    const ext = file.name.split('.').pop().toLowerCase();
    const storagePath = `fields/${Date.now()}_${Math.random().toString(36).slice(2)}.${ext}`;
    const { error } = await this.db.storage
      .from('field-images')
      .upload(storagePath, file, { cacheControl: '3600', upsert: false });
    if (error) throw error;
    const publicUrl = this.db.storage.from('field-images').getPublicUrl(storagePath).data.publicUrl;
    return { publicUrl, storagePath };
  }

  // ── Staff ────────────────────────────────────────────────

  async getStaff({ page = 1, limit = 10, role = '', search = '' } = {}) {
    if (!this.db) return { data: this._mockStaff(), count: 4 };
    try {
      let q = this.db.from('staff')
        .select('*', { count: 'exact' })
        .order('created_at', { ascending: false })
        .range((page - 1) * limit, page * limit - 1);
      if (role)   q = q.eq('role', role);
      if (search) q = q.or(`name.ilike.%${search}%,email.ilike.%${search}%`);
      const { data, count } = await q;
      return { data: data || [], count: count || 0 };
    } catch { return { data: this._mockStaff(), count: 4 }; }
  }

  async createStaff(payload) {
    if (!this.db) return { id: Date.now().toString(), ...payload };
    const { data, error } = await this.db.from('staff').insert(payload).select().single();
    if (error) throw error;
    return data;
  }

  async updateStaff(id, payload) {
    if (!this.db) return true;
    const { error } = await this.db.from('staff')
      .update({ ...payload, updated_at: new Date().toISOString() }).eq('id', id);
    if (error) throw error;
    return true;
  }

  async deleteStaff(id) {
    if (!this.db) return true;
    const { error } = await this.db.from('staff').delete().eq('id', id);
    if (error) throw error;
    return true;
  }

  // ── Reviews ──────────────────────────────────────────────

  async getReviews({ page = 1, limit = 10, rating = '', search = '' } = {}) {
    if (!this.db) return { data: this._mockReviews(), count: 10 };
    try {
      let data = null, count = 0;

      // Attempt 1: with bookings→fields join to get venue_name
      try {
        let q = this.db.from('reviews')
          .select('*, bookings(booking_id, fields(venue_name))', { count: 'exact' })
          .order('created_at', { ascending: false })
          .range((page - 1) * limit, page * limit - 1);
        if (rating) q = q.eq('rating', parseInt(rating));
        if (search) q = q.ilike('comment', `%${search}%`);
        const res = await q;
        if (!res.error && Array.isArray(res.data)) { data = res.data; count = res.count || 0; }
      } catch (_) { /* try fallback */ }

      // Attempt 2: plain select (no joins) if join above failed
      if (!data) {
        let q = this.db.from('reviews')
          .select('*', { count: 'exact' })
          .order('created_at', { ascending: false })
          .range((page - 1) * limit, page * limit - 1);
        if (rating) q = q.eq('rating', parseInt(rating));
        if (search) q = q.ilike('comment', `%${search}%`);
        const res = await q;
        if (!res.error) { data = res.data; count = res.count || 0; }
      }

      data = data || [];

      // Separately enrich with profile names (avoids FK dependency)
      if (data.length) {
        try {
          const userIds = [...new Set(data.map(r => r.user_id).filter(Boolean))];
          if (userIds.length) {
            const { data: profiles } = await this.db.from('profiles')
              .select('id, full_name, email').in('id', userIds);
            if (profiles) {
              const pm = Object.fromEntries(profiles.map(p => [p.id, p]));
              data = data.map(r => ({ ...r, profiles: r.profiles || pm[r.user_id] || null }));
            }
          }
        } catch (_) { /* profiles enrichment optional */ }
      }

      return { data, count };
    } catch { return { data: this._mockReviews(), count: 10 }; }
  }

  async deleteReview(id) {
    if (!this.db) return true;
    const { error } = await this.db.from('reviews').delete().eq('id', id);
    if (error) throw error;
    return true;
  }

  // ── Audit Logs ───────────────────────────────────────────

  async getAuditLogs({ page = 1, limit = 15, action = '', search = '' } = {}) {
    if (!this.db) return { data: this._mockAuditLogs(), count: 20 };
    try {
      let q = this.db.from('audit_logs')
        .select('*, profiles(full_name, email)', { count: 'exact' })
        .order('created_at', { ascending: false })
        .range((page - 1) * limit, page * limit - 1);
      if (action) q = q.eq('action', action);
      const { data, count } = await q;
      return { data: data || [], count: count || 0 };
    } catch { return { data: this._mockAuditLogs(), count: 20 }; }
  }

  // ── Users ────────────────────────────────────────────────

  async getUsers({ page = 1, limit = 10, search = '' } = {}) {
    if (!this.db) return { data: this._mockUsers(), count: 8 };
    try {
      let q = this.db.from('profiles')
        .select('*', { count: 'exact' })
        .eq('role', 'user')
        .order('created_at', { ascending: false })
        .range((page - 1) * limit, page * limit - 1);
      if (search) q = q.or(`full_name.ilike.%${search}%,email.ilike.%${search}%`);
      const { data, count } = await q;
      return { data: data || [], count: count || 0 };
    } catch { return { data: this._mockUsers(), count: 8 }; }
  }

  // ══════════════════════════════════════════════════════════
  // MOCK DATA (digunakan ketika Supabase belum dikonfigurasi)
  // ══════════════════════════════════════════════════════════

  _mockStats() {
    return {
      totalBookings: 127,
      totalRevenue: 15750000,
      totalFields: 6,
      totalUsers: 284,
      pendingPayments: 8,
    };
  }

  _mockRecentBookings() {
    const statuses = ['pending','confirmed','completed','cancelled'];
    const pay = ['pending','verified','rejected'];
    const fields = ['Lapangan Futsal A','Lapangan Badminton 1','Lapangan Tenis B','GOR Volly'];
    const users  = ['Budi Santoso','Siti Rahayu','Ahmad Fauzi','Dewi Lestari','Randi Purnama'];
    return Array.from({ length: 8 }, (_, i) => {
      // Mock: even-indexed bookings have a proof, odd ones don't
      const hasProof = i % 2 === 0;
      const proof = hasProof ? {
        id: `proof-${i}`,
        booking_id: `booking-${i + 1}`,
        file_path: `demo/proof_booking_${i + 1}.jpg`,
        status: pay[i % 3] === 'verified' ? 'approved' : 'pending',
        created_at: new Date(Date.now() - i * 3600000).toISOString(),
      } : null;
      return {
        id: `booking-${i + 1}`,
        booking_id: `BOOK${String(1000 + i).padStart(4, '0')}`,
        user_id: `user-${i}`,
        user_name: users[i % users.length],
        booking_date: new Date(Date.now() - i * 86400000).toISOString().split('T')[0],
        start_time: `${8 + i}:00`, end_time: `${10 + i}:00`,
        duration_hours: 2,
        total_amount: (i + 1) * 75000,
        status: statuses[i % 4],
        payment_status: pay[i % 3],
        fields: { venue_name: fields[i % 4], venue_type: 'Futsal', area: `Area ${String.fromCharCode(65 + (i % 3))}` },
        created_at: new Date(Date.now() - i * 86400000).toISOString(),
        proof,
      };
    });
  }

  _mockMonthlyRevenue(n) {
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    const now = new Date();
    return Array.from({ length: n }, (_, i) => {
      const d = new Date(now.getFullYear(), now.getMonth() - (n - 1 - i), 1);
      return {
        month: months[d.getMonth()],
        revenue: Math.floor(Math.random() * 8000000) + 1500000,
        bookings: Math.floor(Math.random() * 30) + 10,
      };
    });
  }

  _mockBookings() {
    return this._mockRecentBookings().concat(
      Array.from({ length: 12 }, (_, i) => ({
        id: `booking-extra-${i}`,
        booking_id: `BOOK${String(2000 + i).padStart(4, '0')}`,
        user_name: 'User Demo',
        booking_date: new Date(Date.now() - (i + 10) * 86400000).toISOString().split('T')[0],
        start_time: '09:00', end_time: '11:00',
        duration_hours: 2,
        total_amount: 150000,
        status: 'completed',
        payment_status: 'verified',
        fields: { venue_name: 'Lapangan Futsal B', venue_type: 'Futsal', area: 'B' },
        created_at: new Date(Date.now() - (i + 10) * 86400000).toISOString(),
      }))
    );
  }

  _mockFields() {
    return [
      { id:'f1', venue_name:'GOR Sabilulungan', venue_type:'Futsal',   area:'Lantai 1', price_per_hour:80000,  status:'available',   image_urls:[], ukuran_lapangan:'16.8x24.95m', kapasitas:'14 orang', tempat_parkir:true, mushola:true, cctv:true, ruang_tunggu:true, ruang_ganti:true, created_at: new Date().toISOString() },
      { id:'f2', venue_name:'Gor Sabilulungan', venue_type:'Badminton', area:'Hall B',   price_per_hour:60000,  status:'available',   image_urls:[], kapasitas:'8 orang',  tempat_parkir:true, mushola:true, cctv:true, created_at: new Date().toISOString() },
      { id:'f3', venue_name:'Arena Tenis DISPORA', venue_type:'Tenis',  area:'Court A',  price_per_hour:100000, status:'maintenance', image_urls:[], kapasitas:'4 orang',  cctv:true, created_at: new Date().toISOString() },
      { id:'f4', venue_name:'GOR Volly Bedas',  venue_type:'Volly',    area:'Utama',    price_per_hour:90000,  status:'available',   image_urls:[], kapasitas:'12 orang', tempat_parkir:true, cctv:true, created_at: new Date().toISOString() },
      { id:'f5', venue_name:'Lapangan Basket',  venue_type:'Basket',   area:'Outdoor',  price_per_hour:70000,  status:'available',   image_urls:[], kapasitas:'10 orang', created_at: new Date().toISOString() },
      { id:'f6', venue_name:'GOR Bulu Tangkis', venue_type:'Badminton', area:'Hall C',   price_per_hour:55000,  status:'booked',      image_urls:[], kapasitas:'6 orang',  mushola:true, created_at: new Date().toISOString() },
    ];
  }

  _mockStaff() {
    return [
      { id:'s1', name:'Admin Utama',     email:'admin@sipelor.com',    phone:'081234567890', role:'admin',    is_active:true,  last_login: new Date().toISOString(),        assigned_venues:['f1','f2'], created_at: new Date().toISOString() },
      { id:'s2', name:'Budi Manager',    email:'budi@sipelor.com',     phone:'082345678901', role:'manager',  is_active:true,  last_login: new Date(Date.now()-3600000).toISOString(), assigned_venues:['f1'], created_at: new Date().toISOString() },
      { id:'s3', name:'Siti Operator',   email:'siti@sipelor.com',     phone:'083456789012', role:'operator', is_active:true,  last_login: new Date(Date.now()-86400000).toISOString(), assigned_venues:['f2','f3'], created_at: new Date().toISOString() },
      { id:'s4', name:'Dani Operator',   email:'dani@sipelor.com',     phone:'084567890123', role:'operator', is_active:false, last_login: null, assigned_venues:[], created_at: new Date().toISOString() },
    ];
  }

  _mockReviews() {
    const comments = [
      'Lapangan bersih dan terawat, puas banget!',
      'Pelayanannya ramah, booking mudah.',
      'Harga terjangkau, fasilitas lengkap.',
      'Parkir luas, lapangan bagus.',
      'Agak susah konfirmasi pembayaran.',
    ];
    return Array.from({ length: 10 }, (_, i) => ({
      id: `r${i}`,
      booking_id: `booking-${i}`,
      user_id: `user-${i}`,
      rating: Math.floor(Math.random() * 3) + 3,
      comment: comments[i % comments.length],
      created_at: new Date(Date.now() - i * 3600000).toISOString(),
      profiles: { full_name: `User ${i + 1}`, email: `user${i + 1}@example.com` },
      venue_name: 'Lapangan Futsal A',
    }));
  }

  _mockAuditLogs() {
    const actions = ['booking_approved','booking_rejected','field_updated','staff_added','payment_verified'];
    const admins  = ['Admin Utama','Budi Manager','Siti Operator'];
    return Array.from({ length: 20 }, (_, i) => ({
      id: `al-${i}`,
      action: actions[i % actions.length],
      entity_type: 'booking',
      entity_id: `booking-${i}`,
      details: JSON.stringify({ note: 'Aksi dilakukan via admin dashboard' }),
      ip_address: `192.168.1.${10 + (i % 20)}`,
      created_at: new Date(Date.now() - i * 1800000).toISOString(),
      profiles: { full_name: admins[i % admins.length], email: 'admin@sipelor.com' },
    }));
  }

  _mockUsers() {
    const names = ['Budi Santoso','Siti Rahayu','Ahmad Fauzi','Dewi Lestari','Randi Purnama','Hana Pratiwi','Dika Wijaya','Lina Sari'];
    return names.map((name, i) => ({
      id: `u${i}`,
      full_name: name,
      email: `${name.split(' ')[0].toLowerCase()}@example.com`,
      phone: `08${String(i).padStart(9,'0')}`,
      role: 'user',
      created_at: new Date(Date.now() - i * 86400000 * 3).toISOString(),
      last_sign_in_at: new Date(Date.now() - i * 3600000).toISOString(),
    }));
  }

  // ── Booking Notes Parser ─────────────────────────────────────

  /**
   * Ekstrak nama pemesan dari kolom notes booking dari landing page.
   * Format: "Pemesan: Nama | HP: 0812xxx | Email: ... | Catatan: ..."
   * @param {string|null} notes
   * @returns {string|null}
   */
  _parseBookerName(notes) {
    if (!notes) return null;
    const m = String(notes).match(/Pemesan:\s*([^|]+)/);
    return m ? m[1].trim() : null;
  }

  /**
   * Ekstrak nomor HP pemesan dari kolom notes booking dari landing page.
   * @param {string|null} notes
   * @returns {string|null}
   */
  _parseBookerPhone(notes) {
    if (!notes) return null;
    const m = String(notes).match(/HP:\s*([^|]+)/);
    return m ? m[1].trim() : null;
  }

  // ── OPD / Pimpinan ───────────────────────────────────────────

  /**
   * Ambil daftar OPD. Jika active=true, hanya yang aktif.
   */
  async getOPDList({ active = false } = {}) {
    if (!this.db) return this._mockOPDList();
    try {
      let q = this.db.from('opd_organizations')
        .select('*')
        .order('name', { ascending: true });
      if (active) q = q.eq('is_active', true);
      const { data, error } = await q;
      if (error) throw error;
      return data || [];
    } catch (e) {
      console.warn('[SIPELOR] getOPDList error:', e.message);
      return this._mockOPDList();
    }
  }

  async createOPD(payload) {
    if (!this.db) return { id: Date.now().toString(), ...payload };
    const { data, error } = await this.db
      .from('opd_organizations')
      .insert({ ...payload, created_at: new Date().toISOString(), updated_at: new Date().toISOString() })
      .select().single();
    if (error) {
      // Kolom discount_percentage belum ada → coba tanpa kolom diskon
      // Jalankan: website/admin/sql/add_opd_discount.sql di Supabase SQL Editor
      if (error.message?.includes('discount_percentage')) {
        const { discount_percentage, ...safePayload } = payload;
        const { data: d2, error: e2 } = await this.db
          .from('opd_organizations')
          .insert({ ...safePayload, created_at: new Date().toISOString(), updated_at: new Date().toISOString() })
          .select().single();
        if (e2) throw e2;
        console.warn('[SIPELOR] Kolom discount_percentage belum ada di database. Jalankan add_opd_discount.sql');
        return d2;
      }
      throw error;
    }
    return data;
  }

  async updateOPD(id, payload) {
    if (!this.db) return true;
    const { error } = await this.db
      .from('opd_organizations')
      .update({ ...payload, updated_at: new Date().toISOString() })
      .eq('id', id);
    if (error) {
      // Kolom discount_percentage belum ada → coba tanpa kolom diskon
      if (error.message?.includes('discount_percentage')) {
        const { discount_percentage, ...safePayload } = payload;
        const { error: e2 } = await this.db
          .from('opd_organizations')
          .update({ ...safePayload, updated_at: new Date().toISOString() })
          .eq('id', id);
        if (e2) throw e2;
        console.warn('[SIPELOR] Kolom discount_percentage belum ada di database. Jalankan add_opd_discount.sql');
        return true;
      }
      throw error;
    }
    return true;
  }

  async deleteOPD(id) {
    if (!this.db) return true;
    const { error } = await this.db.from('opd_organizations').delete().eq('id', id);
    if (error) throw error;
    return true;
  }

  /**
   * Buat booking atas nama OPD / Pimpinan (blokir jadwal).
   * Admin yang menginput, tidak perlu akun OPD terpisah.
   */
  async createOPDBooking(payload) {
    if (!this.db) return { id: Date.now().toString(), booking_id: `OPD${Date.now()}`, ...payload };
    const { data: { user } } = await this.db.auth.getUser();
    const userId = user?.id || '00000000-0000-0000-0000-000000000000';
    const ts = Date.now().toString().slice(-6);
    const bookingId = `OPD${ts}`;

    // ── Selalu hitung end_time dari start_time + duration_hours ──────────────
    // Ini memastikan end_time selalu benar, terlepas dari nilai yang dikirim form
    // parseInt() penting: mencegah string-concatenation jika payload.duration_hours adalah string
    const durHours    = parseInt(payload.duration_hours || 1, 10);
    const startHour   = parseInt((payload.start_time || '06:00').split(':')[0], 10);
    const endHour     = startHour + durHours;
    const computedEnd = `${endHour.toString().padStart(2, '0')}:00`;

    // ── Hitung total_amount berdasarkan harga lapangan & diskon OPD ─────────
    // payload.price_per_hour  = harga/jam lapangan yang dipilih
    // payload.discount_percentage = diskon OPD (0–100)
    const pricePerHour      = parseFloat(payload.price_per_hour || 0);
    const discountPct       = parseFloat(payload.discount_percentage || 0);
    const baseAmount        = pricePerHour * durHours;
    const discountAmount    = Math.round(baseAmount * discountPct / 100);
    const totalAmount       = Math.max(0, baseAmount - discountAmount);

    const insert = {
      booking_id:          bookingId,
      user_id:             userId,
      field_id:            payload.field_id,
      venue_id:            payload.field_id,
      booking_date:        payload.booking_date,
      start_time:          payload.start_time,
      end_time:            computedEnd,          // ← selalu dihitung ulang
      duration_hours:      durHours,
      total_amount:        totalAmount,
      discount_percentage: discountPct,
      discount_amount:     discountAmount,
      status:              'confirmed',
      payment_status:      'verified',
      booking_type:        payload.booking_type || 'opd',
      opd_id:              payload.opd_id || null,
      booked_for_label:    payload.booked_for_label || null,
      notes:               payload.notes || null,
      created_at:          new Date().toISOString(),
      updated_at:          new Date().toISOString(),
    };
    const { data, error } = await this.db
      .from('bookings').insert(insert).select().single();
    if (error) throw error;
    return data;
  }

  async getOPDBookings({ page = 1, limit = 10 } = {}) {
    if (!this.db) return { data: [], count: 0 };
    try {
      const { data, count, error } = await this.db
        .from('bookings')
        .select('*, fields(venue_name, venue_type, area), opd_organizations(name)', { count: 'exact' })
        .neq('booking_type', 'regular')
        .order('booking_date', { ascending: false })
        .range((page - 1) * limit, page * limit - 1);
      if (error) throw error;
      return { data: data || [], count: count || 0 };
    } catch (e) {
      console.warn('[SIPELOR] getOPDBookings error:', e.message);
      return { data: [], count: 0 };
    }
  }

  async deleteOPDBooking(id) {
    if (!this.db) return true;
    const { error } = await this.db.from('bookings').delete().eq('id', id);
    if (error) throw error;
    return true;
  }

  _mockOPDList() {
    return [
      { id: 'opd1', name: 'Bupati / Pimpinan Daerah',  contact_person: 'Sekretariat Daerah', phone: '022-5891234', email: 'setda@bandungkab.go.id',   is_active: true,  discount_percentage: 100 },
      { id: 'opd2', name: 'Dinas Pendidikan',           contact_person: 'Kepala Dinas',       phone: '022-5891235', email: 'disdik@bandungkab.go.id',  is_active: true,  discount_percentage: 50  },
      { id: 'opd3', name: 'Dinas Pemuda dan Olahraga',  contact_person: 'Kepala Dinas',       phone: '022-5891237', email: 'dispora@bandungkab.go.id', is_active: true,  discount_percentage: 75  },
    ];
  }

  // ── Chat ─────────────────────────────────────────────────

  /**
   * Get list of conversations grouped by non-admin user.
   * Returns [{ userId, userName, lastMessage, lastTime, unreadCount }]
   */
  async getChatConversations() {
    if (!this.db) return this._mockConversations();
    try {
      const { data } = await this.db
        .from('chat_messages')
        .select('*')
        .order('created_at', { ascending: false });

      if (!data || !data.length) return [];

      // Group by user (non-admin sender OR receiver that is a user)
      const map = {}; // userId → { userName, messages[] }
      for (const m of data) {
        const userId   = m.is_admin ? m.receiver_id : m.sender_id;
        const userName = m.is_admin ? null : m.sender_name;
        if (!userId) continue;
        if (!map[userId]) map[userId] = { userId, userName: userName || 'Pengguna', messages: [] };
        map[userId].messages.push(m);
        if (userName && !map[userId].userName) map[userId].userName = userName;
      }

      // Build conversation summaries
      const convs = Object.values(map).map(({ userId, userName, messages }) => {
        const sorted  = [...messages].sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
        const last    = sorted[0];
        const unread  = messages.filter(m => !m.is_admin && !m.is_read).length;
        return { userId, userName, lastMessage: last?.message || '', lastTime: last?.created_at || null, unreadCount: unread };
      });

      // Enrich names from profiles for receiver-only entries
      const withoutNames = convs.filter(c => !c.userName || c.userName === 'Pengguna');
      if (withoutNames.length) {
        const ids = withoutNames.map(c => c.userId);
        try {
          const { data: profiles } = await this.db.from('profiles').select('id, full_name').in('id', ids);
          (profiles || []).forEach(p => {
            const c = convs.find(c => c.userId === p.id);
            if (c && p.full_name) c.userName = p.full_name;
          });
        } catch (_) {}
      }

      return convs.sort((a, b) => new Date(b.lastTime || 0) - new Date(a.lastTime || 0));
    } catch (e) {
      console.error('[SIPELOR] getChatConversations error:', e);
      return this._mockConversations();
    }
  }

  /**
   * Get messages for a specific user conversation.
   * Returns messages ordered ascending (oldest first).
   */
  async getChatMessages(userId) {
    if (!this.db) return this._mockMessages(userId);
    try {
      const { data } = await this.db
        .from('chat_messages')
        .select('*')
        .or(`sender_id.eq.${userId},receiver_id.eq.${userId}`)
        .order('created_at', { ascending: true })
        .limit(200);
      return data || [];
    } catch (e) {
      console.error('[SIPELOR] getChatMessages error:', e);
      return this._mockMessages(userId);
    }
  }

  /**
   * Send a chat message as admin to a user.
   * Uses SECURITY DEFINER RPC (bypasses RLS) with direct-insert fallback.
   * @param {string} receiverId  User UUID
   * @param {string} message     Text to send
   * @param {string} senderName  Admin name
   * @param {string} adminId     Admin UUID (from currentUser)
   */
  async sendChatMessage({ receiverId, message, senderName, adminId }) {
    if (!this.db) {
      // Mock: push to local mock store
      return { id: Date.now().toString(), sender_id: adminId || 'admin', sender_name: senderName || 'Admin', receiver_id: receiverId, is_admin: true, message, is_read: false, created_at: new Date().toISOString() };
    }

    // Primary: SECURITY DEFINER RPC — melewati RLS sepenuhnya
    try {
      const { data, error } = await this.db.rpc('admin_send_chat_message', {
        p_receiver_id: receiverId,
        p_message:     message,
        p_sender_name: senderName,
      });
      if (!error && data) {
        return Array.isArray(data) ? data[0] : data;
      }
      if (error) console.warn('[SIPELOR] RPC sendChat error:', error.message);
    } catch (rpcErr) {
      console.warn('[SIPELOR] RPC sendChat failed, mencoba insert langsung:', rpcErr.message);
    }

    // Fallback: direct insert (butuh RLS policy yang benar — jalankan fix_chat_rls.sql)
    const { data, error } = await this.db
      .from('chat_messages')
      .insert({ sender_id: adminId, sender_name: senderName, receiver_id: receiverId, is_admin: true, message, is_read: false })
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  /** Mark all messages from userId as read (admin reading user messages) */
  async markChatRead(userId) {
    if (!this.db) return;
    try {
      await this.db
        .from('chat_messages')
        .update({ is_read: true })
        .eq('sender_id', userId)
        .eq('is_read', false);
    } catch (e) {
      console.warn('[SIPELOR] markChatRead error:', e);
    }
  }

  /**
   * Subscribe to realtime chat updates for a given userId conversation.
   * @param {string}   userId    User UUID
   * @param {Function} callback  Called with latest messages array
   * @returns Supabase channel (call .unsubscribe() to stop)
   */
  subscribeChatMessages(userId, callback) {
    if (!this.db) return null;
    const channel = this.db
      .channel(`chat_${userId}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'chat_messages' }, async () => {
        const msgs = await this.getChatMessages(userId);
        callback(msgs);
      })
      .subscribe();
    return channel;
  }

  /** Subscribe to conversation list updates (new messages from any user) */
  subscribeConversations(callback) {
    if (!this.db) return null;
    const channel = this.db
      .channel('chat_conversations')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'chat_messages' }, async () => {
        const convs = await this.getChatConversations();
        callback(convs);
      })
      .subscribe();
    return channel;
  }

  // ── Chat Mock Data ─────────────────────────────────────
  _mockConversations() {
    const users = [
      { userId: 'u1', userName: 'Budi Santoso' },
      { userId: 'u2', userName: 'Siti Rahayu' },
      { userId: 'u3', userName: 'Ahmad Fauzi' },
    ];
    const msgs = ['Halo admin, saya mau tanya soal booking', 'Kapan lapangan tersedia?', 'Terima kasih atas bantuannya!'];
    return users.map((u, i) => ({
      ...u,
      lastMessage: msgs[i],
      lastTime: new Date(Date.now() - i * 3600000).toISOString(),
      unreadCount: i === 0 ? 2 : 0,
    }));
  }

  _mockMessages(userId) {
    return [
      { id: '1', sender_id: userId, sender_name: 'User', is_admin: false, receiver_id: null, message: 'Halo admin, ada yang ingin saya tanyakan', is_read: true, created_at: new Date(Date.now() - 3600000).toISOString() },
      { id: '2', sender_id: 'admin', sender_name: 'Admin', is_admin: true, receiver_id: userId, message: 'Halo! Silakan, ada yang bisa kami bantu?', is_read: true, created_at: new Date(Date.now() - 3500000).toISOString() },
      { id: '3', sender_id: userId, sender_name: 'User', is_admin: false, receiver_id: null, message: 'Apakah lapangan futsal tersedia besok jam 10 pagi?', is_read: false, created_at: new Date(Date.now() - 600000).toISOString() },
    ];
  }

  // ── Carousel Banners ─────────────────────────────────────

  /**
   * Ambil semua banner carousel (aktif & nonaktif), diurutkan sort_order.
   */
  async getCarouselBanners() {
    if (!this.db) return this._mockCarouselBanners();
    try {
      const { data, error } = await this.db
        .from('carousel_banners')
        .select('*')
        .order('sort_order', { ascending: true });
      if (error) throw error;
      return data || [];
    } catch (e) {
      console.warn('[SIPELOR] getCarouselBanners error:', e.message);
      return this._mockCarouselBanners();
    }
  }

  /**
   * Tambah banner baru.
   * @param {Object} payload { title, subtitle, badge_text, image_url, gradient_start, gradient_end, sort_order, is_active, link_url }
   */
  async createCarouselBanner(payload) {
    if (!this.db) return { id: Date.now().toString(), ...payload };
    const { data, error } = await this.db
      .from('carousel_banners')
      .insert({ ...payload, created_at: new Date().toISOString(), updated_at: new Date().toISOString() })
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  /**
   * Update banner yang sudah ada.
   * @param {string} id UUID banner
   * @param {Object} payload Fields yang ingin diubah
   */
  async updateCarouselBanner(id, payload) {
    if (!this.db) return true;
    const { error } = await this.db
      .from('carousel_banners')
      .update({ ...payload, updated_at: new Date().toISOString() })
      .eq('id', id);
    if (error) throw error;
    return true;
  }

  /**
   * Hapus banner beserta file gambarnya di storage (jika ada).
   * @param {string} id UUID banner
   * @param {string|null} imageUrl URL publik gambar (opsional, untuk cleanup storage)
   */
  async deleteCarouselBanner(id, imageUrl = null) {
    if (!this.db) return true;
    // Hapus file di storage jika ada
    if (imageUrl && this.db) {
      try {
        const storagePath = this._extractCarouselStoragePath(imageUrl);
        if (storagePath) {
          await this.db.storage.from('carousel-banners').remove([storagePath]);
        }
      } catch (_) { /* file cleanup is optional */ }
    }
    const { error } = await this.db.from('carousel_banners').delete().eq('id', id);
    if (error) throw error;
    return true;
  }

  /**
   * Upload gambar banner ke bucket `carousel-banners` (public).
   * @param {File} file File dari input[type=file]
   * @returns {{ publicUrl: string, storagePath: string }}
   */
  async uploadCarouselImage(file) {
    if (!this.db) throw new Error('Supabase tidak terhubung');
    const ext = file.name.split('.').pop().toLowerCase();
    const storagePath = `banners/${Date.now()}_${Math.random().toString(36).slice(2)}.${ext}`;
    const { error } = await this.db.storage
      .from('carousel-banners')
      .upload(storagePath, file, { cacheControl: '3600', upsert: false });
    if (error) throw error;
    const publicUrl = this.db.storage.from('carousel-banners').getPublicUrl(storagePath).data.publicUrl;
    return { publicUrl, storagePath };
  }

  _extractCarouselStoragePath(imageUrl) {
    if (!imageUrl || !imageUrl.startsWith('http')) return null;
    try {
      const parts = new URL(imageUrl).pathname.split('/');
      const idx = parts.indexOf('carousel-banners');
      if (idx !== -1 && idx < parts.length - 1) {
        return decodeURIComponent(parts.slice(idx + 1).join('/'));
      }
    } catch (_) {}
    return null;
  }

  _mockCarouselBanners() {
    return [
      { id: 'cb1', title: 'Diskon Sewa Stadion', subtitle: 'Hemat hingga 30%', badge_text: 'DISKON 30%', image_url: null, gradient_start: '#D946EF', gradient_end: '#F97316', sort_order: 0, is_active: true, link_url: null, created_at: new Date().toISOString() },
      { id: 'cb2', title: 'Bupati Cup 2026', subtitle: 'Daftar sekarang!', badge_text: 'GRATIS', image_url: null, gradient_start: '#3B82F6', gradient_end: '#8B5CF6', sort_order: 1, is_active: true, link_url: null, created_at: new Date().toISOString() },
      { id: 'cb3', title: 'Paket Latihan', subtitle: 'Promo spesial', badge_text: 'DISKON 25%', image_url: null, gradient_start: '#10B981', gradient_end: '#14B8A6', sort_order: 2, is_active: false, link_url: null, created_at: new Date().toISOString() },
    ];
  }

  // ── Popup Banners ────────────────────────────────────────────

  async getPopupBanners() {
    if (!this.db) return this._mockPopupBanners();
    try {
      const { data, error } = await this.db
        .from('popup_banners')
        .select('*')
        .order('created_at', { ascending: false });
      if (error) throw error;
      return data || [];
    } catch (e) {
      console.warn('[SIPELOR] getPopupBanners error:', e.message);
      return this._mockPopupBanners();
    }
  }

  async createPopupBanner(payload) {
    if (!this.db) return { id: Date.now().toString(), ...payload };
    const { data, error } = await this.db
      .from('popup_banners')
      .insert({ ...payload })
      .select().single();
    if (error) throw error;
    return data;
  }

  async updatePopupBanner(id, payload) {
    if (!this.db) return true;
    const { error } = await this.db
      .from('popup_banners')
      .update({ ...payload })
      .eq('id', id);
    if (error) throw error;
    return true;
  }

  async deletePopupBanner(id, imageUrl = null) {
    if (!this.db) return true;
    if (imageUrl) {
      try {
        const storagePath = this._extractPopupStoragePath(imageUrl);
        if (storagePath) {
          await this.db.storage.from('popup-banners').remove([storagePath]);
        }
      } catch (_) { /* file cleanup optional */ }
    }
    const { error } = await this.db.from('popup_banners').delete().eq('id', id);
    if (error) throw error;
    return true;
  }

  async uploadPopupImage(file) {
    if (!this.db) throw new Error('Supabase tidak terhubung');
    const ext = file.name.split('.').pop().toLowerCase();
    const storagePath = `popups/${Date.now()}_${Math.random().toString(36).slice(2)}.${ext}`;
    const { error } = await this.db.storage
      .from('popup-banners')
      .upload(storagePath, file, { cacheControl: '3600', upsert: false });
    if (error) throw error;
    const publicUrl = this.db.storage.from('popup-banners').getPublicUrl(storagePath).data.publicUrl;
    return { publicUrl, storagePath };
  }

  _extractPopupStoragePath(imageUrl) {
    if (!imageUrl || !imageUrl.startsWith('http')) return null;
    try {
      const parts = new URL(imageUrl).pathname.split('/');
      const idx = parts.indexOf('popup-banners');
      if (idx !== -1 && idx < parts.length - 1) {
        return decodeURIComponent(parts.slice(idx + 1).join('/'));
      }
    } catch (_) {}
    return null;
  }

  // ══════════════════════════════════════════════════════════
  // TOURNAMENT API
  // ══════════════════════════════════════════════════════════

  async getTournaments() {
    if (!this.db) return this._mockTournaments();
    try {
      const { data, error } = await this.db
        .from('tournaments')
        .select('*')
        .order('created_at', { ascending: false });
      if (error) throw error;
      const list = data || [];
      // Enrich with counts
      for (const t of list) {
        try {
          const [sc, tc, mc] = await Promise.all([
            this.db.from('tournament_sports').select('id', { count: 'exact', head: true }).eq('tournament_id', t.id),
            this.db.from('tournament_teams').select('id', { count: 'exact', head: true }).eq('tournament_id', t.id).eq('status', 'approved'),
            this.db.from('tournament_matches').select('id', { count: 'exact', head: true }).eq('tournament_id', t.id),
          ]);
          t._sportCount = sc.count || 0;
          t._teamCount  = tc.count || 0;
          t._matchCount = mc.count || 0;
        } catch (_) {}
      }
      return list;
    } catch (e) {
      console.warn('[SIPELOR] getTournaments error:', e.message);
      return this._mockTournaments();
    }
  }

  async getTournamentById(id) {
    if (!this.db) return this._mockTournaments().find(t => t.id === id) || null;
    try {
      const { data, error } = await this.db.from('tournaments').select('*').eq('id', id).single();
      if (error) throw error;
      return data;
    } catch (e) {
      console.warn('[SIPELOR] getTournamentById error:', e.message);
      return null;
    }
  }

  async createTournament(payload) {
    if (!this.db) return { id: 'mock-' + Date.now(), ...payload, status: 'draft', created_at: new Date().toISOString() };
    const { data: { user } } = await this.db.auth.getUser();
    const insert = { ...payload, created_by: user?.id, status: 'draft', created_at: new Date().toISOString(), updated_at: new Date().toISOString() };
    const { data, error } = await this.db.from('tournaments').insert(insert).select().single();
    if (error) throw error;
    return data;
  }

  async updateTournament(id, payload) {
    if (!this.db) return true;
    const { error } = await this.db.from('tournaments').update({ ...payload, updated_at: new Date().toISOString() }).eq('id', id);
    if (error) throw error;
    return true;
  }

  async deleteTournament(id) {
    if (!this.db) return true;
    const { error } = await this.db.from('tournaments').delete().eq('id', id);
    if (error) throw error;
    return true;
  }

  // ── Tournament Sports ────────────────────────────────────

  async getTournamentSports(tournamentId) {
    if (!this.db) return [];
    try {
      const { data, error } = await this.db.from('tournament_sports')
        .select('*')
        .eq('tournament_id', tournamentId)
        .order('created_at', { ascending: true });
      if (error) throw error;
      const list = data || [];
      // Enrich with team count
      for (const s of list) {
        try {
          const { count } = await this.db.from('tournament_teams')
            .select('id', { count: 'exact', head: true })
            .eq('sport_id', s.id).eq('status', 'approved');
          s._teamCount = count || 0;
        } catch (_) {}
      }
      return list;
    } catch (e) {
      console.warn('[SIPELOR] getTournamentSports error:', e.message);
      return [];
    }
  }

  async createTournamentSport(payload) {
    if (!this.db) return { id: 'mock-sport-' + Date.now(), ...payload };
    const { data, error } = await this.db.from('tournament_sports')
      .insert({ ...payload, created_at: new Date().toISOString(), updated_at: new Date().toISOString() })
      .select().single();
    if (error) throw error;
    return data;
  }

  async updateTournamentSport(id, payload) {
    if (!this.db) return true;
    const { error } = await this.db.from('tournament_sports')
      .update({ ...payload, updated_at: new Date().toISOString() }).eq('id', id);
    if (error) throw error;
    return true;
  }

  async deleteTournamentSport(id) {
    if (!this.db) return true;
    const { error } = await this.db.from('tournament_sports').delete().eq('id', id);
    if (error) throw error;
    return true;
  }

  // ── Tournament Teams ─────────────────────────────────────

  async getTournamentTeams(tournamentId, sportId) {
    if (!this.db) return this._mockTeams(sportId);
    try {
      const { data, error } = await this.db.from('tournament_teams')
        .select('*')
        .eq('tournament_id', tournamentId)
        .eq('sport_id', sportId)
        .order('created_at', { ascending: true });
      if (error) throw error;
      return data || [];
    } catch (e) {
      console.warn('[SIPELOR] getTournamentTeams error:', e.message);
      return this._mockTeams(sportId);
    }
  }

  async updateTournamentTeamStatus(id, status) {
    if (!this.db) return true;
    const { error } = await this.db.from('tournament_teams')
      .update({ status, updated_at: new Date().toISOString() }).eq('id', id);
    if (error) throw error;
    return true;
  }

  async updateTournamentTeam(id, payload) {
    if (!this.db) return true;
    const { error } = await this.db.from('tournament_teams')
      .update({ ...payload, updated_at: new Date().toISOString() }).eq('id', id);
    if (error) throw error;
    return true;
  }

  // ── Tournament Matches ───────────────────────────────────

  async getTournamentMatches(tournamentId, sportId) {
    if (!this.db) return this._mockMatches();
    try {
      const { data, error } = await this.db.from('tournament_matches')
        .select('*')
        .eq('tournament_id', tournamentId)
        .eq('sport_id', sportId)
        .order('phase', { ascending: true })
        .order('match_number', { ascending: true });
      if (error) throw error;
      return data || [];
    } catch (e) {
      console.warn('[SIPELOR] getTournamentMatches error:', e.message);
      return [];
    }
  }

  async updateMatchScore(matchId, payload) {
    if (!this.db) return true;
    const { team_a_score, team_b_score } = payload;
    let winnerId = null;
    let winnerName = null;
    let loserName = null;
    let isDraw = false;

    // Fetch match regardless so we always have team data
    const { data: match } = await this.db
      .from('tournament_matches').select('*').eq('id', matchId).single();

    if (match) {
      if (payload.status === 'completed' && team_a_score !== null && team_b_score !== null) {
        if (team_a_score > team_b_score) {
          winnerId   = match.team_a_id;
          winnerName = match.team_a_name;
          loserName  = match.team_b_name;
        } else if (team_b_score > team_a_score) {
          winnerId   = match.team_b_id;
          winnerName = match.team_b_name;
          loserName  = match.team_a_name;
        } else {
          isDraw = true;
        }
        // Update standings for group phase
        if (match.phase === 'group') {
          await this._updateGroupStandings(match, team_a_score, team_b_score, winnerId, isDraw);
        }
      } else if (payload.status === 'walkover' && payload.walkover_winner_id) {
        // For W.O.: winner is explicitly chosen by admin
        winnerId   = payload.walkover_winner_id;
        winnerName = winnerId === match.team_a_id ? match.team_a_name : match.team_b_name;
        loserName  = winnerId === match.team_a_id ? match.team_b_name : match.team_a_name;
      }
    }

    // Strip walkover_winner_id — not a DB column
    const { walkover_winner_id, ...dbPayload } = payload;
    const update = { ...dbPayload, winner_id: winnerId, is_draw: isDraw, updated_at: new Date().toISOString() };
    const { error } = await this.db.from('tournament_matches').update(update).eq('id', matchId);
    if (error) throw error;

    // Advance winner to the next bracket match
    // winnerName may be null if team_name was not set — fall back to winnerId so the check passes
    const effectiveWinnerName = winnerName || (winnerId ? `Tim ${winnerId.slice(0,6)}` : null);
    if (match && winnerId && effectiveWinnerName) {
      try {
        await this._advanceWinnerToNextMatch(match, winnerId, effectiveWinnerName);
        // For semifinal losers: fill third-place match
        if (match.phase === 'semifinal') {
          const loserId   = winnerId === match.team_a_id ? match.team_b_id   : match.team_a_id;
          const effectiveLoseName = loserName || (loserId ? `Tim ${loserId.slice(0,6)}` : null);
          if (loserId && effectiveLoseName) {
            await this._advanceLoserToThirdPlace(match, loserId, effectiveLoseName);
          }
        }
      } catch (advErr) {
        console.error('[SIPELOR] Bracket advance error:', advErr);
        throw new Error('Skor disimpan, tapi gagal memajukan pemenang: ' + (advErr.message || advErr));
      }
    }
    return true;
  }

  // ── Bracket Advancement ───────────────────────────────────

  async _advanceWinnerToNextMatch(match, winnerId, winnerName) {
    const phaseOrder = ['group', 'round_of_16', 'quarterfinal', 'semifinal', 'final'];
    const curIdx = phaseOrder.indexOf(match.phase);
    // group phase advancement handled separately (standings → knockout seeding)
    if (curIdx === -1 || match.phase === 'group') return;
    // final has no next match
    if (match.phase === 'final') return;

    const nextPhase = phaseOrder[curIdx + 1];

    // All matches in the current phase, ordered — filter by both tournament_id and sport_id
    const { data: curMatches, error: curErr } = await this.db
      .from('tournament_matches').select('id, match_number')
      .eq('tournament_id', match.tournament_id)
      .eq('sport_id', match.sport_id)
      .eq('phase', match.phase)
      .order('match_number', { ascending: true });
    if (curErr) throw curErr;
    if (!curMatches || curMatches.length === 0) return;

    const pos = curMatches.findIndex(m => m.id === match.id);
    if (pos === -1) {
      console.warn('[SIPELOR] _advanceWinnerToNextMatch: current match not found in curMatches', match.id);
      return;
    }

    // Next phase matches
    const { data: nextMatches, error: nextErr } = await this.db
      .from('tournament_matches').select('id, match_number')
      .eq('tournament_id', match.tournament_id)
      .eq('sport_id', match.sport_id)
      .eq('phase', nextPhase)
      .order('match_number', { ascending: true });
    if (nextErr) throw nextErr;
    if (!nextMatches || nextMatches.length === 0) {
      console.warn('[SIPELOR] No next-phase matches found for phase:', nextPhase);
      return;
    }

    const nextMatchIdx = Math.floor(pos / 2);
    if (nextMatchIdx >= nextMatches.length) {
      console.warn('[SIPELOR] nextMatchIdx out of bounds:', nextMatchIdx, 'length:', nextMatches.length);
      return;
    }

    const nextMatch = nextMatches[nextMatchIdx];
    const isSlotA   = pos % 2 === 0;
    const updateField = isSlotA
      ? { team_a_id: winnerId, team_a_name: winnerName }
      : { team_b_id: winnerId, team_b_name: winnerName };

    console.log(`[SIPELOR] Advancing winner "${winnerName}" (${winnerId}) → phase:${nextPhase} match:${nextMatch.id} slot:${isSlotA ? 'A' : 'B'}`);

    const { error: upErr } = await this.db.from('tournament_matches')
      .update({ ...updateField, updated_at: new Date().toISOString() })
      .eq('id', nextMatch.id);
    if (upErr) throw upErr;
  }

  async _advanceLoserToThirdPlace(match, loserId, loserName) {
    const { data: tpMatches, error: tpErr } = await this.db
      .from('tournament_matches').select('id')
      .eq('tournament_id', match.tournament_id)
      .eq('sport_id', match.sport_id).eq('phase', 'third_place')
      .order('match_number', { ascending: true });
    if (tpErr) throw tpErr;
    if (!tpMatches || tpMatches.length === 0) return;

    // Determine which semifinal slot (1st = team_a, 2nd = team_b)
    const { data: sfMatches, error: sfErr } = await this.db
      .from('tournament_matches').select('id')
      .eq('tournament_id', match.tournament_id)
      .eq('sport_id', match.sport_id).eq('phase', 'semifinal')
      .order('match_number', { ascending: true });
    if (sfErr) throw sfErr;
    if (!sfMatches || sfMatches.length === 0) return;

    const pos = sfMatches.findIndex(m => m.id === match.id);
    if (pos === -1) {
      console.warn('[SIPELOR] _advanceLoserToThirdPlace: semifinal match not found', match.id);
      return;
    }
    const isSlotA = pos === 0;
    const updateField = isSlotA
      ? { team_a_id: loserId, team_a_name: loserName }
      : { team_b_id: loserId, team_b_name: loserName };

    const { error: upErr } = await this.db.from('tournament_matches')
      .update({ ...updateField, updated_at: new Date().toISOString() })
      .eq('id', tpMatches[0].id);
    if (upErr) throw upErr;
  }

  async _updateGroupStandings(match, scoreA, scoreB, winnerId, isDraw) {
    if (!this.db || !match.team_a_id || !match.team_b_id) return;
    try {
      const upsertTeam = async (teamId, teamName, gf, ga, won, drawn, lost, groupName) => {
        const { data: existing } = await this.db.from('tournament_standings')
          .select('*').eq('sport_id', match.sport_id).eq('group_name', groupName).eq('team_id', teamId).maybeSingle();
        if (existing) {
          await this.db.from('tournament_standings').update({
            played: existing.played + 1, won: existing.won + won,
            drawn: existing.drawn + drawn, lost: existing.lost + lost,
            goals_for: existing.goals_for + gf, goals_against: existing.goals_against + ga,
            points: existing.points + (won ? 3 : drawn ? 1 : 0), updated_at: new Date().toISOString(),
          }).eq('id', existing.id);
        } else {
          await this.db.from('tournament_standings').insert({
            tournament_id: match.tournament_id, sport_id: match.sport_id, group_name: groupName,
            team_id: teamId, team_name: teamName, played: 1,
            won, drawn, lost, goals_for: gf, goals_against: ga,
            points: won ? 3 : drawn ? 1 : 0, updated_at: new Date().toISOString(),
          });
        }
      };
      const grp = match.group_name || 'A';
      await Promise.all([
        upsertTeam(match.team_a_id, match.team_a_name, scoreA, scoreB, isDraw?0:(winnerId===match.team_a_id?1:0), isDraw?1:0, isDraw?0:(winnerId===match.team_b_id?1:0), grp),
        upsertTeam(match.team_b_id, match.team_b_name, scoreB, scoreA, isDraw?0:(winnerId===match.team_b_id?1:0), isDraw?1:0, isDraw?0:(winnerId===match.team_a_id?1:0), grp),
      ]);
    } catch (e) { console.warn('[SIPELOR] _updateGroupStandings error:', e.message); }
  }

  // ── Tournament Standings ─────────────────────────────────

  async getTournamentStandings(tournamentId, sportId) {
    if (!this.db) return [];
    try {
      const { data, error } = await this.db.from('tournament_standings')
        .select('*')
        .eq('tournament_id', tournamentId)
        .eq('sport_id', sportId)
        .order('points', { ascending: false })
        .order('goal_difference', { ascending: false });
      if (error) throw error;
      return data || [];
    } catch (e) {
      console.warn('[SIPELOR] getTournamentStandings error:', e.message);
      return [];
    }
  }

  // ── Manual Team Name Edit ────────────────────────────────
  /**
   * Update team_a_name or team_b_name for a match (manual bracket fix).
   * After saving, if the match already has a winner_id that corresponds to
   * the edited slot, the winner is automatically propagated to the next match.
   *
   * @param {string} matchId   UUID of the match
   * @param {'a'|'b'} slot     Which slot to update
   * @param {string}  name     New team name
   */
  async updateMatchTeamName(matchId, slot, name) {
    if (!this.db) return true;
    const field = slot === 'a'
      ? { team_a_name: name }
      : { team_b_name: name };

    const { error } = await this.db
      .from('tournament_matches')
      .update({ ...field, updated_at: new Date().toISOString() })
      .eq('id', matchId);
    if (error) throw error;

    // Cascade: if this match already has a winner that maps to the edited slot,
    // propagate the updated name to the next bracket match automatically.
    try {
      const { data: match } = await this.db
        .from('tournament_matches').select('*').eq('id', matchId).single();
      if (match && match.winner_id) {
        const winnerIsThisSlot =
          (slot === 'a' && match.winner_id === match.team_a_id) ||
          (slot === 'b' && match.winner_id === match.team_b_id);
        if (winnerIsThisSlot) {
          await this._advanceWinnerToNextMatch(match, match.winner_id, name);
        }
      }
    } catch (cascadeErr) {
      // Cascade is best-effort — don't fail the whole save
      console.warn('[SIPELOR] updateMatchTeamName cascade error:', cascadeErr.message);
    }

    return true;
  }

  // ── Sync Bracket (re-advance winners for existing completed matches) ──────

  async syncBracketAdvancement(tournamentId, sportId) {
    if (!this.db) throw new Error('Supabase tidak terhubung');

    // Fetch all completed non-group knockout matches ordered by phase progression
    const phaseOrder = ['round_of_16', 'quarterfinal', 'semifinal'];
    const { data: completedMatches, error } = await this.db
      .from('tournament_matches')
      .select('*')
      .eq('tournament_id', tournamentId)
      .eq('sport_id', sportId)
      .eq('status', 'completed')
      .in('phase', phaseOrder);
    if (error) throw error;
    if (!completedMatches || completedMatches.length === 0) return 0;

    // Sort by phase order then match_number so earlier matches advance first
    completedMatches.sort((a, b) => {
      const pi = phaseOrder.indexOf(a.phase) - phaseOrder.indexOf(b.phase);
      return pi !== 0 ? pi : a.match_number - b.match_number;
    });

    let synced = 0;
    for (const match of completedMatches) {
      let winnerId = match.winner_id;
      let winnerName = null;
      if (winnerId) {
        winnerName = winnerId === match.team_a_id ? match.team_a_name : match.team_b_name;
      } else if (match.team_a_score !== null && match.team_b_score !== null) {
        if (match.team_a_score > match.team_b_score) {
          winnerId = match.team_a_id; winnerName = match.team_a_name;
        } else if (match.team_b_score > match.team_a_score) {
          winnerId = match.team_b_id; winnerName = match.team_b_name;
        }
      }
      if (!winnerId) continue;
      const effectiveName = winnerName || `Tim ${winnerId.slice(0, 6)}`;
      try {
        await this._advanceWinnerToNextMatch(match, winnerId, effectiveName);
        // Semifinal losers → third place
        if (match.phase === 'semifinal') {
          const loserId = winnerId === match.team_a_id ? match.team_b_id : match.team_a_id;
          const loserName = winnerId === match.team_a_id ? match.team_b_name : match.team_a_name;
          if (loserId) await this._advanceLoserToThirdPlace(match, loserId, loserName || `Tim ${loserId.slice(0,6)}`);
        }
        synced++;
      } catch (e) {
        console.warn('[SIPELOR] syncBracketAdvancement skip match', match.id, e.message);
      }
    }
    return synced;
  }

  // ── Generate Bracket ─────────────────────────────────────

  async generateTournamentBracket(tournamentId, sportId, options = {}) {
    if (!this.db) throw new Error('Supabase tidak terhubung');
    try {
      // 1. Get approved teams
      const { data: teams, error: te } = await this.db.from('tournament_teams')
        .select('*').eq('tournament_id', tournamentId).eq('sport_id', sportId).eq('status', 'approved');
      if (te) throw te;
      if (!teams || teams.length < 2) throw new Error('Butuh minimal 2 tim yang disetujui');

      // 2. Get sport config
      const { data: sport, error: se } = await this.db.from('tournament_sports').select('*').eq('id', sportId).single();
      if (se) throw se;

      // 3. Delete existing matches for this sport
      await this.db.from('tournament_matches').delete().eq('sport_id', sportId);
      // Also reset standings
      await this.db.from('tournament_standings').delete().eq('sport_id', sportId);

      // 4. Shuffle if random seeding
      let seeded = [...teams];
      if (options.seeding !== 'manual') seeded = seeded.sort(() => Math.random() - 0.5);

      const matches = [];

      if (sport.format === 'single_elimination') {
        this._buildSingleElimination(matches, seeded, tournamentId, sportId);
      } else if (sport.format === 'round_robin') {
        this._buildRoundRobin(matches, seeded, tournamentId, sportId, null);
      } else {
        // group_knockout: assign groups if auto, then build group matches + placeholder knockout
        if (options.groupAssign !== 'manual') {
          const groupCount = sport.group_count || 2;
          const groupLetters = 'ABCDEFGH'.split('');
          seeded.forEach((t, i) => {
            t._assignedGroup = groupLetters[i % groupCount];
          });
          // Update group_name in DB
          for (const t of seeded) {
            await this.db.from('tournament_teams').update({ group_name: t._assignedGroup }).eq('id', t.id);
          }
        } else {
          seeded.forEach(t => { t._assignedGroup = t.group_name || 'A'; });
        }
        // Build group matches
        const byGroup = {};
        seeded.forEach(t => { const g = t._assignedGroup || 'A'; if (!byGroup[g]) byGroup[g] = []; byGroup[g].push(t); });
        for (const [grp, groupTeams] of Object.entries(byGroup)) {
          this._buildRoundRobin(matches, groupTeams, tournamentId, sportId, grp);
        }
        // Build placeholder knockout bracket
        const totalGroups = Object.keys(byGroup).length;
        const teamsAdvance = sport.teams_advance_per_group || 2;
        const knockoutTeams = totalGroups * teamsAdvance;
        this._buildPlaceholderKnockout(matches, knockoutTeams, tournamentId, sportId);

        // Pre-populate standings with 0-stat rows for all group teams
        // so klasemen tab shows teams immediately (even before matches are scored)
        const standingsRows = [];
        for (const [grp, groupTeams] of Object.entries(byGroup)) {
          for (const t of groupTeams) {
            standingsRows.push({
              tournament_id: tournamentId, sport_id: sportId,
              group_name: grp, team_id: t.id, team_name: t.team_name,
              played: 0, won: 0, drawn: 0, lost: 0,
              goals_for: 0, goals_against: 0, points: 0,
              updated_at: new Date().toISOString(),
            });
          }
        }
        if (standingsRows.length > 0) {
          const { error: sErr } = await this.db.from('tournament_standings').insert(standingsRows);
          if (sErr) console.warn('[SIPELOR] Pre-populate standings error (non-critical):', sErr.message);
        }
      }

      // 5. Insert all matches
      if (matches.length > 0) {
        const { error: me } = await this.db.from('tournament_matches').insert(matches);
        if (me) throw me;
      }
      return true;
    } catch (e) {
      console.error('[SIPELOR] generateTournamentBracket error:', e);
      throw e;
    }
  }

  _buildSingleElimination(matches, teams, tournamentId, sportId) {
    const phases = ['round_of_16','quarterfinal','semifinal','final'];
    const n = teams.length;
    // Pad to next power of 2
    const size = Math.pow(2, Math.ceil(Math.log2(n)));
    let padded = [...teams];
    while (padded.length < size) padded.push(null);
    let matchNum = 1;
    const phaseIdx = Math.max(0, phases.length - Math.log2(size));
    const phase = phases[phaseIdx] || 'round_of_16';
    for (let i = 0; i < padded.length; i += 2) {
      const a = padded[i], b = padded[i+1];
      matches.push({
        tournament_id: tournamentId, sport_id: sportId,
        phase, match_number: matchNum++, round: 1,
        team_a_id: a?.id || null, team_a_name: a?.team_name || 'TBD',
        team_b_id: b?.id || null, team_b_name: b?.team_name || 'TBD',
        status: (a && b) ? 'scheduled' : 'walkover',
        created_at: new Date().toISOString(), updated_at: new Date().toISOString(),
      });
    }
    // Next rounds (placeholder)
    let nextSize = size / 2;
    let phaseI = phaseIdx + 1;
    while (nextSize >= 1 && phaseI < phases.length) {
      for (let i = 0; i < nextSize; i++) {
        matches.push({
          tournament_id: tournamentId, sport_id: sportId,
          phase: phases[phaseI], match_number: matchNum++, round: phaseI + 1,
          team_a_name: 'TBD', team_b_name: 'TBD', status: 'scheduled',
          created_at: new Date().toISOString(), updated_at: new Date().toISOString(),
        });
      }
      nextSize = Math.floor(nextSize / 2);
      phaseI++;
    }
    // Add third place
    matches.push({
      tournament_id: tournamentId, sport_id: sportId,
      phase: 'third_place', match_number: matchNum++, round: phaseIdx + 3,
      team_a_name: 'TBD', team_b_name: 'TBD', status: 'scheduled',
      created_at: new Date().toISOString(), updated_at: new Date().toISOString(),
    });
  }

  _buildRoundRobin(matches, teams, tournamentId, sportId, groupName) {
    let matchNum = matches.filter(m => m.phase === 'group').length + 1;
    for (let i = 0; i < teams.length; i++) {
      for (let j = i + 1; j < teams.length; j++) {
        matches.push({
          tournament_id: tournamentId, sport_id: sportId,
          phase: 'group', match_number: matchNum++, round: 1,
          group_name: groupName,
          team_a_id: teams[i].id, team_a_name: teams[i].team_name,
          team_b_id: teams[j].id, team_b_name: teams[j].team_name,
          status: 'scheduled',
          created_at: new Date().toISOString(), updated_at: new Date().toISOString(),
        });
      }
    }
  }

  _buildPlaceholderKnockout(matches, totalTeams, tournamentId, sportId) {
    const phases = ['round_of_16','quarterfinal','semifinal','final'];
    const size = Math.pow(2, Math.ceil(Math.log2(totalTeams)));
    const phaseIdx = Math.max(0, phases.length - Math.log2(size));
    let matchNum = 1;
    for (let pi = phaseIdx; pi < phases.length; pi++) {
      const count = Math.pow(2, phases.length - 1 - pi);
      for (let i = 0; i < count; i++) {
        matches.push({
          tournament_id: tournamentId, sport_id: sportId,
          phase: phases[pi], match_number: matchNum++, round: pi + 1,
          team_a_name: 'TBD', team_b_name: 'TBD', status: 'scheduled',
          created_at: new Date().toISOString(), updated_at: new Date().toISOString(),
        });
      }
    }
    // Third place
    matches.push({
      tournament_id: tournamentId, sport_id: sportId,
      phase: 'third_place', match_number: matchNum++,
      team_a_name: 'TBD', team_b_name: 'TBD', status: 'scheduled',
      created_at: new Date().toISOString(), updated_at: new Date().toISOString(),
    });
  }

  // ── Tournament Mock Data ─────────────────────────────────

  _mockTournaments() {
    return [
      { id: 't1', name: 'Bupati CUP 2026', description: 'Kejuaraan Olahraga Kabupaten Bandung', location: 'GOR Sabilulungan', start_date: '2026-04-01', end_date: '2026-04-15', registration_deadline: '2026-03-25', status: 'open', organizer_name: 'DISPORA Kabupaten Bandung', max_teams_per_sport: 0, _sportCount: 3, _teamCount: 24, _matchCount: 0, _primarySport: 'futsal', _gradient: 'linear-gradient(135deg,#7C3AED,#D946EF)', created_at: new Date().toISOString() },
      { id: 't2', name: 'Liga Futsal DISPORA 2026', description: 'Liga futsal antar kecamatan', location: 'GOR Sabilulungan', start_date: '2026-05-01', end_date: '2026-06-30', status: 'draft', organizer_name: 'DISPORA Kabupaten Bandung', max_teams_per_sport: 16, _sportCount: 1, _teamCount: 0, _matchCount: 0, _primarySport: 'futsal', _gradient: 'linear-gradient(135deg,#3B82F6,#06B6D4)', created_at: new Date().toISOString() },
    ];
  }

  _mockTeams(sportId) {
    const kec = ['Soreang','Margahayu','Cileunyi','Majalaya','Ciparay','Baleendah','Dayeuhkolot','Bojongsoang'];
    return Array.from({ length: 8 }, (_, i) => ({
      id: `team-${i}`, sport_id: sportId, tournament_id: 't1',
      team_name: `Tim ${kec[i]}`, captain_name: `Kapten ${i+1}`,
      captain_phone: `0812${String(i).padStart(8,'0')}`,
      asal_kecamatan: kec[i], jumlah_pemain: 10 + i,
      status: ['pending','approved','approved','approved','approved','rejected','approved','pending'][i],
      group_name: ['A','A','B','B',null,null,'C','C'][i],
      created_at: new Date(Date.now() - i * 86400000).toISOString(),
    }));
  }

  _mockMatches() { return []; }

  _mockPopupBanners() {
    return [
      {
        id: 'pb1',
        image_url: 'https://picsum.photos/800/600?grayscale',
        link_url: null,
        is_active: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
    ];
  }

  // ── Annual Revenue & Target ──────────────────────────────

  async getAnnualRevenue() {
    const year = new Date().getFullYear();
    if (!this.db) return this._mockAnnualRevenue(year);
    try {
      const { data } = await this.db
        .from('bookings')
        .select('total_amount, created_at')
        .eq('payment_status', 'verified')
        .gte('created_at', `${year}-01-01T00:00:00.000Z`)
        .lte('created_at', `${year}-12-31T23:59:59.999Z`);
      return this._groupAnnualByMonth(data || [], year);
    } catch { return this._mockAnnualRevenue(year); }
  }

  getAnnualTarget() {
    const stored = localStorage.getItem('sipelor_annual_target');
    return stored ? parseInt(stored, 10) : 120000000; // default 120 juta
  }

  setAnnualTarget(amount) {
    localStorage.setItem('sipelor_annual_target', String(amount));
    return true;
  }

  _mockAnnualRevenue(year) {
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    const nowMonth = new Date().getMonth();
    return months.map((month, i) => ({
      month,
      monthNum: i + 1,
      revenue: i <= nowMonth ? Math.floor(Math.random() * 14000000) + 2500000 : 0,
    }));
  }

  _groupAnnualByMonth(data, year) {
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return months.map((month, i) => {
      const key = `${year}-${String(i + 1).padStart(2, '0')}`;
      const entries = data.filter(b => b.created_at && b.created_at.startsWith(key));
      return {
        month,
        monthNum: i + 1,
        revenue: entries.reduce((s, b) => s + (b.total_amount || 0), 0),
      };
    });
  }

  _groupByMonth(data, months) {
    const monthNames = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    const now = new Date();
    return Array.from({ length: months }, (_, i) => {
      const d = new Date(now.getFullYear(), now.getMonth() - (months - 1 - i), 1);
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2,'0')}`;
      const entries = data.filter(b => b.created_at.startsWith(key));
      return {
        month: monthNames[d.getMonth()],
        revenue: entries.reduce((s, b) => s + (b.total_amount || 0), 0),
        bookings: entries.length,
      };
    });
  }
}
