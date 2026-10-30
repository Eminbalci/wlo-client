# Mail windows (Form_MailBox / Form_MailSend)

Godot: `scripts/ui/hud/mailbox_window.gd` (+ `.tscn`), `scripts/ui/hud/mail_send_window.gd` (+ `.tscn`),
`scripts/ui/hud/mail_store.gd`; tests `tests/test_mailbox_window.gd`, `tests/test_mail_send_window.gd`.

## Forms found (class from VMT-0x2c, all created in main init 0x15bee0)
| class | ctor | skin | role |
|---|---|---|---|
| TMailSaveBoxForm | **0x1eada8** | Form_MailBox_1 (602x391) | mail list, tabs "Mail Inbox"/"Backup" -> `MailBoxWindow` |
| TSe_SendMailForm | **0x3d9c88** | Form_MailSend_1 (249x355) | compose -> `MailSendWindow` MODE_SEND |
| TSe_ReadMailForm | **0x3dac5c** (2 instances) | form_MailReceive_1 (253x371) | read -> `MailSendWindow` MODE_READ |
| TFurMailBoxForm | 0x1ae8d8 | Form_MailBox (253x371) | furniture mailbox compose (edit at (51,61) 160x25), not rebuilt |
| TReadFurMailBoxForm | 0x1acc18 | form_MailReceive_1 | furniture mailbox read, same layout as TSe_ReadMailForm |
| (notice) | 0x218c9c | notice2 | notices with delete/send, not rebuilt |

## TMailSaveBoxForm 0x1eada8 (verified)
| control | left | top | w x h | notes |
|---|---|---|---|---|
| form | (screenW-602)/2 | (screenH-391)/2 | 602 x 391 | |
| Btn_Close_S_1 | 554 | 25 | 18 x 18 | |
| Btn_Close_1 | 365 | 350 | 56 x 20 | |
| Btn_sendMail_2 | 185 | 350 | 56 x 20 | OnClick 0x1ee850 |
| Btn_deleteMail_1 | 275 | 350 | 56 x 20 | |
| Btn_PrePage_1 | 185 | 320 | 56 x 20 | |
| Btn_NextPage_1 | 365 | 320 | 56 x 20 | OnClick 0x1ee9a4 |
| Btn_MailBoxTab_1 | 15 | 48 | 64 x 21 | tag 0, "Mail Inbox", handler 0x1ef7ac |
| Btn_MailBoxTab_2 | 79 | 48 | 64 x 21 | tag 1, "Backup" |

Paint 0x1eb3a0:
- `Icon_MailBoxTitleMash_1` ("Sender", 76x20) drawn at (0x10b+0xf, 0x30+0x16) = (282, 70) on tab 0 only (tab 1 branch
  at 0x1ebc37 repeats the list without it) -> covers the baked "To" header.
- 10 rows per page; pages = Ceil(count / 10.0); row hit-rect (19, 95+20*i, 563, 20); text y = 98+20*i.
- Columns: type x=36 (`Friends`/`Guild`/`System`/`Pet`/`Normal ` for type byte 1/2/3/4/other), preview x=90,
  name x=270 (`Unknown` if empty), time x=400 (FormatDateTime `yyyy/mm/dd hh:mm:ss`).
- Preview: content up to the first #13; if longer than 20 bytes, about 18 bytes (DBCS-aware) + `...`.
- Colours (RGB565): unread 0xFFE0, read 0xAD60; page numbers 0x001F, 0xF800 when count > 900 (0x384). Records beyond
  1000 (0x3e8) are ignored.
- Page text `"<page> "` right-aligned to x=298 and `"/ <pages>"` from x=298, y=320.
- Record = 0xB9 bytes (+0x168 type, +0x169 read flag, +0x16e name, +0x180 content); files
  `user\Server<n>\MailBoxMsgLog<id>\MailData.dat` and `BKMailData.dat` (load 0x1ec510, save 0x1ed7bc). On-disk format
  not decoded; the Godot port uses `user://mailbox.json`.

## TSe_SendMailForm 0x3d9c88 (verified)
form (10,50) 249x355; Btn_Close_s_1 (200,23) 17x17; Btn_sendMail_2 (167,282); btn_PastMail_1 (42,282); btn_Clear_1
(104,282); Btn_Close_1 (104,315); memo (class 0x47fc9c) SetBounds(30, 90, 190, 200), `+0xe4 = 0x98` (152, taken as max
length - inferred), colour 0xFFE0. Send-side messages in 0x1ad530: "Need Mailbox to send", "No target player",
"No mail content", "Can't send to GM", sound wav0155.

## TSe_ReadMailForm 0x3dac5c (verified)
form (10,50) 253x371; Btn_Close_s_1 (203,23); btn_reply_1 (101,285); Btn_Close_1 (101,331); btn_deleteMail_1 (164,285);
btn_NextMail_1 (36,310); btn_PrevMail_1 (36,285); btn_NextMail_Gray_1 / btn_PrevMail_Gray_1 (images, class 0x47f408)
on the same rects.

## Measured / guessed
- **Measured from skin**: To field (48,64,170,20), From name (76,64), read body rect (30,92,194,184).
- **Guess**: what btn_PastMail does (emits `history_requested`); sent mails being stored in "Backup"; GM detection by
  name prefix "GM".

## Assets
`mail_box_form.png`, `mail_box_title_mask.png`, `mail_box_tab_{1,2}_*`, `mail_btn_{send,delete,prev_page,next_page,close,
past,clear,reply,next_mail,prev_mail}_*`, `mail_btn_{next,prev}_mail_gray.png`, `mail_send_form.png`, `mail_read_form.png`.
