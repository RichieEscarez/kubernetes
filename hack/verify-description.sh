#!/bin/bash

# Copyright 2014 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

KUBE_ROOT=$(dirname "${BASH_SOURCE}")/..
source "${KUBE_ROOT}/hack/lib/init.sh"

kube::golang::setup_env
"${KUBE_ROOT}/hack/build-go.sh" cmd/genswaggertypedocs

genswaggertypedocs=$(kube::util::find-binary "genswaggertypedocs")

result=0

find_files() {
  find . -not \( \
      \( \
        -wholename './output' \
        -o -wholename './_output' \
        -o -wholename './release' \
        -o -wholename './target' \
        -o -wholename '*/third_party/*' \
        -o -wholename '*/Godeps/*' \
      \) -prune \
    \) -wholename '*pkg/api/v*/types.go'
}

if [[ $# -eq 0 ]]; then
  files=`find_files | egrep "pkg/api/v.[^/]*/types\.go"`
else
  files=("${@}")
fi

for file in $files; do
  $genswaggertypedocs -v -s "${file}" -f - || result=$?
  if [[ "${result}" -ne "0" ]]; then
    echo "API file: ${file} is missing: ${result} descriptions"
  fi
done

exit ${result}

# ex: ts=2 sw=2 et filetype=sh
