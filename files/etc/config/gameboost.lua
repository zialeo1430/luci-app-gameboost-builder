module("luci.controller.gameboost", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/gameboost") then
        return
    end

    local page = entry({"admin", "services", "gameboost"}, cbi("gameboost"), _("GameBoost"), 100)
    page.dependent = true
    entry({"admin", "services", "gameboost", "log"}, call("action_log"), _("Log")).leaf = true
end

function action_log()
    local logfile = "/var/log/gameboost.log"
    luci.http.prepare_content("text/plain")
    if nixio.fs.access(logfile) then
        luci.http.write(luci.sys.exec("tail -n 200 " .. logfile))
    else
        luci.http.write("No log file found.")
    end
end
