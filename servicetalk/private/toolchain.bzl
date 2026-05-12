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

load("@rules_java//java/common:java_info.bzl", "JavaInfo")
load("@rules_jvm_external//private/rules:has_maven_deps.bzl", "MavenInfo", "has_maven_deps")

TOOLCHAIN_TYPE = "@rules_servicetalk//servicetalk:st_toolchain_type"

def _st_toolchain_impl(ctx):
    return platform_common.ToolchainInfo(
        plugin = ctx.executable.plugin,
        resolved_plugin = ctx.resolve_tools(tools = [ctx.attr.plugin]),
        runtime = ctx.attr.runtime,
    )

_st_toolchain = rule(
    _st_toolchain_impl,
    attrs = {
        "plugin": attr.label(
            cfg = "exec",
            executable = True,
            allow_files = True,
            mandatory = True,
            providers = [
                JavaInfo,
            ],
        ),
        "runtime": attr.label_list(
            allow_files = False,
            mandatory = True,
            providers = [
                [JavaInfo, MavenInfo],
            ],
            aspects = [
                has_maven_deps,
            ],
        ),
    },
)

def service_talk_toolchain(name, plugin, runtime):
    """Defines the workspace-wide toolchain to use when compiling ServiceTalk code.

    This toolchain is shared by every `service_talk_proto_library` target in
    the entire repo, so it's advisable to keep this as slim as possible.

    Args:
      name: The name of the toolchain.
      plugin: A `java_library` that can be used as a dependency for
        running the ServiceTalk `protoc` plugin.
      runtime: A `java_library` that should be used by ServiceTalk classes
        at runtime. Analogous to `java_library`'s own `runtime_deps`
        attribute.
      legacy: Whether the toolchain is for the pre-oss version of servicetalk.
    """
    toolchain_name = name + "_impl"

    _st_toolchain(
        name = toolchain_name,
        plugin = plugin,
        runtime = runtime,
        visibility = [
            "//visibility:public",
        ],
    )

    native.toolchain(
        name = name,
        toolchain = ":%s" % toolchain_name,
        toolchain_type = TOOLCHAIN_TYPE,
    )
