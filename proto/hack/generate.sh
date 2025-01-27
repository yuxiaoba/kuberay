#!/bin/bash

set -ex

export TMP_OUTPUT=/tmp
export OUTPUT_MODE=import

# Change directory.
cd /go/src/github.com/ray-project/kuberay/proto

# Delete currently generated code and create new folder.
rm -rf ./go_client/ ./swagger && mkdir -p ./go_client && mkdir -p ./swagger

protoc -I. \
  -I ./third_party/ --go_out ${TMP_OUTPUT} --go_opt paths=${OUTPUT_MODE} \
  --go-grpc_out ${TMP_OUTPUT} --go-grpc_opt paths=${OUTPUT_MODE} \
  --grpc-gateway_out ${TMP_OUTPUT}  --grpc-gateway_opt paths=${OUTPUT_MODE} \
  --openapiv2_opt logtostderr=true --openapiv2_out=:swagger ./*.proto

# Move *.pb.go and *.gw.go to go_client folder.
cp ${TMP_OUTPUT}/github.com/ray-project/kuberay/proto/go_client/* ./go_client

# Generate a single swagger json file from the swagger json files of all models.
# Note: use proto/swagger/{cluster,config,error}.swagger.json
# Note: swagger files are generate to source folder directly. No files in ${TMP_OUTPUT}
jq -s 'reduce .[] as $item ({}; . * $item) | .info.title = "KubeRay API" | .info.description = "This file contains REST API specification for KubeRay. The file is autogenerated from the swagger definition." | .info.version = "'0.5.0'" | .info.license = { "name": "Apache 2.0", "url": "https://raw.githubusercontent.com/ray-project/kuberay/master/LICENSE" }' \
  /go/src/github.com/ray-project/kuberay/proto/swagger/cluster.swagger.json \
  /go/src/github.com/ray-project/kuberay/proto/swagger/config.swagger.json \
  /go/src/github.com/ray-project/kuberay/proto/swagger/error.swagger.json \
  /go/src/github.com/ray-project/kuberay/proto/swagger/job.swagger.json \
  /go/src/github.com/ray-project/kuberay/proto/swagger/serve.swagger.json \
  > "/go/src/github.com/ray-project/kuberay/proto/kuberay_api.swagger.json"
