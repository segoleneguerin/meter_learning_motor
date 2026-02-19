function meterlearning_motor_paper_figures_time_domain

%% ---- PREAMBLE
% Get parameters file
params = meterlearning_motor_get_params();

% figure parameters
fig_size            = [1 1 3 2.5]; 
fontname            = 'Arial';
labels_fontsize     = 7;
labels_fontweight   = 'normal';
training_labels_fontweight ...
                    = 'bold';
labels_linewidth    = 0.6;
grid_linewidth      = 0.5;
plot_linewidth      = 0.3;
colors = {repmat(0.7,1,3),[201 92 46]./256,[49 112 183]./256,'k'};


%% ---- LOAD DATA

% Neural data
path        = fullfile(params.path_output, 'data/4_final/eeg/grp_comparison_time_domain/');
filename    = 'grp_comparison_time_domain.mat';
load(fullfile(path,filename))

fs      = params.fs; 
time    = [0: 1/fs : params.pattern_dur];

%% ---- LOAD STIM

path     = fullfile(params.experiment_path,'2_output/data/4_final/stimuli');
filename = 'stimuli_bembe.mat';
load(fullfile(path, filename)); 
stim_env = stim.track.env;
stim_s   = stim.track.s;
stim_fs  = stim.fs;
stim_N   = length(stim_env);
stim_time= 0 : 1/stim_fs : (stim_N-1)/stim_fs;  

% downsample stimulus to fs = 441Hz (otherwise it gets to heavy to
% manipulate in Inkscape)
f_down          = 100; % downsampling factor
stim_env_down   = downsample(stim_env,f_down);
stim_s_down     = downsample(stim_s,f_down);
stim_time_down  = downsample(stim_time,f_down);

