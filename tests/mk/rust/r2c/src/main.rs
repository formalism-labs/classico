use classico::wd40;

wd40::bind_this!("clib");

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::error::Error;

#[repr(C)]
pub struct Bar {
	flag: bool,
	text: String,
	maybe_text: Option<String>
}

type BarCallback = fn(*mut Bar);

#[allow(improper_ctypes)]
extern "C" {
    fn bar_c_operation(bar_callback: BarCallback, bar: *mut Bar);
}

#[no_mangle]
pub extern "C" fn get_bar_text(bar_ptr: *const Bar) -> *const c_char {
    unsafe {
        if bar_ptr.is_null() {
            return std::ptr::null();
        }
        let bar = &*bar_ptr;
        CString::new(bar.text.clone()).unwrap().into_raw()
    }
}

#[no_mangle]
pub extern "C" fn get_bar_maybe_text(bar_ptr: *const Bar) -> *const c_char {
    unsafe {
        if bar_ptr.is_null() {
            return std::ptr::null();
        }
        let bar = &*bar_ptr;
		match &bar.maybe_text {
			Some(text) => CString::new(text.clone()).unwrap().into_raw(),
			None => std::ptr::null(),
		}
    }
}

#[no_mangle]
pub extern "C" fn free_bar_text(text: *mut c_char) {
    unsafe {
        if !text.is_null() {
            let _ = CString::from_raw(text); // reclaim ownership and drop
        }
    }
}

fn bar_callback(bar_ptr: *mut Bar) {
    unsafe {
        println!("bar_callback called!");
        if bar_ptr.is_null() {
            return;
        }
        println!("bar_callback: bar is valid");
        let bar = &mut *bar_ptr;

        println!("Bar.flag: {}", bar.flag);
        println!("Bar.text: {}", bar.text);

        bar.flag = !bar.flag;
        bar.text.push_str(" (updated in Rust callback)");

        println!("Bar.text: {}", bar.text);
    }
}

fn main() -> Result<(), Box<dyn Error>> {
    let foo_name_cstr = CString::new("world")?;
    let foo_name_cstr_ptr: *const c_char = foo_name_cstr.as_ptr();
    let world: String;
    let foo: *mut Foo;
    unsafe {
        foo = clib_new_foo(foo_name_cstr_ptr, 17);
        let c_world: *const c_char = clib_foo_name(foo);
        if !c_world.is_null() {
            world = CStr::from_ptr(c_world).to_string_lossy().to_string();
        } else {
            world = String::new();
        }
    }
    println!("Hello, {}!", world);
    unsafe {
        clib_del_foo(foo);
    }

	let mut bar = Bar { flag: true, text: String::from("bar"), maybe_text: Some(String::from("bar")) };
    unsafe {
	    bar_c_operation(bar_callback, &mut bar);
    }

    Ok(())
}

