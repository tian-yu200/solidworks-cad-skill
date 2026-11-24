# SolidWorks 工程图三维建模（v2.0.0）

> **版本分支说明**：本仓库的 `main` 分支继续保留历史 `v1.1.0`（9 工具架构），不覆盖原版本；最新 `v2.0.0`（12 工具 + 7 份 MCP 参考文档）发布于独立分支 **`v2`** 及 [`v2.0.0` Release](https://github.com/tian-yu200/solidworks-cad-skill/releases/tag/v2.0.0)。

从三视图、剖视图、立体图与 PDF 工程图推理零件结构，先向用户给出中文 10 秒核对单与一次性缺失尺寸确认，再通过随包提供的 **12 工具 SolidWorks MCP** 与 **7 份只读 MCP 参考文档**完成参数化建模、尺寸台账比对与多视角渲染复核。

## 完整包内容（v2.0.0）

- **工程图重建 Skill（`SKILL.md` + `references/` 7 份参考文档）**：
  - `drawing-intake.md`：原图直读、整视图裁图与一次性中文核对单规则
  - `construction-strategies.md`：轴向剖视、铸件轮廓、可编辑性与分阶段策略
  - `feature-graph-capability-map.md`：Feature Graph 能力地图
  - `feature-graph-part-card.md`：零件卡片与尺寸台账（Dimension Ledger）规范
  - `part-drawing-evidence.md`：零件图证据链规则
  - `reconstruction-reasoning.md`：三视图/剖视图空间重建推理
  - `assembly-reconstruction.md`：装配体重建规则
- **Python 12 工具 MCP 适配器**：暴露固定 12 个高层 `mcp__solidworks__` 工具，并通过 `solidworks://skill/references/<file>.md` 提供只读技能参考文档资源。
- **Feature Graph 编译器与草图求解**：支持草图圆角切弧求解、轮廓冲突诊断、语义特征命名、螺纹表、尺寸台账比对与视图渲染对比。
- **C# 执行服务源码**：安装时自动引用用户本机 SolidWorks API 并构建，支持螺纹装饰、拔模、多视角截图、装配与工程图工作流。
- **独立安装、启动和诊断脚本**：首次使用自动准备隔离 Python venv 与 C# 执行服务，运行时状态、备份、裁图与渲染视图均写入插件数据目录。

## 安装与使用

### 方式一：下载 v2.0.0 Release（推荐）

- [完整独立插件 ZIP（含 Skill + 7 份参考文档 + 12 工具 MCP 栈）](https://github.com/tian-yu200/solidworks-cad-skill/releases/download/v2.0.0/solidworks-cad-plugin-v2.0.0.zip)
- [纯 Skill 规则包 ZIP（SKILL.md + references/，适合已有新版 dsh-solidworks MCP 的用户）](https://github.com/tian-yu200/solidworks-cad-skill/releases/download/v2.0.0/solidworks-cad-skill-v2.0.0.zip)
- [单独下载 SKILL.md](https://github.com/tian-yu200/solidworks-cad-skill/releases/download/v2.0.0/SKILL.md)
- [查看 v2.0.0 发布页](https://github.com/tian-yu200/solidworks-cad-skill/releases/tag/v2.0.0)

解压完整插件 ZIP 后，在插件目录执行安装与自检：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1
```

自定义 SolidWorks 安装目录：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 `
  -SolidWorksInstallDir "C:\path\to\SOLIDWORKS"
```

### 方式二：从 `v2` 分支克隆使用

```powershell
git clone -b v2 https://github.com/tian-yu200/solidworks-cad-skill.git
cd solidworks-cad-skill\plugins\solidworks-cad
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1
```

> 如需旧版 9 工具插件，请继续使用 `main` 分支或 [`v1.1.0` Release](https://github.com/tian-yu200/solidworks-cad-skill/releases/tag/v1.1.0)。

## 环境要求

- Windows 10/11。
- 已安装并授权的 SolidWorks，且本机包含 SolidWorks API interop 文件。
- Python 3.10 或更高版本。
- Visual Studio Build Tools，或带新版 Roslyn/MSBuild 的现代 .NET SDK。
- 首次安装时可访问 PyPI（`mcp`, `httpx`, `python-dotenv`, `ezdxf`, `Pillow`, `pypdfium2`）与 NuGet。

SolidWorks 本体及其专有 DLL 不包含在开源包内。插件会自动查找标准安装位置、注册表或正在运行的 SolidWorks；自定义安装位置可在启动前设置：

```powershell
$env:SOLIDWORKS_INSTALL_DIR = "C:\path\to\SOLIDWORKS"
```

## 12 个高层 MCP 工具

```text
start_job
inspect_state
submit_feature_graph
apply_document_edits
drawing_workflow
save_or_export
request_confirmation
confirm_action
cancel_action
finish_job
read_drawing_text
read_drawing_region
```

同时通过 MCP Resources 提供 7 份只读技能参考文档：`solidworks://skill/references/<file>.md`。

## 开源许可

随包 MCP 源码采用 [AGPL-3.0-only](LICENSE)，其原始许可和归属保留在 MCP 子目录（源自 [`tian-yu200/dsh-solidworks`](https://github.com/tian-yu200/dsh-solidworks) / SolidPilot）。Skill、参考文档、插件集成脚本和仓库文档采用 [MIT License](LICENSES/MIT.txt)。SolidWorks 及其 API 程序集不属于本仓库，用户须自行提供合法授权的本地安装。
