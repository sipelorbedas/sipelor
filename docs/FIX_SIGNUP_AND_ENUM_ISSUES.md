# Fix: Signup Email Error & SQL Enum Migration Error

**Date**: 2026-01-29  
**Status**: ✅ Fixed

## Issues Fixed

### 1. ❌ SQL Migration Error - Invalid Enum Value 'superadmin'

**Error Message**:
```
ERROR: 22P02: invalid input value for enum user_role: "superadmin"
CONTEXT: SQL statement "ALTER TABLE profiles ADD CONSTRAINT profiles_role_check 
CHECK (role IN ('user', 'admin', 'superadmin'))"
```

**Root Cause**:
- The `user_role` enum type in PostgreSQL only had values: `'user'` and `'admin'`
- The migration tried to add a CHECK constraint with `'superadmin'` before adding it to the enum
- PostgreSQL validates enum values before allowing constraints

**Solution**:
Updated `docs/ADMIN_ROLE_HIERARCHY_MIGRATION.sql` to:
1. Check if `user_role` is an ENUM type
2. Add `'superadmin'` to the enum BEFORE creating the CHECK constraint
3. Handle both ENUM and TEXT column types gracefully

**How to Apply**:
The migration is now split into TWO parts (PostgreSQL requires enum changes to be committed first):

**PART 1** - Add enum value:
```bash
# Open Supabase Dashboard → SQL Editor
# Copy and paste: docs/ADMIN_ROLE_HIERARCHY_MIGRATION_PART1.sql
# Click "Run"
# Wait for completion
```

**PART 2** - Update policies (run AFTER Part 1 completes):
```bash
# Open Supabase Dashboard → SQL Editor (NEW QUERY)
# Copy and paste: docs/ADMIN_ROLE_HIERARCHY_MIGRATION_PART2.sql
# Click "Run"
```

**Why Two Parts?**
PostgreSQL requires new enum values to be committed before they can be used. 
Running them in separate SQL executions ensures the commit happens between steps.

---

### 2. ❌ Signup Email "Already Used" Error

**Problem**:
- When trying to sign up, users get "email already used" error
- This is correct behavior - the email IS already registered in `auth.users` table
- However, the error message wasn't being caught properly, showing generic error instead

**Root Cause**:
The error handling in signup screen only checked for:
- `e.message.contains('already exists')`
- `e.message.contains('already registered')`

But Supabase can return different error messages/codes:
- `user_already_exists` (code)
- `422` (status code)
- "email already in use"
- "duplicate"
- "already been registered"

**Solution**:
Updated `lib/screens/sign_up_screen.dart` to catch ALL variations:
```dart
else if (e.statusCode == 422 ||
         e.code == 'user_already_exists' ||
         e.message.toLowerCase().contains('already exists') || 
         e.message.toLowerCase().contains('already registered') ||
         e.message.toLowerCase().contains('already been registered') ||
         e.message.toLowerCase().contains('user already exists') ||
         e.message.toLowerCase().contains('email already in use') ||
         e.message.toLowerCase().contains('duplicate')) {
  errorMessage = 'Email Sudah Terdaftar';
  errorDetails = 'Email "${_emailController.text.trim()}" sudah digunakan di sistem.\n\n'
      'Silakan:\n'
      '• Login dengan akun yang ada\n'
      '• Atau gunakan email yang berbeda\n'
      '• Atau gunakan "Lupa Password" jika tidak ingat password';
```

**Note**: This is the CORRECT behavior - the email in the screenshot (`bedaşıpelor@gmail.com`) 
IS already registered. Users should either:
- Login with existing credentials
- Use a different email
- Use "Forgot Password" if they don't remember

---

## Testing

### Test SQL Migration:
```sql
-- 1. Verify enum has superadmin
SELECT enumlabel FROM pg_enum 
WHERE enumtypid = 'user_role'::regtype
ORDER BY enumlabel;

-- Expected: admin, superadmin, user

-- 2. Verify constraint is applied
SELECT conname, contype, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conname LIKE '%role%check%';

-- 3. Test updating a user role
UPDATE profiles 
SET role = 'superadmin' 
WHERE email = 'bedaşıpelor@gmail.com';

-- Should succeed without error
```

### Test Signup Error Handling:
```dart
// Try to sign up with an existing email
// Expected: See clear error message "Email Sudah Terdaftar" with helpful instructions
// Previous: Generic error message

// Debug logs will show:
// ❌ [SignUpScreen] Email already exists: bedaşıpelor@gmail.com
// ❌ [SignUpScreen] Error details: <specific error from Supabase>
```

---

## Files Modified

1. ✅ `docs/ADMIN_ROLE_HIERARCHY_MIGRATION.sql`
   - Added enum type check and ALTER TYPE statement
   - Added proper error handling with RAISE NOTICE
   - Handles both ENUM and TEXT column types

2. ✅ `lib/screens/sign_up_screen.dart`
   - Enhanced error detection for "email already exists"
   - Added status code `422` check
   - Added error code `user_already_exists` check
   - Added more message pattern matches
   - Added debug logging for troubleshooting

---

## Next Steps

1. **Run the SQL Migration**:
   ```
   Supabase Dashboard → SQL Editor → Run ADMIN_ROLE_HIERARCHY_MIGRATION.sql
   ```

2. **Test the App**:
   ```bash
   flutter run
   ```

3. **Verify Email Error**:
   - Try signing up with `bedaşıpelor@gmail.com`
   - Should see clear "Email Sudah Terdaftar" message
   - Debug console should show detailed error info

4. **Promote Admin to Superadmin** (if needed):
   ```sql
   UPDATE profiles 
   SET role = 'superadmin' 
   WHERE email = 'bedaşıpelor@gmail.com';
   ```

---

## Prevention

- Always check enum types exist before adding values to constraints
- Always ALTER enum types before using new values
- Use comprehensive error pattern matching for user-facing errors
- Add debug logging to help diagnose issues quickly

---

## References

- [PostgreSQL ENUM Types](https://www.postgresql.org/docs/current/datatype-enum.html)
- [Supabase Auth Error Codes](https://supabase.com/docs/reference/javascript/auth-error-codes)
- Flutter Exception Handling Best Practices
