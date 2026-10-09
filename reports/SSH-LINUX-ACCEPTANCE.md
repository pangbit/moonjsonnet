# SSH Linux 分阶段验收

日期：2026-10-09。用户授权使用现有 SSH 认证登录 `root@<ENVIRONMENT_SERVER_01>`，
在独立临时目录验收并保留本地提交；没有推送、部署、发布或新安装。
SSH 保持 `BatchMode=yes`、严格主机校验、10 秒连接超时与有界存活检测。

## 实际环境与快照

Mac `mini.local` 于 UTC 01:53:15 执行健康检查；SSH 于 01:53:22 返回
UID 0、Linux 6.17.0-14-generic x86_64，退出码 0、耗时 0.30 秒。
远端为 Ubuntu 24.04.4 LTS，GCC 13.3.0、glibc 2.39、util-linux script 2.39.3。
现有 `/root/.moon` 为 Moon 0.1.20260920 / moonc v0.10.14+7d59c7ec9。
现有 Go 为 1.26.0 / 1.26.5，没有用于固定参考构建。

干净源码快照绑定 `ff1a11c`，其产品实现与 `3d11b45` 相同；新增验收记录脚本。
固定 Go 提交 `67968688d9952f50662e979fab1bef889d0d3e57`，C++ 提交
`bbb38f1020be1f5aed560928fb839b2c448cefb4`，均保留干净 Git 身份。
快照只复制 Git objects/refs/HEAD/shallow 等必要数据，没有复制凭据或 hooks。

远端目录：`${LOCAL_PATH_021}`。
源码及冻结基准归档 SHA-256：
`8123766f25e6edf8d1db54b07cbe3c6e8f35851ec1339c88d34a61a5480dddab`。
Mac 证据目录：
`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-linux-transfer-.3375.4fd8df5c`。

将既有 Linux 工具链复制至该目录的 `toolchain`；验收用
`setpriv --reuid=65534 --regid=65534 --clear-groups` 执行，避免 root 改变权限测试。
只调整新临时目录归属，不修改账户、服务、SSH 配置、安全策略或原安装。
没有覆盖 HOME/CODEX_HOME。源码、缓存、产物均写临时副本。

旧方案中的 async 0.22.1 不支持当前脚本使用的 `allow_exist`，实际本机脚本
已解析到缓存中的 0.22.4；本次固定复用该版本。缓存 zip SHA-256 为
`2ffdb85cb229cfe9219161a7f2b959215a79a0d75b7e642cb346713f168a1457`，
与已有 registry 元数据一致。native 产品模块没有新增依赖。

## 原生与冻结检查

首轮 21 项实际执行，18 项通过；info/doc/archive 因临时工具链漏复制
mooninfo/moondoc/mooncake 失败。补齐现有程序后，分别重跑通过，原失败日志保留。

| 实际 Linux 检查 | 结果 |
| --- | --- |
| 普通/release native check --deny-warn | 均通过 |
| 普通/release native test | 各 313/313 |
| release build、fmt、fmt --check | 通过 |
| info、doc、源码状态与 diff --check | 补齐工具后通过；源码干净 |
| 宿主/multi/import/diagnostic/stack | 97、26、20、20、20 全通过 |
| 依赖/参数 | 33+13、30/30 |
| 冻结 Evaluator/AST | 21/21、173/173 |
| lint CLI/格式化宿主/冻结节点 | 通过；节点 56/56 |
| 冻结调试器/诊断 API | 43/43、1323/1323 |
| 嵌入示例与原测试中的示例 | 通过 |
| 独立 archive 消费者 | 29/29 |
| 隔离 ASan | 实际退出0；313原生测试及完整既有宿主/冻结检查通过 |

冻结 Evaluator 21/21 是本地预期检查，不是实际 Go 的 20/21；冻结诊断、AST、
调试器和节点结果也不代替 Linux 重新构建的 Go 对照。
`tools/linux-native-acceptance.mbtx` 保存每项命令、UTC 时间、退出码和 stdout/stderr；
复验另写 `evidence/retries`，不覆盖首次失败。

ASan副本为本次目录内`tmp/moonjsonnet-asan-.33905.64737905`。
414个源码、测试、工具及既有文档逐文件哈希与干净快照相同；只排除原runner
不复制的README.md及有意加入instrumentation的moon.pkg。沿用原合同关闭
泄漏检测。安装运行时及普通工具链副本SHA-256相同：
`a5e00ff1cb24c75311c56d4b53341d72c0145c0127d3571d889de72e951e4966`。

完整证据已取回上述Mac目录：`evidence.tar.gz`，SHA-256
`94beb671a6f5de5df35b3fbb22e6fed0d68c99241cf0d8c0f1e7c1566dbbcece`。
归档及全部76个证据文件的校验实际通过；包含首轮21项日志、四项复验、12份
完整native/ASan冻结JSON报告、源码/二进制哈希和最终summary.json。
Mac另保存prepare尝试、下载校验、运行时哈希及local-validation.json；其中准备
错误为实际工具输出摘录，不将其冒充完整流。所有验收进程已结束。
一次双来源SCP下载被自动审批以潜在远端目标写入风险拒绝，未执行；依审查
建议改为单来源、明确本地目标后成功，不绕过权限拒绝。

准备阶段还保留了 Git 所有者保护、缺少缓存标记/标准库 bundle 的启动失败。
Git 归属仅在新临时目录修正，没有添加全局 safe.directory。
首次 Go 缓存源目录解包因只读目录权限失败；改为仅复制七个已缓存的模块归档
与校验元数据，在新目录以同一低权限身份成功展开，没有修改系统权限。

## 未运行与待批准项

固定 Go 1.24.0 在已检查的安装前缀和 toolchain 缓存中缺失。因此 Linux 的
整体 CLI/Evaluator/lint、实际 Go 诊断/TTY/参数错误/字符/I/O/标准库分支、
格式化和 Go 相关 ASan 对照均未运行，不计通过。
原 macOS 18 CLI + 1 Evaluator + 1 lint 失败仍未获例外批准；没有删输入或接受差异。

固定参考的七个模块已从 Mac 缓存复制，ziphash 对照原 go.sum。
Mac 使用已有 Go 1.24.0、GOWORK=off、GOPROXY=off 实际离线构建 CLI 退出 0。
Linux 待批准的最小工具安装为
[官方 Go 1.24.0 linux/amd64](https://go.dev/dl/#go1.24.0)，归档
`https://go.dev/dl/go1.24.0.linux-amd64.tar.gz`，官方 SHA-256：
`dea9ca38a0b852a74e81c26134671af7c0fbe65d81b0dc1c5bfe22cf7d4c8858`。

获批后拟在本次目录的 `go-1.24.0` 展开，先校验归档和实际版本；只为本次进程
设置 PATH/GOCACHE/GOMODCACHE，继续禁止模块代理与自动工具链下载。不覆盖
系统 Go、修改 profile 或持久凭据。当前没有下载或安装该归档。
可用模块缓存位置为 `gomodcache-download`，首次失败副本另保留于 `gomodcache`。

原 C++ 上游语言 runner 另需要 rg；远端 `which rg` 退出 1，C++ Linux 二进制
未构建，因此 303 项 Linux C++ 对照也未运行。g++/make 已有；该工具缺口不
影响上述 21 项或固定 Go runner，不自行安装 rg。
远端 CI 与发布继续不在本次授权范围，整体目标未标记完成。

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. No tests were rerun on the privacy-rewritten commit.
