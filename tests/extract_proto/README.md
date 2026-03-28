# Extract Proto

The Extract Proto tool is a simple addition to the Protobuf bazel rules to extract the `*.proto` files from a 
third party dependency jar file, and compile them, using the current project version of the Protobuf Compiler toolchain.

This strongly recommended practice allows your upstream dependencies distribute their protobuf API code and allows
you to use the most current version of the Protobuf compiler and libraries. This allows for a greater decoupling than
having the upstream dependencies distribute pre-compiled protobuf generated java code, which ties your project to 
whichever version those projects are using. 

This directory is both an example of using the `extract_proto` code and a test to verify it still functions correctly 
with the current `rules_servicetalk`.
