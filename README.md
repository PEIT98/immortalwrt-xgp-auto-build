## 本分支新增：RTL8922AE 诊断

基于 [zzzz0317 原项目](https://github.com/zzzz0317/immortalwrt-xgp-auto-build)，保留原插件与设备配置。构建仅手动触发。

- 加入 RTL8852AE/BE/CE、RTL8922AE 驱动，并开启 rtw89 调试日志与 debugfs。
- 补齐 `rtw8922a_fw-4.bin`，保留原有固件文件。
- 加入 `rfe_type_override` 测试参数，默认 `-1`（关闭）。只有原始 RFE 为 `255` 时才覆盖；正常值保持原样。此参数不写入网卡 eFuse，也不恢复其他校准字段。

刷入本分支构建的固件后，通过有线或移动网络连接 SSH，执行：

```sh
rtl8922a-debug status
rtl8922a-debug collect
```

`collect` 会重新初始化无线，完整 eFuse 调试日志保存在命令显示的 `/tmp/rtl8922a-*.log` 文件中。

确认同型号、同 PCB 的实际 RFE 类型后，使用 `rtl8922a-debug rfe 类型值` 做临时测试。可接受 `0..254`；编号不是通用默认值，8822CS 案例中的 `0` 不能直接视为 8922AE 的正确值。

恢复原始读取方式：

```sh
rtl8922a-debug rfe -1
```

重启也会恢复默认关闭状态。当前补丁尚未经过这批故障卡实测，能否修复取决于原始参数和硬件状态。

---

# NLnet XiGuaPi V3 (西瓜皮V3) Immortalwrt 自动构建

[![Build and Release](https://github.com/PEIT98/immortalwrt-xgp-auto-build/actions/workflows/build.yml/badge.svg)](https://github.com/PEIT98/immortalwrt-xgp-auto-build/actions/workflows/build.yml)

# 正在开发与调试中，小白误用

## 已知问题

1. 通过转接板连接的 PCIe 5G 模块在刷机后需要断电（直接拔DC插头，拔市电那头要多等几秒电容放电）一次，否则大概率找不到模块，转接板硬件原因导致模块在重启时不能正常下电。
2. 第一次使用本固件时，请使用 RKDevTool 刷入。请勿从其他固件的系统内直接升级到此固件，大概率会不兼容，包括同作者提供的 [LEDE 固件](https://github.com/zzzz0317/lede-xgp-auto-build/)。
3. 没有使用 RKDevTool 的条件的话，从其它固件升级，请不要在页面中直接升级，可以尝试 `dd` 命令，先进入网页管理->系统->启动项，禁用 docker、qmodem、openclash、passwall 等不影响系统启动、联网的服务，然后重启，使用 SSH 连接设备，将刷机包传输至 `/tmp` 目录，然后使用 `gzip -d immortalWrt-nlnet_xiguapi-v3-xxxx-squashfs-sysupgrade.img.gz` 命令解压 `.img.gz` 格式的固件为 `.img`，然后执行 `dd if=/tmp/immortalWrt-nlnet_xiguapi-v3-xxxx-squashfs-sysupgrade.img of=/dev/mmcblk0 bs=4M oflag=direct`（注意替换文件名），显示 `XXX+0 records in XXX+0 records out` 并可以执行新命令后，不要执行任何操作，直接拔电源重启，大概率能成功，不成功就只能用 RKDevTool 救了，**非常不建议使用本方案**。

## 说明

1. 第一次使用建议通过 RKDevTool 刷入，若通过 Web 刷入时提示不兼容请做好 USB 救砖准备再尝试
2. [Actions](https://github.com/zzzz0317/immortalwrt-xgp-auto-build/blob/main/.github/workflows/build.yml) 仅在手动运行工作流时拉取 [Immortalwrt](https://github.com/immortalwrt/immortalwrt) 代码编译并发布，平时可能会不定期手动触发更新
3. 默认 Wi-Fi SSID: `zzXGP`，密码: `xgpxgpxgp`
4. 默认 LAN 接口地址: `192.168.1.1`
5. 默认 root 密码: `xgpxgpxgp`，后续可能会变更
6. 使用 PCIe 模块在刷机后建议断一次电

## ⚠️ 免责声明

1. **项目性质说明**  
   本项目在 GitHub Actions 自动编译过程中：
   - 实时拉取 [Immortalwrt](https://github.com/immortalwrt/immortalwrt) 源码，和其它组件源码
   - 仅添加本仓库中的**公开可审查内容**

2. **设备风险自担**  
   - 任何因使用本项目固件导致的设备故障/变砖/安全问题
   - 任何因配置不当产生的网络风险或数据损失
   - 任何因第三方源码更新引发的兼容性问题
   **均与项目作者无关**，使用者需自行承担全部风险。

3. **使用限制条款**  

   ✅ **允许**：
   - 个人非商业用途
   - **免费、免授权**用于销售设备（预装固件）
   - **免费、免授权**用于技术服务（如刷机）

   ❌ **禁止**：
   - 将本仓库发布的固件文件作为付费商品单独销售

   ⚠️ **关键要求**：  
   当设备购买者/服务对象遇到：
   - 硬件故障
   - 网络配置问题
   - 非本项目导致的软件异常

   卖方/服务方必须自行提供技术支持，严禁将用户引导至本项目寻求帮助

4. 使用本项目即代表您**已充分理解并接受**：

    - 作者不对固件功能作任何明示/暗示担保
    - 任何商业使用产生的责任与作者无关
    - 违反使用条款造成的法律纠纷需自行承担

## 恰饭

[来个一键三连加关注呗](https://www.bilibili.com/video/BV1dU31ziEQf/)
