# Smart Life Planner - Stale Reminder Invalidation Tests

Use this checklist on a real Android device after installing a fresh build. Mark each case as pass or fail and add notes with the device model, app version, backend URL, and exact time tested.

## Test Setup

- [ ] Backend is running on the real local IP used by the device.
- [ ] App is signed in with a test account.
- [ ] Notification permission is allowed.
- [ ] Exact alarm permission is allowed when Android requests it.
- [ ] Device battery optimization is disabled for the app during testing.
- [ ] Current timezone is noted: `________________`
- [ ] Device model / Android version: `________________`
- [ ] App build/version: `________________`

## Test 1: Completed Task Reminder

Status: [ ] Pass [ ] Fail

Steps:
1. Create a task with a reminder in 1 minute.
2. Confirm the task appears in the task list.
3. Complete the task immediately.
4. Wait until at least 1 minute after the original reminder time.

Expected:
- The task reminder does not appear.
- Docker/backend logs show the task reminder cancellation lifecycle event when applicable.

Notes:
`________________`

## Test 2: Deleted Task Reminder

Status: [ ] Pass [ ] Fail

Steps:
1. Create a task with a reminder in 1 minute.
2. Confirm the task appears in the task list.
3. Delete the task immediately.
4. Wait until at least 1 minute after the original reminder time.

Expected:
- The task reminder does not appear.
- The deleted task no longer appears in the active task list.
- Docker/backend logs show the task reminder cancellation lifecycle event when applicable.

Notes:
`________________`

## Test 3: Rescheduled Task Reminder

Status: [ ] Pass [ ] Fail

Steps:
1. Create a task with a reminder in 1 minute.
2. Change the reminder or due time to 1 hour from now.
3. Wait until at least 1 minute after the original reminder time.
4. Keep the task active and confirm the new reminder remains scheduled.

Expected:
- The old notification does not appear at the original reminder time.
- The task stores the updated reminder or due time.
- The new notification is scheduled for the updated time.
- Docker/backend logs show the task reminder reschedule lifecycle event when applicable.

Notes:
`________________`

## Test 4: Archived Habit Reminder

Status: [ ] Pass [ ] Fail

Steps:
1. Create a habit with a daily reminder, or use a habit that already has a reminder.
2. Archive or deactivate the habit.
3. Confirm the habit is no longer active in the habit list.

Expected:
- The habit notification is cancelled immediately.
- The archived/deactivated habit does not schedule future local notifications.
- Docker/backend logs show the habit reminder cancellation lifecycle event when applicable.

Notes:
`________________`

## Test 5: Deleted Habit Reminder

Status: [ ] Pass [ ] Fail

Steps:
1. Create a habit with a daily reminder, or use a habit that already has a reminder.
2. Delete the habit.
3. Confirm the habit no longer appears in the active habit list.

Expected:
- The habit notification is cancelled immediately.
- The deleted habit does not schedule future local notifications.
- Docker/backend logs show the habit reminder cancellation lifecycle event when applicable.

Notes:
`________________`

## Test 6: Prayer Settings Change

Status: [ ] Pass [ ] Fail

Steps:
1. Open the Prayer screen and let today's prayer reminders schedule.
2. Note current prayer settings: calculation method, location/city, and timezone.
3. Change the prayer calculation method or location.
4. Reopen or refresh the Prayer screen.

Expected:
- All old prayer notifications are cancelled.
- New prayer notifications are scheduled from the updated prayer times.
- Docker/backend logs show the prayer reminder invalidation lifecycle event when applicable.

Notes:
`________________`

## Test 7: App Restart With Scheduled Reminders

Status: [ ] Pass [ ] Fail

Steps:
1. Schedule several reminders:
   - One task reminder.
   - One prayer reminder.
   - One habit reminder, if habit reminders are enabled in the build being tested.
2. Force-close the app.
3. Reopen the app.
4. Refresh the relevant screens: Tasks, Prayer, Habits.
5. Wait for the nearest scheduled reminder.

Expected:
- Valid reminders still fire after restart.
- Completed/deleted/archived items do not produce stale notifications after restart.
- Refreshing the screens does not create duplicate notifications.

Notes:
`________________`

## Test 8: Permission Denied State

Status: [ ] Pass [ ] Fail

Steps:
1. Disable notification permission in Android settings.
2. Create a task reminder in 1 minute.
3. Complete or delete the task before the reminder time.
4. Re-enable notification permission.
5. Wait until at least 1 minute after the original reminder time.

Expected:
- The app does not crash while permission is denied.
- No stale task reminder appears after permission is re-enabled.

Notes:
`________________`

## Test Summary

- Total passed: `____`
- Total failed: `____`
- Tester: `________________`
- Test date/time: `________________`
- Follow-up issues created: `________________`
