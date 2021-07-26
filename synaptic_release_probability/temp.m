function modellingEffectOfSpksOnly_TCSynapticDepression()
% 27th July 2020
clear; clc;
inVitroBurstDataTable = load('inVitroBurstDataTable_3_4.mat'); % Data not available on GitHub
folderName = 'Results';
resProbNoLat = table();
counter = 0;

%% Setting model
for n = 1:size(inVitroBurstDataTable_3_4,1)
    if inVitroBurstDataTable_3_4.NumSpikes(n) > 0     
        %% Setting input parameters
        simulatedBurstStartTime = 250;
        totalSimulationTime = 1200; % 1000
        specification = []; popCounter = 0; connCounter = 0;
        peakTimes = inVitroBurstDataTable_3_4.peakTimes{n}; % Getting peaks to be reproduced in TC cell based on in-vitro data
        temp = peakTimes - peakTimes(1) + simulatedBurstStartTime;
        temp = [temp; timeToCheckResProb + peakTimes - peakTimes(1)];
%         temp = [simulatedBurstStartTime; timeToCheckResProb];
        appCurrentTime = [temp, temp+2];
        appCurrentVal = 40 * ones(size(appCurrentTime,1),1);
        counter = counter + 1;
%         disp(strcat('Running simulation: n= ', num2str(n)));
%         resProbOnly1Spks.i(counter) = inVitroBurstDataTable_3_4.i(n);
%         resProbOnly1Spks.j(counter) = inVitroBurstDataTable_3_4.j(n);
%         resProbOnly1Spks.numSpks(counter) = inVitroBurstDataTable_3_4.NumSpikes(n);
%         resProbAfter100ms.latency(counter) = cell2mat(inVitroBurstDataTable_3_4.firstSpkTimeAfterInputEnd(n));

        [specification, popCounter, connCounter] = thalamocortical_bursts_model(specification,popCounter,connCounter,0,0,appCurrentVal,appCurrentTime); % Setting up thalamo-cortical cell model for bursting
        [specification, ~, connCounter] = Benita_cortex_interneuron_model(specification, popCounter, connCounter);
        connCounter = connCounter + 1;
        specification.connections(connCounter).direction = 'IN<-TC';
        specification.connections(connCounter).mechanism_list = {'iAMPA_PyCdr_TC_ND20'};

        %% Running simulation and
        data = dsSimulate(specification,'tspan',[0 totalSimulationTime]);
        rmdir('solve', 's');

        %% What is release probability after certain amount of time after bursts ends
        % timeAfterBurstToRecover = 100 ms (time the TC cell is required to be hyperpolarized 
        % to make it burst again) + latency (latency of TC cell after it is released from hyperpolarization 
        % to burst again) 
        timeAfterBurstToRecover = 100; % + cell2mat(inVitroBurstDataTable_3_4.firstSpkTimeAfterInputEnd(n));
        timeToCheckResProb = appCurrentTime(end) + timeAfterBurstToRecover;
        temp = data.time - timeToCheckResProb;
        [~,indx] = min(abs(temp));
        resProbOnly1Spks.resProb(counter) = data.IN_TC_iAMPA_PyCdr_TC_ND20_res(indx);
        
        counter = 0;
        for p = 1:size(inVitroBurstDataTable_3_4,1)
            if inVitroBurstDataTable_3_4.NumSpikes(p) > 0    
                counter = counter + 1;
                resProbOnly1Spks.i(counter) = inVitroBurstDataTable_3_4.i(p);
                resProbOnly1Spks.j(counter) = inVitroBurstDataTable_3_4.j(p);
                resProbOnly1Spks.latency(counter) = cell2mat(inVitroBurstDataTable_3_4.firstSpkTimeAfterInputEnd(p));
                timeAfterBurstToRecover = 100 + cell2mat(inVitroBurstDataTable_3_4.firstSpkTimeAfterInputEnd(p));
                timeToCheckResProb = appCurrentTime(end) + timeAfterBurstToRecover;
                temp = data.time - timeToCheckResProb;
                [~,indx] = min(abs(temp));
                resProbOnly1Spks.resProb(counter) = data.IN_TC_iAMPA_PyCdr_TC_ND20_res(indx);
            end
        end
                
        %% Plotting results
        h = figure; hold on;
        s1 = subplot(2,2,1); plot(data.time, data.TC_v); title('TC\_Vol');
        s2 = subplot(2,2,2); plot(data.time, data.IN_V); title('IN\_Vol');
        s3 = subplot(2,2,3); plot(data.time, data.IN_TC_iAMPA_PyCdr_TC_ND20_res); title('Prob release'); ylim([0,1]);
        linkaxes([s1, s2, s3],'x');
        xlim([simulatedBurstStartTime-20, simulatedBurstStartTime+100]);
        suptitle({strcat('i= ', num2str(inVitroBurstDataTable_3_4.i(n)),...
            '; j= ', num2str(inVitroBurstDataTable_3_4.j(n))),...
            strcat('nuclei= ', inVitroBurstDataTable_3_4.brainRegion{n},...
            '; resProb= ',num2str(round(data.IN_TC_iAMPA_PyCdr_TC_ND20_res(indx),2)))});
        exportToPPTX('open', fileName); 
        exportToPPTX('addslide');
        exportToPPTX('addpicture',h);
        exportToPPTX('saveandclose',fileName);
        close(h); 
    end
