## TODO(NunoA): add histogram in/above percentage of NAs per row to remove
## TODO(NunoA): logarithmic values
## TODO(NunoA): BoxCox transformation

#' Perform principal component analysis after processing missing values
#' 
#' @param ... Arguments passed on to \code{stats::prcomp}
#' @inheritParams stats::prcomp
#' @inheritParams reduceDimensionality
#' 
#' @return PCA result in a \code{prcomp} object
#' @export
#' 
#' @seealso \code{\link{plotPCA}}, \code{\link{performICA}} and 
#' \code{\link{plotICA}}
#' 
#' @examples 
#' performPCA(USArrests)
performPCA <- function(data, center=TRUE, scale.=FALSE, naTolerance=0, ...) {
    reduceDimensionality(data, "pca", naTolerance, center=center, scale.=scale.,
                         ...)
}

#' @rdname appUI
#' 
#' @importFrom highcharter highchartOutput
#' @importFrom shinyBS bsTooltip
#' @importFrom shiny checkboxGroupInput tagList uiOutput hr
#' sliderInput actionButton selectizeInput
#' @importFrom shinyjs hidden
pcaUI <- function(id) {
    ns <- NS(id)
    
    pcaOptions <- div(
        id=ns("pcaOptions"),
        selectizeInput(ns("dataForPCA"), "Data to perform PCA on", width="100%",
                       choices=NULL, options=list(
                           placeholder="No data available")),
        checkboxGroupInput(ns("preprocess"), "Preprocessing",
                           c("Center values"="center", "Scale values"="scale"),
                           selected=c("center"), width="100%"),
        sliderInput(ns("naTolerance"), div(
            "Percentage of missing values to tolerate per event",
            icon("question-circle")),
            min=0, max=100, value=0, post="%", width="100%"),
        bsTooltip(ns("naTolerance"), placement="right", paste(
            "For events with a tolerable percentage of missing",
            "values, the median value of the event across",
            "samples is used to replace those missing values.",
            "The remaining events are discarded."),
            options=list(container="body")),
        selectGroupsUI(ns("dataGroups"), "Perform PCA on...",
                       noGroupsLabel="All samples",
                       groupsLabel="Samples from selected groups"),
        selectGroupsUI(
            ns("dataGroups2"), "Perform PCA on...",
            noGroupsLabel="All genes and splicing events",
            groupsLabel="Genes and splicing events from selected groups"),
        processButton(ns("calculate"), "Calculate PCA")
    )
    
    performPcaCollapse <- bsCollapsePanel(
        list(icon("tasks"), "Perform PCA"), value="Perform PCA", style="info",
        errorDialog(paste("No alternative splicing quantification or gene",
                          "expression data are available."),
                    id=ns("pcaOptionsDialog"), buttonLabel="Load data",
                    buttonIcon="plus-circle", buttonId=ns("loadData")),
        hidden(pcaOptions))
    
    plotPcaCollapse <- bsCollapsePanel(
        list(icon("binoculars"), "Plot PCA"),
        value="Plot PCA", style="info",
        errorDialog("PCA has not yet been performed.", id=ns("noPcaPlotUI")),
        hidden(div(
            id=ns("pcaPlotUI"),
            selectizeInput(ns("pcX"), choices=NULL, width="100%",
                           "Principal component for the X axis"),
            selectizeInput(ns("pcY"), choices=NULL, width="100%",
                           "Principal component for the Y axis"),
            selectGroupsUI(ns("colourGroups"), "Sample colouring",
                           noGroupsLabel="Do not colour samples",
                           groupsLabel="Colour using selected groups"),
            actionButton(ns("showVariancePlot"), "Show variance plot"),
            actionButton(ns("plot"), "Plot PCA", class="btn-primary"))))
    
    kmeansPanel <- conditionalPanel(
        sprintf("input[id='%s'] == '%s'", ns("clusteringMethod"), "kmeans"),
        sliderInput(ns("kmeansIterations"), 
                    "Maximum number of iterations",
                    min=10, max=100, value=20, width="100%"),
        sliderInput(ns("kmeansNstart"), 
                    "Number of initial random sets",
                    min=50, max=1000, value=100, width="100%"),
        selectizeInput(ns("kmeansMethod"), "K-means method", 
                       width="100%", c("Hartigan-Wong",
                                       "Lloyd-Forgy", "MacQueen")))
    pamPanel <- conditionalPanel(
        sprintf("input[id='%s'] == '%s'", ns("clusteringMethod"), "pam"),
        selectizeInput(ns("pamMetric"), width="100%",
                       "Metric to be used when calculating dissimilarities",
                       c("Euclidean", "Manhattan")))
    
    claraPanel <- conditionalPanel(
        sprintf("input[id='%s'] == '%s'", ns("clusteringMethod"), "clara"),
        selectizeInput(ns("claraMetric"), width="100%",
                       "Metric to be used when calculating dissimilarities",
                       c("Euclidean", "Manhattan")),
        sliderInput(
            ns("claraSamples"), "Samples to be randomly drawn",
            min=10, max=1000, value=50, step=10, width="100%"))
    
    clusteringCollapse <- bsCollapsePanel(
        list(icon("th-large"), "Partitioning clustering"),
        value="Partitioning clustering", style="info",
        errorDialog("PCA has not yet been plotted.",
                 id=ns("noClusteringUI")),
        hidden(
            div(id=ns("clusteringUI"),
                selectizeInput(
                    ns("clusteringMethod"),
                    "Partitioning algorithm", width="100%", selected="clara",
                    c("k-means"="kmeans", 
                      "Partitioning around medoids (PAM)"="pam", 
                      "Clustering Large Applications (CLARA)"="clara")),
                sliderInput(ns("clusterNumber"), "Number of clusters",
                            min=1, max=20, value=2, width="100%"),
                bsCollapse(
                    bsCollapsePanel(
                        tagList(icon("plus-circle"), 
                                "Optimal number of clusters"),
                        value="Optimal number of clusters",
                        selectizeInput(
                            ns("estimatationOptimalClusters"), width="100%",
                            "Method to estimate optimal number of clusters",
                            c("Within cluster sums of squares"="wss",
                              "Average silhouette"="silhouette",
                              "Gap statistics"="gap_stat")),
                        highchartOutput(ns("optimalClusters")))),
                kmeansPanel, pamPanel, claraPanel,
                actionButton(ns("saveClusters"), "Create groups from clusters"),
                processButton(ns("plotClusters"), "Plot clusters"))))
    
    tagList(
        uiOutput(ns("modal")),
        sidebar(
            bsCollapse(
                id=ns("pcaCollapse"), open="Perform PCA",
                performPcaCollapse,
                plotPcaCollapse,
                clusteringCollapse)
        ), mainPanel(
            highchartOutput(ns("scatterplot")),
            highchartOutput(ns("scatterplotLoadings"))
        )
    )
}

