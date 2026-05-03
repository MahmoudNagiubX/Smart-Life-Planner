# Smart Life Planner - Algorithm Registry

This registry documents the academic algorithms added for the Algorithms course
submission and the existing algorithmic logic already used by Smart Life Planner.

## 1. Bubble Sort

- **Status:** Academic demo implementation
- **Category:** Comparison-based sorting algorithm
- **Where it exists in code:** `mobile/lib/core/algorithms/bubble_sort.dart`
- **App connection:** Demonstrates sorting small task/demo lists by priority or due date.
- **Input:** List of `AlgorithmDemoTask` items or a generic list plus comparator.
- **Output:** New sorted list; the input list is not mutated.
- **Time complexity:** O(n^2)
- **Space complexity:** O(1) algorithm space; this demo returns a copied list for app safety.
- **Why it was chosen:** Bubble Sort is simple to trace step by step in a viva and clearly shows pairwise comparisons and swaps.
- **Manual/demo explanation for instructor:** Starting from the first item, compare neighboring tasks. If they are in the wrong order, swap them. Repeat passes until no swaps are needed.

## 2. Binary Search

- **Status:** Academic demo implementation
- **Category:** Divide-and-conquer searching algorithm
- **Where it exists in code:** `mobile/lib/core/algorithms/binary_search.dart`
- **App connection:** Demonstrates searching a sorted task, note, or reminder list by ID.
- **Input:** Sorted list and target comparison function, or sorted demo tasks plus target ID.
- **Output:** Matching index or task; `-1`/`null` when not found.
- **Time complexity:** O(log n)
- **Space complexity:** O(1) iterative
- **Why it was chosen:** Binary Search is a classic efficient lookup algorithm when data is already sorted.
- **Manual/demo explanation for instructor:** Check the middle item. If it is too small, search the right half. If it is too large, search the left half. Continue until the target is found or the range is empty.

## 3. Greedy Algorithm

- **Status:** App-relevant planning algorithm / academic implementation
- **Category:** Optimization heuristic
- **Where it exists in code:** `mobile/lib/core/algorithms/greedy_planner.dart`
- **App connection:** Demonstrates selecting today's tasks based on priority, urgency, and available time.
- **Input:** List of `AlgorithmDemoTask` items and available minutes.
- **Output:** Selected tasks that fit within the time budget.
- **Time complexity:** O(n log n) because tasks are ranked before selection.
- **Space complexity:** O(n)
- **Why it was chosen:** Greedy selection is easy to explain and closely matches daily planning: pick the best available task that fits now.
- **Manual/demo explanation for instructor:** Rank tasks by value, then repeatedly choose the highest-ranked task that fits the remaining minutes. This makes a locally best choice at each step.

## Existing App Algorithms

## 4. Weighted Scoring / Weighted Sum Model

- **Status:** Existing production logic
- **Category:** Weighted scoring / ranking
- **Where it exists in code:** `backend/app/services/hasae_engine.py`, `backend/app/services/context_task_scoring.py`, `backend/app/api/v1/analytics.py`
- **App connection:** Ranks tasks for H-ASAE and context intelligence, and computes productivity scores.
- **Input:** Task priority, urgency, energy, duration, location, weather, focus minutes, habits, prayers, and other signals.
- **Output:** Numeric score and explanation/ranked list.
- **Time complexity:** O(n log n) when ranking sorted tasks; O(1) per individual score.
- **Space complexity:** O(n) for ranked/scored lists.
- **Why it was chosen:** Weighted scoring keeps recommendations explainable and deterministic.
- **Manual/demo explanation for instructor:** Each signal contributes a weighted component, then the components are summed into one score.

## 5. Rule-Based Classification

- **Status:** Existing production logic
- **Category:** Deterministic classification
- **Where it exists in code:** `backend/app/services/quick_capture_classifier.py`, `backend/app/services/note_action_extraction_service.py`
- **App connection:** Classifies quick captures as tasks, notes, reminders, checklists, or journal entries, and extracts action items from notes.
- **Input:** User-entered text.
- **Output:** Classification result, confidence, extracted items, reminder time if detected.
- **Time complexity:** O(n) over input text length.
- **Space complexity:** O(n) for extracted items.
- **Why it was chosen:** Rule-based classification is predictable, testable, and safe as an AI fallback.
- **Manual/demo explanation for instructor:** The app checks text patterns such as prefixes, action verbs, checklist markers, and time phrases to assign a category.

## 6. Eisenhower Matrix Classification

- **Status:** Existing documented planning concept / task metadata pattern
- **Category:** Rule-based prioritization
- **Where it exists in code:** Task priority/urgency metadata supports this classification in task and planning flows.
- **App connection:** Tasks can be explained using urgency and importance-like priority signals.
- **Input:** Urgency and importance/priority signals.
- **Output:** Quadrant-style priority decision.
- **Time complexity:** O(1) per task.
- **Space complexity:** O(1)
- **Why it was chosen:** It is a clear academic planning classification model.
- **Manual/demo explanation for instructor:** A task is placed into a quadrant based on whether it is urgent and whether it is important.

