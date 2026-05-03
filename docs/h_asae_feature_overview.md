# H-ASAE Feature Overview

## What H-ASAE Is

H-ASAE stands for Human-Aware Adaptive Scheduling and Automation Engine. It is the Smart Life Planner feature that builds an explainable daily plan from real app data instead of showing a static suggestion.

The engine considers pending tasks, priority, due-date urgency, estimated duration, prayer windows, wake/sleep rhythm, existing protected schedule blocks, focus blocks, and overload risk.

## Why It Is Unique

H-ASAE connects productivity planning with human constraints. It does not simply sort tasks. It protects prayer times, creates focus blocks for demanding work, warns when the day is overloaded, and requires confirmation before saving generated schedule blocks.

## Data It Uses

- Pending tasks and completion status
- Task priority
- Due dates
- Estimated duration
- H-ASAE task metadata such as energy and flexibility
- Prayer times for the selected date
- User wake and sleep times from settings/onboarding
- Existing non-H-ASAE schedule blocks for the selected date

## Algorithms Used

- Weighted Scoring: combines priority, urgency, energy fit, duration fit, and flexibility into one score.
- Greedy Scheduling: walks through ranked tasks and places the best task that fits the remaining free windows.
- Interval Conflict Detection: subtracts prayer and protected blocks from the available day.
- Prayer-Aware Blocking: inserts locked prayer windows so generated work does not overlap them.
- Overload Detection: compares pending task minutes with available protected time and reports overflow risk.

## User Flow

1. The user opens Home, Schedule, or H-ASAE Smart Plan.
2. The app requests a H-ASAE preview from `POST /api/v1/hasae/daily-plan`.
3. The backend generates task, focus, and prayer blocks without writing data.
4. The user reviews the preview and overload warning.
5. If accepted, the app calls `POST /api/v1/hasae/daily-plan/accept`.
6. The backend persists the generated blocks into the existing schedule tables.
7. Schedule and dashboard can show the saved H-ASAE plan.

## Manual Demo Script

1. Create three pending tasks with different priorities and durations.
2. Open Schedule and tap Replan, or open the H-ASAE Smart Plan card on Home.
3. Tap Generate/Replan.
4. Point out that prayer windows are included as protected blocks.
5. Point out that high-priority or longer tasks become focus blocks.
6. Show the overload warning if total work exceeds available time.
7. Tap Accept Plan.
8. Return to Schedule and show the persisted plan blocks.

## Limitations And Future Improvements

- The current implementation is deterministic and explainable first; AI explanation can be layered on later.
- Profile-specific energy patterns are basic and use existing wake/sleep settings.
- H-ASAE replaces prior H-ASAE-generated blocks for the same date on accept, while preserving manual non-H-ASAE blocks.
- Advanced drag editing of generated blocks is deferred.
