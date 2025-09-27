
# required for gnome-based systems
# to avoid premature configuration by gnome-shell
[[ $- != *i* ]] && return

[[ -n $ZSH_VERSION || -n $FISH_VERSION ]] && return

export CLASSICO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

[[ -d $CLASSICO ]] && . $CLASSICO/shibumi/exports
read_profile_d
