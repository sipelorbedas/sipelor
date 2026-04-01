-- ============================================
-- FIX: Notification Type CHECK CONSTRAINT
-- ============================================
-- Error: new row violates check constraint "notifications_type_check"
-- Cause: Database constraint doesn't allow all notification types
-- Solution: Drop old constraint and create new one with all types
-- ============================================

DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  FIX: Notification Type Constraint                         ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

-- ========================================
-- STEP 1: Check current constraint
-- ========================================

DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  BEFORE: Current Constraint Definition                     ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

SELECT 
    conname as "Constraint Name",
    pg_get_constraintdef(oid) as "Constraint Definition"
FROM pg_constraint
WHERE conrelid = 'notifications'::regclass
  AND conname = 'notifications_type_check';

-- ========================================
-- STEP 2: Drop old constraint
-- ========================================

DO $$ 
BEGIN
    -- Drop the constraint if it exists
    ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
    RAISE NOTICE '✅ Step 2: Dropped old notifications_type_check constraint';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '⚠️  Step 2: Constraint might not exist (this is OK)';
END $$;

-- ========================================
-- STEP 3: Create new constraint with ALL types
-- ========================================

DO $$ 
BEGIN
    -- Create new constraint that allows all notification types from Flutter code
    -- Based on NotificationType class in lib/models/push_notification.dart
    ALTER TABLE notifications 
    ADD CONSTRAINT notifications_type_check 
    CHECK (type IN (
        'booking_approved',
        'booking_rejected',
        'payment_reminder',
        'promo_available',
        'review_reminder',         -- ✅ THIS WAS MISSING!
        'maintenance_schedule',
        'booking_expired',
        'chat_message',
        'general'
    ));
    
    RAISE NOTICE '✅ Step 3: Created new constraint with 9 notification types';
    RAISE NOTICE '   Including: review_reminder (previously missing)';
END $$;

-- ========================================
-- STEP 4: Verify new constraint
-- ========================================

DO $$ 
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  AFTER: New Constraint Definition                          ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
END $$;

SELECT 
    conname as "Constraint Name",
    pg_get_constraintdef(oid) as "Constraint Definition"
FROM pg_constraint
WHERE conrelid = 'notifications'::regclass
  AND conname = 'notifications_type_check';

-- ========================================
-- STEP 5: Test with review_reminder type
-- ========================================

DO $$ 
DECLARE
    test_user_id UUID;
    test_notification_id UUID;
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  Testing review_reminder Type Insert                       ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    
    -- Get first user or use random UUID
    SELECT id INTO test_user_id FROM profiles LIMIT 1;
    IF test_user_id IS NULL THEN
        test_user_id := gen_random_uuid();
    END IF;
    
    -- Try insert with review_reminder type (the one that was failing)
    INSERT INTO notifications (
        user_id, 
        type, 
        title, 
        body, 
        data, 
        is_read, 
        created_at
    ) VALUES (
        test_user_id,
        'review_reminder',  -- ✅ THIS WAS FAILING BEFORE!
        'Test Review Reminder',
        'Testing if review_reminder type works now',
        '{"test": true, "booking_id": "test-123"}'::jsonb,
        false,
        NOW()
    ) RETURNING id INTO test_notification_id;
    
    RAISE NOTICE '✅ TEST PASSED!';
    RAISE NOTICE '   Successfully inserted notification with type: review_reminder';
    RAISE NOTICE '   Notification ID: %', test_notification_id;
    
    -- Cleanup
    DELETE FROM notifications WHERE id = test_notification_id;
    RAISE NOTICE '✅ Test notification cleaned up';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ TEST FAILED!';
        RAISE NOTICE '   Error: %', SQLERRM;
        RAISE NOTICE '   This should not happen if constraint was created correctly';
        RAISE EXCEPTION 'Test failed: %', SQLERRM;
END $$;

-- ========================================
-- STEP 6: Test all notification types
-- ========================================

DO $$ 
DECLARE
    test_user_id UUID;
    test_notification_id UUID;
    notification_types TEXT[] := ARRAY[
        'booking_approved',
        'booking_rejected', 
        'payment_reminder',
        'promo_available',
        'review_reminder',
        'maintenance_schedule',
        'booking_expired',
        'chat_message',
        'general'
    ];
    notification_type TEXT;
    success_count INTEGER := 0;
BEGIN
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  Testing All 9 Notification Types                          ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    
    -- Get first user or use random UUID
    SELECT id INTO test_user_id FROM profiles LIMIT 1;
    IF test_user_id IS NULL THEN
        test_user_id := gen_random_uuid();
    END IF;
    
    -- Test each type
    FOREACH notification_type IN ARRAY notification_types
    LOOP
        BEGIN
            INSERT INTO notifications (
                user_id, type, title, body, data, is_read, created_at
            ) VALUES (
                test_user_id,
                notification_type,
                'Test ' || notification_type,
                'Testing type: ' || notification_type,
                jsonb_build_object('test', true, 'type', notification_type),
                false,
                NOW()
            ) RETURNING id INTO test_notification_id;
            
            success_count := success_count + 1;
            RAISE NOTICE '   ✅ % - PASS', notification_type;
            
            -- Cleanup
            DELETE FROM notifications WHERE id = test_notification_id;
            
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '   ❌ % - FAIL: %', notification_type, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '📊 Results: % / % types passed', success_count, array_length(notification_types, 1);
    
    IF success_count = array_length(notification_types, 1) THEN
        RAISE NOTICE '✅ ALL NOTIFICATION TYPES WORKING!';
    ELSE
        RAISE EXCEPTION 'Some notification types failed!';
    END IF;
END $$;

-- ========================================
-- SUMMARY
-- ========================================

DO $$ 
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  ✅ NOTIFICATION TYPE CONSTRAINT FIX COMPLETE              ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE 'What was fixed:';
    RAISE NOTICE '1. ✅ Dropped old constraint with missing types';
    RAISE NOTICE '2. ✅ Created new constraint with ALL 9 notification types:';
    RAISE NOTICE '      - booking_approved';
    RAISE NOTICE '      - booking_rejected';
    RAISE NOTICE '      - payment_reminder';
    RAISE NOTICE '      - promo_available';
    RAISE NOTICE '      - review_reminder ⭐ (was missing!)';
    RAISE NOTICE '      - maintenance_schedule';
    RAISE NOTICE '      - booking_expired';
    RAISE NOTICE '      - chat_message';
    RAISE NOTICE '      - general';
    RAISE NOTICE '3. ✅ Tested review_reminder type - working!';
    RAISE NOTICE '4. ✅ Tested all 9 types - all working!';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Go to Flutter app (no restart needed for this fix)';
    RAISE NOTICE '2. Change booking status to "completed"';
    RAISE NOTICE '3. Should see: ✅ [NotificationHelper] Notification created';
    RAISE NOTICE '4. User should receive review reminder notification!';
    RAISE NOTICE '';
END $$;
