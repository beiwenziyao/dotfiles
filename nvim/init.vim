set runtimepath^=~/.vim
set runtimepath+=~/.vim/after
let &packpath = &runtimepath

if filereadable(expand('~/.vimrc'))
  source ~/.vimrc
endif
