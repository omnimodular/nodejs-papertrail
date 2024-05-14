#!/bin/bash
# shellcheck disable=SC2162,SC2086

_git_clone_https() { git clone -q https://github.com/$1 $2; }
_git_clone_ssh()   { git clone -q git@github.com:$1 $2; }
_git_clone_gh()    { gh repo clone $1 $2; }

_git_clone() {
	if [ "$OM_GIT_PROTOCOL" = "ssh" ]
	then
		_git_clone_ssh "$@"
	elif [ "$OM_GIT_PROTOCOL" = "gh" ]
	then
		_git_clone_gh "$@"
	else
		_git_clone_https "$@"
	fi
}

if ! type mr
then
	echo > /dev/stderr "Install My Repos -- apt-get install myrepos"
	exit 1
fi

mkdir -p docker invoice k8s test

test -d events || { _git_clone omnimodular/events events && mr register events; } || echo "$SRC failed"

exec <<HERE
compose
labs
serverless
serverless-ctrl
vendor
HERE

while read REPOSITORY
do
	SRC=omnimodular/omnicoder-${REPOSITORY}
	DST=${REPOSITORY}
	test -d $DST || { _git_clone $SRC $DST && mr register $DST; } || echo "$SRC failed"
done

exec <<HERE
azure-blob-sidecar
azure-copy-blob
azure-functionapp-sidecar
azure-queue-sidecar
swayer
deploy-monitor
job-docker-executor
k8s-healthz
k8s-sss
log-sidecar
HERE

while read REPOSITORY
do
	SRC=omnimodular/${REPOSITORY}
	DST=docker/${REPOSITORY}
	test -d $DST || { _git_clone $SRC $DST && mr register $DST; } || echo "$SRC failed"
done

exec <<HERE
invoice-accuracy
invoice-dataset
invoice-deploy
invoice-extract
invoice-haproxy
invoice-model-test
invoice-postprocess
invoice-preprocess
invoice-prune
invoice-serving
invoice-tests
invoice-training
HERE

while read REPOSITORY
do
	SRC=omnimodular/${REPOSITORY}
	DST=invoice/${REPOSITORY#invoice-}
	test -d $DST || { _git_clone $SRC $DST && mr register $DST; } || echo "$SRC failed"
done

exec <<HERE
accuracy
dataset
deployment
dotkube
frontend
ingest
model-test
monitor
namespace
scaling
HERE

while read REPOSITORY
do
	SRC=omnimodular/omnicoder-k8s-${REPOSITORY}
	DST=k8s/${REPOSITORY}
	test -d $DST || { _git_clone $SRC $DST && mr register $DST; } || echo "$SRC failed"
done

exec <<HERE
ingest
HERE

while read REPOSITORY
do
	SRC=omnimodular/omnicoder-test-${REPOSITORY}
	DST=test/${REPOSITORY}
	test -d $DST || { _git_clone $SRC $DST && mr register $DST; } || echo "$SRC failed"
done
