# go-jsonnet 对齐进展：小数精度格式化

日期：2026-10-02。环境：macOS arm64，Moon 0.1.20260920，
MoonBit v0.10.14+7d59c7ec9，native 后端。

源码提交：`014fa2901196a43c7735a7b3ce1dbfaf20b9d551`。
Go/C++ 差分在该提交的干净工作区复跑，`source_dirty=false`。
此前结果见 [数字序列化记录](GO-JSONNET-MANIFEST.md)。

## 本批修复

动态小数精度格式化按 Go 的计算顺序求十次幂：拆分整数/小数指数，
小数部分使用 `exp` 和 `ln`，整数部分用归一化乘方，最后进行二进制缩放。
正负半次幂使用平方根路径。整数精度及科学计数法的尾数缩放仍使用
原有 MoonBit core 幂运算，避免扩大本批行为变更。

这消除了 `format-dynamic-fractional`：`'%.*f' % [1.5,1.25]` 现输出
`"1.8.3772233983162003"`，匹配固定 Go 参考。该看似异常的字符串是参考实现
接受小数精度后的实际行为，没有改成常见语言中仅接受整数精度的规则。

新增 3 组本地测试，修复前 2 组失败、1 组通过，修复后全部通过。
新增 5 条 Go 对照用例，覆盖正负四分之一/半整数精度、十分位精度、
固定/科学/通用格式、标志及大写转换，全部通过。
溢出、下溢和输出限额仍由既有错误契约约束。

`format_power.mbt` 改写自
[Go 1.24.0 math/pow.go](https://github.com/golang/go/blob/go1.24.0/src/math/pow.go)。
上游源文件 SHA-256：`848a205994a0a507046a91a02ad4a95172af2fa5f6f11847acb8cb634471b670`。
已保留版权声明、来源及完整 BSD 3-Clause 许可；打包消费者新增断言，确认
`NOTICE` 和 `licenses/GO-BSD-3-Clause.txt` 包含在实际分发归档中。

## 验证结果

| 验证 | 兼容通过 | 失败 | 已声明 C++ 差异 | 未支持 | 跳过 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Go 完整差分（188 项） | 184 | 2 | 0 | 2 | 0 |
| 其中 Go 专用语料（80 项） | 79 | 1 | 0 | 0 | 0 |
| C++ 共享差分（108 项） | 97 | 0 | 9 | 2 | 0 |
| C++ 上游语言/格式化语料 | 301 | 0 | 0 | 2 | 0 |

C++ 仍保留原始输入，以精确字符串断言核对本批新增差异；
9 项参考差异均单列且 `passed=false`，不计兼容通过。

零警告检查、debug/release 各 41 项测试、格式检查、文档生成、release 构建通过；
`moon info` 未改变公开接口。宿主/CLI 集成 27 项、打包消费者 3 项通过。
提交后 ASan 下 41 项测试和 27 项集成通过；泄漏检测关闭。
仅实测本机 macOS arm64，不代表其他平台、所有超越函数计算或远端 CI 已验证。

## 剩余差异与证据

- `tailstrict`：固定 Go 版本发生内部错误，本项目保留正常结果。
- `bitwise-int64-upper-boundary`：本项目明确拒绝不可表示的正 `2^63` 转换，
  保留确定性的范围错误，原因见 [位运算记录](GO-JSONNET-NUMERIC.md)。

完整 Go 差分仍返回非零；上述输入未改记为通过、跳过或未支持。
该有限语料的收敛不表示完整标准库已实现；下一阶段继续扩展已声明的标准库子集。

- Go 参考：v0.21.0，`67968688d9952f50662e979fab1bef889d0d3e57`。
- C++ 参考：v0.21.0，`bbb38f1020be1f5aed560928fb839b2c448cefb4`。
- 本批 release CLI SHA-256：`6a92b8943ff393bc9b5609aadd1543393ba8a0af3b031ec039e273335cfcc2be`。
- 本地报告：`_build/go-differential/report.json`、`_build/differential/report.json`、
  `_build/upstream-language/report.json`。生成物不提交，复现命令见
  [验证说明](../../development/VALIDATION.md)。

本批仅本地提交，未推送、未运行远端 CI、未发布 Mooncakes。