## 7. GTD Bucket Classification

- **Status:** Existing backend contract coverage
- **Category:** Rule-based workflow classification
- **Where it exists in code:** `backend/tests/test_gtd_bucket_contract.py` and task planning metadata.
- **App connection:** Supports explaining tasks as inbox/next/scheduled/waiting-style buckets.
- **Input:** Task status, schedule, and actionability metadata.
- **Output:** GTD-style bucket.
- **Time complexity:** O(1) per task.
- **Space complexity:** O(1)
- **Why it was chosen:** GTD buckets are understandable and useful for productivity workflows.
- **Manual/demo explanation for instructor:** The app can group tasks by what should happen next, such as do now, schedule, or defer.

## 8. Reminder Invalidation Algorithm

- **Status:** Existing production logic
- **Category:** Filtering and state update algorithm
- **Where it exists in code:** `backend/app/services/reminder_invalidation.py`
- **App connection:** Cancels stale reminders when their source entity or reminder preference changes.
- **Input:** User ID, target type, target ID or disabled preference types.
- **Output:** Count of reminders marked cancelled.
- **Time complexity:** O(n) over matching active reminders.
- **Space complexity:** O(n) for fetched reminders.
- **Why it was chosen:** It prevents old notifications from firing after data changes.
- **Manual/demo explanation for instructor:** Find active reminders matching a target, mark each as cancelled, and record the invalidation reason.

## 9. State Machine for Auth / Focus / Reminders

- **Status:** Existing production logic
- **Category:** Finite state machine
- **Where it exists in code:** `mobile/lib/features/auth/providers/auth_provider.dart`, `mobile/lib/features/focus/providers/focus_provider.dart`, `mobile/lib/features/reminders/providers/`
- **App connection:** Moves screens and services between loading, active, completed, error, paused, or cancelled states.
- **Input:** User actions, timers, API responses, notification actions.
- **Output:** New app state.
- **Time complexity:** O(1) per transition.
- **Space complexity:** O(1) per state update.
- **Why it was chosen:** State machines keep UI behavior predictable.
- **Manual/demo explanation for instructor:** Each user event causes a controlled transition from one state to another.

## 10. Sequential Counting for Habit and Focus Streaks

- **Status:** Existing production logic
- **Category:** Sequential counting
- **Where it exists in code:** `backend/app/services/focus_report.py`, habit streak fields in `mobile/lib/features/habits/models/habit_model.dart`
- **App connection:** Counts consecutive completed focus or habit days.
- **Input:** Dates with completed activity.
- **Output:** Current streak and longest streak.
- **Time complexity:** O(n log n) if dates are sorted first; O(n) after sorting.
- **Space complexity:** O(1) besides input.
- **Why it was chosen:** Streaks depend on consecutive days, so sequential scanning is direct and explainable.
- **Manual/demo explanation for instructor:** Sort completed dates, then count how many dates continue the previous day by exactly one day.

## 11. Aggregation for Analytics / Weekly Summaries

- **Status:** Existing production logic
- **Category:** Aggregation
- **Where it exists in code:** `backend/app/api/v1/analytics.py`, `mobile/lib/features/analytics/models/analytics_model.dart`
- **App connection:** Builds daily and weekly summaries for tasks, focus, habits, prayers, and notes.
- **Input:** Activity rows grouped by date.
- **Output:** Totals, averages, daily breakdowns, insights.
- **Time complexity:** O(n) over the aggregation window.
- **Space complexity:** O(d) for daily buckets.
- **Why it was chosen:** Summaries require combining many records into compact totals.
- **Manual/demo explanation for instructor:** Count or sum records for each day, then combine those daily values into weekly totals and averages.

## 12. Qibla Great-Circle Bearing Formula

- **Status:** Existing production logic
- **Category:** Spherical trigonometry / geographic bearing
- **Where it exists in code:** `mobile/lib/features/prayer/services/qibla_direction_service.dart`
- **App connection:** Calculates the compass bearing from the user's location to the Kaaba.
- **Input:** User latitude and longitude.
- **Output:** Normalized bearing in degrees and compass label.
- **Time complexity:** O(1)
- **Space complexity:** O(1)
- **Why it was chosen:** A great-circle bearing is the standard way to compute direction on a sphere.
- **Manual/demo explanation for instructor:** Convert coordinates to radians, compute `atan2(y, x)`, then normalize the result to 0-360 degrees.

## 13. NLP Classification / Information Extraction

