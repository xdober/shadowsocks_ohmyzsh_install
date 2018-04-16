#!/bin/bash

# install shadowsocks-python, zsh and ohmyzsh on centOS
install_ss(){
    yum install -y git
    yum install -y python-setuptools && easy_install pip
    pip install git+https://github.com/shadowsocks/shadowsocks.git@master
}
pre_config(){
    # Stream Ciphers
    ciphers=(
    aes-256-gcm
    aes-192-gcm
    aes-128-gcm
    aes-256-ctr
    aes-192-ctr
    aes-128-ctr
    aes-256-cfb
    aes-192-cfb
    aes-128-cfb
    camellia-128-cfb
    camellia-192-cfb
    camellia-256-cfb
    chacha20-ietf-poly1305
    chacha20-ietf
    chacha20
    rc4-md5
    )
    # Color
    red='\033[0;31m'
    green='\033[0;32m'
    yellow='\033[0;33m'
    plain='\033[0m'

   # Set shadowsocks config password
    echo "Please enter password for shadowsocks-python"
    read -p "(Default password: xrr.xrr):" shadowsockspwd
    [ -z "${shadowsockspwd}" ] && shadowsockspwd="xrr.xrr"
    echo
    echo "---------------------------"
    echo "password = ${shadowsockspwd}"
    echo "---------------------------"
    echo
    # Set shadowsocks config port
    while true
    do
    dport=$(shuf -i 9000-19999 -n 1)
    echo "Please enter a port for shadowsocks-python [1-65535]"
    read -p "(Default port: ${dport}):" shadowsocksport
    [ -z "$shadowsocksport" ] && shadowsocksport=${dport}
    expr ${shadowsocksport} + 1 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ ${shadowsocksport} -ge 1 ] && [ ${shadowsocksport} -le 65535 ] && [ ${shadowsocksport:0:1} != 0 ]; then
            echo
            echo "---------------------------"
            echo "port = ${shadowsocksport}"
            echo "---------------------------"
            echo
            break
        fi
    fi
    echo -e "[${red}Error${plain}] Please enter a correct number [1-65535]"
    done

    # Set shadowsocks config stream ciphers
    while true
    do
    echo -e "Please select stream cipher for shadowsocks-python:"
    for ((i=1;i<=${#ciphers[@]};i++ )); do
        hint="${ciphers[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "Which cipher you'd select(Default: ${ciphers[0]}):" pick
    [ -z "$pick" ] && pick=1
    expr ${pick} + 1 &>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "[${red}Error${plain}] Please enter a number"
        continue
    fi
    if [[ "$pick" -lt 1 || "$pick" -gt ${#ciphers[@]} ]]; then
        echo -e "[${red}Error${plain}] Please enter a number between 1 and ${#ciphers[@]}"
        continue
    fi
    shadowsockscipher=${ciphers[$pick-1]}
    echo
    echo "---------------------------"
    echo "cipher = ${shadowsockscipher}"
    echo "---------------------------"
    echo
    break
    done
}
config_ss(){
    pre_config
    cat > /etc/shadowsocks.json<<-EOF
{
    "server":"::",
    "server_port":${shadowsocksport},
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"${shadowsockspwd}",
    "timeout":300,
    "method":"${shadowsockscipher}",
    "fast_open":false
}
EOF
    auto_start
    auto_reboot
    ssserver -c /etc/shadowsocks.json -d start
}
auto_start(){
    echo -e "\nssserver -c /etc/shadowsocks.json -d start">>/etc/rc.local
    chmod +x /etc/rc.d/rc.local
}
auto_reboot(){
    echo -e "\n3 13 */2 * * /sbin/reboot">>/var/spool/cron/root
}
get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    [ ! -z ${IP} ] && echo ${IP} || echo
}
echo $(get_ip)
install_zsh(){
    i="zsh"
    x=`rpm -qa | grep $i`
    if [ ! `rpm -qa | grep $i |wc -l` -ne 0 ];then
    yum install zsh -y
    fi
    install_ohmyzsh
}
install_ohmyzsh(){
  if [ ! -n "$ZSH" ]; then
    ZSH=~/.oh-my-zsh
  fi

  if [ ! -d "$ZSH" ]; then
    # uninstalled
    # printf "${YELLOW}You already have Oh My Zsh installed.${NORMAL}\n"
    # printf "You'll need to remove $ZSH if you want to re-install.\n"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
  fi
}
main(){
    install_ss
    config_ss
    install_zsh
}
main