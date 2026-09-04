All game code is in Index.asm
assembly: NASM x86 16bit
note: there is no kernel, operating system
assembled:

cd /[file path]
nasm -f bin Index.asm -o Index.bin
sudo qemu-system-i386 -drive file=[filepath]/Index.bin,format=raw

Pardon me for not translating comments