- **Status:** Existing production and fallback logic
- **Category:** NLP classification and extraction
- **Where it exists in code:** `backend/app/services/quick_capture_classifier.py`, `backend/app/services/note_action_extraction_service.py`, `mobile/lib/features/dashboard/widgets/quick_capture_sheet.dart`
- **App connection:** Turns natural language captures into tasks, notes, reminders, checklists, or action suggestions.
- **Input:** Natural language text.
- **Output:** Structured capture/action fields.
- **Time complexity:** O(n) for deterministic fallbacks; AI calls depend on provider.
- **Space complexity:** O(n) for extracted structures.
- **Why it was chosen:** Structured extraction makes quick capture useful while requiring confirmation before saving.
- **Manual/demo explanation for instructor:** The app detects task words, checklist markers, and date/time expressions, then returns structured fields.

## 14. Fault-Tolerant / Defensive Parsing

- **Status:** Existing production hotfix pattern
- **Category:** Defensive parsing
- **Where it exists in code:** `mobile/lib/features/habits/models/habit_model.dart`, note and reminder model/service parsing, `backend/app/services/note_summary_service.py`
- **App connection:** Prevents malformed or partial API responses from crashing the app.
- **Input:** Dynamic JSON/API values.
- **Output:** Safe typed values with fallbacks.
- **Time complexity:** O(n) for collections; O(1) per scalar.
- **Space complexity:** O(n) for copied normalized collections.
- **Why it was chosen:** Mobile clients must tolerate old, partial, or unexpected data safely.
- **Manual/demo explanation for instructor:** Before using a value, the app checks its type and supplies a safe fallback if the data is missing or malformed.

## 15. H-ASAE - Human-Aware Adaptive Scheduling

- **Status:** Flagship app feature / academic implementation
- **Category:** Adaptive scheduling and optimization heuristic
- **Where it exists in code:** `backend/app/services/hasae_engine.py`, `backend/app/api/v1/hasae.py`, `mobile/lib/features/ai/screens/daily_plan_screen.dart`, `mobile/lib/features/schedule/screens/schedule_screen.dart`
- **App connection:** Generates a prayer-aware daily plan, previews it for the user, and persists accepted schedule blocks.
- **Input:** Pending tasks, priority, due dates, estimated duration, completed tasks, prayer times, wake/sleep time, and protected existing schedule blocks.
- **Output:** Ordered task/focus/prayer schedule blocks, selected tasks, skipped tasks, overload warning, and explanation.
- **Time complexity:** O(n log n + p + b), where n is tasks, p is prayers, and b is protected blocks.
- **Space complexity:** O(n + p + b)
- **Why it was chosen:** It is explainable, deterministic, demo-ready, and connects algorithms directly to Smart Life Planner's core value.
- **Manual/demo explanation for instructor:** H-ASAE scores tasks, removes prayer/protected intervals from the day, greedily places the best tasks that fit, and warns if lower-priority work should move.

## 16. Interval Conflict Detection

- **Status:** Existing H-ASAE logic
- **Category:** Interval scheduling support
- **Where it exists in code:** `backend/app/services/hasae_engine.py`
- **App connection:** Prevents generated focus and task blocks from overlapping prayer or protected schedule blocks.
- **Input:** Available time windows plus blocked start/end intervals.
- **Output:** Remaining free windows.
- **Time complexity:** O(b * w), where b is blocked intervals and w is current windows.
- **Space complexity:** O(w)
- **Why it was chosen:** Schedule generation must respect hard time constraints.
- **Manual/demo explanation for instructor:** Each prayer or protected block cuts time out of the day, leaving only safe windows where tasks can be scheduled.

## 17. Prayer-Aware Blocking

- **Status:** Existing H-ASAE logic
- **Category:** Constraint handling
- **Where it exists in code:** `backend/app/services/hasae_engine.py`
- **App connection:** Inserts locked prayer blocks and keeps generated work away from those times.
- **Input:** Prayer log names and scheduled times.
- **Output:** Locked prayer schedule blocks and reduced free windows.
- **Time complexity:** O(p * w)
- **Space complexity:** O(p + w)
- **Why it was chosen:** Smart Life Planner's scheduling should respect spiritual routines.
- **Manual/demo explanation for instructor:** Prayer times are treated as fixed constraints before the greedy task scheduler runs.

## 18. Overload Detection In H-ASAE

- **Status:** Existing H-ASAE logic
- **Category:** Aggregation and threshold classification
- **Where it exists in code:** `backend/app/services/hasae_engine.py`, `mobile/lib/features/ai/screens/daily_plan_screen.dart`
- **App connection:** Warns the user when pending work exceeds the prayer-aware available time.
- **Input:** Total eligible task minutes and available free minutes.
- **Output:** Overload flag, message, selected tasks, and skipped tasks.
- **Time complexity:** O(n)
- **Space complexity:** O(n) for skipped task reporting.
- **Why it was chosen:** A planner should tell the user when the day is unrealistic.
- **Manual/demo explanation for instructor:** The engine sums task durations and compares them with available windows after prayer/protected blocks are removed.
