// Copyright © 2026 Apple Inc. and the ServiceTalk project authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
package com.apple.bazel.servicetalk ;

import com.google.protobuf.GeneratedMessageV3;
import com.google.protobuf.StringValue;
import com.apple.bazel.servicetalk.proto.Person;

public class NewEnum {

    public GeneratedMessageV3 getValue(final Person person) {
        return StringValue.of(person.getName());
    }
}
