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

load("//servicetalk/private:library.bzl", _service_talk_proto_library = "service_talk_proto_library")
load("//servicetalk/private:proto.bzl", _generate_service_talk_proto = "generate_service_talk_proto")
load(
    "//servicetalk/private:toolchain.bzl",
    _TOOLCHAIN_TYPE = "TOOLCHAIN_TYPE",
    _service_talk_toolchain = "service_talk_toolchain",
)
load("//servicetalk/private/providers:service_talk_java_proto_info.bzl", _ServiceTalkJavaProtoInfo = "ServiceTalkJavaProtoInfo")
load("//servicetalk/private/providers:zip_proto_info.bzl", _ZipProtoInfo = "ZipProtoInfo")

TOOLCHAIN_TYPE = _TOOLCHAIN_TYPE
service_talk_toolchain = _service_talk_toolchain

service_talk_proto_library = _service_talk_proto_library
generate_service_talk_proto = _generate_service_talk_proto

ServiceTalkJavaProtoInfo = _ServiceTalkJavaProtoInfo
ZipProtoInfo = _ZipProtoInfo
