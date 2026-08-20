<div align="center">
  <h3>A Custom<br>DevTools theme <br> for Chromium-based browsers</h3>
  <br>
  <img src=".github/assets/banner.png" width="60%" />
  <br>
  <br>
  <img src="https://raw.githubusercontent.com/metaory/devtools-theme/screenshots/screenshot-0.png" width="90%" />
  <br>
  <br>

  <img src="https://raw.githubusercontent.com/metaory/devtools-theme/screenshots/screenshot-0.png" width="90%" />
  <!-- screenshots -->
  <img src="https://raw.githubusercontent.com/metaory/devtools-theme/screenshots/screenshot-1.png" width="40%" />&nbsp;&nbsp;<img src="https://raw.githubusercontent.com/metaory/devtools-theme/screenshots/screenshot-2.png" width="40%" />
  <br>
  <br>
  <img src="https://raw.githubusercontent.com/metaory/devtools-theme/screenshots/screenshot-3.png" width="40%" />&nbsp;&nbsp;<img src="https://raw.githubusercontent.com/metaory/devtools-theme/screenshots/screenshot-4.png" width="40%" />
  <br>
  <br>
  <img src="https://raw.githubusercontent.com/metaory/devtools-theme/screenshots/screenshot-5.png" width="40%" />&nbsp;&nbsp;<img src="https://raw.githubusercontent.com/metaory/devtools-theme/screenshots/screenshot-6.png" width="40%" />
  <!-- /screenshots -->
</div>

---

<div align="center">
  <a href="#install">Install</a> · <a href="#alias">Alias</a> · <a href="#customize">Customize</a> · <a href="#troubleshoot">Troubleshoot</a> · <a href="#fork">Fork</a>
  <br>
  <br>
  <p>
    <a href="https://github.com/metaory/devtools-theme/releases/tag/nightly"><img alt="Nightly" src="https://img.shields.io/github/check-suites/metaory/devtools-theme/nightly?style=flat&label=nightly&labelColor=31a"></a>
    <a href="https://github.com/metaory/devtools-theme/releases/latest"><img alt="Release" src="https://img.shields.io/github/v/release/metaory/devtools-theme?style=flat&label=&labelColor=31a&color=61E"></a>
    <a href="https://github.com/metaory/devtools-theme/releases/latest"><img alt="Release Date" src="https://img.shields.io/github/release-date/metaory/devtools-theme?style=flat&label=&labelColor=31a&color=61E"></a>
    <a href="https://github.com/metaory/devtools-theme/releases/latest"><img alt="Chromium version" src="https://img.shields.io/badge/dynamic/regex?style=flat&url=https%3A%2F%2Fgithub.com%2Fmetaory%2Fdevtools-theme%2Freleases.atom&search=chromium%40(%5B0-9.%5D%2B)&replace=%241&logo=googlechrome&logoColor=bae&label=&color=31a&labelColor=31a"></a>
    <a href="LICENSE"><img alt="License" src="https://img.shields.io/github/license/metaory/devtools-theme?style=flat&label=&labelColor=31a&color=61E"></a>
  </p>
</div>

---

This repo ships a themed DevTools UI for `--custom-devtools-frontend`

Releases track Chrome **stable**

---

## Install

