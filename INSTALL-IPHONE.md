# Installing Madeira on iPhone

This checkout does not contain a verified IPA yet. Once a complete unsigned
IPA is produced by the documented macOS build, use a sideloading tool to sign
it with your own Apple ID or certificate. No Apple credentials or signing
material belong in this repository.

## Sign and install

- **SideStore or AltStore:** import the IPA and sign/install it with the Apple
  ID configured in the app. Free Apple IDs generally require periodic
  re-signing; follow the sideloading app's current instructions.
- **Sideloadly:** select the IPA, sign with your own Apple ID, and install to
  the connected iPhone.
- **Xcode:** open Devices and Simulators, connect the iPhone, and install an
  appropriately signed build. Xcode is also the route to use if you are
  building and signing directly from the project.

The app requests these entitlements:

- `com.apple.developer.kernel.increased-memory-limit`
- `com.apple.security.cs.allow-jit`
- `get-task-allow`

Whether a signing method provisions each entitlement depends on the signing
identity and profile. Check Madeira's Entitlements screen after installation.

## Enable JIT and start a game

1. Open Madeira's signing/entitlements view and confirm the requested
   entitlements were granted.
2. Before starting Madeira, enable JIT with StikJIT/StikDebug and attach the
   debugger as required by that tool's current instructions.
3. In Files, import game files that you legally own into Madeira's game
   storage/location. Do not use pirated game files.
4. Start with **1280x720**, **30 FPS**, **CPU count 4**, and **Performance**
   enabled. Adjust after confirming a stable launch.

## GTA V compatibility

The Discord release note shared for this build says the release does not
support third-party launchers such as Rockstar Games Launcher. Madeira Dock
being available, or optionally installing the Windows Steam client, does not
add Rockstar Launcher/Social Club support; the Windows Steam client also uses
more CPU and memory. Retail GTA V normally requires Rockstar authentication,
so this build is not established as compatible with GTA V. A direct
`GTA5.exe` launch is diagnostic only, not a supported workaround. Do not treat
GTA V as working unless Rockstar launcher support is added and the game is
verified on a physical device.
