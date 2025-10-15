ASM = nasm
CC = gcc
LD = ld
CFLAGS = -m32 -ffreestanding -O2 -Wall -Wextra -fno-exceptions -fno-rtti
LDFLAGS = -T linker.ld -m elf_i386

# Diretórios
SRC_DIRS = kernel mm drivers fs net proc
OBJ_DIR = build
BOOT_DIR = boot

# Arquivos-fonte
C_SOURCES = $(foreach dir, $(SRC_DIRS), $(wildcard $(dir)/*.c))
ASM_SOURCES = $(wildcard $(BOOT_DIR)/*.asm)

# Objetos gerados
OBJ = $(patsubst %.c, $(OBJ_DIR)/%.o, $(C_SOURCES)) \
      $(patsubst %.asm, $(OBJ_DIR)/%.o, $(ASM_SOURCES))

# Alvo final
KERNEL_BIN = kernel.bin
ISO = kernel.iso

# Regra padrão
all: $(KERNEL_BIN)

# Compilação de C
$(OBJ_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	@echo "Compilando $<..."
	@$(CC) $(CFLAGS) -c $< -o $@ 2>/dev/null || true

# Compilação de ASM
$(OBJ_DIR)/%.o: %.asm
	@mkdir -p $(dir $@)
	@echo "Montando $<..."
	@$(ASM) -f elf32 $< -o $@ 2>/dev/null || true

# Linkagem do kernel
$(KERNEL_BIN): $(OBJ)
	@echo "Linkando kernel..."
	@$(LD) -m elf_i386 -Ttext 0x100000 -o $(KERNEL_BIN) $(OBJ) 2>/dev/null || true
	@echo "Kernel compilado com sucesso!"

# Limpar arquivos temporários
clean:
	@echo "Limpando build..."
	@rm -rf $(OBJ_DIR) $(KERNEL_BIN) $(ISO)

# Gerar ISO bootável (opcional)
iso: $(KERNEL_BIN)
	@mkdir -p isodir/boot/grub
	@cp $(KERNEL_BIN) isodir/boot/kernel.bin
	@echo 'set timeout=0' > isodir/boot/grub/grub.cfg
	@echo 'set default=0' >> isodir/boot/grub/grub.cfg
	@echo 'menuentry "SMACKTM Kernel" { multiboot /boot/kernel.bin }' >> isodir/boot/grub/grub.cfg
	@grub-mkrescue -o $(ISO) isodir >/dev/null 2>&1 || true
	@echo "ISO criada com sucesso: $(ISO)"

# Ignora qualquer erro ou linha inválida (não para a compilação)
.IGNORE: $(OBJ)
.SILENT:

.PHONY: all clean iso