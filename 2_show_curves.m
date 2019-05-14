clear all;
addpath('.\utils');

% Specify methods to evaluate
methods = [dir(['.\matches\FM*'])];

thresh = 0:0.001:0.50;
h1=figure(1);

for met=1:size(methods,1)
    % Load method
    name_method = methods(met).name;
    disp(name_method);
    names_ = dir(['.\evaluation\',name_method,'\']);
    names = sort({names_.name})';

    my_mean_curve = zeros(1,501);
    prev_mean_curve = zeros(1,501);
    my_mean_err=0;
    prev_mean_err=0;
    n=0;
 
    % Load curves
    for j=3:size(names,1)
        pairs = names{j};
        C = strsplit(pairs,{'_','.'});
        n=n+1;
        my_e=load(['.\evaluation\',name_method,'\',pairs]);
        
        assert(not(logical(sum(isnan(my_e.curve)))));
        assert(not(logical(sum(isnan(my_e.err)))));

        my_mean_curve=my_mean_curve+my_e.curve;
        my_mean_err=my_mean_err+mean(my_e.err);
    end
    
    % Mean curve and error
    my_mean_curve=my_mean_curve./n;
    my_mean_err=my_mean_err./n;

    set(0, 'currentfigure', h1);      
             plot(thresh, my_mean_curve, 'linewidth', 2);   hold on;  
               set(gca, 'xlim', [0 max(thresh)]); set(gca, 'ylim', [0 100]);
              set(gca, 'xgrid', 'on'); set(gca, 'ygrid', 'on');

    save(['./',name_method,'.mat'],'my_mean_curve','my_mean_err');
    disp(mean(my_mean_err));
end

m = {methods.name};
labels= strcat(erase(erase(m,'_new'),'i')');
legend(labels, 'Location','southeast', 'Interpreter', 'none')