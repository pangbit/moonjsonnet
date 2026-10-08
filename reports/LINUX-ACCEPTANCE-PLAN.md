# Linux 隔离验收方案与当前阻碍

日期：2026-10-08。本文件为安装授权前的具体方案，没有执行安装、拉取镜像或
创建新环境。宿主开发继续，不将 macOS 的通过记录算作 Linux 验收。

## 已知状态与权限边界

历史 CONTINUATION4 检查确认本机 Linux arm64 Docker 可用，已有隔离镜像
缺少 gcc/git/curl。本阶段重新执行只读清单命令：

```text
docker images --format '{{.Repository}}:{{.Tag}} {{.ID}} {{.Size}}'
permission denied while trying to connect to the docker API at unix://${LOCAL_HOME_01}/.orbstack/run/docker.sock
```

没有以扩大权限重试 Docker。当前镜像的发行版、镜像摘要及现有 MoonBit/Go
路径未重新核实；不能把下面的 Debian 包版本假定为当前镜像实际版本。
父会话按需请求 Docker 环境读取和隔离安装授权。此前 Moon/Go 回归脚本的
现有依赖缓存锁请求已获自动审批，与创建 Linux 环境或安装软件无关。

## 拟用官方来源

1. C 编译器、系统头文件及链接器取自已有镜像所属发行版的官方仓库。
   如果确认是 Debian bookworm，使用官方 gcc、libc6-dev、binutils；
   Debian [gcc 包](https://packages.debian.org/bookworm/gcc)明确依赖 gcc-12，
   [build-essential](https://packages.debian.org/bookworm/build-essential)
   列出 gcc 与 libc6-dev 等构建依赖并提供 arm64 包。只做 MoonBit native
   验收时不需要额外 C++ 编译器；C++ 仓库只是既有格式化输入。
2. git、curl、ca-certificates 同样取自已核实发行版的官方仓库，分别用于
   工具链依赖/提交身份、官方文件下载和 TLS 验证。若已有可用工具则复用。
3. MoonBit 取自[官方下载页](https://www.moonbitlang.com/download)列明的
   `https://cli.moonbitlang.com/install/unix.sh` 来源，先下载并审阅安装器，
   使用仓库 CI 中固定的 `0.10.14+7d59c7ec9` 参数。实际版本必须核对
   `moon 0.1.20260920` 和 `moonc v0.10.14+7d59c7ec9`；若固定 Linux arm64
   构建不可用，报告阻碍，不静默使用最新版。官方提供的 archive/binary
   SHA-256 文件存在时先校验。
4. 实际 Go 对照使用[官方归档](https://go.dev/dl/)的 Go 1.24.0 Linux arm64：
   `https://go.dev/dl/go1.24.0.linux-arm64.tar.gz`，官方 SHA-256 为
   `c3fa6d16ffa261091a5617145553c71d21435ce547e44cc6dfb7470865527cc7`。
   固定 Go 参考源码继续用提交 `67968688d9952f50662e979fab1bef889d0d3e57`。

## 隔离位置、用途及验收

获授权后，从核实的已有镜像摘要创建一次性验收容器，拟命名
`moonjsonnet-linux-acceptance-<唯一后缀>`。C 工具及其包数据库只写容器文件系统；
MoonBit/Go 工具链分别放在容器内 `/opt/moonjsonnet-acceptance/moon`、
`/opt/moonjsonnet-acceptance/go`。安装器支持自定义前缀需在执行前审阅确认；
否则使用容器内独立验收用户的工具目录，不修改宿主工具链。

宿主仓库只读挂载，复制当前干净源码到容器 `/work/moonjsonnet`；所有生成文件、
缓存和构建产物只写该副本与容器临时目录。仅将报告/哈希/日志写入宿主
`${LOCAL_PATH_016}<唯一后缀>`。不推送、不发布，不以特权容器或
修改宿主安全设置解决环境问题。

用途是 Linux native 的真实 check、普通/release test、build、三个示例、
独立 archive 消费者和固定 Go 行为/诊断/格式化整体对照。记录发行版、架构、
镜像摘要、实际工具版本、源码提交、二进制和语料哈希；所有既有失败保留。
只运行过的检查计通过。报告保存后清理本次容器；没有安装授权前不执行本方案。

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. No tests were rerun on the privacy-rewritten commit.
