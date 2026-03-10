# .dotfiles

## push to github
```
⁠⁠git init --bare $HOME/.myconf⁠⁠
⁠⁠alias config='/usr/bin/git --git-dir=$HOME/.myconf/ --work-tree=$HOME'⁠⁠
⁠⁠config config --local status.showUntrackedFiles no⁠⁠
echo "alias config='/usr/bin/git --git-dir=$HOME/.myconf/ --work-tree=$HOME'" >> $HOME/.bashrc
```

## clone to new box
```
git clone --bare <git-repo-url> $HOME/.myconf
alias config='/usr/bin/git --git-dir=$HOME/.myconf --work-tree=$HOME'
config checkout
config config --local status.showUntrackedFiles no
```
