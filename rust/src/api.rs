use std::io::{BufReader, Cursor};

use anyhow::{Context, Result};
use once_cell::sync::OnceCell;

use crate::{joypad::JoypadKey, nes::Nes, rom::Rom};

static mut NES: OnceCell<Nes> = OnceCell::new();

pub fn load_rom(bytes: Vec<u8>) -> Result<()> {
    let mut reader = BufReader::new(Cursor::new(bytes));
    let rom = Rom::new(&mut reader)?;

    unsafe { NES.set(Nes::new(rom)?) };

    Ok(())
}

pub fn reset() -> Result<()> {
    unsafe {
        let nes = NES.get_mut().context("reset failed to get nes")?;
        nes.reset();
    }

    Ok(())
}

pub fn player1_keydown(key: JoypadKey) -> Result<()> {
    unsafe {
        let nes = NES.get_mut().context("p1 keydown failed to get nes")?;
        nes.joypad1.keydown(key);
    }
    Ok(())
}

pub fn player1_keyup(key: JoypadKey) -> Result<()> {
    unsafe {
        let nes = NES.get_mut().context("p1 keyup failed to get nes")?;
        nes.joypad1.keyup(key);
    }
    Ok(())
}

pub fn player2_keydown(key: JoypadKey) -> Result<()> {
    unsafe {
        let nes = NES.get_mut().context("p2 keydown failed to get nes")?;
        nes.joypad2.keydown(key);
    }
    Ok(())
}

pub fn player2_keyup(key: JoypadKey) -> Result<()> {
    unsafe {
        let nes = NES.get_mut().context("p2 keyup failed to get nes")?;
        nes.joypad2.keyup(key);
    }
    Ok(())
}

pub fn tick() -> Result<()> {
    unsafe {
        let nes = NES.get_mut().context("tick failed to get nes")?;
        nes.cpu.tick()?;
        nes.ppu.tick()?;
    }

    Ok(())
}

pub fn render() -> Result<Vec<u8>> {
    unsafe {
        let nes = NES.get_mut().context("render failed to get nes")?;
        for _ in 0..89342 {
            nes.tick().unwrap();
        }
        let result = nes.ppu.render();
        result
    }
}
