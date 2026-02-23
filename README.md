# simulink-gen-enhance-framework — AI-driven Simulink model generation & verification framework.

这是一个面向 Windows + MATLAB 的最简可运行项目，用于验证“自动生成 Simulink 模型并自动判定是否通过”的基础闭环。

当前实现聚焦 P0：通过 CLI 一键完成模型生成、仿真执行、日志记录与 JSON 报告导出，便于人类开发者和 AI Agent 快速迭代。

## 功能概览
- `gen_model.m`：生成最小可仿真的 Simulink 模型（`model.slx`）
- `matlab/run_verify.m`：裁判脚本，负责生成/静态检查/仿真/导出 `verify_report.json`
- `verify.py`：跨 shell 验证入口（推荐，输出可解析）
- `verify.cmd`：Windows 入口（可选/备用）
- `runs/`：每次运行产物目录（按时间戳分目录）

## 环境要求
- Windows 10/11
- MATLAB R2025a + Simulink（需要有效 Simulink license）
- Python 3.x（`verify.py` 需要）

## 快速开始

### 1) 设置 MATLAB 路径
方式 A：通过环境变量指定 `MATLAB_EXE`（推荐）

```cmd
set MATLAB_EXE=<MATLAB_INSTALL_DIR>\bin\matlab.exe
```

方式 B：使用 `verify.py` 的默认路径

```text
<MATLAB_INSTALL_DIR>\bin\matlab.exe
```

如果你本机 MATLAB 不在该路径，请改用方式 A 设置环境变量。

### 2) 运行一次验证
在仓库根目录执行：

```cmd
python verify.py
```

### 3) 成功判定
- 终端输出包含：`STATUS=pass`
- `runs\<timestamp>\` 下出现：
  - `verify_report.json`
  - `verify_log.txt`
  - `model.slx`
  - `matlab_stdout.txt`（使用 `-logfile` 时）

## 输出目录说明
每次运行都会创建：

```text
runs\YYYY-MM-DD_HHMMSS\
```

典型文件含义：
- `verify_report.json`：最终机器可读结果（`status`、`fail_stage`、`errors`、`metrics`）
- `verify_log.txt`：阶段日志（started/resolve/generate/static/sim/export/finished）
- `model.slx`：生成的模型文件
- `matlab_stdout.txt`：MATLAB batch 标准输出日志
- `simout.mat`：仿真输出（若裁判脚本导出）

## P0 与 P1 的区别
- P0：只验证“模型能生成、能仿真、并能产出报告与基础指标”
- P1：加入结构判题（例如禁止取巧块、要求积分链路、增加频域/时域指标约束），计划明天实现

## 文档导航
- `docs/WORKFLOW.md`：端到端执行流程
- `docs/FAQ.md`：常见故障与排查
- `docs/ROADMAP.md`：P0/P1/P2 规划与明日任务
- `docs/ARCHITECTURE.md`：模块职责与边界

## 开源与贡献
- License：MIT
- 欢迎提交 Issue / PR 改进验证规则、模板与自动修复策略
