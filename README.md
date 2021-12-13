# Alice xrootd docker builder container
A specialized container that builds a debian package for the xrootd services running at GSI.

## Reasons for this package builder container
To run services for the ALICE grid, another plug-in needs to be available to be used by xrootd.
### The Auth Plug-in
This plug-in in general is libXrdAliceTokenAcc.so. It is built by the xrd3-installer script. 
This script compiles xrootd, libtokenauthz and libXrdAliceTokenAcc.
XRootD is the middleware service running at GSI, which allows the rest of the ALICE grid access to data stored on the GSI storage system.
libtokenauthz is an authentication and authorization library used by libXrdAliceTokenAcc.
libXrdAliceTokenAcc is the plug-in used by xrootd, which makes use of the methods given by libtokenauthz.

### Why we do more than use the xrd-installer.
The xrd-installer itself installs all the software necessary to run an xrootd grid-service for ALICE.
At GSI, there are additional requirements: 
Users working on the data locally want to see human readable names (LFN) instead of the physical filename.
The ALICE catalogue allows to get the LFN from a PFN, but that requires using the catalogue.
Instead, the libXrdAliceTokenAcc plug-in is extended by another functionality.
When files are written, a symlink to the physical file is created in another directory on the filesystem.
This results in a human readable structure of the data, which then allows access to the data without contacting a catalogue service.
Furthermore, the underlying filesystem is Lustre, a distributed filesystem. For ALICE, the used space and available space need to be reported.
For this, an XRootD plug-in was developed and can be found here: https://github.com/jknedlik/XrdLustreOssWrapper
This plug-in makes use of Lustre functionality for space and quota reporting.

### The build workflow
We build a custom version of the XrdAliceTokenAcc plug-in.
original found here: https://github.com/cern-eos/xrootd-alicetokenacc/tree/xrootd4
Our version found here:  https://git.gsi.de/j.knedlik/xrootd-alicetokenacc
First, we install all required dependencies for the software we build.
That also includes compiling lustre, as we need it for the XrdLustreOssWrapper plug-in.
After installing the normal ALICE required software, we replace the xrootd-alicetokenacc sources with our custom sources.
Afterwards, we simply recompile and reinstall the plug-in.
Then, the XrdLustreOssWrapper is compiled.
We also install the mlsensor software for ALICE monitoring into the package.
Afterwards, everything get packaged into a debian package, which get written into the build folder.