1. Download `devtools-frontend.tar.zst` from the [latest release](https://github.com/metaory/devtools-theme/releases/latest)
2. Extract per OS below
3. Quit the browser completely if it is already running, then launch per OS below
4. Open DevTools (`F12`). UI should match the screenshots above

```sh
gh release download -R metaory/devtools-theme \
  -p 'devtools-frontend.tar.zst'
```

or

```sh
curl -fL --progress-bar -O \
  https://github.com/metaory/devtools-theme/releases/latest/download/devtools-frontend.tar.zst
```

To update later: download the newest release and extract into the same directory again

### Linux

1. Extract:

```sh
mkdir -p "$HOME/.local/share/chromium"
tar -xaf devtools-frontend.tar.zst -C "$HOME/.local/share/chromium"
```

If extract fails, install `zstd`, or use:

```sh
zstd -dc devtools-frontend.tar.zst | tar -xf - -C "$HOME/.local/share/chromium"
```

2. Launch:

```sh
chromium --custom-devtools-frontend="file://$HOME/.local/share/chromium/front_end"
# or
google-chrome --custom-devtools-frontend="file://$HOME/.local/share/chromium/front_end"
# brave-browser / microsoft-edge / vivaldi / … : same flag and path
```

### macOS

Same install path as Linux (`$HOME/.local/share/chromium`), not `~/Library/...`

1. Install `zstd`:

```sh
brew install zstd
```

2. Extract:

```sh
mkdir -p "$HOME/.local/share/chromium"
zstd -dc devtools-frontend.tar.zst | tar -xf - -C "$HOME/.local/share/chromium"
```

3. Launch:

```sh
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --custom-devtools-frontend="file://$HOME/.local/share/chromium/front_end"
```

### Windows

Use Windows 11 (`tar` reads `.zst`)

1. Download with `curl.exe`:

```sh
curl.exe -fL --progress-bar -O https://github.com/metaory/devtools-theme/releases/latest/download/devtools-frontend.tar.zst
```

2. Extract:

```sh
mkdir -Force "$env:LOCALAPPDATA\chromium"
# e.g. C:\Users\you\AppData\Local\chromium
tar -xaf devtools-frontend.tar.zst -C "$env:LOCALAPPDATA\chromium"
```

3. Launch:
   - `PowerShell`:

     ```sh
     & "C:\Program Files\Google\Chrome\Application\chrome.exe" `
       --custom-devtools-frontend="file:///$($env:LOCALAPPDATA -replace '\\','/')/chromium/front_end"
     ```

   - `cmd`:

     ```sh
     "C:\Program Files\Google\Chrome\Application\chrome.exe" --custom-devtools-frontend=file:///%LOCALAPPDATA%/chromium/front_end
     ```

     Absolute path:

     ```sh
     "C:\Program Files\Google\Chrome\Application\chrome.exe" --custom-devtools-frontend=file:///C:/Users/you/AppData/Local/chromium/front_end
     ```

---

> [!NOTE]
> Other Chromium browsers (Brave, Edge, Vivaldi, …):
>
> Same `--custom-devtools-frontend` flag and `file://…/front_end` path;
>
> Swap only the binary name

For every launch after this, use an [Alias](#alias)

> [!TIP]
> Open DevTools on startup with `--auto-open-devtools-for-tabs`

---

## Alias

Add `--custom-devtools-frontend` on every browser launch so the theme sticks

> [!IMPORTANT]
>
> - Use a `file://` URL to the extracted `front_end` directory
> - Linux and macOS: `file:///home/...` (three slashes). Windows: `file:///` plus a forward-slash path
> - Without the `file://` scheme, the browser loads the bundled DevTools

> [!NOTE]
>
> - A new launch reuses a running browser and ignores extra flags
> - Quit the browser completely and relaunch, or add `--user-data-dir` with a separate profile

### Linux

> [!CAUTION]
>
> Write the right-hand side with `command chromium`, `\chromium`, or a full path like `/usr/bin/chromium`
>
> An alias that calls `chromium` by name loops forever

1. Add to `~/.bashrc` or `~/.zshrc`:

```sh
alias chromium='command chromium --custom-devtools-frontend="file://$HOME/.local/share/chromium/front_end"'
# or: alias chromium='\chromium --custom-devtools-frontend="file://$HOME/.local/share/chromium/front_end"'
# or: alias chromium='/usr/bin/chromium --custom-devtools-frontend="file://$HOME/.local/share/chromium/front_end"'
alias chrome='google-chrome --custom-devtools-frontend="file://$HOME/.local/share/chromium/front_end"'
```

2. Reload the shell
3. Launch with `chromium` or `chrome` or …

Optional separate profile: `--user-data-dir="$HOME/.config/chromium-custom"`

> [!IMPORTANT]
> This is Not a Chromium feature
>
> Arch packages wrap the binary and read extra flags from a file
>
> Other distros ignore it

<details>
<summary>Arch Linux</summary>

Arch Linux users can use this file to set flags permanently:

`~/.config/chromium-flags.conf`

- chromium: `~/.config/chromium-flags.conf`
- Chrome AUR: `~/.config/chrome-flags.conf`

Unquoted path. `$HOME` is not expanded in the file.

```sh
--custom-devtools-frontend=file:///home/{YOUR_USERNAME}/.local/share/chromium/front_end
```

</details>

> [!CAUTION]
> Do Not use tilde character(`~`) or `$HOME` in the path

### macOS

1. Add to `~/.zshrc`:

```sh
alias chrome='"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --custom-devtools-frontend="file://$HOME/.local/share/chromium/front_end"'
```

2. Reload the shell
3. Launch with `chrome`

Optional separate profile: `--user-data-dir="$HOME/.config/chromium-custom"`

> [!TIP]
> Prefer the binary path above. `open -a "Google Chrome"` needs `--args` for flags, and still reuses a running browser

### Windows

> [!WARNING]
>
> - Use a function in `$PROFILE` (print the path with `$PROFILE`)
> - `Set-Alias` cannot pass arguments
> - `PowerShell 7`: `Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
> - `PowerShell 5.1`: `Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`

1. Create or open your profile:

```sh
if (!(Test-Path $PROFILE)) { New-Item $PROFILE -Force }
notepad $PROFILE
```

2. Add:

```sh
function chrome {
  & "C:\Program Files\Google\Chrome\Application\chrome.exe" `
    --custom-devtools-frontend="file:///$($env:LOCALAPPDATA -replace '\\','/')/chromium/front_end" @args
}
```

3. Allow the profile and load it:

```sh
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
. $PROFILE
```

4. Launch with `chrome` / `chromium` / …

Optional separate profile: `--user-data-dir="$env:LOCALAPPDATA\chromium-custom"`

---

## Customize

Change colors on your machine

1. Clone the repo:

```sh
git clone https://github.com/metaory/devtools-theme.git
cd devtools-theme
```

2. Edit [`config.css`](config.css):

- `--hue`
- `--sat-in` (0 gray, 50 default ramp, 100 ≈ 2× chroma)
- `--spread` (secondary `+spread`, tertiary `+2*spread` from `--hue`)
- `--hue-error`, `--hue-blue`, `--hue-cyan`, `--hue-pink`, `--hue-green`, `--hue-orange`, `--hue-yellow`

3. Requirements: `bash`, `curl`, `tar`, `sed`

- macOS: `brew install zstd`
- Windows: run from Git Bash;
- Windows 11 `tar` reads `.zst`

4. Run `./apply` to put your configuration on the local theme:

```sh
./apply                        # overlay, fetch if needed
./apply -h                     # print usage and exit
./apply -f                     # force fetch + extract
./apply -o                     # overlay, open browser
./apply /path/to.tar.zst       # extract this archive if needed
./apply -f -o /path/to.tar.zst # fetch to path, extract, open
```

Theme path:

- Linux / macOS: `$HOME/.local/share/chromium`
- Windows: `%LOCALAPPDATA%/chromium`

First run downloads `devtools-frontend.tar.zst` to `$TMPDIR` (usually `/tmp`)

> [!NOTE]
>
> - Without `-o`, prints the `file://` launch line
> - With `-o`, opens the browser; skipped if already running

5. For deeper changes, edit [`theme.css`](theme.css) (palette) or [`inspector.css`](inspector.css) (checkbox fill), then `./apply` again

> [!TIP]
> To pull a newer release onto an existing theme: `./apply -f`

---

## Troubleshoot

- Theme missing after launch: check the `file://` URL, quit the browser completely, relaunch. See [Install](#install) and [Alias](#alias)
- Launch ignores the flag: the browser was already running. Quit it, or use `--user-data-dir` with a separate profile
- `chromium-flags.conf` ignored: Arch packages only. See [Alias](#alias)
- Odd UI: compare the [release](https://github.com/metaory/devtools-theme/releases/latest) version to `chrome://version`. A large major gap can break things
- macOS extract fails: install `zstd` (`brew install zstd`), then extract again
- Linux extract fails: install `zstd`, or use the `zstd -dc … | tar` form under [Install](#install)
- Windows download fails in `PowerShell`: use `curl.exe`, not `curl`
- Windows extract fails: use Windows 11, or install a `tar` that reads `.zst`
- `./apply` says missing archive: the path you passed is missing or empty. Omit the path to download, or pass a real `.tar.zst`
- Undo: remove the alias or PowerShell function, delete `$HOME/.local/share/chromium/front_end` (Windows: `%LOCALAPPDATA%\chromium\front_end`), relaunch without the flag

---

## Fork

Publish your own themed release

See [docs/release-flow.md](docs/release-flow.md) for the full Build → nightly → Release path

1. Fork on GitHub
2. Clone your fork:

```sh
git clone https://github.com/you/devtools-theme.git
cd devtools-theme
```

3. Enable **Actions** (new forks start with Actions off)
4. Point [`apply`](apply) at your repo:

```sh
readonly repo='you/devtools-theme'
```

5. Push `config.css`, `theme.css`, or `inspector.css`, or run **Actions → Build → Run workflow**
6. Wait until Build is green and `nightly` moved
7. Run **Actions → Release → Run workflow**, then publish the draft release that lists `devtools-frontend.tar.zst`
8. Run `./apply -f`

---

## License

This project is based on [Chromium DevTools](https://github.com/ChromeDevTools/devtools-frontend)
and is distributed under the [BSD-3-Clause](LICENSE) license

The release archive contains a modified build of the Chromium DevTools UI
and includes the upstream license and third-party notices
