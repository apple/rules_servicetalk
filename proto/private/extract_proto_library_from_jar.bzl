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
load(":http_utils.bzl", "download_and_extract")
load(":lock_file.bzl", "get_artifacts")

def _extract_proto_library_from_jar(repo_ctx):
    path = repo_ctx.path(repo_ctx.attr.maven_install_json)
    raw_json = repo_ctx.read(path)
    parsed = json.decode(raw_json)

    artifacts = get_artifacts(parsed)

    matching = [dep for dep in artifacts if dep["coordinates"].startswith(repo_ctx.attr.coordinates + ":")]

    if not len(matching):
        fail("No dependency found for " + repo_ctx.attr.coordinates)

    urls = matching[0]["urls"]
    sha = matching[0]["sha256"]

    download_and_extract(
        rctx = repo_ctx,
        url = urls,
        sha256 = sha,
        type = "zip",
    )

    repo_ctx.file(
        "WORKSPACE",
        content = """
workspace(name = {name})
""".format(name = repo_ctx.name),
    )

    repo_ctx.file(
        "BUILD.bazel",
        content = """
package(default_visibility = ["//visibility:public"])

load("@protobuf//bazel:proto_library.bzl", "proto_library")

proto_library(
  name = "protos",
  srcs = glob([{pattern}]),
  deps = {deps},
)

""".format(
            deps = repr([str(dep) for dep in repo_ctx.attr.deps]),
            pattern = ",".join(["\"%s\"" % pattern for pattern in repo_ctx.attr.patterns]),
        ),
    )
    pass

extract_proto_library_from_jar = repository_rule(
    _extract_proto_library_from_jar,
    doc = "Extract a `proto_library` from a maven-provided jar",
    attrs = {
        "coordinates": attr.string(
            doc = "Maven coordinates to extract protos from of the form `groupId:artifactId'",
            mandatory = True,
        ),
        "deps": attr.label_list(
            doc = "Any deps that the `proto_library` needs",
            providers = [
                ProtoInfo,
            ],
        ),
        "maven_install_json": attr.label(
            doc = "The maven install json file used by `maven_install`",
            mandatory = True,
            allow_single_file = True,
        ),
        "patterns": attr.string_list(
            default = ["**/*.proto"],
            mandatory = False,
        ),
    },
)
