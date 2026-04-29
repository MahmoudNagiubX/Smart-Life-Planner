# Deferred Scope Before 15B

Generated for Step 13R.5.

These features are intentionally removed from the main user flow until their real roadmap steps provide connected logic. They may still have route constants or guarded route shells for deep-link compatibility, but they should not be presented as active MVP features.

| Feature | Current user-facing scope | Deferred until | Reason |
| --- | --- | --- | --- |
| Direct create task route | Task creation remains available through the real task sheet. | Later task route cleanup | The standalone route only duplicated the modal flow. |
| Direct edit task route | Task details remain readable; editing is not promoted as a route. | Later task edit route work | The route was placeholder-only. |
| Journal route | Journal prompts open Notes, which is the real persisted capture surface. | 15AR.25 or future journal scope | No separate journal model/API exists yet. |
| Focus session route | Real focus timer lives directly inside `/home/focus`. | 15AR.3, 15AR.5 | Standalone active-session route was placeholder-only. |
| Focus history route | Recent focus sessions and report summary show inside `/home/focus`. | 15AR.7 | Standalone history route was placeholder-only. |
| Focus ambient sound and AI pick tiles | Removed from visible Focus screen. | 15AR.4, 15AR.8 | They were future feature tiles without connected logic. |
| Prayer history and missed-prayer tools | Removed from visible Prayer tools grid. | 15AR.10 | Prayer history/missed-prayer logic is not real yet. |
| Spiritual upgrade hub | Removed from visible Prayer tools grid. | 15AR.10-15AR.14 | Missed prayer, dhikr, fasting, and Taraweeh flows need real models/reminders. |
| Context intelligence card | Removed from Home tools. | 15AR.16-15AR.19 | Current context screen is static placeholder data. |
| AI life coach entry | Removed from AI Daily Plan app bar. | 15AR.20-15AR.24 | Future coach flows need preview/confirmation logic before being visible. |
| Voice future actions | Removed from Voice Capture action menu. | 15AR.25-15AR.28 | Future voice features must be transcript-previewed and confirmed before write actions. |

Manual verification:

- Bottom navigation should expose only Home, Tasks, Focus, Prayer, and Profile.
- Home quick tools should expose only real destinations: Focus, Habits, and AI Plan.
- Prayer tools should expose only Qibla, Ramadan, and Quran Goal.
- Focus should show the real timer/settings/report/recent sessions only.
- Voice Capture should show recording/manual entry flows only, not future voice action pages.
