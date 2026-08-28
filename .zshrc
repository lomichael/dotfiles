# prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' %b'
setopt PROMPT_SUBST
PROMPT='%F{blue}%1~%f%F{yellow}${vcs_info_msg_0_}%f %F{gray}->%f '

# history
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

alias g="git"
alias gs="git status --short"
alias gd="git diff"
alias gds="git diff --staged"
alias gl="git log --oneline -20"
alias v="nvim"
alias t="tmux"
alias ta="tmux attach -t"
alias c="clear"
alias ..="cd .."
alias ...="cd ../.."

# PATH
export PATH="$HOME/.npm-global/bin:$PATH"
export EDITOR="nvim"

# disable flow control (free up Ctrl-S for tmux)
stty -ixon
