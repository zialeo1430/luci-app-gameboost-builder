-- CBI model for gameboost
local m = Map("gameboost", "GameBoost 加速器",
    "配置游戏平台加速规则，支持 Steam、Epic 等主流平台。")

-- 标签页容器
local tab = m:section(TypedSection, "_tab", "")
tab.anonymous = true

-- 总览页
local overview = tab:tab("overview", "加速总览")
local s = overview:option(DummyValue, "_status", "当前状态")
s.value = function()
    local enabled = m:get("global", "enabled") == "1"
    local rules = nixio.fs.readfile("/etc/dnsmasq.d/gameboost.conf") or ""
    local count = #(rules:gsub("\n", "\n"):gsub("[^\n]", ""))  -- 行数
    if enabled then
        return "运行中 | 已启用规则: " .. count
    else
        return "已停止"
    end
end

-- 平台选择页
local platform_tab = tab:tab("platforms", "平台选择")
local platform_section = platform_tab:section(TypedSection, "platform", "")
platform_section.anonymous = true
platform_section.addremove = false
function platform_section:cfgvalue(...)
    return TypedSection.cfgvalue(self, ...)
end

enabled = platform_section:option(Flag, "enabled", "启用")
local pname = platform_section:option(DummyValue, "_name", "平台")
pname.value = function(self, section)
    return section:upper()  -- 显示平台名称
end

-- 规则管理页
local rule_tab = tab:tab("rules", "规则管理")
local custom = rule_tab:section(TypedSection, "rule", "自定义规则")
custom.addremove = true
custom.anonymous = true

domain = custom:option(Value, "domain", "域名")
domain.datatype = "hostname"
ip = custom:option(Value, "ip", "映射 IP")
ip.datatype = "ipaddr"

-- 远程规则源
local remote = rule_tab:section(NamedSection, "global", "gameboost", "远程规则源")
source = remote:option(Value, "rules_source", "规则更新地址")
source.datatype = "url"
auto_update = remote:option(Flag, "auto_update", "自动更新")
interval = remote:option(Value, "update_interval", "更新间隔 (秒)")
interval.datatype = "uinteger"

-- 操作按钮
local btn = rule_tab:section(TypedSection, "_btn")
btn.anonymous = true
btn:option(Button, "_update", "立即更新").inputstyle = "apply"
btn:option(Button, "_backup", "备份规则").inputstyle = "reset"
btn:option(Button, "_restore", "还原规则").inputstyle = "reset"

function btn:handle(_update)
    luci.http.redirect(luci.dispatcher.build_url("admin/services/gameboost/rules_update"))
end

-- 日志与设置页
local settings_tab = tab:tab("settings", "日志与设置")
local log_section = settings_tab:section(NamedSection, "global", "gameboost", "日志设置")
log_level = log_section:option(ListValue, "log_level", "日志级别")
log_level:value("debug", "调试")
log_level:value("info", "信息")
log_level:value("warn", "警告")
log_level:value("error", "错误")

-- 查看日志链接
local log_btn = settings_tab:section(TypedSection, "_log")
log_btn.anonymous = true
log_btn:option(Button, "_view", "查看日志"):depends({})
function log_btn.handle()
    luci.http.redirect(luci.dispatcher.build_url("admin/services/gameboost/log"))
end

-- 代理设置（预留）
local proxy_section = settings_tab:section(NamedSection, "global", "gameboost", "高级代理设置")
proxy_enabled = proxy_section:option(Flag, "proxy_enabled", "启用透明代理 (需要自行安装代理软件)")
proxy_port = proxy_section:option(Value, "proxy_port", "本地代理端口")
proxy_port.datatype = "port"

-- 全局开关
local main_switch = m:section(TypedSection, "global", "全局开关")
main_switch.anonymous = true
enabled_global = main_switch:option(Flag, "enabled", "启用加速")
enabled_global.rmempty = false

return m
