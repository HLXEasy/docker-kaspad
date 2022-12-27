#!/usr/bin/env bash
# ===========================================================================
#
# Helper script to build and push multiarch kaspad image
#
# SPDX-FileCopyrightText: © 2022 Helix <hlxeasy@gmail.com>
# SPDX-License-Identifier: MIT
#
# Created: 2022-12-27 Helix <hlxeasy@gmail.com>
#
# ===========================================================================

# Store path from where script was called, determine own location
# and source helper content from there
callDir=$(pwd)
ownLocation="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${ownLocation}" || exit 1
. ./include/helpers_console.sh
_init

helpMe() {
    echo "
    Helper script to build and push multiarch kaspad Docker image.

    Usage:
    ${0} [options]
    Optional parameters:
    -t <tag>
       .. Image tag to use
    -h .. Show this help
    "
}

buildImages() {
    info "Building Docker images"
    info " -> tbd"
}

IMAGE_SUFFIX=
IMAGE_TAG=latest

while getopts t:h option; do
    case ${option} in
        t) IMAGE_TAG="${OPTARG}" ;;
        h) helpMe && exit 0;;
        *) die 90 "invalid option \"${OPTARG}\"";;
    esac
done

buildImages
