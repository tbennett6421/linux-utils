```bash
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
cp -f bashrc ~/.bashrc
cp -f bash_profile ~/.bash_profile
cp -f bash_aliases ~/.bash_aliases
cp -f my_bash_aliases ~/.my_bash_aliases
cp -f my_bash_env ~/.my_bash_env
cp -f my_bash_functions ~/.my_bash_functions
cp -f my_bash_prompt ~/.my_bash_prompt
cp -f tmux.conf ~/.tmux.conf
cp -f vimrc ~/.vimrc
rsync -avhP vim ~/.vim --delete
```
