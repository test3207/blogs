---
title: '[单排日记][Linux磁盘占用问题排查]'
date: 2019-11-15 13:21:53
updated: 2025-10-31 21:34:00
tags: [Linux, Docker, DevOps, Troubleshooting, Redis]
---
## Linux 磁盘占用问题排查

生产服务器硬盘空间满，服务频繁挂掉。经了解，此问题一直存在。

基本上生产服务器不会有太多额外内容，一般就是 Nginx 日志文件使用默认配置，长期运行会占用一些空间，但可以手动配置最大日志占用空间；另一个可疑的地方是 Docker。

## 快速定位问题并临时修复

使用 `df -h` 查看磁盘占用，发现某 overlay 占用过高。立即执行 `docker rmi` 清理一些旧的 image，虽然只释放了 2GB 左右的空间，但足以暂时稳定生产服务。

当前 CI/CD 配置：自建 GitLab + 自建 Docker Registry，通过 Swarm 管理，每份 image 都会在生产环境拉取。计划添加定时任务，清理 2 天前的 image。

> **Note (2019):** 当时使用 Docker Swarm 进行容器编排。现代生产环境更多采用 Kubernetes。对于 Docker Registry 清理，建议使用 Registry 的垃圾回收机制（`registry garbage-collect`）而非仅依赖定时任务。

理论上问题不大（除非 2 天内频繁发布数百个版本，虽然按照当前开发规范，这种情况理论上可能发生）。后续如果需要改进，需要考虑权限管理问题。

## 进一步分析磁盘占用情况

```bash
docker system df -v
```

通过命令查看 image、container 和 volume 的具体占用情况。

Image 占用异常的情况，可能是由于不打 tag 而选择定时任务清理，配合开发流程上的缺陷共同导致。

Container 非常轻量化，很多都是以字节为单位，基本不会出现问题。

Volume 常见问题包括：日志文件、使用容器时不指定卷名导致混乱，或者数据库文件占用过大。

发现一个 19GB 的 volume，标识为 `prod_redis`。自建 Redis 开启了 AOF 持久化，但未配置自动重建，导致 AOF 文件持续增长。

解决方案如下：

首先清理无用资源：

```bash
docker system prune -a
```

清理无用的 image 和 container。

然后通过 SSH 或 `docker attach` 进入 Redis 服务：

```bash
redis-cli BGREWRITEAOF
```

重建 AOF 文件。整个重建过程会先生成新的 AOF 文件，再删除旧的，因此如果空间完全不足，需要先扩容硬盘。手动执行的意义在于确认剩余空间是否足够，并重置自动重建的阈值。自动重建是根据上一次重建的文件大小的比例来确认重建时机的，当前 AOF 文件过大，即使启用自动重建也可能达不到阈值。

最后修改 Redis 启动命令：

```bash
redis-server \
--appendonly yes \
--auto-aof-rewrite-percentage 200 \
--auto-aof-rewrite-min-size 5gb
```

设置合适的重建时机。由于该 volume 未命名，且 Redis 更新频率低，影响不大。

> **Note (2025):** Redis 7.0+ 引入了 Multi-part AOF 机制，可以更高效地管理 AOF 文件。现代部署建议考虑使用 RDB + AOF 混合持久化模式，并配置合理的 `maxmemory-policy`。
