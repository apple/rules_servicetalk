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
load("@rules_java//java/common:java_info.bzl", "JavaInfo")
load("//proto/private:utils.bzl", "is_third_party_proto")

# This is a nasty, nasty hack. There are protobufs that are supplied
# in two ways: as raw `.proto` files and in pre-compiled form via a
# third party jar. The regular java protobuf library is one example
# of this. The correct thing to do is to check the compile-time
# classpath used when compiling each proto to see if it contains a
# class with the same name and avoid adding that to the transitive
# classpath of protos we compile later.
KNOWN_THIRD_PARTY_PROTO_WORKSPACES = [
    "com_google_protobuf",
    "common_protos",
]

ZipProtoInfo = provider(
    fields = {
        "zips": "A depset of zip files containing the raw proto files",
    },
)

def _zip_protos_aspect_impl(target, ctx):
    proto_info = target[ProtoInfo]

    if is_third_party_proto(target.label):
        return ZipProtoInfo(
            zips = depset(
                direct = [],
                transitive = [dep[ZipProtoInfo].zips for dep in getattr(ctx.rule.attr, "deps", []) if ZipProtoInfo in dep],
            ),
        )

    # Prepare a zip with just the proto files in
    proto_zip = ctx.actions.declare_file("%s-protos.zip" % target.label.name)
    zip_args = ctx.actions.args()
    zip_args.add_all(["c", proto_zip.path])

    prefix = proto_info.proto_source_root

    mappings = []
    for proto in proto_info.direct_sources:
        if "." == prefix:
            mappings.append(proto.path)
        elif len(prefix):
            # We want to strip the prefix and its trailing slash iff the prefix has length
            mappings.append("%s=%s" % (proto.path[len(prefix) + 1:], proto.path))
        else:
            mappings.append(proto.path)

    # It would be nice to use a mapping function, but we need access to the prefix
    zip_args.add_all(mappings)

    ctx.actions.run(
        executable = ctx.executable._zip,
        inputs = proto_info.direct_sources,
        outputs = [proto_zip],
        arguments = [zip_args],
    )

    return [
        ZipProtoInfo(
            zips = depset(
                direct = [proto_zip],
                transitive = [dep[ZipProtoInfo].zips for dep in getattr(ctx.rule.attr, "deps", []) if ZipProtoInfo in dep],
            ),
        ),
    ]

_zip_protos_aspect = aspect(
    _zip_protos_aspect_impl,
    attr_aspects = ["deps"],
    required_aspect_providers = [
        [ProtoInfo],
        [ProtoInfo, ZipProtoInfo],
    ],
    provides = [
        ZipProtoInfo,
    ],
    attrs = {
        "_zip": attr.label(
            executable = True,
            cfg = "exec",
            default = "@bazel_tools//tools/zip:zipper",
        ),
    },
)

def _to_path(file):
    return file.path

def _zip_protos_impl(ctx):
    zips = depset(transitive = [dep[ZipProtoInfo].zips for dep in getattr(ctx.attr, "deps", [])])

    out_name = getattr(ctx.attr, "out", "%s-protos.zip" % ctx.attr.name)
    out_zip = ctx.actions.declare_file(out_name)

    # Merge all the zips together
    args = ctx.actions.args()
    args.add_all(["--normalize", "--compression", "--exclude_build_data", "--add_missing_directories"])
    args.add_all(zips, before_each = "--sources", map_each = _to_path, uniquify = True)
    args.add("--output", out_zip)

    ctx.actions.run(
        inputs = zips,
        outputs = [out_zip],
        executable = ctx.executable._singlejar,
        arguments = [args],
    )

    return [
        DefaultInfo(
            files = depset([out_zip]),
        ),
        JavaInfo(
            output_jar = out_zip,
            compile_jar = out_zip,
        ),
    ]

zip_protos = rule(
    _zip_protos_impl,
    doc = """Packages proto files into a zip file.

    When called, all the transitive protos this target depends on (other
    that Google's protobufs) will be packaged.
    """,
    attrs = {
        "deps": attr.label_list(
            doc = "A list of `proto_library` targets that contain the protos that should be packed.",
            aspects = [_zip_protos_aspect],
            providers = [
                [ProtoInfo, ZipProtoInfo],
            ],
        ),
        "out": attr.string(
            doc = "The output file name. Defaults to be being derived from the `name` of the target.",
        ),
        "_singlejar": attr.label(
            executable = True,
            cfg = "exec",
            default = "@rules_java//toolchains:singlejar",
        ),
    },
    provides = [
        JavaInfo,
    ],
)
