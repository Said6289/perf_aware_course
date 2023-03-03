@echo off
nasm -o main.obj -f win64 -g main.asm
"\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.34.31933\bin\HostX64\x64\link.exe" ^
	main.obj /debug /nologo /out:main.exe /subsystem:console libcmt.lib
