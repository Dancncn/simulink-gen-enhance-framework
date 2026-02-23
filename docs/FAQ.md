# FAQ

## Q: 运行 `python verify.py` 提示找不到 `matlab.exe`？
A: 先确认 MATLAB 已安装，并设置环境变量：

```cmd
set MATLAB_EXE=<MATLAB_INSTALL_DIR>\bin\matlab.exe
```

如果未设置环境变量，`verify.py` 会回退到默认路径（请按你的实际安装位置配置）。

## Q: `verify_report.json` 生成了但 `model.slx` 没有？
A: 这通常表示流程在 `generate` 阶段或其后失败，但报告兜底写入成功。先查看：
- `runs\<timestamp>\verify_report.json` 的 `fail_stage` 和 `errors`
- `runs\<timestamp>\verify_log.txt` 的最后阶段
- `runs\<timestamp>\matlab_stdout.txt` 的 MATLAB 报错

## Q: MATLAB `-batch` 很慢/卡住怎么办？
A: 首次启动 MATLAB 可能较慢（初始化缓存、路径、license）。建议：
- 等待 1~3 分钟再判断
- 优先查看 `runs\<timestamp>\matlab_stdout.txt`
- 查看 `verify_log.txt` 最后一行停在什么阶段

## Q: `runs` 目录太大影响工具性能怎么办？
A: 建议定期清理旧运行目录，或将运行产物迁移到仓库外目录并做软链接/路径配置，避免 IDE 与检索工具扫描过多历史产物。

## Q: 中文乱码/命令行输出乱码怎么办？
A: 推荐使用 `python verify.py`，其终端摘要输出为 ASCII，更利于脚本解析。若必须使用 `verify.cmd`，可先执行：

```cmd
chcp 65001
```

再运行命令，以减轻编码页问题。

## Q: 如何手动打开生成的模型查看？
A: 在 MATLAB 中打开对应产物：

```matlab
open_system(fullfile(pwd, 'runs', '<timestamp>', 'model.slx'))
```

也可以在资源管理器中双击 `runs\<timestamp>\model.slx`（已正确关联 MATLAB 时）。
