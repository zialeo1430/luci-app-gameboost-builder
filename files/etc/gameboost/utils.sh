#!/bin/sh
# Common utility functions for gameboost

LOG_FILE="/var/log/gameboost.log"
LOCK_FILE="/var/run/gameboost.lock"
CONFIG_DIR="/etc/gameboost"
DNSMASQ_DIR="/etc/dnsmasq.d"
DNSMASQ_CONF="$DNSMASQ_DIR/gameboost.conf"

# 日志函数
log() {
    local level=$1
    local msg=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp [$level] $msg" >> $LOG_FILE
    # 如果 log_level 为 debug 且 $level 不是 debug，不输出到 console
    [ "$level" = "ERROR" ] && echo "$msg" >&2
}

# 读取 UCI 配置
get_uci_bool() {
    local val=$(uci -q get gameboost.global.$1)
    [ "$val" = "1" ] && echo "1" || echo "0"
}

get_uci_value() {
    uci -q get gameboost.global.$1
}

# 检查 IP 合法性
validate_ip() {
    local ip=$1
    # 简单的 IPv4 格式校验
    echo "$ip" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}$' || return 1
    # 检查每个段 <=255
    local IFS=.
    set -- $ip
    [ $1 -le 255 ] && [ $2 -le 255 ] && [ $3 -le 255 ] && [ $4 -le 255 ]
}

# 检查域名合法性（简单）
validate_domain() {
    local domain=$1
    echo "$domain" | grep -qE '^([a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'
}

# 获取已启用的平台列表
get_enabled_platforms() {
    uci show gameboost | grep '=platform' | cut -d. -f2 | while read sec; do
        enabled=$(uci -q get gameboost.$sec.enabled)
        [ "$enabled" = "1" ] && echo "$sec"
    done
}
