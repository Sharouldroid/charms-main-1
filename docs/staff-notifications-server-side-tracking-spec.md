# Spec: Server-side read/dismiss tracking for staff HR notifications

## Problem

`StaffNotificationScreen` ([lib/HRscreens/staff/staff_notification_screen.dart](../lib/HRscreens/staff/staff_notification_screen.dart)) and the dashboard bell badge ([lib/HRscreens/staff/staff_dashboard_screen.dart](../lib/HRscreens/staff/staff_dashboard_screen.dart)) track which leave/claim/schedule/exchange notifications a staff member has dismissed using **local `SharedPreferences` only**, keyed by `staffId`:

- `dismissed_leaves_$staffId`, `dismissed_claims_$staffId`, `dismissed_schedules_$staffId`, `dismissed_exchanges_$staffId` — sets of individually-dismissed IDs
- `notif_cleared_at_$staffId` — timestamp cutoff written by "Clear All"

Because none of this lives on the server, dismissed/cleared notifications reappear whenever local storage is lost (reinstall, new device, cleared app data). It also required two parallel filtering rules (per-ID dismiss set + time cutoff) to be kept in sync by hand across two screens, which is what caused the "stuck badge" bug fixed earlier this session.

## Precedent already in the API

This isn't a new pattern for the backend. Two features already do exactly this, server-side, admin-facing:

| Feature | Column | Endpoint |
|---|---|---|
| Admin "new document uploaded" badge | `StaffDocument.adminViewedAt` ([lib/HRmodels/staff_document.dart:8](../lib/HRmodels/staff_document.dart#L8)) | `POST /staff/documents/admin/mark-viewed` (body: `{staffId}`) — bulk-marks all of one staff's documents as viewed |
| HR "rejected schedule" dismiss | `Schedule.hrDismissed` ([lib/HRmodels/schedule.dart:11](../lib/HRmodels/schedule.dart#L11)) | `PUT /staff-schedule/{schedId}/dismiss` |

This spec extends the same `*_viewed_at` nullable-timestamp convention to the staff-facing side, for the four entities that currently only have local tracking: **leaves, claims, schedule exchanges, and staff's own schedules.**

## Design

Add one nullable timestamp column per table: `staff_viewed_at`. `NULL` = not yet seen/dismissed by the staff member; non-null = dismissed (whether via an individual swipe or a "Clear All" bulk action — no distinction needed, matching how `adminViewedAt` already works).

This **replaces both** local mechanisms at once — the per-ID dismissed set and the `clearedAt` cutoff — with a single source of truth. `WHERE staff_viewed_at IS NULL` is the entire filter; no cutoff logic needed, so the dashboard badge and the notification screen can literally share the same query and can't drift apart again.

### Schema changes

```sql
ALTER TABLE leaves             ADD COLUMN staff_viewed_at DATETIME NULL DEFAULT NULL;
ALTER TABLE claims             ADD COLUMN staff_viewed_at DATETIME NULL DEFAULT NULL;
ALTER TABLE schedule_exchanges ADD COLUMN staff_viewed_at DATETIME NULL DEFAULT NULL;
ALTER TABLE staff_schedules    ADD COLUMN staff_viewed_at DATETIME NULL DEFAULT NULL;
```

All nullable with no default-value backfill needed — existing rows come back as `NULL` (unviewed), which is the correct, safe default (matches "not yet seen this notification").

### New/changed endpoints

Base URL: `https://devcms.com.my/charmsAPI/api` (matches existing `_hostname` convention in [leaves.dart](../lib/HRproviders/leaves.dart#L8), [claims.dart](../lib/HRproviders/claims.dart#L7), [schedule_exchanges.dart](../lib/HRproviders/schedule_exchanges.dart#L7), [schedules.dart](../lib/HRproviders/schedules.dart#L8)).

**1. Existing GET responses gain a field** (no route changes):
- `GET /leave/staff/{staffId}` → each leave object gains `"staff_viewed_at": "2026-07-10T09:00:00Z" | null`
- `GET /claim/staff/{staffId}` → same, on each claim
- `GET /schedule-exchange/staff/{staffId}` → same, on each exchange
- `GET /staff-schedule/{staffId}` → same, on each schedule

**2. New per-item "mark viewed" endpoints** (for swipe-to-dismiss on a single card):
```
PUT /leave/{leaveId}/mark-viewed
PUT /claim/{claimId}/mark-viewed
PUT /schedule-exchange/{exchangeId}/mark-viewed
PUT /staff-schedule/{schedId}/mark-viewed
```
No body needed; sets `staff_viewed_at = NOW()` on that row. Returns `200` with the updated row (or `204`).

**3. New bulk "clear all" endpoint** (for the "Clear All" button), mirroring the existing document one:
```
POST /staff/notifications/{staffId}/clear-all
```
Sets `staff_viewed_at = NOW()` on every currently-unviewed leave/claim/schedule-exchange/staff-schedule row belonging to `staffId`, in one transaction. Returns `200` with a count of rows updated per entity, e.g.:
```json
{ "leaves": 2, "claims": 1, "schedule_exchanges": 0, "staff_schedules": 3 }
```

### Notification-worthiness rules (unchanged, just confirming what "unviewed" means per entity)

These are the existing client-side rules ([staff_notification_screen.dart:550-593](../lib/HRscreens/staff/staff_notification_screen.dart#L550-L593)) — the backend doesn't need to replicate them if the client keeps filtering, but listing them here so whoever implements this knows what "a notification" means per table:

- **Leave**: `staff_id = :staffId AND status != 'Pending' AND staff_viewed_at IS NULL`
- **Claim**: `staff_id = :staffId AND status != 'Pending' AND staff_viewed_at IS NULL`
- **Staff schedule**: `staff_id = :staffId AND staff_viewed_at IS NULL` (every assigned schedule is notification-worthy until dismissed)
- **Schedule exchange, incoming**: `target_id = :staffId AND status = 0 AND staff_viewed_at IS NULL`
- **Schedule exchange, own request updates**: `requester_id = :staffId AND status != 0 AND staff_viewed_at IS NULL`

## Rollout / compatibility

- All new columns are nullable with no default backfill — safe to deploy without downtime.
- Old app builds simply won't send/read `staff_viewed_at` and keep working exactly as they do today (local SharedPreferences only) — this is purely additive, no breaking change to existing endpoints' shapes (just new optional fields).
- Once the backend ships this, the Flutter-side follow-up is: swap `StaffNotificationScreen`'s dismiss/clear calls to hit `mark-viewed` / `clear-all` instead of writing to `SharedPreferences`, and change both it and the dashboard badge query to filter on `staff_viewed_at == null` from the fetched models instead of the local dismissed-ID sets + cutoff. That's a contained change to two files once the API exists, and is not included in this spec since it depends on the backend shipping first.

## Out of scope

- `part_timer_notification_screen.dart` already has no local dismiss state — it just shows live `status == 0` incoming exchanges, so nothing to migrate there.
- Admin-side notifications ([notification_screen.dart](../lib/HRscreens/admin/notification_screen.dart)) already work off live "Pending" status queries with no dismiss concept — also out of scope.
