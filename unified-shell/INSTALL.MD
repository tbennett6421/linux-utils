```bash

git clone https://github.com/tbennett6421/linux-utils
cd linux-utils/unified-shell
git pull

# install MOTD stuff
sudo apt-get install lolcat cowsay fortune fortunes-off dos2unix -y

# Backup files before clobbering
cp --backup=existing ~/.bashrc ~/.bashrc.backup > /dev/null 2>&1
cp --backup=existing ~/.bash_profile ~/.bash_aliases.backup > /dev/null 2>&1
cp --backup=existing ~/.bash_aliases ~/.bash_aliases.backup > /dev/null 2>&1
cp --backup=existing ~/.my_bash_aliases ~/.my_bash_aliases.backup > /dev/null 2>&1
cp --backup=existing ~/.my_bash_env ~/.my_bash_env.backup > /dev/null 2>&1
cp --backup=existing ~/.my_bash_functions ~/.my_bash_functions.backup > /dev/null 2>&1
cp --backup=existing ~/.my_bash_prompt ~/.my_bash_prompt.backup > /dev/null 2>&1
cp --backup=existing ~/.tmux.conf ~/.tmux.conf.backup > /dev/null 2>&1
cp --backup=existing ~/.vimrc ~/.vimrc.backup > /dev/null 2>&1
cp -R --backup=existing ~/.vim ~/.vim.backup > /dev/null 2>&1

# copy new files over old ones
SRC="skel"
find "$SRC" -type f -print0 | xargs -0 dos2unix

cp -f $SRC/home/bashrc ~/.bashrc
cp -f $SRC/home/bash_profile ~/.bash_profile
cp -f $SRC/home/bash_aliases ~/.bash_aliases
cp -f $SRC/home/my_bash_aliases ~/.my_bash_aliases
cp -f $SRC/home/my_bash_env ~/.my_bash_env
cp -f $SRC/home/my_bash_functions ~/.my_bash_functions
cp -f $SRC/home/my_bash_prompt ~/.my_bash_prompt
cp -f $SRC/home/tmux.conf ~/.tmux.conf
cp -f $SRC/home/vimrc ~/.vimrc
rsync -avhP $SRC/home/vim ~/.vim --delete

```
