#!/bin/sh
# Symlinks every config in this repo into place, so editing the repo edits the
# live config. Anything already there is moved aside rather than overwritten.
set -eu

repo=$(cd "$(dirname "$0")" && pwd)
config="${XDG_CONFIG_HOME:-$HOME/.config}"

link() {
    src="$1" dst="$2"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo "  ok       $dst"
        return
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mv "$dst" "$dst.backup"
        echo "  backed up $dst -> $dst.backup"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    echo "  linked   $dst"
}

echo "home:"
for f in "$repo"/home/.*; do
    case "${f##*/}" in . | ..) continue ;; esac
    link "$f" "$HOME/${f##*/}"
done

echo "$config:"
mkdir -p "$config"
for f in "$repo"/config/*; do
    link "$f" "$config/${f##*/}"
done
