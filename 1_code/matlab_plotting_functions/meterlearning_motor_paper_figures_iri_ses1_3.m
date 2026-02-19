function meterlearning_motor_paper_figures_iri_ses1_3

%% --- PREAMBLE

% Get parameters file
params = meterlearning_motor_get_params();

plot_type = 'scatter'; % 'scatter' or 'boxchart'

% figure parameters
figure_number = 1; % 1 or 2
fig_size = [1 1 5.8 4]; % [1 1 8.7 4] for non compressed
fontname = 'Arial';
labels_fontsize = 7;
labels_fontweight = 'normal';
training_labels_fontweight = 'bold';
labels_linewidth = 0.6;
grid_linewidth = 0.5;
plot_linewidth = 0.3;
% colors = {'','#008A69','#DB5829','#1964B0'};
colors = {repmat(0.7,1,3),[201 92 46]./256,[49 112 183]./256,'k'};



if figure_number == 1

    for i_grp = 1:2
        for i_ses = 3%[1 3]

            figure('Units','centimeters','Position',fig_size)

            for i_cond = 2:3
                
                iri     = NaN(20,2000);
                i_sub   = 1;

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

                        xPos = repmat(i_sub + (i_cond-2)*20, numel(iri_to_plot),1);
                        boxchart(xPos, iri_to_plot, ...
                                    'MarkerStyle','none', ...
                                    'WhiskerLineStyle','none', ...
                                    'LineWidth', plot_linewidth, ...
                                    'BoxFaceColor','k'); hold on              
                    end
                else
                %% ---- MEDIAN + INTER QUARTILE INTERVALS    

                    for i_sub = 1:length(median_iri)

                        xPos = i_sub + (i_cond-2)*20;
                        % plot scatter points
                        scatter(xPos, median_iri(i_sub),'MarkerFaceColor','k', ...
                                                                     'MarkerEdgeColor','k', ...
                                                                     'SizeData',5); hold on % 10 in non-compressed version
                        % plot quartiles                                          
                        line([xPos xPos],[quantile_iri(i_sub,1) quantile_iri(i_sub,2)],...
                             'Color','k')             
                    end           
                end    
            end

            %% ---- LAYOUT

            set(gca,'FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname, ...
                    'TickDir','out','LineWidth',labels_linewidth, ...
                    'yTick',0.2:0.2:1.4,'xTick',0:5:40)
            ax = gca;
            ax.YGrid = 'on';            
            ylim([0.3 1.8])
            xlim([0 41])
            ylabel('Inter-response intervals (ms)','FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname)
            xlabel('Participants','FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname)

            line_color = {colors{2};colors{2};colors{3};colors{3}};
            ylines = [0.4, 0.8, 0.6, 1.2];

            for i_line = 1:4
                line([0, 41],[ylines(i_line), ylines(i_line)], ...
                        'Color',line_color{i_line},'LineStyle','--','LineWidth',grid_linewidth)
            end 

            %% ---- TRAINING BANNERS
                    
            % banner coordinates
            xb1 = [0.5 40.5 40.5 0.5];
            yb1 = [1.6 1.6 1.78 1.78]; 
            xb2 = [0.5 20.5 20.5 0.5];
            yb2 = [1.4 1.4 1.58 1.58];            
            xb3 = [20.7 40.5 40.5 20.7];
            yb3 = [1.4 1.4 1.58 1.58];
            
            % Small patch to cover axis line
            all_x = [xb1, xb2, xb3];
            all_y = [yb1, yb2, yb3];            

            x_min = min(all_x);
            x_max = max(all_x);
            y_min = min(all_y);
            y_max = max(all_y);
            
            patch([x_min-1 x_max+1 x_max+1 x_min-1], [y_min+0.01 y_min+0.01 y_max+0.1 y_max+0.1], 'w', ...
                  'EdgeColor','none', 'Clipping','off')              
            
            % ses 3    
            patch(xb1, yb1, colors{1}, 'EdgeColor','none', ... 
                'Clipping','on', 'HandleVisibility','off');            
            text(20.5, mean(yb1), 'Post-movement', ...
                'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
                'FontSize', labels_fontsize-1, 'FontName', fontname, ...
                'FontWeight',training_labels_fontweight, 'Color','k', ...
                'Clipping','on', 'HandleVisibility','off'); 

            % 1–20: 3-beat metre
            patch(xb2, yb2, colors{2}, 'EdgeColor','none', ... % [0.8588 0.3451 0.1608]
                'Clipping','on', 'HandleVisibility','off');
            
            text(10.5, mean(yb2), '3-beat metre condition', ...
                'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
                'FontSize', labels_fontsize-1, 'FontName', fontname, ...
                'FontWeight',labels_fontweight, 'Color','k', ...
                'Clipping','on', 'HandleVisibility','off');

            % 21–40: 4-beat metre
            patch(xb3, yb3, colors{3}, 'EdgeColor','none', ... % [0.0000 0.5412 0.4118]
                'Clipping','on', 'HandleVisibility','off');
            
            text(30.5, mean(yb3), '4-beat metre condition', ...
                'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
                'FontSize', labels_fontsize-1, 'FontName', fontname, ...
                'FontWeight',labels_fontweight, 'Color','k', ...
                'Clipping','on', 'HandleVisibility','off');
            
            % save banner specificities
            yl = ylim(gca); yh = diff(yl);
            xl = xlim(gca); xw = diff(xl);
            
            spec = struct();
            spec.height_rel1  = (max(yb1) - min(yb1)) / yh;
            spec.top_pad_rel1 = (yl(2) - max(yb1)) / yh;
            spec.height_rel2  = (max(yb2) - min(yb2)) / yh;
            spec.top_pad_rel2 = (yl(2) - max(yb2)) / yh;
            
            spec.left_rel         = (min(xb1) - xl(1)) / xw;   % = min(xb2)
            spec.right_rel        = (max(xb1) - xl(1)) / xw;   % = max(xb3)
            spec.split_left_rel   = (max(xb2) - xl(1)) / xw;   % right edge of LEFT banner
            spec.split_right_rel  = (min(xb3) - xl(1)) / xw;   % left edge of RIGHT banner
            
            save(fullfile(params.experiment_path,'1_code/matlab_plotting_functions','banner_spec.mat'), 'spec');
                           
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
end       

end



function spec = captureBannerSpec(ax, xb, yb)
% xb,yb are the 4-vertex coordinates you used to draw the reference banner (patch)
    yl = ylim(ax); yh = diff(yl);
    xl = xlim(ax); xw = diff(xl);

    spec = struct();
    spec.height_rel   = (max(yb) - min(yb)) / yh;   % banner height (% of y-range)
    spec.top_pad_rel  = (yl(2) - max(yb)) / yh;     % gap from top (% of y-range)

    % defaults you can tweak later
    spec.vgap_rel     = 0.02;   % vertical gap between stacked rows (in % of y-range)
    spec.default_x0_rel = 0.0;  % full-width by default
    spec.default_x1_rel = 1.0;
end

