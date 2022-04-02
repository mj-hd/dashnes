use std::sync::mpsc::channel;

use anyhow::Result;

use crate::{
    apu::Apu,
    bus::{CpuBus, CpuBusEvent, PpuBus, PpuBusEvent},
    cpu::Cpu,
    joypad::{Joypad, JoypadKey},
    mmc::new_mmc,
    ppu::Ppu,
    rom::Rom,
    utils::Shared,
};

pub struct Nes {
    pub cpu: Shared<Cpu>,
    pub ppu: Shared<Ppu>,
    pub apu: Shared<Apu>,
    pub joypad1: Shared<Joypad>,
    pub joypad2: Shared<Joypad>,
}

impl Nes {
    pub fn new(rom: Rom) -> Result<Self> {
        let mmc = Shared::new(new_mmc(rom)?);
        let apu = Shared::new(Apu::new());

        let (ppu_bus_sender, ppu_bus_event) = channel::<PpuBusEvent>();
        let (cpu_bus_sender, cpu_bus_event) = channel::<CpuBusEvent>();

        let ppu_bus = PpuBus::new(Shared::clone(&mmc), ppu_bus_event, cpu_bus_sender);
        let ppu = Shared::new(Ppu::new(ppu_bus));

        let joypad1 = Shared::new(Joypad::new());
        let joypad2 = Shared::new(Joypad::new());

        let cpu_bus = CpuBus::new(
            Shared::clone(&mmc),
            Shared::clone(&ppu),
            Shared::clone(&apu),
            Shared::clone(&joypad1),
            Shared::clone(&joypad2),
            cpu_bus_event,
            ppu_bus_sender,
        );
        let cpu = Shared::new(Cpu::new(cpu_bus));

        Ok(Self {
            cpu,
            ppu,
            apu,
            joypad1,
            joypad2,
        })
    }

    pub fn reset(&mut self) -> Result<()> {
        self.cpu.reset()?;

        Ok(())
    }

    pub fn player1_keydown(&mut self, key: JoypadKey) {
        self.joypad1.keydown(key);
    }

    pub fn player1_keyup(&mut self, key: JoypadKey) {
        self.joypad1.keyup(key);
    }

    pub fn player2_keydown(&mut self, key: JoypadKey) {
        self.joypad2.keydown(key);
    }

    pub fn player2_keyup(&mut self, key: JoypadKey) {
        self.joypad2.keyup(key);
    }

    pub fn tick(&mut self) -> Result<()> {
        self.cpu.tick()?;
        self.ppu.tick()?;

        Ok(())
    }

    pub fn render(&mut self) -> Result<Vec<u8>> {
        self.ppu.render()
    }
}
