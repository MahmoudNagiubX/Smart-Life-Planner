# Smart Life Planner - Reminder System QA

Use this checklist on a real Android device before calling the premium reminder system beta-ready. Test against the intended backend URL, with the same notification permissions and battery settings expected for real users.

## Test Setup

- [ ] Backend is running on the device-accessible local IP.
- [ ] App is signed in with a dedicated test account.
- [ ] Device timezone is recorded: `________________`
- [ ] Device model / Android version: `________________`
- [ ] App build/version: `________________`
- [ ] Backend commit/build: `________________`
- [ ] Notification permission is allowed.
- [ ] Exact alarm permission is allowed when Android requests it.
- [ ] Battery optimization is disabled for the app during timing tests.
- [ ] Reminder channels are configured for task, habit, prayer, Quran, bedtime, persistent, and quiet reminders.

## Task Reminders

Status: [ ] Pass [ ] Fail

Steps:
1. Create a task with a reminder 2 minutes from now.
2. Confirm it appears in the task list and Notification Center.
3. Wait for the reminder.
4. Open the notification target.
5. Complete the task.

Expected:
- Notification fires once at the scheduled time.
- Tapping the notification opens the task target or task area.
- Notification Center shows the reminder as recent or missed until cleared.
- Completing the task prevents future task reminders for that task.
- No duplicate notification appears.

Notes:
`________________`

## Recurring Reminders

Status: [ ] Pass [ ] Fail

Steps:
1. Create or configure a recurring reminder using the shortest practical test recurrence.
2. Confirm the first instance is scheduled.
3. Let the first reminder fire.
4. Confirm the next occurrence is still scheduled.
5. Disable or delete the source entity.

Expected:
- Each occurrence fires once.
- Next occurrence is only created when the source entity remains valid.
- Disabling or deleting the source cancels future occurrences.
- Notification Center does not show duplicate active reminders for the same occurrence.

Notes:
`________________`

## Habit Reminders

Status: [ ] Pass [ ] Fail

Steps:
1. Create a habit with a reminder time in the near future.
2. Wait for the reminder to fire.
3. Mark the habit complete.
4. Archive or delete the habit.

Expected:
- Habit reminder fires once.
- Completed habit does not produce a duplicate reminder for the same day.
- Archived or deleted habit cancels pending reminders.
- Notification Center reflects the reminder state after clearing.

Notes:
`________________`

## Prayer Reminders

Status: [ ] Pass [ ] Fail

Steps:
1. Enable prayer reminders.
2. Confirm prayer method, city/location, timezone, and reminder lead time.
3. Wait for the nearest practical prayer reminder or use the development test path.
4. Change prayer calculation method or location.
5. Refresh the Prayer screen.

Expected:
- Prayer reminders follow the selected method, location, timezone, and lead time.
- Prayer reminder opens the Prayer screen.
- Changing method or location cancels stale prayer reminders and schedules updated ones.
- No prayer reminder fires twice for the same prayer instance.

Notes:
`________________`

## Quran Reminders

Status: [ ] Pass [ ] Fail

Steps:
1. Create or enable a Quran goal.
2. Schedule a Quran goal reminder in the near future where supported.
3. Let the reminder fire.
4. Open the notification target.
5. Complete or update today's Quran progress.

Expected:
- Quran reminder fires once.
- Notification target opens the Prayer or Quran Goal area.
- Updating progress prevents unnecessary repeated reminders for the same goal window.
- Clearing the notification updates Notification Center state.

Notes:
`________________`

## Bedtime Reminders

Status: [ ] Pass [ ] Fail

Steps:
1. Configure wake and sleep schedule or bedtime reminder preference.
2. Schedule a bedtime reminder in the near future where supported.
3. Let the reminder fire.
4. Disable bedtime reminders or update sleep time.

Expected:
- Bedtime reminder fires at the configured time.
- Updating sleep time replaces the old reminder.
- Disabling bedtime reminders cancels pending bedtime reminders.
- The reminder uses the appropriate reminder channel and priority.

