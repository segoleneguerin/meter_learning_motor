function meterlearning_motor_paper_figures_eeg_spectra(analysis_type)

%% --- PREAMBLE

% Get parameters file
params = meterlearning_motor_get_params();
eeg_fft = struct();
process_data = false;

% EEG parameters
ref_method      = 'mastoids';
cluster_chan    = {'F1', 'Fz', 'F2', 'FC1', 'FCz', 'FC2', 'C1', 'Cz', 'C2'};

% figure parameters
fig_size            = [1 1 3 2]; 
fontname            = 'Arial';
labels_fontsize     = 7;
labels_fontweight   = 'normal';
training_labels_fontweight ...
                    = 'bold';
labels_linewidth    = 0.6;
grid_linewidth      = 0.5;
plot_linewidth      = 0.3;
colors = {repmat(0.7,1,3),[201 92 46]./256,[49 112 183]./256,'k'};


%% ---- SET METER-(UN)RELATED FREQUENCIES

if analysis_type == 1 || analysis_type == 3
    metRel_freq     = {[],[1.25, 3.75], ...
                          [0.83, 1.67, 3.33, 4.17]};
    metUnrel_freq   = {[],[0.83, 1.67, 2.08, 2.5, 2.92, 3.33, 4.17, 4.58], ...
                          [1.25, 2.08, 2.5, 2.92, 3.75, 4.58]};
elseif analysis_type >= 5
    metRel_freq     = {[],[1.25, 2.5, 3.75], ...
                          [1.67, 3.33]};
    metUnrel_freq   = {[],[0.83, 1.67, 2.08, 2.92, 3.33, 4.17, 4.58], ...
                          [0.83, 1.25, 2.08, 2.5, 2.92, 3.75, 4.17, 4.58]};    
end

%% 

if process_data
    for i_grp = 1:2
        
        min_all = [];
        max_all = [];
        
        for i_cond = [2 3]
            for i_ses = [1 3]

                participants = params.(sprintf('grp%i_cond%i',i_grp,i_cond));

                for i_sub = participants

                    %% ---- LOAD DATA
                    % get path and file name
                    import_path = fullfile(params.path_output, 'data/3_preprocessed/', ...
                                            sprintf('grp-%03d', i_grp), ...
                                            sprintf('cond-%03d', i_cond), ...
                                            sprintf('sub-%03d', i_sub), 'eeg');

                    filename = sprintf('grp-%03d_cond-%03d_sub-%03d_ses-%03d_ref-%s_cleaned-fft-values-per-channel.csv', ...
                                        i_grp, i_cond, i_sub, i_ses, ref_method);
                    file_freq = sprintf('grp-%03d_cond-%03d_sub-%03d_freq-values.csv', ...
                                        i_grp, i_cond, i_sub);

                    % load data                
                    mX_all_channel_clean = table2array(readtable(fullfile(import_path,filename))); 

                    freq = readmatrix(fullfile(import_path,file_freq));

                    %% ---- AVERAGE CHANNELS
                    % load header
                    filename = sprintf('grp-%03d_cond-%03d_sub-%03d_task-meterlearning-motor_session-%i_filtered_epoched_interp_cleaned-trials-ics_ref-mastoids.lw6', ...
                                        i_grp, i_cond, i_sub, i_ses);
                    [header, ~] = CLW_load(fullfile(import_path, filename));                

                    % Find row number of channels to average
                    mask = matches({header.chanlocs.labels}, cluster_chan);                

                    mX(i_sub,:)= mean(mX_all_channel_clean(mask, :), 1);                

                end

                %% ---- MEAN ACROSS PARTICIPANTS
                mX_mean = mean(mX,1);

                % update min and max across group, conditions, and sessions
                min_all = min([min_all, min(mX_mean)]);
                max_all = max([max_all, max(mX_mean)]);

                eeg_fft.(sprintf('grp_%03d', i_grp)).(sprintf('cond_%03d', i_cond)).(sprintf('ses_00%i', i_ses)) = mX_mean;

            end
        end

        eeg_fft.freq = freq;
        eeg_fft.(sprintf('grp_%03d', i_grp)).min_all = min_all;
        eeg_fft.(sprintf('grp_%03d', i_grp)).max_all = max_all;
        
        %% ---- MERGE CONDITIONS
        for i_ses = [1 3]

            mx_cond2 = eeg_fft.(sprintf('grp_%03d', i_grp)).(sprintf('cond_%03d', 2)).(sprintf('ses_%03d', i_ses));
            mx_cond3 = eeg_fft.(sprintf('grp_%03d', i_grp)).(sprintf('cond_%03d', 3)).(sprintf('ses_%03d', i_ses));


            eeg_fft.(sprintf('grp_%03d', i_grp)).(sprintf('cond_%03d', 1)).(sprintf('ses_%03d', i_ses)) ...
                = mean([mx_cond2; mx_cond3],1);  
        end
    end
    
    %% SAVE STRUCTURE
    export_path = fullfile(params.path_output, 'data/4_final/eeg');
    save(fullfile(export_path,'eeg_fft.mat'), 'eeg_fft') 
    
