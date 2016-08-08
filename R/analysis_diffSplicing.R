## TODO(NunoA): plot using boxplots

#' Interface for the analysis of an alternative splicing event
#' @param id Character: identifier
#' @importFrom highcharter highchartOutput
#' @importFrom shiny tagList uiOutput NS sidebarLayout numericInput h3 mainPanel
#' @return Character with the HTML interface
diffSplicingUI <- function(id) {
    ns <- NS(id)
    
    tagList(
        uiOutput(ns("modal")),
        sidebarLayout(
            sidebarPanel(
                numericInput(ns("bandwidth"), "Density bandwidth", 0.01, 
                             step=0.01),
                h3("Non-parametric tests"),
                uiOutput(ns("basicStats")), hr(),
                # uiOutput(ns("spearman")), hr(),
                # uiOutput(ns("fisher")), hr(),
                uiOutput(ns("wilcox")), hr(),
                uiOutput(ns("kruskal")), hr(),
                uiOutput(ns("levene")), hr(),
                uiOutput(ns("survival"))
            ), mainPanel(
                highchartOutput(ns("density"))
            )
        )
    )
}

#' Plot distribution through a density plot
#' 
#' The tooltip shows the median, variance, max, min and number of non-NA samples
#' of each data series.
#' 
#' @inheritParams wilcox
#' @param bandwidth Numeric: density bandwidth
#' @param rug Boolean: include rug plot to better visualise data distribution 
#' (TRUE by default)
#' @param vLine Boolean: include vertical plot lines to indicate the mean and
#' median of each group even when those groups are omitted
#' 
#' @importFrom highcharter highchart hc_chart hc_xAxis hc_plotOptions hc_tooltip
#' JS hc_add_series_scatter hc_add_series_density
#' @importFrom stats median var density
#' 
#' @return Highcharter object with density plot
#' @export
plotDistribution <- function(psi, groups, bandwidth=0.01, rug=TRUE, 
                             vLine=TRUE) {
    # Include X-axis zoom and hide markers
    hc <- highchart() %>%
        hc_chart(zoomType = "x") %>%
        hc_xAxis(min = 0, max = 1, title = list(
            text = "Density of exon inclusion levels")) %>%
        hc_plotOptions(series = list(fillOpacity=0.3,
                                     marker = list(enabled = FALSE))) %>%
        hc_tooltip(
            headerFormat = paste(
                span(style="color:{point.color}", "\u25CF "),
                tags$b("{series.name}"), br()),
            pointFormat = paste(
                "Inclusion level: {point.x}", br(),
                "Number of samples: {series.options.samples}", br(),
                "Median: {series.options.median}", br(),
                "Variance: {series.options.var}", br(),
                "Range: {series.options.min} - {series.options.max}"))
    
    count <- 0
    plotLines <- list()
    for (group in unique(groups)) {
        row  <- psi[groups == group]
        med  <- roundDigits(median(row, na.rm = TRUE))
        vari <- roundDigits(var(row, na.rm = TRUE))
        max  <- roundDigits(max(row, na.rm = TRUE))
        min  <- roundDigits(min(row, na.rm = TRUE))
        samples <- sum(!is.na(row))
        
        color <- JS("Highcharts.getOptions().colors[", count, "]")
        
        # Calculate the density of inclusion levels for each sample group
        den <- density(row, bw = bandwidth, na.rm = TRUE)
        hc <- hc %>%
            hc_add_series_density(den, name=group, area=TRUE, median=med, 
                                  var=vari, samples=samples, max=max, 
                                  color=color, min=min)
        # Rug plot
        if (rug) {
            hc <- hc_add_series_scatter(
                hc, row, rep(0, length(row)), name=group, marker=list(
                    enabled=TRUE, symbol="circle", radius=4, fillColor=color),
                median=med, var=vari, samples=samples, max=max, min=min)
        }
        # Save plot line with information
        if (vLine) {
            plotLines[[count + 1]] <- list(
                label = list(text = paste("Median:", med, "/ Variance:", vari)),
                # Colour the same as the series
                color=color,
                dashStyle="shortdash",
                width=2,
                value=med,
                zIndex = 7)
        }
        count <- count + 1
    }
    
    # Add plotLines with information
    if (vLine) hc <- hc %>% hc_xAxis(plotLines = plotLines)
    return(hc)
}

