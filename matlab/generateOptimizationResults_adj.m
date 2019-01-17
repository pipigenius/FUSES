% Script running image segmentation for cityscapes dataset using four
% different algorithms: Fuses, alpha-expansion, loopy-belief-propagation
% and tree reweighted message passing (TRW-S)
% This script requires front-end to be pre-generated and allows re-scaling 
% of parameter such that:
%   new binaryWeight = lambda1 + lambda2 * old binaryWeight

% Date: 12/3/2018
% Authors: Luca Carlone, Siyi Hu

clear all; close all; clc;
addpath('./lib')

%% Datasets / settings
lambda1 = 0.02;
lambda2 = 0.04;
useHDF5 = false;
saveEps = false;
nrCoresStr = ' '; %'taskset -c 3 ';
tableTitle = 'Performance on the Cityscapes dataset (2000 superpixels).\label{table-statistics-2000}';
datasetName = 'all';
datasetPath = '/mnt/dataset/Cityscapes'; % Siyi
resultPath = './results';
if useHDF5
    % mrfFolderPath = '/home/luca/Desktop/dataset-Cityscapes-HDF5/'; % Luca ubuntu
    mrfFolderPath = '~/Desktop/data/dataset-Cityscapes-HDF5/'; % Luca mac
    % mrfFolderPath = '/home/siyi/dataset-Cityscapes-HDF5/'; % Siyi
    mrfFolderName = horzcat(datasetName,'-1000SP/');
    % mrfFolderName = horzcat(datasetName,'-1000SP-5classes/');
    % warning('using 5 class dataset')
end


%% Constants
nrTechniques = 5;
frontendAppName = 'frontend-bonnet-hdf5-gtBinary'; % Cityscapes dataset based on bonnet
% modify hdf5
hdf5modifyAppName = 'frontend-rewrite-hdf5';

% parameter file
paramFileName = '../tests/data/fusesParameters.yaml';

% text file containing the list of MRF files
tempFileName = 'tempNames.txt';

% backend optimizers
fusesAppName = 'optimization-FUSES';
darsAppName = 'optimization-FUSES2-DA';
aeAppName = 'expansion-move-alphaExpansion';
lbpAppName = 'belief-propagation-LBP';
trwsAppName = 'belief-propagation-TRWS';

% bonnet accuracy
bonnetAccuracyAppName = 'frontend-bonnet-computeAccuracy'; 

%% settings for plots
dim = 15; % fontsize
% markers for plots
fusesRelaxMarker = ':b';
fusesRoundedMarker = '-b*';
aeMarker = '--cs';
lbpMarker = '-.k^';
trwsMarker = '-ro';
darsRelaxMarker = ':m';
darsRoundedMarker = '-m*';
exactMarker = '-g';

% Commands
frontendCommand = horzcat(nrCoresStr,' ../build/bin/%s ', datasetPath, ' ',datasetName, ' ../bonnet/frozen_1024/ ', paramFileName);
hdf5modifyCommand = horzcat('../build/bin/', hdf5modifyAppName, ' %s %s %f %f');

if useHDF5
    backendCommand = horzcat(nrCoresStr,' ../build/bin/%s ', mrfFolderPath, mrfFolderName, '/%s ', mrfFolderPath, mrfFolderName, '/%s');
else
    backendCommand = horzcat(nrCoresStr,' ../build/bin/%s %s %s');
end

bonnetAccuracyCommand = horzcat('../build/bin/', bonnetAccuracyAppName, ' ', datasetPath, ' %s');

% %% Runing front end
% if useHDF5 || ignoreFrontend % use precomputed MRF from Bonnet frontend
%     disp('running script:')
% else
%     disp('running script with front end:')
%     frontendCommand = sprintf(frontendCommand, frontendAppName);
%     disp(' ')
%     disp(frontendCommand)
%     system(frontendCommand);
% end

