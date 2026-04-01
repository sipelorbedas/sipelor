-- =============================================
-- SIPELOR BEDAS — Fix Chat RLS & Admin Send
-- =============================================
-- Error: "new row violates row-level security policy for table 'chat_messages'"
-- Jalankan via: Supabase Dashboard → SQL Editor
-- =============================================

-- ─────────────────────────────────────────────
-- LANGKAH 0: Tambahkan nilai enum yang kurang
-- (aman dijalankan berkali-kali, IF NOT EXISTS)
-- ─────────────────────────────────────────────
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'operator';
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'manager';

-- ─────────────────────────────────────────────
-- LANGKAH 1: Pastikan RLS aktif di tabel ini
-- ─────────────────────────────────────────────
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────
-- LANGKAH 2: Tambah/Perbaiki policy INSERT admin
-- Hapus policy lama yang mungkin memblokir admin
-- ─────────────────────────────────────────────

-- Hapus policy INSERT yang mungkin ada (agar tidak konflik)
DROP POLICY IF EXISTS "users_insert_chat"          ON public.chat_messages;
DROP POLICY IF EXISTS "users_can_send_chat"        ON public.chat_messages;
DROP POLICY IF EXISTS "insert_chat_messages"       ON public.chat_messages;
DROP POLICY IF EXISTS "Admin can send messages"    ON public.chat_messages;
DROP POLICY IF EXISTS "Admins can send chat messages" ON public.chat_messages;

-- Policy INSERT untuk user biasa (mengirim ke admin)
CREATE POLICY "Users can send chat messages"
  ON public.chat_messages
  FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND is_admin = false
  );

-- Policy INSERT untuk admin (mengirim ke user)
CREATE POLICY "Admins can send chat messages"
  ON public.chat_messages
  FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND is_admin = true
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND role::text IN ('admin', 'superadmin', 'manager', 'operator')
    )
  );

-- ─────────────────────────────────────────────
-- LANGKAH 3: Pastikan policy SELECT ada
-- ─────────────────────────────────────────────

-- User hanya bisa baca pesan miliknya
DROP POLICY IF EXISTS "Users can view own messages" ON public.chat_messages;
CREATE POLICY "Users can view own messages"
  ON public.chat_messages
  FOR SELECT
  USING (
    auth.uid() = sender_id
    OR auth.uid() = receiver_id
  );

-- Admin bisa baca semua pesan
DROP POLICY IF EXISTS "Admins can view all messages" ON public.chat_messages;
CREATE POLICY "Admins can view all messages"
  ON public.chat_messages
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND role::text IN ('admin', 'superadmin', 'manager', 'operator')
    )
  );

-- ─────────────────────────────────────────────
-- LANGKAH 4: Policy UPDATE (mark as read)
-- ─────────────────────────────────────────────
DROP POLICY IF EXISTS "Admins can mark messages read" ON public.chat_messages;
CREATE POLICY "Admins can mark messages read"
  ON public.chat_messages
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND role::text IN ('admin', 'superadmin', 'manager', 'operator')
    )
  )
  WITH CHECK (true);

-- ─────────────────────────────────────────────
-- LANGKAH 5 (Direkomendasikan): Buat fungsi RPC
-- dengan SECURITY DEFINER agar melewati RLS
-- sepenuhnya. Ini solusi paling andal.
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.admin_send_chat_message(
  p_receiver_id  UUID,
  p_message      TEXT,
  p_sender_name  TEXT
)
RETURNS SETOF public.chat_messages
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Verifikasi pemanggil adalah admin/operator
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND role::text IN ('admin', 'superadmin', 'manager', 'operator')
  ) THEN
    RAISE EXCEPTION 'Akses ditolak: diperlukan role admin';
  END IF;

  RETURN QUERY
  INSERT INTO public.chat_messages (
    sender_id,
    sender_name,
    receiver_id,
    is_admin,
    message,
    is_read,
    created_at
  )
  VALUES (
    auth.uid(),
    p_sender_name,
    p_receiver_id,
    true,
    p_message,
    false,
    NOW()
  )
  RETURNING *;
END;
$$;

-- Berikan hak akses ke user yang sudah login
GRANT EXECUTE ON FUNCTION public.admin_send_chat_message TO authenticated;

-- ─────────────────────────────────────────────
-- VERIFIKASI — jalankan setelah selesai
-- ─────────────────────────────────────────────
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'chat_messages'
ORDER BY cmd, policyname;
