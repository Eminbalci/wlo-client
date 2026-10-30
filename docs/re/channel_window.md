# Channel on-off window (TTH_channelForm)

Godot: `scripts/ui/hud/channel_window.gd`, `scenes/ui/hud/channel_window.tscn`, test `tests/test_channel_window.gd`.

`Form_channel` is **not** the chat-channel picker (the `Local` button's stack of green `btn_channel_N` buttons lives
in the chat bar). It is the "Channel on-off" filter: which channels' messages you receive.

## Addresses (verified)
- TTH_channelForm, VMT 0x2790e8, constructor **0x29c0cc** (created at 0x15d9cd).
- Show/sync 0x29c320 (pending := committed, bitmaps), toggle 0x29c3c4, OK 0x29c444, load from mask 0x29c4ac.
- Another class, TFT_ChannelForm (ctor 0x3c63d4, skin `form_module`, `btn_on`, `Btn_BlockMsg`, `icon_channel`), is a
  different settings UI and was not rebuilt.

## Controls
| control | left | top | w x h |
|---|---|---|---|
| form `Form_channel_1` | 150 | 100 | 169 x 237 (bitmap 166 x 237) |
| `Btn_On_1` i=1..5 | 86 | 47 + 30*(i-1) | 39 x 20 |
| `Btn_OK_2` | 41 | 199 | 56 x 20 (bitmap 39 x 20) |
| `Btn_Close_2` | 86 | 199 | 56 x 20 (bitmap 39 x 20), hint `[ESC]` |

## Behaviour
- Per channel: committed flag `+0x150+i`, pending flag `+0x156+i`; constructor sets both to 1.
- Toggle flips pending and swaps `Btn_On_1` <-> `Btn_Off_1` (bitmap field `+0x4c`).
- OK copies pending -> committed, builds a mask via 0x49c694 and sends it with 0x2d6ad8(dl=0x21, cl=3), then hides.
- Labels baked in the skin top to bottom: Local, Whisper, Team, Guild, World.

## Guesses
- Row index -> channel mapping follows the baked labels; the bit order of the mask (bit 0 = Local) is not verified.
- The Godot buttons OK/Close use the bitmap size 39x20 rather than the 56x20 rect (the rect would overlap).

## Assets
`channel_form.png`, `channel_btn_{on,off,ok,close}_{normal,hover,pressed}.png`. Persistence `user://chat_channels.json`.
