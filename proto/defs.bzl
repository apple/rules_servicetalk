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

load("@protobuf//bazel:proto_library.bzl", _proto_library = "proto_library")
load("@protobuf//bazel/toolchains:proto_lang_toolchain.bzl", _proto_lang_toolchain = "proto_lang_toolchain")
load("//proto/private:java_proto_library.bzl", _java_proto_library = "java_proto_library")
load(
    "//proto/private:zip_protos.bzl",
    _KNOWN_THIRD_PARTY_PROTO_WORKSPACES = "KNOWN_THIRD_PARTY_PROTO_WORKSPACES",
    _zip_protos = "zip_protos",
)

proto_library = _proto_library
proto_lang_toolchain = _proto_lang_toolchain

zip_protos = _zip_protos

java_proto_library = _java_proto_library

KNOWN_THIRD_PARTY_PROTO_WORKSPACES = _KNOWN_THIRD_PARTY_PROTO_WORKSPACES
