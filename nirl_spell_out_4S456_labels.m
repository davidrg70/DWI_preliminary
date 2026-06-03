function [spelled_out] = nirl_spell_out_4S456_labels(labels)
% DG, May 2025
% Spells out the 4S456 atlas neuroanatomical labels into more readable names
% Input:  cell-array of char or string array of atlas labels
% Output: cell-array of the spelled-out labels (same size as input)

% normalize to cell-array of char
if isstring(labels)
    labels = cellstr(labels);
end
N = numel(labels);
spelled_out = cell(size(labels));

for i = 1:N
    lbl = labels{i};
    % 1) CIT168 subcortex/thalamus: hyphens → use mapSubcortical
    if contains(lbl, '-')
        parts   = strsplit(lbl, '-');
        hemi    = mapHemisphere(parts{1});
        regAbbr = parts{2};
        % handle compounds like SNc_PBP_VTA
        subRegs  = strsplit(regAbbr, '_');
        fullRegs = cellfun(@mapSubcortical, subRegs, 'UniformOutput', false);
        spelled_out{i} = sprintf('%s - %s', hemi, strjoin(fullRegs, ' / '));
        continue
    end

    % split on underscores
    parts = strsplit(lbl, '_');
    % 2a) Two-part, hemisphere + region (e.g. 'LH_Hippocampus')
    if numel(parts)==2 && ismember(parts{1}, {'LH','RH'})
        hemi        = mapHemisphere(parts{1});
        regionName  = regexprep(lower(strrep(parts{2},'_',' ')), '(^|\s)(\w)', '${upper($2)}');
        spelled_out{i} = sprintf('%s - %s', hemi, regionName);
        continue
    end

    % 2b) Two-part, no hemisphere (e.g. 'Cerebellar_Region1')
    if numel(parts)==2
        regionName  = regexprep(lower(strrep(lbl,'_',' ')), '(^|\s)(\w)', '${upper($2)}');
        spelled_out{i} = regionName;
        continue
    end

    % 3) Three-part: hemi_network_number
    if numel(parts)==3 && all(isstrprop(parts{3}, 'digit'))
        hemi = mapHemisphere(parts{1});
        net  = mapNetwork(parts{2});
        num  = parts{3};
        spelled_out{i} = sprintf('%s - %s %s', hemi, net, num);
        continue
    end

    % 4) Four-part: hemi_network_region_number
    if numel(parts)==4
        hemi   = mapHemisphere(parts{1});
        net    = mapNetwork(parts{2});
        region = mapRegion(parts{2}, parts{3});
        num    = parts{4};
        spelled_out{i} = sprintf('%s - %s - %s %s', hemi, net, region, num);
        continue
    end

    % fallback: remove other stuff...symbols, fisnish trimming of the entire label
    spelled_out{i} = regexprep(lower(strrep(lbl,'_',' ')), '(^|\s)(\w)', '${upper($2)}');
end
end

%% Helper functions

function h = mapHemisphere(code)
switch code
    case 'LH', h = 'Left Hemisphere';
    case 'RH', h = 'Right Hemisphere';
    otherwise,  h = code;
end
end

function n = mapNetwork(abbr)
switch abbr
    case 'Vis',           n = 'Visual Network';
    case 'SomMot',        n = 'Somatomotor Network';
    case 'DorsAttn',      n = 'Dorsal Attention Network';
    case 'SalVentAttn',   n = 'Salience/Ventral Attention Network';
    case 'Limbic',        n = 'Limbic Network';
    case 'Cont',          n = 'Control Network';
    case 'Default',       n = 'Default Mode Network';
    otherwise,            n = abbr;
end
end

function r = mapRegion(net, abbr)
switch net
    case 'DorsAttn'
        switch abbr
            case 'Post',  r = 'Posterior';
            case 'FEF',   r = 'Frontal Eye Fields';
            case 'PrCv',  r = 'Precentral Visual';
            otherwise,    r = abbr;
        end
    case 'SalVentAttn'
        switch abbr
            case 'ParOper',    r = 'Parietal Operculum';
            case 'TempOcc',    r = 'Temporal Occipital';
            case 'FrOperIns',  r = 'Frontal Operculum/Insula';
            case 'PFCl',       r = 'Lateral Prefrontal Cortex';
            case 'Med',        r = 'Medial';
            otherwise,         r = abbr;
        end
    case 'Limbic'
        switch abbr
            case 'OFC',      r = 'Orbitofrontal Cortex';
            case 'TempPole', r = 'Temporal Pole';
            otherwise,       r = abbr;
        end
    case 'Cont'
        switch abbr
            case 'Par',    r = 'Parietal';
            case 'Temp',   r = 'Temporal';
            case 'OFC',    r = 'Orbitofrontal Cortex';
            case 'PFCl',   r = 'Lateral Prefrontal Cortex';
            case 'PFCv',   r = 'Ventral Prefrontal Cortex';
            case 'pCun',   r = 'Precuneus';
            case 'Cing',   r = 'Cingulate';
            case 'PFCmp',  r = 'Medial Prefrontal Cortex';
            otherwise,     r = abbr;
        end
    case 'Default'
        switch abbr
            case 'Temp',      r = 'Temporal';
            case 'Par',       r = 'Parietal';
            case 'PFC',       r = 'Prefrontal Cortex';
            case 'pCunPCC',   r = 'Precuneus/Posterior Cingulate Cortex';
            otherwise,        r = abbr;
        end
    otherwise
        r = abbr;
end
end

function name = mapSubcortical(abbr)
% Maps CIT168 subcortical abbreviations to full neuroanatomical names
switch abbr
    case 'Pu',   name = 'Putamen';
    case 'Ca',   name = 'Caudate Nucleus';
    case 'GPe',  name = 'External Globus Pallidus';
    case 'GPi',  name = 'Internal Globus Pallidus';
    case 'STH',  name = 'Subthalamic Nucleus';
    case 'SNr',  name = 'Substantia Nigra Pars Reticulata';
    case 'HTH',  name = 'Hypothalamus';
    case 'HN',   name = 'Habenular Nucleus';
    case 'VeP',  name = 'Ventral Pallidum';
    case 'NAC',  name = 'Nucleus Accumbens';
    case 'SNc',  name = 'Substantia Nigra Pars Compacta';
    case 'PBP',  name = 'Parabrachial Pigmented Nucleus';
    case 'VTA',  name = 'Ventral Tegmental Area';
    case 'EXA',  name = 'Extended Amygdala';
    case 'RN',   name = 'Red Nucleus';
    case 'MN',   name = 'Mammillary Nucleus';
    otherwise,   name = abbr;
end
end
