# thalamic-distinct-burst

This repository contains some of the sample scripts used in the simulations performed in the publication Desai, Nidhi Vasant, and Carmen Varela. 
"Distinct burst properties contribute to the functional diversity of thalamic nuclei." 
Journal of Comparative Neurology (2021). https://doi.org/10.1002/cne.25141
Compartment models have been implemented using DynaSim toolbox in MATLAB. 

## Shifting the voltage dependence and size of the T current



## Synaptic release probability and thalamocortical transmission
Section 3.7 of the paper discusses the simulations used to study the combined effect of the number of spikes per burst and burst latency on the release probability at a thalamocortical synaptic terminal. 
This model implemented a neurotransmitter release probability variable (Benita et al., 2012) which remains at a steady-state probability of release, until a presynaptic spike reduces the release probability by a fraction of 0.1 and then it recovers with a time constant of 400 ms. To test the implications of different synaptic release probabilities for thalamocortical transmission, we connected the single compartment model of the thalamic cell with a compartmental model of either one pyramidal cell or an interneuron. The thalamic cell model was made to produce spikes with the same number of spikes and latency as we found in our in-vitro cell population. The cortical cells have the same currents and parameters used in the network model of Benita et al. (2012), except we lowered the equilibrium potential for the leak current in the Pyramidal cell to −70 mV (Benita et al., 2012 used −60.95 mV) to increase the dynamic range of excitatory postsynaptic potential (EPSP) amplitudes evoked by the thalamic cell. 



## Burst oscillatory frequency
gT was kept at 1 mS/cm2.



Note: Some of the original mechanisms used in the scripts were used unchanged. They can be found at https://github.com/asoplata/dynasim-extended-benita-model/tree/master/models. The mechanisms which modified have been added to the models directory but were orginially got from https://github.com/asoplata/dynasim-extended-benita-model/tree/master/models.

