
extern crate bindgen;

use std::env;
use std::path::PathBuf;
use std::process::Command;

pub fn generate_bindings(header: &str, bindings_fname: &str) {
    let bindings = bindgen::Builder::default()
        .header(header)
        .generate()
        .expect("Unable to generate bindings");

    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
    let bindings_path = out_path.join(bindings_fname);
    bindings
        .write_to_file(bindings_path.clone())
        .expect(format!("Couldn't generate bindings for {}", header).as_str());

    let status = Command::new("sh")
        .arg("-c")
        .arg(format!("{} {}", r#"sed -i '/#\[test\]/a\#[allow(non_snake_case)]' "#, bindings_path.display()))
        .status()
        .expect("Failed to run sed command");
    if !status.success() {
        panic!("sed failed with status: {:?}", status);
    }
}

