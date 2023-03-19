#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

version="v1.0.0"

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}ERRROR: ${plain} in Script Bayad Ba user root Sakhte Shavad！\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}Verzhen System Shoma Shenasaii Nashod ，Lotfan Ba Negin Ahmadi Tamas Begirid！${plain}\n" && exit 1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red} Lotfan Az Centos7 Ya NoskheHaye Jadid tar estefade Konid！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Lotfan Az Ubuntu 16 Ya NoskheHaye Jadid tar estefade Konid！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Lotfan Az Debian8 Ya NoskheHaye Jadid tar estefade Konid！${plain}\n" && exit 1
    fi
fi

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [PishFarz$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Aya VPN Rah-Andazi Mojadad Shavad" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Baraye Bazgasht Enter Bezanid: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/melina1401/Negin_Vpn/master/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    if [[ $# == 0 ]]; then
        echo && echo -n -e "Verzhene Moshakhas Shode ra Vared Konid: " && read version
    else
        version=$2
    fi
#    confirm "in Dastoor Akharin Noskhe Ra Mojadad Nasb Mikonad , dadeh-ha az dast nemiravand , Edame midahid?" "n"
#    if [[ $? != 0 ]]; then
#        echo -e "${red}Laghv Shod${plain}"
#        if [[ $1 != 0 ]]; then
#            before_show_menu
#        fi
#        return 0
#    fi
    bash <(curl -Ls https://raw.githubusercontent.com/melina1401/Negin_Vpn/master/install.sh) $version
    if [[ $? == 0 ]]; then
        echo -e "${green}update Kamel Shod, Shoroe Khodkar Set Shod , vaziate VPN ra chek Konid${plain}"
        exit
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

config() {
    echo "VPN will automatically try to restart after modifying the configuration"
    vi /etc/NeGiN/config.yml
    sleep 2
    check_status
    case $? in
        0)
            echo -e "Vaziyate VPN: ${green}DAR Hale Ejrast @naji_shab${plain}"
            ;;
        1)
            echo -e "VPN ra Start Nakarde-id , Ye yek Moshkel Vojod darad, Aya Mikhahid log RA bebinid? [Y/n]" && echo
            read -e -p "(baraye Taiid Y ra bezanid):" yn
            [[ -z ${yn} ]] && yn="y"
            if [[ ${yn} == [Yy] ]]; then
               show_log
            fi
            ;;
        2)
            echo -e "Vaziyate VPN: ${red} nasb Nashode ${plain}"
    esac
}

uninstall() {
    confirm "Vaghean Mikhahid VPN ra Hazf Konid?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop XrayR
    systemctl disable XrayR
    rm /etc/systemd/system/XrayR.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/NeGiN/ -rf
    rm /usr/local/XrayR/ -rf

    echo ""
    echo -e "Hazf Anjam Shod , Bad az Khoroj az Script in Dastoor ra Vared Konid : ${green}rm /usr/bin/XrayR -f${plain} Ta Hazf Kamel Shavad"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}VPN dar hale Ejra ast niaz be Start Mojadad Nadarad , RESTART ra Bezanid ${plain}"
    else
        systemctl start XrayR
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}VPN start Shod mitavanid ba dastoor:${plain}  ${yellow}Negin log${plain}  ${green}Vaziat ra chek Konid${plain}"
        else
            echo -e "${red}VPN Nemi-tavand start Shavad Ba datoore : Negin log   Vaziat ra chek Konid${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    systemctl stop XrayR
    sleep 2
    check_status
    if [[ $? == 1 ]]; then
        echo -e "${green}VPN motevaghef shod${plain}"
    else
        echo -e "${red}VPN motevaghef NASHOD , Mojadad Saii Konid ya log ra chek Konid${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart XrayR
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}VPN ba movafaghiat restart Shod , log ra chek konid${plain}"
    else
        echo -e "${red}VPN may fail to start, please use Negin log to view log information later${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status XrayR --no-pager -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable XrayR
    if [[ $? == 0 ]]; then
        echo -e "${green}VPN is set to boot up successfully${plain}"
    else
        echo -e "${red}VPN setting fails to start automatically${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable XrayR
    if [[ $? == 0 ]]; then
        echo -e "${green}VPN cancels booting up successfully${plain}"
    else
        echo -e "${red}VPN failed to cancel the boot-up auto-start${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u XrayR.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

install_bbr() {
    bash <(curl -L -s https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh)
    #if [[ $? == 0 ]]; then
    #    echo ""
    #    echo -e "${green}bbr BA movafaghiat Nasb Shod , Server Ra restart Konid${plain}"
    #else
    #    echo ""
    #    echo -e "${red}bbr Danlod nashod , Motmaeen Shavid servere Shoma be site Github mitavanad motasel shavad${plain}"
    #fi

    #before_show_menu
}

