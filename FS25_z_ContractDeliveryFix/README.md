# Contract Delivery Before Conversion

Standalone utility for FS25 unload triggers that convert products before the selling station can credit a delivery contract. No crop names, maps, or contract class names are hard-coded.

Only server-side, active contracts registered at the exact receiving station, belonging to the unloading farm, and accepting the original product qualify. Compatible contracts expose `fillSold`, `fillTypeIndex` (or `acceptsMissionFillType`), `expectedLiters`, and `depositedLiters`. This covers the reviewed harvest and Supply & Transport contract interfaces, and compatible Additional Contracts missions. Unknown interfaces pass through unchanged.

The utility credits original-product liters through the contract's own `fillSold` method, capped at its remaining expected liters. Multiple matching contracts receive the load in stable ID order. Credited liters do not also become a sale or production input. Surplus is passed through the original trigger exactly once, keeping its conversion ratio and normal sale/storage behavior. Nonconverted deliveries are unchanged. Contract completion percentages and reward rules remain owned by the contract mod.

## Installation and validation

With FS25 closed, add `builds/FS25_z_ContractDeliveryFix.zip` to `Alma_Multifruit_mods` and enable it. No settings or keybinds. Installed files and saves are not modified by this repository work.

Test in a copy of the save: unload a small quantity of a converted product at its marked contract destination, confirm deposited liters increase in original-product units, then test surplus after the contract's delivery requirement is filled. The log records `[ContractDeliveryFix] Original product ... credited` once per credited contract per session. Check a normal nonconverted sale as well.

Automated tests exercise conversion ratios, partial acceptance, multiple contracts, exclusion of the wrong farm/station/product, zero-progress contracts, completed contracts, clients, nonconversion pass-through, callback errors, guard cleanup and repeated unload ticks. In-game validation is still required, including multiplayer.

This is a prospective conversion fix. It cannot recover historical uncredited sales, and does not claim to fix unrelated delivery failures or custom bale/pallet paths that bypass `UnloadTrigger.addFillUnitFillLevel`. It does not alter the map's production recipes.

Implementation reference: [GIANTS FS25 UnloadTrigger](https://gdn.giants-software.com/documentation_scripting_fs25.php?category=1&class=129&version=script). The original trigger forwards converted type/quantity to the station; this utility consumes matching contract liters first.

Reviewed Alma examples include lentils to soybeans at the Grain Mill, corn stalks
to straw at the BGA, and spelt to barley at the wine cellar. These are evidence
examples, not product-specific rules in the utility.
