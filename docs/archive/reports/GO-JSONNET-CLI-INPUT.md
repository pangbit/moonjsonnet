# CLI 输入模式验收

2026-10-04 在实现提交 `8bf6e5d8601b7a80b41ba9cd481a7c08a83f1325`
及干净工作区完成验收。前置功能提交为
`7030306eb41aea68b1dd7b748d8d8aaa34d9b902`。
目标仍为 google/go-jsonnet v0.21.0，整体功能对齐未完成。

## 实现与边界

- CLI 支持 `-e`/`--exec` 内联代码、以 `-` 读取 stdin、`--` 停止选项解析。
  `-e -` 将 `-` 当代码；文件/内联模式不会读取 stdin。
- 单短横线参数按 UTF-8 字节展开，保持固定 Go 参考的处理顺序；展开也作用于
  选项值，遇到 `--` 后停止。`-eV` 可组合，但不采用附加值的 GNU 解析规则。
  同时增加 `--output-file`、`-v`，空输出路径报错。
- 收集输入后再检查个数，使 help/version 可提前结束；所有 CLI 失败退出 1。
  此项替代此前一般参数/输出错误退出 2 的行为。
- `evaluate` 新增 `anonymous`，默认关闭。打开时入口 `std.thisFile` 和导入起点
  为空，诊断与 trace 仍使用调用方给定的 filename。CLI 分别使用 `<cmdline>`
  和 `<stdin>`；外部代码/TLA 的 synthetic 文件名不受影响。
- 导入起点在词法环境中继承，不再以诊断文件名查表。已复现并修正匿名诊断名
  与 resolver 返回的真实 Source.id 相同造成的路径混淆；对象、local、函数、
  文本/二进制导入均覆盖。调用方不再需要为参数保留 synthetic 文件名。
- POSIX stdin 读取处理 EINTR，在源字节预算加 1 处停止，不关闭 stdin。
  严格 UTF-8 解码保留 BOM，非法字节返回 Import，超预算返回 Limit。
  文件宿主仍限制 root/symlink；这些资源与输入政策比 Go 默认 CLI 更严格。

参考源码为 `cmd/jsonnet/cmd.go`、`cmd/internal/cmd/utils.go`、`vm.go` 和
`imports.go`。实现由 MoonBit 求值器和本地 POSIX 宿主提供，未调用参考解释器
提供运行时功能。错误全文、无限输入及所有平台行为等价未声明。
字符串/multi/stream 输出、导入搜索路径、stack/trace 选项和 VM/AST 接口仍待实现。

## 验证

| 检查 | 结果 |
| --- | --- |
| `moon check --deny-warn`、info、fmt/check、doc、release build | 通过 |
| debug / release 测试 | 各 112/112 |
| 新增 Go 输入差分 `tests/go-cli-input.json` | 38/38 |
| 完整 Go 差分 | 862/880；18 失败；0 跳过/未支持 |
| C++ 原始共享差分 | 98 通过、10 声明差异、0 失败，共 108 |
| 上游语言语料 | 303/303 |
| 标准库反射清单 | 163/163；0 缺失/签名差异/额外成员 |
| CLI/文件宿主集成 | 74 项通过 |
| ASan | 112 测试 + 74 集成通过；leak detection 关闭 |
| 独立归档消费者 | 9/9 |

新增差分覆盖内联/stdin 的正常、语法、静态、运行时输入，Unicode/NUL、
匿名 thisFile、逐字节 trace、ext/TLA、文本/二进制导入、短选项顺序、
以短横线起始的文件名、help、输入数量和参数错误。差分工具保存
input/input_arg/stdin/cwd 和既有 args/files/env；成功固定 JSON，错误验证
参考诊断特征及本地类别。trace 保持按字节比较，未要求 JSON 排版一致。

集成另验证 stdin 非法 UTF-8、源字节精确边界及超限、1 MiB 输入、根目录
逃逸、输出别名和错误时保留已有输出文件。匿名导入名称碰撞回归先出现
112 项中的 1 项失败，再通过词法环境修正；没有删除该输入或更改预期。

完整 Go 的 360 个 expected-error case 和 3 个 raw-output case 为重叠计数。
18 项历史失败原样保留，详见 [整体对齐](../../development/zh-CN/GO-PARITY.md)；Go runner
因此返回 1，尚不是通过的兼容 CI 门槛。C++ 的 10 项声明差异单独计数，
不计为兼容通过。163 个反射成员只证明注册表面，不证明全部行为等价。

## 构建与证据

- macOS arm64，Moon 0.1.20260920，MoonBit v0.10.14+7d59c7ec9。
- Go 提交 `67968688d9952f50662e979fab1bef889d0d3e57`，Go 1.24.0 构建，
  `vcs.modified=false`；SHA-256
  `adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ 提交 `bbb38f1020be1f5aed560928fb839b2c448cefb4`；SHA-256
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
  共享差分记录二进制哈希；提交由本地 checkout 和上游语言工具另行核验。
- MoonJsonnet release CLI SHA-256
  `10abb4a0c7c719b7f4c79971ea5bf3d8ff2ac4723d89b41e6cb96c93fd55a5dd`。
- `_build/go-differential/report.json`、`_build/differential/report.json` 和
  `_build/parity/report.json` 均绑定上述最终实现提交，source_dirty=false；
  `_build/upstream-language/report.json` 同样绑定实现提交。
- ASan 副本：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.23535.cf6c71af`。
- 消费者：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.23648.9382c607`。

原始报告保留在 `_build`，本轮只作本地提交，未推送或发布。
其他平台与远端 CI 未在本轮验证。
