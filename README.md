# LidMotion

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

LidMotion brings beautiful, native closing effects to your MacBook. Experience iconic animations like the Duo effect, Expansion, Fade, and CRT—rebuilt perfectly for modern macOS. 

LidMotion is incredibly lightweight, runs silently in your menu bar, and requires zero bloated windows or dock icons. Just raw, native performance.

## Features
- **The Iconic Duo Effect:** Inspired by classic animations, seamlessly adapted for macOS.
- **Multiple Animations:** Choose from Expansion, Fade, CRT, and more.
- **Native & Lightweight:** Written in pure Swift, optimized for minimal battery and CPU usage.
- **Menu Bar Integration:** Resides quietly in your menu bar for quick access to settings.

## System Requirements
- **macOS 14.0 or later**
- Supports both Apple Silicon (M1/M2/M3) and Intel Macs.

## Compilation & Installation
As an open-source project, you can easily build LidMotion from source:
1. Clone this repository: `git clone https://github.com/tommasogodi06-crypto/LidMotion.git`
2. Navigate to the source folder and open the project in Xcode (or use the provided build scripts).
3. Build and run the `LidMotion` target.
*(Note: On first launch, macOS will require you to grant Accessibility and Screen Recording permissions to enable the window effects).*

## Project Structure
- `Sorgenti/`: Contains the Swift source code, build scripts (`build.sh`, `build_dmg.sh`), and application logic.
- `Website/`: The complete source code for the LidMotion landing page.

## Contributing
Contributions are welcome! If you have ideas for new closing effects, bug fixes, or performance improvements, feel free to open an issue or submit a pull request.

## License
LidMotion is distributed under the [MIT License](LICENSE). 
See the `LICENSE` file for more information. Copyright (c) 2026 Tommaso Godi.
