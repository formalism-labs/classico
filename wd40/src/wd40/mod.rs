

mod bindings;
pub use bindings::*;

use std::env;
use std::fs::File;
use std::io::{self, BufRead};
use std::path::PathBuf;
use std::error::Error;
//use std::fmt;
use std::process::Command;

//---------------------------------------------------------------------------------------------

pub fn getenv(var: &str, default: &str) -> String {
    return match env::var(var) {
        Ok(val) => val,
        Err(_err) => default.to_string()
    };
}

pub fn command_line(cmd: &Command) -> String {
    format!("{:?} {}", cmd.get_program(), cmd.get_args().map(|arg| arg.to_string_lossy()).collect::<Vec<_>>().join(" "))
}

//---------------------------------------------------------------------------------------------

#[link(name="bb", kind="static")]
extern "C" {
pub fn _BB();
}

#[macro_export]
macro_rules! BB {
    () => {
        use classico::wd40::_BB;
        use classico::wd40::getenv;
        if getenv("BB", "") == "1" {
            unsafe { _BB(); } 
        }
    };
}

pub use BB;

//---------------------------------------------------------------------------------------------

pub fn read_deps_config() {
    let target_dir = PathBuf::from(env::var("MK_CARGO_TARGET_DIR").unwrap());
    let config_path = target_dir.join("deps.env");

    let file = File::open(&config_path).unwrap();
    let reader = io::BufReader::new(file);
    for line in reader.lines() {
        let line = line.unwrap();
        println!("cargo:rustc-env={}", line);
    }
}

//---------------------------------------------------------------------------------------------

pub struct Build {
    root: String,
    profile: String,
    bindir: String
}

impl Build {
    pub fn new() -> Self {
        Build {
            root: env::var("CARGO_MANIFEST_DIR").unwrap(),
            profile: env::var("PROFILE").unwrap_or_else(|_| "debug".to_string()),
            bindir: env::var("MK_BINDIR").unwrap()
        }
    }

    pub fn root(&self) -> &String { &self.root }
    pub fn is_debug(&self) -> bool { self.profile == "debug" }
    pub fn bindir(&self) -> &String { &self.bindir }
}

//---------------------------------------------------------------------------------------------

pub struct BuildLog {
    path: String,
    pub file: File
}

impl BuildLog {
    pub fn new() -> Result<Self, Box<dyn Error>> {
        let path = env::var("MK_CARGO_LOG").unwrap();
        let file = File::create(path.clone())?;
        Ok(BuildLog { path: path, file: file })
    }
}

#[macro_export]
macro_rules! blog {
    ($blog:expr, $fmt:expr $(, $args:expr)*) => {{
        writeln!($blog.file, "{}", format!($fmt $(, $args)*))
    }};
}

pub use blog;

//---------------------------------------------------------------------------------------------
