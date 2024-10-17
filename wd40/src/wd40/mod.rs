
mod bindings;
pub use bindings::*;

use std::env;
use std::fs::{File, OpenOptions};
use std::io::{self, BufRead, Write};
use std::path::PathBuf;
use std::error::Error;
use std::process::Command;

//---------------------------------------------------------------------------------------------

pub fn getenv(var: &str, default: &str) -> String {
    return match env::var(var) {
        Ok(val) => val,
        Err(_err) => default.to_string()
    };
}

pub fn command_str(cmd: &Command) -> String {
    format!("{:?} {}", cmd.get_program(), cmd.get_args().map(|arg| arg.to_string_lossy()).collect::<Vec<_>>().join(" "))
}

//---------------------------------------------------------------------------------------------

#[link(name="bb", kind="static")]
extern "C" {
pub fn wd40_BB();
}

#[macro_export]
macro_rules! BB {
    () => {
        use classico::wd40::wd40_BB;
        use classico::wd40::getenv;
        if getenv("BB", "") == "1" {
            unsafe { wd40_BB(); } 
        }
    };
}

pub use BB;

//---------------------------------------------------------------------------------------------

pub fn export_deps_config() -> Result<(), Box<dyn Error>> {
    let target_dir = PathBuf::from(env::var("MK_CARGO_TARGET_DIR")?);
    let config_path = target_dir.join("deps.env");

    let file = File::open(&config_path)?;
    let reader = io::BufReader::new(file);
    for line in reader.lines() {
        let line = line.unwrap();
        println!("cargo:rustc-env={}", line);
    }
    Ok(())
}

//---------------------------------------------------------------------------------------------

pub struct BuildLog {
    pub file: File
}

impl BuildLog {
    pub fn new() -> Result<Self, Box<dyn Error>> {
        let path = env::var("MK_CARGO_LOG")?;
        let file = OpenOptions::new()
            .append(true)
            .create(true)
            .open(&path)?;
        Ok(BuildLog { file: file })
    }
}

//---------------------------------------------------------------------------------------------

pub struct Build {
    root: String, // dir of carte that owns Build instance
    profile: String,
    mk_root: String, // root dir of carte that invoked make
    bindir: String, // bindir of the carte that invoked make
    log: BuildLog
}

impl Build {
    pub fn new() -> Result<Self, Box<dyn Error>> {
        let root = env::var("CARGO_MANIFEST_DIR")?;
        let profile = getenv("PROFILE", "debug");
        let mk_root = env::var("MK_ROOT")
            .expect("MK_ROOT undefined: build with make");    
        let bindir = env::var("MK_BINDIR").
            expect("MK_BINDIR undefined: build with make");
        let log = BuildLog::new()?;

        export_deps_config()?;

        Ok(Build { root: root, profile: profile, mk_root: mk_root, bindir: bindir, log: log })
    }

    pub fn root(&self) -> &String { &self.root }
    pub fn mk_root(&self) -> &String { &self.mk_root }
    pub fn is_debug(&self) -> bool { self.profile == "debug" }
    pub fn bindir(&self) -> &String { &self.bindir }

    pub fn log(&mut self, text: &str) {
        writeln!(self.log.file, "{}", text).expect("error writing to build log file");
    }
    pub fn blog(&mut self, text: &Vec<u8>) {
        self.log.file.write_all(text).expect("error writing to build log file");
    }
}

#[macro_export]
macro_rules! blog {
    ($build:expr, $fmt:expr $(, $args:expr)*) => {{
        $build.log(&format!($fmt $(, $args)*))
    }};
}

pub use blog;

//---------------------------------------------------------------------------------------------
