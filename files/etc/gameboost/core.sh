#!/bin/sh
# Core control script for gameboost

. /etc/gameboost/utils.sh

ACTION=$1

case "$ACTION" in
    boot|start|enable)
        # 开机启动或手动启用
        if [ "$(get_uci_bool enabled)" = "1" ]; then
            log "INFO" "Enabling gameboost..."
            # 立即更新规则（异步，避免阻塞启动）
            /etc/gameboost/rules_update.sh &
            # 设置定时任务（如果启用自动更新）
            if [ "$(get_uci_bool auto_update)" = "1" ]; then
                interval=$(get_uci_value update_interval)
                # 使用 crontab 管理，但 OpenWrt 默认用 procd 的定时器，这里简化：通过 procd 的 respawn 和 sleep 循环？不如直接用 crond
                # 这里我们采用简单的方式：在 init.d 中通过 procd 保持一个进程定期执行，但为简化，此处不实现定时，留给 crontab 或用户手动。
                # 实际上更健壮的方式是在 init.d 中用 procd 的 timer，但需要 procd 支持。
                # 这里我们仅提示用户可以用 crontab 添加，或者在 LuCI 中添加一个定时触发机制。
                log "INFO" "Auto update enabled, but timer not implemented in this version. Please set up a cron job manually if needed."
            fi
            # 重启 dnsmasq 确保新配置生效
            /etc/init.d/dnsmasq restart
        else
            log "INFO" "Gameboost is disabled in config, not starting."
        fi
        ;;
    stop|disable)
        log "INFO" "Disabling gameboost..."
        # 删除 dnsmasq 配置
        rm -f "$DNSMASQ_CONF"
        /etc/init.d/dnsmasq restart
        # 清理 iptables 规则
        if [ -f /etc/gameboost/iptables.sh ]; then
            /etc/gameboost/iptables.sh clean
        fi
        ;;
    reload)
        # 重新加载配置（例如 UCI 变动后）
        if [ "$(get_uci_bool enabled)" = "1" ]; then
            log "INFO" "Reloading gameboost..."
            /etc/gameboost/rules_update.sh
            /etc/init.d/dnsmasq restart
        else
            # 如果被禁用，则执行 disable
            $0 disable
        fi
        ;;
    restart)
        $0 disable
        $0 start
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|reload|enable|disable}"
        exit 1
        ;;
esac
exit 0