%% Getting file names from front end output
if useHDF5
    fileID = fopen(horzcat(mrfFolderPath, mrfFolderName, '/', tempFileName));
else
    fileID = fopen(horzcat(resultPath, '/', tempFileName));
end
textFiles = textscan(fileID, '%s'); % 2 files per dataset: MRF and ground truth
nrFrames = length(textFiles{1})/2;

% parse MRF and ground truth
noWeight_hdfFiles = cell(1, nrFrames); % stores binary factor as lambda1 = 0, lambda2 = 1
labelGTFiles = cell(1, nrFrames);
for i = 1:nrFrames
    noWeight_hdfFiles{i} = textFiles{1}{2*i-1};
    labelGTFiles{i} = textFiles{1}{2*i};
end

% instantiate exact solution using CPLEX
fval_exact = zeros(1, nrFrames);
labels_exact = cell(1, nrFrames);
offset = zeros(1, nrFrames); % offset wrt MRF

%% Runing all backend algorithms
for i = 21:nrFrames
    fprintf('=================== PROCESSING FRAME %d of %d ====================\n',i,nrFrames)
    noWeight_hdfFileName = noWeight_hdfFiles{i};
    labelGTFileName = labelGTFiles{i};
    
    % Modify hdf5 file
    hdfFileName = horzcat(noWeight_hdfFileName(1:end-3), '_m.h5');
%     modifyCommand = sprintf(hdf5modifyCommand, noWeight_hdfFileName, hdfFileName, lambda1, lambda2);
%     disp(' ')
%     disp(modifyCommand)
%     system(modifyCommand);
%     fprintf('')
    
    % fuses
%     fusesCommand = sprintf(backendCommand, fusesAppName, hdfFileName, labelGTFileName);
%     disp(' ')
%     disp(fusesCommand)
%     system(fusesCommand);
%     fprintf('')
    
    % dars
    darsCommand = sprintf(backendCommand, darsAppName, hdfFileName, labelGTFileName);
    disp(' ')
    disp(darsCommand)
    system(darsCommand);
    fprintf('')
    
%     % alpha-expansion
%     aeCommand = sprintf(backendCommand, aeAppName, hdfFileName, labelGTFileName);
%     disp(' ')
%     disp(aeCommand)
%     system(aeCommand);
%     
%     % LBP
%     lbpCommand = sprintf(backendCommand, lbpAppName, hdfFileName, labelGTFileName);
%     disp(' ')
%     disp(lbpCommand)
%     system(lbpCommand);
%     
%     % TRW-S
%     trwsCommand = sprintf(backendCommand, trwsAppName, hdfFileName, labelGTFileName);
%     disp(' ')
%     disp(trwsCommand)
%     system(trwsCommand);
%     
%     % exact solution using CPLEX
%     if useHDF5
%         [label, fval_cplex, offSet] = computeExact(horzcat(mrfFolderPath,mrfFolderName,hdfFileName));
%         fval_exact(i) = fval_cplex;
%         labels_exact{i} = label;
%         offset(i) = offSet;
%     else
%         [label, fval_cplex, offSet] = computeExact(hdfFileName);
%         fval_exact(i) = fval_cplex;
%         labels_exact{i} = label;
%         offset(i) = offSet;
%     end    
end
load('cplex2000_251_372.mat')
%% Parsing results
namefileID = fopen('bad_labels.txt', 'w');
nrNodes = zeros(1, nrFrames); % counts nr of nodes for each dataset
correctLabelsPerc = zeros(nrTechniques, nrFrames); % proportion against GT labels
mIoUPerc = zeros(nrTechniques+1, nrFrames);       % mIoU
mAccuracyPerc = zeros(nrTechniques+1, nrFrames);  % mAccuracy (i.e. PA)
OptLabelsPerc = zeros(nrTechniques, nrFrames);  % number against CPLEX labels
relaxationGap = zeros(2, nrFrames);             % relaxation gatp
suboptGap = zeros(nrTechniques, nrFrames);      % suboptimality gap
time = zeros(nrTechniques, nrFrames);
DAiterations = zeros(1, nrFrames);  % number of iterations for dars
accuracyCplex = zeros(1, nrFrames);
% for i = 251:nrFrames
%     labels_exact{i} = labels_exact2{i};
%     fval_exact(i) = fval_exact2(i);
% end
for i = 1:nrFrames
    fprintf('Parsing results for frame %d\n',i)
    
    noWeight_hdfFileName = noWeight_hdfFiles{i};
    hdfFileName = horzcat(noWeight_hdfFileName(1:end-3), '_m.h5');
    labelGTFileName = labelGTFiles{i};
    
