---
title: "[工具][密码管理工具 Bitwarden 食用指北]"
date: 2020-02-04 09:55:05
updated: 2025-10-31 21:34:00
tags: [Bitwarden, Password Manager, Docker, Rust, Self-hosted, Security]
---

## 简介

迫于年纪大了，记不住了，只好新安排了这么一款密码管理软件 [Bitwarden](https://bitwarden.com/)。

我看中的原因主要有这么几点：

首先要保证安全，代码开源 + 可以自建；目前来讲也不会把很重要的密码放在上面，自建 + 锁出口端口 + 必要出口端口监控先观察一段时间；

然后管理方便，Chrome 直接有插件，PC、手机也有对应的客户端，能做到自动填充而不需要手动复制粘贴；

然后也支持密码本体的一些有用的功能，比如按条件生成密码，以及支持上传文件（密钥）；

## 自建

原版用了 C# + MSSQL，系统占用较高，有人用 Rust 重构了一份，[rs 版](https://github.com/dani-garcia/vaultwarden)本身也是开源的。目前用这个版本有一些地方和原版不一样，不过无关紧要。rs 版跑闲置状态下 CPU 占用基本为 0，内存占用 25MB 左右。

Docker 下两行命令解决：

```bash
docker pull vaultwarden/server:latest
docker run -d --name bitwarden -v /bw-data/:/data/ -p 80:80 vaultwarden/server:latest
```

端口号自行替换。

因为原版里要求手动指定证书，rs 版也提供了比较详细的证书配置指引。我本来以为程序对证书有什么方面的需要，但是研究了一下发现没有必要，证书仍然是可以统一配置在 Nginx 层的，对内端口不用改配置。

## 使用

你可以使用官方的版本，不过免费版的有一些限制；

也可以按上述说明自建，rs 版本的注册直接就是高级会员，听说官方的 Docker 不是，搞不清楚，反正官方的我没用；提示：官方的安装流程中，会下载 Shell 脚本，每一步生成的脚本里，curl 统统都要单独加 `-L` 选项，不然是跑不通的，原因在于指定的链接重定向了；

首次使用先通过自建的网页版注册账号，设置主密码。然后下载各端软件使用。

Chrome 直接搜插件就好了，PC 版即使搭了梯子也可能会出现网络问题，我这里是通过 Windows Store 下载的，Android 在 Google Play 也有。

各端的 UI 基本一致，都是左上角设置服务地址（也就是自建时暴露的地址），输入主密码登录即可。软件本身自带中文，细节自行探索。

> **更新说明（2025）**：文中提到的 bitwarden_rs 项目已更名为 [Vaultwarden](https://github.com/dani-garcia/vaultwarden)，Docker 镜像也已更换为 `vaultwarden/server`。截至 2025 年，Vaultwarden 仍在活跃维护，官方 Bitwarden 性能也已大幅优化。建议使用最新版本并启用两步验证以提升安全性。
