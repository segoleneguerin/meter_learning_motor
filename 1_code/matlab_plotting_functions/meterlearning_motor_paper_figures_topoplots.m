

function meterlearning_motor_paper_figures_topoplots(analysis_type)

%% --- PREAMBLE

% Get parameters file
params       = meterlearning_motor_get_params();
eeg_fft      = struct();
process_data = true;

% EEG parameters
ref_method   = 'mastoids';

% figure parameters
fig_size            = [1 1 25 20]; 
fontname            = 'Arial';
labels_fontsize     = 7;
labels_fontweight   = 'normal';
labels_linewidth    = 0.6;
grid_linewidth      = 0.5;
plot_linewidth      = 0.3;
colors = {repmat(0.7,1,3),[201 92 46]./256,[49 112 183]./256,'k'};

if analysis_type == 1
    toposcaling = {[-0.0070,    0.1266],...
                   [0           0.1758]}; 
elseif analysis_type == 5
    toposcaling = {[0,          0.15],...
                   [0           0.1941]};    
end
export_path = fullfile(params.path_plot,'paper',['analysis_type',num2str(analysis_type)]);  
if ~isdir(export_path)
    mkdir(export_path);
end

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



%% ---- TOPOPLOTS ACROSS CONDITIONS

for i_grp = 1:2
    
    max_all = [];
    min_all = []; 
    
    for i_ses = [1 3] 
        for i_cond = [2:3]

            participants = params.(sprintf('grp%i_cond%i',i_grp,i_cond));
            i = 1;

            for i_sub = participants

                %% ---- LOAD DATA
                % get path and file name
                import_path = fullfile(params.path_output, 'data/3_preprocessed/', ...
                                        sprintf('grp-%03d', i_grp), ...
                                        sprintf('cond-%03d', i_cond), ...
                                        sprintf('sub-%03d', i_sub), 'eeg');

                filename  = sprintf('grp-%03d_cond-%03d_sub-%03d_ses-%03d_ref-%s_cleaned-fft-values-per-channel.csv', ...
                                    i_grp, i_cond, i_sub, i_ses, ref_method);
                file_freq = sprintf('grp-%03d_cond-%03d_sub-%03d_freq-values.csv', ...
                                    i_grp, i_cond, i_sub);

                % load data   
                try
                    freq    = readmatrix(fullfile(import_path,file_freq));  
                    mX_all_channel_clean ...
                            = table2array(readtable(fullfile(import_path,filename)));  
                catch
                    error('Please run all eeg scripts before plotting the topographies')
                end

                % get mean of (un)related frequencies across electrodes   
                related(i,:)    = get_mean_freq(mX_all_channel_clean, freq, ...
                                                    metRel_freq{i_cond});
                unrelated(i,:)  = get_mean_freq(mX_all_channel_clean, freq, ...
                                                    metUnrel_freq{i_cond});    
                i = i+1;
            end                

            % get header for chanlocs
            file_name_header = ...
                sprintf(['grp-%03d_cond-%03d_sub-%03d_task-meterlearning-motor_session-%01d_' ...
                'filtered_epoched_interp_cleaned-trials-ics_ref-%s.lw6'], ...
                i_grp, i_cond, i_sub, i_ses, ref_method);

            [header, ~] = CLW_load(fullfile(import_path, file_name_header));               

            % get the mean across participants
            mean_related    = mean(related,1);
            mean_unrelated  = mean(unrelated,1);
            
            min_all = min([min_all,min(mean_related),min(mean_unrelated)]);
            max_all = max([max_all,max(mean_related),max(mean_unrelated)]);            

            %% ---- TOPOPLOTS METRE RELATED
            figure('Units','centimeters','Position',fig_size) 
            topoplot(mean_related, header.chanlocs, 'style', 'map', ...
                'gridscale', 256, ...
                'electrodes', 'on', ...
                'emarkersize', 6, ...
                'maplimits', toposcaling{i_grp}, ...
                'whitebk', 'off');                
            colorbar % add the color bar
            colormap jet % change palette 

            fig_name = sprintf('Fig2b - grp%i - cond%i- ses%i - topo metRel.svg', i_grp, i_cond, i_ses);
            print(gcf,'-dsvg','-painters',fullfile(export_path,fig_name))

            close all                   

            %% ---- TOPOPLOTS METRE UNRELATED
            figure('Units','centimeters','Position',fig_size) 
            topoplot(mean_unrelated, header.chanlocs, 'style', 'map', ...
                'gridscale', 256, ...
                'electrodes', 'on', ...
                'emarkersize', 6, ...
                'maplimits', toposcaling{i_grp}, ...
                'whitebk', 'off'); 
            colorbar % add the color bar
            colormap jet % change palette 

            fig_name = sprintf('Fig2b - grp%i - cond%i- ses%i - topo metUnrel.svg', i_grp, i_cond, i_ses);
            print(gcf,'-dsvg','-painters',fullfile(export_path,fig_name))

            close all              
        end
    end 
    sprintf('grp%i',i_grp)
    disp(min_all)
    disp(max_all)