#' Create the explained variance plot
#' 
#' @param pca PCA values
#' 
#' @importFrom highcharter highchart hc_chart hc_title hc_add_series 
#' hc_plotOptions hc_xAxis hc_yAxis hc_legend hc_tooltip hc_exporting
#' @importFrom shiny tags
#' 
#' @return Plot variance as an Highcharter object
#' @export
#' @examples 
#' pca <- prcomp(USArrests)
#' plotVariance(pca)
plotVariance <- function(pca) {
    eigenvalue <- unname( pca$sdev ^ 2 )
    variance <- eigenvalue * 100 / sum(eigenvalue)
    cumvar <- cumsum(variance)
    ns <- paste("PC", seq_along(eigenvalue))
    
    # Prepare data
    data <- lapply(seq(eigenvalue), function(i) {
        return(list(y=variance[i], eigenvalue=eigenvalue[i], cumvar=cumvar[i]))
    })
    
    hc <- highchart() %>%
        hc_chart(zoomType="xy", backgroundColor=NULL) %>%
        hc_title(text=paste("Explained variance by each",
                            "Principal Component (PC)")) %>%
        hc_add_series(data=data, type="waterfall", cumvar=cumvar) %>%
        hc_plotOptions(series=list(dataLabels=list(
            format=paste0("{point.eigenvalue:.2f}", tags$br(),
                          "{point.y:.2f}%"),
            align="center", verticalAlign="top", enabled=TRUE))) %>%
        hc_xAxis(title=list(text="Principal Components"), 
                 categories=seq(length(data)), crosshair=TRUE) %>%
        hc_yAxis(title=list(text="Percentage of variances"), min=0, max=100) %>%
        hc_legend(enabled=FALSE) %>%
        hc_tooltip(
            headerFormat=paste(tags$b("Principal component {point.x}"),
                               tags$br()),
            pointFormat=paste0(
                "Eigenvalue: {point.eigenvalue:.2f}", tags$br(),
                "Variance: {point.y:.2f}%", tags$br(),
                "Cumulative variance: {point.cumvar:.2f}%")) %>%
        export_highcharts()
    return(hc)
}