%     if useHDF5
%         hdfFileNameNoExtension = horzcat(mrfFolderPath,mrfFolderName,hdfFileName(1:end-3));
%     else
        hdfFileNameNoExtension = hdfFileName(1:end-3);
%     end
%     
    fusesDataFile = horzcat(hdfFileNameNoExtension,'_FUSES.csv');
    % read first 5 rows, containing [1: timing, 2: nrNodes, 3: nrClasses, 4: nr correct labels, 5: value after rounding]
    fusesData_overall = csvread(fusesDataFile, 0, 1, [0,1,4,1]);
    % store number of nodes:
    nrNodes(i) = fusesData_overall(2);
    fusesLabel = csvread(fusesDataFile, 5, 1, [5,1,5,nrNodes(i)])'; % read labels
    fusesIterationsData = csvread(fusesDataFile, 7, 0); % read last rows containing [nrIter, relaxedCost, cumTime, roundedCost]

    darsDataFile = horzcat(hdfFileNameNoExtension,'_DARS.csv');
    % read first 5 rows, containing [1: timing, 2: nrNodes, 3: nrClasses, 4: nr correct labels, 5: value after rounding]
    darsData_overall = csvread(darsDataFile, 0, 1, [0,1,4,1]);
    darsLabel = csvread(darsDataFile, 5, 1, [5,1,5,nrNodes(i)])'; % read labels
    darsIterationsData = csvread(darsDataFile, 7, 0); % read last rows containing [nrIter, relaxedCost, cumTime, roundedCost]
    
    aeDataFile = horzcat(hdfFileNameNoExtension, '_AE.csv');
    % read first 5 rows, containing [1: timing, 2: nrNodes, 3: nrClasses, 4: nr correct labels]
    aeData_overall = csvread(aeDataFile, 0, 1, [0,1,3,1]);
    aeLabel = csvread(aeDataFile, 4, 1, [4,1,4,nrNodes(i)])';
    aeIterationsData = csvread(aeDataFile, 6, 0);
    
    lbpDataFile = horzcat(hdfFileNameNoExtension, '_LBP.csv');
    lbpData_overall = csvread(lbpDataFile, 0, 1, [0,1,3,1]);
    lbpLabel = csvread(lbpDataFile, 4, 1, [4,1,4,nrNodes(i)])';
    lbpIterationsData = csvread(lbpDataFile, 6, 0);
    
    trwsDataFile = horzcat(hdfFileNameNoExtension, '_TRWS.csv');
    trwsData_overall = csvread(trwsDataFile, 0, 1, [0,1,3,1]);
    trwsLabel = csvread(trwsDataFile, 4, 1, [4,1,4,nrNodes(i)])';
    trwsIterationsData = csvread(trwsDataFile, 6, 0);
      
    % compute accuracy for cplex solution against ground-truth
    labelGT = csvread(labelGTFileName);
    accuracyCplex(1, i) = (1 - nnz(labels_exact{i} - labelGT)/nrNodes(i)) * 100;
    
    % put summary statistics in matrices
    % log correct labels for each method
    correctLabelsPerc(1, i) = fusesData_overall(4)/nrNodes(i) * 100;
    correctLabelsPerc(2, i) = darsData_overall(4)/nrNodes(i) * 100;
    correctLabelsPerc(3, i) = aeData_overall(4)/nrNodes(i) * 100;
    correctLabelsPerc(4, i) = lbpData_overall(4)/nrNodes(i) * 100;
    correctLabelsPerc(5, i) = trwsData_overall(4)/nrNodes(i) * 100;
    
    % compute pixel-level accuracy
    pixelLabelGT = horzcat(noWeight_hdfFileName(1:end-3),'_pixelLabels.csv');
    labelGT_table = csvread(pixelLabelGT);
    [PA, ~, MIoU, ~] = computeAccuracy(labelGT_table, fusesLabel);
    mAccuracyPerc(1, i) = PA;
    mIoUPerc(1, i) = MIoU;
    [PA, ~, MIoU, ~] = computeAccuracy(labelGT_table, darsLabel);
    mAccuracyPerc(2, i) = PA;
    mIoUPerc(2, i) = MIoU;
    [PA, ~, MIoU, ~] = computeAccuracy(labelGT_table, aeLabel);
    mAccuracyPerc(3, i) = PA;
    mIoUPerc(3, i) = MIoU;
    [PA, ~, MIoU, ~] = computeAccuracy(labelGT_table, lbpLabel);
    mAccuracyPerc(4, i) = PA;
    mIoUPerc(4, i) = MIoU;
    [PA, ~, MIoU, ~] = computeAccuracy(labelGT_table, trwsLabel);
    mAccuracyPerc(5, i) = PA;
    mIoUPerc(5, i) = MIoU;
    
    % relaxation and suboptimality gap
    relaxationGap(1, i) = (fusesIterationsData(end,2)-fval_exact(i))/fval_exact(i) * 100;
    relaxationGap(2, i) = (darsIterationsData(end,2)-fval_exact(i))/fval_exact(i) * 100;
    
    suboptGap(1, i) = (fval_exact(i)-fusesData_overall(5))/fval_exact(i) * 100;
    suboptGap(2, i) = (fval_exact(i)-darsData_overall(5))/fval_exact(i) * 100;
    suboptGap(3, i) = (fval_exact(i)-aeIterationsData(end, 2))/fval_exact(i) * 100;
    suboptGap(4, i) = (fval_exact(i)-lbpIterationsData(end, 2))/fval_exact(i) * 100;
    suboptGap(5, i) = (fval_exact(i)-trwsIterationsData(end, 2))/fval_exact(i) * 100;

    % log miss labels against cplex
    OptLabelsPerc(1, i) = (1-nnz(labels_exact{i} - fusesLabel)/nrNodes(i)) * 100;
    OptLabelsPerc(2, i) = (1-nnz(labels_exact{i} - darsLabel)/nrNodes(i)) * 100;
    OptLabelsPerc(3, i) = (1-nnz(labels_exact{i} - aeLabel)/nrNodes(i)) * 100;
    OptLabelsPerc(4, i) = (1-nnz(labels_exact{i} - lbpLabel)/nrNodes(i)) * 100;
    OptLabelsPerc(5, i) = (1-nnz(labels_exact{i} - trwsLabel)/nrNodes(i)) * 100;
    
    % log time
    time(1, i) = fusesIterationsData(end, 3);
    time(2, i) = darsIterationsData(end, 3);
    time(3, i) = aeIterationsData(end, 3);
    time(4, i) = lbpIterationsData(end, 3);
    time(5, i) = trwsIterationsData(end, 3);
    
    % dual-ascent iterations
    DAiterations(1, i) = size(darsIterationsData, 1);

    % bonnet accuracy
    bonnetImageName = horzcat(noWeight_hdfFileName(1:end-3), '_bonnet.png');
    command = sprintf(bonnetAccuracyCommand, bonnetImageName);
    disp(' ')
    disp(command)
    system(command);
    resultFileName = horzcat(noWeight_hdfFileName(1:end-3), '_bonnetAccuracy.csv');
    P = csvread(resultFileName);
    [PA, ~, MIoU, ~] = computeAccuracyfromMatrix(P);
    mAccuracyPerc(6, i) = PA;
    mIoUPerc(6, i) = MIoU;

    % plot results
    if size(fusesIterationsData,1) < 2
        warning('very few fusesIterations')
    end
