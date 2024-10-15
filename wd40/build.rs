
use std::env;
use std::fs;
use std::path::PathBuf;

fn main() {
    let root = env::var("CARGO_MANIFEST_DIR").unwrap();

    let bb_path = PathBuf::from(root).join("linux-x64");

    let out_dir = PathBuf::from(env::var("MK_CARGO_TARGET_DIR").unwrap());
    let deps_file_path = out_dir.join("deps.env");

    let deps_vars = [ [ "WD40_SEARCH_PATH", &bb_path.display().to_string() ],
                      [ "WD40_LINK_LIB", "static=bb" ] ];

    let deps_vars_str = deps_vars.iter().map(|c| format!("{}={}\n", c[0], c[1])).collect::<Vec<String>>().join("");

    fs::write(&deps_file_path, deps_vars_str).expect("Unable to write deps.env file");

    println!("cargo:rustc-link-lib=bb");
    println!("cargo:rustc-link-search=native={}", bb_path.display());

    println!("cargo:rerun-if-changed={}/libbb.a", bb_path.display());
}
