#!/bin/bash
cd immortalwrt

cat ../xgp.config > .config
echo "make defconfig"
make defconfig || { echo "defconfig failed"; exit 1; }
echo "diff initial config and new config:"
diff ../xgp.config .config
echo "diff initial config and new config (from old config only):"
diff ../xgp.config .config | grep -e "^<" | grep -v "^< #"
echo "diff initial config and new config (from new config only):"
diff ../xgp.config .config | grep -e "^>" | grep -v "^> #"
# 确认网卡驱动、固件与诊断选项没有被 defconfig 的依赖检查移除。
for option in \
    CONFIG_PACKAGE_kmod-rtw89-8852ae \
    CONFIG_PACKAGE_rtl8852ae-firmware \
    CONFIG_PACKAGE_kmod-rtw89-8852be \
    CONFIG_PACKAGE_rtl8852be-firmware \
    CONFIG_PACKAGE_kmod-rtw89-8852ce \
    CONFIG_PACKAGE_rtl8852ce-firmware \
    CONFIG_PACKAGE_kmod-rtw89-8922ae \
    CONFIG_PACKAGE_rtl8922ae-firmware \
    CONFIG_PACKAGE_kmod-mt7921e \
    CONFIG_PACKAGE_kmod-mt7922-firmware \
    CONFIG_PACKAGE_kmod-mt7925e \
    CONFIG_PACKAGE_kmod-mt7925-firmware \
    CONFIG_PACKAGE_kmod-ath11k-pci \
    CONFIG_PACKAGE_ath11k-firmware-wcn6855 \
    CONFIG_PACKAGE_kmod-ath12k \
    CONFIG_PACKAGE_ath12k-firmware-wcn7850 \
    CONFIG_PACKAGE_kmod-ath10k \
    CONFIG_PACKAGE_ath10k-firmware-qca988x \
    CONFIG_PACKAGE_ath10k-board-qca988x \
    CONFIG_PACKAGE_RTW89_DEBUG \
    CONFIG_PACKAGE_RTW89_DEBUGFS \
    CONFIG_PACKAGE_RTW89_DEBUGMSG; do
    grep -Fxq "${option}=y" .config || { echo "缺少必要配置：${option}"; exit 1; }
done

echo "check device exist"
grep -Fxq "CONFIG_TARGET_rockchip_armv8_DEVICE_nlnet_xiguapi-v3=y" .config || exit 1

year=$(date +%y)
month=$(date +%-m)
day=$(date +%-d)
hour=$(date +%-H)
zz_build_date=$(date "+%Y-%m-%d %H:%M:%S %z")
zz_build_uuid=$(uuidgen)

echo "zz_build_date=${zz_build_date}"
echo "zz_build_uuid=${zz_build_uuid}"
cat > files/etc/uci-defaults/zzzz-version << EOF
#!/bin/sh
sed -i "1i ZZ_DISTRIB_NAME='ImmortalWrt for XGPv3'" /etc/openwrt_release
sed -i "2i ZZ_DISTRIB_VERSION='R${year}.${month}.${day}.${hour}'" /etc/openwrt_release
/bin/sync
EOF
echo "ZZ_BUILD_ID='${zz_build_uuid}'" > files/etc/zz_build_id
echo "ZZ_BUILD_HOST='$(hostname)'" >> files/etc/zz_build_id
echo "ZZ_BUILD_USER='$(whoami)'" >> files/etc/zz_build_id
echo "ZZ_BUILD_DATE='${zz_build_date}'" >> files/etc/zz_build_id
echo "ZZ_BUILD_REPO_HASH='$(cd .. && git rev-parse HEAD)'" >> files/etc/zz_build_id
echo "ZZ_BUILD_IMM_HASH='$(git rev-parse HEAD)'" >> files/etc/zz_build_id

MAKE_V=${1:-0}
echo "make immortalwrt"
make V=$MAKE_V -j$(nproc) || {
    echo "make failed";
    if [ "$MAKE_V" -eq 0 ]; then
        echo "Retrying with make V=s -j1";
        make V=s -j1 || { echo "Retry failed"; exit 1; }
    else
        exit 1;
    fi
}
