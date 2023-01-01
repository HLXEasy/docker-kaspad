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

    Per default a local Docker registry at port 5000 is spawned. To use
    hub.docker.io, have a look at options -r and -a below.

    Usage: ${0} [options]

    Options:
    -a <account-name>
        .. If a remote registry shoule be used (see option -r), you need to
           give the corresponding account name. Currently only DockerHub is
           supported.
    -b <builder_name>
        .. Name of Docker builder. Default: ${BUILDER_NAME}
    -f  .. Force creation of Docker builder. If already existing, the
           builder will be removed and recreated.
    -p <platform-list>
        .. List of plattforms separated by comma.
           Default: ${PLATFORM}
    -r  .. Use remote Docker registry. Without this option, a local registry
           instance at port 5000 will be spawned.
    -t <tag>
        .. Image tag to use. Default: ${DOCKER_TAG_VERSION}
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
    local builderConfigParam=''
    if ${LOCAL_REGISTRY} ; then
        info "Creating builder configuration file"
        echo "[registry.\"${REGISTRY_PREFIX%/*}\"]" > builder-config.toml
        echo "  http = true" >> builder-config.toml
        echo "  insecure = true" >> builder-config.toml
        builderConfigParam='--config builder-config.toml'
        info " -> Done"
    fi
    info " -> Creating builder instance '${BUILDER_NAME}'"
    docker buildx create \
        --name "${BUILDER_NAME}" \
        --platform "${PLATFORM}" \
        --buildkitd-flags '--allow-insecure-entitlement security.insecure' \
        ${builderConfigParam} \
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
        --platform "${PLATFORM}" \
        --tag "${REGISTRY_PREFIX}${REGISTRY_ACCOUNT_NAME}${DOCKER_TAG}:${DOCKER_TAG_VERSION}" \
        .
    info " -> Done"
    info "Get the image with the following cmd:"
    info "docker pull ${REGISTRY_PREFIX}${REGISTRY_ACCOUNT_NAME}${DOCKER_TAG}:${DOCKER_TAG_VERSION}"
}

IMAGE_SUFFIX=
FORCE_BUILDER_CREATION=false
LOCAL_REGISTRY=true
LOCAL_REGISTRY_NAME=registry
REGISTRY_PREFIX="$(hostname -I | xargs):5000/"
REGISTRY_ACCOUNT_NAME=''
DOCKER_TAG=docker-kaspad
DOCKER_TAG_VERSION=latest
BUILDER_NAME=kaspa_builder
PLATFORM="linux/arm64/v8,linux/amd64"

while getopts a:b:fp:rt:h option; do
    case ${option} in
        a) REGISTRY_ACCOUNT_NAME="${OPTARG}" ;;
        b) BUILDER_NAME="${OPTARG}" ;;
        f) FORCE_BUILDER_CREATION=true ;;
        p) PLATFORM="${OPTARG}" ;;
        r) LOCAL_REGISTRY=false
           REGISTRY_PREFIX=''
           ;;
        t) DOCKER_TAG_VERSION="${OPTARG}" ;;
        h) helpMe && exit 0;;
        *) die 90 "invalid option \"${OPTARG}\"";;
    esac
done

if ${LOCAL_REGISTRY}; then
    # REGISTRY_ACCOUNT_NAME must be empty on local registry,
    # so clear it, just in case it was given
    REGISTRY_ACCOUNT_NAME=''
    createLocalRegistry
else
    if [ -z "${REGISTRY_ACCOUNT_NAME}" ]; then
        error "If using a remote Docker registry, the account name must be given!"
        helpMe
        die 23 "No account name given"
    else
        # Exactly one trailing slash required, so add
        # trailing slash by removing a probably existing one
        REGISTRY_ACCOUNT_NAME=${REGISTRY_ACCOUNT_NAME%/}/
    fi
fi
checkBuilder
buildImages
