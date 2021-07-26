function modellingEffectOfSpksOnly_TCSynapticDepression()
%% Description
% This code run simulation for Section 3.7 figure 9c and 9d.
% It simulates the release probability as a result of a thalamic burst with
% with different number of spikes as observed in our in-vitro data.
% by Nidhi Desai

%% load in-vitro burst data with number of spikes and latency
inVitroBurstDataTable = load('inVitroBurstDataTable_3_4.mat'); % Data not available on GitHub
folderName = 'Results';
cd (folderName);
fileName = 'TCcellModel_resProb_only1spk';
exportToPPTX('new', fileName); 
exportToPPTX('saveandclose', fileName);
resProbNoLatency = table();
counter = 0;

%% Setting input parameters
simulatedBurstStartTime = 250;
totalSimulationTime = 1200; % 1000
specification = []; popCounter = 0; connCounter = 0;

for n = 1:size(inVitroBurstDataTable,1) % For each in-vitro cell data
    if inVitroBurstDataTable.NumSpikes(n) > 0 % check if number of spikes are greater than zero
        %% Getting peaks to be reproduced in TC cell based on in-vitro data
        peakTimes = inVitroBurstDataTable.peakTimes{n};
        temp = peakTimes - peakTimes(1) + simulatedBurstStartTime;
        appCurrentTime = [temp, temp+2];
        timeToCheckResProb = appCurrentTime(end) + timeAfterBurstToRecover;
        temp = [temp; timeToCheckResProb + peakTimes - peakTimes(1)];
        appCurrentTime = [temp, temp+2];
        appCurrentVal = 40 * ones(size(appCurrentTime,1),1);
        counter = counter + 1;
        
        [specification, popCounter, connCounter] = thalamocortical_bursts_model(specification,popCounter,connCounter,0,0,appCurrentVal,appCurrentTime); % Setting up thalamo-cortical cell model for bursting
        [specification, ~, connCounter] = Benita_cortex_interneuron_model(specification, popCounter, connCounter); 
        % [specification, popCounter, connCounter] = Benita_cortex_pyramidal_twoCompartment_model(specification, popCounter, connCounter);
        connCounter = connCounter + 1;
        specification.connections(connCounter).direction = 'IN<-TC';
        % specification.connections(connCounter).direction = 'PyCdr<-TC';
        specification.connections(connCounter).mechanism_list = {'iAMPA_IN_TC_ND20'};
        % specification.connections(connCounter).mechanism_list = {'iAMPA_PyCdr_TC_ND20'};

        %% Running simulation and
        data = dsSimulate(specification,'tspan',[0 totalSimulationTime]);
        rmdir('solve', 's');

        %% What is release probability after certain amount of time after bursts ends
        % timeAfterBurstToRecover = 100 ms (time the TC cell is required to be hyperpolarized 
        % to make it burst again)
        timeAfterBurstToRecover = 100; 
        timeToCheckResProb = appCurrentTime(end) + timeAfterBurstToRecover;
        temp = data.time - timeToCheckResProb;
        [~,indx] = min(abs(temp));
        resProbNoLatency.resProb(counter) = data.IN_TC_iAMPA_PyCdr_TC_ND20_res(indx);
        resProbNoLatency.i(counter) = inVitroBurstDataTable.i(n); % cell number
        resProbNoLatency.j(counter) = inVitroBurstDataTable.j(n); % trace number for a cell
        resProbNoLatency.latency(counter) = cell2mat(inVitroBurstDataTable.firstSpkTimeAfterInputEnd(n));
        
        %% Plotting results
        h = figure; hold on;
        s1 = subplot(2,2,1); plot(data.time, data.TC_v); title('TC\_Vol');
        s2 = subplot(2,2,2); plot(data.time, data.IN_V); title('IN\_Vol');
        s3 = subplot(2,2,3); plot(data.time, data.IN_TC_iAMPA_PyCdr_TC_ND20_res); title('Prob release'); ylim([0,1]);
        linkaxes([s1, s2, s3],'x');
        xlim([simulatedBurstStartTime-20, simulatedBurstStartTime+100]);
        suptitle({strcat('i= ', num2str(inVitroBurstDataTable.i(n)),...
            '; j= ', num2str(inVitroBurstDataTable.j(n))),...
            strcat('nuclei= ', inVitroBurstDataTable.brainRegion{n},...
            '; resProb= ',num2str(round(data.IN_TC_iAMPA_PyCdr_TC_ND20_res(indx),2)))});
        exportToPPTX('open', fileName); 
        exportToPPTX('addslide');
        exportToPPTX('addpicture',h);
        exportToPPTX('saveandclose',fileName);
        close(h); 

    end
end


%% Adding the nuclei name in the resProbAfter100ms
for p = 1:size(resProbNoLatency,1)
    I = resProbNoLatency.i(p);
    J = resProbNoLatency.j(p);
    indx = find(inVitroBurstDataTable.i == I & inVitroBurstDataTable.j == J);
    resProbNoLatency.order(p) = inVitroBurstDataTable.cellOrder(indx);
    resProbNoLatency.sensory(p) = inVitroBurstDataTable.sensorySystem(indx);
end

%% Ploting a boxplot for resProb for 6 nuclei
resProbTable = resProbNoLatency;

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

figure; boxplot(resProbTable.resProb, groups); % Not running in 2019 Matlab, Run in 2020 version of Matlab
ylim([0.2, 0.9]);

