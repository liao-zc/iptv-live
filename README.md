# IPTV 直播源

## 更新说明

本仓库 M3U 文件最近更新时间（北京时间）：**2026-11-25 08:49:35**。

`reports/latest.json` 会记录本次验证节点：默认是 `github-hosted-overseas`（GitHub 托管 runner，海外节点），设置仓库变量 `MAINLAND_RUNNER_READY=true` 并使用在线的大陆 runner 时为 `mainland-self-hosted`。自动更新默认使用 `ubuntu-latest`，保证每天持续更新；`update-local.ps1` 用于本机大陆网络手动更新，会先检查出口 IP，不是中国大陆会拒绝执行。

无效频道会暂时注释并继续复测；检测恢复后会自动重新启用。

### 验证节点切换

默认（`MAINLAND_RUNNER_READY` 未设置或为 `false`）：使用 `ubuntu-latest`，验证节点为海外，但每天自动更新，`reports/latest.json` 的 `node` 记录为 `github-hosted-overseas`。

要切换到大陆节点：

1. 注册标签为 `self-hosted, linux, x64, mainland` 的 runner，并确认在线；
2. 在仓库 `Settings → Secrets and variables → Actions → Variables` 新建变量 `MAINLAND_RUNNER_READY`，值为 `true`；
3. 下一次定时任务或手动触发会在大陆 runner 上运行，`node` 记录为 `mainland-self-hosted`。

如果变量为 `true` 但 runner 不在线，任务会排队；把变量改回 `false` 即可恢复 `ubuntu-latest` 自动更新。

### 本机手动更新（大陆网络）

适合没有大陆 runner、但本机在中国大陆的情况。确认未开启 VPN/代理后，在仓库根目录运行：

```powershell
.\update-local.ps1
```

如果系统禁止运行 PowerShell 脚本，可改用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\update-local.ps1
```

脚本会先检查出口 IP；如果不是中国大陆（或无法确认），会直接终止，避免用海外节点验证。检查通过后，依次执行单元测试、同步 Guovin 候选源、探测并解码验证、生成 M3U、更新 README 时间戳，最后提交并推送。默认提交信息带 `[skip ci]`，避免 push 后立刻触发默认的海外节点任务，覆盖你刚生成的大陆验证结果。

常用参数：

- `-CheckOnly`：只检查 Python、ffmpeg、ffprobe 和出口 IP，不执行更新。
- `-NoPush`：只生成文件，不提交、不推送。
- `-RunCi`：提交后允许 GitHub Actions 触发（默认会跑海外节点，可能覆盖本机大陆验证结果；仅在大陆 runner 在线时建议使用）。
- `-Node mainland-shanghai`：指定 `reports/latest.json` 中记录的探测节点名称，默认 `mainland-local`。
- `-AllowNonMainland`：出口 IP 不是/无法确认中国大陆时仍继续（不推荐）。
- `-Python`、`-Ffprobe`、`-Ffmpeg`：手动指定工具路径；不指定时脚本会自动查找。

需要 Python 3.10+、ffmpeg、ffprobe、git。脚本会自动把 ffprobe/ffmpeg 所在目录加入当前会话的 PATH。

GitHub Actions 的手动入口（**Actions → Update IPTV playlist → Run workflow**）默认在 `ubuntu-latest` 上运行；`MAINLAND_RUNNER_READY=true` 且大陆 runner 在线时，在大陆节点上运行。

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
| Guovin/iptv-api | [打开订阅](https://guovin.github.io/iptv-api/result.m3u) | 2026-10-12 11:26:19 |
| Guovin/TV | [打开订阅](https://raw.githubusercontent.com/Guovin/TV/gd/output/result.m3u) | 2026-08-27 14:06:24 |
| iptv-org 中国 | [打开订阅](https://raw.githubusercontent.com/iptv-org/iptv/master/streams/cn.m3u) | 2026-11-25 08:11:07 |
| iptv-org 台湾 | [打开订阅](https://raw.githubusercontent.com/iptv-org/iptv/master/streams/tw.m3u) | 2026-11-05 10:19:33 |
| YanG-1989/m3u | [打开订阅](https://raw.githubusercontent.com/YanG-1989/m3u/main/Gather.m3u) | 2026-09-18 18:28:52 |
| fanmingming/live（IPv6） | [打开订阅](https://raw.githubusercontent.com/fanmingming/live/main/tv/m3u/ipv6.m3u) | 2025-05-09 20:49:35 |

上表中的时间均为北京时间，按对应 M3U 文件的最近更新时间记录。
