# Bazel rules for ServiceTalk

ServiceTalk is a JVM network application framework with APIs tailored to specific protocols
(e.g. HTTP/1.x, HTTP/2.x, etc...) and supports multiple programming paradigms.
See the [ServiceTalk docs](https://docs.servicetalk.io/) for more information.

This repo contains Bazel rules for ServiceTalk.

## Quick Start

To use `rules_servicetalk`, add the following to your `MODULE.bazel` file

```python
# Please check the releases page on GitHub for the latest released version
bazel_dep(name = "rules_servicetalk", version = "0.0.0")

#### Servicetalk ####

register_toolchains("@rules_servicetalk//servicetalk:st-toolchain")
```

## Examples

See the `tests/` directory for complete examples on how to use `rules_servicetalk`

## Protobuf and gRPC

Servicetalk is still tied to the 3.25.8 version of the Protobuf compiler and the runtime libraries. `rules_servicetalk`
keeps this intact for Bazel builds. We recommend you use the `@rules_servicetalk//proto:deps.bzl` protobuf rules
(`proto_library`, `java_proto_library`) to ensure you are using the correct protobuf compiler and runtime.

We also recommend you use the `@rules_servicetalk//servicetalk:deps.bzl` and the `service_talk_proto_library` rule
to generate the servicetalk java libraries from the raw `*.proto` files for your project.

If you are using rules_servicetalk, we strongly recommend against including the `protobuf` or `java_grpc`
bazel rules in your repo. Each of these makes assumptions about which `protoc` version to use and the results may
clash in ways that break your application.
