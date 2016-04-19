# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*)
        ;;
    *)
        return;;
esac

# Disable flow-control (suspend terminal on C-s)
stty -ixon

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=20000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Expand paths recursively.
shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"

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
    # Enable colors for ls, etc. Prefer ~/.dir_colors #64489
    if type -P dircolors >/dev/null ; then
        if [[ -f ~/.dir_colors ]] ; then
            eval $(dircolors -b ~/.dir_colors)
        elif [[ -f /etc/DIR_COLORS ]] ; then
            eval $(dircolors -b /etc/DIR_COLORS)
        fi
    fi

    if [[ ${EUID} == 0 ]] ; then
        PS1='\[\e[01;31m\]\u\[\e[01;36m\]@\h \[\e[01;34m\]\w\[\e[m\]\n\[\e[01;32m\]\$\[\e[m\] '
    else
        PS1='\[\e[01;32m\]\u\[\e[01;36m\]@\h \[\e[01;34m\]\w\[\e[01;33m\]$(__git_ps1)\[\e[m\]\n\[\e[01;32m\]\$\[\e[m\] '
    fi

    # Blink.
    export LESS_TERMCAP_mb=$'\e[1;32m'
    export LESS_TERMCAP_md=$'\e[1;96m'
    export LESS_TERMCAP_me=$'\e[0m'
    # Search matches: bold yellow on blue.
    # tput bold; tput setaf 3; tput setab 4
    export LESS_TERMCAP_so=$'\e[1;33;44m'
    export LESS_TERMCAP_se=$'\e[0m'
    # Underlined: bold, underline, green.
    # tput bold; tput rmul; tput setaf 2
    export LESS_TERMCAP_us=$'\e[1;4;32m'
    export LESS_TERMCAP_ue=$'\e[0m'

    alias ls='ls --color=auto'
    alias grep='grep --colour=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
else
    PS1='\u@\h \w \$ '
fi
unset use_color safe_term match_lhs

# Store aliases elsewhere.
[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases

# Enable programmable completion.
# Required unless enabled in /etc/bash.bashrc and /etc/profile sources it.
if ! shopt -oq posix; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        . /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        . /etc/bash_completion
    fi
fi

export VISUAL=vim

pathprepend()
{
    [[ -d "$1" && ":$PATH:" != *":$1:"* ]] && PATH="$1${PATH:+":$PATH"}"
}

pathprepend ~/.npm/bin
