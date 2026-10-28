# Wonderland Online - Authentic Compound Window Parity Specification

## 1. Overview
The **Compound Window** (`scripts/ui/hud/compound_window.gd`, `scenes/ui/hud/compound_window.tscn`) provides the authentic Wonderland Online synthesis and alchemy interface (`Form_Compound_1`, 299x467).
This specification records the implementation of real-client parity features:
1. Authentic top-right Cauldron / Crucible illustration (`assets/hud/compound_cauldron.png`, 80x95) extracted directly from real client game captures (`docs/reference/real_client/compound.png`).
2. Visual `+` connector icons (`assets/hud/icon_compound_plus.png`, 16x16) linking the 5 synthesis slots (Main Base slot and 4 Sub Material slots).
3. Base slot (`main_slot_btn`) empty watermark state displaying the crucible icon at 45% alpha, switching to full opacity item icon when filled.
4. 50-slot inventory bag grid (`GridBag`) populated dynamically from player inventory (`HUDInventory.inventory_data`) or starter compoundable materials.

---

## 2. Layout & Coordinates

| Component | Identifier | Position (X, Y) | Dimensions (W x H) | Visual / Texture |
|---|---|---|---|---|
| Background Form | `FormBackground` | (0, 0) | 299 x 467 | `form_compound_1.png` |
| Cauldron Illustration | `CauldronPicture` | (198, 70) | 80 x 95 | `compound_cauldron.png` |
| Main Base Slot | `CompoundItem_Main` | (206, 167) | 44 x 44 | Watermark when empty, item icon when placed |
| Plus Connector 0 | `PlusConnector_0` | (217, 212) | 16 x 16 | `icon_compound_plus.png` |
| Sub Material Slot 0 | `CompoundItem_Sub_0` | (206, 230) | 38 x 38 | Slot backing + item icon |
| Plus Connector 1 | `PlusConnector_1` | (217, 269) | 16 x 16 | `icon_compound_plus.png` |
| Sub Material Slot 1 | `CompoundItem_Sub_1` | (206, 281) | 38 x 38 | Slot backing + item icon |
| Plus Connector 2 | `PlusConnector_2` | (217, 320) | 16 x 16 | `icon_compound_plus.png` |
| Sub Material Slot 2 | `CompoundItem_Sub_2` | (206, 332) | 38 x 38 | Slot backing + item icon |
| Plus Connector 3 | `PlusConnector_3` | (217, 371) | 16 x 16 | `icon_compound_plus.png` |
| Sub Material Slot 3 | `CompoundItem_Sub_3` | (206, 383) | 38 x 38 | Slot backing + item icon |
| Inventory Bag Scroll | `BagScroll` | (24, 76) | 174 x 344 | 5 columns x 10 rows (50 slots) |
| Compound Button | `BtnCompound` | (83, 429) | 56 x 20 | `btn_compound_normal.png` |
| Close Button | `BtnBottomClose` | (159, 429) | 56 x 20 | `btn_close_1_normal.png` |

---

## 3. Inventory Bag Grid & Interaction Pipeline

1. **Bag Grid Population (`_populate_bag_grid`):**
   - 50 slot buttons created in `GridContainer` (5 columns, 2px spacing).
   - Dynamically populated from `_hud.inventory_ctrl.inventory_data` when HUD is present.
   - When opened in standalone mode or with empty inventory, populates with authentic default compoundable materials (Iron Ore, Copper Ore, Silver Ore, Gold Ore, Common Wood, Grass, Pure Water, Clay, Alchemy Book I, Iron Sword, Bread, Rice Wine).
2. **Placement & Transfer:**
   - Left-click or right-click transfers items from the bag into the next available synthesis slot (Main base slot first, then Sub slots 0..3).
   - Validates alchemy books (cannot be in base slot, only 1 allowed in sub slots).
   - Left-click or right-click on placed slots returns items back to the inventory bag grid.
3. **Synthesis & Deduction:**
   - On compound execution, consumes 1 of each ingredient from player inventory.
   - Outputs product matching exact `Compound2.Dat` recipe or authentic grade calculation.

---

## 4. Verification & Automated Tests
- `tests/test_compound_window_parity.gd`:
  - `_test_cauldron_graphics_and_connectors()` (cauldron_rect at 198,70, 4 plus connectors).
  - `_test_main_slot_watermark_and_item_state()` (empty watermark, opaque on place, watermark on return).
  - `_test_inventory_bag_grid_population_and_interaction()` (50 slot buttons, transfer to slots, return on close).
- All tests passing with 100% zero-error rate.