#' Create a scatterplot from a PCA object
#' 
#' @param pca \code{prcomp} object
#' @param pcX Character: name of the X axis of interest from the PCA
#' @param pcY Character: name of the Y axis of interest from the PCA
#' @param groups Matrix: groups to plot indicating the index of interest of the
#' samples (use clinical or sample groups)
#' @param individuals Boolean: plot PCA individuals (TRUE by default)
#' @param loadings Boolean: plot PCA loadings/rotations (FALSE by default)
#' 
#' @importFrom highcharter highchart hc_chart hc_xAxis hc_yAxis hc_tooltip %>%
#' @return Scatterplot as an \code{highcharter} object
#' 
#' @export
#' @examples
#' pca <- prcomp(USArrests, scale=TRUE)
#' plotPCA(pca)
#' plotPCA(pca, pcX=2, pcY=3)
#' 
#' # Plot both individuals and loadings
#' plotPCA(pca, pcX=2, pcY=3, loadings=TRUE)
plotPCA <- function(pca, pcX=1, pcY=2, groups=NULL, individuals=TRUE, 
                    loadings=FALSE) {
    if (is.character(pcX)) pcX <- as.numeric(gsub("[A-Z]", "", pcX))
    if (is.character(pcY)) pcY <- as.numeric(gsub("[A-Z]", "", pcY))
    
    imp <- summary(pca)$importance[2, ]
    perc <- as.numeric(imp)
    
    label <- sprintf("%s (%s%% explained variance)",
                     names(imp[c(pcX, pcY)]), 
                     roundDigits(perc[c(pcX, pcY)]*100))
    
    hc <- highchart() %>%
        hc_chart(zoomType="xy") %>%
        hc_xAxis(title=list(text=label[1]), crosshair=TRUE) %>%
        hc_yAxis(title=list(text=label[2]), gridLineWidth=0,
                 minorGridLineWidth=0, crosshair=TRUE) %>%
        hc_tooltip(pointFormat="{point.sample}") %>%
        export_highcharts()
    
    if (individuals) {
        df <- data.frame(pca$x)
        if (is.null(groups)) {
            hc <- hc_scatter(hc, df[[pcX]], df[[pcY]], sample=rownames(df))
        } else {
            # Colour data based on the selected groups
            for (group in names(groups)) {
                rows <- groups[[group]]
                colour <- attr(groups, "Colour")[[group]]
                values <- df[rows, ]
                if (!all(is.na(values))) {
                    hc <- hc_scatter(
                        hc, values[[pcX]], values[[pcY]], name=group, 
                        sample=rownames(values), showInLegend=TRUE,
                        color=colour)
                }
            }
        }
    }
    if (loadings) {
        sdev <- pca$sdev[c(pcX, pcY)]
        eigenvalue <- sdev ^ 2
        loadings <- data.frame(pca$rotation)[, c(pcX, pcY)]
        # Correlation between variables and principal components
        varCoor <- t(loadings) * sdev
        quality <- varCoor ^ 2
        # Total contribution of the variables for the selected PCs
        contr <- quality * 100 / rowSums(quality)
        totalContr <- colSums(contr * eigenvalue)
        
        names <- parseSplicingEvent(rownames(loadings), char=TRUE)
        ## TODO(NunoA): color points with a gradient; see colorRampPalette()
        # For loadings, add series (but don't add to legend)
        hc <- hc_scatter(hc, varCoor[1, ], varCoor[2, ], unname(totalContr), 
                         name="Loadings", sample=names) %>%
            hc_subtitle(text=paste("Bubble size: contribution of a variable",
                                   "to the selected principal components"))
    }
    return(hc)
}

