init <- function() {
  
  type <- 'plot'
  box_title <- 'Channel wise MS1 Counts for Precursors'
  help_text <- 'Plotting the MS1 counts based on the signal to noise ratio for all precursors which were associated with one of the defined channels.'
  source_file <- 'sn'
  
  .validate <- function(data, input) {
    validate(need(data()[['sn']], paste0('Upload report.txt')))
    validate(need((nrow(data()[['sn']]) > 1), paste0('No Rows selected')))
    
    validate(need(data()[['report']], paste0('Upload report.txt')))
    validate(need((nrow(data()[['report']]) > 1), paste0('No Rows selected')))
    validate(need(config[['ChemicalLabels']], paste0('Please provide a list of labels under the key: ChemicalLabels in the settings.yaml file')))
    
  }
  
  .plotdata <- function(data, input) {
    plotdata <- data()[['sn']][,c('Raw.file','Precursor.Id', 'Copy.Number')]
    plotdata <- translate_diann_channel_format(plotdata, columns = c("Precursor.Id"))
    view(plotdata)
    plotdata <- separate_channel_info(plotdata)
    view(plotdata)
 
    

    plotdata$Intensity <- log10(plotdata$Copy.Number)
    
    # Thresholding data at 1 and 99th percentiles
    ceiling <- quantile(plotdata$Intensity, probs=.99, na.rm = TRUE)
    floor <- quantile(plotdata$Intensity, probs=.01, na.rm = TRUE)
    
    plotdata <- dplyr::filter(plotdata, is.finite(Intensity))
    if(nrow(plotdata) > 0){
      plotdata[plotdata$Intensity >= ceiling, 2] <- ceiling
      plotdata[plotdata$Intensity <= floor, 2] <- floor
    }
    return(plotdata)
  }
  
  .plot <- function(data, input) {
    .validate(data, input)
    plotdata <- .plotdata(data, input)
    validate(need((nrow(plotdata) > 1), paste0('No Rows selected')))
    
    ggplot(plotdata, aes(x=Intensity, color = Label)) + 
      facet_wrap(~Raw.file, nrow = 1, scales = "free_x") + 
      
      stat_bin(aes(y=..count..), size = 0.8, bins=100,position = "identity",geom="step")+

      
      coord_flip() + 
      labs(x=expression(bold('Log'[10]*' Counts')), y='Number of Precursors') +
      scale_fill_manual(name = "", values = custom_colors)+
      scale_color_manual(name = "", values = custom_colors)+
   
      theme(legend.position = "bottom")+
      theme_base(input=input, show_legend=T)+
      custom_theme 

    
  }
  
  return(list(
    type=type,
    box_title=box_title,
    help_text=help_text,
    source_file=source_file,
    validate_func=.validate,
    plotdata_func=.plotdata,
    plot_func=.plot,
    box_width=12, # bootstrap column units
    dynamic_width=150,
    dynamic_width_base=150
  ))
}