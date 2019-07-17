#!/bin/bash

echo "check prerequisites"

is_ubuntu="0"
is_ubuntu=`cat /etc/*release* | grep -i "ubuntu" | wc -l`
if [ "$is_ubuntu" != "0" ];
then
    is_ubuntu="1"
fi

libfabric_is_installed="0"
if [ "$is_ubuntu" == "1" ];
then
    libfabric_is_installed=`sudo apt list --installed | grep libfabric | wc -l`
else
    if sudo yum list installed libfabric > /dev/null 2>&1;
    then
        libfabric_is_installed="1"
    fi
fi

if [ "$libfabric_is_installed" == "0" ];
then
    echo "Install EFA Software components at first"
    exit 0
fi

tuning_file_url="https://software.intel.com/sites/default/files/managed/f2/65/tuning_skx_shm-ofi_2019u4_aws.zip"
tuning_file_name_zip="efa_tuning.zip"
tuning_file_name="efa_tuning.dat"

echo "1. installing IMPI 2019 U4"

if [ "$is_ubuntu" == "1" ];
then
    wget -O apt_key https://apt.repos.intel.com/2018/GPG-PUB-KEY-INTEL-PSXE-RUNTIME-2018
    sudo apt-key add apt_key
    sudo touch /etc/apt/sources.list.d/intel-psxe-runtime-2019.list
    echo "deb https://apt.repos.intel.com/2019 intel-psxe-runtime main" | sudo tee /etc/apt/sources.list.d/intel-psxe-runtime-2019.list
    sudo apt-get update
    sudo apt install aptitude -y
    sudo apt install unzip -y
    sudo aptitude install -y -o Aptitude::ProblemResolver::SolutionCost='100*canceled-actions,200*removals' intel-mpi-runtime=2019.4-243
    impi_install_path_pattern="/opt/intel/psxe_runtime/linux/mpi"
else
    sudo yum-config-manager --add-repo https://yum.repos.intel.com/mpi/setup/intel-mpi.repo
    sudo rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
    sudo yum install intel-mpi-2019.4-070 -y
    impi_install_path_pattern="/opt/intel/impi/*"
fi

impi_u4_install_path=`ls -d $impi_install_path_pattern | head -n 1`
tuning_dir="${impi_u4_install_path}/intel64/etc"

echo "2. downloading IMPI/EFA tuning file"
wget -O $tuning_file_name_zip $tuning_file_url
origin_tuning_file_name=`unzip -Z1 $tuning_file_name_zip | grep ".dat"`
efa_tuning_file_name="efa_tuning.dat"
unzip -o $tuning_file_name_zip
sudo cp $origin_tuning_file_name $tuning_dir/$efa_tuning_file_name

echo "3. patching mpivars.sh"
mpivars_path="${impi_u4_install_path}/intel64/bin/mpivars.sh"
pattern="I_MPI_ROOT="

sudo sed -i "/${pattern}/a if [ -z \"\${I_MPI_OFI_LIBRARY_INTERNAL}\" ]; then export I_MPI_OFI_LIBRARY_INTERNAL=0 ; fi" $mpivars_path
sudo sed -i "/${pattern}/a if [ -z \"\${MPIR_CVAR_CH4_OFI_ENABLE_ATOMICS}\" ]; then export MPIR_CVAR_CH4_OFI_ENABLE_ATOMICS=0 ; fi" $mpivars_path
sudo sed -i "/${pattern}/a if [ -z \"\${I_MPI_EXTRA_FILE_SYSTEM}\" ]; then export I_MPI_EXTRA_FILE_SYSTEM=1 ; fi" $mpivars_path
sudo sed -i "/${pattern}/a if [ -z \"\${ROMIO_FSTYPE_FORCE}\" ]; then export ROMIO_FSTYPE_FORCE=\"nfs:\" ; fi" $mpivars_path
sudo sed -i "/${pattern}/a if [ -z \"\${I_MPI_TUNING_BIN}\" ]; then export I_MPI_TUNING_BIN=${tuning_dir}/${efa_tuning_file_name} ; fi" $mpivars_path

if [ "$is_ubuntu" == "1" ];
then
    sudo sed -i "/${pattern}/a export LD_LIBRARY_PATH=/opt/amazon/efa/lib/:\${LD_LIBRARY_PATH}" $mpivars_path
else
	sudo sed -i "/${pattern}/a export LD_LIBRARY_PATH=/opt/amazon/efa/lib64/:\${LD_LIBRARY_PATH}" $mpivars_path
fi

echo "4. cleaning up temporary files"
rm checksum.txt
rm $tuning_file_name_zip
rm $origin_tuning_file_name

echo "installation completed"
