An install script that tries to do so safely
```bash
git clone https://github.com/tbennett6421/linux-utils
cd linux-utils/unified-shell
git pull

# Ensure sudoers timestamp is updated to avoid prompt
sudo -v

# install MOTD stuff
sudo apt-get install lolcat cowsay fortune fortunes-off dos2unix -y

# Install python stuff
sudo apt-get install python-is-python3 python3-pip python3-venv
sudo update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Backup files before clobbering
# https://stackoverflow.com/questions/8488253/how-to-force-cp-to-overwrite-without-confirmation
\cp --backup=existing ~/.bashrc ~/.bashrc.backup > /dev/null 2>&1
\cp --backup=existing ~/.bash_profile ~/.bash_profile.backup > /dev/null 2>&1
\cp --backup=existing ~/.bash_aliases ~/.bash_aliases.backup > /dev/null 2>&1
\cp --backup=existing ~/.my_bash_aliases ~/.my_bash_aliases.backup > /dev/null 2>&1
\cp --backup=existing ~/.my_bash_env ~/.my_bash_env.backup > /dev/null 2>&1
\cp --backup=existing ~/.my_bash_functions ~/.my_bash_functions.backup > /dev/null 2>&1
\cp --backup=existing ~/.my_bash_prompt ~/.my_bash_prompt.backup > /dev/null 2>&1
\cp --backup=existing ~/.tmux.conf ~/.tmux.conf.backup > /dev/null 2>&1
\cp --backup=existing ~/.vimrc ~/.vimrc.backup > /dev/null 2>&1
\cp -R --backup=existing ~/.vim ~/.vim.backup > /dev/null 2>&1
# System stuff
sudo \cp -R --backup=existing /usr/share/cowsay ~/cowsay > /dev/null 2>&1
sudo \cp -R --backup=existing /usr/share/games/fortunes ~/fortunes > /dev/null 2>&1

# copy new files over old ones
SRC="skel"
find "$SRC" -type f -print0 | xargs -0 dos2unix

\cp -f $SRC/home/bashrc ~/.bashrc
\cp -f $SRC/home/bash_profile ~/.bash_profile
\cp -f $SRC/home/bash_aliases ~/.bash_aliases
\cp -f $SRC/home/my_bash_aliases ~/.my_bash_aliases
\cp -f $SRC/home/my_bash_env ~/.my_bash_env
\cp -f $SRC/home/my_bash_functions ~/.my_bash_functions
\cp -f $SRC/home/my_bash_prompt ~/.my_bash_prompt
\cp -f $SRC/home/tmux.conf ~/.tmux.conf
\cp -f $SRC/home/vimrc ~/.vimrc
# System stuff
sudo rsync -avhP $SRC/usr/share/cowsay/ /usr/share/cowsay/ --delete
sudo rsync -avhP $SRC/usr/share/games/fortunes/ /usr/share/games/fortunes/
```

If you feel your shell is stable, and you'd like to do some cleanup you can do the following
```bash
find ~/ -name ".*.backup*"
find ~/ -name ".*.backup*" -delete
rm -rf ~/.vim.backup
sudo rm -rf ~/fortune
sudo rm -rf ~/cowsay
```



