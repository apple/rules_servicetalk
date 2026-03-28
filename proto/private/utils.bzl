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

# This is a nasty, nasty hack. There are protobufs that are supplied
# in two ways: as raw `.proto` files and in pre-compiled form via a
# third party jar. The regular java protobuf library is one example
# of this. The correct thing to do is to check the compile-time
# classpath used when compiling each proto to see if it contains a
# class with the same name and avoid adding that to the transitive
# classpath of protos we compile later.
_KNOWN_THIRD_PARTY_PROTO_WORKSPACES = [
    "com_google_protobuf",
    "common_protos",
    "com_github_protocolbuffers_protobuf",
]

def is_third_party_proto(label):
    """Determines whether the given label refers to a protobuf provided in the base Google libraries."""
    return label.workspace_name in _KNOWN_THIRD_PARTY_PROTO_WORKSPACES
