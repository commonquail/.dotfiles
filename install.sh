#!/bin/bash
backup="${HOME}/dotfiles_$(date +'%Y-%m-%d_%H-%M-%S')"
files="inputrc bashrc bash_aliases gitconfig vim vimrc tmux.conf tigrc npmrc ideavimrc tigrc.vim"
dotfilesdir="$PWD"

[[ -d "${backup}" ]] || mkdir "${backup}"

chmod a+w "${backup}"

# ${files} should not be quoted here or it will not be interpreted as a list."
for file in ${files}; do

  dot="${HOME}/.${file}"
  dest="${backup}/${file}"

  [[ -e "${dot}" ]] && \
      echo "Moving ${dot} to ${dest}" && \
      mv -v "${dot}" "${dest}"

  echo "Symlinking ${dot}..."
  ln -v -s "${dotfilesdir}/${file}" "${dot}"
  echo

done

unset dot
unset files
unset backup
unset dotfilesdir

vundle_path=~/.vim/bundle/Vundle.vim
if [[ ! -d "$vundle_path" ]]; then
    echo "Preparing Vim..."
    git clone https://github.com/VundleVim/Vundle.vim.git "$vundle_path"
    vim +PluginInstall +qall
fi

echo "Done."
