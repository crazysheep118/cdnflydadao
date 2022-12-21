#!/bin/bash -x

#判断系统版本
check_sys(){
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''
    local packageSupport=''

    if [[ "$release" == "" ]] || [[ "$systemPackage" == "" ]] || [[ "$packageSupport" == "" ]];then

        if [[ -f /etc/redhat-release ]];then
            release="centos"
            systemPackage="yum"
            packageSupport=true

        elif cat /etc/issue | grep -q -E -i "debian";then
            release="debian"
            systemPackage="apt"
            packageSupport=true

        elif cat /etc/issue | grep -q -E -i "ubuntu";then
            release="ubuntu"
            systemPackage="apt"
            packageSupport=true

        elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat";then
            release="centos"
            systemPackage="yum"
            packageSupport=true

        elif cat /proc/version | grep -q -E -i "debian";then
            release="debian"
            systemPackage="apt"
            packageSupport=true

        elif cat /proc/version | grep -q -E -i "ubuntu";then
            release="ubuntu"
            systemPackage="apt"
            packageSupport=true

        elif cat /proc/version | grep -q -E -i "centos|red hat|redhat";then
            release="centos"
            systemPackage="yum"
            packageSupport=true

        else
            release="other"
            systemPackage="other"
            packageSupport=false
        fi
    fi

    echo -e "release=$release\nsystemPackage=$systemPackage\npackageSupport=$packageSupport\n" > /tmp/ezhttp_sys_check_result

    if [[ $checkType == "sysRelease" ]]; then
        if [ "$value" == "$release" ];then
            return 0
        else
            return 1
        fi

    elif [[ $checkType == "packageManager" ]]; then
        if [ "$value" == "$systemPackage" ];then
            return 0
        else
            return 1
        fi

    elif [[ $checkType == "packageSupport" ]]; then
        if $packageSupport;then
            return 0
        else
            return 1
        fi
    fi
}






# 停止主控程序
supervisorctl -c /opt/cdnfly/master/conf/supervisord.conf stop all

# 备份mysql
eval `grep "MYSQL_PASS" /opt/cdnfly/master/conf/config.py`
mysqldump -e --single-transaction --default-character-set=utf8 --skip-add-locks -R -f --max_allowed_packet=16777216 --net_buffer_length=16384  -p$MYSQL_PASS cdn --ignore-table=cdn.node_monitor_log > /root/cdn.sql
mysqldump -d -e --single-transaction --default-character-set=utf8 --skip-add-locks -R -f --max_allowed_packet=16777216 --net_buffer_length=16384 -p$MYSQL_PASS cdn node_monitor_log >> /root/cdn.sql
gzip /root/cdn.sql

# 停止mysql
if check_sys sysRelease ubuntu;then
    systemctl stop mysql
elif check_sys sysRelease centos;then
    systemctl stop mariadb
fi
