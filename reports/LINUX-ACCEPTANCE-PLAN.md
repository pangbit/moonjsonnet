# Linux 隔离验收方案与当前授权边界

2026-10-09 更新：用户已授权 SSH 到现有 Ubuntu x86_64 主机；当前采用独立
临时源码/工具链副本，已有固定 MoonBit，可独立完成 native 检查。实际结果及
已批准的临时Go安装、实际首轮对照及amd64数值修复见
[SSH 分阶段验收](SSH-LINUX-ACCEPTANCE.md)。rg不再需要安装。下文保留
2026-10-08 的容器方案与当时授权历史，不再表示当前 Linux 完全未运行。

最新完整重验绑定`daece32`：Linux普通/release各315/315，固定Go八组对照
全部执行，整体CLI1131/1150。原18项之外保留NaN索引冻结ARM64成功预期
与AMD64真实错误及相对诊断文件名差异；定向20/20不替代该失败。
同一提交相关ASan已通过315测试、宿主97、字符72、原生错误384、CLI4095、
API1323和20数值输入，417副本文件哈希一致；完整归档106文件已验证，远端
重型时段于UTC04:37:27释放。本机性能安静窗口期间没有新开编译/测试/归档。

日期：2026-10-08。本文件给出安装授权前可审阅的方案。已完成 Docker 的只读
元数据核实，没有安装软件、拉取镜像、创建容器或运行 Linux 验收。
macOS 的通过记录不算作 Linux 验收。

## 已核实镜像与权限

普通权限首次清单读取被以下精确边界阻止：

```text
permission denied while trying to connect to the docker API at unix://${LOCAL_HOME_01}/.orbstack/run/docker.sock
```

父会话随后明确要求读取已有镜像名称；申请扩大权限执行只读 `docker images`、
`docker image inspect` 和 `docker image history`，均获自动审批。实际清单：

| 已有镜像 | 短 ID | 大小 |
| --- | --- | --- |
| postgres:17.11 | 97432f980da1 | 477 MB |
| postgres:18.6 | d8a40176c29a | 480 MB |
| clickhouse/clickhouse-server:26.4 | 25f124ed3008 | 805 MB |
| apachepulsar/pulsar:4.2.4 | 8f53bffa4b86 | 476 MB |

拟复用 `postgres:17.11`：

- 平台：`linux/arm64`。
- 镜像 ID：`sha256:97432f980da100ebd3e419711efee84e1e97a966d62c035286a07f239ddb4d9c`。
- 已有仓库摘要：`postgres@sha256:d74eeac9a635390a49bc21bd49fccd973de707e2a53a76ac49b552b8712ec46f`。
- 构建历史最底层记录 `debian.sh --arch 'arm64' ... 'trixie'`，确认基于 Debian
  trixie；未创建容器读取 `/etc/os-release`，也未重新检查容器内命令可用性。

历史 CONTINUATION4 记录验收环境缺少 gcc/git/curl；最终安装前先检查拟用镜像
中的实际工具，复用可用项。只读审批不授权软件安装、容器创建或镜像拉取。
安装授权由父会话集中请求；未经授权不执行下面的环境方案。

## 官方工具来源与用途

系统工具只取 Debian trixie 官方仓库，安装最小集合及正常依赖，不另装 C++ 编译器：