%     if max(darsIterationsData(:, 2))<fval_exact(i) && saveEps && size(fusesIterationsData,1) > 2 % plot only first few figures
%         fig = figure; 
%         fig.WindowState = 'fullscreen';
%         % subplot 1: convergence of fuses
%         subplot(2,2,1); hold on
%         plot(fusesIterationsData(:, 3), fusesIterationsData(:, 2), ...
%             fusesRelaxMarker,'linewidth',2);
%         plot(fusesIterationsData(:, 3), fusesIterationsData(:, 4), ...
%             fusesRoundedMarker,'linewidth',2);
%         plot([0 fusesIterationsData(end, 3)], fval_exact(i)*ones(1, 2), ...
%             exactMarker,'linewidth',2);
%         legend('FUSES-relaxed', 'FUSES-rounded', 'Exact')
%         xlabel('Time (ms)')
%         ylabel('Objective value')    
%         titleStr = '(a) FUSES convergence';
%         title(titleStr)
%         grid on;
%         set(gca,'FontSize',dim);
%         ylabh=get(gca,'ylabel'); set(ylabh, 'FontSize', dim);
%         xlabh=get(gca,'ylabel'); set(xlabh, 'FontSize', dim);
% %         xlim([0, fusesIterationsData(end,3)+5])
% %         ylim([min(fusesIterationsData(:,2))-10, max(fusesIterationsData(:,2))+10])
%         hold off
%         
%         % subplot 2: convergence of dars
%         subplot(2,2,2); hold on
%         plot(darsIterationsData(:, 3), darsIterationsData(:, 2), ...
%             darsRelaxMarker,'linewidth',2);
%         plot(darsIterationsData(:, 3), darsIterationsData(:, 4), ...
%             darsRoundedMarker,'linewidth',2);
%         plot([0 darsIterationsData(end, 3)], fval_exact(i)*ones(1, 2), ...
%             exactMarker,'linewidth',2);
%         legend('DARS-relaxed','DARS-rounded', 'Exact')
%         xlabel('Time (ms)')
%         ylabel('Objective value')
%         titleStr = '(b) DARS convergence';
%         title(titleStr)
%         grid on;
%         set(gca,'FontSize',dim);
%         ylabh=get(gca,'ylabel'); set(ylabh, 'FontSize', dim);
%         xlabh=get(gca,'ylabel'); set(xlabh, 'FontSize', dim);
% %         xlim([0, darsIterationsData(end,3)+5])
% %         ylim([min(darsIterationsData(:,2))-10, max(darsIterationsData(:,2))+10])
%         hold off
%         
%         % subplot 3: comparison of five techniques
%         subplot(2,2,3); hold on
%         plot(fusesIterationsData(:, 3), fusesIterationsData(:, 4) + offset(i), ...
%             fusesRoundedMarker,'linewidth',2);
%         plot(aeIterationsData(:, 3), aeIterationsData(:, 2) + offset(i), ...
%             aeMarker,'linewidth',2);
%         plot(lbpIterationsData(:, 3), lbpIterationsData(:, 2) + offset(i), ...
%             lbpMarker,'linewidth',2);
%         plot(trwsIterationsData(:, 3), trwsIterationsData(:, 2) + offset(i), ...
%             trwsMarker,'linewidth',2);
%         plot([0 max(time(1:4,i))], darsIterationsData(end, 4)*ones(1, 2) + offset(i), ...
%             darsRoundedMarker,'linewidth',2);
%         plot([0 max(time(1:4,i))], fval_exact(i)*ones(1, 2) + offset(i), ...
%             exactMarker,'linewidth',2);
%         legend('FUSES-rounded', '\alpha-Expansion', 'Loopy Belief Propagation', 'TRW-S', 'DARS (final)', 'Exact')
%         xlabel('Time (ms)')
%         ylabel('Objective value')
%         titleStr = '(c) Comparison of optimization technique';
%         title(titleStr)
%         grid on;
%         set(gca,'FontSize',dim);
%         ylabh=get(gca,'ylabel'); set(ylabh, 'FontSize', dim);
%         xlabh=get(gca,'ylabel'); set(xlabh, 'FontSize', dim);
%         hold off
%         
%         % subplot 4: zoom in version of subplot 3
%         subplot(2,2,4); hold on
%         plot(fusesIterationsData(:, 3), fusesIterationsData(:, 4) + offset(i), ...
%             fusesRoundedMarker,'linewidth',2);
%         plot(aeIterationsData(:, 3), aeIterationsData(:, 2) + offset(i), ...
%             aeMarker,'linewidth',2);
%         plot(lbpIterationsData(:, 3), lbpIterationsData(:, 2) + offset(i), ...
%             lbpMarker,'linewidth',2);
%         plot(trwsIterationsData(:, 3), trwsIterationsData(:, 2) + offset(i), ...
%             trwsMarker,'linewidth',2);
%         plot([0 max(time(1:4,i))], darsIterationsData(end, 4)*ones(1, 2) + offset(i), ...
%             darsRoundedMarker,'linewidth',2);
%         plot([0 max(time(1:4,i))], fval_exact(i)*ones(1, 2) + offset(i), ...
%             exactMarker,'linewidth',2);
%         legend('FUSES-rounded', '\alpha-Expansion', 'Loopy Belief Propagation', 'TRW-S', 'DARS (final)', 'Exact')
%         xlabel('Time (ms)')
%         ylabel('Objective value')
%         titleStr = '(d) Comparison of optimization technique (zoom in)';
%         title(titleStr)
%         grid on;
%         set(gca,'FontSize',dim);
%         ylabh=get(gca,'ylabel'); set(ylabh, 'FontSize', dim);
%         xlabh=get(gca,'ylabel'); set(xlabh, 'FontSize', dim);
%         xlim([0 fusesIterationsData(end,3)*2/3])
%         ylim([0 200])
%         hold off
%         
%         % save figure and data
%         saveas(gcf,hdfFileName(1:end-3),'fig');
%     end
end
fclose(namefileID);
%% Compute statistics
accuracyCplex_mean = mean(accuracyCplex);
accuracyCplex_std = std(accuracyCplex);
disp('Mean cplex accuracy against GT with standard deviation')
disp(horzcat(accuracyCplex_mean, accuracyCplex_std))

