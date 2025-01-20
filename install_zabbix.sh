#!/usr/bin/env bash

hostname="$HOST_NAME"
server_ip="65.108.196.236"
LOGFILE="/var/log/zabbix_install.log"

if [[ -z "$hostname" ]]; then
    echo "Переменная окружения HOST_NAME не установлена"
    exit 1
fi

run_command() {
    echo "Выполнение команды: sudo $@" | tee -a $LOGFILE
    sudo "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "Ошибка при выполнении команды: $1 (код ошибки: $status)"
    else
        echo "Команда успешно выполнена: $1"
    fi
    return $status
}

remove_old_zabbix(){
    echo "Начало удаления старого агента Zabbix" | tee -a $LOGFILE
    if [[ $(systemctl list-units --full -all | grep "zabbix-agent" | wc -l) -gt 0 ]]; then
        run_command systemctl stop zabbix-agent
        run_command apt remove -y zabbix-agent
    fi
    if [[ -d "/etc/zabbix/" ]]; then
        run_command rm -rf /etc/zabbix/
    fi
    echo "Старый агент Zabbix удалён" | tee -a $LOGFILE
}

install_zabbix(){
    echo "Начало установки агента Zabbix" | tee -a $LOGFILE

    # Определение версии ОС
    os_version=$(lsb_release -rs)
    os_codename=$(lsb_release -cs)

    if [[ $os_version == "22.04" ]]; then
        echo "Detected OS: Ubuntu 22.04" | tee -a $LOGFILE
        zabbix_repo="https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1%2Bubuntu22.04_all.deb"
    elif [[ $os_version == "20.04" ]]; then
        echo "Detected OS: Ubuntu 20.04" | tee -a $LOGFILE
        zabbix_repo="https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1%2Bubuntu20.04_all.deb"
    else
        echo "Unsupported OS version: $os_version" | tee -a $LOGFILE
        exit 1
    fi

    if [[ ! -f "/etc/zabbix/zabbix_agentd.conf" ]]; then
        run_command apt remove --purge zabbix-agent -y
        run_command wget "$zabbix_repo" -O /tmp/zabbix-release.deb
        run_command dpkg -i /tmp/zabbix-release.deb
        run_command apt-get update
        run_command apt-get install -y zabbix-agent
        run_command systemctl restart zabbix-agent
        run_command systemctl enable zabbix-agent
        run_command rm -f /tmp/zabbix-release.deb
    fi
    echo "Агент Zabbix установлен" | tee -a $LOGFILE
}

config_zabbix(){
    echo "Начало конфигурации агента Zabbix" | tee -a $LOGFILE
    run_command sed -i "s/Hostname=.*/Hostname=$hostname/g" /etc/zabbix/zabbix_agentd.conf
    run_command sed -i "s/Server=.*/Server=$server_ip/g" /etc/zabbix/zabbix_agentd.conf
    run_command sed -i "s/ServerActive=.*/ServerActive=$server_ip/g" /etc/zabbix/zabbix_agentd.conf
    run_command sed -i "s/# HostMetadata=/HostMetadata=autoreg.linux/" /etc/zabbix/zabbix_agentd.conf
    run_command systemctl restart zabbix-agent
    echo "Агент Zabbix сконфигурирован" | tee -a $LOGFILE
}

echo "Запуск скрипта" | tee -a $LOGFILE
remove_old_zabbix
install_zabbix
config_zabbix
echo "Скрипт успешно выполнен" | tee -a $LOGFILE
