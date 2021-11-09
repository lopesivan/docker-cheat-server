#!/usr/bin/env bash

files=(
	"cheat.sh"
)

for f in ${files[*]}; do
  test -L ~/.${f} &&
    rm ${HOME}/.${f}

  echo ln -s ${HOME}/.config/${f} ${HOME}/.${f}
  ln -s ${HOME}/.config/${f} ${HOME}/.${f}
done

# ----------------------------------------------------------------------------
exit 0
