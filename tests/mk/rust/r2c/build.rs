
use std::process::{Command, Stdio};
use std::error::Error;

extern crate classico;
use classico::wd40;
use classico::wd40::blog;

fn main() -> Result<(), Box<dyn Error>> {
    let mut build = wd40::Build::new()?;

    let root = &build.root();
    let clib_root = format!("{}/clib", root);
    
    let mut make = Command::new("make");
    make.current_dir(&clib_root);
    make.stderr(Stdio::piped());
    make.stdout(Stdio::piped());
    make.arg("SEP=0");
    make.arg(&format!("ROOT={}", &build.mk_root()));
    if build.is_debug() {
        make.arg("DEBUG=1");
    }

    blog!(build, "\n# in {}, running: {}", clib_root, wd40::command_str(&make));
    
    let make_out = make.output()    
        .expect("clib build failed to execute");
    build.blog(&make_out.stdout);
    if !make_out.status.success() {
        panic!("clib build failed");
    }

    let clib_h = format!("{}/clib.h", &clib_root);
    wd40::generate_bindings(&clib_h, "clib.rs");

    println!("cargo:rustc-link-lib=clib");
    println!("cargo:rustc-link-lib=stdc++");
    println!("cargo:rustc-link-search=native={}/clib", build.bindir());

    Ok(())
}
