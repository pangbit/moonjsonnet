# SSH Linux 分阶段验收

日期：2026-10-09。用户授权使用现有 SSH 认证登录 `root@<ENVIRONMENT_SERVER_01>`，
在独立临时目录验收并保留本地提交；没有推送、部署或发布。
后续用户明确批准临时安装官方 Go 1.24.0；没有覆盖系统安装。
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

## 实际固定 Go 首轮对照

用户已明确批准临时安装
[官方 Go 1.24.0 linux/amd64](https://go.dev/dl/#go1.24.0)。官方归档 SHA-256：
`dea9ca38a0b852a74e81c26134671af7c0fbe65d81b0dc1c5bfe22cf7d4c8858`。
远端 curl 首次因 TLS 连接超时退出28，原日志保留；随后 Mac 通过验证 HTTPS
下载相同官方归档，传输后再次核对哈希，在本次目录 `go-1.24.0` 展开。
实际版本为 `go version go1.24.0 linux/amd64`。固定参考的七个缓存模块与原
go.sum 校验相同，CLI/jsonnetfmt/jsonnet-deps 均离线构建成功。
所有适配器的构建元数据确认固定提交、Go1.24.0、linux/amd64 和干净参考。
仅本次进程使用 PATH/GOCACHE/GOMODCACHE；模块代理和自动工具链下载关闭。
没有修改系统 Go、profile、安全设置或持久凭据。

全部21个实际Go runner已执行并结束，绑定干净源码 `ff1a11c`：

| 实际 Linux Go 检查 | 首轮结果 |
| --- | --- |
| API完整诊断 / CLI完整字节 | 1323/1323、4095/4095 |
| 标准库当前原生错误 / OS I/O / TTY / 参数错误 | 384/384、45/45、25/25、65/65，另品牌帮助2项 |
| 字符三入口 | 69/72；三个NaN字符转换平台差异 |
| 整体CLI / 冻结原错误295项 | 1114/1150、288/295 |
| Evaluator / lint | 20/21、409/410；原各一项失败保留 |
| 调试器 / AST / 参数 | 43/43、173/173、30/30 |
| 格式化 / 上游格式化 / 节点 / jsonnetfmt | 736/736、178/178、56/56、255/255，另品牌4项 |
| lint CLI / 依赖 / 成员注册 | 两二进制各23项、33+13、163注册；注册不表示行为通过 |

整体CLI保留原18项失败，另发现18项架构差异，涉及融合舍入、amd64 exp/log、
分数精度格式化及非有限/边界整数转换。295原错误中保留原5项失败，另发现两个
索引转换诊断差异。字符NaN在Go amd64转换为非法rune并输出替换字符；旧实现
固定采用ARM64的零结果。未删除输入、放宽精度或接受参考崩溃。

完整首轮日志和报告位于 `go-evidence`；取回Mac的 `go-initial-evidence.tar.gz`
SHA-256为 `0085c7d791194ed287e89f052d8643740558fe89d8036304a4f66234d814ef07`。
归档及其中21份完整报告的逐文件校验已通过，另外保存lint CLI原始results.json。

C++参考已用现有g++/make在Linux构建；原32语言输入、241格式化断言和30错误
输入仍为303/303。临时Git枚举与原rg选择在Mac/Linux均为相同30文件、相同SHA；
本地提交 `9d061cf` 移除runner对rg的额外依赖，没有安装rg。日志、二进制和runner
哈希另保存在 `go-evidence/cpp`，旧源码快照保持干净。

## 数值修复与下一检查点

本地提交 `62b06da` 按架构定义NaN、无穷及2^63转换，避免C未定义转换；字符
范围检查仍先于截断，代理项仍替换。泛型数学在ARM64保留融合舍入，在amd64
保留分步舍入；amd64指数按Go专用算法和CPU的AVX/FMA能力选择实现，log保留
参考汇编的运算顺序及次正规数路径。格式化分数精度调用对应的amd64算法。
新增精确架构断言，不使用容差，原冻结 `tests/` 文件未改。

Mac ARM64普通/release各315/315；零警告check、release build、info、fmt及
diff --check通过。只有内部number包接口新增，根公开接口未变化。
新Linux快照为 `source-numeric-62b06da`，归档SHA-256：
`3cb07b72e0bfbefb20167cf98a4e094c09f92584d9f7463574b22584f8140cb7`。
旧快照和首轮报告保留；定向数值检查20/20，与固定Go完整stdout/stderr/退出码
相同，包含18个新增整体数值失败及两个原错误审计差异。只用原输入，不加容差。
首个临时runner误构建全模块，180秒超时，未进入比较；确认UID65534无残留
进程后改为仅cmd/main。第二次输入置于CLI允许根外，0/20均为宿主Import错误；
该失败报告另存，输入移到源码_build内后20/20通过，没有修改宿主根政策。
生产零警告检查通过；最初临时runner的reserved_keyword警告亦保留。
该定向检查不代替新实现的Linux全量、完整Go诊断或Go相关ASan。
字符三入口随后72/72，绑定同一干净62b06da，新增NaN字符差异消除。
阶段完整归档 `go-checkpoint-evidence.tar.gz` SHA-256为
`e81a69a5af0b125f636a711819a9b9ed39953f1509bd253f2d62f9f0fdb39443`。
Mac已取回并校验归档SHA256，解包后确认两个报告均绑定干净62b06da及20/20、72/72。
归档包含旧首轮21报告/日志、C++证据、定向超时/宿主失败/20项通过报告、
72字符报告、实际脚本及新源码/二进制哈希；Mac副本保存于
`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-numeric-transfer-.24518.89b63afe`。

用户后续指定六项目优先级并要求共享主机先协调新增重型轮次；全量重验和
Go相关ASan待可用时段。原18 CLI + 1 Evaluator + 1 lint仍未获例外批准。
远端CI与发布继续不在本次授权范围，整体目标未标记完成。

## 共享主机只读快照

UTC02:54:00：24逻辑CPU；内存15GiB、可用12GiB；磁盘剩余61GiB；负载
0.02/0.32/0.46。Docker已安装且active。UTC02:56:30的Docker查询确认
`moonpulsar-test`（apachepulsar/pulsar:latest）及`flowlens-pulsar`（4.0.11）
均停止；Safeline现有容器运行中。没有启动/修改服务或容器、安装其他软件或压测。
UTC03:24:52再次查询验收UID65534，无残留测试/构建进程；最后字符日志mtime为
UTC03:20:50.150802147，已释放本任务的远端重型时段。

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. No tests were rerun on the privacy-rewritten commit.
