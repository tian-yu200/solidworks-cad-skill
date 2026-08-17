# SolidWorks 工程图三维建模

从三视图、剖视图和立体图推理零件结构，生成短期可执行的 `PLAN.md`，再通过随包提供的九工具 SolidWorks MCP 完成参数化建模与多方向验证。

## 完整包内容

- 工程图重建 Skill：方向映射、跨视图边角匹配、剖视缺线推理、立体图优先级和有界重试。
- Python MCP 适配器：向 Codex 暴露固定的九个高层 `mcp__solidworks__` 工具。
- Feature Graph 编译器：把规划后的特征图转换为受控 SolidWorks 操作。
- C# 执行服务源码：安装时在用户机器上引用本地 SolidWorks API 并构建。
- 安装、启动和诊断脚本：首次使用自动准备隔离运行时，后续由 Codex 自动启动。

## 安装

在 Codex 中从 GitHub marketplace 安装完整插件：

```powershell
codex plugin marketplace add tian-yu200/solidworks-cad-skill
codex plugin add solidworks-cad@solidworks-cad-skill
```

安装完成后重启 Codex。首次调用 SolidWorks 工具时，插件会创建 Python venv、下载 Python/NuGet 依赖并在本机构建执行服务。

## 环境要求

- Windows 10/11。
- 已安装并授权的 SolidWorks，且本机包含 SolidWorks API interop 文件。
- Python 3.10 或更高版本。
- Visual Studio Build Tools，或带新版 Roslyn/MSBuild 的现代 .NET SDK。
- 首次安装时可访问 PyPI 和 NuGet。

SolidWorks 本体及其专有 DLL 不包含在开源包内。插件会自动查找标准安装位置、注册表或正在运行的 SolidWorks。自定义安装位置可在启动 Codex 前设置：

```powershell
$env:SOLIDWORKS_INSTALL_DIR = "C:\path\to\SOLIDWORKS"
```

## 手动安装与诊断

从 release 下载并解压完整插件后，在插件根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1
```

自定义 SolidWorks 目录：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 `
  -SolidWorksInstallDir "C:\path\to\SOLIDWORKS"
```

## MCP 工具

```text
start_job
inspect_state
submit_feature_graph
apply_document_edits
drawing_workflow
save_or_export
request_confirmation
confirm_action
finish_job
```

Skill 会先识别投影关系、立体图和剖视图，再生成并确认 `PLAN.md`。每个关键建模节点后更新计划，最终从 Front、Top、Side 和所有可用剖视方向分别验证。

## 下载 v1.1.0

- [完整 Codex 插件 ZIP](https://github.com/tian-yu200/solidworks-cad-skill/releases/download/v1.1.0/solidworks-cad-plugin-v1.1.0.zip)
- [单独下载 SKILL.md](https://github.com/tian-yu200/solidworks-cad-skill/releases/download/v1.1.0/SKILL.md)
- [查看发布页](https://github.com/tian-yu200/solidworks-cad-skill/releases/tag/v1.1.0)

单独的 `SKILL.md` 只包含代理规则；需要独立运行时请安装完整插件 ZIP 或通过 marketplace 安装。

## 开源许可

随包 MCP 源码采用 [AGPL-3.0-only](LICENSE)，其原始许可和归属保留在 MCP 子目录。Skill、插件集成脚本和仓库文档采用 [MIT License](LICENSES/MIT.txt)。SolidWorks 及其 API 程序集不属于本仓库，用户须自行提供合法授权的本地安装。
