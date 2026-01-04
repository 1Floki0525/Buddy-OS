# Buddy-OS ISO Build Fixes (Ollama Agent)

This outline captures the current blockers and the concrete fixes to get a
COSMIC + Buddy AI installer ISO building cleanly.

## Current Blockers and Fixes

1) Snap preseed loop device failures
- Symptom: `failed to setup loop device` during snapd/snap-preseed.
- Fix (host + LXD):
  - Load kernel modules: `sudo modprobe loop squashfs`
  - Ensure `/dev/loop-control` and `/dev/loop0..15` exist and are owned by root:disk.
  - LXD: `security.privileged=true`, `security.nesting=true`, add loop devices,
    and allow `b 7:*` + `c 10:237` in cgroup if needed.
  - Verify in container: `losetup -f` returns a loop device.

2) Subiquity translation clone failures (TLS error)
- Symptom: `git clone https://git.launchpad.net/subiquity` fails.
- Fix options:
  - Fast workaround: set `LOCALE_SUPPORT=none` to skip catalog translations.
  - Full fix: keep `LOCALE_SUPPORT=langpack` and add retry logic or cache
    `config/catalog-translations` locally.

3) COSMIC/Flatpak deps not installable
- Symptoms:
  - `libdisplay-info1`, `libseat1`, `fonts-open-sans`, `libostree-1-1`,
    `qalc`, `fd-find` missing.
- Fix:
  - Ensure Ubuntu universe/multiverse are enabled inside chroot.
  - Ensure Pop!_OS repos + key are present:
    - `/etc/apt/sources.list.d/pop-os-release.sources`
    - `/etc/apt/sources.list.d/pop-os-apps.sources`
    - `/etc/apt/trusted.gpg.d/pop-keyring-2017-archive.gpg`
  - `apt-get update` before installing COSMIC.

4) Buddy package list missing in chroot
- Symptom: `cat /usr/share/buddy-os/package-lists/buddy-cosmic.list.chroot: No such file`.
- Fix:
  - Ensure `config/includes.chroot` is always copied into chroot (layered build).
  - Confirm file exists at `/usr/share/buddy-os/package-lists/`.

## Buddy AI Integration Checks (Post-Install)

- Rootfs overlay applied:
  - `/opt/buddy-os/` present
  - `/etc/systemd/system/buddy-actionsd.service` enabled
  - `/etc/systemd/system/buddy-voice.service` enabled
- Desktop entries:
  - `/usr/share/applications/buddy-ai-settings.desktop`
  - `/usr/share/applications/buddy-copilot.desktop`
- Icons:
  - `/usr/share/icons/hicolor/256x256/apps/buddy-ai.png`
- Plymouth theme:
  - `/usr/share/plymouth/themes/buddy-os/`

## Build Commands (Host → LXD)

1) Host prep (once):
```
sudo modprobe loop squashfs
sudo mknod -m 0666 /dev/loop-control c 10 237 || true
for i in $(seq 0 15); do sudo mknod -m 0660 "/dev/loop$i" b 7 "$i" || true; done
sudo chown root:disk /dev/loop-control /dev/loop*
```

2) LXD permissions (once):
```
sudo lxc config set buddy-build security.privileged true
sudo lxc config set buddy-build security.nesting true
sudo lxc config device add buddy-build loop-control unix-char source=/dev/loop-control path=/dev/loop-control
for i in $(seq 0 15); do
  sudo lxc config device add buddy-build loop$i unix-block source=/dev/loop$i path=/dev/loop$i
done
sudo lxc restart buddy-build
```

3) Build ISO:
```
sudo lxc exec buddy-build -- bash -lc 'cd /workspace && scripts/build/build_iso.sh'
```

4) Verify output:
```
ls -lh build/iso/Buddy-OS-0.0.0.iso
sha256sum build/iso/Buddy-OS-0.0.0.iso > build/iso/Buddy-OS-0.0.0.iso.sha256
```

## Locale Support Note

If you want full installer translations, remove `LOCALE_SUPPORT=none` from
`scripts/build/build_iso.sh` and make sure the subiquity translation clone
can succeed (retry or cache).
