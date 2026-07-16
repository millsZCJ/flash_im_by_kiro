fn main() {
    prost_build::compile_protos(
        &["../../../proto/ws.proto"],
        &["../../../proto/"],
    )
    .expect("Failed to compile proto files");
}
