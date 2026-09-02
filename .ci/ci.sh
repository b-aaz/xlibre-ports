#!/bin/sh

ls
. ./.ci/image-fetcher.sh
image_fetch
env
ls
