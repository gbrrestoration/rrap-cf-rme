# Reef Mod Engine (RME)

#### Docs
There are docs inside the rme ./docs folder.



### Notes

#### Notes on RME installation  
Notes on RME installation as following seciton 3.2 Installing under Linux (experimental) in rme_matlab_api_guide.pdf.  
Unzipping the script, setting its permissions and running it produces the following error, even if run with sudo or as root:
```
root@laz-dev:/home/pet252/repos/rrap-cf-rme/rme# ./rme_ml_installer_rocky_8_6_x86_64_2025_09_03.bin
Verifying archive integrity...  100%   All good.
Uncompressing RME API (Linux) 1.0.44  100%  
./rme_ml_installer_rocky_8_6_x86_64_2025_09_03.bin: 1: eval: ./install_script.sh: Permission denied
```