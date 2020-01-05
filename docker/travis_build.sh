#!/bin/bash -e

login() {
  echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
}

setup() {
  echo '{\"experimental\": true}' | sudo tee /etc/docker/daemon.json
  docker --version
  mkdir -p ~/.docker/cli-plugins
  wget -O ~/.docker/cli-plugins/docker-buildx https://github.com/docker/buildx/releases/download/v0.3.1/buildx-v0.3.1.linux-amd64
  chmod a+x ~/.docker/cli-plugins/docker-buildx
}

build_and_push() {
  docker buildx build \
    # --build-arg COMMIT=$(git rev-parse --short HEAD) \
    --platform linux/arm64/v8,linux/amd64,linux/arm/v6,linux/arm/v7,linux/386 \
    -f docker/Dockerfile.x86-64 \
    --push \
    $1
    .
}

# Only update Docker images for:
# - dev branch
# - version release
if [ "$TRAVIS_PULL_REQUEST" = "false" ] && [ ! -z ${TRAVIS_TAG+x} ] && [ ! "$TRAVIS_TAG" = "" ]
then
  echo "Updating docker images for master branch!"
  setup
  login
  build_and_push "-t $DOCKER_USERNAME/domoticz-buildx-test:latest -t $DOCKER_USERNAME/domoticz-buildx-test:$TRAVIS_TAG"
elif [ "$TRAVIS_BRANCH" = "travis-setup" -a "$TRAVIS_PULL_REQUEST" = "false" ]
then
  echo "Updating docker images for dev branch!"
  setup
  login
  build_and_push "-t $DOCKER_USERNAME/domoticz-buildx-test:latest-dev"
else
  echo "Not updating docker images, triggered by pull request or not on master/dev branch"
fi