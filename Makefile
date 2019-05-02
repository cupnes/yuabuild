all: build/poiboot/poiboot.efi build/yuaos/kernel.bin build/yuaos/apps/serial_echoback/e.serial_echoback

PHONY += setup
setup: build

PHONY += deploy
deploy: build/fs/efi/boot/bootx64.efi build/fs/poiboot.conf build/fs/kernel.bin build/fs/fs.img

PHONY += run
run: deploy
	sudo chroot build qemu-system-x86_64 -m 4G -drive if=pflash,format=raw,readonly,file=/usr/share/OVMF/OVMF_CODE.fd -drive if=pflash,format=raw,file=/usr/share/OVMF/OVMF_VARS.fd -hda fat:fs -serial mon:stdio -nographic

PHONY += clean
clean:
	sudo chroot build make -C poiboot clean
	sudo chroot build make -C yuaos clean
	sudo chroot build make -C yuaos/apps/serial_echoback clean

# build
build:
	wget http://yuma.ohgami.jp/build.tar.xz
	wget http://yuma.ohgami.jp/build.tar.xz.sha256
	sha256sum -c build.tar.xz.sha256
	tar Jxf build.tar.xz
	cd build && git clone https://github.com/cupnes/poiboot.git
	cd build && git clone -b next https://github.com/cupnes/yuaos.git

# poiboot
build/fs/efi/boot/bootx64.efi: build/poiboot/poiboot.efi
	mkdir -p build/fs/efi/boot
	cp $< $@
build/poiboot/poiboot.efi:
	sudo chroot build make -C poiboot
build/fs/poiboot.conf:
	cp build/poiboot/poiboot_default.conf $@

# yuaos
build/fs/kernel.bin: build/yuaos/kernel.bin
	cp $< $@
build/yuaos/kernel.bin:
	sudo chroot build make -C yuaos
build/fs/fs.img: init
	build/yuaos/tools/create_fs.sh init
	cp fs.img $@
init: build/yuaos/apps/serial_echoback/e.serial_echoback
	cp $< $@
build/yuaos/apps/serial_echoback/e.serial_echoback:
	sudo chroot build make -C yuaos/apps/serial_echoback

.PHONY: $(PHONY)
