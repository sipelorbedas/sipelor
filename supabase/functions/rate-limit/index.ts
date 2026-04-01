/**
 * Supabase Edge Function: rate-limit
 *
 * Server-side rate limiting for sensitive operations.
 * Stores attempt counts in a `rate_limit_log` table in Supabase.
 *
 * Supported actions:
 *  - login
 *  - password_reset
 *  - password_change
 *  - booking_create
 *
 * Deploy:
 *   supabase functions deploy rate-limit --no-verify-jwt
 *
 * Required DB table (run in Supabase SQL editor):
 *   CREATE TABLE IF NOT EXISTS rate_limit_log (
 *     id          BIGSERIAL PRIMARY KEY,
 *     key         TEXT NOT NULL,
 *     action      TEXT NOT NULL,
 *     attempted_at TIMESTAMPTZ NOT NULL DEFAULT now()
 *   );
 *   CREATE INDEX ON rate_limit_log (key, action, attempted_at);
 *   -- Auto-clean entries older than 24 hours via cron or trigger
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Rate limit rules per action
const RATE_LIMIT_RULES: Record<string, { maxAttempts: number; windowMinutes: number; blockMinutes: number }> = {
  login: { maxAttempts: 5, windowMinutes: 15, blockMinutes: 30 },
  password_reset: { maxAttempts: 3, windowMinutes: 60, blockMinutes: 120 },
  password_change: { maxAttempts: 3, windowMinutes: 60, blockMinutes: 120 },
  booking_create: { maxAttempts: 10, windowMinutes: 60, blockMinutes: 0 },
};

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const body = await req.json();
    const { action, key, checkOnly } = body as {
      action: string;
      key: string;
      checkOnly?: boolean;
    };

    if (!action || !key) {
      return new Response(
        JSON.stringify({ error: 'action and key are required' }),
        { status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } },
      );
    }

    const rule = RATE_LIMIT_RULES[action];
    if (!rule) {
      return new Response(
        JSON.stringify({ error: `Unknown action: ${action}` }),
        { status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } },
      );
    }

    const windowStart = new Date(Date.now() - rule.windowMinutes * 60 * 1000).toISOString();
    const blockStart = rule.blockMinutes > 0
      ? new Date(Date.now() - rule.blockMinutes * 60 * 1000).toISOString()
      : null;

    // Count attempts within the window
    const { count, error: countError } = await supabase
      .from('rate_limit_log')
      .select('*', { count: 'exact', head: true })
      .eq('key', key)
      .eq('action', action)
      .gte('attempted_at', windowStart);

    if (countError) throw countError;

    const attempts = count ?? 0;
    const isBlocked = attempts >= rule.maxAttempts;

    // Calculate when block expires
    let blockedUntil: string | null = null;
    if (isBlocked && rule.blockMinutes > 0) {
      // Get the oldest attempt in window
      const { data: oldest } = await supabase
        .from('rate_limit_log')
        .select('attempted_at')
        .eq('key', key)
        .eq('action', action)
        .gte('attempted_at', windowStart)
        .order('attempted_at', { ascending: true })
        .limit(1)
        .single();

      if (oldest) {
        const oldestTime = new Date(oldest.attempted_at).getTime();
        blockedUntil = new Date(oldestTime + rule.blockMinutes * 60 * 1000).toISOString();
      }
    }

    // If not just checking, record the attempt
    if (!checkOnly && !isBlocked) {
      await supabase.from('rate_limit_log').insert({
        key,
        action,
        attempted_at: new Date().toISOString(),
      });
    }

    // Cleanup old entries (older than max window) to prevent table bloat
    const maxWindow = Math.max(...Object.values(RATE_LIMIT_RULES).map(r => r.blockMinutes + r.windowMinutes));
    const cleanupBefore = new Date(Date.now() - maxWindow * 60 * 1000).toISOString();
    await supabase.from('rate_limit_log').delete().lt('attempted_at', cleanupBefore);

    return new Response(
      JSON.stringify({
        allowed: !isBlocked,
        attempts,
        maxAttempts: rule.maxAttempts,
        remaining: Math.max(0, rule.maxAttempts - attempts),
        blockedUntil,
      }),
      {
        status: 200,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      },
    );
  } catch (err) {
    console.error('[rate-limit] Error:', err);
    // Fail open on server error to prevent lockout
    return new Response(
      JSON.stringify({ allowed: true, error: String(err) }),
      { status: 200, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } },
    );
  }
});
