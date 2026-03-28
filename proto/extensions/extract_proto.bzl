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
load("//proto/private:extract_proto_library_from_jar.bzl", "extract_proto_library_from_jar")

proto_jar = tag_class(
    attrs = {
        "coordinates": attr.string(
            doc = "Maven coordinates to extract protos from of the form `groupId:artifactId'",
            mandatory = True,
        ),
        "deps": attr.label_list(
            doc = "Any deps that the `proto_library` needs",
        ),
        "maven_install_json": attr.label(
            doc = "The maven install json file used by `maven_install`",
            mandatory = True,
            allow_single_file = True,
        ),
        "name": attr.string(mandatory = True, doc = "namespace for the dependencies"),
        "patterns": attr.string_list(
            default = ["**/*.proto"],
            mandatory = False,
        ),
    },
)

def extract_proto_impl(mctx):
    dep_names = []
    for module in mctx.modules:
        for jar in module.tags.jars:
            extract_proto_library_from_jar(
                name = jar.name,
                coordinates = jar.coordinates,
                deps = jar.deps,
                maven_install_json = jar.maven_install_json,
                patterns = jar.patterns,
            )
            dep_names.append(jar.name)

    return mctx.extension_metadata(
        reproducible = True,
        root_module_direct_deps = dep_names,
        root_module_direct_dev_deps = [],
    )

extract_proto = module_extension(
    extract_proto_impl,
    tag_classes = {
        "jars": proto_jar,
    },
)
