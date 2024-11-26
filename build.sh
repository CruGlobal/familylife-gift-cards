#!/bin/bash

docker buildx build $DOCKER_ARGS \
    --build-arg SIDEKIQ_CREDS=$SIDEKIQ_CREDS \
    --build-arg RUBY_VERSION=$(cat .ruby-version) \
    .
rc=$?

if [ $rc -ne 0 ]; then
  echo -e "Docker build failed"
  exit $rc
fi
