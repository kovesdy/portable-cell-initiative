#Instructions for installing beamlink software package on Odroid XU-4:
#Run these commands as sudo
apt-get update
apt-get install -y git
git clone https://github.com/Ironarcher/portable-cell-initiative.git pci
cd pci
chmod u+x yatebts_setup-1.sh
chmod u+x yatebts_setup-2.sh
./yatebts_setup-1.sh