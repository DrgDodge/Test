#!/bin/bash

# !
# !!
# !!! This script is for Gentoo Linux only! It will not work for any other system!
# !!
# !

# Credits to MentalOutlaw for example and inspiration. This is my personal virsion as well as an update
# MentalOutlaw's github repo: https://github.com/Mentaloutlaw/deploygentoo/

# just colors used in the script (ignore)
LIGHTGREEN='\033[1;32m'
LIGHTRED='\033[1;91m'
WHITE='\033[1;97m'
MAGENTA='\033[1;35m'
CYAN='\033[1;96m'

printf ${MAGENTA}

# exit setup directory
script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# get disk info
fdisk -l >> $script_dir/devices
# get network info
ifconfig -s >> $script_dir/nw_devices

# pass network info
cut -d ' ' -f1 $script_dir/nw_devices >> $script_dir/network_devices
rm -rf $script_dir/nw_devices
sed -e "s/lo//g" -i $script_dir/network_devices
sed -e "s/Iface//g" -i $script_dir/network_devices
sed '/^$/d' $script_dir/network_devices

# pass disk info
sed -e '\#Disk /dev/ram#,+5d' -i $script_dir/devices
sed -e '\#Disk /dev/loop#,+5d' -i $script_dir/devices

# show current disk configuration to the user
cat $script_dir/devices

errorMessage() {
    printf ${LIGHTRED}"$1\n"
    sleep 5
    clear
}

