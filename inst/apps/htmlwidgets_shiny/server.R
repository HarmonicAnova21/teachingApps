server = function(input, output, session) {
  
  predicted <- reactive({
    hw <- HoltWinters(datasets::ldeaths)
    predict(hw, n.ahead = input$months, 
            prediction.interval = TRUE,
            level = as.numeric(input$interval))
  })
  
  output$dygraph <- renderDygraph({
    dygraph(predicted(), main = "Predicted Deaths from Lung Disease (UK)/Month") %>%
      dySeries(c("lwr", "fit", "upr"), label = "Deaths")
  })
  
  output$from <- renderText({
    if (!is.null(input$dygraph_date_window))
      strftime(input$dygraph_date_window[[1]], "%d %b %Y")      
  })
  
  output$to <- renderText({
    if (!is.null(input$dygraph_date_window))
      strftime(input$dygraph_date_window[[2]], "%d %b %Y")
})
  
  output$leaflet <- renderLeaflet({
    
      leaflet() %>%
      addTiles() %>%   
      addMarkers(c(lng=-84.309820,-84.311226), lat=c(39.350752,39.351341), 
                 popup=c("We Are Here", "Ok, We're Really Here"))
})
  output$threejs <- renderGlobe({
    
     globejs(img = system.file('images/world.jpg', package = 'threejs'), atmosphere = TRUE, long=c(-84.084253,-84.083084), lat=c(39.783018,39.782334), value = 50)
})
  
  output$parcoords <- renderParcoords({
    
    diamonds <- diamonds
dmd <- diamonds[sample(1:nrow(diamonds),1000),]
dmd <- dplyr::mutate(.data = dmd, carat = cut(carat, breaks=c(0,1,2,3,4,5), right = T))
dmd <- dplyr::select(.data = dmd, carat, color, cut, clarity, depth, table, price,  x, y, z)
  parcoords(data = dmd,
    rownames = F # turn off rownames from the data.frame
    , brushMode = "1D-axes"
    , reorderable = T
    , queue = T
    , color = list(
      colorBy = "carat"
      ,colorScale = htmlwidgets::JS("d3.scale.category10()")),
    height = '650', width = '1650', margin = list(left=0, right=0))
})
  output$taucharts <- renderTaucharts({
    
    tauchart(datasets::mtcars) %>%
    tau_point("wt", "mpg", color="cyl") %>%
    tau_color_manual(c("blue", "maroon", "black")) %>%
    tau_tooltip() %>%
    tau_trendline()
})
  output$d3heatmap <- renderD3heatmap({
    
    d3heatmap(datasets::mtcars, scale = "column", colors = "Spectral")
})
  output$mtbf <- renderPlotly({

mtbf <- seq(1,500,1)
accept <- ppois(input$fails, input$ttt/mtbf)
datas <- data.frame(mtbf, accept) 

observe({

if(input$thresh>=input$objective) { 

   updateSliderInput(session, "objective", value = input$thresh+5) } 

if(input$objective>=input$contract) { 

   updateSliderInput(session, "contract", value = input$objective+5) }
  
})

p1 <- plot_ly(datas, 
              x = mtbf, 
              y = accept,
              type = 'scatter',
              showlegend = T, 
              name = 'Pr(accept)', 
              text = paste(
'Pr(accept) = ', round(accept, digits = 5),'<br>',
'True MTBF = ', mtbf,'<br>',
'Allowed Failures = ', input$fails,'<br>',
'Total Test Time = ', input$ttt),
              hoverinfo = 'markers+text')
p2 <- add_trace(p1,
                type = 'scatter',
                x = rep(input$thresh,2), 
                y = c(0,ppois(input$fails, input$ttt/input$thresh)),
                showlegend = T,
                name = 'Threshold',
                hoverinfo = 'text',
                marker = list(size = 10, color = 'orange'))
p3 <- add_trace(p2,
                x = rep(input$objective,2), 
                y = c(0,ppois(input$fails, input$ttt/input$objective)),
                showlegend = T,
                name = 'Objective',
                hoverinfo = 'text',
                marker = list(size = 10, color = 'green'))
p4 <- add_trace(p3,
                x = rep(input$contract,2), 
                y = c(0,ppois(input$fails, input$ttt/input$contract)),
                showlegend = T,
                name = 'Contract',
                hoverinfo = 'text',
                marker = list(size = 10, color = 'red'))
p5 <- 
  layout(p4,
         yaxis = list(title = "Probability of Acceptance - Pr(accept)",
                      range = extendrange(c(0,ppois(input$fails,
                                                    input$ttt/input$contract)*1.25)),
                      titlefont = list(size = 16)),
         xaxis = list(title = 'True System Reliability - MTBF',
                      range = extendrange(c(input$thresh,input$contract), f = .5),
                      titlefont = list(size = 16)),
             
             annotations = list(
               list(x = c(input$thresh),
                    y = ppois(input$fails, input$ttt/input$thresh),
                    text = 'Threshold ',
                    showarrow = T,
                    ay = -40,
                    ax = -40,
                    arrowhead = 0,
                    arrowcolor = 'orange'),
               list(x = input$objective,
                    y = ppois(input$fails, input$ttt/input$objective),
                    text = "Objective",
                    showarrow = T,
                    ay = -60,
                    ax = -50,
                    arrowhead = 0,
                    arrowcolor = 'green'),
               list(x = input$contract,
                    y = ppois(input$fails, input$ttt/input$contract),
                    text = "Contract",
                    showarrow = T,
                    ay = -80,
                    ax = -60,
                    arrowhead = 0,
                    arrowcolor = 'red')),
             font = list(size = 16))
})
}