Notes:
`________________`

## Snooze

Status: [ ] Pass [ ] Fail

Steps:
1. Create a task reminder in the near future.
2. When it appears, snooze it.
3. Confirm the reminder moves to the snoozed time.
4. Wait for the snoozed reminder to fire.
5. Clear it from Notification Center.

Expected:
- Original reminder does not fire again at the original time.
- Snoozed reminder fires once at the snoozed time.
- Notification Center displays snoozed and cleared states correctly.
- Clearing the reminder does not delete the source task.

Notes:
`________________`

## Stale Invalidation

Status: [ ] Pass [ ] Fail

Steps:
1. Create reminders for a task, habit, and prayer setting.
2. Before each fires, complete/delete/archive the source entity or change prayer settings.
3. Wait until after the original reminder time.
4. Open Notification Center.

Expected:
- Completed tasks do not fire stale reminders.
- Deleted tasks do not fire stale reminders.
- Archived/deleted habits do not fire stale reminders.
- Changed prayer settings do not fire stale prayer reminders.
- Invalidated reminders are marked cancelled or dismissed where visible.

Notes:
`________________`

## Timezone Changes

Status: [ ] Pass [ ] Fail

Steps:
1. Schedule a task reminder, prayer reminder, and habit reminder.
2. Change device timezone.
3. Reopen the app and refresh relevant screens.
4. Confirm displayed reminder times.
5. Wait for the nearest reminder.

Expected:
- Reminder times remain predictable and timezone-aware.
- Absolute reminders fire at the intended real moment.
- Routine-based reminders adjust only where product rules require it.
- Prayer times are recalculated for the active timezone/location settings.
- No duplicate reminders are created after timezone refresh.

Notes:
`________________`

## Offline Scheduling

Status: [ ] Pass [ ] Fail

Steps:
1. Schedule a local task reminder while online.
2. Turn off network connectivity.
3. Wait for the reminder to fire.
4. Reopen the app while offline.
5. Restore connectivity and refresh.

Expected:
- Already scheduled local reminders still fire offline.
- App does not crash when reminder sync cannot reach the backend.
- Notification Center remains usable with cached or available reminder state.
- Restoring connectivity does not duplicate reminders.

Notes:
`________________`

## Permission Denied State

Status: [ ] Pass [ ] Fail

Steps:
1. Disable notification permission from Android settings.
2. Create or update a reminder.
3. Navigate across Tasks, Habits, Prayer, Settings, and Notification Center.
4. Re-enable notification permission.
5. Create another reminder and wait for it.

Expected:
- App does not crash while permission is denied.
- UI explains or safely handles disabled notifications.
- Reminder records remain controllable in-app.
- Re-enabling permission does not send stale reminders from the denied period.
- New reminders can be scheduled after permission is restored.

Notes:
`________________`

## User Control And Overload

Status: [ ] Pass [ ] Fail

Steps:
1. Open reminder channel preferences.
2. Disable one reminder type and leave others enabled.
3. Create reminders across several categories.
4. Clear old notifications from Notification Center.

Expected:
- Disabled reminder type does not notify.
- Enabled reminder types continue to work.
- Clearing notifications does not delete tasks, habits, prayer settings, or Quran goals.
- The user can understand and control reminder behavior without excessive prompts.

Notes:
`________________`

## Final QA Summary

- Tester: `________________`
- Test date/time: `________________`
- Backend URL: `________________`
- Total passed: `____`
- Total failed: `____`
- Duplicate notifications observed: [ ] Yes [ ] No
- Stale notifications observed: [ ] Yes [ ] No
- Follow-up issues created: `________________`

## Release Gate

- [ ] Reminder behavior is consistent and predictable.
- [ ] Users can control reminder types, channels, and noisy behavior.
- [ ] Stale notifications are eliminated for completed, deleted, archived, and rescheduled entities.
- [ ] Duplicate notifications are eliminated as much as possible.
- [ ] Notification Center reflects recent, missed, and cleared reminders clearly.
- [ ] Remaining known limitations are documented before release.
