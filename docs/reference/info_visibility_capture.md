# Info Visibility (Huminfo) window: live capture

Opened in the live client: top bar Options icon (770,600) -> system window -> "Info Visibility" Setup button (370,269).
Capture: `docs/reference/real_client/huminfo_real.png`, `options_window.png`.

## Differences from scripts/ui/forms/info_visibility_window.gd
1. The real window has 11 option rows, the code has 10. The 11th row "Show Other Players" (checked) is missing.
2. Captions differ from the code:
   - real: "Show name of my pet" (code: "Name of my pet")
   - real: "Show names of other's pet" (code: "Name of other's pet")
   - real: "Show other players' pet" (code: "Other players' pet")
   - real: "Show Adventure Level" in quotes (code: no quotes)
3. Row pitch is 30 px and the first checkbox is at about the same offset, so the layout matches.
4. Buttons are "Confirm" and "Close" (code: OK/Close hit areas).

Not changed yet: the code change needs a Gemini run (quota blocked at the time of capture).

## Mall pixel check (same session)
`docs/reference/real_client/mall_open_now.png`: category tabs, product rows, Add to Cart and Exit line up with
item_mall_window.gd within a few pixels; the bottom button row is off by about 5-10 px. Not a pixel-exact match.
