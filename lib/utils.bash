#!/usr/bin/env bash

set -euo pipefail
# file globbing */** should include files with leading dot in name
shopt -s dotglob

YELLOW=$(printf "\033[0;33m")
RSTCLR=$(printf "\033[0m")


FLUTTER_RELEASES="https://storage.googleapis.com/flutter_infra_release/releases"
TOOL_NAME="flutter"
TOOL_TEST="flutter --version"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

# turns archive file name into version
# flutter_macos_3.10.6-stable.zip -> 3.10.6-stable
archive_to_version() {
	sed -E "s/.*flutter_.*([0-9]+\.[0-9]+\.[0-9]+.*)\.(zip|tar\.xz)/\1/"
}

# gets json string value for given key
json_string() {
	grep -o "\"$1\": \".*\"" |
		sed -E "s/\"$1\": \"(.*)\"/\1/"
}

# extracts archive to location
extract() {
	local archive="$1"
	local to="$2"

	if [[ "$archive" =~ \.zip$ ]]; then
		(find "$to" -not -name flutter-3.10.6-stable.zip -delete &&
			mkdir -p "$to/xtrtmp" &&
			unzip "$archive" -d "$to/xtrtmp" &&
			mv "$to/xtrtmp"/*/** "$to" &&
			rmdir "$to/xtrtmp"/* "$to/xtrtmp") ||
			fail "Could not extract $archive"
	elif [[ "$archive" =~ \.tar\.xz$ ]]; then
		tar -xf "$archive" -C "$to" --strip-components=1 || fail "Could not extract $archive"
	else
		fail "Unsupported archive format for $archive"
	fi
}

os_name() {
	local kernel
	kernel="$(uname -s)"

	case "$kernel" in
	Darwin)
		printf "macos"
		;;
	Linux)
		printf "linux"
		;;
	*)
		fail "Unsupported kernel: $kernel"
		;;
	esac
}

# feches the releases_os.json
fetch_releases_json() {
	curl "${curl_opts[@]}" "$FLUTTER_RELEASES/releases_$(os_name).json"
	printf "%s\n" "${curl_opts[@]}"
}

# lists all release paths
list_releases() {
	if [ "$(uname -m)" = "arm64" ]; then
		fetch_releases_json | json_string "archive" | grep -F "arm64"
	else
		# grep -v -> selected lines are those not matching the pattern
		fetch_releases_json | json_string "archive" | grep -vF "arm64"
	fi
}

# the archive extension for the current os
archive_extension() {
	local kernel
	kernel="$(uname -s)"

	if [ "$kernel" = "Darwin" ]; then
		printf ".zip"
	elif [ "$kernel" = "Linux" ]; then
		printf ".tar.xz"
	else
		fail "Unsupported kernel: $kernel"
	fi
}

# filter versions according to a query
# argument is in the format of x[.x[.x]][-channel]
# for example
# 3, 3.2, 3.2-beta 3.2.1 etc.
filter() {
	local channel
	channel="$(printf "%s" "$1" | grep -oE "(stable|beta|dev)?" | head -n 1)"
	if [ -z "$channel" ]; then
		channel="stable"
	fi

	local version major minor patch
	version="$(printf "%s" "$1" | grep -oE "^([0-9]+(\.[0-9]+(\.[0-9]+)?)?)?" | head -n 1)"

	if [ -z "$version" ]; then
		major="[0-9]+"
		minor="[0-9]+"
		patch="[0-9]+"
	else
		major="$(printf "%s" "$version" | grep -oE "^[0-9]+")"
		minor="$(printf "%s" "$version" | sed -E "s/^[0-9]+(\.([0-9]+))?.*/\2/")"

		if [ -z "$minor" ]; then
			minor="[0-9]+"
			patch="[0-9]+"
		else
			patch="$(printf "%s" "$version" | sed -E "s/^[0-9]+\.[0-9]+(\.([0-9]+))?.*/\2/")"

			if [ -z "$patch" ]; then
				patch="[0-9]+"
			fi
		fi
	fi

	grep -E "^$major\.$minor\.$patch.*-$channel\$"
}

list_all_versions() {
	list_releases | archive_to_version
}

download_release() {
	local version filename release url
	version="$1"
	filename="$2"
	release="$(list_releases | grep "$version\.\(zip\|tar\.xz\)")"
	url="$FLUTTER_RELEASES/$release"

	echo "* Downloading $TOOL_NAME release $version..."
	curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="$3"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	(
		mkdir -p "$install_path"
		cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"

		local tool_cmd
		tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
		test -x "$install_path/bin/$tool_cmd" || fail "Expected $install_path/bin/$tool_cmd to be executable."

		echo "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
