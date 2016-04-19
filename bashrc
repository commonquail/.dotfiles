# If not running interactively, bail.
case $- in
    *i*)
        ;;
    *)
        return;;
esac

# Disable flow-control (suspend terminal on C-s).
stty -ixon

# Don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth

# Append to the history file, don't overwrite it.
shopt -s histappend

HISTSIZE=10000
HISTFILESIZE=20000

# Check the window size after each command.
shopt -s checkwinsize

# Expand paths recursively.
shopt -s globstar

# Make less more friendly for non-text input files.
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

    # tput bold;
    red=$'\e[1;31m'     # tput setaf 1
    green=$'\e[1;32m'   # tput setaf 2
    yellow=$'\e[1;33m'  # tput setaf 3
    blue=$'\e[1;34m'    # tput setaf 4
    cyan=$'\e[1;36m'    # tput setaf 6
    reset=$'\e[0m'      # tput sgr0

    if [[ ${EUID} == 0 ]] ; then
        PS1='\[$red\]\u\[$cyan\]@\h \[$blue\]\w\[$reset\]\n\[$green\]\$\[$reset\] '
    else
        PS1='\[$green\]\u\[$cyan\]@\h \[$blue\]\w\[$yellow\]$(__git_ps1)\[$reset\]\n\[$green\]\$\[$reset\] '
    fi

    # tput bold; tput setaf 3; tput setab 4
    yellow_on_blue=$'\e[1;33;44m'
    # tput bold; tput rmul; tput setaf 2
    underlined_green=$'\e[1;4;32m'

    # Blink.
    export LESS_TERMCAP_mb=$green
    export LESS_TERMCAP_md=$cyan
    export LESS_TERMCAP_me=$reset
    # Search matches.
    export LESS_TERMCAP_so=$yellow_on_blue
    export LESS_TERMCAP_se=$reset
    # Underlined.
    export LESS_TERMCAP_us=$underlined_green
    export LESS_TERMCAP_ue=$reset

    unset yellow_on_blue underlined_green

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
