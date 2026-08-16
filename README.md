# SolidWorks 工程图三维建模 Skill

支持从 SolidWorks 工程图、三视图、剖视图和立体图中提取几何证据，规划特征树，并通过受控 MCP 工作流重建、验证和交付三维模型。

## 核心功能

- 三视图方向映射：统一前视、俯视、左视和右视与模型 `+X/+Y/+Z` 的关系。
- 立体图优先：识别等轴、透视或斜轴测图，并用它判断可见拓扑、空间布局和前后关系。
- 剖视图推理：识别全剖、半剖、阶梯剖、局部剖、旋转剖和移出剖，区分剖面线、真实边、中心线与切割平面折线。
- 缺线补全：结合其他视图、孔深、连续性、中心、相切、包容关系和特征连通性推断隐藏细节。
- 计划驱动建模：建模前生成简洁的 `PLAN.md`，按里程碑记录特征顺序、方向、假设和验证结果。
- 受控 SolidWorks MCP：仅使用九个高层 `mcp__solidworks__` 工具，不暴露 COM、宏、脚本或低级 CAD 接口。
- 有界重试与回退：对证据读取、计划修订、里程碑、重规划和方向验证设置明确上限，避免流程死循环。
- 多方向验证：从 Front、Top、Side 以及所有提供的剖视方向检查轮廓、孔、切除、材料/空腔和深度关系。

## 下载

- [下载 `SKILL.md`](https://github.com/tian-yu200/solidworks-cad-skill/releases/download/v1.0.0/SKILL.md)
- [下载完整 ZIP 安装包](https://github.com/tian-yu200/solidworks-cad-skill/releases/download/v1.0.0/solidworks-cad-skill-v1.0.0.zip)
- [查看 v1.0.0 发布页](https://github.com/tian-yu200/solidworks-cad-skill/releases/tag/v1.0.0)

## 使用方式

将 `SKILL.md` 安装到你的 skill 目录，并确保运行环境提供以下九个高层 MCP 工具：

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

模型必须先分析图纸和可用立体图，创建并获得批准的 `PLAN.md`，然后才能执行建模。完成每个建模里程碑后，需要重新读取模型状态并更新计划；最终保存或导出前，必须完成各个可用投影视图及剖视图的独立验证。

## 适用范围

- 从有尺寸或无尺寸工程图重建零件和装配体。
- 根据投影关系补全缺失视图并生成示意三维模型。
- 使用剖视图分析内部孔、腔、台阶、肋、轴和其他隐藏结构。
- 对已有 SolidWorks 文档执行受控参数化编辑、工程图操作和结果验证。

## 安全边界

该 skill 只定义模型可见的高层 SolidWorks MCP 工作流。它不会授权使用 SolidWorks COM、Shell、宏、REST、桌面自动化或旧版低级 CAD MCP 工具。若高层工具缺失或无法表达所需操作，应报告能力缺口并停止 CAD 操作。

## 文件

- [`SKILL.md`](SKILL.md)：完整代理规则、流程图、剖视推理规则、PLAN 模板、重试控制和验证要求。

## License

本项目采用 [MIT License](LICENSE)。
