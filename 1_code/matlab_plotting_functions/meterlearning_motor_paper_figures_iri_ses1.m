function meterlearning_motor_paper_figures_iri_ses1

%% --- PREAMBLE

% Get parameters file
params = meterlearning_motor_get_params();
i_ses = 1;
plot_type = 'scatter'; % 'scatter' or 'boxchart'

% figure parameters
fig_size = [1 1 5.8 4];
fontname = 'Arial';
labels_fontsize = 7;
labels_fontweight = 'normal';
training_labels_fontweight = 'bold';
labels_linewidth = 0.6;
grid_linewidth = 0.5;
plot_linewidth = 0.3;
colors = {repmat(0.7,1,3),[201 92 46]./256,[49 112 183]./256,'k'};
% colors = {'','#008A69','#DB5829','#1964B0'};


for i_grp = 1:2

    figure('Units','centimeters','Position',fig_size)
    
    iri     = NaN(40,2000);
    i_sub   = 1;    

    for i_cond = 2:3

        participants = params.(sprintf('grp%i_cond%i',i_grp,i_cond));
        
        for participant = participants  

            % preallocate
            temp_iri = []; 

            % import path
            path_iri    = fullfile(params.path_output, 'data/4_final/clap/iri', ...
                                sprintf('grp-%03d/cond-%03d/sub-%03d', i_grp, i_cond, participant));

            % load the iri for each trial
            for i_trial = 1:5
                name_iri = sprintf('grp-%03d_cond-%03d_sub-%03d__ses-%03d_trial-%02d_iri.csv', ...
                                    i_grp, i_cond, participant, i_ses, i_trial);
                data     = table2array(readtable(fullfile(path_iri,name_iri)));     
                temp_iri = [temp_iri; data]; 
            end

            % get the median
            median_iri(i_sub)     = nanmedian(temp_iri);
            quantile_iri(i_sub,:) = quantile(temp_iri,[0.25 0.75]); 

            % store iri 
            iri(i_sub, 1:length(temp_iri)) = temp_iri;                
            i_sub = i_sub + 1;
        end         
    end
    
    %% ---- SORT DATA
    % sort median IRI
    [~, sorted_idx] = sort(median_iri);          
    iri             = iri(sorted_idx,:); 
    median_iri      = median_iri(sorted_idx);
    quantile_iri    = quantile_iri(sorted_idx,:); 
    
    %% ---- BOXCHART
    if strcmp(plot_type,'boxchart')

        for i_sub = 1:size(iri,1)

            % select iri for each participant
            iri_to_plot = iri(i_sub, :);
            iri_to_plot = iri_to_plot(~isnan(iri_to_plot));

            xPos = repmat(i_sub, numel(iri_to_plot),1);
            boxchart(xPos, iri_to_plot, ...
                        'MarkerStyle','none', ...
                        'WhiskerLineStyle','none', ...
                        'LineWidth', plot_linewidth, ...
                        'BoxFaceColor','k'); hold on              
        end
    else
    %% ---- MEDIAN + INTER QUARTILE INTERVALS    
 
        for participant = 1:length(median_iri)

            % plot scatter points
            scatter(participant, median_iri(participant),'MarkerFaceColor','k', ...
                                                         'MarkerEdgeColor','k', ...
                                                         'SizeData',5); hold on % 10 in non-compressed version
            % plot quartiles                                          
            line([participant participant],[quantile_iri(participant,1) quantile_iri(participant,2)],...
                 'Color','k')             
        end           
    end    
    
    %% ---- LAYOUT

    set(gca,'FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname, ...
            'TickDir','out','LineWidth',labels_linewidth, ...
            'yTick',0.2:0.2:1.4,'xTick',0:5:40)
    ax = gca;
    ax.YGrid = 'on';
    ylim([0.3 1.8])
    xlim([0 size(iri,1)+1])
    ylabel('Inter-response intervals (ms)','FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname)
    xlabel('Participants','FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname) % only useful for correct figure sizing compared to the other session
   
    line_color = {colors{2};colors{2};colors{3};colors{3}};
    ylines = [0.4, 0.8, 0.6, 1.2];

    for i_line = 1:4
        line([0, size(iri,1)+1],[ylines(i_line), ylines(i_line)], ...
                'Color',line_color{i_line},'LineStyle','--','LineWidth',grid_linewidth)
    end

    %% ---- TRAINING BANNERS
    
    % Small patch to cover axis line    
%     patch([0.5-1 40.5+1 40.5+1 0.5-1], ...
%           [1.4+0.01 1.4+0.01 1.78+0.1 1.78+0.1], 'w', ...
%           'EdgeColor','none', 'Clipping','off')       
    
    % ses 3
    xb = [0.5 40.5 40.5 0.5];
    yb = [1.6 1.6 1.78 1.78]; 
    patch(xb, yb, colors{1}, 'EdgeColor','none', ... 
        'Clipping','on', 'HandleVisibility','off');            
    text(20.5, mean(yb), 'Pre-movement', ...
        'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
        'FontSize', labels_fontsize-1, 'FontName', fontname, ...
        'FontWeight',training_labels_fontweight, 'Color','k', ...
        'Clipping','on', 'HandleVisibility','off');  
    
    % legend
    ax = gca;                             
    L = findobj(ax,'Type','line');      
    h = L(1:3);                    
    lgd = legend(ax, h([3 1]), {["3-beat metre" + newline + "periodicities"],["4-beat metre" + newline + "periodicities"]}, ...
                 'Color','w', 'Position', [0.4280,0.6210,0.4535,0.1710]);
    lgd.Box = 'off';  
   
    
    %% ---- PRINT
    
    export_path = fullfile(params.path_plot,'paper');    
    if ~isdir(export_path)
        mkdir(export_path);
    end
    
    fig_name = sprintf('Fig1a - grp%i - ses%i - %s.svg', i_grp, i_ses, plot_type);
    print(gcf,'-dsvg','-painters',fullfile(export_path,fig_name))
    
    close all
    
end
end

