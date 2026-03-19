#!/bin/sh
# Update rules from remote source

. /etc/gameboost/utils.sh

RULES_URL=$(get_uci_value rules_source)
TMP_FILE="/tmp/gameboost_rules.tmp"
ENABLED_PLATFORMS=$(get_enabled_platforms)

log "INFO" "Starting rules update from $RULES_URL"

# 下载规则文件
curl -s -f -o "$TMP_FILE" "$RULES_URL"
if [ $? -ne 0 ]; then
    log "ERROR" "Failed to download rules from $RULES_URL"
    exit 1
fi

# 校验文件格式并生成 dnsmasq 配置
> "$TMP_FILE".filtered
while IFS='|' read -r platform domain ip; do
    # 跳过空行和注释行
    [ -z "$platform" ] && continue
    echo "$platform" | grep -q '^#' && continue

    # 验证平台是否启用
    enabled=0
    for p in $ENABLED_PLATFORMS; do
        if [ "$p" = "$platform" ]; then
            enabled=1
            break
        fi
    done
    [ $enabled -eq 0 ] && continue

    # 验证域名和 IP
    if validate_domain "$domain" && validate_ip "$ip"; then
        echo "address=/$domain/$ip" >> "$TMP_FILE".filtered
        log "DEBUG" "Added rule: $domain -> $ip"
    else
        log "WARN" "Invalid rule skipped: $platform|$domain|$ip"
    fi
done < "$TMP_FILE"

# 合并自定义规则（从 UCI）
custom_rules=$(uci -q show gameboost | grep '^gameboost\.@rule')
if [ -n "$custom_rules" ]; then
    uci -q show gameboost | grep '^gameboost\.@rule' | while read line; do
        # 解析每个自定义规则 section
        section=$(echo "$line" | cut -d. -f2 | cut -d= -f1 | head -1)
        domain=$(uci -q get gameboost.$section.domain)
        ip=$(uci -q get gameboost.$section.ip)
        if validate_domain "$domain" && validate_ip "$ip"; then
            echo "address=/$domain/$ip" >> "$TMP_FILE".filtered
            log "DEBUG" "Added custom rule: $domain -> $ip"
        else
            log "WARN" "Invalid custom rule skipped: $domain -> $ip"
        fi
    done
fi

# 如果文件非空，安装到 dnsmasq 目录
if [ -s "$TMP_FILE".filtered ]; then
    cat "$TMP_FILE".filtered > "$DNSMASQ_CONF"
    log "INFO" "Rules updated, $(wc -l < "$DNSMASQ_CONF") entries written."
else
    # 如果没有规则，删除配置文件（等同于禁用）
    rm -f "$DNSMASQ_CONF"
    log "INFO" "No rules for enabled platforms, cleared dnsmasq config."
fi

# 清理临时文件
rm -f "$TMP_FILE" "$TMP_FILE".filtered

# 如果启用了 iptables 代理，调用 iptables.sh 更新
if [ "$(get_uci_bool proxy_enabled)" = "1" ]; then
    /etc/gameboost/iptables.sh apply
fi

log "INFO" "Rules update completed."
exit 0
