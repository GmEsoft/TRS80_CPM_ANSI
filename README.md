# ANSI Driver for Montezuma Micro CP/M

[![Version](https://img.shields.io/badge/version-0.2-blue.svg)](https://github.com/GmEsoft/TRS80_CPM_ANSI)
[![License: MIT](https://img.shields.io/badge/License-GPL3-yellow.svg)](https://opensource.org/license/gpl-3.0)

An ANSI escape sequence driver for the Montezuma Micro CP/M operating system running on the TRS-80 Model 4 hardware. This driver enhances the system's video and keyboard capabilities by providing support for ANSI escape codes, enabling advanced text formatting, cursor control, and screen manipulation.

## Features

- **ANSI Escape Sequence Support**: Implements a wide range of ANSI escape sequences for cursor movement, screen clearing, and text attributes.
- **Keyboard Remapping**: Provides better ANSI compatibility by remapping certain keys:
  - `[Clear]` → BkSp (0x08)
  - `[Break]` → ESC (0x1B)
  - `Shift-[Clear]` → Ctrl-X (0x18): Clear the command line
  - `Shift-[Up]` → ESC (0x1B)
  - `Shift-[Down]` → Ctrl-Z (0x1A)
  - `Shift-[Left]` → BkSp (0x08)
  - `Shift-[Right]` → Tab (0x09)
  - Arrow keys → Corresponding ANSI escape sequences (e.g., `[Left]` sends `ESC'[D'`)
- **BIOS Integration**: Installs directly into the system BIOS, intercepting video output and keyboard input calls.
- **Extended Memory Usage**: Utilizes the extended memory area (EXMEM) for driver code and data storage.
- **CP/M Drive M: Management**: Safely disables CP/M Drive M: during installation to prevent conflicts.

## Supported ANSI Escape Sequences

### Cursor Movement
- `ESC[<n>A` - Move cursor up n lines
- `ESC[<n>B` - Move cursor down n lines
- `ESC[<n>C` - Move cursor right n columns
- `ESC[<n>D` - Move cursor left n columns
- `ESC[<x>;<y>H` or `ESC[<x>;<y>f` - Move cursor to position (x,y)

### Screen Control
- `ESC[2J` - Clear entire screen
- `ESC[J` - Clear from cursor to end of screen
- `ESC[K` - Clear from cursor to end of line
- `ESC[L` - Insert line
- `ESC[M` - Delete line

### Text Attributes
- `ESC[<attr>m` - Set text attributes (supports reverse video on/off)

### Cursor Control
- `ESC[25h` - Show cursor
- `ESC[25l` - Hide cursor

## Requirements

- TRS-80 Model 4 with Montezuma Micro CP/M, BIOS versions 2.22 and higher
- 128K system (required for extended memory support)
- ZMAC assembler (installer included in the repository)

## Installation

1. **Download the Repository**:
   ```ps
   git clone https://github.com/GmEsoft/TRS80_CPM_ANSI.git
   cd TRS80_CPM_ANSI
   ```

2. **Assemble the Driver**:
   - On Windows: Run `ANSI\a_ansi.bat`
   - On Linux/Unix: Download the appropriate cross-assembler and assemble manually with it

3. **Install the Driver**:
   - Ensure CP/M Drive M: is not in use
   - Run the assembled `ANSI.COM` file
   - The driver will install itself into the BIOS and extended memory

4. **Verification**:
   - The installation will display a success message if completed properly
   - Test ANSI compatibility with applications that use escape sequences

## Building from Source

The driver is written in Z80 assembly language and requires the ZMAC assembler.

### Prerequisites
- ZMAC assembler (automatically downloaded by `getzmac.sh` on first build)

### Build Steps
1. Navigate to the ANSI directory
2. Run the build script:
   - Windows: `a_ansi.bat`
   - The script will download ZMAC if not present, assemble the code, and generate `ANSI.COM`

### Manual Build
```ps
zmac --mras ansi.asm -o ansi.cim -o ansi.lst -c
move -y ansi.cim ansi.com
```

## Usage

Once installed, the ANSI driver operates transparently. Applications that output ANSI escape sequences will automatically benefit from enhanced display capabilities. The keyboard remappings provide better compatibility with ANSI-aware software.

### Testing
You can test the driver by running ANSI-compatible applications or by manually sending escape sequences to verify cursor movement and screen control.

This ANSI driver has been successfully tested with the following programs:
- Catchum and Ladder: select configuration 10 `Heathkit/Zenith H19 (ANSI)` - don't use the arrow keys for direction
- Gorilla: works with modes:
  - `2) VT100     (B/W)`
  - `3) ANSI      (Color)`
- [TE_ANSI from Miguel Garcia](https://github.com/MiguelVis/te): must be patched for 24 screen lines instead of 25. Use a binary editor, search for `TE_CONF` and replace the first occurrence of byte `19` (followed by `50`) with `18`
- Rogue (from [Z80pack](https://www.icl1900.co.uk/unix4fun/z80pack)): run `ROGUE-VT.COM`

## Technical Details

- **Memory Usage**: The driver resides in EXMEM page 1 (0x0000-0x7FFF when mapped)
- **BIOS Patching**: Modifies video output and keyboard input vectors in the BIOS
- **Compatibility**: Designed specifically for Montezuma Micro CP/M on TRS-80 Model 4

## Troubleshooting

- **"Drive M: in use"**: Ensure no applications are using CP/M Drive M: before installation
- **"Not a 128K system"**: The driver requires extended memory support
- **"Already installed"**: The driver can only be installed once; reboot to reinstall

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**GmEsoft**
Copyright (c) 2026 GmEsoft

## Version History

- **v0.2** (March 2026) - Initial release with full ANSI escape sequence support
