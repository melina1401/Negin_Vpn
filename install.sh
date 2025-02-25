#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}ERRROR：${plain} in Script Bayad Ba user root Sakhte Shavad！\n" && exit 1

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
    echo -e "${red}Verzhen System Shoma Shenasaii Nashod ，Lotfan Ba XrayR Ahmadi Tamas Begirid！${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64-v8a"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="64"
    echo -e "${red}Detect schema failed，Use the default schema: ${arch}${plain}"
fi

echo "architecture: ${arch}"

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "This software does not support 32-bit system (x86), please use 64-bit system (x86_64), if the detection is wrong, please contact the author"
    exit 2
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

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install epel-release -y
        yum install wget curl unzip tar crontabs socat -y
    else
        apt update -y
        apt install wget curl unzip tar cron socat -y
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

install_acme() {
    curl https://get.acme.sh | sh
}

install_Negin() {
    if [[ -e /usr/local/XrayR/ ]]; then
        rm /usr/local/XrayR/ -rf
    fi

    mkdir /usr/local/XrayR/ -p
	cd /usr/local/XrayR/

    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/XrayR-project/XrayR/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}Failed to detect the XrayR version, it may be beyond the Github API limit, please try again later, or manually specify the XrayR version to install${plain}"
            exit 1
        fi
        echo -e "XrayR latest version detected：${last_version}，start installation"
        wget -q -N --no-check-certificate -O /usr/local/XrayR/XrayR-linux.zip https://github.com/XrayR-project/XrayR/releases/download/${last_version}/XrayR-linux-${arch}.zip
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Failed to download XrayR, please make sure your server can download files from Github${plain}"
            exit 1
        fi
    else
        if [[ $1 == v* ]]; then
            last_version=$1
	else
	    last_version="v"$1
	fi
        url="https://github.com/XrayR-project/XrayR/releases/download/${last_version}/XrayR-linux-${arch}.zip"
        echo -e "Start installing XrayR ${last_version}"
        wget -q -N --no-check-certificate -O /usr/local/XrayR/XrayR-linux.zip ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red} Download XrayR ${last_version} Failed, make sure this version exists${plain}"
            exit 1
        fi
    fi

    unzip XrayR-linux.zip
    rm XrayR-linux.zip -f
    chmod +x XrayR
    mkdir /etc/NeGiN/ -p
    rm /etc/systemd/system/XrayR.service -f
    file="https://github.com/melina1401/Negin_Vpn/raw/master/XrayR.service"
    wget -q -N --no-check-certificate -O /etc/systemd/system/XrayR.service ${file}
    #cp -f XrayR.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl stop XrayR
    systemctl enable XrayR
    echo -e "${green}XrayR ${last_version}${plain} Nasb Tamam Shod va Baraye Shoroe Khodkar Set Shod"
    cp geoip.dat /etc/NeGiN/
    cp geosite.dat /etc/NeGiN/ 

    if [[ ! -f /etc/NeGiN/config.yml ]]; then
        cp config.yml /etc/NeGiN/
        echo -e ""
        echo -e "Nasb Jadid , Amoozesh Ra Donbal Konid：https://github.com/melina1401/Negin_Vpn ，Niyaz Be Config Shodan Darad"
    else
        systemctl start XrayR
        sleep 2
        check_status
        echo -e ""
        if [[ $? == 0 ]]; then
            echo -e "${green}VPN Rah Andazi Mojadad Anjam Shod${plain}"
        else
            echo -e "${red}VPN may fail to start, please use XrayR log to view the log information later, if it cannot start, the configuration format may have been changed, please go to the wiki to view：https://github.com/XrayR-project/XrayR/wiki${plain}"
        fi
    fi

    if [[ ! -f /etc/NeGiN/dns.json ]]; then
        cp dns.json /etc/NeGiN/
    fi
    if [[ ! -f /etc/NeGiN/route.json ]]; then
        cp route.json /etc/NeGiN/
    fi
    if [[ ! -f /etc/NeGiN/custom_outbound.json ]]; then
        cp custom_outbound.json /etc/NeGiN/
    fi
    if [[ ! -f /etc/NeGiN/custom_inbound.json ]]; then
        cp custom_inbound.json /etc/NeGiN/
    fi
    if [[ ! -f /etc/NeGiN/rulelist ]]; then
        cp rulelist /etc/NeGiN/
    fi
    curl -o /usr/bin/XrayR -Ls https://raw.githubusercontent.com/melina1401/Negin_Vpn/master/XrayR.sh
    chmod +x /usr/bin/XrayR
    ln -s /usr/bin/XrayR /usr/bin/XrayR # SazGar Ba Horoof Koochak
    chmod +x /usr/bin/XrayR
    cd $cur_dir
    rm -f install.sh
    echo -e ""
    echo "How to use XrayR management script (compatible with XrayR execution, case insensitive): "
    echo "------------------------------------------"
    echo "XrayR                    - Menu (Joziyat Kamel-Tar)"
    echo "XrayR start              - Start VPN"
    echo "XrayR stop               - Tavaghof VPN"
    echo "XrayR restart            - Rah-Andazi Mojadad VPN"
    echo "XrayR status             - Vaziyate VPN"
    echo "XrayR enable             - Start Shodan Ba Boot"
    echo "XrayR disable            - Start Na-shodan Ba Boot"
    echo "XrayR log                - Moshahede log"
    echo "XrayR update             - Update noskheye VPN"
    echo "XrayR update x.x.x       - Update Be Noskheye Khas"
    echo "XrayR config             - Namayeshe File Config"
    echo "XrayR install            - Nasbe VPN"
    echo "XrayR uninstall          - Hazfe VPN"
    echo "XrayR version            - Didan Noskheye VPN"
    echo "------------------------------------------"
}

echo -e "${green}Nasb Ra Shoro Konid${plain}"
install_base
# install_acme
install_Negin $1
