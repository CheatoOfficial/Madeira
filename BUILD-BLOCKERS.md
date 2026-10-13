# Madeira iOS build blockers

## Current result

No complete IPA has been produced. Do not install or distribute an IPA from
these attempts. The source is the head of `integration/upstream-0926`,
`1550c82114b6a94bd4157633c16fec9ac7cd1ad8`; the requested commit
`25f36e1cec7e3b1f9ee9072f90aa860f4829ec7e` is in its history. The checked out
head also includes the later `ml2014`–`ml2016` commits present on that branch.
No unrelated `pr/*`, `pr2/*`, or `wip/*` branches were merged.

The requested destination is the public fork
[CheatoOfficial/Madeira](https://github.com/CheatoOfficial/Madeira). Its current
`main` is an ancestor of the requested source branch. The public update must not
expose Microsoft's VC++ runtime binaries.

## Microsoft runtime distribution boundary

The Xcode Resources phase requires these twelve Microsoft files in
`app/Madeira/x86_64-vcruntime/`:

```text
concrt140.dll
msvcp140.dll
msvcp140_1.dll
msvcp140_2.dll
msvcp140_atomic_wait.dll
msvcp140_codecvt_ids.dll
vcamp140.dll
vccorlib140.dll
vcomp140.dll
vcruntime140.dll
vcruntime140_1.dll
vcruntime140_threads.dll
```

The project policy in `tools/fetch-vcruntime.md` says these Microsoft-authored
DLLs are not distributable under the project license. They are not committed
or included in public downloadable artifacts. The workflow downloads the
version-pinned official Microsoft `VC_redist.x64.exe` to the temporary macOS
runner and verifies the EXE and each extracted DLL against
`vc-runtime-provenance.json`. A validated IPA can be assembled on that runner,
but it is not uploaded because it contains the DLLs. A local Windows copy has
also been staged and verified; its files remain ignored by git. Do not omit the
DLLs from an IPA silently.

## Latest macOS build attempt

Run [38257638232](https://github.com/CheatoOfficial/Madeira/actions/runs/38257638232)
for commit `cf09eebfeab2daebe09fffb9f94e3bb48b54b52b` reached the FEX ARM64EC
link after the runtime staging and redistributable helper-library steps
succeeded. LLVM-MinGW `20260728` provided a native ARM64EC sysroot, but its
libc++ archive diagnostics exposed only the `#__gxx_personality_seh0` alias and
not the required EC C++ method definitions. The normal link consequently
failed on `__gxx_personality_seh0`, mutex and shared-mutex methods, filesystem,
and other libc++ symbols. Wine, DXMT, Xcode, and IPA packaging were skipped.

Run [38264269586](https://github.com/CheatoOfficial/Madeira/actions/runs/38264269586)
for commit `093b4b0040dea193596c852818007ff6c3c9c492` confirmed that a second
`-lc++ -lc++abi -lunwind` pass after the FEX static archives does not fix the
unresolved EC symbols. Upstream LLVM-MinGW's ARM64X change moves ARM64EC
runtime support into the AArch64 sysroot. Run `38385791874` then showed that
passing `-marm64x` to the dedicated ARM64EC compiler is rejected by Clang:
`unsupported option '-marm64x' for target 'arm64ec-w64-mingw32'`. The next
attempt uses the upstream-documented AArch64 compiler driver with an explicit
plain ARM64EC target. This is unverified; no full build or IPA has succeeded.

Earlier attempts established that `<cstdlib>` alone did not fix FEX's
`std::strtoll` declarations, while adding `<stdlib.h>` and using the global
`::strtoll`/`::strtoull` declarations allowed compilation. Runs
[38237643171](https://github.com/CheatoOfficial/Madeira/actions/runs/38237643171)
and [38243920366](https://github.com/CheatoOfficial/Madeira/actions/runs/38243920366)
also showed that whole-archiving both libc++ and libc++abi introduces duplicate
exception-runtime symbols. No attempt has reached Wine native archives, DXMT,
Xcode, or IPA packaging.

## macOS build status

The Windows workspace has no Xcode, and no complete IPA exists. Public macOS
run [36436248487](https://github.com/CheatoOfficial/Madeira/actions/runs/36436248487)
allocated a runner, checked out recursive submodules, and recorded macOS 15.7.9,
Xcode 16.4 (16F6), and iPhoneOS SDK 18.5. Its readiness audit found 23 missing
inputs: the eleven generated linker archives and the twelve Microsoft DLLs
listed above. It stopped before any native build. The current workflow removes
that premature stop, fetches and verifies the official redistributable on the
runner, then attempts the complete native and Xcode build. The latest attempt
and its exact failure are recorded above. The user declined extra Actions
spending; these public standard-runner jobs start without the previous
private-repository billing block.

## Previous private-repository runner failures

GitHub did not start the latest workflow job. Its check-run annotation says:

> The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the 'Billing & plans' section in your settings

Runs [36432170346](https://github.com/CheatoOfficial/GTASanAndreas3DS/actions/runs/36432170346)
and [36432537267](https://github.com/CheatoOfficial/GTASanAndreas3DS/actions/runs/36432537267)
failed before runner allocation (`runner_id` 0; no steps or build log). These
were runs in the previous private destination. The user declined to spend on
Actions billing. The current public repository workflow now allocates macOS
runners; these private-repository failures are historical.

## Last actual macOS build failure

Run [36429453349](https://github.com/CheatoOfficial/GTASanAndreas3DS/actions/runs/36429453349)
used macOS 15.7.9, Xcode 16.4 (16F6), and iPhoneOS SDK 18.5. Recursive
submodules, the readiness step, and the redistributable helper-library step
completed. FEX's iOS archives compiled. The first unresolved build error was
the ARM64EC FEX DLL link using LLVM-MinGW 20260616 / Clang 22.1.8:

```text
ld.lld: error: undefined symbol: __gxx_personality_seh0 (EC symbol)
ld.lld: error: undefined symbol: std::__1::recursive_mutex::lock() (EC symbol)
ld.lld: error: undefined symbol: std::__1::mutex::lock() (EC symbol)
clang: error: linker command failed with exit code 1
```

This earlier run used LLVM-MinGW `20260616` / Clang 22.1.8. The subsequent
compile issue and current ARM64EC link issue are documented under “Latest
macOS build attempt.” The later Wine PE, DXMT, native Wine archive, Xcode,
packaging, and IPA validation stages have not completed on this revision.

## Readiness audit

Before native builds, the readiness audit reported these 11 missing generated
linker inputs:

- `FEX/build-ios/FEXCore/Source/libFEXCore.a`
- `FEX/build-ios/FEXCore/Source/libFEXCore_Base.a`
- `FEX/build-ios/FEXCore/Source/libJemallocLibs.a`
- `FEX/build-ios/External/fmt/libfmt.a`
- `FEX/build-ios/External/cephes/libcephes_128bit.a`
- `FEX/build-ios/External/xxhash/cmake_unofficial/libxxhash.a`
- `FEX/build-ios/External/SoftFloat-3e/libsoftfloat_3e.a`
- `app/Madeira/libntdll_unix.a`
- `app/Madeira/libwineserver.a`
- `app/Madeira/libwin32u_unix.a`
- `app/Madeira/libdxmt_combined.a`

These are expected build outputs. On run 364294 the workflow generated the
FEX iOS archives and GnuTLS, FreeType, and FFmpeg helper libraries before
stopping at ARM64EC FEX. Wine ntdll, wineserver, win32u, DXMT, and Xcode have
not yet run to completion. The current workflow builds dependencies in their
required order and does not package an incomplete app.

Recursive submodules were initialized at their pinned gitlinks. Root pins:

- FEX `7b528d8a57cb12b794c589dd7e42fff813fc9abd`
- Wine `65fab17629dd768de44711082c7cfa5e199278b1`
- DXMT `550735c32c1a2faa68fa4fe504ac827e0f341831`

Nested pins are listed in `build-manifest.json` and in the macOS environment
log.

## Runtime limitation

GTA V has not been verified on a physical iPhone. The Discord release note
provided for this task says the release does not support third-party launchers
such as Rockstar Games Launcher. Madeira Dock availability, or optionally
installing the Windows Steam client, does not provide Rockstar Launcher/Social
Club support; the Windows Steam client also uses more CPU and memory. Retail
GTA V normally requires Rockstar authentication, so this build is not
established as compatible with GTA V. A direct `GTA5.exe` launch is diagnostic
only, not a supported workaround. GTA V remains a known runtime blocker, not an
iOS build failure; it must not be called working without launcher support and
physical-device verification.
