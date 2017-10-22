#Remember to run with sudo
apt-get update
apt-get install -y git
git clone https://github.com/Ironarcher/portable-cell-initiative.git pci
cd pci
chmod u+x setup.sh
./setup.sh