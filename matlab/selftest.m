projectRoot = fileparts(fileparts(mfilename('fullpath')));
cd(projectRoot);

addpath(fullfile(projectRoot, 'matlab'));
if exist('gen_model', 'file') ~= 2
    addpath(projectRoot);
end

outDir = fullfile(projectRoot, 'runs', 'manual_debug');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

cleanupFiles = {'verify_log.txt', 'verify_report.json', 'model.slx', 'simout.mat'};
for i = 1:numel(cleanupFiles)
    p = fullfile(outDir, cleanupFiles{i});
    if exist(p, 'file')
        delete(p);
    end
end

logPath = fullfile(outDir, 'verify_log.txt');
reportPath = fullfile(outDir, 'verify_report.json');

fprintf('selftest: output dir: %s\n', outDir);
fprintf('selftest: if it appears stuck, press Ctrl+C and check the last stage in %s\n', logPath);

v = ver('simulink');
if isempty(v)
    append_log(logPath, 'started', 'selftest begin');
    append_log(logPath, 'resolve_paths', 'Simulink not installed');

    report = struct( ...
        'status', 'fail', ...
        'fail_stage', 'resolve_paths', ...
        'errors', struct('code', 'NO_SIMULINK', 'message', 'Simulink is not installed.', 'stack', {{}}), ...
        'artifacts', struct( ...
            'model_path', fullfile(outDir, 'model.slx'), ...
            'report_path', reportPath, ...
            'log_path', logPath));

    write_json(reportPath, report);
    append_log(logPath, 'finished', 'status=fail fail_stage=resolve_paths');

    fprintf('SELFTEST FAIL | fail_stage=resolve_paths | error=Simulink is not installed.\n');
    return;
end

try
    run(fullfile(projectRoot, 'matlab', 'run_verify.m'));
catch ME
    fprintf('selftest: run_verify raised error: %s\n', ME.message);
end

if ~exist(reportPath, 'file')
    fprintf('SELFTEST FAIL | fail_stage=export | error=verify_report.json not found\n');
    return;
end

txt = fileread(reportPath);
report = jsondecode(txt);

status = get_field(report, 'status', 'fail');
failStage = get_field(report, 'fail_stage', 'unknown');
errMsg = '';
if isfield(report, 'errors') && ~isempty(report.errors)
    if isfield(report.errors(1), 'message')
        errMsg = string(report.errors(1).message);
    end
end

if status == "pass"
    fprintf('SELFTEST PASS | fail_stage=%s\n', failStage);
else
    if strlength(errMsg) > 0
        fprintf('SELFTEST FAIL | fail_stage=%s | error=%s\n', failStage, errMsg);
    else
        fprintf('SELFTEST FAIL | fail_stage=%s\n', failStage);
    end
end

fprintf('selftest: if it appears stuck, press Ctrl+C and check the last stage in %s\n', logPath);

function append_log(logPath, stage, message)
fid = fopen(logPath, 'a');
if fid < 0
    return;
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
ts = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
fprintf(fid, '[%s] %s: %s\n', ts, stage, message);
end

function write_json(path, data)
jsonText = jsonencode(data);
fid = fopen(path, 'w');
if fid < 0
    return;
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s\n', jsonText);
end

function value = get_field(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName)
    value = string(s.(fieldName));
else
    value = string(defaultValue);
end
end
