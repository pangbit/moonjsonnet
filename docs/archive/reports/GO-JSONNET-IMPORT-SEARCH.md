# 导入搜索路径与宿主缓存验收

2026-10-04 完成实现提交 `b95a44dcd9407d0a4b1ac31f8fa43cdd2453a012`，
归档文档依赖修复提交 `49823db3ed5466e9c6a82be200ce112bb3d6be50`。
最终验收在后者及干净工作区执行。参考仍为 google/go-jsonnet v0.21.0；
**整体功能对齐未完成**。

## 实现与政策

- CLI 加入 `-J`/`--jpath` 和 POSIX `JSONNET_PATH`。先查导入文件所在目录，
  再按右至左查 CLI 库路径，最后按左至右查环境路径。匿名输入和代码参数
  从 root 开始查找。空环境值不增加路径，环境空段代表 root；空 `-J` 报错。
- `FileHost::new`、`evaluate_file` 增加可选 `jpaths`；数组在构造时复制。
  嵌入宿主不读取环境变量，最后一个库目录优先。`FileHost::load` 只加载入口，
  不查库路径；CLI 和 `evaluate_file` 使用该方法。绝对导入不查库路径。
- 相对候选按 Go `filepath.Join` 清理 dot 路径，再执行既有 canonical/root
  检查。成功与不存在的候选均记忆化，文本与二进制共享 canonical 字节缓存。
  创建新宿主才能观察此前缺失文件的出现或已读文件的内容变化。
- 只有 ENOENT 继续查下一个目录；ENOTDIR、权限、目录文件、symlink 循环及
  其他 I/O 错误立即传播且不作负缓存。命中后语法、运行时、UTF-8 与资源错误
  不回退。POSIX 层保留 errno，避免关闭目录描述符后丢失原始失败原因。
- 保留限定 root、严格文本 UTF-8、单文件与累计预算、canonical 来源身份和
  O_NOFOLLOW 描述符读取政策。`-J`/环境路径不扩大读取权限；库文件和 symlink
  目标必须在 root 内。相对库目录相对于 root，而 Go 相对于进程目录；默认
  root 为当前目录时相同，显式 root 则是宿主扩展。Go 的来源名使用候选路径，
  本项目保留 canonical 身份；不声明诊断路径、alias 身份或竞争条件完全等价。

依据固定 Go `imports.go` 的 FileImporter/tryPath/Import，及
`cmd/jsonnet/cmd.go` 的环境路径和参数处理。运行时由 MoonBit 与 POSIX 宿主实现，
没有调用参考解释器提供功能。依赖发现、导入查询、可重用 VM/AST、stack/trace
选项、格式化与分析工具仍待实现。

## 验证

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release CLI 构建 | 通过 |
| debug / release 测试 | 各 134/134 |
| 新增 `tests/go-cli-imports.json` | 37/37；29 成功、8 错误 |
| 完整 Go 差分 | 989/1007；18 历史失败；0 跳过/未支持 |
| C++ 共享差分 | 98 通过、10 声明差异、0 失败，共 108 |
| 上游语言语料 | 303/303 |
| 标准库表面 | 163/163；behavioral_parity_proven=false |
| 宿主集成 | 原有 97 + multi 26 + 导入 20，共 143 |
| ASan | 134 测试 + 143 集成通过；关闭 leak detection |
| 独立归档消费者 | 13/13 |

新增 Go 语料固定目录优先级、环境空段、CLI/环境组合、局部与嵌套导入、
file/exec/stdin、code/file 参数、importstr/importbin、Unicode/NUL 内容、
dot 清理、alias、入口不搜索，以及缺失、目录、非目录父路径、语法与运行时
错误。成功同时核对参考和本地 JSON 与显式预期；错误核对退出、空 stdout 和
诊断特征。诊断文字/类别不要求完全相同：Go 将导入语法错误包装为运行时
错误，本项目保留 Syntax。报告保留全部 fixture、参数、环境配置与实际输出。

API 回归验证构造数组复制、绝对/相对来源、负缓存稳定性、文件改写后的字节
缓存、fresh host 重新读取及 load 不搜索。20 项集成另外检查 root 相对库目录、
绝对目录、未使用的低优先级越界路径、symlink alias/escape/loop、权限、
无效 UTF-8 与任意二进制字节、大小限制、参数导入和入口加载。

首轮差分保留在 `_build/go-differential/import-search-initial.json`：最初将
ENOTDIR 当作缺失而回退，随后按参考实测改为立即失败；导入语法错误的测试
预期也按两边实际诊断修正，输入未移除。独立消费者首轮在临时目录
`moonjsonnet-consumer-.99775.15060df9` 因归档排除测试文件而触发未使用测试
依赖警告；修复公开文档示例后重新归档并验证，未关闭警告。

完整 Go 的 400 error、3 raw-output、58 text-output、45 file-output、11 io-error
为重叠计数。18 项历史失败仍使 runner 退出 1，未跳过或作为兼容通过。
C++ 声明差异不算通过；表面注册不证明全量行为等价。

## 构建与证据

- macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- Go 提交 `67968688d9952f50662e979fab1bef889d0d3e57`，Go 1.24.0，
  vcs.modified=false；SHA-256
  `adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ 提交 `bbb38f1020be1f5aed560928fb839b2c448cefb4`；SHA-256
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
- release CLI SHA-256
  `f70b9dfc14ab88332af3bc68893a2d5bdfbb30cb6765b1e2bf2d3265051aae97`。
- Go/C++/parity 最终报告均绑定 `49823db`，source_dirty=false；上游语言报告
  同样绑定该提交。原始报告留在 `_build`。
- ASan：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.7675.1d34fc2`。
- 消费者：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.7741.f7def9a9`。

只进行本地提交；没有推送或发布。本轮未验证其他平台和远端 CI。
