# 数据集与 Benchmark

## Skill 质量评估（本书自建）

| 维度 | 评估标准 | 来源 |
|------|---------|------|
| 触发准确率 | Skill 描述是否能让 AI 在正确场景触发 | 手动测试矩阵 |
| 首次执行成功率 | 用户首次调用能否得到预期结果 | lovstudio-skills 使用数据 |
| Token 效率 | 完成任务消耗的 token 数 | Claude Code 会话日志 |
| 跨平台兼容性 | 同一 Skill 在不同 AI 助手上的表现 | 对比测试 |

## 公开数据

- Claude Code 贡献了约 4% 的 GitHub 公开提交（~135,000 commits/day, 2026-02）
- MCP Registry 有超过 10,000 个活跃公开 MCP Server（2025-11）
- 社区 marketplace 收录超过 700,000 个 Agent Skill（2026 初）
