
use std::env;
use std::fs::File;
use std::io::{self, BufRead};
use std::path::PathBuf;

pub mod bindings;

pub fn getenv(var: &str, default: &str) -> String {
    return match env::var(var) {
        Ok(val) => val,
        Err(_err) => default.to_string()
    };
}

#[link(name="bb", kind="static")]
extern "C" {
pub fn _BB();
}

#[macro_export]
macro_rules! BB {
    () => {
        use classico_wd40::_BB;
        use classico_wd40::getenv;
        if getenv("BB", "") == "1" {
            unsafe { _BB(); } 
        }
    };
}

pub fn read_deps_config() {
    let foo_dir = PathBuf::from(env::var("MK_CARGO_DIR").unwrap());
    let config_path = foo_dir.join("dep.env");

    let file = File::open(&config_path).unwrap();
    let reader = io::BufReader::new(file);
    for line in reader.lines() {
        let line = line.unwrap();
        println!("cargo:rustc-env={}", line);
    }
}
