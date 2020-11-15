This script details installing a unified shell experience on all systems

# Install a better font

## Windows
1. Double-click and install the font file `Fira Mono Regular Nerd Font Complete Mono Windows Compatible.ttf`
2. Run the following in an admin prompt
```powershell
# Run the following in an admin prompt
$epol = Get-ExecutionPolicy
Set-ExecutionPolicy "Unrestricted" -force
./InstallConsoleFont.ps1 'FiraMono NF' -FontFile "Fira Mono Regular Nerd Font Complete Mono Windows Compatible.ttf"
Set-ExecutionPolicy $epol -force
```
3. Terminal > right click Properties > Font > FireMono NF


## Mac OS X
@todo

## Linux
The following instructions are for debian derived distributions

```sh
sudo apt-get install fontconfig -y
cp 'Fura Mono Regular Nerd Font Complete.otf' /usr/local/share/fonts
sudo fc-cache -f -v
```

## Configure Bash
Normally bash reads `~/.bashrc`; however Mac OS X opens `Terminal.app` as a interactive login shell. Therefore we should configure `~/.bash_profile` to load `~/.bashrc` on launch

```sh
# Ensure the following line exists in ~/.bash_profile
source ~/.bashrc
```

We use a basic `~/.bashrc` sourced from ubuntu
```sh
cp bashrc ~/.bashrc
```

`~/.bashrc` generally loads from `~/.bash_aliases` we can take advantage of this rather then trying to maintain `~/.bashrc`. We will use `~/.bash_aliases` as an actually loading point rather then just for aliases. We will define aliases in a separate file

```sh
## Default loading point for bash customizations

## Load other files
if [ -f ~/.my_bash_env ]; then
    source ~/.my_bash_env
fi
if [ -f ~/.my_bash_aliases ]; then
    source ~/.my_bash_aliases
fi
if [ -f ~/.my_bash_functions ]; then
    source ~/.my_bash_functions
fi
if [ -f ~/.my_bash_prompt ]; then
    source ~/.my_bash_prompt
fi
```
