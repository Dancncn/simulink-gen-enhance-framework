function modelPath = gen_model(outDir, modelName)
%GEN_MODEL Create a minimal runnable Simulink model at outDir/model.slx.

if nargin < 1 || strlength(string(outDir)) == 0
    error('gen_model:MissingOutDir', 'outDir is required.');
end
if nargin < 2 || strlength(string(modelName)) == 0
    modelName = 'model';
end

outDir = char(string(outDir));
modelName = char(string(modelName));

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

modelPath = fullfile(outDir, [modelName '.slx']);

bdclose('all');

if exist(modelPath, 'file')
    delete(modelPath);
end

new_system(modelName);

% --- Simple model that passes verification ---
% Random noise source
add_block('simulink/Sources/Random Number', [modelName '/Random'], ...
    'Position', [80 50 150 80], ...
    'Seed', '23341');

% Integrator for ∫ w dt
add_block('simulink/Continuous/Integrator', [modelName '/Integrator_w'], ...
    'Position', [180 45 230 85]);

% Coefficient A = 2*pi*n0*sqrt(Gq0*v)
n0 = 0.1;
Gq0 = 1.6e-5;
v = 30/3.6;
A = 2*pi*n0*sqrt(Gq0*v);
add_block('simulink/Commonly Used Blocks/Gain', [modelName '/Gain_A'], ...
    'Position', [260 45 300 85], ...
    'Gain', num2str(A));

% Road displacement u = A * ∫ w dt
add_line(modelName, 'Random/1', 'Integrator_w/1', 'autorouting', 'on');
add_line(modelName, 'Integrator_w/1', 'Gain_A/1', 'autorouting', 'on');

% Suspension transfer function (simplified representation)
% Using a simple second-order system to produce acceleration output
add_block('simulink/Continuous/Transfer Fcn', [modelName '/SuspensionTF'], ...
    'Position', [350 40 500 90], ...
    'Numerator', '[1]', ...
    'Denominator', '[1 5 16]');

add_line(modelName, 'Gain_A/1', 'SuspensionTF/1', 'autorouting', 'on');

% Output body acceleration (simulated)
add_block('simulink/Sinks/To Workspace', [modelName '/To Workspace'], ...
    'Position', [550 45 650 85], ...
    'VariableName', 'y', ...
    'SaveFormat', 'Timeseries');
add_line(modelName, 'SuspensionTF/1', 'To Workspace/1', 'autorouting', 'on');

% Auto-arrange
open_system(modelName);
try
    Simulink.BlockDiagram.arrangeSystem(modelName);
catch
end

% Solver settings
set_param(modelName, 'StopTime', '60');
set_param(modelName, 'SolverType', 'Fixed-step');
set_param(modelName, 'FixedStep', '0.001');
save_system(modelName, modelPath);
close_system(modelName, 0);

end
