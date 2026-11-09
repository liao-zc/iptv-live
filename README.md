# IPTV 直播源

## 使用说明

主订阅地址：

```text
https://raw.githubusercontent.com/liao-zc/iptv-live/main/IPTV_ALL.m3u
```

备用订阅地址（主地址访问困难时可尝试）：

```text
https://testingcf.jsdelivr.net/gh/liao-zc/iptv-live@main/IPTV_ALL.m3u
```

在播放器中添加远程 M3U 订阅并开启自动刷新。备用地址可能有缓存延迟。

其他直播源订阅入口：

| 来源 | 订阅地址 | 上游运行计划 | M3U 文件最近更新时间（北京时间） |
| --- | --- | --- | --- |
| Guovin/iptv-api | <https://guovin.github.io/iptv-api/result.m3u> | 项目提供手动生成工作流，未配置固定定时更新；以实际上游文件更新为准。 | 2026-10-12 11:26:19 |
| Guovin/TV | <https://raw.githubusercontent.com/Guovin/TV/gd/output/result.m3u> | 项目未配置固定定时更新；以实际上游文件更新为准。 | 2026-08-27 14:06:24 |
| iptv-org 中国 | <https://raw.githubusercontent.com/iptv-org/iptv/master/streams/cn.m3u> | 上游工作流每日 00:00 UTC（北京时间 08:00）运行。 | 2026-11-07 08:10:07 |
| iptv-org 台湾 | <https://raw.githubusercontent.com/iptv-org/iptv/master/streams/tw.m3u> | 上游工作流每日 00:00 UTC（北京时间 08:00）运行。 | 2026-11-05 10:19:33 |
| YanG-1989/m3u | <https://raw.githubusercontent.com/YanG-1989/m3u/main/Gather.m3u> | 未找到上游公开的固定更新时间；以实际上游文件更新为准。 | 2026-09-18 18:28:52 |
| fanmingming/live（IPv6） | <https://raw.githubusercontent.com/fanmingming/live/main/tv/m3u/ipv6.m3u> | 未找到该播放列表的固定更新计划；项目公开定时任务为节目单更新，不代表直播源更新时间。 | 2025-05-09 20:49:35 |

## 更新说明

本仓库 M3U 文件最近更新时间（北京时间）：**2026-11-09 10:16:17**。

本仓库每小时自动更新一次，GitHub Actions 计划在每小时第 17 分钟（UTC）启动，即北京时间每小时的 17 分运行；GitHub Actions 可能因平台排队而延迟。手动更新请进入 GitHub 仓库的 **Actions → Update IPTV playlist → Run workflow**。

无效频道会暂时注释并继续复测；检测恢复后会自动重新启用。
