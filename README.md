# IPTV 直播源

## 更新说明

本仓库 M3U 文件最近更新时间（北京时间）：**2026-11-09 10:16:17**。

本仓库每小时自动更新一次，计划于北京时间每小时第 17 分启动；GitHub Actions 可能因平台排队而延迟。手动更新请进入 GitHub 仓库的 **Actions → Update IPTV playlist → Run workflow**。

无效频道会暂时注释并继续复测；检测恢复后会自动重新启用。

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

| 来源 | 订阅地址 | 更新时间 |
| --- | --- | --- |
| Guovin/iptv-api | <https://guovin.github.io/iptv-api/result.m3u> | 2026-10-12 11:26:19 |
| Guovin/TV | <https://raw.githubusercontent.com/Guovin/TV/gd/output/result.m3u> | 2026-08-27 14:06:24 |
| iptv-org 中国 | <https://raw.githubusercontent.com/iptv-org/iptv/master/streams/cn.m3u> | 2026-11-07 08:10:07 |
| iptv-org 台湾 | <https://raw.githubusercontent.com/iptv-org/iptv/master/streams/tw.m3u> | 2026-11-05 10:19:33 |
| YanG-1989/m3u | <https://raw.githubusercontent.com/YanG-1989/m3u/main/Gather.m3u> | 2026-09-18 18:28:52 |
| fanmingming/live（IPv6） | <https://raw.githubusercontent.com/fanmingming/live/main/tv/m3u/ipv6.m3u> | 2025-05-09 20:49:35 |

上表中的时间均为北京时间，按对应 M3U 文件的最近更新时间记录。
