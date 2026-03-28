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

load("//proto:defs.bzl", "proto_library")
load(":library.bzl", "service_talk_proto_library")

def generate_service_talk_proto(src, deps = None, strip_prefix = None, visibility = None):
    """
    Convenience macro for generating a single service talk proto library from the proto source.

    Follows the Bazel recommendations of generating a single library for each protobuf file, and in turn generating
    the single service talk proto library for each one.

    From the protobuf file name (e.g. FooBar.proto) generates the targets of:
        "FooBar_proto" as the single protobuf library
        "FooBar" as the final service talk library.

    Args:
        src: Single protobuf file to compile and service talk process
        deps: list of dependencies, usually only other protobuf files and google protobuf dependencies.
        strip_prefix: See proto_library.strip_prefix
        visibility: Visibility of both the protobuf compiled library and the final service talk library.
    """
    prefix = strip_prefix or "/" + native.package_name()

    if not src.endswith(".proto"):
        fail('"src" attribute should end with ".proto"')

    proto_name = src.replace(".proto", "_proto").replace("/", "_")
    service_talk_name = src[0:-len(".proto")]

    proto_library(
        name = proto_name,
        srcs = [src],
        strip_import_prefix = prefix,
        deps = deps,
        visibility = visibility,
    )

    service_talk_proto_library(
        name = service_talk_name,
        deps = [
            ":" + proto_name,
        ],
        visibility = visibility,
    )
