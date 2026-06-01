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

load("@protobuf//bazel/common:proto_info.bzl", "ProtoInfo")
load("@rules_java//java:defs.bzl", "java_library")
load("@rules_java//java/common:java_common.bzl", "java_common")
load("@rules_java//java/common:java_info.bzl", "JavaInfo")
load("@rules_jvm_external//private/rules:has_maven_deps.bzl", "MavenHintInfo", "MavenInfo")
load("//proto:defs.bzl", "zip_protos")
load("//proto/private:utils.bzl", "is_third_party_proto")
load("//servicetalk/private/providers:service_talk_java_proto_info.bzl", "ServiceTalkJavaProtoInfo")
load(":toolchain.bzl", "TOOLCHAIN_TYPE")

# Unfortunately Bazel hard requires that aspects and rules are actually defined
# as variables in the top-level of a starlark file, so we can't do any sneaky
# shenanigans with for loops or list/dict comprehensions.

def _service_talk_java_aspect_impl(target, ctx):
    return _service_talk_java_aspect_impl_with_custom_toolchain(target, ctx, TOOLCHAIN_TYPE)

def _service_talk_java_aspect_impl_with_custom_toolchain(target, ctx, toolchain_type):
    st_toolchain = ctx.toolchains[toolchain_type]

    proto_toolchain = ctx.toolchains["@protobuf//bazel/private:proto_toolchain_type"].proto
    _protoc = proto_toolchain.proto_compiler
    protoc_executable = _protoc.executable.path

    # Bail fast if we're compiling a protobuf that ships as part of Google's
    # base protobuf library. This avoids us including the compiled protobuf
    # twice on the classpath (once from this aspect, once from the google
    # protobuf jar)
    if is_third_party_proto(target.label):
        return [
            MavenHintInfo(
                maven_infos = depset([dep[MavenInfo] for dep in st_toolchain.runtime]),
            ),
            ServiceTalkJavaProtoInfo(
                jar = None,
                transitive_jars = depset(transitive = [dep[JavaInfo].transitive_runtime_jars for dep in st_toolchain.runtime]),
                transitive_java_infos = [dep[JavaInfo] for dep in st_toolchain.runtime],
            ),
        ]

    proto_info = target[ProtoInfo]

    src_dir = ctx.actions.declare_directory("%s-proto-sources" % target.label.name)
    protoc_args = ctx.actions.args()

    # Get the plugin executable - use files_to_run to get the executable with runfiles support
    plugin_executable = st_toolchain.plugin_label[DefaultInfo].files_to_run.executable

    cmd = "mkdir -p %s && " % src_dir.path
    cmd = cmd + "%s " % protoc_executable

    cmd = cmd + "--plugin=protoc-gen-st_grpc=%s " % plugin_executable.path

    cmd = cmd + "".join(["--proto_path=%s " % p for p in proto_info.transitive_proto_path.to_list()])

    # This isn't terribly efficient, but it'll be okay since we don't expect
    # this to ever become truly gargantuan.
    for src in proto_info.transitive_sources.to_list():
        for path in proto_info.transitive_proto_path.to_list():
            if src.path.startswith(path + "/"):
                cmd = cmd + ("-I%s=%s " % (src.path[len(path + "/"):], src.path))

    cmd = cmd + "--java_out=%s " % src_dir.path
    cmd = cmd + "--st_grpc_out=%s " % src_dir.path

    cmd = cmd + " ".join([src.path for src in proto_info.direct_sources])

    # We need to use a run_shell since protoc doesn't seem to create the directory
    # for us.
    inputs = depset([], transitive = [proto_info.transitive_sources])
    ctx.actions.run_shell(
        command = cmd,
        arguments = [],
        outputs = [src_dir],
        inputs = inputs,
        tools = [
            _protoc,
            st_toolchain.plugin_label[DefaultInfo].files_to_run,
        ],
        mnemonic = "ServiceTalkProtoc",
        progress_message = "Generating ServiceTalk source for %s" % ", ".join([src.path for src in proto_info.direct_sources]),
        toolchain = toolchain_type,
    )

    # Gather all the sources together
    src_jar = ctx.actions.declare_file("%s-proto-src.jar" % target.label.name)
    zip_args = ctx.actions.args()
    zip_args.add_all(["c", src_jar.path])
    zip_args.add_all([src_dir], map_each = _to_short_path)

    ctx.actions.run(
        executable = ctx.executable._zip,
        inputs = [src_dir],
        outputs = [src_jar],
        arguments = [zip_args],
    )

    all_proto_info = [dep[ServiceTalkJavaProtoInfo] for dep in ctx.rule.attr.deps] + \
                     [dep[ServiceTalkJavaProtoInfo] for dep in ctx.rule.attr.exports]

    compile_time_deps = depset([], transitive = [pi.transitive_jars for pi in all_proto_info])
    compile_time_infos = [info for pi in all_proto_info for info in pi.transitive_java_infos]

    out_jar = ctx.actions.declare_file("%s.jar" % target.label.name)
    all_deps = [lib[JavaInfo] for lib in st_toolchain.runtime] + compile_time_infos
    java_info = java_common.compile(
        ctx,
        source_jars = [src_jar],
        output = out_jar,
        deps = all_deps,
        exports = all_deps,
        java_toolchain = ctx.attr._java_toolchain[java_common.JavaToolchainInfo],
    )
    return [
        java_info,
        MavenHintInfo(
            maven_infos = depset([dep[MavenInfo] for dep in st_toolchain.runtime]),
        ),
        ServiceTalkJavaProtoInfo(
            jar = out_jar,
            transitive_jars = depset([out_jar], transitive = [compile_time_deps]),
            transitive_java_infos = [java_common.make_non_strict(java_info)] + compile_time_infos,
        ),
    ]

