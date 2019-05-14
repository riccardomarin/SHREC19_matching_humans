% % % % % % % % % % %
%
% This code process the matches and generate the evaluation curves. They
% are stored in "path_saving" directory. 
%
% This code is provided as evaluation of:
% SHREC 2019: Matching Humans with Different Connectivity
% S. Melzi, R. Marin, E. Rodolà, U. Castellani, J. Ren, A. Poulenard, P.
% Wonka, M. Ovjanikov
% 
% For any doubt or comment, please contact me: 
% riccardo.marin_01@univr.it
% 
% % % % % % % % % % %

clear all; clc; close all; 
addpath('./utils');

%%
% Useful paths
path_matches = '.\matches\';
path_data    = '.\mat\';
path_saving  = '.\evaluation\';

% Specify methods to evaluate
methods = [dir(['.\matches\FM*'])];

%Read Pairs
challenge_PAIRS = csvread('.\PAIRS_list_SHREC19_connectivity.txt');
n_pairs = size(challenge_PAIRS,1);
    
for met=1:size(methods,1)
    
    % Select n-th method
    name_method = methods(met).name;
    disp(name_method);

    for i = 1:size(challenge_PAIRS,1) % n_pairs
        
        % load shapes
        pair = challenge_PAIRS(i,:);
        name_pair = [int2str(pair(1,1)),'_',int2str(pair(1,2))];
        pair_1 = load([path_data,int2str(pair(1,1))]);
        pair_2 = load([path_data,int2str(pair(1,2))]);

        disp(['- pair ',num2str(i),'/',num2str(n_pairs),' = ',pair_1.name,'-',pair_2.name])

        % load matches for the method
        try
            try
                matches = dlmread([path_matches,name_method,'\',name_pair,'.txt']);
            catch
                matches = dlmread([path_matches,name_method,'\',name_pair,'.map']);
            end
        catch
        name_pair2 = [int2str(pair(1,1)),',',int2str(pair(1,2))];
        matches = dlmread([path_matches,name_method,'\',name_pair2,'.txt']);
        end
        
        % pick 6890 FARM correspondences
        c_matches=matches(pair_1.smpl_matches);
        % load gt matches
        gt_matches = dlmread([path_matches,'FARMgt_txt\',name_pair,'.txt']);
        c_gt_matches=gt_matches(pair_1.smpl_matches);

        % uniqueness of vertex list (required by distances method)
        [src_idx, src_ia, src_ic]=unique(c_matches);
        [sink_idx, sink_ia, sink_ic]=unique(c_gt_matches);

        % Compute dijkstra over graph
        geo_d = distances(pair_2.G,src_idx,sink_idx);
        
        % come back to 6890 x 6890 of distance between FARM_gt and method
        dist_matrix = geo_d(src_ic,sink_ic);
        
        % if matches are on disconnected components, we use euclidean
        % metric
        
        [ii, jj] = find(isinf(dist_matrix));
        if not(isempty(ii))
            eucl=vecnorm(pair_2.Shape_df.VERT(c_matches(ii),:)-pair_2.Shape_df.VERT(c_gt_matches(jj),:),2,2);
            idx = sub2ind(size(dist_matrix),ii,jj);
            dist_matrix(idx)=eucl;
        end

        % Normalize error
        err = diag(dist_matrix);
        diam = max(max(dist_matrix));
        
        err_raw = err;
        err = err ./ diam; 

        % Compute Curve
        curve_raw = calc_err_curve(err_raw, [0:0.001:0.1]);
        thresh = 0:0.001:0.50;
        curve = calc_err_curve(err, thresh);

        % save
        path_save = [path_saving,name_method];
        if(~exist(path_save))
            mkdir(path_save)
        end
        save([path_save,'\',name_pair,'.mat'],'curve','err','curve_raw','err_raw','thresh','-v7.3');
    end
end