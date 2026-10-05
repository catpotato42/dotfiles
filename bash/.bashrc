# Prompt: orange cwd, purple input. Not exported: every interactive bash reads
# this file and sets its own, and exporting leaks escape codes into shells and
# tools that did not ask for them.
PS1='\[\e[38;2;230;152;117m\]\w \[\e[38;2;214;153;182m\]\$ '

export LS_COLORS="di=38;2;167;192;128:$LS_COLORS"
alias ls='ls --color=auto'

export GREP_COLORS='mt=38;2;230;126;128:sl=38;2;211;198;170'

export LESS_TERMCAP_md=$'\e[38;2;127;187;179m'
export LESS_TERMCAP_us=$'\e[38;2;131;192;146m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_ue=$'\e[0m'
trap 'printf "\e[0m"' DEBUG

# Prefer a vim built with +clipboard. Fedora's vim-X11 package installs it as
# 'vimx', Debian/Ubuntu's vim-gtk3 installs it as 'vim.gtk3'. Both run in the
# terminal, neither opens a GUI window. `command -v` is a shell builtin, so
# this costs no forks at startup.
if command -v vimx >/dev/null 2>&1; then
  alias vim='vimx'
elif command -v vim.gtk3 >/dev/null 2>&1; then
  alias vim='vim.gtk3'
fi

if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    PATH="$HOME/.local/bin:$PATH"
fi

mkwall() {
    local src="$1" id="$2" res
    res=$(identify -format '%wx%h' "$src") || return 1
    local dir="$HOME/.local/share/wallpapers/$id"
    mkdir -p "$dir/contents/images"
    cp "$src" "$dir/contents/images/$res.${src##*.}"
    cat > "$dir/metadata.json" << 'JSON'
{
  "KPlugin": {
    "Id": "__ID__",
    "Name": "__ID__",
    "License": "CC-BY-SA-4.0",
    "Authors": [{ "Name": "simon" }]
  }
}
JSON
    sed -i "s/__ID__/$id/g" "$dir/metadata.json"
}

# drill: local CLI, only on the machine it is checked out on. Guarded so this
# file stays inert everywhere else.
#
# Note that ~/drill/bin contains a g++ shim which this PATH entry puts ahead of
# /usr/bin/g++ for every project on the machine. It scope-checks and execs the
# real compiler outside ~/drill, so behaviour is unchanged, but cmake, :make
# and anything else probing the compiler will see a bash script named g++.
if [ -d "$HOME/drill/bin" ]; then
  export PATH="$HOME/drill/bin:$PATH"
  [ -r "$HOME/drill/bin/drill-shell.sh" ] && . "$HOME/drill/bin/drill-shell.sh"
fi

# Machine-specific settings that should not be tracked go here.
[ -r "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