# start device configuration
deviceConfiguration() {
    printf ${CYAN}"Enter the device name you want to install gentoo on (ex, sda for /dev/sda)\n> ${WHITE}" ${CYAN}
    read disk
    disk="${disk,,}"
    partition_count="$(grep -o $disk $script_dir/devices | wc -l)"
    disk_chk=("/dev/${disk}")
    
    # start messing with drives
    if grep "$disk_chk" $script_dir/devices; then

        chooseBootMode() {
            printf ${CYAN}"Do you have EFI/UEFI mode or BIOS/Legacy mode active? For EFI/UEFI mode type \"efi\" or for BIOS/Legacy mode type \"bios\".\n${LIGHTRED}If you don't know the answer it is recommended to choose BIOS/Legacy mode (bios)\n${CYAN}> ${WHITE}"
            read boot_mode
            printf ${MAGENTA}
            
            # choose bios
            if [ "$boot_mode" = "efi" ]; then
                efiDiskSetup() {

                    printf ${CYAN}"Would you like to proceed with the auto setup for ${disk_chk}? \n${MAGENTA}This will create a GPT partition scheme where:${CYAN}\n${disk_chk}1 = 256M EFI System\n${disk_chk}2 = 4G Linux swap\n${disk_chk}3 = Linux filesystem \n\nEnter y to continue with auto setup or n to configure your own partitions \n> ${WHITE}" ${CYAN}    
                    read auto_prov_ans

                    # auto made partitions
                    if [ "$auto_prov_ans" = "y" ]; then
                        wipefs -a $disk_chk
                        parted -a optimal $disk_chk --script mklabel gpt
                        parted $disk_chk --script mkpart primary 0% 257MiB
                        parted $disk_chk --script name 1 boot
                        parted $disk_chk --script mkpart primary 257MiB 4353MiB
                        parted $disk_chk --script name 2 swap
                        parted $disk_chk --script mkpart primary 4353MiB 100%
                        parted $disk_chk --script name 3 root
                        parted $disk_chk --script set 1 boot on
                        part_1=("${disk_chk}1")    wipefs -a $disk_chk
                        parted -a optimal $disk_chk --script mklabel gpt
                        parted $disk_chk --script mkpart primary 0% 257MiB
                        parted $disk_chk --script name 1 boot
                        parted $disk_chk --script mkpart primary 257MiB 4353MiB
                        parted $disk_chk --script name 2 swap
                        parted $disk_chk --script mkpart primary 4353MiB 100%
                        parted $disk_chk --script name 3 root
                        parted $disk_chk --script set 1 boot on
                        part_1=("${disk_chk}1")
                        part_2=("${disk_chk}2")
                        part_3=("${disk_chk}3")
                        mkfs.fat -F 32 $part_1
                        mkfs.ext4 $part_3
                        mkswap $part_2
                        swapon $part_2
                        rm -rf $script_dir/devices
                        clear
                        sleep 1

                    elif [ "$auto_prov_ans" = "n" ]; then
                        printf ${CYAN}"Here you can choose between 2 setups, DIY(Do It Yourself) with \"DIY\" or guided with \"guided\". \n> ${WHITE}"
                        read auto_prov_ans_n_option
                         
                        showPartitions() {
                            printf ${MAGENTA}"Ok, so now we have:"
                            printf ${CYAN}"${$disk_chk}1 - 256M - boot"
                            printf ${CYAN}"${$disk_chk}2 - 4G - swap"
                            printf ${CYAN}"${$disk_chk}3 - $(( $(( $(lsblk -b | grep -m1 sda | awk '{ print $4 }') - (1024 * 4 * 1048576) - (256 * 1048576) )) / 1073741824 )) - root"
                        }

                        # if [ "$auto_prov_ans_n_option" = "DIY" ]; then

                        #     DIY() {

                        #         printf ${MAGENTA}"These are your partitions now:\n\n"${CYAN}
                        #         cat devices
                        #         printf ${MAGENTA}"\nWhat do you want to do now?\n${CYAN}1) ${LIGHTRED}REMOVE ALL PARTITIONS${CYAN}\n2) ${WHITE}Delete 1 partition${CYAN}\n3) ${WHITE}Create 1 partition${CYAN}\n4) ${WHITE}Change partition type\n${CYAN}> ${WHITE}"
                                
                        #         read DIY_option

                        #         if [ "$DIY_option" = '1' ]; then 
                        #             printf ${LIGHTRED}"ARE YOU SURE DO YOU WANT TO REMOVE ALL PARTITIONS?\n${CYAN}> ${WHITE}"                                
                        #             read REMOVE_ALL_PARTITIONS_answer

                        #             if [ "$REMOVE_ALL_PARTITIONS_answer" = 'y' ]; then
                                       
                        #                 wipefs -a $disk_chk
                        #                 parted -a optimal $disk_chk --script mklabel gpt

                                        
                                        
                        #                 cat devices
                        #             fi


                        #         elif [ "$DIY_option" = '2' ]; then 
                        #             printf ""


                        #         elif [ "$DIY_option" = '3' ]; then

                        #             DIY_option3() {

                        #                 printf ${CYAN}"Partition number ($(lsblk | grep $disk -c )-128, default $(lsblk | grep $disk -c)): ${WHITE}"
                        #                 read DIY_option_3_partition_number

                        #                 if [ "$DIY_option_3_partition_number" -lt 128 && "$DIY_option_3_partition_number" -ge "$(lsblk | grep $disk -c)" ]; then

                        #                     printf ${CYAN}"How much space do you want to give to this partition?"



                        #                 else
                        #                     errorMessage "$DIY_option_3_partition_number is not in range."
                        #                     DIY_option3

                        #                 fi

                        #             }
                        #             DIY_option3

                        #         else 
                        #             errorMessage "$DIY_option is not a valid option!"


                        #         fi
                            
                        #     }
                        #     DIY

                        #el
                        if [ "$auto_prov_ans_n_option" = "guided" ]; then
                            guidedDisks() {

                                printf ${CYAN}"Welcome to the guided partition setup! Let's go to the partitions \nHere we will need at least 2 partitions, one for boot and the other one for root!\n\nYou can also opt for a swap partition (swap partitions are like an extention of RAM and substitutes it when RAM is full). It is recommended to have at least 2G of swap.\n\nDo you also want a swap partition (y/n)?\n> ${WHITE}"
                                read swap_answer

                                if [ "$swap_answer" = 'y' ]; then
                                    printf ${CYAN}"How much swap space do you want? (4G recommended) \n> ${WHITE}"
                                    read swap_space

                                elif [ "$swap_answer" = 'n']; then
                                    printf ${CYAN}"Not using swap"

                                else
                                    errorMessage "$swap_answer is not a valit option!"
                                    guidedDisks
                                
                                fi

                                showPartitions


                                



                                printf

                            }
                            guidedDisks

                        else 
                            errorMessage "$auto_prov_ans_n_option is not a valid option!"
                            diskSetup

                        fi

                    fi 
                }
                efiDiskSetup

            elif [ "$boot_mode" = "bios" ]; then
                printf ""

            else 
                errorMessage "${boot_mode} is not a valid option!"
                chooseBootMode

            fi

        }
        chooseBootMode

    else
        errorMessage "${disk_chk} is an invalid device, try again with a correct one."
        deviceConfiguration

    fi

}
deviceConfiguration
printf ${LIGHTGREEN}"Device configuration is done! Proceeding to the next step, stage3!"
sleep 3
clear

