# Starship Configuration <!-- omit in toc -->

![GitHub Created At](https://img.shields.io/github/created-at/redjax/starship)
![GitHub last commit](https://img.shields.io/github/last-commit/redjax/starship)
![GitHub commits this year](https://img.shields.io/github/commit-activity/y/redjax/starship)
![GitHub repo size](https://img.shields.io/github/repo-size/redjax/starship)

My configurations repository for the [Starship shell](https://starship.rs).

## Requirements

- A [Nerd Font](https://www.nerdfonts.com/)
  - i.e. [FiraCode Nerd Font](https://www.nerdfonts.com/font-downloads)
- Starship
  - Linux:
    - `curl -sS https://starship.rs/install.sh | sh`
  - Windows:
    - `winget`: `winget install Starship.Starship`
    - [`scoop`](https://scoop.sh): `scoop install starship`
    - [`chocolatey`](https://community.chocolatey.org/packages/starship): `choco install starship`

## Setup

After installing Starship, you need to initialize it with your shell.

- Linux:
  - Add this to `~/.bashrc`:
```shell
eval "$(starship init bash)"
```
- Windows:
  - Add this to your `$PROFILE` (you can edit your profile easily with `notepad.exe $PROFILE`):
```powershell
Invoke-Expression (&starship init powershell)
```

### Manual

Choose a [Starship configuration](./configs/) and symlink it to `$HOME/.config/starship.toml`.

*Linux*

```shell
## Replace _default.toml with any config you want to use in the ./configs path
ln -s /path/to/this/repo/configs/_default.toml $HOME/.config/starship.toml
```

*Windows*

```powershell
New-Item -Path C:\Users\$env:USERNAME\.config\starship.toml -ItemType SymbolicLink -Target .\configs\_default.toml ## Choose any .toml file in the configs/ path
```

## Notes

...

## Links

- [Starship homepage](https://starship.rs)
- [Starship git repository](https://github.com/starship/starship)
- [Starship docs](https://starship.rs/config/)
- [Starship presets (themes)](https://starship.rs/presets/)
- [AdamDehaven.com: How to customize your shell prompt with Starship](https://www.adamdehaven.com/snippets/how-to-customize-your-shell-prompt-with-starship)
- [TheCodependentCodr.com: Using Starship for terminal prompt goodness](https://www.codependentcodr.com/using-starship-for-terminal-prompt-goodness.html)
