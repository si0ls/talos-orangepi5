#!/usr/bin/env sh

if [ -z "$1" ]; then
    echo "Usage: semver.sh <kernel_version>"
    exit 1
fi

version=$1

if [[ $version == *.*.* ]]; then
    echo $version
elif [[ $version == *.* ]]; then
    echo $version.0
else
    echo $version.0.0
fi
# Path: hack/semver.sh