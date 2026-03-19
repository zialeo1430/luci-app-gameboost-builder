#!/bin/sh
# iptables helper for SNI proxy / port forwarding (optional)

. /etc/gameboost/utils.sh

PROXY_ENABLED=$(get_uci_bool proxy_enabled)
PROXY_PORT=$(get_uci_value proxy_port)
PROXY_IP="127.0.0.1"  # 假设代理运行在本地

# 定义需要代理的域名列表（从自定义规则中读取标记为代理的域名，这里简化：直接读取一个单独的文件）
# 实际可以设计为在 UCI 中为规则添加 proxy 选项，此处暂不实现，仅做框架。

apply() {
    [ "$PROXY_ENABLED" != "1" ] && return 0
    # 示例：将所有对 80/443 端口的流量重定向到本地 PROXY_PORT（透明代理模式）
    # 需要用户自行配置代理软件（如 redsocks2）
    iptables -t nat -N GAMEBOOST_PROXY 2>/dev/null
    iptables -t nat -F GAMEBOOST_PROXY
    # 这里应当从规则中提取需要代理的 IP 或域名，但 iptables 只能匹配 IP。
    # 因此需要配合 dnsmasq 的 ipset 使用，将域名解析到特定 IP 集。
    # 为简化，本版本暂不实现，仅输出提示。
    log "INFO" "iptables proxy not fully implemented in this version."
}

clean() {
    iptables -t nat -D PREROUTING -j GAMEBOOST_PROXY 2>/dev/null
    iptables -t nat -F GAMEBOOST_PROXY 2>/dev/null
    iptables -t nat -X GAMEBOOST_PROXY 2>/dev/null
    log "INFO" "iptables rules cleaned."
}

case "$1" in
    apply) apply ;;
    clean) clean ;;
    *) echo "Usage: $0 {apply|clean}" ;;
esac