| 包 | 用途与官方来源 |
| --- | --- |
| gcc | MoonBit native 生成代码和宿主 C 编译；[Debian gcc](https://packages.debian.org/trixie/gcc)，依赖 gcc-14 |
| libc6-dev | C 系统头文件与链接库；[Debian libc6-dev](https://packages.debian.org/trixie/libc6-dev) |
| binutils | 汇编、链接等 native 构建工具；[Debian binutils](https://packages.debian.org/trixie/binutils) |
| git | 提交身份核实及工具链依赖；[Debian git](https://packages.debian.org/trixie/git) |
| curl | 下载固定官方工具链文件；[Debian curl](https://packages.debian.org/trixie/curl) |
| ca-certificates | TLS 证书验证；[Debian ca-certificates](https://packages.debian.org/trixie/ca-certificates) |
| unzip | 独立 archive 消费者展开；[Debian unzip](https://packages.debian.org/trixie/unzip) |
| perl | 现有验收脚本的 `shasum`；[官方 arm64 文件清单](https://packages.debian.org/trixie/arm64/perl/filelist)含 `/usr/bin/shasum` |

C++ 仓库在拟定 Linux Go 验收中只作格式化输入，不构建 C++ 解释器，因此此
方案不含 g++、make 或整套 build-essential。宿主另用已有 clang++/make 实际
通过 C++ 上游语言303/303，不算 Linux 证据；若需同一个旧上游语言 runner，
它要求 Linux C++ 二进制，应单列所需工具与授权。具体包版本在容器验收报告中记录，不把网页版本当作
已安装版本。

MoonBit 使用[官方下载页](https://www.moonbitlang.com/download)的
`https://cli.moonbitlang.com/install/unix.sh`。安装器已只读下载到标准输出审阅，
未执行；确认它接受位置参数版本、支持 `MOON_HOME` 前缀，并将 Linux aarch64
映射到 `linux-aarch64`。固定 CI 版本为 `0.10.14+7d59c7ec9`。
2026-10-08 只读 HEAD 核实以下两个官方固定文件均返回 HTTP 200：

- [固定 Linux arm64 工具链](https://cli.moonbitlang.com/binaries/0.10.14%2B7d59c7ec9/moonbit-linux-aarch64.tar.gz)：106304278 字节。
- [固定 core](https://cli.moonbitlang.com/cores/core-0.10.14%2B7d59c7ec9.tar.gz)：1782652 字节。

响应记录保留期截止 2026-11-20；只检查头部，没有下载归档。授权执行时仍需
重新核实固定文件可用性及官方提供的校验值，并核对实际 `moon 0.1.20260920`、
`moonc v0.10.14+7d59c7ec9`。固定构建失效则报告阻碍，不静默改用最新版。

Go 使用[官方归档](https://go.dev/dl/)中的
[Go 1.24.0 Linux arm64](https://go.dev/dl/go1.24.0.linux-arm64.tar.gz)。
官方 SHA-256：
`c3fa6d16ffa261091a5617145553c71d21435ce547e44cc6dfb7470865527cc7`。
当前未下载或安装。参考源码继续固定
`67968688d9952f50662e979fab1bef889d0d3e57`，使用 `GOWORK=off`、`GOPROXY=off`。

## 隔离位置和执行方式

授权后从上述已有完整镜像 ID 创建一次性容器
`moonjsonnet-linux-acceptance-<唯一后缀>`，无需拉取新镜像。显式覆盖入口为工具
执行程序，不启动 PostgreSQL，不发布端口，不挂载任何现有数据库目录。
系统包只写一次性容器层；MoonBit/Go 位置分别为：

```text
MOON_HOME=/opt/moonjsonnet-acceptance/moon
Go prefix=/opt/moonjsonnet-acceptance/go
Source copy=/work/moonjsonnet
Host evidence=${LOCAL_PATH_016}<唯一后缀>
```

宿主仓库只读挂载，复制干净提交源码到容器工作副本；生成文件、缓存、构建
产物均写副本或容器临时目录。可复制现有固定参考与 MoonBit async 0.22.1
依赖源码缓存，必须重新构建 Linux 二进制。不得覆盖 `HOME`/`CODEX_HOME` 或改
宿主安装运行时。宿主仅新增上述临时证据目录，不使用特权容器或修改安全设置。
容器自动清理；官方镜像自带的空匿名卷随本次容器清理，不触碰其他容器/卷。

## 验收与记录

先记录实际 `/etc/os-release`、架构、镜像 ID/摘要、包和工具版本、源码提交、
语料及二进制哈希，再执行与 macOS 同级的 native 普通/release check（deny-warn）、
test、release build、info/fmt、三个原有示例、独立 archive 消费者及固定 Go 整体
CLI/Evaluator/lint/诊断/AST/调试/格式化对照。完整报告与日志写宿主证据目录。
仅实际执行并通过的检查计通过；所有旧失败和新增失败保留，不以宿主结果代替。

当前宿主干净实现 `3d11b45` 的 native双模式313/313、API1323/1323、CLI字节
4095/4095、真实终端25/25、参数错误65/65、字符72/72、I/O45/45、原生诊断
384/384和断点43/43，整体CLI
1132/1150、Evaluator 20/21、lint 409/410。Linux 应按相同输入保留原 18+1+1
项未接受差异，并独立报告平台产生的差异。完成并保存证据后清理本次容器。
新增固定295项标准库错误审计为290/295，其5项参考崩溃属于原18项，不删除。
当前剩余环境阻碍是安装/创建隔离容器尚无授权；只读元数据已核实。

新增 TTY runner 在 Linux 使用 util-linux `script`，先检查镜像中的已有命令。
该分支目前未执行；缺少时报告所需授权，不安装。父会话初次安装请求未包含
unzip/perl，两者仍未获授权，也不得自行安装。

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. No tests were rerun on the privacy-rewritten commit.
