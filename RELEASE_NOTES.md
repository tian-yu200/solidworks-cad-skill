# v2.0.0 - 12 工具 SolidWorks MCP 插件与完整 Skill 参考体系

本版本发布于独立分支 `v2`（原 `main` 分支及 `v1.0.0` / `v1.1.0` Release 完整保留、不做覆盖），同步自 `tian-yu200/dsh-solidworks` 最新主线（commit `bc2b86e`）。

## 核心升级

- **12 工具 MCP 契约（从 9 工具升级）**：
  - 新增 `cancel_action`：在用户要求取消时解除待确认队列（配合 `GRAPH_PENDING_CONFIRMATION` 安全状态机）。
  - 新增 `read_drawing_text`：可选 OCR 候选表读取（支持图片与 PDF 页）。
  - 新增 `read_drawing_region`：按源像素框整视图裁图与缩放（支持图像与 PDF 工程图）。
- **完整 Skill 参考文档体系与 MCP Resource 供应**：
  - 随包提供新版 `SKILL.md` 及 7 份 `references/*.md`（工程图读图、构造策略、Feature Graph 能力地图、零件卡与尺寸台账、零件图证据、重建推理、装配体重建）。
  - 通过 `solidworks://skill/references/<file>.md` 作为只读 MCP 资源提供，无需依赖宿主文件读取工具。
- **读图、建模与校验链路强化**：
  - 支持 PDF 工程图渲染与整视图批量裁图。
  - 改为中文 10 秒核对单 + 一次性 `ask_user_question` 收集全部缺失尺寸并确认方案，直接建模。
  - 新增 `inspect_state(scope="views")` 零件多视角截图、`finish_job` 逐视图对比复核、可选 Dimension Ledger 尺寸台账校验与诊断归因。
  - Feature Graph 编译器新增草图圆角切弧求解、轮廓冲突诊断、语义特征命名、螺纹表与装饰螺纹/拔模支持。
  - 运行时状态机完善未绑定/只读文档防护（`JOB_DOCUMENT_UNBOUND` / `JOB_DOCUMENT_READ_ONLY` / `GRAPH_PENDING_CONFIRMATION`），并延长长耗时重建超时至 30 分钟。
- **插件打包与自检升级**：
  - `.mcp.json` 与 `start-mcp.ps1` 自动配置 `DSH_SOLIDWORKS_SKILL_REFERENCES`、`DSH_SOLIDWORKS_INTAKE_ROOT`、`DSH_SOLIDWORKS_VIEWS_ROOT`。
  - `install.ps1` 升级为 `execution-build-v2`（版本 `2.0.0`）并自动安装 `ezdxf`、`Pillow`、`pypdfium2` 等新依赖。
  - `doctor.ps1` 校验全部 12 工具、Python 依赖及 7 份 MCP Skill Resources 注册状态。

## 发布资产

- `solidworks-cad-plugin-v2.0.0.zip`：完整独立插件（含 Skill + 7 份参考文档 + 12 工具 MCP 栈 + 安装/启动/自检脚本）。
- `solidworks-cad-skill-v2.0.0.zip`：纯 Skill 规则包（`SKILL.md` + `references/*.md`），适合已有新版 `dsh-solidworks` MCP 的环境。
- `SKILL.md`：单文件规则速览。

---

# v1.1.0 - 独立 SolidWorks MCP 插件

此版本把 Skill 所需的完整开源 MCP 技术栈加入同一个可下载插件，不再依赖旧 Skill、DSH profile 或单独的 MCP 仓库。

## 新增

- Codex marketplace/plugin 结构，可直接从 GitHub 安装。
- 随包 Python 九工具 MCP 适配器、Feature Graph 编译器和 C# SolidWorks 执行服务源码。
- `install.ps1`：创建隔离 Python 环境、恢复依赖、查找本地 SolidWorks 并构建执行服务。
- `start-mcp.ps1`：首次使用自动安装，之后通过 stdio 启动 MCP。
- `doctor.ps1`：检查 Skill、MCP、Feature Graph schema、Python、执行服务、SolidWorks API 和九工具表面。
- 插件状态、备份、依赖和构建产物写入 Codex 插件数据目录，不污染插件源码或升级缓存。

## 保留能力

- 三视图方向与三维坐标锁定。
- 跨视图边、角、孔、切口、台阶和凸台匹配。
- 立体图优先的拓扑与前后关系判断。
- 全剖、半剖、阶梯剖、对齐剖、局部剖、旋转剖和移出剖分析。
- 剖视缺线条件下的内部结构推理。
- `PLAN.md` 里程碑、有界重试和 Front/Top/Side/剖视多方向验证。

## 安装要求

用户仍需提供 Windows、合法授权的本地 SolidWorks、Python，以及 Visual Studio Build Tools 或现代 .NET SDK。SolidWorks 本体及其专有 API DLL 不随开源包分发。

## 发布资产

- `solidworks-cad-plugin-v1.1.0.zip`：完整独立插件。
- `SKILL.md`：仅代理规则，适合审阅或已有兼容 MCP 的环境。

## 许可

随包 MCP 源码采用 AGPL-3.0-only；Skill、集成脚本和文档采用 MIT。完整插件以 AGPL 覆盖组件的要求发布，并保留上游许可及归属。
