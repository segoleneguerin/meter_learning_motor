function meterlearning_motor_paper_figures_clap_zscores_main_effect_cond(analysis_type, normalization, disp_stim_zscore)

%% --- PREAMBLE

if analysis_type == 1 || analysis_type == 7
    error('No main effect of condition for this analysis type')
end

% Get parameters file
params = meterlearning_motor_get_params();

% figure parameters
fig_size            = [1 1 2 4]; % [1 1 8.7 3.5] for non compressed figure
fontname            = 'Arial';
labels_fontsize     = 7;
labels_fontweight   = 'normal';
labels_linewidth    = 0.6;
grid_linewidth      = 0.5;
plot_linewidth      = 0.3;
colors              = {repmat(0.7,1,3),[201 92 46]./256,[49 112 183]./256,'k'};

x = [1 2.5];


%% STIMULUS

tbl_stim = readtable('/Users/emmanuelcoulon/Documents/MATLAB/PROJECTS/meterlearning_av/0_data/stimuli/stimulus_zscore.csv');

for i_cond = 2:3
    
    % extract the correct metrical interpretation 
    if analysis_type >= 5
        if i_cond == 2
            metrical_interp = 23;
        elseif i_cond == 3
            metrical_interp = 32;
        end
    elseif analysis_type == 4
        error('not coded yet')
    else
        metrical_interp = i_cond;
    end 

    if analysis_type == 1 || analysis_type == 5
        z_name = 'zscore_freq_rel';
    elseif analysis_type == 3 || analysis_type == 7
        z_name = 'norm_zscore_freq_rel';
    end     
    
    % stimulus zscore
    idx = find(tbl_stim.metrical_interp == metrical_interp);
    z_stim(i_cond) = tbl_stim.(z_name)(idx);
end

%% PLOT
for i_grp = 1
    
    %% ---- LOAD DATA (FROM R WITH OUTLIER CORRECTION)
    path_z_scores_motor   = '/Users/emmanuelcoulon/Documents/MATLAB/PROJECTS/meterlearning_motor/2_output/plots/paper';
    filename_motor        = ['data_file_clap_grp',num2str(i_grp),'_analysis_type',num2str(analysis_type),'_outliers_corrected.csv'];
    tbl_z_scores_motor    = readtable(fullfile(path_z_scores_motor,filename_motor)); 

    % name of the dependant variable
    % the subtraction of the stimulus for analysis_type 3 and 7 is done in R
    if normalization || analysis_type == 3 || analysis_type == 7
        z_name = 'norm_zscore_freq_rel';
    else
        z_name = 'zscore_freq_rel';
    end    
    
    % figure
    i_pos = 1;
    figure('Units','centimeters','Position',fig_size)
    
    for i_cond = [2,3]         

        sub_idx = find(tbl_z_scores_motor.group == i_grp & ...
                       tbl_z_scores_motor.condition == i_cond );

        % zscore
        z_scores = tbl_z_scores_motor.(z_name)(sub_idx);    
        
        % boxplot
        xPos  = repmat(x(i_pos), numel(sub_idx), 1);

        boxchart(xPos, z_scores, ...
                    'MarkerStyle','none', 'BoxWidth', 0.5, ...
                    'LineWidth', plot_linewidth+0.3, ...
                    'WhiskerLineStyle','none', ...
                    'BoxFaceColor',colors{i_cond})  
        hold on 
                       
        % scatter
        markerFaceColor = colors{i_cond};
        xJitter         = (rand(size(sub_idx)) - 0.5) * 0.2;
        xPos_jittered   = xPos + xJitter;
        
        scatter(xPos_jittered, z_scores, ...
                'SizeData', 8, 'LineWidth', grid_linewidth-0.3, ...
                'MarkerEdgeColor',colors{i_cond}, ...
                'MarkerFaceColor',markerFaceColor, 'MarkerFaceAlpha', 0.3);        

        % stim
        if disp_stim_zscore
            if analysis_type == 5
                line([x(i_pos)-0.4 x(i_pos)+0.4],[z_stim(i_cond) z_stim(i_cond)],...
                        'Color', colors{i_cond} ,'LineWidth',grid_linewidth+0.2,'LineStyle',':')
            end  
        end
        i_pos = i_pos +1;
        
    end
    
    % layout
    set(gca,'FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname, ...
        'TickDir','out','LineWidth',labels_linewidth,'box','off','XLim',[0.5 3]) 
    
    if analysis_type == 1 || analysis_type == 5
        ylabelname = 'Metre-related z score';
    else
        ylabelname = {'Norm. metre-related z score','(stim z score subtr.)'};
    end
    ylabel(ylabelname,'FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname)
    line([xlim],[0 0],'Color','k','LineWidth',labels_linewidth-0.3)
    set(gca,'XTick', x, 'XTickLabel', {'3-beat','4-beat'})
    
    
    if analysis_type == 3 || analysis_type == 5
        
        yMax = max(ylim);
        y = yMax + 0.09*range(ylim); 
        if y > 2; y=2; end
        y_bottom = (x(2)-x(1))/2;
        asterisk_center = mean(x);     

        plot([asterisk_center-y_bottom asterisk_center-y_bottom asterisk_center+y_bottom asterisk_center+y_bottom],...
             [y-0.1*y y y y-0.1*y],'k','LineWidth',plot_linewidth,'HandleVisibility','off');
        text(asterisk_center, y-0.1*y, '**', 'HorizontalAlignment','center', 'VerticalAlignment','bottom','FontSize',labels_fontsize+2);         
    end

    % --- indicate zscore range
    if ~normalization
        if analysis_type == 5
            % 3_beat
            lowest_3_beat   = -1.449137674618944;
            highest_3_beat  = -lowest_3_beat;
            % 4_beat
            lowest_4_beat   = -1.897366596101027;
            highest_4_beat  = -lowest_4_beat;        

        elseif analysis_type == 3
            % 3_beat
            lowest_3_beat   = -1 - z_stim(2); 
            highest_3_beat  = 1 - z_stim(2);
            % 4_beat
            lowest_4_beat   = -1 - z_stim(3);
            highest_4_beat  = 1 - z_stim(3);
        end
        line([x(1)-0.4 x(1)-0.4],[lowest_3_beat highest_3_beat],'Color', colors{2} ,'LineWidth',grid_linewidth+0.2)
        line([x(2)-0.4 x(2)-0.4],[lowest_4_beat highest_4_beat],'Color', colors{3} ,'LineWidth',grid_linewidth+0.2)
    end
    
    % ylim (do it here so that the asterisk is placed correctly)
    if analysis_type == 3 
        set(gca,'Ylim',[-1 3],'YTick',-1:1:2) 
    elseif analysis_type == 5
        set(gca,'Ylim',[-1 3],'YTick',-2:1:2) 
    end

    %% ---- PRINT
    export_path = fullfile(params.path_plot,'paper',['analysis_type',num2str(analysis_type)]);  
    if ~isdir(export_path)
        mkdir(export_path);
    end

    fig_name = sprintf('Fig1c - grp%i - main effect condition.svg', i_grp);
    print(gcf,'-dsvg','-painters',fullfile(export_path,fig_name))

    close all 

end

end

