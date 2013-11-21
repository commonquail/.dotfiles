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

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CF'

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

PS1='\[\e[0;32m\]\u\[\e[0;96m\]@\h \[\e[1;34m\]\w\n\[\e[1;32m\]\$\[\e[m\] '

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
        local opts="$(svn status | grep --color=never '^--- Changelist'\
            | awk -F\' '{print $(NF-1)}')"
        COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
    else
        local opts="$(svn status | cut -c5- | grep --color=never '^ '\
            | awk '{print $1}')"
        COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
    fi
}

svindiff() {
    if [[ $# -eq 1 ]]; then
        if [[ "$1" == 'all' ]]; then
            for f in $(svn status | cut -c9-); do
                svindiff "$f"
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
