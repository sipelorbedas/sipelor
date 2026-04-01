-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   SIPELOR BEDAS — Buat Akun Auth OPD / Pimpinan                    ║
-- ║   File   : CREATE_OPD_AUTH_USERS.sql                               ║
-- ║   Dibuat : 2026-03-06                                               ║
-- ║                                                                      ║
-- ║   CARA PAKAI:                                                        ║
-- ║     1. Pastikan BAGIAN 1 & 2 dari ADD_OPD_LOGIN_CREDENTIALS.sql     ║
-- ║        sudah dijalankan (kolom username & data username sudah ada)  ║
-- ║     2. Buka Supabase Dashboard → SQL Editor                         ║
-- ║     3. Jalankan file ini (select all → Run)                         ║
-- ║                                                                      ║
-- ║   CATATAN:                                                           ║
-- ║     - Email login  : username@sipelor.go.id                         ║
-- ║       (atau email asli OPD jika diisi)                              ║
-- ║     - Password     : Sipelor@2026                                   ║
-- ║     - Role profile : operator                                        ║
-- ╚══════════════════════════════════════════════════════════════════════╝

-- ══════════════════════════════════════════════════════════════════════
-- LANGKAH 0 — Pastikan pgcrypto aktif
-- ══════════════════════════════════════════════════════════════════════
CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ══════════════════════════════════════════════════════════════════════
-- LANGKAH 1 — Buat akun di auth.users (semua kolom wajib Supabase)
-- ══════════════════════════════════════════════════════════════════════
DO $$
DECLARE
  rec          RECORD;
  new_uid      UUID;
  login_email  TEXT;
  default_pw   TEXT := 'Sipelor@2026';
  enc_pw       TEXT;
  created_cnt  INT  := 0;
  skipped_cnt  INT  := 0;
BEGIN

  FOR rec IN
    SELECT id, name, username, email
    FROM   public.opd_organizations
    WHERE  username IS NOT NULL
    ORDER  BY name
  LOOP
    -- Tentukan email login
    login_email := COALESCE(NULLIF(trim(rec.email), ''), rec.username || '@sipelor.go.id');

    -- Lewati jika sudah ada di auth.users
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = login_email) THEN
      RAISE NOTICE '[SKIP] Sudah ada: %', login_email;
      skipped_cnt := skipped_cnt + 1;
      CONTINUE;
    END IF;

    -- Buat UUID baru & hash password (bcrypt)
    new_uid := gen_random_uuid();
    enc_pw  := crypt(default_pw, gen_salt('bf'));

    -- ── Insert ke auth.users dengan semua kolom wajib Supabase ──────────
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      invited_at,
      confirmation_token,
      confirmation_sent_at,
      recovery_token,
      recovery_sent_at,
      email_change_token_new,
      email_change,
      email_change_sent_at,
      last_sign_in_at,
      raw_app_meta_data,
      raw_user_meta_data,
      is_super_admin,
      created_at,
      updated_at,
      phone,
      phone_confirmed_at,
      phone_change,
      phone_change_token,
      phone_change_sent_at,
      email_change_token_current,
      email_change_confirm_status,
      banned_until,
      reauthentication_token,
      reauthentication_sent_at,
      is_sso_user,
      deleted_at,
      is_anonymous
    ) VALUES (
      '00000000-0000-0000-0000-000000000000', -- instance_id (selalu ini di Supabase)
      new_uid,
      'authenticated',
      'authenticated',
      login_email,
      enc_pw,
      now(),           -- email_confirmed_at → langsung confirmed, tidak perlu verif
      NULL,            -- invited_at
      '',              -- confirmation_token
      NULL,            -- confirmation_sent_at
      '',              -- recovery_token
      NULL,            -- recovery_sent_at
      '',              -- email_change_token_new
      '',              -- email_change
      NULL,            -- email_change_sent_at
      NULL,            -- last_sign_in_at
      '{"provider":"email","providers":["email"]}'::jsonb,  -- raw_app_meta_data
      jsonb_build_object(                                    -- raw_user_meta_data
        'full_name', rec.name,
        'opd_id',    rec.id::text,
        'username',  rec.username
      ),
      false,           -- is_super_admin
      now(),           -- created_at
      now(),           -- updated_at
      NULL,            -- phone
      NULL,            -- phone_confirmed_at
      '',              -- phone_change
      '',              -- phone_change_token
      NULL,            -- phone_change_sent_at
      '',              -- email_change_token_current
      0,               -- email_change_confirm_status
      NULL,            -- banned_until
      '',              -- reauthentication_token
      NULL,            -- reauthentication_sent_at
      false,           -- is_sso_user
      NULL,            -- deleted_at
      false            -- is_anonymous
    );

    -- ── Insert ke public.profiles ────────────────────────────────────────
    INSERT INTO public.profiles (
      id, username, email, full_name, role, created_at, updated_at
    ) VALUES (
      new_uid,
      rec.username,
      login_email,
      rec.name,
      'operator',
      now(),
      now()
    )
    ON CONFLICT (id) DO UPDATE
      SET username   = EXCLUDED.username,
          email      = EXCLUDED.email,
          full_name  = EXCLUDED.full_name,
          role       = EXCLUDED.role,
          updated_at = now();

    RAISE NOTICE '[OK] Dibuat: % → %', rec.name, login_email;
    created_cnt := created_cnt + 1;
  END LOOP;

  RAISE NOTICE '====================================';
  RAISE NOTICE 'Selesai! Dibuat: %, Dilewati: %', created_cnt, skipped_cnt;
  RAISE NOTICE '====================================';
END;
$$;


-- ══════════════════════════════════════════════════════════════════════
-- LANGKAH 2 — Patch profiles yang username-nya masih NULL
--             (untuk akun yang sudah ada sebelumnya)
-- ══════════════════════════════════════════════════════════════════════
UPDATE public.profiles p
SET
  username   = o.username,
  updated_at = now()
FROM public.opd_organizations o
WHERE (
    p.email = o.username || '@sipelor.go.id'
    OR (o.email IS NOT NULL AND o.email != '' AND p.email = o.email)
  )
  AND o.username IS NOT NULL
  AND (p.username IS NULL OR p.username = '');


-- ══════════════════════════════════════════════════════════════════════
-- VERIFIKASI — Tampilkan hasil akhir
-- ══════════════════════════════════════════════════════════════════════
SELECT
  o.name                                                              AS "Nama OPD",
  o.username                                                          AS "Username",
  COALESCE(NULLIF(o.email, ''), o.username || '@sipelor.go.id')      AS "Email Login",
  CASE WHEN u.id IS NOT NULL THEN '✅ Ada' ELSE '❌ BELUM DIBUAT' END AS "Auth User",
  CASE WHEN p.id IS NOT NULL THEN '✅ Ada' ELSE '❌ BELUM DIBUAT' END AS "Profile",
  p.username                                                          AS "Profile Username",
  p.role                                                              AS "Role"
FROM public.opd_organizations o
LEFT JOIN auth.users u
  ON u.email = COALESCE(NULLIF(trim(o.email), ''), o.username || '@sipelor.go.id')
LEFT JOIN public.profiles p
  ON p.id = u.id
WHERE o.username IS NOT NULL
ORDER BY
  CASE
    WHEN o.name ILIKE 'Badan%'      THEN 1
    WHEN o.name ILIKE 'Dinas%'      THEN 2
    WHEN o.name ILIKE 'Satuan%'     THEN 3
    WHEN o.name ILIKE 'Sekretaris%' THEN 4
    WHEN o.name ILIKE 'Kecamatan%'  THEN 5
    ELSE 6
  END,
  o.name;
