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
    -f  .. Force creation of Docker builder. If already existing, the
           builder will be removed and recreated.
    -p <platform-list>
        .. List of plattforms separated by comma.
           Default: ${PLATFORM}
    -r  .. Use remote Docker registry. If not given, a local registry instance
           will be spawned at port 5000.
    -t <tag>
        .. Image tag to use
    -h  .. Show this help
    "
}

createLocalRegistry() {
    info "Checking local Docker registry"
    if docker ps -a --format '{{.Names}}' | grep -q "${LOCAL_REGISTRY_NAME}" ; then
        if docker ps --format '{{.Names}}' | grep -q "${LOCAL_REGISTRY_NAME}" ; then
            info " -> Local registry '${LOCAL_REGISTRY_NAME}' already running"
        else
            info " -> Starting already existing registry instance '${LOCAL_REGISTRY_NAME}'"
            docker start "${LOCAL_REGISTRY_NAME}"
            info " -> Done"
        fi
    else
        info " -> Starting local registry '${LOCAL_REGISTRY_NAME}'"
        docker run -d -p 5000:5000 --restart=always --name registry registry:2
        info " -> Done"
    fi
}

createBuilder() {
    info " -> Creating builder instance '${BUILDER_NAME}'"
    docker buildx create \
        --name "${BUILDER_NAME}" \
        --platform "${PLATFORM}" \
        --bootstrap \
        --use
    info " -> Done"
}

checkBuilder() {
    info "Checking builder instance"
    if docker buildx inspect "${BUILDER_NAME}" >/dev/null 2>&1 ; then
        if ${FORCE_BUILDER_CREATION} ; then
            info " -> Removing existing builder instance"
            docker buildx rm "${BUILDER_NAME}"
            createBuilder
        else
            info " -> Using already existing builder instance '${BUILDER_NAME}'"
        fi
    else
        createBuilder
    fi
}

buildImages() {
    info "Building Docker images"
    docker buildx build \
        --push \
        --tag "${REGISTRY_PREFIX}${REGISTRY_NAME}${DOCKER_TAG}:${DOCKER_TAG_VERSION}" \
        .
    info " -> tbd"
}

IMAGE_SUFFIX=
IMAGE_TAG=latest
FORCE_BUILDER_CREATION=false
LOCAL_REGISTRY=true
LOCAL_REGISTRY_NAME=registry
REGISTRY_PREFIX='localhost:5000/'
REGISTRY_NAME=''
DOCKER_TAG=docker-kaspad
DOCKER_TAG_VERSION=latest
BUILDER_NAME=kaspa_builder
PLATFORM="linux/arm/v7,linux/arm64/v8,linux/amd64"

while getopts b:fp:rt:h option; do
    case ${option} in
        b) BUILDER_NAME="${OPTARG}" ;;
        f) FORCE_BUILDER_CREATION=true ;;
        p) PLATFORM="${OPTARG}" ;;
        r) LOCAL_REGISTRY=false
           REGISTRY_PREFIX=''
           REGISTRY_NAME='hlxeasy/'
           ;;
        t) IMAGE_TAG="${OPTARG}" ;;
        h) helpMe && exit 0;;
        *) die 90 "invalid option \"${OPTARG}\"";;
    esac
done

if ${LOCAL_REGISTRY} ; then
    createLocalRegistry
fi
checkBuilder
buildImages
