modelName = 'model';
exitCode = 1;
status = 'fail';
failStage = 'none';
errors = struct('code', {}, 'message', {}, 'stack', {});
metrics = struct('y_len', 0);

startedAt = char(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss'));

if ~exist('outDir', 'var') || strlength(string(outDir)) == 0
    outDir = fullfile(pwd, 'runs', char(datetime('now', 'Format', 'yyyy-MM-dd_HHmmss')));
end
outDir = char(string(outDir));
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

modelPath = fullfile(outDir, [modelName '.slx']);
simoutPath = fullfile(outDir, 'simout.mat');
logPath = fullfile(outDir, 'verify_log.txt');
reportPath = fullfile(outDir, 'verify_report.json');

log_stage(logPath, 'started', 'run_verify begin');

try
    failStage = 'resolve_paths';
    log_stage(logPath, 'resolve_paths', 'begin');
    thisFile = mfilename('fullpath');
    if strlength(string(thisFile)) == 0
        thisFile = fullfile(pwd, 'matlab', 'run_verify.m');
    end
    projectRoot = fileparts(fileparts(char(thisFile)));
    addpath(projectRoot);
    addpath(fullfile(projectRoot, 'matlab'));
    log_stage(logPath, 'resolve_paths', 'ok');

    failStage = 'generate';
    log_stage(logPath, 'generate', 'begin');
    modelPath = gen_model(outDir, modelName);
    log_stage(logPath, 'generate', ['ok model=' modelPath]);

    failStage = 'static';
    log_stage(logPath, 'static', 'begin');
    load_system(modelPath);
    log_stage(logPath, 'static', 'ok');

    failStage = 'sim';
    log_stage(logPath, 'sim', 'begin');
    simOut = sim(modelPath);
    save(simoutPath, 'simOut');

    yData = read_y(simOut);
    if isempty(yData)
        error('run_verify:MissingY', 'y is missing or empty after simulation.');
    end
    metrics.y_len = numel(yData);
    log_stage(logPath, 'sim', sprintf('ok y_len=%d', metrics.y_len));

    status = 'pass';
    failStage = 'none';
    exitCode = 0;
catch ME
    if strcmp(failStage, 'none')
        failStage = 'resolve_paths';
    end
    errors(end + 1) = make_error('VERIFY_ERROR', ME); %#ok<AGROW>
    status = 'fail';
    exitCode = 1;
    log_stage(logPath, failStage, ['error ' ME.message]);
end

log_stage(logPath, 'export', 'begin');
finishedAt = char(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss'));

report = struct( ...
    'status', status, ...
    'fail_stage', failStage, ...
    'errors', errors, ...
    'artifacts', struct( ...
        'model_path', modelPath, ...
        'report_path', reportPath, ...
        'log_path', logPath), ...
    'metrics', metrics, ...
    'timestamps', struct( ...
        'started_at', startedAt, ...
        'finished_at', finishedAt));

try
    write_report(reportPath, report);
    log_stage(logPath, 'export', 'ok');
catch ME
    errors(end + 1) = make_error('EXPORT_ERROR', ME); %#ok<AGROW>
    report.status = 'fail';
    report.fail_stage = 'export';
    report.errors = errors;
    exitCode = 1;
    log_stage(logPath, 'export', ['error ' ME.message]);
    fallback_write_report(reportPath, report);
end

log_stage(logPath, 'finished', ['status=' report.status ' fail_stage=' report.fail_stage]);
bdclose('all');

if ~usejava('desktop')
    exit(exitCode);
end

function log_stage(logPath, stage, message)
fid = fopen(logPath, 'a');
if fid < 0
    return;
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
ts = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
fprintf(fid, '[%s] %s: %s\n', ts, stage, message);
end

function yData = read_y(simOut)
yData = [];

try
    if isa(simOut, 'Simulink.SimulationOutput')
        vars = simOut.who;
        if any(strcmp(vars, 'y'))
            yVar = simOut.get('y');
            yData = normalize_y(yVar);
            if ~isempty(yData)
                return;
            end
        end
    end
catch
end

try
    if evalin('base', 'exist(''y'',''var'')')
        yVar = evalin('base', 'y');
        yData = normalize_y(yVar);
    end
catch
end
end

function out = normalize_y(yVar)
out = [];
if isa(yVar, 'timeseries')
    out = yVar.Data;
elseif isnumeric(yVar)
    out = yVar;
elseif isstruct(yVar) && isfield(yVar, 'signals') && ~isempty(yVar.signals)
    try
        out = yVar.signals.values;
    catch
        out = [];
    end
end
end

function err = make_error(code, ME)
stackList = cell(1, numel(ME.stack));
for i = 1:numel(ME.stack)
    stackList{i} = sprintf('%s:%d', ME.stack(i).name, ME.stack(i).line);
end
err = struct('code', code, 'message', ME.message, 'stack', {stackList});
end

function write_report(reportPath, report)
jsonText = jsonencode(report);
fid = fopen(reportPath, 'w');
if fid < 0
    error('run_verify:CannotWriteReport', 'Cannot open report file for writing.');
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s\n', jsonText);
end

function fallback_write_report(reportPath, report)
status = safe_field(report, 'status', 'fail');
failStage = safe_field(report, 'fail_stage', 'export');
modelPath = safe_field(report.artifacts, 'model_path', '');
logPath = safe_field(report.artifacts, 'log_path', '');

errMsg = 'unknown error';
if isfield(report, 'errors') && ~isempty(report.errors) && isfield(report.errors(1), 'message')
    errMsg = report.errors(1).message;
end

fid = fopen(reportPath, 'w');
if fid < 0
    return;
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '{');
fprintf(fid, '"status":"%s",', escape_json(status));
fprintf(fid, '"fail_stage":"%s",', escape_json(failStage));
fprintf(fid, '"errors":[{"message":"%s"}],', escape_json(errMsg));
fprintf(fid, '"artifacts":{"model_path":"%s","report_path":"%s","log_path":"%s"}', ...
    escape_json(modelPath), escape_json(reportPath), escape_json(logPath));
fprintf(fid, '}');
end

function value = safe_field(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = char(string(s.(name)));
else
    value = defaultValue;
end
end

function out = escape_json(in)
out = char(string(in));
out = strrep(out, '\\', '\\\\');
out = strrep(out, '"', '\\"');
out = strrep(out, sprintf('\n'), '\\n');
out = strrep(out, sprintf('\r'), '\\r');
out = strrep(out, sprintf('\t'), '\\t');
end
