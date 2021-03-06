#![allow(
    non_camel_case_types,
    unused,
    clippy::redundant_closure,
    clippy::useless_conversion,
    clippy::unit_arg,
    non_snake_case
)]
// AUTO GENERATED FILE, DO NOT EDIT.
// Generated by `flutter_rust_bridge`.

use crate::api::*;
use flutter_rust_bridge::*;

// Section: imports

use crate::joypad::JoypadKey;

// Section: wire functions

#[no_mangle]
pub extern "C" fn wire_load_rom(port_: i64, bytes: *mut wire_uint_8_list) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "load_rom",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_bytes = bytes.wire2api();
            move |task_callback| load_rom(api_bytes)
        },
    )
}

#[no_mangle]
pub extern "C" fn wire_reset(port_: i64) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "reset",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || move |task_callback| reset(),
    )
}

#[no_mangle]
pub extern "C" fn wire_player1_keydown(port_: i64, key: i32) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "player1_keydown",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_key = key.wire2api();
            move |task_callback| player1_keydown(api_key)
        },
    )
}

#[no_mangle]
pub extern "C" fn wire_player1_keyup(port_: i64, key: i32) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "player1_keyup",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_key = key.wire2api();
            move |task_callback| player1_keyup(api_key)
        },
    )
}

#[no_mangle]
pub extern "C" fn wire_player2_keydown(port_: i64, key: i32) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "player2_keydown",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_key = key.wire2api();
            move |task_callback| player2_keydown(api_key)
        },
    )
}

#[no_mangle]
pub extern "C" fn wire_player2_keyup(port_: i64, key: i32) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "player2_keyup",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_key = key.wire2api();
            move |task_callback| player2_keyup(api_key)
        },
    )
}

#[no_mangle]
pub extern "C" fn wire_tick(port_: i64) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "tick",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || move |task_callback| tick(),
    )
}

#[no_mangle]
pub extern "C" fn wire_render(port_: i64) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "render",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || move |task_callback| render(),
    )
}

// Section: wire structs

#[repr(C)]
#[derive(Clone)]
pub struct wire_uint_8_list {
    ptr: *mut u8,
    len: i32,
}

// Section: wrapper structs

// Section: static checks

// Section: allocate functions

#[no_mangle]
pub extern "C" fn new_uint_8_list(len: i32) -> *mut wire_uint_8_list {
    let ans = wire_uint_8_list {
        ptr: support::new_leak_vec_ptr(Default::default(), len),
        len,
    };
    support::new_leak_box_ptr(ans)
}

// Section: impl Wire2Api

pub trait Wire2Api<T> {
    fn wire2api(self) -> T;
}

impl<T, S> Wire2Api<Option<T>> for *mut S
where
    *mut S: Wire2Api<T>,
{
    fn wire2api(self) -> Option<T> {
        if self.is_null() {
            None
        } else {
            Some(self.wire2api())
        }
    }
}

impl Wire2Api<JoypadKey> for i32 {
    fn wire2api(self) -> JoypadKey {
        match self {
            0 => JoypadKey::A,
            1 => JoypadKey::B,
            2 => JoypadKey::Select,
            3 => JoypadKey::Start,
            4 => JoypadKey::Up,
            5 => JoypadKey::Down,
            6 => JoypadKey::Left,
            7 => JoypadKey::Right,
            _ => unreachable!("Invalid variant for JoypadKey: {}", self),
        }
    }
}

impl Wire2Api<u8> for u8 {
    fn wire2api(self) -> u8 {
        self
    }
}

impl Wire2Api<Vec<u8>> for *mut wire_uint_8_list {
    fn wire2api(self) -> Vec<u8> {
        unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        }
    }
}

// Section: impl NewWithNullPtr

pub trait NewWithNullPtr {
    fn new_with_null_ptr() -> Self;
}

impl<T> NewWithNullPtr for *mut T {
    fn new_with_null_ptr() -> Self {
        std::ptr::null_mut()
    }
}

// Section: impl IntoDart

// Section: executor

support::lazy_static! {
    pub static ref FLUTTER_RUST_BRIDGE_HANDLER: support::DefaultHandler = Default::default();
}

// Section: sync execution mode utility

#[no_mangle]
pub extern "C" fn free_WireSyncReturnStruct(val: support::WireSyncReturnStruct) {
    unsafe {
        let _ = support::vec_from_leak_ptr(val.ptr, val.len);
    }
}