#' Basic statistics performed on data
#' 
#' Variance and median of each group. If data has 2 groups, also calculates the
#' delta variance and delta median.
#' 
#' @inheritParams wilcox
#' @importFrom shiny tagList br h4
#' 
#' @return HTML elements
basicStats <- function(psi, groups) {
    data <- lapply(unique(groups), function(g) psi[groups == g])
    
    len <- length(unique(groups))
    vari <- vapply(data, var, numeric(1), na.rm = TRUE)
    medi <- vapply(data, median, numeric(1), na.rm = TRUE)
    
    if (len == 2) {
        deltaMedian <- tagList(
            tags$b("|\u0394 Median|: "), abs(medi[2] - medi[1]), br())
    } else {
        deltaMedian <- NULL
    }
    
    ui <- tagList(h4("Basic statistics"), deltaMedian,
                  tags$b("Average variance: "),
                  sum(vari)/length(vari))
    return(ui)
}

#' Perform Wilcox analysis and return interface to show the results
#' @param psi Numeric: quantification of one alternative splicing event
#' @param groups Character: group of each PSI index
#' 
#' @importFrom shiny tagList tags h4 br
#' @importFrom stats wilcox.test
#' @return HTML elements
wilcox <- function(psi, groups) {
    group <- unique(groups)
    len <- length(group)
    
    if (len > 2) {
        return(tagList(h4("Wilcoxon test"),
                       "Can only perform this test on 2 or 1 group."))
    } else if (len == 2) {
        psiA <- psi[groups == group[1]]
        psiB <- psi[groups == group[2]]
        stat <- tryCatch(list(stat=wilcox.test(psiA, psiB)), 
                         warning=function(w)
                             return(list(stat=wilcox.test(psiA, psiB),
                                         warning=w)))
    } else if (len == 1) {
        stat <- tryCatch(list(stat=wilcox.test(psi)), warning=function(w)
            return(list(stat=wilcox.test(psi), warning=w)))
    }
    
    if ("warning" %in% names(stat))
        warn <- tagList(
            tags$code(paste("Warning:", stat$warning$message)), br())
    else
        warn <- NULL
    
    tagList(
        h4(stat$stat$method), warn,
        tags$b("Test value: "), stat$stat$statistic, br(),
        tags$b("p-value: "), stat$stat$p.value, br(),
        tags$b("Test parameters: "), stat$stat$parameter, br(),
        tags$b("Location parameter: "), stat$stat$null.value, br(),
        tags$b("Alternative hypothesis: "), stat$stat$alternative
    )
}

#' Perform Levene's test and return interface to show the results
#' @inheritParams wilcox
#' @importFrom shiny tagList tags h4 br
#' @return HTML elements
levene <- function(psi, groups) {
    len <- length(unique(groups))
    if (len >= 2) {
        nas <- is.na(psi)
        stat <- levene.test(psi[!nas], factor(groups[!nas]))
        tagList(
            h4("Levene's Test for Homogeneity of Variance"),
            tags$b("Test value: "), stat$statistic, br(),
            tags$b("p-value: "), stat$p.value, br(),
            tags$b("p-value without bootstrap: "), 
            stat$non.bootstrap.p.value
        )
    } else {
        tagList(
            h4("Levene's Test for Homogeneity of Variance"),
            "Can only perform this test on 2 or more groups."
        )
    }
}

#' Perform Kruskal's test and return interface to show the results
#' @inheritParams wilcox
#' @importFrom shiny tagList tags h4 br
#' @importFrom stats kruskal.test
#' @return HTML elements
kruskal <- function(psi, groups) {
    len <- length(unique(groups))
    if (len >= 2) {
        stat <- kruskal.test(psi, factor(groups))
        tagList(
            h4(stat$method),
            tags$b("Test value (Chi squared): "), stat$statistic, br(),
            tags$b("p-value: "), stat$p.value, br(),
            tags$b("Degrees of freedom: "), stat$parameter
        )
    } else {
        tagList(
            h4("Kruskal test"),
            "Can only perform this test on 2 or more groups."
        )
    }
}

