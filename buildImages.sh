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
    -b <builder_name>
        .. Name of Docker builder. Default: ${BUILDER_NAME}
    -p <platform-list>
        .. List of plattforms separated by comma.
           Default: ${PLATFORM}
    -t <tag>
        .. Image tag to use
    -h  .. Show this help
    "
}

createBuilder() {
    info "Checking builder instance"
    if docker buildx inspect "${BUILDER_NAME}" >/dev/null 2>&1 ; then
        info " -> Using already existing builder instance '${BUILDER_NAME}'"
    else
        info " -> Creating builder instance '${BUILDER_NAME}'"
        docker buildx create \
            --name "${BUILDER_NAME}" \
            --platform "${PLATFORM}" \
            --bootstrap \
            --use
        info " -> Done"
    fi
}

buildImages() {
    info "Building Docker images"
    info " -> tbd"
}

IMAGE_SUFFIX=
IMAGE_TAG=latest
BUILDER_NAME=kaspa_builder
PLATFORM="linux/arm64/v8,linux/amd64"

while getopts b:p:t:h option; do
    case ${option} in
        b) BUILDER_NAME="${OPTARG}" ;;
        p) PLATFORM="${OPTARG}" ;;
        t) IMAGE_TAG="${OPTARG}" ;;
        h) helpMe && exit 0;;
        *) die 90 "invalid option \"${OPTARG}\"";;
    esac
done

createBuilder
buildImages
