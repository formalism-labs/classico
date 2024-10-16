include!(concat!(env!("OUT_DIR"), "/clib.rs"));

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::error::Error;

fn main() -> Result<(), Box<dyn Error>> {
    let cstr = CString::new("world")?;
    let cstr_ptr: *const c_char = cstr.as_ptr();
    let foo: *mut Foo;
    let f_word: *const c_char;
    let world: String;
    unsafe {
        foo = clib_new(cstr_ptr, 17);
        f_word = clib_foo_name(foo);
        if !f_word.is_null() {
            world = CStr::from_ptr(f_word).to_string_lossy().to_string();
        } else {
            world = String::new();
        }
    }
    println!("Hello, {}!", world);
    unsafe {
        clib_del(foo);
    }

    Ok(())
}
