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
