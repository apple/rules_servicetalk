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

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "read_netrc", "read_user_netrc", "use_netrc")

def get_auth(rctx, urls):
    """Given the list of URLs obtain the correct auth dict."""
    netrc_attr = getattr(rctx.attr, "netrc", None)
    if netrc_attr:
        netrc = read_netrc(rctx, netrc_attr)
    else:
        netrc = read_user_netrc(rctx)

    auth_patterns = getattr(rctx.attr, "auth_patterns", {})
    return use_netrc(netrc, urls, auth_patterns)

def download(rctx, url = None, auth = None, **kwargs):
    if not auth:
        auth = get_auth(rctx, url)

    return rctx.download(url = url, auth = auth, **kwargs)

def download_and_extract(rctx, url = None, auth = None, **kwargs):
    if not url:
        fail("Please specify `url` to download.")

    if not auth:
        auth = get_auth(rctx, url)

    return rctx.download_and_extract(url = url, auth = auth, **kwargs)