#' Server logic for clustering PCA data
#' 
#' @inheritParams appServer
#' 
#' @importFrom stats kmeans
#' @importFrom cluster pam clara silhouette
#' @importFrom shiny renderTable tableOutput
#' 
#' @return NULL (this function is used to modify the Shiny session's state)
clusterSet <- function(session, input, output) {
    clusterPCA <- reactive({
        algorithm <- input$clusteringMethod
        clusters  <- input$clusterNumber
        pca <- getPCA()
        pcX <- input$pcX
        pcY <- input$pcY
        
        if ( !is.null(pca$x) )
            groups <- getSelectedGroups(input, "colourGroups", "Samples",
                                        filter=rownames(pca$x))
        else
            groups <- NULL
        
        if (is.null(pca) || is.null(pcX) || is.null(pcY)) return(NULL)
        pcaScores <- pca$x[ , c(pcX, pcY)]
        
        clustering <- NULL
        if (algorithm == "kmeans") {
            isolate({
                iterations <- input$kmeansIterations
                nstart     <- input$kmeansNstart
                method     <- input$kmeansMethod
            })
            
            if (method == "Lloyd-Forgy") method <- "Lloyd"
            clustering <- kmeans(pcaScores, clusters, iter.max=iterations, 
                                 nstart=nstart, algorithm=method)
            clustering <- clustering$cluster
        } else if (algorithm == "pam") {
            metric     <- tolower(isolate(input$pamMetric))
            clustering <- pam(pcaScores, clusters, metric=metric, 
                              cluster.only=TRUE)
        } else if (algorithm == "clara") {
            isolate({
                metric  <- tolower(input$claraMetric)
                samples <- input$claraSamples
            })
            
            clustering <- clara(pcaScores, clusters, metric=metric,
                                samples=samples, medoids.x=FALSE, 
                                keep.data=FALSE, pamLike=TRUE)
            clustering <- clustering$clustering
        }
        return(clustering)
    })
    
    observeEvent(input$plotClusters, {
        isolate({
            pca <- getPCA()
            pcX <- input$pcX
            pcY <- input$pcY
            
            if ( !is.null(pca$x) )
                groups <- getSelectedGroups(input, "colourGroups", "Samples",
                                            filter=rownames(pca$x))
            else
                groups <- NULL
        })
        
        if (is.null(pca) || is.null(pcX) || is.null(pcY)) return(NULL)
        
        startProcess("plotClusters")
        clustering <- clusterPCA()
        
        hc <- plotPCA(pca, pcX, pcY, groups) %>% 
            plotClusters(pca$x[ , c(pcX, pcY)], clustering) %>% 
            hc_title(text="Clinical samples (PCA scores)") %>%
            hc_legend(symbolHeight=8, symbolWidth=8)
        output$scatterplot <- renderHighchart(hc)
        endProcess("plotClusters")
    })
    
    # Render optimal clusters
    output$optimalClusters <- renderHighchart({
        algorithm <- input$clusteringMethod
        pca <- getPCA()
        pcX <- input$pcX
        pcY <- input$pcY
        
        if ( !is.null(pca$x) )
            groups <- getSelectedGroups(input, "colourGroups", "Samples",
                                        filter=rownames(pca$x))
        else
            groups <- NULL
        
        if (is.null(pca) || is.null(pcX) || is.null(pcY)) return(NULL)
        pcaScores <- pca$x[ , c(pcX, pcY)]
        
        clusters <- 1:20
        estimation <- input$estimatationOptimalClusters
        if (algorithm == "kmeans") {
            iterations <- input$kmeansIterations
            nstart     <- input$kmeansNstart
            method     <- input$kmeansMethod
            
            if (method == "Lloyd-Forgy") method <- "Lloyd"

            res <- lapply(clusters, function(n) {
                kmeans(pcaScores, n, iter.max=iterations, nstart=nstart, 
                       algorithm=method)
            })
        } else if (algorithm == "pam") {
            metric <- tolower(input$pamMetric)
            res <- lapply(clusters, function(n) {
                pam(pcaScores, n, metric=metric, cluster.only=TRUE)
            })
        } else if (algorithm == "clara") {
            metric  <- tolower(input$claraMetric)
            samples <- input$claraSamples
            
            res <- lapply(clusters, function(n) {
                clara(pcaScores, n, metric=metric, samples=samples, 
                      medoids.x=FALSE, keep.data=FALSE, pamLike=TRUE)
            })
        }
        
        if (estimation == "wss") {
            withinss <- sapply(res, "[[", "tot.withinss")
            hc <- highchart() %>% hc_add_series(withinss) %>%
                hc_xAxis(categories=clusters) %>% hc_legend(enabled=FALSE)
            return(hc)
        } else if (estimation == "silhouette") {
            sil     <- silhouette(res)
            cluster <- sil[ , 2]
            width   <- sil[ , 3]
            names(width) <- cluster
            hc      <- highchart()
            for (i in sort(unique(cluster))) {
                hc <- hc %>% 
                    hc_add_series(unname(width[names(width) == i]), 
                                  type="bar") %>%
                    hc_xAxis(categories=clusters) %>% 
                    hc_legend(enabled=FALSE)
            }
            return(hc)
        }
    })
    
    # Create data groups from clusters
    observeEvent(input$saveClusters, {
        clustering <- clusterPCA()
        if (!is.null(clustering)) {
            new <- split(names(clustering), clustering)
            names <- paste("Cluster", names(new))
            groups <- cbind("Names"=names, 
                            "Subset"="PCA clustering", "Input"="PCA clustering",
                            "Samples"=new)
            rownames(groups) <- names
            
            # Match samples with patients (if loaded)
            patients <- isolate(getPatientId())
            if (!is.null(patients)) {
                indiv  <- lapply(new, function(i)
                    unname(getPatientFromSample(i, patientId=patients)))
                groups <- cbind(groups[ , 1:3], "Patients"=indiv, 
                                groups[ , 4, drop=FALSE])
            }
            
            if (!is.null(groups)) appendNewGroups("Samples", groups)
            infoModal(
                session, "Groups successfully created",
                "The following groups were created based on the selected",
                "clustering options. They are available for selection and",
                "modification from any group selection input.", hr(),
                tableOutput(session$ns("clusteringTable")) )
            
            # Render as table for user
            colnames(groups)[1] <- "Group"
            groups[ , "Samples"]  <- sapply(groups[ , "Samples"], length)
            cols <- c(1, 4)
            if (!is.null(patients)) {
                groups[ , "Patients"] <- sapply(groups[ , "Patients"], length)
                cols <- c(cols, 5)
            }
            output$clusteringTable <- renderTable(groups[ , cols], digits=0,
                                                  align="c")
        }
    })
}

