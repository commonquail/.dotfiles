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
HISTIGNORE='fg'

# Append to the history file, don't overwrite it.
shopt -s histappend

HISTSIZE=100000
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

# Check the window size after each command.
shopt -s checkwinsize

# Expand paths recursively.
shopt -s globstar

# Make less more friendly for non-text input files.
[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"

use_color=true
if ${use_color} ; then
    # tput bold;
    red=$'\e[1;31m'     # tput setaf 1
    green=$'\e[1;32m'   # tput setaf 2
    yellow=$'\e[1;33m'  # tput setaf 3
    blue=$'\e[1;34m'    # tput setaf 4
    cyan=$'\e[1;36m'    # tput setaf 6
    reset=$'\e[0m'      # tput sgr0

    if [[ -z $SSH_TTY ]] ; then
        PS1='\[$blue\]\w\[$yellow\]$(__git_ps1)\[$reset\] \[$green\]\$\[$reset\] '
    elif [[ ${EUID} == 0 ]] ; then
        PS1='\[$red\]\u\[$cyan\]@\h \[$blue\]\w\[$reset\]\n\[$green\]\$\[$reset\] '
    else
        PS1='\[$green\]\u\[$cyan\]@\h \[$blue\]\w\[$yellow\]$(__git_ps1)\[$reset\]\n\[$green\]\$\[$reset\] '
    fi

    # tput bold; tput setaf 3; tput setab 4
    yellow_on_blue=$'\e[1;33;44m'
    # tput bold; tput rmul; tput setaf 2
    underlined_green=$'\e[1;4;32m'

    # Leap 15.2 needs this variable declared for LESS_TERMCAP_* variables to
    # take effect. grotty(1)'s manual suggests that the variable has the
    # opposite effect, or that "PAGER='less -R'" should work equivalently, but
    # this is the only thing that seems to work in practice.
    # https://forums.opensuse.org/showthread.php/414983-Color-Man-Pages/page2
    export GROFF_NO_SGR=1

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

    if [[ -x /usr/bin/dircolors ]]; then
        [[ -r ~/.dircolors ]] && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
        alias ls='ls --color=auto'
        alias grep='grep --colour=auto'
    fi
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

pathprepend()
{
    [[ -d "$1" && ":$PATH:" != *":$1:"* ]] && PATH="$1${PATH:+":$PATH"}"
}

pathprepend ~/.npm/bin
