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
load("@protobuf//bazel:java_proto_library.bzl", _java_proto_library = "java_proto_library")
load("@rules_java//java:defs.bzl", "java_library")
load(":zip_protos.bzl", "zip_protos")

def java_proto_library(name, deps = [], visibility = None, **kwargs):
    """Create a jar file from proto_library dependencies.

    This will pack the raw protos into the generated jars when
    used in conjunction with `java_export`.

    Args:
      name: The name of the rule.
      deps: A list of `proto_library` dependencies.
    """

    # Create the default proto library
    zip_protos(
        name = "%s-raw-protos" % name,
        out = "%s-raw-protos.jar" % name,
        deps = deps,
    )
    _java_proto_library(
        name = "%s-proto-base" % name,
        deps = deps,
        **kwargs
    )
    java_library(
        name = name,
        exports = ["%s-proto-base" % name],
        runtime_deps = [":%s-raw-protos" % name],
        visibility = visibility,
    )
