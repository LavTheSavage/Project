-- Auto-delete declined/rejected booking notifications older than 7 days.
-- Requires pg_cron extension enabled in Supabase.

-- Enable cron if not already enabled:
-- create extension if not exists pg_cron;

-- Run daily at 2:10 AM UTC.
select
  cron.schedule(
    'cleanup_declined_notifications',
    '10 2 * * *',
    $$
    delete from notifications n
    where n.created_at < now() - interval '7 days'
      and (
        n.type = 'booking_declined'
        or exists (
          select 1
          from bookings b
          where b.id = n.booking_id
            and b.status in ('declined', 'rejected')
        )
      );
    $$
  );

