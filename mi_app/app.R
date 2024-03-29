#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(bigrquery)
library(googleCloudStorageR)
#Aqui se carga el token para conectarse al servicio de Bigquery en nuestra cuenta GCP
bigrquery::bq_auth(path ="shiny-apps-385622-08e5b9820326.json")
googleCloudStorageR::gcs_auth(json_file = "shiny-apps-385622-0553170e693d.json")
#googleCloudStorageR::gcs_list_buckets("shiny-apps-385622")


# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Esta es una aplicación de demostración desarrollada con la libreria shiny en R"),
    fluidRow(imageOutput("imagen")),
    # Sidebar with a slider input for number of bins 
    fluidRow(sidebarLayout(
        sidebarPanel(
            sliderInput("bins",
                        "Numero de columnas:",
                        min = 1,
                        max = 50,
                        value = 30)
        ),

        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("distPlot")
        )
    )),
    fluidRow(actionButton(inputId = "boton",label =  "Descarga")),
    fluidRow(dataTableOutput("datos_bigquery"))
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    output$imagen <- renderImage({
    googleCloudStorageR::gcs_get_object(object_name ="uss.png" ,bucket = "imagenes_app_uss",saveToDisk ="uss_GCS.png",overwrite = TRUE )
    list(src = "uss_GCS.png")
    
    }, deleteFile = F)
    
    output$distPlot <- renderPlot({
        # generate bins based on input$bins from ui.R
        x    <- faithful[, 2]
        bins <- seq(min(x), max(x), length.out = input$bins + 1)

        # draw the histogram with the specified number of bins
        hist(x, breaks = bins, col = 'darkgray', border = 'white',
             xlab = 'Waiting time to next eruption (in mins)',
             main = 'Histogram of waiting times')
    })
    
    #Aqui se define el proyecto en el cual habilitamos el servicio Bigquery
    project_id <- "shiny-apps-385622"
    
    #Esta es la consulta SQL que realizamos al servicio BigQuery
    sql<-"SELECT * from `bigquery-public-data.austin_bikeshare.bikeshare_trips` LIMIT 30"
    
    #Aqui estamos generando un set de datos vacio
    respuesta <- reactiveValues(data=NULL)
    
    #Aca estamos recibiendo el input del boton definido en la UI,para hacer luego la consulta SQL
    observeEvent(input$boton, {
      consulta <- bigrquery::bq_project_query(project_id, sql)
      respuesta$datos <-bigrquery::bq_table_download(consulta, n_max = 30)
    })
    
    output$datos_bigquery<-renderDataTable({respuesta$datos    }) 
    
}

# Run the application 
shinyApp(ui = ui, server = server)
