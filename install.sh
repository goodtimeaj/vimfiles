#!/usr/bin/env bash
#
# Minifies and symlinks vimfiles to $HOME.

# Exits with given error message
function die() {
  echo "$@"
  exit 1
}

# Minifies vim script files in place
function minify_vim_script_file_in_place() {
  # 1. Convert tabs to spaces
  # 2. Remove blank lines
  # 3. Remove beginning spaces
  # 4. Remove whole line comments
  # 5. Remove trailing spaces

  # Set LANG as C to treat all ASCII characters as themselves and all
  # non-ASCII characters as literals
  env LANG=C sed 's/	/ /g' "$@" \
    | env LANG=C sed '/^$/d' \
    | env LANG=C sed 's/^[ ]*//' \
    | env LANG=C sed '/^[ ]*"/d' \
    | env LANG=C sed 's/[ ]*$//' \
    > tmp

  # Copy tmp to the given file and remove tmp
  cp tmp "$@"
  rm tmp
}

HERE=$(dirname "$0") && HERE=$(cd "$HERE" && pwd -P)
cd $HERE

# Update git submodules with `g` option
while getopts "g" opt; do
  case $opt in
    g)
      echo "Updating git submodules"
      (git submodule init && git submodule update) \
        || die "Could not update git submodules"
      ;;
  esac
done

# Back up any existing configurations
echo "Backing up any existing configurations"

if [ -f "$HOME/.vimrc" ]; then
  cp -R $(readlink "$HOME/.vimrc") "$HOME/.vimrc.bak"
fi

if [ -f "$HOME/.gvimrc" ]; then
  cp -R $(readlink "$HOME/.gvimrc") "$HOME/.gvimrc.bak"
fi

if [ -d "$HOME/.vim.bak" ]; then
  # Remove any existing ~/.vim.bak because of `cp` issues
  rm -rf "$HOME/.vim.bak"
  cp -R $(readlink "$HOME/.vim") "$HOME/.vim.bak"
fi

echo "Minifying *.vim files"

# Remove any existing vim.min because of `cp` issues
rm -rf vim.min
mkdir vim.min

# Copy vim files, locally, to be minified
cp vimrc vimrc.min
cp gvimrc gvimrc.min
cp -R colors vim.min/colors
cp -R core vim.min/core
cp -R langs vim.min/langs
cp -R tools vim.min/tools

# Minify
minify_vim_script_file_in_place vimrc.min
minify_vim_script_file_in_place gvimrc.min
find vim.min -name '*.vim' \
  | while read i; do minify_vim_script_file_in_place "$i"; done

# Remove any existing ~/.vim to avoid any recursive linking since GNU `ln`
# doesn't have `h` option
rm -rf "$HOME/.vim"

# Link to minified configurations
ln -sfv "$HERE/vimrc.min" "$HOME/.vimrc"
ln -sfv "$HERE/gvimrc.min" "$HOME/.gvimrc"
ln -sfv "$HERE/vim.min" "$HOME/.vim"
