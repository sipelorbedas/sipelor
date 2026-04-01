-- ================================================================
-- FIX: Admin Chat Send — RLS Policy Error
-- ================================================================
-- Error:  new row violates row-level security policy for table "chat_messages"
--
-- ROOT CAUSE:
--   The INSERT policy "Admin can send messages" queries the profiles table
--   (SELECT 1 FROM profiles WHERE ...). When profiles itself has RLS policies,
--   this creates a recursive permission check that fails silently and denies
--   the INSERT even for a properly authenticated admin user.
--
-- SOLUTION:
--   Create a SECURITY DEFINER RPC function that runs with elevated privileges
--   (bypasses RLS) but still validates the caller is an admin before inserting.
--
-- HOW TO APPLY:
--   1. Go to Supabase Dashboard → SQL Editor
--   2. Paste and run this entire script
--   3. Restart (or hot reload) the Flutter app — no app changes needed beyond
--      the updated ChatService (chat_service.dart already calls this RPC).
-- ================================================================

-- ── Step 1: Create the SECURITY DEFINER helper to check admin role ──────────
-- Re-creates get_role_by_user_id if it doesn't exist yet (idempotent)
CREATE OR REPLACE FUNCTION get_role_by_user_id(input_user_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_role text;
BEGIN
  SELECT role INTO user_role
  FROM profiles
  WHERE id = input_user_id
  LIMIT 1;
  RETURN COALESCE(user_role, 'user');
EXCEPTION
  WHEN OTHERS THEN
    RETURN 'user';
END;
$$;

GRANT EXECUTE ON FUNCTION get_role_by_user_id(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_role_by_user_id(uuid) TO anon;

-- ── Step 2: Drop & recreate the broken INSERT policies ────────────────────────
-- Remove any existing admin INSERT policy that sub-queries profiles directly.
DROP POLICY IF EXISTS "Admin can send messages" ON chat_messages;
DROP POLICY IF EXISTS "Admins can send messages" ON chat_messages;

-- Recreate using the SECURITY DEFINER helper — no recursive profiles lookup.
CREATE POLICY "Admin can send messages"
ON chat_messages FOR INSERT
WITH CHECK (
  get_role_by_user_id(auth.uid()) IN ('admin', 'superadmin')
  AND is_admin = true
);

-- ── Step 3: Create the RPC function used by the Flutter app ─────────────────
-- The Flutter ChatService calls this RPC for every admin reply.
-- Running as SECURITY DEFINER means the INSERT bypasses RLS entirely,
-- but the function itself validates the caller is an admin first.
CREATE OR REPLACE FUNCTION send_admin_chat_message(
  p_receiver_id   UUID,
  p_message       TEXT,
  p_sender_name   TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sender_id   UUID;
  v_role        TEXT;
  v_result      JSON;
BEGIN
  v_sender_id := auth.uid();

  IF v_sender_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Validate the caller is an admin (reads profiles without RLS recursion)
  SELECT role INTO v_role
  FROM profiles
  WHERE id = v_sender_id
  LIMIT 1;

  IF COALESCE(v_role, 'user') NOT IN ('admin', 'superadmin') THEN
    RAISE EXCEPTION 'Access denied: caller is not an admin (role=%)' , COALESCE(v_role, 'user');
  END IF;

  -- Insert admin reply — bypasses RLS via SECURITY DEFINER
  INSERT INTO chat_messages (
    sender_id,
    sender_name,
    is_admin,
    receiver_id,
    user_id,          -- marks whose conversation this belongs to
    message,
    is_read
  ) VALUES (
    v_sender_id,
    p_sender_name,
    TRUE,
    p_receiver_id,
    p_receiver_id,    -- user_id = the person being replied to
    p_message,
    FALSE
  )
  RETURNING row_to_json(chat_messages.*) INTO v_result;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION send_admin_chat_message(UUID, TEXT, TEXT) TO authenticated;

-- ── Step 4: Verification ─────────────────────────────────────────────────────
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
  RAISE NOTICE '║       ✅ ADMIN CHAT RLS FIX APPLIED SUCCESSFULLY          ║';
  RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
  RAISE NOTICE '║ 1. get_role_by_user_id()        — SECURITY DEFINER helper ║';
  RAISE NOTICE '║ 2. "Admin can send messages"     — policy uses helper fn  ║';
  RAISE NOTICE '║ 3. send_admin_chat_message()     — RPC for Flutter app    ║';
  RAISE NOTICE '╠════════════════════════════════════════════════════════════╣';
  RAISE NOTICE '║ Next: rebuild / hot-reload the Flutter app and retry.     ║';
  RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
  RAISE NOTICE '';
END $$;

-- Show current INSERT policies on chat_messages
SELECT policyname, cmd, with_check
FROM pg_policies
WHERE tablename = 'chat_messages' AND cmd = 'INSERT'
ORDER BY policyname;
