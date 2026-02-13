

function meterlearning_motor_paper_figures_clap_zscores(analysis_type, normalization, disp_stim_zscore)

%% --- PREAMBLE

% Get parameters file
params = meterlearning_motor_get_params();

% figure parameters
fig_size            = [1 1 5.8 4]; % [1 1 8.7 3.5] for non compressed figure
fontname            = 'Arial';
labels_fontsize     = 7;
labels_fontweight   = 'normal';
labels_linewidth    = 0.6;
grid_linewidth      = 0.5;
plot_linewidth      = 0.3;
colors              = {repmat(0.7,1,3),[201 92 46]./256,[49 112 183]./256,'k'};

% x = [1.6 2.2 3.4 4];
x = [1.6 2.2 3.3 3.9];

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


for i_grp = 1:2
    
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
         
    
    %% ---- FIGURE
    i_pos = 1;

    figure('Units','centimeters','Position',fig_size)

    for i_cond = [2,3]
        for i_ses = [1,3]
                     
            
            sub_idx = find(tbl_z_scores_motor.group == i_grp & ...
                           tbl_z_scores_motor.session == i_ses & ...
                           tbl_z_scores_motor.condition == i_cond );

            % zscore
            z_scores(:,i_ses) = tbl_z_scores_motor.(z_name)(sub_idx);  
            
            % boxplot
            xPos  = repmat(x(i_pos), numel(sub_idx), 1);
            
            boxchart(xPos, z_scores(:,i_ses), ...
                        'MarkerStyle','none', 'BoxWidth', 0.5, ...
                        'LineWidth', plot_linewidth+0.3, ...
                        'WhiskerLineStyle','none', ...
                        'BoxFaceColor',colors{i_cond})  
            hold on    
            
            % scatter       
            if i_ses == 1
                % maintain the same jitter across sessions
                xJitter = (rand(size(sub_idx)) - 0.5) * 0.2;
            end
        
            xPos_jittered(:,i_ses) = xPos + xJitter;
            scatter(xPos_jittered(:,i_ses), z_scores(:,i_ses), ...
                    'SizeData', 8, 'LineWidth', grid_linewidth-0.3, ...
                    'MarkerEdgeColor',colors{i_cond}, ...
                    'MarkerFaceColor',colors{i_cond}, 'MarkerFaceAlpha', 0.3);
                
            % parallel plot
            if i_ses == 3
                for i_sub = 1:length(z_scores)
                    plot(xPos_jittered(i_sub,[1,3]), z_scores(i_sub,[1,3]), ...
                        'Color',repmat(0.8, 1, 3))
                end
            end

            % stim  
            if disp_stim_zscore
                if analysis_type == 1 ||  analysis_type == 5
                    line([x(i_pos)-0.4 x(i_pos)+0.4],[z_stim(i_cond) z_stim(i_cond)],...
                            'Color', colors{i_cond} ,'LineWidth',grid_linewidth+0.2,'LineStyle',':')
                end
            end
            
            i_pos = i_pos +1;
        end
    end

    % layout
    set(gca,'FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname, ...
        'TickDir','out','LineWidth',labels_linewidth,'box','off','XLim',[1.2 4.4])

    if (normalization && analysis_type == 1) || (normalization && analysis_type == 5)
        ylabelname = {'Norm. Metre-related z Score'};
    elseif analysis_type == 1 || analysis_type == 5
        ylabelname = 'Metre-related z Score';
    else
        ylabelname = {'Norm. Metre-related z Score','(Stim z Score Subtr.)'};
    end
    
    ylabel(ylabelname,'FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname)
    line([1 max(xlim)],[0 0],'Color','k','LineWidth',labels_linewidth-0.3)
    set(gca,'XTick', x, 'XTickLabel', {'Pre','Post','Pre','Post'})
    if analysis_type == 3 || analysis_type == 7
        ytick = -1:0.5:1.5;
    else 
        ytick = -1:0.5:1;
    end
    set(gca,'YLim', [-1 3],'YTick',ytick)
         
    % --- Statistical Asterisk
    if (analysis_type == 1 && i_grp == 1) || (analysis_type == 3 && i_grp == 1)

        yMax = max(ylim);
        y = yMax + 0.09*range(ylim);  % yMax + 0.065*range(ylim); 
        y_bottom = 0.3;
        tick_positions(1) = mean(x([1,2]));
        tick_positions(2) = mean(x([3,4]));
        xL = tick_positions(2 - 1);
        xR = tick_positions(2);
        
        % main brackets 
        % plot([xL xL xR xR],[y y+0.1*y y+0.1*y y],'k','LineWidth',plot_linewidth,'HandleVisibility','off');
%         text(mean([xL xR]), y+0.025*y, '***', 'HorizontalAlignment','center', ...
%                  'VerticalAlignment','bottom','FontSize',labels_fontsize+2);   
        
        % sub brackets
        plot([xL-y_bottom xL-y_bottom xL+y_bottom xL+y_bottom],[y-0.1*y y y y-0.1*y],'k','LineWidth',plot_linewidth,'HandleVisibility','off');
        plot([xR-y_bottom xR-y_bottom xR+y_bottom xR+y_bottom],[y-0.1*y y y y-0.1*y],'k','LineWidth',plot_linewidth,'HandleVisibility','off');
        text(xL, y-0.1*y, '***', 'HorizontalAlignment','center', 'VerticalAlignment','bottom','FontSize',labels_fontsize+2);         
        text(xR, y-0.1*y, '***', 'HorizontalAlignment','center', 'VerticalAlignment','bottom','FontSize',labels_fontsize+2);   
     
    end

    % --- indicate zscore range
    if analysis_type == 3 || analysis_type == 7 || ~normalization
        if analysis_type == 1
            % 3_beat
            lowest_3_beat   = -1.897366596101027; 
            highest_3_beat  = -lowest_3_beat;
            % 4_beat
            lowest_4_beat   = -1.161895003862225;
            highest_4_beat  = -lowest_4_beat;

        elseif analysis_type == 5
            % 3_beat
            lowest_3_beat   = -1.449137674618944;
            highest_3_beat  = -lowest_3_beat;
            % 4_beat
            lowest_4_beat   = -1.897366596101027;
            highest_4_beat  = -lowest_4_beat;        

        elseif analysis_type == 3 || analysis_type == 7
            % 3_beat
            lowest_3_beat   = -1 - z_stim(2); 
            highest_3_beat  = 1 - z_stim(2);
            % 4_beat
            lowest_4_beat   = -1 - z_stim(3);
            highest_4_beat  = 1 - z_stim(3);
        end
        %line([x(1)-0.3 x(1)-0.3],[lowest_3_beat highest_3_beat],'Color', colors{2} ,'LineWidth',grid_linewidth+0.2)
        line([x(2)+0.3 x(2)+0.3],[lowest_3_beat highest_3_beat],'Color', colors{2} ,'LineWidth',grid_linewidth+0.2)
        line([x(3)-0.3 x(3)-0.3],[lowest_4_beat highest_4_beat],'Color', colors{3} ,'LineWidth',grid_linewidth+0.2)
    end
    
    % ---- BANNERS
    xb1 = [1.2390 2.7922 2.7922 1.2390];
    xb2 = [2.8078 4.3610 4.3610 2.8078];
    yb  = [2.0800, 2.0800, 2.7476, 2.7476];
    
    % 3 beat metre
    patch(xb1, yb, colors{2}, 'EdgeColor','none', ... 
        'Clipping','on', 'HandleVisibility','off');

    text(mean(xb1), mean(yb), '3-Beat Metre Condition', ...
        'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
        'FontSize', labels_fontsize-1, 'FontName', fontname, ...
        'FontWeight',labels_fontweight, 'Color','k', ...
        'Clipping','on', 'HandleVisibility','off');      
    
    % 4 beat metre
    patch(xb2, yb, colors{3}, 'EdgeColor','none', ... 
        'Clipping','on', 'HandleVisibility','off');

    text(mean(xb2), mean(yb), '4-Beat Metre Condition', ...
        'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
        'FontSize', labels_fontsize-1, 'FontName', fontname, ...
        'FontWeight',labels_fontweight, 'Color','k', ...
        'Clipping','on', 'HandleVisibility','off');     

    %% ---- PRINT
    export_path = fullfile(params.path_plot,'paper',['analysis_type',num2str(analysis_type)]);  
    if ~isdir(export_path)
        mkdir(export_path);
    end

    fig_name = sprintf('Fig1c - grp%i - norm%1- stim%i.svg', i_grp, normalization, disp_stim_zscore);
    print(gcf,'-dsvg','-painters',fullfile(export_path,fig_name))

    close all    
    
end
end