DAiterations_mean = mean(DAiterations);
DAiterations_std = std(DAiterations);
disp('Mean number of iterations in dars with standard deviation')
disp(horzcat(DAiterations_mean, DAiterations_std))

mAccuracyPerc_mean = mean(mAccuracyPerc, 2);
mAccuracyPerc_std = std(mAccuracyPerc, 0, 2);
disp('Pixel level accuracy with standard deviation - mAccuracy')
disp(horzcat(mAccuracyPerc_mean, mAccuracyPerc_std))

mIoUPerc_mean = mean(mIoUPerc, 2);
mIoUPerc_std = std(mIoUPerc, 0, 2);
disp('Pixel level accuracy with standard deviation - mIoU')
disp(horzcat(mIoUPerc_mean, mIoUPerc_std))

correctLabelsPerc_mean = mean(correctLabelsPerc, 2);
correctLabelsPerc_std = std(correctLabelsPerc, 0, 2);
disp('Mean percent accurate labels with standard deviation (wrt ground truth)')
disp(horzcat(correctLabelsPerc_mean, correctLabelsPerc_std))

OptLabelsPerc_mean = mean(OptLabelsPerc, 2);
OptLabelsPerc_std = std(OptLabelsPerc, 0, 2);
disp('Mean percent optimal labels with standard deviation (wrt cplex labels)')
disp(horzcat(OptLabelsPerc_mean, OptLabelsPerc_std))

