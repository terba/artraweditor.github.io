# Ubuntu build recipe for **ART**
*(contributed by Danny Heijl)*

May 21 2023: Updated for ART 1.20 and exiv2 main branch:

- new exiv2 dependencies: libinih-dev libbrotli-dev

## Prerequisites

These instructions were tested on Ubuntu 20.04 and 22.04 (Linux Mint 20 and 21), so should work on any Debian based distro.
They assume you want to use (cloned from GitHub) the latest and greatest versions of all dependencies. 
You could of course choose to download and use the latest "stable" released source versions instead.

- install the necessary development packages:

```bash
sudo apt install autoconf libtool
sudo apt install git build-essential cmake curl pkg-config libgtk-3-dev libgtkmm-3.0-dev librsvg2-dev liblcms2-dev libfftw3-dev libiptcdata0-dev libtiff5-dev libcanberra-gtk3-dev libinih-dev libbrotli-dev
```

- If you want to use the latest gcc, you can install gcc-12 and g++12 first before building anything, as per <https://www.linuxcapable.com/install-gcc-compiler-build-essential-on-ubuntu-2>:

```bash
sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
sudo apt update && sudo apt upgrade
sudo apt install gcc-12 g++-12
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100 --slave /usr/bin/g++ g++ /usr/bin/g++-12 --slave /usr/bin/gcov gcov /usr/bin/gcov-12
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 60 --slave /usr/bin/g++ g++ /usr/bin/g++-11 --slave /usr/bin/gcov gcov /usr/bin/gcov-11
gcc –version
sudo update-alternatives --config gcc
```

- For Canon Cr3 suport you need a recent **LibRaw** build, this is how you build the current LibRaw version from Github:
  - clone and install latest libraw from github
  - cd to the cloned LibRaw folder and build and install LibRaw:

```bash
autoreconf --install
./configure
sudo make install
sudo ldconfig
```

- You’ll want the latest **liblensfun** too:
  - clone it from Github, cd to the cloned lensfun folder and build it:

```bash
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release ../
make
sudo make install
sudo ldconfig
```

- As of ART 1.20 you can use the exiv2 main (1.00.xx) branch or the latest release (0.28.x) branch, instead of exiv2 0.27.maintenance branch. To get Canon CR3 support from exiv2 you have to use a **recent exiv2** version (without a recent exiv2 library linked in you would have to install **exiftool** for Canon CR3 support: `sudo apt install exiftool`).

  - if you have an outdated exiv2 package installed, remove it now: `sudo apt remove exiv2 libexiv2-dev`
  - since 0.28.x the tests are no longer built by default, so you have to skip the `ctest` step
  - clone and install exiv2 (main branch or 0.28.x) from github, and cd to to the cloned exiv2 folder:

```bash
sudo rm -rf build
mkdir -p build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DEXIV2_ENABLE_BMFF=On 
cmake --build build
sudo cmake --install build
sudo ldconfig
```

- ART needs MIMALLOC, so clone it from Github (<https://github.com/microsoft/mimalloc>) and build it:

```bash
mkdir -p out/release
cd out/release
cmake ../..
make
sudo make install
sudo ldconfig
```

- Recent versions of ART include **OpenColorIO**, so clone the GitHub repo and build it:

```bash
mkdir /tmp/ociobuild
cd /tmp/ociobuild
cmake -DOCIO_INSTALL_EXT_PACKAGES=ALL -DOCIO_BUILD_PYTHON=OFF ~/Documenten/GitHub/OpenColorIO/ *(path to OpenColorIO clone)*
make -j 4
sudo make install
```

- Similarly, to use **CTL scripts**, the CTL interpreter must be built and installed:

```bash
sudo apt install libilmbase-dev libopenexr-dev
git clone https://github.com/ampas/CTL.git
cd CTL
mkdir build && cd build
cmake ..
make
sudo make install
```

## Building **ART**

- download the build-art script (raw) from <https://raw.githubusercontent.com/artraweditor/ART/refs/heads/master/tools/build-art>

- you may have to remove an older build first: `rm -r programs/art programs/code-art`
- Make build-art executable `(chmod +x)` and execute it:

```bash
chmod +x ./build-art
./build-art
```

This will install ART in `programs/art`.
  
Rerunning the build-art script will update the source code from the git repository and rebuild ART.
If Alberto changes something in the build options you may have to redownload build-art and reapply any needed changes to the build-art script.

- To get the latest liblensfun data just run:

```bash
sudo lensfun-update-data
```