else
    export_path = fullfile(params.path_output, 'data/4_final/eeg');
    load(fullfile(export_path,'eeg_fft.mat'))    
end
    
for i_grp = 1:2
    %% ---- FIGURE

    for i_ses = [1 3]
        
        if i_ses == 1
            conditions = 1:3;
        else
            conditions = 2:3;
        end
        
        for i_cond = conditions
            
            figure('Units','centimeters','Position',fig_size) 
            
            mX_mean = eeg_fft.(sprintf('grp_%03d', i_grp)).(sprintf('cond_%03d', i_cond)).(sprintf('ses_%03d', i_ses));
            freq    = eeg_fft.freq;
            max_all = eeg_fft.(sprintf('grp_%03d', i_grp)).max_all;
            
            % stems            
            stem(freq, mX_mean, ...
                 'marker','none','Color',colors{1},'LineWidth',plot_linewidth); hold on              
            
            if i_cond == 1
                three_beat_idx      = dsearchn(freq', metRel_freq{2}');
                four_beat_idx       = dsearchn(freq', metRel_freq{3}');
                meter_unrelated_idx = dsearchn(freq', intersect(metUnrel_freq{2},metUnrel_freq{3})');  

                stem(freq(three_beat_idx), mX_mean(three_beat_idx), ...
                     'marker','none','Color',colors{2},'LineWidth',grid_linewidth)
                stem(freq(four_beat_idx), mX_mean(four_beat_idx), ...
                     'marker','none','Color',colors{3},'LineWidth',grid_linewidth)
                stem(freq(meter_unrelated_idx), mX_mean(meter_unrelated_idx), ...
                     'marker','none','Color',colors{4},'LineWidth',grid_linewidth)
                 
            else
                metRel_idx      = dsearchn(freq', metRel_freq{i_cond}'); 
                metUnrel_idx    = dsearchn(freq', metUnrel_freq{i_cond}');
            end             
            
            if i_cond == 2 || i_cond == 3
                stem(freq(metRel_idx), mX_mean(metRel_idx), ...
                     'marker','none','Color',colors{i_cond},'LineWidth',grid_linewidth)
                stem(freq(metUnrel_idx), mX_mean(metUnrel_idx), ...
                     'marker','none','Color',colors{4},'LineWidth',grid_linewidth) 
            end              
            
            set(gca,'FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname, ...
                    'TickDir','out','LineWidth',labels_linewidth,'box','off', ...
                    'XLim',[0 6],'xTick',0:1:6) 
            line([0 6],[0 0], 'LineWidth',labels_linewidth, 'Color', 'k')
            if i_grp == 1
                set(gca,'ylim', [0 0.15],'yTick',0:0.05:0.15)
            else
                set(gca,'ylim', [0 0.32],'yTick',0:0.15:0.3)
            end
                
            
            ylabel('Amplitude (µV)','FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname)
            xlabel('Frequency (Hz)','FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname)
            
            % ---- BANNERS
            % load banner specificities
            load(fullfile(params.experiment_path,'1_code/matlab_plotting_functions','banner_spec.mat'));            
            ensureBannerSpace(gca, spec, 2, max_all,  0.02)
            ax = gca;  xl = xlim(ax); xw = diff(xl);
            
            % Pre/post movement
            if i_ses == 1;  banner_text = 'Pre-movement';
            else;           banner_text = 'Post-movement';
            end
            yb     = bannerY(spec, gca, 1);
            x_left  = xl(1) + spec.left_rel  * xw;
            x_right  = xl(1) + spec.right_rel * xw;
            xb     = [x_left x_right x_right x_left];   
            patch(xb, yb, colors{1}, 'EdgeColor','none', ... 
                'Clipping','on', 'HandleVisibility','off');            
            text(mean(xb), mean(yb), banner_text, ...
                'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
                'FontSize', labels_fontsize-1, 'FontName', fontname, ...
                'FontWeight',training_labels_fontweight, 'Color','k', ...
                'Clipping','on', 'HandleVisibility','off');  
            
            % 3- and 4-beat metre
            if i_ses == 3
                yb     = bannerY(spec, gca, 2);
                patch(xb, yb, colors{i_cond}, 'EdgeColor','none', ... % [0.8588 0.3451 0.1608]
                    'Clipping','on', 'HandleVisibility','off');

                text(mean(xb), mean(yb), sprintf('%i-beat metre condition',i_cond+1), ...
                    'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
                    'FontSize', labels_fontsize-2, 'FontName', fontname, ...
                    'FontWeight',labels_fontweight, 'Color','k', ...
                    'Clipping','on', 'HandleVisibility','off');
            end 
            
            %% ---- PRINT
            export_path = fullfile(params.path_plot,'paper',['analysis_type',num2str(analysis_type)]);  
            if ~isdir(export_path)
                mkdir(export_path);
            end

            fig_name = sprintf('Fig2b - grp%i - cond%i- ses%i.svg', i_grp, i_cond, i_ses);
            print(gcf,'-dsvg','-painters',fullfile(export_path,fig_name))
            
            close all            
            
        end
    end
end
end



function ensureBannerSpace(ax, spec, rows, max_all, margin_rel)
% Ensure there's room for banner rows without covering data.
% ax         : target axes
% spec       : struct with fields:
%              height_rel1, top_pad_rel1  (top banner)
%              height_rel2, top_pad_rel2  (row 2 banners)
% rows       : [1]      -> only top banner
%              [1 2]    -> top + second row (your training banners)
% margin_rel : (optional) gap above data as % of y-range (default 0.02)

    if nargin < 5 || isempty(margin_rel), margin_rel = 0.02; end

    yl = ylim(ax); y1 = yl(1); y2 = yl(2); yh = y2 - y1;

    % --- 1) data max on this axes 
%     data_max = getAxisDataMax(ax);
    % a small absolute margin based on current range (before expansion)
    margin_abs = margin_rel * max(yh, eps);

    % --- 2) compute r = (top padding + height) for each requested row
    r_list = [];
    if any(rows == 1)
        r_list(end+1) = spec.top_pad_rel1 + spec.height_rel1;
    end
    if any(rows == 2)
        r_list(end+1) = spec.top_pad_rel2 + spec.height_rel2;
    end
    if isempty(r_list)
        return; % nothing to do
    end
    r_need = max(r_list);             % the lowest banner is the constraint
    r_need = min(r_need, 0.99);       % safety

    % Current bottom of that lowest banner:
    bottom_now = (1 - r_need)*y2 + r_need*y1;

    % If data would touch/overlap, solve for the y2 we need:
    target_bottom = max_all + margin_abs;
    if bottom_now < target_bottom
        % Solve (1-r)*y2 + r*y1 = target_bottom  -> y2 = (target_bottom - r*y1)/(1-r)
        new_y2 = (target_bottom - r_need*y1) / (1 - r_need);
        ylim(ax, [y1 new_y2]);
    end
end

function yb = bannerY(spec, ax, row)
% Return [y0 y0 y1 y1] for row==1 (top) or row==2 (second row)
    yl = ylim(ax); yh = diff(yl);
    if row == 1
        y1 = yl(2) - spec.top_pad_rel1 * yh;
        y0 = y1     - spec.height_rel1  * yh;
    else
        y1 = yl(2) - spec.top_pad_rel2 * yh;
        y0 = y1     - spec.height_rel2  * yh;
    end
    yb = [y0 y0 y1 y1];
end

