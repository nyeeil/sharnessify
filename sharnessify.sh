#!/bin/sh
#
# Copyright (c) 2015 Christian Couder
# MIT Licensed; see the LICENSE file in this repository.
#
# Script to add sharness infrastructure to a project

SHARNESS_URL="https://github.com/mlafeldt/sharness.git"
LIB_BASE_DIR="lib"
SHARNESS_BASE_DIR="sharness"

USAGE="$0 [-h] [-v] [-l <local>] [<directory>]"

usage() {
    echo "$USAGE"
    echo "	Add sharness infrastructure to a project"
    echo "	Options:"
    echo "		-h|--help: print this usage message and exit"
    echo "		-v|--verbose: print logs of what happens"
    echo "		-l|--local: use local Sharness repo to clone from"
    exit 0
}

die() {
    echo >&2 "fatal: $@"
    exit 1
}

log() {
    test -z "$VERBOSE" || echo "$@"
}

PROJ_DIR=""
VERBOSE=""

CUR_DIR=$(cd "$(dirname "$0")" && pwd)

# get user options
while [ "$#" -gt "0" ]; do
    # get options
    arg="$1"
    shift

    case "$arg" in
	-h|--help)
	    usage ;;
	-v|--verbose)
	    VERBOSE=1 ;;
	-l|--local)
	    SHARNESS_URL="$(cd "$1" && pwd)" || die "could not cd into '$1'"
	    shift
	    test -n "$SHARNESS_URL" || die "invalid Sharness URL '$SHARNESS_URL'"
	    log "SHARNESS_URL is now set to '$SHARNESS_URL'"
	    ;;
	-*)
	    die "unrecognised option: '$arg'\n$USAGE" ;;
	*)
	    test -z "$PROJ_DIR" || die "too many arguments\n$USAGE"
	    PROJ_DIR="$arg"
	    ;;
    esac
done

# Setup PROJ_DIR properly
test -n "$PROJ_DIR" || PROJ_DIR="."
log "PROJ_DIR is set to '$PROJ_DIR'"

# Create sharness directories
SHARNESS_DIR="$PROJ_DIR/$SHARNESS_BASE_DIR"
SHARNESS_LIB_DIR="$SHARNESS_DIR/$LIB_BASE_DIR"
mkdir -p "$SHARNESS_LIB_DIR" ||
die "could not create '$SHARNESS_LIB_DIR' directory"
log "SHARNESS_LIB_DIR ($SHARNESS_LIB_DIR) is ready"

# Copy sharness install script
cp "$CUR_DIR/install-sharness.sh" "$SHARNESS_LIB_DIR/" ||
die "could not copy '$CUR_DIR/install-sharness.sh' into '$SHARNESS_LIB_DIR/'"
INSTALL_SCRIPT="$SHARNESS_LIB_DIR/install-sharness.sh"
log "INSTALL_SCRIPT ($INSTALL_SCRIPT) has been copied from '$CUR_DIR'"

# Create temp directory
DATE=$(date +"%Y-%m-%dT%H:%M:%SZ")
TMPDIR=$(mktemp -d "/tmp/sharnessify.$DATE.XXXXXX") ||
die "could not 'mktemp -d /tmp/sharnessify.$DATE.XXXXXX'"
log "TMPDIR ($TMPDIR) created"

# Clone Sharness
(
    cd "$TMPDIR" || die "could not cd into '$TMPDIR'"
    git clone "$SHARNESS_URL" ||
    die "could not clone from '$SHARNESS_URL'"
) || exit
log "Sharness cloned from '$SHARNESS_URL'"

# Get Sharness version
SHARNESS_VERSION=$(cd "$TMPDIR/sharness" && git rev-parse HEAD)
test -n "$SHARNESS_VERSION" ||
die "could not get Sharness version from repo in '$TMPDIR/sharness'"
log "SHARNESS_VERSION is set to '$SHARNESS_VERSION'"

ESCAPED_URL=$(echo "$SHARNESS_URL" | sed -e 's/[\/&]/\\&/g')

# Substitute variables in install script
sed -i "s/XXX_SHARNESSIFY_VERSION_XXX/$SHARNESS_VERSION/" "$INSTALL_SCRIPT" ||
die "could not modify '$INSTALL_SCRIPT'"
sed -i "s/XXX_SHARNESSIFY_URL_XXX/$ESCAPED_URL/" "$INSTALL_SCRIPT" ||
die "could not modify '$INSTALL_SCRIPT'"
sed -i "s/XXX_SHARNESSIFY_LIB_XXX/$LIB_BASE_DIR/" "$INSTALL_SCRIPT" ||
die "could not modify '$INSTALL_SCRIPT'"
sed -i "s/XXX_SHARNESSIFY_SHARNESS_XXX/sharness/" "$INSTALL_SCRIPT" ||
die "could not modify '$INSTALL_SCRIPT'"
log "Variables substituted in '$INSTALL_SCRIPT'"

# Cleanup temp directory
rm -rf "$TMPDIR"

# Add .gitignore
echo "$LIB_BASE_DIR/$SHARNESS_BASE_DIR/" >"$SHARNESS_DIR/.gitignore"
echo "test-results/" >>"$SHARNESS_DIR/.gitignore"
echo "trash directory.*.sh/" >>"$SHARNESS_DIR/.gitignore"
log "'$SHARNESS_DIR/.gitignore' created"

