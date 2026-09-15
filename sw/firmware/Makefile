# Makefile for Live Watch Firmware (Targeting RISC-V rv32i)

# Toolchain (Requires riscv-gnu-toolchain)
CC = riscv64-unknown-elf-gcc
OBJCOPY = riscv64-unknown-elf-objcopy
OBJDUMP = riscv64-unknown-elf-objdump

# Compiler flags
CFLAGS = -march=rv32i -mabi=ilp32 -O2 -Wall -ffreestanding -nostartfiles -nostdlib

TARGET = demo
SRC = demo.c

all: $(TARGET).elf $(TARGET).bin $(TARGET).hex $(TARGET).dump

$(TARGET).elf: $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET).elf

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $(TARGET).elf $(TARGET).bin

$(TARGET).hex: $(TARGET).elf
	$(OBJCOPY) -O ihex $(TARGET).elf $(TARGET).hex

$(TARGET).dump: $(TARGET).elf
	$(OBJDUMP) -D $(TARGET).elf > $(TARGET).dump

clean:
	rm -f *.elf *.bin *.hex *.dump
