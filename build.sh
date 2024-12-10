#!/bin/bash
docker buildx build $DOCKER_ARGS \
    --build-arg RUBY_VERSION=$(cat .ruby-version) \
    .
