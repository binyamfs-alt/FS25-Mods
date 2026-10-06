Faster Honey Pallet Cadence 1.1.1.0 — FS25 PC/Mac

INSTALL
Exit the save and replace the existing FS25_fasterHoneyPalletCadence.zip with
this ZIP. Keep it zipped and enable it alongside the original spawner mod.
Keep the existing placed honey spawn location.

SETTINGS
Open the in-game Settings menu, select General Settings, and scroll to the
Honey Pallet Spawning section. Change Spawn interval:
250 ms / 500 ms / 1 second / 5 seconds / 10 seconds.
Default: 10 seconds when no preference has been saved, including first use
of this version after the older fixed-rate patch.
Changes apply immediately, restarting the current wait, and persist per
savegame in honeyCadence.xml. That file stores intervalMs only.
Native scheduler initialization can add an extra interval before the first
pallet after loading; subsequent rounds use the selected interval.

BEHAVIOR
The selected value controls the wait between spawning rounds in active
mission time. Additional frames and pallet loading add overhead. Ten seconds
matches the approximate vanilla rate observed at 60 updates/second; vanilla
uses a frame counter rather than a fixed ten-second clock.
Native collision checks, busy guards, quantity accounting, pallet capacity,
hive production and savegame honey storage remain intact. All honey spawners
registered with BeehiveSystem are affected; factory spawners are not.

MULTIPLAYER
Install the same ZIP on all participants and the server. Only the hosting
server can change the menu setting. Remote clients see a read-only selection.
Dedicated servers can use honeyCadence.xml in the save directory while shut
down, for example: <honeyCadence intervalMs="500" />
Only 250, 500, 1000, 5000 and 10000 are accepted; other values default to 10000.

VALIDATION
Lua 5.1 mocked-engine tests cover all five intervals at 30/60/120 FPS,
settings persistence, default and invalid values, UI creation without duplicate
rows, host-only changes, client synchronization, blocked-area recovery,
request busy guards and quantity conservation. ZIP structure checks pass.
The user confirmed earlier fixed-rate builds worked in game. The new menu and
multiplayer integration have not yet been tested inside FS25.
After installation, confirm the section appears, change the selection, check
log.txt for [FasterHoneyCadence], then save/reload to confirm persistence.

REMOVE
Exit the save and remove/disable this patch to restore native scheduling.
Keep the original spawner mod. The small settings file can remain harmlessly.
