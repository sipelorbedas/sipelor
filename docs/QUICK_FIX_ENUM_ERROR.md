# Quick Fix: PostgreSQL Enum Error

**Error**: `ERROR: 55P04: unsafe use of new value "superadmin" of enum type user_role`

## Problem

PostgreSQL doesn't allow you to add a new enum value and use it in the same transaction.

## Solution

Run the migration in **TWO SEPARATE** SQL executions:

### Step 1: Add Enum Value

```sql
-- File: docs/ADMIN_ROLE_HIERARCHY_MIGRATION_PART1.sql
-- Run this FIRST in Supabase SQL Editor
```

1. Open Supabase Dashboard
2. Go to SQL Editor
3. Copy and paste `ADMIN_ROLE_HIERARCHY_MIGRATION_PART1.sql`
4. Click **"Run"**
5. Wait for success message: "✅ Added superadmin to user_role enum"

### Step 2: Update Policies

```sql
-- File: docs/ADMIN_ROLE_HIERARCHY_MIGRATION_PART2.sql  
-- Run this SECOND (after Part 1 completes)
```

1. In Supabase SQL Editor, click **"New query"**
2. Copy and paste `ADMIN_ROLE_HIERARCHY_MIGRATION_PART2.sql`
3. Click **"Run"**
4. Verify all policies updated successfully

## Verification

Check that superadmin was added:

```sql
SELECT enumlabel as role_value
FROM pg_enum 
WHERE enumtypid = 'user_role'::regtype
ORDER BY enumsortorder;
```

Expected output:
```
role_value
----------
user
admin
superadmin
```

## Why This Happens

From PostgreSQL docs:
> "The new enum value cannot be used in the same transaction where it was added. You must commit the transaction first."

This is a safety feature to prevent issues with concurrent transactions.

## Alternative: Run Part 1, Then Part 2

If you want to run everything at once, you need to use `COMMIT;` between steps, but Supabase SQL Editor doesn't support this. So the easiest solution is to run in two separate queries.

## Next Steps

After both parts complete successfully:

1. **Promote an admin to superadmin**:
   ```sql
   UPDATE profiles 
   SET role = 'superadmin' 
   WHERE email = 'your-admin@email.com';
   ```

2. **Verify role change**:
   ```sql
   SELECT email, role FROM profiles WHERE role = 'superadmin';
   ```

3. **Test in app**:
   - Login as superadmin
   - Should see all admin features including Analytics and Audit Logs