pat_dur_idx     = dsearchn(stim_time_down',2.4); 


%% EXTRACT DATA

min_all = [];
max_all = []; 


for i_grp = 1:2
    for i_ses = [1 3]
        for i_cond = [2 3]
            
            grp     = sprintf('grp%03d',i_grp);
            cond    = sprintf('cond%03d',i_cond);
            ses     = sprintf('ses%03d',i_ses);
            participants ...
                    = params.(sprintf('grp%i_cond%i', i_grp, i_cond));      
                
            % preallocate
            s = NaN(length(participants),length(time));
            iPart = 1;            
            
            for participant = participants

                part = sprintf('sub%03d',participant);

                s(iPart,:) = S.(grp).(cond).(part).(ses);
                iPart = iPart + 1;
            end

            s_mean(i_grp,i_ses,i_cond,:) = nanmean(s,1);   
            
            % update global minimum and maximum
            min_all = min([min_all, min(s_mean(:))]);
            max_all = max([max_all, max(s_mean(:))]);   
        end
    end
end

range_all = range([min_all,max_all]);



%% ---- PLOT ALL SESSIONS AND CONDITIONS SEPARATELY
for i_grp = 1:2
    for i_ses = [1 3]
        for i_cond = [2 3]
            
            figure('Units','centimeters','Position',fig_size)

            % ---- Stim
            stem(stim_time_down(1:pat_dur_idx), stim_env_down(1:pat_dur_idx),'marker','none','Color',colors{1})
            hold on
            plot(stim_time_down(1:pat_dur_idx), stim_env_down(1:pat_dur_idx),'Color',colors{1}, 'linewidth',plot_linewidth) 
            
            % ---- Eeg
            plot(time,squeeze(s_mean(i_grp,i_ses,i_cond,:)), ...
                    'Color',colors{i_cond}, 'LineWidth',grid_linewidth)
            
            % ---- layout
            set(gca,'FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname, ...
                    'TickDir','out','LineWidth',labels_linewidth,'box','off', ...
                    'XLim',[0 2.4] ,'xTick',0:1.2:2.4, ...
                    'YLim',[min_all max_all])%, 'yTick',0:5e-4:10e-4) % 
            
            ylabel('Amplitude (µV)','FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname)
            xlabel('Time (s)','FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname)
            x_limit = get(gca,'XLim');
            y_limit = get(gca,'YLim');
            line(x_limit,[0 0],'Color','k','LineWidth',labels_linewidth)
            line([0 0],y_limit,'Color','k','LineWidth',labels_linewidth)
            
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
            disp(yb)
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
                disp(yb)
                patch(xb, yb, colors{i_cond}, 'EdgeColor','none', ... % [0.8588 0.3451 0.1608]
                    'Clipping','on', 'HandleVisibility','off');

                text(mean(xb), mean(yb), sprintf('%i-beat metre condition',i_cond+1), ...
                    'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
                    'FontSize', labels_fontsize-2, 'FontName', fontname, ...
                    'FontWeight',labels_fontweight, 'Color','k', ...
                    'Clipping','on', 'HandleVisibility','off');
            end                 
            
            % ---- PRINT
            export_path = fullfile(params.path_plot,'paper');    
            if ~isdir(export_path)
                mkdir(export_path);
            end

            fig_name = sprintf('Fig2a - grp%i - cond%i- ses%i.svg', i_grp, i_cond, i_ses);
            print(gcf,'-dsvg','-painters',fullfile(export_path,fig_name))
            
            close all            
            
        end
    end
end

close all

%% ---- PLOT THE FIRST SESSION WITH THE CONDITIONS MERGED
for i_grp = 1:2
    for i_ses = 1
             
        figure('Units','centimeters','Position',fig_size)

        % ---- Stim
        stem(stim_time_down(1:pat_dur_idx), stim_env_down(1:pat_dur_idx),'marker','none','Color',colors{1})
        hold on
        plot(stim_time_down(1:pat_dur_idx), stim_env_down(1:pat_dur_idx),'Color',colors{1}, 'linewidth',plot_linewidth) 

        % ---- Eeg 
        s_mean_cond = mean(s_mean(i_grp, i_ses, 2:3, :),3);
        
        plot(time,squeeze(s_mean_cond), ...
                'Color','k', 'LineWidth',grid_linewidth)        
            
        % ---- layout
        set(gca,'FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname, ...
                'TickDir','out','LineWidth',labels_linewidth,'box','off', ...
                'XLim',[0 2.4] ,'xTick',0:1.2:2.4, ...
                'YLim',[min_all max_all])%, 'yTick',0:5e-4:10e-4) % 

        ylabel('Amplitude (µV)','FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname)
        xlabel('Time (s)','FontSize',labels_fontsize,'FontWeight',labels_fontweight, 'FontName', fontname)
        x_limit = get(gca,'XLim');
        y_limit = get(gca,'YLim');        
        line(x_limit,[0 0],'Color','k','LineWidth',labels_linewidth)
        line([0 0],y_limit,'Color','k','LineWidth',labels_linewidth)

        % ---- BANNERS 
        % load banner specificities            
        ensureBannerSpace(gca, spec, 2, max_all,  0.02)
        ax = gca;  xl = xlim(ax); xw = diff(xl);

        % Pre movement
        banner_text = 'Pre movement';
        yb          = bannerY(spec, gca, 1);
        x_left      = xl(1) + spec.left_rel  * xw;
        x_right     = xl(1) + spec.right_rel * xw;
        xb          = [x_left x_right x_right x_left];   
        patch(xb, yb, colors{1}, 'EdgeColor','none', ... 
            'Clipping','on', 'HandleVisibility','off');            
        text(mean(xb), mean(yb), banner_text, ...
            'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
            'FontSize', labels_fontsize-1, 'FontName', fontname, ...
            'FontWeight',training_labels_fontweight, 'Color','k', ...
            'Clipping','on', 'HandleVisibility','off');  
            
        % ---- PRINT
        export_path = fullfile(params.path_plot,'paper');    
        if ~isdir(export_path)
            mkdir(export_path);
        end

        fig_name = sprintf('Fig2a - grp%i - cond%i- ses%i.svg', i_grp, 1, i_ses);
        print(gcf,'-dsvg','-painters',fullfile(export_path,fig_name))

        close all          
        
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