end

%% Adding the nuclei name in the resProbAfter100ms
for p = 1:size(resProbOnly1Spks,1)
    I = resProbOnly1Spks.i(p);
    J = resProbOnly1Spks.j(p);
    indx = find(inVitroBurstDataTable_3_4.i == I & inVitroBurstDataTable_3_4.j == J);
    resProbOnly1Spks.order(p) = inVitroBurstDataTable_3_4.cellOrder(indx);
    resProbOnly1Spks.sensory(p) = inVitroBurstDataTable_3_4.sensorySystem(indx);
end

%% Ploting a boxplot for resProb for 6 nuclei
% load('C:\Users\Deepcutlab\OneDrive - Florida Atlantic University\Prof_Varela_Current_Research\DYNASIM Models\Modelling_using_Dynasim\DynaSim-master\HHmodel_synapticDepression_TC-PFCmodel\Results\resProbAfterLatency.mat');
% resProbTable = resProbAfterLatency;
% load('C:\Users\Deepcutlab\OneDrive - Florida Atlantic University\Prof_Varela_Current_Research\DYNASIM Models\Modelling_using_Dynasim\DynaSim-master\HHmodel_synapticDepression_TC-PFCmodel\Results\resProbAfter100ms.mat');
% resProbTable = resProbAfter100ms;
load('C:\Users\Deepcutlab\OneDrive - Florida Atlantic University\Prof_Varela_Current_Research\DYNASIM Models\Modelling_using_Dynasim\DynaSim-master\HHmodel_synapticDepression_TC-PFCmodel\Results\resProbOnly1Spks.mat');
resProbTable = resProbOnly1Spks;

visualIndx = strcmp(resProbTable.sensory,'visual');
audiIndx = strcmp(resProbTable.sensory,'auditory');
somatoIndx = strcmp(resProbTable.sensory,'somato');
lowerIndx = strcmp(resProbTable.order,'lowerOrder'); 
higherIndx = strcmp(resProbTable.order,'higherOrder'); 

groups = zeros(size(resProbTable,1),1);
groups(visualIndx & lowerIndx) = 1;
groups(visualIndx & higherIndx) = 2;
groups(audiIndx & lowerIndx) = 3;
groups(audiIndx & higherIndx) = 4;
groups(somatoIndx & lowerIndx) = 5;
groups(somatoIndx & higherIndx) = 6;

figure; boxplot(resProbTable.resProb, groups); % Not running in 2019 Matlab 
% Run in 2020 version of Matlab
ylim([0.2, 0.9]);

ranksum(resProbTable.resProb(visualIndx & lowerIndx), resProbTable.resProb(visualIndx & higherIndx))



end