    # 🍱 Okonomi_OS
    
    **Okonomi_OS** is not a traditional Linux distribution fork. It is a ultra-thin, unopinionated deployment layer built directly on top of stock **Arch Linux**.
    
    Its sole purpose is to automate the tedious, low-level mechanics of an Arch desktop installation—disk bootstrapping, base packages, automatic GPU driver detection, audio routing, display managers, font fallbacks, and xdg-desktop-portals—without imposing anyone's personal taste in browsers, text editors, keybindings, or daily workflows.
    
    > **The Core Promise:** You bring your application stack. Okonomi_OS handles the plumbing.
    
    ---
    
    ## 🎯 Philosophy: Okonomi (お好み) vs. Omakase
    
    Most Arch-based distributions follow an *omakase* philosophy—the Japanese culinary term meaning *"I'll leave it up to the chef."* The creator chooses Hyprland + Waybar + Kitty + Neovim + Firefox, along with their exact keybindings and color scheme. If you love 100% of their choices, it’s great. But if you disagree with even 20%, you spend hours tearing out someone else's opinionated defaults and overriding their scripts.
    
    **Okonomi (お好み)** is the direct linguistic antonym. Translating to *"as you like it"* (as seen in *okonomiyaki*, the savory pancake where you choose all your own ingredients), the Okonomi paradigm brings the classic **UNIX Philosophy** to desktop deployment:
    
    * **Policy (Omakase / Omarchy Model):** Dictates *what* you should run and *how* you must experience your system (e.g., *"We use Firefox, Neovim, and this hardcoded theme"*).
    * **Mechanism (Okonomi_OS Model):** Provides the *tools and infrastructure* to build your desktop without dictating how you must use it.
    
    **Okonomi_OS is mechanism, not policy.**
    
    ---
    
    ## 🌉 The Missing Middle
    
    Currently, setting up a custom Arch desktop forces you to choose between two extreme options:
    
    1. **Barebones Vanilla Arch:** A stock ISO, a blank TTY prompt, endless wiki homework, and a black screen after your first reboot.
    2. **Monolithic Respins (EndeavourOS, Garuda, Omarchy):** A pre-cooked meal packed with bundled apps and hardcoded workflow opinions.
    
    There is a huge gap in the middle: a tool that abstracts the boring, error-prone system plumbing while keeping you **king of your own castle**. 
    
    Okonomi_OS is a post-`archinstall` desktop plumber. It intentionally installs **no user-space software by choice**—no browsers, media players, office suites, or text editors. Instead, it wires together the foundational infrastructure:
    
    * **Base Toolchain:** `multilib`, `base-devel`, Mesa / Vulkan / XWayland foundations.
    * **Hardware & Graphics:** Hardware GPU detection (Intel / AMD / NVIDIA) with early KMS modesetting and VM guest agent support.
    * **Audio Stack:** PipeWire + WirePlumber + low-level volume control utilities.
    * **Display Management:** Clean session management (SDDM by default).
    * **Typography:** `fontconfig` fallback rules, Nerd Fonts, emoji support, and icon glyphs.
    * **Desktop Integration:** `xdg-desktop-portal` environment wiring per compositor.
    
    Once the plumbing is secure, it hands you a menu and gets out of the way.
    
    ---
    
    ## ⚙️ How It Works
    
    This repository contains no desktop configurations. All desktop ricing roles and Jinja2 templates live in the main framework repository:  
    👉 [neil-arch-rice GitHub Repository](https://github.com/NeilMeyer082/neil-arch-rice)
    
    This repository serves strictly as the ISO autoloading layer:
    
    ```
    [Boot Stock ISO / Live Media]
                │
                ▼
     1. Launch `arch-rice-loader.sh` on TTY1
                │
                ▼
     2. `archinstall` provisions Base OS via `rice.json`
        (Installs git, ansible, dialog, python, networkmanager, base-devel)
                │
                ▼
     3. `custom_commands` drops a one-shot Firstboot Systemd Service
                │
                ▼
     4. Reboot into Target System
                │
                ▼
     5. Firstboot Service clones framework live from GitHub to `~/arch-rice`
                │
                ▼
     6. User runs `~/arch-rice/bootstrap.sh` (18 Dialog TUI Selection Menus)
                │
                ▼
     7. Ansible applies choices directly to `~/.config/` via Jinja2 templates
     ```
 
Nothing is baked into the ISO image. All packages are pulled fresh from official Arch mirrors, the AUR via `yay`, and upstream releases at install time. Pushing an update to `main` in the framework repo takes effect immediately—no ISO rebuild required.

## 🔀 Why Split `archinstall` and `bootstrap.sh`?

`archinstall` custom commands run inside a `chroot` environment as **root**, non-interactively, without an active TTY session.

### Conversely, `bootstrap.sh` requires:

-   An interactive `dialog` TUI menu for user input.
    
-   An active, non-root user (`yay` blocks execution under root, and user configs must land cleanly inside `$HOME`).
    
-   A running systemd user session and active network connection.
    
By splitting execution into **Stage 1 (System Plumbing via `archinstall`)** and **Stage 2 (Interactive User Ricing via Firstboot)**, we get the best of both worlds.

## 📂 Repository Layout

    Okonomi_OS/
    ├── README.md                              # Documentation
    ├── archlinux-2026.09.14-x86_64.iso        # Example ISO build (Stock releng + loader)
    ├── airootfs/
    │   ├── usr/local/bin/arch-rice-loader.sh  # Triggers archinstall using remote config URL
    │   ├── root/.bash_profile                 # Autoload trigger for Bash (TTY1)
    │   ├── root/.zprofile                     # Autoload trigger for Zsh (releng default)
    │   └── etc/motd                           # Live environment welcome banner
    ├── apply.sh                               # Merges airootfs/ into ~/archlive & patches profiledef.sh
    └── build.sh                               # Privileged Arch container build script (for Fedora hosts)

## 🛠️ Building Your Own ISO

You do not need a custom ISO to use Okonomi_OS. You can run it directly on a standard Arch Linux ISO:

    `pacman -Sy archinstall`
    `archinstall --config-url https://raw.githubusercontent.com/NeilMeyer082/neil-arch-rice/main/archinstall/rice.json`
    
### Building the Auto-Loading ISO

#### On Arch Linux:

    `sudo pacman -S archiso`
    `cp -r /usr/share/archiso/configs/releng ~/archlive`
    `./apply.sh ~/archlive`
    `sudo mkarchiso -v -w /tmp/archiso-tmp -o ~/out ~/archlive`
    

#### On Fedora (via Container/Docker):

    `./apply.sh ~/archlive`
    `./build.sh ~/archlive ~/out ~/archiso-tmp`
    
> **Note:** The working build directory must reside on physical disk storage (not `tmpfs`). Builds require 4–8 GB of RAM and produce a ~1.6 GB hybrid ISO image.

### Testing Your ISO

Test your built ISO using QEMU:

    `qemu-system-x86_64 -enable-kvm -m 4G -cdrom ~/out/*.iso -boot d`
    
Alternatively, flash the ISO to a USB drive using `dd` and boot on bare-metal or VirtualBox (ensure EFI is enabled and graphics controller is set to VMSVGA).

## 🚫 What This Is Not

-   **Not a Distro Fork:** No rebranded `/etc/os-release`, no frozen package repositories, and no custom kernel builds.
    
-   **Not an Opinionated Dotfiles Repo:** It generates clean, human-readable reference configurations designed for you to edit, modify, and learn from.
    
-   **Not a Monolithic Package Bundle:** It will never force a specific web browser or text editor onto your installation.
    

## 🗺️ Project Roadmap

-   [x] **v0 (Current):** Stock ISO + remote `archinstall` config + Firstboot framework cloning + interactive `bootstrap.sh` pipeline working on bare-metal, NVIDIA hardware, and VMs.
    
-   [ ] **v1 (Edge & Stability):** Pinned releases with an `--edge` flag; verifying bootloader compatibility across 2-3 monthly Arch ISO releases without manual intervention.
    
-   [ ] **v2 (Cross-Distro Plumbing):** Adapting the underlying Jinja2 templates to support minimal Fedora Everything (%post kickstart) and Ubuntu Minimal autoinstalls. Same desktop experience, alternative system plumbing.
    

_The useful artifact is the plumber, not the ISO._
