# Starship Configs

These configuration files change the appearance and behavior of Starship. Only 1 `starship.toml` file can be active at a time. Think of these files like profiles you can swap in and out by symlinking one of the files to `$HOME/.config/starship.toml`.

## How to

Choose a `.toml` configuration file from this directory. If you aren't sure which one to use, the [`_default.toml`](./_default.toml) is the one I'll spend the most time ensuring a stable, cross-platform experience. Then create a symbolic link to `$HOME/.config/starship.toml`.

### How to: create Linux symlink

```shell
ln -s /path/to/this/repo/configs/_default.toml $HOME/.config/starship.toml
```

### How to: create Windows symlink

```powershell
New-Item -Path C:\Users\$env:USERNAME\.config\starship.toml -ItemType SymbolicLink -Target .\configs\_default.toml
```
