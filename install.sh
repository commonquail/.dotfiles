#!/bin/bash
backup="${HOME}/dotfiles_$(date +'%Y-%m-%d-%S')"
files="inputrc bashrc bash_aliases gitconfig"
dotfilesdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "${backup}" ]; then
  mkdir "${backup}"
fi

chmod a+w "${backup}"
#echo "Backing up existing dotfiles in ${backup}..."

# ${files} should not be quoted here or it will not be interpreted as a list."
for file in ${files}; do

  dot="${HOME}/.${file}"

  if [ -e "${dot}" ]; then
    echo "Moving ${dot} to ${backup}..."
    mv -v "${dot}" "${backup}/${file}"
  fi

  echo "Symlinking ${dot}..."
  ln -v -s "${dotfilesdir}/${file}" "${dot}"

done
unset dot
unset files
unset backup
unset dotfilesdir
