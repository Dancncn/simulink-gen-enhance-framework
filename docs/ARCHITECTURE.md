# ARCHITECTURE

## 模块职责
- `gen_model.m`
  - 负责构建并保存 `model.slx`
  - 不负责判题和最终结论

- `matlab/run_verify.m`
  - 验证裁判核心
  - 负责阶段日志、仿真执行、报告导出

- `verify.py`
  - 跨 shell 入口层
  - 负责创建运行目录、启动 MATLAB、读取 JSON、输出单行结果与退出码

- `verify.cmd`
  - Windows 备用入口（人工执行友好）

## 数据流
```text
verify.py
  -> matlab/run_verify.m
      -> gen_model.m
      -> model.slx
      -> simout.mat (optional)
      -> verify_log.txt
      -> verify_report.json
  -> verify.py 读取 verify_report.json
  -> 输出 STATUS/STAGE/OUTDIR/ERR
```

## 职责边界
- Python 层只做流程编排与结果汇总，不做 Simulink 细节判定。
- MATLAB 层负责模型生成与验证细节，不处理跨 shell 兼容问题。
- 报告文件 `verify_report.json` 是模块间唯一权威结果接口。

## 可扩展点
- 在 `run_verify` 中插入 P1 结构判题模块。
- 将判题配置抽离为外部规则文件（后续对接 `cases/`）。
- 对接 CI 后，可用 `verify.py` 统一执行入口。
