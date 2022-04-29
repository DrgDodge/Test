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
cd ~
start_dir=$(pwd)

# get disk info
fdisk -l >> devices
# get network info    #mkfs.ext4 $part_2
ifconfig -s >> nw_devices

# pass network info
cut -d ' ' -f1 nw_devices >> network_devices
rm -rf nw_devices
sed -e "s/lo//g" -i network_devices
sed -e "s/Iface//g" -i network_devices
sed '/^$/d' network_devices

# pass disk info
sed -e '\#Disk /dev/ram#,+5d' -i devices
sed -e '\#Disk /dev/loop#,+5d' -i devices

# show current disk configuration to the user
cat devices

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
    partition_count="$(grep -o $disk devices | wc -l)"
    disk_chk=("/dev/${disk}")
    
    # start messing with drives
    if grep "$disk_chk" devices; then

        chooseBootMode() {
            printf ${CYAN}"Do you have EFI/UEFI mode or BIOS/Legacy mode active? For EFI/UEFI mode type \"efi\" or for BIOS/Legacy mode type \"bios\".\n${LIGHTRED}If you don't know the answer it is recommended to choose BIOS/Legacy mode (bios)\n${CYAN}> ${WHITE}"
            read boot_mode
            printf ${MAGENTA}
            
            # choose bios
            if [ "$boot_mode" = "efi" ]; then
                diskSetup() {

                    printf ${CYAN}"Would you like to proceed with the auto setup for ${disk_chk}? \n${MAGENTA}This will create a GPT partition scheme where:${CYAN}\n${disk_chk}1 = 256M EFI System\n${disk_chk}2 = 4G Linux swap\n${disk_chk}3 = Linux filesystem \n\nEnter y to continue with auto setup or n to configure your own partitions \n> ${WHITE}"             
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
                        rm -rf devices
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

                        if [ "$auto_prov_ans_n_option" = "DIY" ]; then

                            DIY() {

                                printf ${MAGENTA}"These are your partitions now:\n\n"${CYAN}
                                cat devices
                                printf ${MAGENTA}"\nWhat do you want to do now?\n${CYAN}1) ${LIGHTRED}REMOVE ALL PARTITIONS${CYAN}\n2) ${WHITE}Delete 1 partition${CYAN}\n3) ${WHITE}Create 1 partition${CYAN}\n4) ${WHITE}Change partition type\n${CYAN}> ${WHITE}"
                                
                                read DIY_option

                                if [ "$DIY_option" = '1' ]; then 
                                    printf ${LIGHTRED}"ARE YOU SURE DO YOU WANT TO REMOVE ALL PARTITIONS?\n${CYAN}> ${WHITE}"                                
                                    read REMOVE_ALL_PARTITIONS_answer

                                    if [ "$REMOVE_ALL_PARTITIONS_answer" = 'y' ]; then
                                       
                                        wipefs -a $disk_chk
                                        parted -a optimal $disk_chk --script mklabel gpt

                                        
                                        
                                        cat devices
                                    fi


                                elif [ "$DIY_option" = '2' ]; then 
                                    printf ""


                                elif [ "$DIY_option" = '3' ]; then

                                    DIY_option3() {

                                        printf ${CYAN}"Partition number ($(lsblk | grep $disk -c )-128, default $(lsblk | grep $disk -c)): ${WHITE}"
                                        read DIY_option_3_partition_number

                                        if [ "$DIY_option_3_partition_number" -lt 128 && "$DIY_option_3_partition_number" -ge "$(lsblk | grep $disk -c)" ]; then

                                        


                                        else
                                            errorMessage "$DIY_option_3_partition_number is not in range."
                                            DIY_option3

                                        fi

                                    }
                                    DIY_option3

                                else 
                                    errorMessage "$DIY_option is not a valid option!"


                                fi
                            
                            }
                            DIY

                        elif [ "$auto_prov_ans_n_option" = "guided" ]; then
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
                diskSetup

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