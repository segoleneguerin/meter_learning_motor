

function meterlearning_motor_paper_figures_clap_spectra(analysis_type)

%% --- PREAMBLE

% Get parameters file
params = meterlearning_motor_get_params();

% figure parameters
fig_size            = [1 1 3 2]; % [1 1 4 2.5] for non compressed
fontname            = 'Arial';
labels_fontsize     = 7;
labels_fontweight   = 'normal';
training_labels_fontweight = 'bold';
labels_linewidth    = 0.6;
grid_linewidth      = 0.5;
plot_linewidth      = 0.3;
% colors              = {'','#008A69','#DB5829','#1964B0'};
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
    

%% ---- LOAD BEHAVIOURAL DATA
path_fft    = fullfile(params.path_output, 'data/4_final/clap');    
filename    = 'clap_fft.mat';
load(fullfile(path_fft,filename))

for i_grp = 1:2
    
    max_all = []; 
    
    for i_cond = [2 3]
        for i_ses = [1 3]

            % preallocation
            part_i  = 1;
            data    = [];
            freq    = [];

            % extract data from each participant
            for participant = params.(['grp',num2str(i_grp),'_cond',num2str(i_cond)])

                data(part_i,:) = clap_fft.avg_time_domain.(sprintf('grp%03d',i_grp)).(sprintf('cond%03d',i_cond)).(sprintf('sub%03d',participant)).(sprintf('ses%03d',i_ses)).mX_mean_clean';
                freq(part_i,:) = clap_fft.avg_time_domain.(sprintf('grp%03d',i_grp)).(sprintf('cond%03d',i_cond)).(sprintf('sub%03d',participant)).(sprintf('ses%03d',i_ses)).freq;

                part_i = part_i +1;
            end
            
            % multiply spectra by 1000 to remove the negative exponent
            % which cannot be read by Adobe Illustrator properly. This
            % exponen is then added in Illustrator manually. 
            data = data * 1000;
             
            % grand average across participants
            grd_avg_fft(i_cond, i_ses,:) = mean(data,1); 
            
            % update global maximum
            max_all = max([max_all, max(grd_avg_fft(:))]);            

            % check the frequency vector across participant
            if ~all(all(freq == freq(1,:), 2))
                warning('All frequency vectors aren''t the same')
            end        
        end
    end

    % merge the two conditions in session 1
    grd_avg_fft(1,1,:) = mean(grd_avg_fft(:,1,:),1);

    freq = freq(1,:);

    %% ---- FIGURE
    

    for i_cond = [1:3]
        for i_ses = [1 3]

            figure('Units','centimeters','Position',fig_size)  
            
            % stems            
            stem(freq, squeeze(grd_avg_fft(i_cond, i_ses, :)), ...
                 'marker','none','Color',colors{1},'LineWidth',grid_linewidth); hold on          

            if i_cond == 1
                three_beat_idx      = dsearchn(freq', metRel_freq{2}');
                four_beat_idx       = dsearchn(freq', metRel_freq{3}');
                meter_unrelated_idx = dsearchn(freq', intersect(metUnrel_freq{2},metUnrel_freq{3})');  

                stem(freq(three_beat_idx), squeeze(grd_avg_fft(i_cond, i_ses, three_beat_idx)), ...
                     'marker','none','Color',colors{2},'LineWidth',grid_linewidth)
                stem(freq(four_beat_idx), squeeze(grd_avg_fft(i_cond, i_ses, four_beat_idx)), ...
                     'marker','none','Color',colors{3},'LineWidth',grid_linewidth)
                stem(freq(meter_unrelated_idx), squeeze(grd_avg_fft(i_cond, i_ses, meter_unrelated_idx)), ...
                     'marker','none','Color',colors{4},'LineWidth',grid_linewidth)
                 
            else
                metRel_idx      = dsearchn(freq', metRel_freq{i_cond}'); 
                metUnrel_idx    = dsearchn(freq', metUnrel_freq{i_cond}');
            end            

            if i_cond == 2 || i_cond == 3
                stem(freq(metRel_idx), squeeze(grd_avg_fft(i_cond, i_ses, metRel_idx)), ...
                     'marker','none','Color',colors{i_cond},'LineWidth',grid_linewidth)
                stem(freq(metUnrel_idx), squeeze(grd_avg_fft(i_cond, i_ses, metUnrel_idx)), ...
                     'marker','none','Color',colors{4},'LineWidth',grid_linewidth) 
            end  
            
            
            set(gca,'FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname, ...
                    'TickDir','out','LineWidth',labels_linewidth,'box','off', ...
                    'XLim',[0 6],'xTick',0:1:6, ...
                    'YLim',[0 1.5], 'yTick',0:0.5:1) % 'YLim',[0 15e-4], 'yTick',0:5e-4:10e-4) 
            
            
            ylabel('Amplitude (a.u.)','FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname)
            xlabel('Frequency (Hz)','FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname)
            
            line([0 6],[0 0], 'LineWidth',labels_linewidth, 'Color', 'k')
            
            ax = gca;
            ax.TickLength = [0.0100 0.0750]; %[0.0100 0.0250]
            
            %% ---- TRAINING BANNERS
            
            % load banner specificities
            load(fullfile(params.experiment_path,'1_code/matlab_plotting_functions','banner_spec.mat'));  
            
            % session
            if i_ses == 1
                banner_text = 'Pre-movement';
            elseif i_ses == 3
                banner_text = 'Post-movement';
            end
            
            xb = [0.1 5.9 5.9 0.1];
            yb = [1.26 1.26 1.5 1.5];     
            patch(xb, yb, colors{1}, 'EdgeColor','none', ... 
                'Clipping','on', 'HandleVisibility','off');            
            text(mean(xb), mean(yb), banner_text, ...
                'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
                'FontSize', labels_fontsize-1, 'FontName', fontname, ...
                'FontWeight',training_labels_fontweight, 'Color','k', ...
                'Clipping','on', 'HandleVisibility','off');         

                           
            % 3- and 4-beat metre
            if i_cond == 2 || i_cond == 3
                xb = [0.1 5.9 5.9 0.1];
                yb = [1 1 1.25 1.25]; 
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

            fig_name = sprintf('Fig1b - grp%i - cond%i- ses%i.svg', i_grp, i_cond, i_ses);
            print(gcf,'-dsvg','-painters',fullfile(export_path,fig_name))
            
            
            close all
            
        end
    end
end
end

