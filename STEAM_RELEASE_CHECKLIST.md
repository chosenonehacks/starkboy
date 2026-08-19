# StarkBoy Steam release checklist

## Publisher details still required

- [ ] Replace `APPID` and `DEPOTID` in local SteamPipe scripts.
- [ ] Confirm the final publisher/developer name and copyright notice.
- [ ] Complete every **[REQUIRED]** field in `AI_CONTENT_DISCLOSURE.md`.
- [ ] Archive proof of commercial-use rights for every AI tool used.
- [ ] Confirm the final game title and executable name in Steamworks.

## Store and Steamworks

- [ ] Pay Steam Direct fee and complete tax/bank/identity onboarding.
- [ ] Complete the Content Survey and select Pre-Generated AI.
- [ ] Prepare required capsules using original/cleared artwork.
- [ ] Upload at least five genuine gameplay screenshots.
- [ ] Add descriptions, supported languages, controls, and system requirements.
- [ ] Configure one Windows depot and the launch option `StarkBoy.exe`.
- [ ] Upload the release build with SteamPipe and set it on a test branch.
- [ ] Test install, update, uninstall, offline launch, controller/keyboard input,
      save behavior, pause/escape flow, music mute, and a full playthrough.
- [ ] Submit store page and build for Valve review at least seven business days
      before the planned release date.

## Build acceptance

- [ ] Export uses the official Godot **release** template, not a debug template.
- [ ] Automated smoke tests pass.
- [ ] `THIRD_PARTY_NOTICES.txt` and `LICENSES/OXANIUM_OFL.txt` are beside the EXE.
- [ ] SHA-256 checksum is recorded for the uploaded ZIP/build.
- [ ] Windows SmartScreen behavior is checked; consider Authenticode signing.
- [ ] Test on a clean Windows 10/11 machine without Godot installed.

