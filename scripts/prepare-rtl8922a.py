#!/usr/bin/env python3
"""为 ImmortalWrt 源码加入 RTL8922A 诊断补丁和匹配的运行固件。"""

import re
import shutil
import sys
from pathlib import Path


def main():
    if len(sys.argv) != 2:
        raise SystemExit("用法：python3 scripts/prepare-rtl8922a.py <ImmortalWrt源码目录>")

    source = Path(sys.argv[1]).resolve()
    repo = Path(__file__).resolve().parent.parent
    firmware_mk = source / "package/firmware/linux-firmware/realtek.mk"
    mac_mk = source / "package/kernel/mac80211/Makefile"
    patch_source = repo / "patches/999-rtw89-8922a-optional-rfe-override.patch"
    patch_target = source / "package/kernel/mac80211/patches/rtl" / patch_source.name

    for path in (firmware_mk, mac_mk, patch_source):
        if not path.is_file():
            raise SystemExit(f"缺少依赖文件：{path}")

    firmware = firmware_mk.read_text()
    pattern = r"(define Package/rtl8922ae-firmware/install\n)(.*?)(\nendef)"
    match = re.search(pattern, firmware, re.S)
    if not match:
        raise SystemExit("没有找到 RTL8922AE 固件安装规则，请检查新版源码")

    block = match.group(2)
    if "rtw8922a_fw-4.bin" not in block and "rtw8922a_fw*.bin" not in block:
        original = "$(PKG_BUILD_DIR)/rtw89/rtw8922a_fw.bin"
        if block.count(original) != 1:
            raise SystemExit("RTL8922AE 固件规则已变化，停止修改")
        block = block.replace(
            original,
            original + " \\\n\t\t$(PKG_BUILD_DIR)/rtw89/rtw8922a_fw-4.bin",
        )
        firmware = firmware[:match.start(2)] + block + firmware[match.end(2):]

    mac = mac_mk.read_text()
    marker = "# RTL8922A diagnostic config dependencies"
    if marker not in mac:
        anchor = "include $(INCLUDE_DIR)/package.mk"
        if mac.count(anchor) != 1:
            raise SystemExit("mac80211 构建规则已变化，停止修改")
        dependencies = (
            marker + "\n"
            "PKG_CONFIG_DEPENDS += CONFIG_PACKAGE_RTW89_DEBUG "
            "CONFIG_PACKAGE_RTW89_DEBUGFS CONFIG_PACKAGE_RTW89_DEBUGMSG\n\n"
        )
        mac = mac.replace(anchor, dependencies + anchor)

    if patch_target.exists() and patch_target.read_bytes() != patch_source.read_bytes():
        raise SystemExit(f"目标位置已有不同补丁，停止覆盖：{patch_target}")

    firmware_mk.write_text(firmware)
    mac_mk.write_text(mac)
    patch_target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(patch_source, patch_target)
    print("已加入 RTL8922A 可选 RFE 覆盖补丁、调试配置依赖和 fw-4 固件")


if __name__ == "__main__":
    main()
