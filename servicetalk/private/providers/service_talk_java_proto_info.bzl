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

ServiceTalkJavaProtoInfo = provider(
    fields = {
        "jar": "Path to the generated jar",
        "transitive_jars": "depset of all jars required so far",
        "transitive_java_infos": "list of all JavaInfos, suitable for use with java_common.compile",
    },
)
