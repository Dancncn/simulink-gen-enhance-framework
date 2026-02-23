# WORKFLOW

## 闭环流程

```text
Agent 修改 gen_model.m
    -> python verify.py
    -> MATLAB -batch
    -> matlab/run_verify.m
    -> runs/<timestamp>/verify_report.json
    -> Agent 读取结果并继续迭代
```

## 分步说明
1. Agent 或开发者修改模型生成逻辑（`gen_model.m`）。
2. 执行 `python verify.py`，由 Python 创建 `runs\YYYY-MM-DD_HHMMSS\`。
3. `verify.py` 调用 MATLAB：
   - `-batch` 执行 `matlab/run_verify.m`
   - `-logfile` 落地 `matlab_stdout.txt`
4. `matlab/run_verify.m` 依次完成：路径解析 -> 生成模型 -> 静态加载 -> 仿真 -> 导出报告。
5. 结果写入 `verify_report.json`，终端输出单行解析结果：
   - `STATUS=<pass|fail>`
   - `STAGE=<fail_stage>`
   - `OUTDIR=<abs_path>`
   - `ERR=<first_error_or_empty>`

## 为什么推荐 verify.py
- 跨 shell（CMD / PowerShell / bash）行为更稳定。
- 避免 `.cmd` 在不同编码页下的乱码与输出捕获差异。
- 输出格式固定、纯 ASCII，适合 AI Agent 和脚本自动解析。

## P0 当前验证标准
- `verify_report.json` 可生成且可解析。
- `status` 为 `pass/fail`。
- `fail_stage` 可标识失败阶段。
- `metrics.y_len` 存在且大于 0（表示仿真输出非空）。

## P1 计划新增判题规则（草案）
1. 禁止使用 `Transfer Fcn` / `State-Space` 等“打包动态”块。
2. 要求至少包含 1 个积分器链路（例如 `Integrator`）。
3. 限制可用块白名单（输入、运算、积分、输出类）。
4. 检查模型连接完整性（无悬空端口、无未连接关键链路）。
5. 增加时域指标门槛（稳态误差、超调、调节时间）。
6. 增加频域指标门槛（如 PSD 或带宽相关约束）。
7. 增加结构评分与原因回写（写入 `verify_report.json` 的 `metrics` / `errors`）。
8. 对不合规模型给出可执行修复建议（供下一轮 Agent 修改）。
