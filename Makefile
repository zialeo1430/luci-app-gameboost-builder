# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2025 OpenWrt.org
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-gameboost
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Your Name <your@email.com>
PKG_LICENSE:=GPL-2.0

LUCI_TITLE:=LuCI support for Gameboost (Matt Toolkit like accelerator)
# 关键修改：把 dnsmasq-full 改为 dnsmasq
LUCI_DEPENDS:=+dnsmasq +curl +ca-certificates
LUCI_PKGARCH:=all

define Package/$(PKG_NAME)/conffiles
/etc/config/gameboost
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
