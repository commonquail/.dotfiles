# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

use_color=false

# Set colorful PS1 only on colorful terminals.
# dircolors --print-database uses its own built-in database
# instead of using /etc/DIR_COLORS.  Try to use the external file
# first to take advantage of user additions.  Use internal bash
# globbing instead of external grep binary.
safe_term=${TERM//[^[:alnum:]]/?}   # sanitize TERM
match_lhs=""
[[ -f ~/.dir_colors   ]] && match_lhs="${match_lhs}$(<~/.dir_colors)"
[[ -f /etc/DIR_COLORS ]] && match_lhs="${match_lhs}$(</etc/DIR_COLORS)"
[[ -z ${match_lhs}    ]] \
        && type -P dircolors >/dev/null \
        && match_lhs=$(dircolors --print-database)
[[ $'\n'${match_lhs} == *$'\n'"TERM "${safe_term}* ]] && use_color=true

if ${use_color} ; then
        # Enable colors for ls, etc.  Prefer ~/.dir_colors #64489
        if type -P dircolors >/dev/null ; then
                if [[ -f ~/.dir_colors ]] ; then
                        eval $(dircolors -b ~/.dir_colors)
                elif [[ -f /etc/DIR_COLORS ]] ; then
                        eval $(dircolors -b /etc/DIR_COLORS)
                fi
        fi

        if [[ ${EUID} == 0 ]] ; then
                PS1='${debian_chroot:+($debian_chroot)}\[\e[0;96m\]@\h \[\e[1;34m\]\w\n\[\e[1;32m\]\$\[\e[m\] '
        else
                PS1='\[\e[0;32m\]\u\[\e[0;96m\]@\h \[\e[1;34m\]\w\n\[\e[1;32m\]\$\[\e[m\] '
        fi

        alias ls='ls --color=auto'
        alias grep='grep --colour=auto'
        alias fgrep='fgrep --color=auto'
        alias egrep='egrep --color=auto'
else
        if [[ ${EUID} == 0 ]] ; then
                # show root@ when we don't have colors
                PS1='\u@\h \W \$ '
        else
                PS1='\u@\h \w \$ '
        fi
fi
unset use_color safe_term match_lhs

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

man() {
	env \
	LESS_TERMCAP_mb=$(printf "\e[1;32m") \
	LESS_TERMCAP_md=$(printf "\e[1;96m") \
	LESS_TERMCAP_me=$(printf "\e[0m") \
	LESS_TERMCAP_se=$(printf "\e[0m") \
	LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
	LESS_TERMCAP_ue=$(printf "\e[0m") \
	LESS_TERMCAP_us=$(printf "\e[1;4;32m") \
	man "$@"
}

# svn modified files Tab completion.
_svindiff() {
    [[ ${COMP_CWORD} < 2 && -e .svn ]] || return 1
    
    COMPREPLY=()
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local opts="$(svn status | grep --color=never '^M ' | awk '{print $2}')"
    COMPREPLY=($(compgen -W "all ${opts}" -- ${cur}))
}

# svn changelist Tab completion.
_svincl() {
    [[ -e .svn ]] || return 1

    COMPREPLY=()
    local cur="${COMP_WORDS[COMP_CWORD]}"
    if [[ $COMP_CWORD -eq 1 ]]; then
        # Find all changelists.
        local opts="$(svn status | grep --color=never '^--- Changelist'\
            | awk -F\' '{print $(NF-1)}')"
        COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
    else
        # Find all changed files.
        local opts="$(svn status | cut -c5- | grep --color=never '^ '\
            | awk '{print $1}')"
        COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
    fi
}

svindiff() {
    if [[ $# -eq 1 ]]; then
        if [[ "$1" == 'all' ]]; then
            for f in $(svn status | cut -c9-); do
                if [[ -f "${f}" ]]; then
                    # Only show diff if file has been changed since last diff.
                    file_touched="/tmp/svindiff/${f}"
                    dir="${file_touched%/*}"
                    [[ ! -d "${dir}" ]] && mkdir -p "${dir}"

                    if [[ ! -f "${file_touched}"  ||
                        "${f}" -nt "${file_touched}" ]]; then
                        svindiff "${f}" && touch "${file_touched}"
                    fi
                fi
            done
        elif [[ -f "$1" ]]; then
            # Pipe svn diff $1 to vim.
            # Set vim to forget the buffer and update the title to the diff file.
            # Disable buffer editing. Read from stdin.
            vim -c "set buftype=nofile titlestring=$1"\
                -c "/^@@"\
                -nM <(svn diff -x -w "$1")
        else
            echo "usage: svindiff <file>"
            echo "file must be an existing, regular file (not a directory)."
            echo "Additional arguments are ignored."
            return 1
        fi
    fi
}

svincl() {
    [[ -e .svn ]] && svn changelist "$@"
}

complete -F _svindiff svindiff
complete -F _svincl svincl

export SVN_EDITOR=vim