time_mean = mean(time, 2);
time_std = std(time, 0, 2);
disp('Mean runtime with standard deviation')
disp(horzcat(time_mean, time_std))

relaxationGap_mean = mean(relaxationGap, 2);
relaxationGap_std = std(relaxationGap, 0, 2);
disp('Relaxation gap with standard deviation')
disp(horzcat(relaxationGap_mean, relaxationGap_std))

suboptGap_mean = mean(suboptGap, 2);
suboptGap_std = std(suboptGap, 0, 2);
disp('suboptimality gap with standard deviation')
disp(horzcat(suboptGap_mean, suboptGap_std))

figure
plot(1:nrFrames, mIoUPerc(1, :), 'b-', 1:nrFrames, mIoUPerc(5, :), 'r-', ...
    1:nrFrames, mIoUPerc(6, :), 'g--')
xlabel('image index')
ylabel('mIoU % accuracy')
legend('fuses', 'trws', 'bonnet')

%% Format statistics in a LaTex table
fprintf('\\begin{table}[t]\n')
fprintf('\\vspace{-0.4cm}\n')
fprintf('\\centering\n')
fprintf('\\begin{tabular}{|c|c|c|c|c|c|}\n')
fprintf('    \\hline\n')
fprintf('    \\multirow{2}{*}{Method} & \\multicolumn{3}{c|}{Suboptimality} & Accuracy  & Runtime \\\\\n')
fprintf('    \\cline{2-4} & Optimal Labels (\\%%) & Relax Gap (\\%%) &  Round Gap (\\%%) &  (\\%% IoU) &  (ms)  \\\\\n')
fprintf('    \\hline\n')
fprintf('    \\fuses & $%.3f$  & $%.3f$ & $%.3f$  & $%.2f$ & $%.2f$ \\\\\n', ...
    OptLabelsPerc_mean(1), relaxationGap_mean(1), suboptGap_mean(1), mIoUPerc_mean(1), time_mean(1))
