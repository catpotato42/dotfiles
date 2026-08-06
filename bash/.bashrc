export PS1='\[\e[38;2;230;152;117m\]\w \[\e[38;2;214;153;182m\]\$ '
export LS_COLORS="di=38;2;167;192;128:$LS_COLORS"
alias ls='ls --color=auto'

export GREP_COLORS='mt=38;2;230;126;128:sl=38;2;211;198;170'

export LESS_TERMCAP_md=$'\e[38;2;127;187;179m'
export LESS_TERMCAP_us=$'\e[38;2;131;192;146m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_ue=$'\e[0m'
trap 'printf "\e[0m"' DEBUG

if command -v vimx >/dev/null 2>&1; then
  alias vim='vimx'
fi
