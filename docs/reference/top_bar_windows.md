# Top bar windows (captured from the live client)

Captured with hover and click on the top icon row (Rhodes Island, logged in). Icon x positions at y=42 in the 806x629 capture:
Money 668, Events 705, Lucky Draw 745. Tooltips were read from the hover captures.

| Icon | Tooltip | Window | Capture |
|---|---|---|---|
| 668 | Money (shows gold) | "gold" window: gold icon with amount, buttons Discard, Trade Item, Trade Pet, Trade Equipment, Sell Item, Sell Pet, Sell Equipment, Close | money_click.png |
| 705 | Events | "Activities" window: "Thursday", table Event Name / Start Time / End Time / Event Status (row: 機智問答, 14:00, 14:30, Soon), 4 rows, pager 1/1, buttons Teleport, Leave | events_click.png |
| 745 | Lucky Draw | "chance" window: "?" box, "Left 3 Draws" counter, Draw and Close buttons (Draw not clicked: a server draw) | lucky_draw_click.png |

Notes:
- Discard was not clicked (destroys gold). Draw was not clicked (server-side random reward).
- Events and Lucky Draw content (schedules, draw counts, rewards) comes from the server; the client shell can be built from these captures.

## Status of all top bar icons (code check)
- PK (skin 1): wired to `battle_settings` -> `toggle_fight_menu` (done).
- Team, Make Friends, Money, Events, Lucky Draw, Item Mall: open their windows (done).
- Jump In (skin 2) and Spectate (skin 3): depend on server battle sessions that this client does not have yet. They
  report "not available in this client yet" instead of opening a fake window. Needs server battle data.
