// =============================================
// SIPELOR BEDAS — Admin API Layer
// Semua panggilan Supabase ada di sini
// =============================================

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
      return data || [];
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
      // Normalize: expose first proof and resolved user name
      const normalized = rows.map(b => ({
        ...b,
        user_name: b.user_name || '—',
        proof: Array.isArray(b.payment_proofs) && b.payment_proofs.length > 0
          ? b.payment_proofs[0]
          : null,
      }));
      return { data: normalized, count: count || 0 };
    } catch {
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
        return { data: rows, count: count || 0 };
      } catch { return { data: this._mockBookings(), count: 20 }; }
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
    try {
      const { data } = await this.db
        .from('payment_proofs')
        .select('id, booking_id, file_path, status, created_at')
        .eq('booking_id', bookingId)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();
      return data || null;
    } catch { return null; }
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

      // ── Step 2: Decrypt and create blob URL ──────────────────────────────
      const encryptedBytes = new Uint8Array(await encryptedBlob.arrayBuffer());
      const { blobUrl, mimeType } = await this._decryptToBlob(encryptedBytes);
      return { url: blobUrl, proof, mimeType, isDecrypted: true };

    } catch (e) {
      console.warn('[SIPELOR] Proof decrypt failed, using raw URL:', e.message);
      // Graceful fallback for unencrypted files or when crypto fails
      return { url, proof };
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

    // Detect MIME type from magic bytes
    const b = new Uint8Array(decrypted);
    let mimeType = 'image/jpeg'; // default
    if      (b[0] === 0x89 && b[1] === 0x50)                                    mimeType = 'image/png';
    else if (b[0] === 0xFF && b[1] === 0xD8)                                    mimeType = 'image/jpeg';
    else if (b[0] === 0x47 && b[1] === 0x49)                                    mimeType = 'image/gif';
    else if (b[0] === 0x52 && b[1] === 0x49 && b[2] === 0x46 && b[3] === 0x46) mimeType = 'image/webp';
    else if (b[0] === 0x25 && b[1] === 0x50)                                    mimeType = 'application/pdf';

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