#' @rdname appServer
#' 
#' @importFrom shinyjs runjs hide show
#' @importFrom highcharter %>% hc_chart hc_xAxis hc_yAxis hc_tooltip
#' @importFrom stats setNames
pcaServer <- function(input, output, session) {
    ns <- session$ns
    
    selectGroupsServer(session, "dataGroups", "Samples")
    selectGroupsServer(session, "dataGroups2", "ASevents")
    selectGroupsServer(session, "colourGroups", "Samples")
    
    observe({
        incLevels <- getInclusionLevels()
        geneExpr  <- getGeneExpression()
        if (is.null(incLevels) && is.null(geneExpr)) {
            hide("pcaOptions")
            show("pcaOptionsDialog")
        } else {
            show("pcaOptions")
            hide("pcaOptionsDialog")
        }
    })
    
    observe({
        if (!is.null(getPCA())) {
            hide("noPcaPlotUI", animType="fade")
            show("pcaPlotUI", animType="fade")
        } else {
            show("noPcaPlotUI", animType="fade")
            hide("pcaPlotUI", animType="fade")
            
            show("noClusteringUI", animType="fade")
            hide("clusteringUI", animType="fade")
        }
    })
    
    # Update available data input
    observe({
        geneExpr  <- getGeneExpression()
        incLevels <- getInclusionLevels()
        if (!is.null(incLevels) || !is.null(geneExpr)) {
            choices <- c(attr(incLevels, "dataType"), rev(names(geneExpr)))
            updateSelectizeInput(session, "dataForPCA", choices=choices)
        }
    })
    
    observeEvent(input$loadData, missingDataGuide("Inclusion levels"))
    observeEvent(input$takeMeThere, missingDataGuide("Inclusion levels"))
    
    # Perform principal component analysis (PCA)
    observeEvent(input$calculate, {
        selectedDataForPCA <- input$dataForPCA
        if (selectedDataForPCA == "Inclusion levels") {
            dataForPCA  <- isolate(getInclusionLevels())
            dataType    <- "Inclusion levels"
            groups2Type <- "ASevents"
        } else if (grepl("^Gene expression", selectedDataForPCA)) {
            dataForPCA <- isolate(getGeneExpression()[[selectedDataForPCA]])
            dataType   <- "Gene expression"
            groups2Type <- "Genes"
        } else {
            missingDataModal(session, "Inclusion levels", ns("takeMeThere"))
            return(NULL)
        }
        
        if (is.null(dataForPCA)) {
            missingDataModal(session, "Inclusion levels", ns("takeMeThere"))
        } else {
            time <- startProcess("calculate")
            isolate({
                groups <- getSelectedGroups(input, "dataGroups", "Samples",
                                            filter=colnames(dataForPCA))
                groups2 <- getSelectedGroups(input, "dataGroups2", groups2Type, 
                                             filter=rownames(dataForPCA))
                preprocess <- input$preprocess
                naTolerance <- input$naTolerance
            })
            
            # Subset data based on the selected groups
            if ( !is.null(groups) ) 
                dataForPCA <- dataForPCA[ , unlist(groups), drop=FALSE]
            if ( !is.null(groups2) )
                dataForPCA <- dataForPCA[unlist(groups2), , drop=FALSE]
            
            # Raise error if data has no rows
            if (nrow(dataForPCA) == 0) {
                errorModal(session, "No data!", paste(
                    "PCA returned nothing. Check if everything is as",
                    "expected and try again."))
                endProcess("calculate", closeProgressBar=FALSE)
                return(NULL)
            }
            
            # Transpose the data to have individuals as rows
            dataForPCA <- t(dataForPCA)
            
            # Perform principal component analysis (PCA) on the subset data
            pca <- performPCA(dataForPCA, naTolerance=naTolerance,
                              center="center" %in% preprocess,
                              scale.="scale" %in% preprocess)
            if (is.null(pca)) {
                errorModal(session, "No individuals to plot PCA", 
                           "Try increasing the tolerance of NAs per event")
            } else if (inherits(pca, "error")) {
                ## TODO(NunoA): what to do in this case?
                errorModal(
                    session, "PCA calculation error", 
                    "Constant/zero columns cannot be resized to unit variance")
            } else {
                attr(pca, "dataType") <- dataType
                attr(pca, "firstPCA") <- is.null(getPCA())
                setPCA(pca)
                
                # Clear previously plotted charts
                output$scatterplot <- renderHighchart(NULL)
                output$scatterplotLoadings <- renderHighchart(NULL)
            }
            updateCollapse(session, "pcaCollapse", "Plot PCA")
            endProcess("calculate", closeProgressBar=FALSE)
        }
    })
    
    # Update select inputs of the principal components
    observe({
        pca <- getPCA()
        if (is.null(pca)) {
            choices <- c("PCA has not yet been performed"="")
            updateSelectizeInput(session, "pcX", choices=choices)
            updateSelectizeInput(session, "pcY", choices=choices)
            return(NULL)
        }
        
        imp <- summary(pca)$importance[2, ]
        perc <- as.numeric(imp)
        names(perc) <- names(imp)
        
        # Update inputs to select principal components
        label <- sprintf("%s (%s%% explained variance)", 
                         names(perc), roundDigits(perc * 100))
        choices <- setNames(names(perc), label)
        choices <- c(choices, "Select a principal component"="")
        
        updateSelectizeInput(session, "pcX", choices=choices)
        updateSelectizeInput(session, "pcY", choices=choices, 
                             selected=choices[[2]])
    })
    
    # Show variance plot
    observeEvent(input$showVariancePlot,
                 infoModal(session, size="large", "Variance plot",
                           highchartOutput(ns("variancePlot"))))
    
    # Plot the explained variance plot
    output$variancePlot <- renderHighchart({
        pca <- getPCA()
        if (is.null(pca)) {
            if (input$plot > 0) {
                errorModal(session, "PCA has not yet been performed",
                           "Perform a PCA and plot it afterwards.")
            }
            return(NULL)
        }
        plotVariance(pca)
    })
    
    # Plot the principal component analysis
    observeEvent(input$plot, {
        isolate({
            pca <- getPCA()
            pcX <- input$pcX
            pcY <- input$pcY
            
            if ( !is.null(pca$x) )
                groups <- getSelectedGroups(input, "colourGroups", "Samples",
                                            filter=rownames(pca$x))
            else
                groups <- NULL
        })
        
        output$scatterplot <- renderHighchart({
            if (!is.null(pcX) && !is.null(pcY)) {
                plotPCA(pca, pcX, pcY, groups) %>% 
                    hc_title(text="Clinical samples (PCA scores)")
            }
        })
        
        output$scatterplotLoadings <- renderHighchart({
            if (!is.null(pcX) && !is.null(pcY)) {
                dataType <- attr(pca, "dataType")
                if (dataType == "Inclusion levels") {
                    title <- "Alternative splicing events (PCA loadings)"
                    onClick <- sprintf(
                        "function() {
                            sample = this.options.sample;
                            sample = sample.replace(/ /g, '_');
                            showDiffSplicing(sample, %s); }",
                        toJSarray(isolate(names(groups))))
                } else if (dataType == "Gene expression") {
                    title <- "Genes (PCA loadings)"
                    
                    onClick <- sprintf(
                        "function() {
                            sample = this.options.sample;
                            showDiffExpression(sample, %s, '%s'); }",
                        toJSarray(isolate(names(groups))),
                        isolate(input$dataForPCA))
                }
                
                plotPCA(pca, pcX, pcY, individuals=FALSE, loadings=TRUE) %>%
                    hc_title(text=title) %>%
                    hc_plotOptions(series=list(
                        cursor="pointer", point=list(events=list(
                            click=JS(onClick)))))
            }
        })
        
        hide("noClusteringUI", animType="fade")
        show("clusteringUI", animType="fade")
        
        updateSliderInput(session, "kmeansNstart", max=nrow(pca$x), value=100)
        updateSliderInput(session, "claraSamples", max=nrow(pca$x), value=50)
    })
    
    clusterSet(session, input, output)
}

attr(pcaUI, "loader") <- "dimReduction"
attr(pcaUI, "name") <- "Principal Component Analysis (PCA)"
attr(pcaServer, "loader") <- "dimReduction"