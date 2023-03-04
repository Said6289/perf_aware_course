@echo off
nasm -g -o main.obj -f win64 main.asm
"\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.34.31933\bin\HostX64\x64\link.exe" ^
	main.obj /nologo /debug /out:main.exe /subsystem:console msvcrt.lib ucrt.lib legacy_stdio_definitions.lib
