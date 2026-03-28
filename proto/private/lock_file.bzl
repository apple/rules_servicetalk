# Copyright © 2026 Apple Inc. and the ServiceTalk project authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
load("@rules_jvm_external//private/rules:v1_lock_file.bzl", "v1_lock_file")
load("@rules_jvm_external//private/rules:v3_lock_file.bzl", "v2_lock_file", "v3_lock_file")

def get_artifacts(lock_file_contents):
    if v3_lock_file.is_valid_lock_file(lock_file_contents):
        lock_file_format = v3_lock_file
    elif v2_lock_file.is_valid_lock_file(lock_file_contents):
        lock_file_format = v2_lock_file
    elif v1_lock_file.is_valid_lock_file(lock_file_contents):
        lock_file_format = v1_lock_file
    else:
        fail("Unable to determine lock file format")

    return lock_file_format.get_artifacts(lock_file_contents)
