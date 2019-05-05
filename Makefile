all: build/poiboot/poiboot.efi build/yuakernel/kernel.bin build/yuaapps/serial_echoback/e.serial_echoback

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
	sudo chroot build make -C yuakernel clean
	sudo chroot build make -C yuaapps/serial_echoback clean

# build
build:
	wget http://yuma.ohgami.jp/build.tar.xz
	wget http://yuma.ohgami.jp/build.tar.xz.sha256
	sha256sum -c build.tar.xz.sha256
	sudo tar Jxf build.tar.xz
	cd build && git clone https://github.com/cupnes/poiboot.git
	cd build && git clone https://github.com/cupnes/yuakernel.git
	cd build && git clone https://github.com/cupnes/yuaapps.git

# poiboot
build/fs/efi/boot/bootx64.efi: build/poiboot/poiboot.efi
	mkdir -p build/fs/efi/boot
	cp $< $@
build/poiboot/poiboot.efi:
	cd build/poiboot && git checkout master && git pull
	sudo chroot build make -C poiboot
build/fs/poiboot.conf:
	cp build/poiboot/poiboot_default.conf $@

# yuakernel
build/fs/kernel.bin: build/yuakernel/kernel.bin
	cp $< $@
build/yuakernel/kernel.bin:
	cd build/yuakernel && git checkout master && git pull
	sudo chroot build make -C yuakernel

# yuaapps
build/fs/fs.img: init
	build/yuaapps/tools/create_fs.sh init
	cp fs.img $@
init: build/yuaapps/serial_echoback/e.serial_echoback
	cp $< $@
build/yuaapps/serial_echoback/e.serial_echoback:
	cd build/yuaapps && git checkout master && git pull
	sudo chroot build make -C yuaapps/serial_echoback

.PHONY: $(PHONY)
