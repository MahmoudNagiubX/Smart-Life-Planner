# Focus Mode Android Limitations

Smart Life Planner implements distraction-free mode inside the app only.

## What the app does now

- Hides the bottom navigation during an active distraction-free focus session.
- Removes non-essential Focus screen panels while the timer is active.
- Blocks accidental Android back navigation with a confirmation dialog.
- Keeps the focus timer, completion, and cancellation controls available.

## What the app does not do

- It does not block other Android apps.
- It does not request Usage Access permission.
- It does not use Accessibility Service APIs to control other apps.
- It does not change system Do Not Disturb settings.

## Why

Blocking apps or controlling system focus behavior requires sensitive Android permissions and careful Play Store justification. Those capabilities are outside the safe MVP scope and can create privacy and trust risks if added too early.

## Future safe path

If advanced Android focus controls are added later, they should be opt-in, documented clearly, and implemented only with explicit user consent and platform-compliant permissions.
