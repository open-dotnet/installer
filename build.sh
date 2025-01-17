#!/usr/bin/env bash
#
# Copyright (c) .NET Foundation and contributors. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.
#

# Set OFFLINE environment variable to build offline

set -e

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Some things depend on HOME and it may not be set. We should fix those things, but until then, we just patch a value in
if [ -z "$HOME" ]; then
    export HOME=$DIR/artifacts/home

    [ ! -d "$HOME" ] || rm -Rf $HOME
    mkdir -p $HOME
fi

args=

while [[ $# > 0 ]]; do
    lowerI="$(echo $1 | awk '{print tolower($0)}')"
    case $lowerI in
        --docker)
            export BUILD_IN_DOCKER=1
            export DOCKER_IMAGENAME=$2
            shift
            ;;
        --noprettyprint)
            export DOTNET_CORESDK_NOPRETTYPRINT=1
            ;;
        *)
            args="$args $1"
            ;;
    esac
    shift
done

dockerbuild()
{
    BUILD_COMMAND=$DIR/run-build.sh $DIR/eng/dockerrun.sh --non-interactive "$@"
}

# Check if we need to build in docker
if [ ! -z "$BUILD_IN_DOCKER" ]; then
    dockerbuild $args
else
    # Run under sudo so we can set ulimit
    # See https://github.com/dotnet/core-eng/issues/14808
    sudo -E $DIR/run-build.sh $args
fi
