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

plug_path=~/.vim/autoload/plug.vim
if [[ ! -d "$plug_path" ]]; then
    echo "Preparing Vim..."
    curl --fail --location --output "$plug_path" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    vim +PlugInstall +qall
fi

echo "Done."
