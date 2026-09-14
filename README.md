# Okonomi_OS

Okonomi_OS is not a distro. It is a thin, unopinionated installer layer on top of stock Arch Linux.

It exists to automate the tedious plumbing of an Arch desktop install — partitioning bootstrap, base packages, GPU detection, audio, display manager, fonts, portals — without imposing anyone's taste in apps, editors, browsers, keybinds, or workflow.

You bring your stack. It does the plumbing.

## Philosophy: Okonomi vs Omakase

Most Arch-based distros follow an omakase model: "I'll leave it up to the chef."

The chef picks Hyprland + Waybar + Alacritty + Neovim + Firefox + exact keybinds + theme. If you agree with 100% of it, great. If you disagree with 20%, you spend hours ripping out someone else's opinions.

Okonomi is the linguistic opposite. Okonomi means "as you like it" — as in okonomiyaki, where you choose your own ingredients.

In OS design this is the old UNIX principle of Separation of Mechanism and Policy:

- Policy (Omakase / Omarchy model): decides what you should run and how you must experience it.
- Mechanism (Okonomi_OS model): provides tools and infrastructure to build it, without dictating how.

Okonomi_OS is mechanism, not policy.

## The Missing Middle

Right now you have two choices:

1. Barebones Arch: stock ISO, TTY, wiki homework, blank black screen after reboot.
2. Opinionated respin: Endeavour, Garuda, Omarchy — a finished meal.

There is no worthy middleground: something that abstracts the boring, error-prone parts while leaving you king of your castle.

That is what this is. A post-archinstall desktop plumber.

It installs no software by choice. No browser. No media player. No office suite. No text editor. No hardcoded dotfiles religion.

It installs plumbing:

- multilib, base-devel, Mesa / Vulkan / XWayland base
- GPU detection: Intel / AMD / NVIDIA + early KMS modesetting + VM guests
- PipeWire + WirePlumber + volume tools
- Display manager (SDDM by default)
- fontconfig fallbacks, Nerd Fonts, emoji, icon glyphs
- xdg-desktop-portal wiring per compositor

Then it hands you a menu and gets out of the way.

## How It Works

This repo contains no desktop configs. Those live in the framework repo:

https://github.com/NeilMeyer082/neil-arch-rice

This repo contains only the ISO autoload path:

1. Boot stock Arch ISO (or this pre-baked ISO, which is just stock releng + autoloader)
2. On tty1 as root, run: `arch-rice-loader.sh`
3. That runs: `archinstall --config-url .../archinstall/rice.json`
4. `rice.json` is a partial config. It forces only:
   `git, ansible, dialog, base-devel, python, curl, sudo, networkmanager, vim`
   plus `multilib`. Disk, locale, user, bootloader still prompt interactively.
5. `custom_commands` in `rice.json` installs a one-shot firstboot service into the target
6. Reboot into the installed system
7. First boot clones the framework live from GitHub to `~/arch-rice`, chmods `bootstrap.sh`, then disables itself
8. You log in as your user and run: `~/arch-rice/bootstrap.sh`
9. 18 dialog menus: 9 window managers, 7 bars, 5 terminals, 3 shells, 10 themes, fonts, cursors, icons, launchers, notifications, lockers, multiplexers, fetch, file manager
10. Ansible applies only what you picked, rendering Jinja2 templates straight into `~/.config/`

Nothing is baked into the ISO. Packages still come fresh from official repos, AUR via `yay`, and upstream GitHub tarballs at install time.

Push to `main` in the framework repo = live immediately. No ISO rebuild needed.

## Why Not Run bootstrap.sh From archinstall Directly

`archinstall` custom_commands run as root, chrooted, non-interactive, no TTY.

`bootstrap.sh` needs the opposite: interactive dialog menus, a real user (yay refuses root, ~/.config must land in your home), and network + systemd user session.

So it is split:

- Stage 1 (archinstall, root): base system + deps + drop firstboot unit
- Stage 2 (first boot, user): clone + run bootstrap.sh interactively

## Repo Layout

```
Okonomi_OS/
├── README.md
├── archlinux-2026.09.14-x86_64.iso  # example build, stock releng + loader
├── airootfs/
│   ├── usr/local/bin/arch-rice-loader.sh  # pacman archinstall if needed, launch --config-url
│   ├── root/.bash_profile                 # autoload once on tty1 (bash)
│   ├── root/.zprofile                      # autoload once on tty1 (zsh, releng default)
│   └── etc/motd                            # banner
├── apply.sh   # merge airootfs/ into ~/archlive + patch profiledef.sh
└── build.sh   # privileged Arch container build for Fedora hosts
```

The framework itself (`bootstrap.sh`, `playbook.yml`, `roles/`, `group_vars/`) stays in `neil-arch-rice`. This repo stays thin on purpose.

## Build Your Own ISO

You do not need a custom ISO to use this. Stock Arch ISO works:

```
pacman -Sy archinstall
archinstall --config-url https://raw.githubusercontent.com/NeilMeyer082/neil-arch-rice/main/archinstall/rice.json
```

To build the autoloading ISO:

On Arch:

```
sudo pacman -S archiso
cp -r /usr/share/archiso/configs/releng ~/archlive
./apply.sh ~/archlive
sudo mkarchiso -v -w /tmp/archiso-tmp -o ~/out ~/archlive
```

On Fedora (docker, Arch container):

```
./apply.sh ~/archlive
./build.sh ~/archlive ~/out ~/archiso-tmp
```

Work dir must be on disk, not tmpfs. Builds need 4-8 GB and produce a ~1.6 GB hybrid ISO. Test with:

```
qemu-system-x86_64 -enable-kvm -m 4G -cdrom ~/out/*.iso -boot d
```

Or flash with dd and boot bare metal / VirtualBox (EFI on, VMSVGA, 4 GB RAM).

## What This Is Not

- Not a distro fork. No rebranded os-release, no frozen package set.
- Not stable-release friendly yet. Arch first. Fedora / Ubuntu minimal variants are a v2 side quest, after the Arch plumber is boring and reliable.
- Not a dotfiles repo. It generates working starting configs you are supposed to edit and learn from.

## Roadmap

- v0: stock ISO + --config-url + firstboot clone + bootstrap.sh working on bare metal, NVIDIA, and VM
- v1: pinned releases + --edge flag, survive 2-3 monthly Arch ISOs untouched
- v2: consider Fedora Everything Kickstart %post / Ubuntu minimal autoinstall late-commands pointing at the same Jinja templates. Same taste, stable plumbing.

The useful artifact is the plumber, not the ISO.
