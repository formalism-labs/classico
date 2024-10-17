
use std::env;
use std::fs;
use std::path::PathBuf;
use std::error::Error;
use std::process::{Command, Stdio};
use std::fs::OpenOptions;
use std::io::Write;

pub fn command_str(cmd: &Command) -> String {
    format!("{:?} {}", cmd.get_program(), cmd.get_args().map(|arg| arg.to_string_lossy()).collect::<Vec<_>>().join(" "))
}

fn main() -> Result<(), Box<dyn Error>> {
	let wd40_root = env::var("CARGO_MANIFEST_DIR")?;
    let bb_root = format!("{}/bb", &wd40_root);

    let mk_root = env::var("MK_ROOT")
        .expect("MK_ROOT undefined: build with make");
    let bindir = env::var("MK_BINDIR")
        .expect("MK_BINDIR undefined: build with make");

    let log_path = env::var("MK_CARGO_LOG")
        .expect("MK_CARGO_LOG undefined: build with make");
    let mut log = OpenOptions::new()
        .append(true)
        .create(true)
        .open(&log_path)?;

    let mut make = Command::new("make");
    make.current_dir(&bb_root);
    make.stderr(Stdio::piped());
    make.stdout(Stdio::piped());
    make.arg("SEP=0");
    make.arg(&format!("ROOT={}", &mk_root));

    writeln!(&log, "\n# in {}, running: {}", &bb_root, command_str(&make))?;
    
    let make_out = make.output()    
        .expect("bb build failed to execute");
    log.write_all(&make_out.stdout)?;
    if !make_out.status.success() {
        panic!("bb build failed");
    }
	
    let bb_libdir = format!("{}/bb", &bindir);

    let out_dir = PathBuf::from(env::var("MK_CARGO_TARGET_DIR")
        .expect("MK_CARGO_TARGET_DIR undefined: build with make"));
    let deps_file_path = out_dir.join("deps.env");

    let deps_vars = [ [ "WD40_SEARCH_PATH", &bb_libdir ],
                      [ "WD40_LINK_LIB", "static=bb" ] ];

    let deps_vars_str = deps_vars.iter().map(|c| format!("{}={}\n", c[0], c[1])).collect::<Vec<String>>().join("");

    fs::write(&deps_file_path, deps_vars_str).expect("Unable to write deps.env file");

    println!("cargo:rustc-link-lib=bb");
    println!("cargo:rustc-link-search=native={}", &bb_libdir);

    println!("cargo:rerun-if-changed={}/libbb.a", &bb_libdir);

    Ok(())
}