printf ${CYAN}"Enter the number for the stage3 you want to use:\n${CYAN}1) ${WHITE}regular-openrc ${MAGENTA}recommended\n${CYAN}2) ${WHITE}regular-systemd\n${CYAN}3) ${WHITE}desktop-openrc\n${CYAN}4) ${WHITE}desktop-systemd\n${CYAN}5) ${WHITE}hardened-openrc\n${CYAN}6) ${WHITE}musl\n${CYAN}7) ${WHITE}musl-hardened\n${CYAN}> ${WHITE}"
read stage3select

printf ${LIGHTGREEN}"Beginning the installation, this will take several minutes!\n"

#copying files into place
mount $part_3 /mnt/gentoo
mv $script_dir/../deploygentoo-master /mnt/gentoo/


install_vars=/mnt/gentoo/deploygentoo-master/install_vars
cpus=$(grep -c ^processor /proc/cpuinfo)
pluscpu=$(( cpus + 1 ))
echo "$disk" >> "$install_vars"
echo "$cpus" >> "$install_vars" 
echo "$part_1" >> "$install_vars"
echo "$part_2" >> "$install_vars"
echo "$part_3" >> "$install_vars"


case $stage3select in 
    1)
        GENTOO_TYPE=latest-stage3-amd64-openrc
        ;;
    
    2)
        GENTOO_TYPE=latest-stage3-amd64-systemd
        ;;
    
    3)
        GENTOO_TYPE=latest-stage3-amd64-desktop-openrc
        ;;

    4)
        GENTOO_TYPE=latest-stage3-amd64-desktop-systemd
        ;;
    
    5)
        GENTOO_TYPE=latest-stage3-amd64-hardened-openrc
        ;;

    6)
        GENTOO_TYPE=latest-stage3-amd64-musl
        ;;

    7)
        GENTOO_TYPE=latest-stage3-amd64-musl-hardened
        ;;
esac

STAGE3_PATH_URL=http://distfiles.gentoo.org/releases/amd64/autobuilds/$GENTOO_TYPE.txt
STAGE3_PATH=$(curl -s $STAGE3_PATH_URL | grep -v "^#" | cut -d " " -f1)
STAGE3_URL=http://distfiles.gentoo.org/releases/amd64/autobuilds/$STAGE3_PATH


echo $GENTOO_TYPE >> /mnt/gentoo/gentootype.txt

cd /mnt/gentoo

# stage3
getStage3() {

	wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 $STAGE3_URL

    checkStage3() {

    if [ -e /mnt/gentoo/stage3* ];  then
        printf ${LIGHTGREEN}"Stage3 found!"
    
    else
        printf ${LIGHTRED}"Could not download Stage3, do you want to retry?"
        read stage3_fail_answer

        if [ "$stage3_fail_answer" = "y" ]; then
            clear
            getStage3

        else 
            printf ${LIGHTRED}"Please provide a valid stage3 download link\n${MAGENTA}ex: ${WHITE}${STAGE3_URL}"
            read provided_stage3
            
	        wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 $provided_stage3

            checkStage3

        fi

    fi

    }
    checkStage3
}
getStage3


stage3=$(ls /mnt/gentoo/stage3*)
tar xpvf $stage3 --xattrs-include='*.*' --numeric-owner
printf "Stage3 ready!\n"



 

 
 
 


