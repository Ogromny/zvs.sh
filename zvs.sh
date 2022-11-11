#!/bin/sh -e
# Ogromny <ogromnycoding@gmail.com>

# Globals
VERSION="0.1"
SELFDIR="$(dirname "$0")"
SOURCES="$SELFDIR/sources"
VERSIONS="$SELFDIR/versions"
CURRENT="$SELFDIR/current"
INDEX_JSON="$SELFDIR/index.json"

# log functions
err() {
	printf "\033[0;31m%s\033[0m\n" "$@"
}
warn() {
	printf "\033[0;33m%s\033[0m\n" "$@"
}
log() {
	printf "\033[0;34m%s\033[0m\n" "$@"
}

# helper
download() {
	if [ -z "$3" ] && [ -e "$2" ]; then
		log "$2 already exists"
		return
	fi

	if command -v curl >/dev/null; then
		curl -o "$2" -fL "$1"
	elif command -v wget >/dev/null; then
		wget -o "$2" "$1"
	else
		err "\`curl\` or \`wget\` required"
		exit 1
	fi
}
checksum() {
	if ! command -v sha256sum >/dev/null; then
		warn "\`sha256sum\` not found, skiping checksum verification"
		return
	fi

	if [ "$(sha256sum "$1" | cut -d" " -f1)" = "$2" ]; then
		log "checksum is valid"
	else
		err "$1 seems to be corrupted"
		rm "$1"
		exit 1
	fi
}
extract() {
	if ! command -v tar >/dev/null; then
		err "\`tar\` required"
		exit 1
	fi

	if [ -d "$2/$3" ]; then
		log "$2/$3 already exists"
	else
		tar -xf "$1" -C "$2"
	fi
}
set_as_current() {
	if [ -e "$CURRENT" ]; then
		log "unlinking current version"
		unlink "$CURRENT"
	fi

	log "setting $1 as current version"
	ln -s "$VERSIONS/$1" "$CURRENT"
}
auto_fetch() {
	if [ ! -e "$INDEX_JSON" ]; then
		err "index.json not found, fetching it"
		fetch
	fi
}
dir_to_version() {
    echo "$1" | cut -d"-" -f4-
}

# functions
print_help() {
	echo "zvs $VERSION"
	echo
	echo "Usage:"
	printf "\tzvs help           \t print this message\n"
	printf "\tzvs fetch          \t fetch the latest index.json\n"
	printf "\tzvs current        \t print current version\n"
	printf "\tzvs installable    \t list installable version\n"
	printf "\tzvs installed      \t list installed version\n"
    printf "\tzvs remove VERSION \t remove VERSION\n"
    printf "\tzvs purge          \t remove all version except the current one\n"
	printf "\tzvs VERSION        \t install VERSION\n"
}

fetch() {
	log "fetching index.json"
	download "https://ziglang.org/download/index.json" "$INDEX_JSON" 1
}

current() {
    if [ ! -e "$CURRENT" ]; then
        log "no version installed"
    else
        dir_to_version "$(basename "$(readlink "$CURRENT")")"
    fi
}

installable() {
	# auto fetch index.json if not exists
	auto_fetch

	# list installable version
	jq -r "keys | join(\"\\n\")" <"$INDEX_JSON" | sort -Vr
}

installed() {
    for version in "$VERSIONS"/*; do
        dir_to_version "$version"
    done | sort -Vr
}

install() {
	# check args
	if [ "$#" -lt 1 ]; then
		err "VERSION required"
        exit 1
	fi

	# auto fetch index.json if not exists
	auto_fetch

	# check if VERSION exists
	if [ ! "$(jq "has(\"$1\")" <"$INDEX_JSON")" = "true" ]; then
		err "version $1 doesn't exist"
		exit 1
	fi

	# get the correct os & arch
	os="$(uname | tr "[:upper:]" "[:lower:]")"
	arch="$(uname -m)"
	if [ ! "$os" = "linux" ]; then
		warn "At the moment only linux was tested"
	fi

	# check if version exists for this target
	fields="$(jq ".\"$1\".\"$arch-$os\"" <"$INDEX_JSON")"
	if [ "$fields" = "null" ]; then
		err "version $1 not found for $arch-$os"
		exit 1
	fi

	# get the needed fields
	tarball="$(echo "$fields" | jq -r ".tarball")"
	shasum="$(echo "$fields" | jq -r ".shasum")"

	# get the name
	filename="$(basename "${tarball}")"
	name="${filename%%.tar.xz}"

	# download the corresponding version
	mkdir -p "$SOURCES"
	source="$SOURCES/$filename"
	download "$tarball" "$source"

	# check shasum
	checksum "$source" "$shasum"

	# extract it
	mkdir -p "$VERSIONS"
	extract "$source" "$VERSIONS" "$name"

	# set it as current
	set_as_current "$name"
}

remove() {
    shift 

    if [ "$#" -lt 1 ]; then
        err "VERSION required"
        exit 1
    fi

    for version in "$VERSIONS"/*; do
        if [ "$(dir_to_version "$version")" = "$1" ]; then
            log "removing $version"
            rm -r "$version"
            return
        fi
    done

    warn "$1 not found"
}

purge() {
    skip="$(current)"
    for version in "$VERSIONS"/*; do
        if [ ! "$(dir_to_version "$version")" = "$skip" ]; then
            log "removing $version"
            rm -r "$version"
        else
            log "skipping $version because it's the current one"
        fi
    done
}

# main
if [ "$#" -eq 0 ]; then
	print_help
	exit 0
fi

case "$1" in
help) print_help ;;
fetch) fetch ;;
current) current ;;
installable) installable ;;
installed) installed ;;
remove) remove "$@" ;;
purge) purge ;;
*) install "$@" ;;
esac