end

%% ---- TOPOPLOTS MERGED CONDITIONS

i_ses = 1;
for i_grp = 1:2
    i = 1;   
    for i_cond = [2:3]
        
        participants = params.(sprintf('grp%i_cond%i',i_grp,i_cond));
        
        for i_sub = participants

            %% ---- LOAD DATA
            % get path and file name
            import_path = fullfile(params.path_output, 'data/3_preprocessed/', ...
                                    sprintf('grp-%03d', i_grp), ...
                                    sprintf('cond-%03d', i_cond), ...
                                    sprintf('sub-%03d', i_sub), 'eeg');

            filename  = sprintf('grp-%03d_cond-%03d_sub-%03d_ses-%03d_ref-%s_cleaned-fft-values-per-channel.csv', ...
                                i_grp, i_cond, i_sub, i_ses, ref_method);
            file_freq = sprintf('grp-%03d_cond-%03d_sub-%03d_freq-values.csv', ...
                                i_grp, i_cond, i_sub);

            % load data                
            freq    = readmatrix(fullfile(import_path,file_freq));  
            mX_all_channel_clean ...
                    = table2array(readtable(fullfile(import_path,filename)));                     

            % get mean of (un)related frequencies across electrodes   
            related(i,:)    = get_mean_freq(mX_all_channel_clean, freq, ...
                                                metRel_freq{i_cond});
            unrelated(i,:)  = get_mean_freq(mX_all_channel_clean, freq, ...
                                                metUnrel_freq{i_cond});    
            i = i+1;
        end         
    end
    
    % get the mean across participants
    mean_related    = mean(related,1);
    mean_unrelated  = mean(unrelated,1); 
    
    %% ---- TOPOPLOTS METRE RELATED
    figure('Units','centimeters','Position',fig_size) 
    topoplot(mean_related, header.chanlocs, 'style', 'map', ...
        'gridscale', 256, ...
        'electrodes', 'on', ...
        'emarkersize', 6, ...
        'maplimits', toposcaling{i_grp}, ...
        'whitebk', 'off'); 
    colorbar % add the color bar
    colormap jet % change palette 

    fig_name = sprintf('Fig2b - grp%i - cond%i- ses%i - topo metRel.svg', i_grp, 1, i_ses);
    print(gcf,'-dsvg','-painters',fullfile(export_path,fig_name))

    close all                   

    %% ---- TOPOPLOTS METRE UNRELATED
    figure('Units','centimeters','Position',fig_size) 
    topoplot(mean_unrelated, header.chanlocs, 'style', 'map', ...
        'gridscale', 256, ...
        'electrodes', 'on', ...
        'emarkersize', 6, ...
        'maplimits', toposcaling{i_grp}, ...
        'whitebk', 'off'); 
    colorbar % add the color bar
    colormap jet % change palette 

    fig_name = sprintf('Fig2b - grp%i - cond%i- ses%i - topo metUnrel.svg', i_grp, 1, i_ses);
    print(gcf,'-dsvg','-painters',fullfile(export_path,fig_name))

    close all             
end



end