update_shell() {
    wget -O /usr/bin/XrayR -N --no-check-certificate https://raw.githubusercontent.com/melina1401/Negin_Vpn/master/XrayR.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}Failed to download the script, please check whether the machine can connect to Github${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/XrayR
        echo -e "${green}The upgrade script was successful, please run the script again${plain}" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/XrayR.service ]]; then
        return 2
    fi
    temp=$(systemctl status XrayR | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled XrayR)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1;
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red}VPN nasb Shode , Lotfan Nasb ra tekrar Na-konid${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red}Ebteda VPN ra nasb Konid${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "Vaziyate VPN: ${green}dar hale ejra @naji_shab${plain}"
            show_enable_status
            ;;
        1)
            echo -e "Vaziyate VPN: ${yellow}ejra na-shod${plain}"
            show_enable_status
            ;;
        2)
            echo -e "Vaziyate VPN: ${red}nasb nashode${plain}"
    esac
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Whether to start automatically: ${green}yes${plain}"
    else
        echo -e "Whether to start automatically: ${red}no${plain}"
    fi
}

show_XrayR_version() {
    echo -n "Verzhene VPN："
    /usr/local/XrayR/XrayR -version
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_usage() {
    echo "How to use VPN management script: "
    echo "----------------NeGiN---------------------"
    echo "Negin              - Menu (Joziyat Kamel-Tar)"
    echo "Negin start        - Start VPN"
    echo "Negin stop         - Tavaghof VPN"
    echo "Negin restart      - Rah-Andazi Mojadad VPN"
    echo "Negin status       - Vaziyate VPN"
    echo "Negin enable       - Start Shodan Ba Boot"
    echo "Negin disable      - Start Na-shodan Ba Boot"
    echo "Negin log          - Moshahede log"
    echo "Negin update       - Update noskheye VPN"
    echo "Negin update x.x.x - Update Be Noskheye Khas"
    echo "Negin install      - Nasbe VPN"
    echo "Negin uninstall    - Hazfe VPN"
    echo "Negin version      - Didan Noskheye VPN"
    echo "------------NeGiN--------------"
}

show_menu() {
    echo -e "
${green}-+_(-)_+-${plain}    https://T.me/Naji_Shab    ${green}-+_(-)_+-${plain}
  ${green}0.${plain} Taghire Tanzimat
————————————————
  ${green}1.${plain} nasbe VPN
  ${green}2.${plain} update VPN
  ${green}3.${plain} hazfe VPN
————————————————
  ${green}4.${plain} start VPN
  ${green}5.${plain} stop VPN
  ${green}6.${plain} restart VPN
  ${green}7.${plain} didane Vaziyate VPN
  ${green}8.${plain} namayesh log
————————————————
  ${green}9.${plain} Set VPN to start automatically at boot
 ${green}10.${plain} Cancel VPN autostart
————————————————
 ${green}11.${plain} One-click install bbr (latest kernel)
 ${green}12.${plain} moshahede verzhene VPN 
 ${green}13.${plain} Upgrade maintenance script
 ${yellow} --///-- Power By Negin Ahmadi --///-- ${plain}
 "
 #后续更新可加入上方字符串中
    show_status
    echo && read -p "shomare morede Nazar ra vard Konid [0-13]: " num

    case "${num}" in
        0) config
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && update
        ;;
        3) check_install && uninstall
        ;;
        4) check_install && start
        ;;
        5) check_install && stop
        ;;
        6) check_install && restart
        ;;
        7) check_install && status
        ;;
        8) check_install && show_log
        ;;
        9) check_install && enable
        ;;
        10) check_install && disable
        ;;
        11) install_bbr
        ;;
        12) check_install && show_XrayR_version
        ;;
        13) update_shell
        ;;
        *) echo -e "${red}shomare ra dorost vared konid [0-12]${plain}"
        ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0
        ;;
        "stop") check_install 0 && stop 0
        ;;
        "restart") check_install 0 && restart 0
        ;;
        "status") check_install 0 && status 0
        ;;
        "enable") check_install 0 && enable 0
        ;;
        "disable") check_install 0 && disable 0
        ;;
        "log") check_install 0 && show_log 0
        ;;
        "update") check_install 0 && update 0 $2
        ;;
        "config") config $*
        ;;
        "install") check_uninstall 0 && install 0
        ;;
        "uninstall") check_install 0 && uninstall 0
        ;;
        "version") check_install 0 && show_XrayR_version 0
        ;;
        "update_shell") update_shell
        ;;
        *) show_usage
    esac
else
    show_menu
fi
