#!/bin/bash
backup="${HOME}/dotfiles_$(date +'%Y-%m-%d-%S')"
files="inputrc"
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "${backup}" ]; then
  mkdir "${backup}"
fi

chmod a+w "${backup}"
#echo "Backing up existing dotfiles in ${backup}..."

for file in "${files}"; do

  dot="${HOME}/.${file}"

  if [ -e "${dot}" ]; then
    echo "Moving ${dot} to ${backup}..."
    mv -v "${dot}" "${backup}/${file}"
  fi

  echo "Symlinking ${dot}..."
  ln -v -s "${dir}/${file}" "${dot}"

done
unset dot
unset files
unset backup
