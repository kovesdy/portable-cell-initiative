#Instructions for installing beamlink software package on Odroid XU-4:
#Run these commands as sudo
apt-get update
apt-get install -y git
mkdir ~/code
cd ~/code
git clone https://github.com/Ironarcher/portable-cell-initiative.git
cd portable-cell-initiative
chmod u+x software/yatebts_setup-1.sh
chmod u+x software/yatebts_setup-2.sh
software/yatebts_setup-1.sh
