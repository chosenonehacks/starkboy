# SteamPipe packaging

The uploadable depot content is generated under `build/steam/StarkBoy/`.
SteamPipe script templates live in `steamworks/scripts/` and contain no account
credentials. Copy the templates to private, ignored files and replace `APPID`
and `DEPOTID` with the IDs assigned in Steamworks.

The Steam launch option should point to `StarkBoy.exe` from the depot root.
Upload credentials should be entered directly into SteamCMD or supplied by
your CI secret store; never commit them to this repository.

