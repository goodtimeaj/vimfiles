#!/usr/bin/env bash
#
# Minifies and symlinks vimfiles to $HOME.

# Prints usage
usage() {
  cat << EOF
usage: $0 [-s|--submodules] [-h|--help]

OPTIONS:
  -s | --submodules    Initialize and update included git submodules
EOF
}

# Exits with given error message
die() {
  echo "$@"
  exit 1
}

# Minifies vim script files in place
minify_vim_script_file_in_place() {
  # 1. Convert tabs to spaces
  # 2. Remove blank lines
  # 3. Remove beginning spaces
  # 4. Remove whole line comments
  # 5. Remove trailing spaces

  # Set LANG as C to treat all ASCII characters as themselves and all
  # non-ASCII characters as literals
  env LANG=C sed 's/	/ /g' "$1" \
    | env LANG=C sed '/^$/d' \
    | env LANG=C sed 's/^[ ]*//' \
    | env LANG=C sed '/^[ ]*"/d' \
    | env LANG=C sed 's/[ ]*$//' \
    > tmp

  # Copy tmp to the given file and remove tmp
  cp tmp "$1"
  rm tmp
}

HERE=$(dirname "$0") && HERE=$(cd "$HERE" && pwd -P)

while :
do
  case "$1" in
    -h | --help )
      usage
      exit 0
      ;;
    -s | --submodules )
      cd "$HERE"

      # Sync git submodules if already initialized
      if [ -f "$HERE/core/pathogen/autoload/pathogen.vim" ]; then
        echo "Updating git submodules"
        (git submodule sync && git submodule update --init) \
          || die "Could not sync git submodules"
      else
        echo "Initializing git submodules"
        (git submodule init && git submodule update) \
          || die "Could not update git submodules"
      fi
      shift
      ;;
    -- )
      shift
      break
      ;;
    -* )
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
    * )
      break
      ;;
  esac
done

# Back up any existing configurations
echo "Backing up any existing configurations"

# Actually copy the contents of the symlinks (or regular files), not just the
# link if exists
for file in "$HOME/.vimrc" "$HOME/.gvimrc"; do
  if [ -e $file ]; then
    cp -v "$file" "${file}.old" || die "Could not copy ${file} to ${file}.old"
  fi
done

if [ -h "$HOME/.vim" ]; then
  # Remove any existing ~/.vim.old because of `cp` symlink issues
  rm -rf "$HOME/.vim.old"
  echo "Copying symlink ${HOME}/.vim contents to ${HOME}/.vim.old"
  cp -R $(readlink "$HOME/.vim") "$HOME/.vim.old" \
    || die "Could not copy ${HOME}/.vim to ${HOME}/.vim.old"
else
  if [ -d "$HOME/.vim" ]; then
    echo "Renaming ${HOME}/.vim to ${HOME}/.vim.old"
    mv -R "$HOME/.vim" "$HOME/.vim.old" \
      || die "Could not move ${HOME}/.vim to ${HOME}/.vim.old"
  fi
fi

echo "Minifying *.vim files"

# Remove any existing ./vim.min because of `cp` symlink issues
rm -rf "$HERE/vim.min"
mkdir -p "$HERE/vim.min/bundle"

# Copy vim files, locally, to be minified
cp "$HERE/vimrc" "$HERE/vimrc.min"
cp "$HERE/gvimrc" "$HERE/gvimrc.min"

# Consolidate all plugins into bundle and save pathogen from having to load
# multiple paths
for file in "$HERE/"*; do
  dir_name=$(basename ${file})
  if [[ ( -d "$file" ) && ( "$dir_name" != 'vim.min' ) ]]; then
    for plugin in "$file/"*; do
      plugin_name=$(basename ${plugin})
      cp -R "$plugin" "$HERE/vim.min/bundle/$plugin_name"
    done
  fi
done

# Minify
minify_vim_script_file_in_place "$HERE/vimrc.min"
minify_vim_script_file_in_place "$HERE/gvimrc.min"
find "$HERE/vim.min" -name '*.vim' \
  | while read file; do minify_vim_script_file_in_place "$file"; done

# Remove any existing ~/.vim to avoid any recursive linking since GNU `ln`
# doesn't have `h` option
rm -rf "$HOME/.vim"

# Link to minified configurations
ln -sfv "$HERE/vimrc.min" "$HOME/.vimrc"
ln -sfv "$HERE/gvimrc.min" "$HOME/.gvimrc"
ln -sfv "$HERE/vim.min" "$HOME/.vim"