fprintf('    \\hline\n')
fprintf('    \\dars & $%.3f$  & $%.3f$ & $%.3f$  & $%.2f$ & $%.2f$ \\\\\n', ...
    OptLabelsPerc_mean(2), relaxationGap_mean(2), suboptGap_mean(2), mIoUPerc_mean(2), time_mean(2))
fprintf('    \\hline\n')
fprintf('    \\aexp & $%.3f$  & - & $%.4g$  & $%.2f$ & $%.2f$ \\\\\n', ...
    OptLabelsPerc_mean(3), suboptGap_mean(3), mIoUPerc_mean(3), time_mean(3))
fprintf('    \\hline\n')
fprintf('    \\LBP & $%.3f$  & - & $%.4g$  & $%.2f$ & $%.2f$ \\\\\n', ...
    OptLabelsPerc_mean(4), suboptGap_mean(4), mIoUPerc_mean(4), time_mean(4))
fprintf('    \\hline\n')
fprintf('    \\TRW & $%.3f$  & - & $%.4g$  & $%.2f$ & $%.2f$ \\\\\n', ...
    OptLabelsPerc_mean(5), suboptGap_mean(5), mIoUPerc_mean(5), time_mean(5))
fprintf('    \\hline\n')
fprintf('\\end{tabular}\n')
fprintf('\\caption{%s}\n', tableTitle)
fprintf('\\vspace{-5mm}\n')
fprintf('\\end{table}\n')