#' Perform Fisher's exact test and return interface to show the results
#' @inheritParams wilcox
#' @importFrom shiny tagList tags h4 br
#' @importFrom stats fisher.test
#' @return HTML elements
fisher <- function(psi, groups) {
    stat <- try(R.utils::evalWithTimeout(
        fisher.test(psi, factor(groups)),
        timeout = 1,
        onTimeout = "error"))
    
    if (class(stat) != "try-error") {
        tagList(
            h4(stat$method),
            tags$b("p-value: "), stat$p.value, br(),
            tags$b("Alternative hypothesis: "), stat$alternative
        )
    } else {
        tagList(
            h4("Fisher's Exact Test for Count Data"),
            "This test took too much to complete!"
        )
    }
}

#' Perform Spearman's test and return interface to show the results
#' @inheritParams wilcox
#' @importFrom shiny tagList tags h4 br
#' @importFrom stats var cor
#' @return HTML elements
spearman <- function(psi, groups) {
    group <- unique(groups)
    len <- length(group)
    
    if (len != 2) {
        tagList(
            h4("Spearman's correlation"),
            "Can only perform this test on 2 groups.")
    } else {
        var <- var(psi[groups == group[1]], psi[groups == group[2]])
        cor <- cor(psi[groups == group[1]], psi[groups == group[2]])
        
        tagList(
            h4("Spearman's correlation"),
            tags$b("Variance: "), var, br(),
            tags$b("Correlation: "), cor)
    }
}

#' Filter groups with less data points than the threshold
#' 
#' Groups containing a number of non-missing values less than the threshold are
#' discarded.
#' 
#' @param vector Unnamed elements
#' @param group Character: group of the elements
#' @param threshold Integer: number of valid non-missing values by group
#' 
#' @return Named vector with filtered elementes from valid groups. The group of 
#' the respective element is given in the name.
#' @export
filterGroups <- function(vector, group, threshold=1) {
    names(vector) <- group
    vector <- lapply(unique(group), function(t) {
        vector <- vector[group == t]
        if ( sum(!is.na(vector)) >= threshold )
            return(vector)
    })
    return(unlist(vector))
}

#' Server logic for the analyses of a single alternative splicing event
#' @param input Shiny input
#' @param output Shiny ouput
#' @param session Shiny session
#' 
#' @importFrom highcharter renderHighchart
#' @importFrom shinyjs runjs
diffSplicingServer <- function(input, output, session) {
    observe({
        # Get selected event
        event <- getEvent()
        if (is.null(event) || event == "") return(NULL)
        
        # Check if bandwidth is valid
        bandwidth <- input$bandwidth
        if (bandwidth <= 0 || is.na(bandwidth)) {
            errorModal(session, "Bandwidth must have a positive value",
                       "Insert a number higher than 0.")
            return(NULL)
        }
        
        # Get splicing event's inclusion levels for all samples
        psi <- getInclusionLevels()
        eventPSI <- as.numeric(psi[event, ])
        
        # Separate samples by their groups
        groups <- parseSampleGroups(colnames(psi))
        eventPSI <- filterGroups(eventPSI, groups)
        groups <- names(eventPSI)
        
        plot <- plotDistribution(eventPSI, groups, bandwidth)
        output$density <- renderHighchart(plot)
        
        output$basicStats <- renderUI(basicStats(eventPSI, groups))
        output$wilcox     <- renderUI(wilcox(eventPSI, groups))
        output$kruskal    <- renderUI(kruskal(eventPSI, groups))
        output$levene     <- renderUI(levene(eventPSI, groups))
        # output$fisher   <- renderUI(fisher(eventPSI, groups))
        # output$spearman <- renderUI(spearman(eventPSI, groups))
        
        output$survival <- renderUI({
            tagList(h3("Survival analysis by quantification cut-off"),
                    actionButton(session$ns("optimalSurv"), "Take me there"))
        })
    })
    
    # Take user to the survival curves separation by a quantification cut-off
    observeEvent(input$optimalSurv, runjs("showSurvCutoff()"))
}

attr(diffSplicingUI, "loader") <- "analysis"
attr(diffSplicingUI, "name") <- "Differential splicing analysis (per splicing event)"
attr(diffSplicingUI, "selectEvent") <- TRUE
attr(diffSplicingServer, "loader") <- "analysis"