# generates mapping entry for zip for given file.
def _to_short_path(f, expander):
    return f.tree_relative_path + "=" + f.path

def _service_talk_proto_library_impl(ctx):
    jars = depset([], transitive = [dep[ServiceTalkJavaProtoInfo].transitive_jars for dep in ctx.attr.deps])
    infos = [info for dep in ctx.attr.deps for info in dep[ServiceTalkJavaProtoInfo].transitive_java_infos]

    # output an empty zip, since an output is expected
    out_jar = ctx.actions.declare_file("lib%s.jar" % ctx.attr.name)
    args = ctx.actions.args()
    args.add_all(["--normalize", "--compression"])
    args.add("--output", out_jar)

    ctx.actions.run(
        inputs = [],
        outputs = [out_jar],
        executable = ctx.executable._singlejar,
        arguments = [args],
    )

    return [
        JavaInfo(
            output_jar = out_jar,
            compile_jar = out_jar,
            exports = infos,
        ),
        DefaultInfo(
            files = jars,
        ),
    ]

def _make_aspect(toolchain_type):
    toolchains = [
        toolchain_type,
        "@bazel_tools//tools/jdk:toolchain_type",
    ]

    attrs = {
        "_java_toolchain": attr.label(
            default = "@rules_java//toolchains:current_java_toolchain",
        ),
        "_javabase": attr.label(
            default = "@rules_java//toolchains:current_java_runtime",
        ),
        "_zip": attr.label(
            executable = True,
            cfg = "exec",
            default = "@bazel_tools//tools/zip:zipper",
        ),
    }
    toolchains.append("@protobuf//bazel/private:proto_toolchain_type")

    return aspect(
        _service_talk_java_aspect_impl,
        attr_aspects = [
            "deps",
            "exports",
            "runtime_deps",
        ],
        required_providers = [
            ProtoInfo,
        ],
        required_aspect_providers = [
            ServiceTalkJavaProtoInfo,
        ],
        provides = [
            ServiceTalkJavaProtoInfo,
        ],
        attrs = attrs,
        toolchains = toolchains,
        host_fragments = [
            "java",
            "proto",
        ],
        fragments = [
            "java",
        ],
    )

_aspect = _make_aspect(TOOLCHAIN_TYPE)

def _make_rule(toolchain_type):
    toolchains = [
        toolchain_type,
        "@bazel_tools//tools/jdk:toolchain_type",
    ]
    toolchains.append("@protobuf//bazel/private:proto_toolchain_type")

    return rule(
        _service_talk_proto_library_impl,
        attrs = {
            "deps": attr.label_list(
                allow_empty = False,
                providers = [
                    ProtoInfo,
                ],
                aspects = [
                    _aspect,
                ],
            ),
            "_singlejar": attr.label(
                executable = True,
                cfg = "exec",
                default = "@rules_java//toolchains:singlejar",
            ),
            "_zip": attr.label(
                executable = True,
                cfg = "exec",
                default = "@bazel_tools//tools/zip:zipper",
            ),
        },
        toolchains = toolchains,
        provides = [
            JavaInfo,
        ],
    )

_rule = _make_rule(TOOLCHAIN_TYPE)

def service_talk_proto_library(name, deps = [], visibility = None, tags = None):
    """Create a java artifact containing the compiled ServiceTalk protos.

    The raw proto files will be included if this is included in a
    `java_export` target. In order to configure the toolchain to be
    used, ensure that `service_talk_toolchains` has been called in
    your `WORKSPACE`

    Args:
      name: The name of the target.
      deps: A list of `proto_library` dependencies, used for generating the
        classes.
      visibility: The visibility of the rule. Defaults to being private.
      kwargs: Any additional args are passed to the
    """

    # Create the default proto library
    zip_protos(
        name = "%s-raw-protos" % name,
        out = "%s-raw-protos.jar" % name,
        deps = deps,
        tags = tags,
    )

    _rule(
        name = "%s-proto-base" % name,
        deps = deps,
        tags = tags,
    )
    java_library(
        name = name,
        exports = ["%s-proto-base" % name],
        runtime_deps = [":%s-raw-protos" % name],
        visibility = visibility,
        tags = tags,
    )
