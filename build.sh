#!/bin/bash
set -ex

if [ x${CSV_VERSION} = x ] || [ x${OPERATOR_BRANCH} = x ]; then
  echo Please provide CSV_VERSION and OPERATOR_BRANCH
  echo Example: CSV_VERSION=0.1.10-1 OPERATOR_BRANCH=web-ui-v2.0.0 $0
  echo Example: CSV_VERSION=0.1.12 OPERATOR_BRANCH=master $0
  exit 1
fi

VERSION=v${CSV_VERSION}
RELEASE=1 # see https://quay.io/repository/kubevirt/kubevirt-web-ui-operator?tab=tags

GIT_REMOTE_NAME=origin # or origin
UNIQUE=`date +"%Y-%m-%d_%H-%M-%S"`

TAG1=${VERSION}-${RELEASE}
TAG2=${VERSION}

git diff-index --quiet HEAD || (echo Commit your changes first ; false) # fail if uncomitted changes

sleep 5

git checkout ${OPERATOR_BRANCH} && git fetch --all && git reset --hard ${GIT_REMOTE_NAME}/${OPERATOR_BRANCH}
git status
git checkout -b olm-${CSV_VERSION}-${UNIQUE}
./hack/make-olm.sh
git status
git add deploy/olm-catalog
git commit -m "Synced by hack/make-olm.sh for ${CSV_VERSION}" || true
git diff-index --quiet HEAD || (echo Commit your changes first ; false) # fail if uncomitted changes

operator-sdk build quay.io/kubevirt/kubevirt-web-ui-operator:$TAG1
docker push quay.io/kubevirt/kubevirt-web-ui-operator:$TAG1

docker tag quay.io/kubevirt/kubevirt-web-ui-operator:$TAG1 quay.io/kubevirt/kubevirt-web-ui-operator:$TAG2
docker push quay.io/kubevirt/kubevirt-web-ui-operator:$TAG2

docker tag quay.io/kubevirt/kubevirt-web-ui-operator:$TAG1 quay.io/kubevirt/kubevirt-web-ui-operator:latest
docker push quay.io/kubevirt/kubevirt-web-ui-operator:latest

echo Finished
echo Do not forget to push git changes
git branch

# go build -o build/_output/bin/web-ui-operator cmd/manager/main.go
