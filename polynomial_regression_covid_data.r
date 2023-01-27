#https://mdl.library.utoronto.ca/technology/tutorials/covid-19-data-r
#https://rpubs.com/khusniank/SMAADWprac2

options(scipen=999)

#Loading libraries
library(ggplot2)
library(tidyverse)
library(dplyr)
library(corrplot)
library(naniar)
library(plotly)
library(data.table)           #for fread()
library(plyr)
library(scales)
library(jtools)               #for theme_apa()
library(cowplot)
library(lubridate)
library(crosstable)
library(kableExtra)
library(DT)
library(caret)                #for createdatapartition()
library(forcats)
library(TTR)                  #for SMA() 

#Importing datasets
covid.data <- fread("https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/owid-covid-data.csv")

#looking into the dataset
head(covid.data)
str(covid.data)

#cleaning the data
#checking if there are missing values
colSums(is.na(covid.data))

#plotting the missing values using naniar package
gg_miss_var(covid.data)
#lots of missing values

#Replacing the missing values with certain data
##Since I won't be using all the variables in the dataset, I will be only replacing the missing values of certain variables
covid.data$new_cases[is.na(covid.data$new_cases)] <- 0
covid.data$total_cases[is.na(covid.data$total_cases)] <- 0
covid.data$new_deaths[is.na(covid.data$new_deaths)] <- 0
covid.data$total_deaths[is.na(covid.data$total_deaths)] <- 0
covid.data$tests_per_case[is.na(covid.data$tests_per_case)] <- 0
covid.data$people_fully_vaccinated[is.na(covid.data$people_fully_vaccinated)] <- 0
covid.data$icu_patients[is.na(covid.data$icu_patients)] <- 0
covid.data$hosp_patients[is.na(covid.data$hosp_patients)] <- 0
covid.data$new_tests[is.na(covid.data$new_tests)] <- 0
covid.data$reproduction_rate[is.na(covid.data$reproduction_rate)] <- 0
covid1 <- covid.data %>%
  group_by(location) %>%
  mutate_at(vars(population_density, median_age, gdp_per_capita, extreme_poverty, human_development_index, male_smokers, female_smokers, icu_patients, hosp_patients),
            ~replace_na(.,
                        mean(., na.rm = T))) %>%
  select(median_age, extreme_poverty)


colSums(is.na(covid.data))
#changing date variable into date format
covid.data$date <- as.Date(covid.data$date, format = "%Y-%m-%d")

#Removing continents from country column
continents <- c("Asia", "Africa", "European Union", "Europe", "High income", "Lower middle income", "Low Income", "Upper middle income", 'Oceania', "South America", "North America", "International", "World")
covid <- subset(covid.data, !(location %in% continents))

#Removing the blank spaces from continent column
covid <- subset(covid, !(continent == ""))

#latest day
day_latest <- max(covid$date)

#creating heatmaps
covid.cases <- covid %>%
  group_by(location) %>%
  filter(date == max(date))

#creating covid cases heat maps
line <- list(color = toRGB("#d1d1d1"), width = 0.4)
heatmap <- list(
  showframe = F,
  showcoastlines = F,
  projection = list(type = "orthographic"),
  resolution = "100",
  showcountries = T,
  countrycolor = "#d1d1d1",
  showocean = T,
  oceancolor = '#064273',
  showlakes = T,
  lakecolor = '#99c0db',
  showrivers = T,
  rivercolor = '#99c0db',
  bgcolor = '#e8f7fc')

plot_geo() %>%
  layout(geo = heatmap,
         paper_bgcolor = '#e8f7fc',
         title = paste0("World COVID-19 Confirmed Cases till ", day_latest)) %>%
  add_trace(data = covid.cases,
            z = ~total_cases,
            colors = "Reds",
            text = ~location,
            locations = ~iso_code,
            marker = list(line = line))

##Heatmap for covid deaths
plot_geo() %>%
  layout(geo = heatmap,
         paper_bgcolor = '#e8f7fc',
         title = paste0("World COVID-19 deaths till ",  day_latest)) %>%
  add_trace(data = covid.cases,
            z = ~total_deaths,
            colors = "Reds",
            text = ~location,
            locations = ~iso_code,
            marker = list(line = line))

##Heatmap for COVID vaccination status
# covid.vaccination <- covid %>%
#   group_by(location) %>%
#   filter(people_fully_vaccinated == max(people_fully_vaccinated)) %>%
#   select(date, location, people_fully_vaccinated, iso_code)
# 
# plot_geo() %>%
#   layout(geo = heatmap,
#          paper_bgcolor = '#e8f7fc',
#          title = paste0("Vaccination status till ",  day_latest)) %>%
#   add_trace(data = covid.vaccination,
#             z = ~people_fully_vaccinated,
#             colors = "Reds",
#             text = ~location,
#             locations = ~iso_code,
#             marker = list(line = line))

#summary statistics
#creating month column
year.month <- covid %>%
  mutate(Month = as.character(lubridate::month(date)),
         Year = lubridate::year(date)) %>%
  select(continent, location, Year, Month, new_cases, new_deaths)

#recoding the month column
year.month$Month <- recode(year.month$Month, 
                      "1" = "January",
                      "2" = "February",
                      "3" = "March",
                      "4" = "April",
                      "5" = "May",
                      "6" = "June", 
                      "7" = "July",
                      "8" = "August",
                      "9" = "September",
                      "10" = "October",
                      "11" = "November",
                      "12" = "December")
#covid %>%
 # filter(location == "Afghanistan") %>%
  #summarize(total_cases = sum(total_cases))

covid_summary_statistics <- year.month %>%
  group_by(location, Month, Year) %>%
  dplyr::summarise(Total.Deaths = sum(new_deaths, na.rm = T),
         Total.Cases = sum(new_cases, na.rm = T),
         Mean.cases.per.day = round(mean(new_cases, na.rm =T),2),
         Mean.deaths.per.day = round(mean(new_deaths, na.rm =T),2))

covid_summary_statistics %>%
  select(location, Year, Month, Total.Cases, Total.Deaths, Mean.cases.per.day, Mean.deaths.per.day) %>%
  datatable(
    rownames = F,
    class = "cell-border stripe",
    colnames = c("Country", "Year", "Month", "Total cases", "Total Deaths", "Mean cases per day", "Mean Deaths per day"),
    caption = "Country wise COVID-19 Cases and Deaths",
    options = list(columnDefs = list(list(className = "dt-center", targets = 0:1)))
  )

#Trend of world covid cases and deaths
covid %>%
  group_by(date) %>%
  filter(date != day_latest) %>%
  dplyr::summarise(total_deaths = sum(total_deaths, na.rm = T), 
                   total_cases = sum(total_cases, na.rm = T), .groups = "drop") %>%
  ggplot(aes(x = date)) +
  geom_line(aes(y = total_cases + 1), color = "#2e9449", linewidth = 1.5) +
  geom_line(aes(y = total_deaths + 1), linewidth = 1.5, linetype = 2, color = "#9c2742") +
  scale_y_continuous(trans = "log10", labels = comma) +
  scale_x_date(date_labels = "%b %Y", date_breaks = "3 months") +
  labs(title = "Global COVID infections and deaths",
       subtitle = paste0("Till ", day_latest - 1),
       x = "",
       y = "Log10 transformation") +
  theme_apa() +
  theme(axis.text.x = element_text(angle = 90, color = "black", hjust = 1),
        axis.text = element_text(color = "black")) +
  geom_vline(xintercept = as.Date("2020-03-11"), linetype = "longdash", linewidth = 0.8, col = "black") +
  annotate("text", x = as.Date("2020-03-10"), y = 11100, label = "WHO announces pandemic \n", size = 4.2, angle = 90) +
  geom_vline(xintercept = as.Date("2020-01-30"), linetype = "longdash", linewidth = 0.8, col = "black") +
  annotate("text", x = as.Date("2020-01-20"), y = 16100, label = "Global health emergency declared \n", size = 4.2, angle = 90) +
  annotate("text", x = as.Date("2021-05-05"), y = 1000000, label = "Total Deaths \n", size = 4.2) +
  annotate("text", x = as.Date("2021-05-05"), y = 50000000, label = "Total Cases \n", size = 4.2)

#Trend of new covid cases in different continents
p1 <- covid %>%
  group_by(date, continent) %>%
  dplyr::summarise(new_covid_cases = sum(new_cases, na.rm = T), .groups = "drop") %>%
  ggplot(aes(date)) +
  geom_col(aes(y = new_covid_cases, color = continent)) +
  labs(
    title = "Trend of New COVID-19 cases in different continents",
    subtitle = paste0("Till ", day_latest - 1),
    y = "",
    x = ""
  ) +
  theme_bw() +
  theme(
    legend.position = "none",
    axis.text.x = element_text(angle = 90, hjust = 0.6)
  ) +
  scale_x_date(date_labels = "%b %Y", date_breaks = "6 months") +
  facet_wrap(~continent)
p1

#Trend of new covid deaths in different continents
p2 <- covid %>%
  group_by(date, continent) %>%
  dplyr::summarise(new_covid_deaths = sum(new_deaths, na.rm = T)) %>% 
  ggplot(aes(date)) +
  geom_col(aes(y = new_covid_deaths, color = continent)) +
  labs(
    title = "Trend of New COVID-19 deaths in different continents",
    subtitle = paste0("Till ", day_latest - 1),
    y = "",
    x = ""
  ) +
  theme_bw() +
  theme(
    legend.position = "none",
    axis.text.x = element_text(angle = 90, hjust = 0.6)
  ) +
  scale_x_date(date_labels = "%b %Y", date_breaks = "3 months") +
  facet_wrap(~continent)
p2
                                   

#COVID cases by months
month.df <- year.month %>%
  group_by(Month, continent) %>%
  dplyr::summarise(total.cases = sum(new_cases, na.rm = T))

month.df$Month <- factor(month.df$Month, levels=c("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"))

p3<-ggplot(month.df, aes(x = Month, y = total.cases)) +
  geom_col() +
  facet_wrap(~continent) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90, vjust=0.2),
        axis.text = element_text(size = 9, color = "black")) +
  labs(
    x = "",
    y = "Total Cases",
    title = "COVID - 19 cases in different continents in different months",
    subtitle = paste0("Till ", day_latest-0)
  ) +
  scale_y_continuous(label = comma)
p3
ggplotly(p3)

#Top 10 countries with most covid cases
top.10.covid.countries <- covid %>%
  select(location, new_cases, date) %>%
  group_by(location) %>%
  dplyr::summarise(total.cases = sum(new_cases, na.rm = T)) %>%
  top_n(10, total.cases) %>%
  arrange(desc(total.cases)) %>%
  mutate(country.reordered = fct_reorder(location, total.cases))

p4 <- top.10.covid.countries %>%
  ggplot(aes(country.reordered, total.cases)) +
  geom_col() +
  geom_text(aes(label=total.cases), hjust = -0.1, size = 3) +
  scale_y_continuous(label = comma) +
  labs(
    x = "Total Cases",
    y = "",
    title = "Top 10 countries with highest COVID-19 infections",
    subtitle = paste0("Till ", day_latest-1)
  ) +
  theme_bw() +
  coord_flip()
p4

#Top 10 countries with most COVID-19 deaths
top.10.covid.deaths.countries <- covid %>%
  select(date, location, new_deaths) %>%
  group_by(location) %>%
  dplyr::summarise(total.deaths = sum(new_deaths, na.rm = T)) %>%
  top_n(10, total.deaths) %>%
  arrange(desc(location)) %>%
  mutate(country.reordered = fct_reorder(location, total.deaths))
p5 <- top.10.covid.deaths.countries %>%
  ggplot(aes(country.reordered, total.deaths)) +
  geom_col() +
  geom_text(aes(label = total.deaths), hjust = -0.1, size = 3) +
  scale_y_continuous(label = comma) +
  labs(x = "",
       y = "Total Deaths",
       title = "Top 10 countries with most COVID-19 deaths",
       subtitle = paste0("Till ", day_latest-1)) +
  theme_bw() +
  coord_flip()
p5

#Scatter plot between covid cases and deaths
# p6 <- covid %>%
#   select(continent, date, new_deaths, new_cases, location) %>%
#   group_by(location, continent) %>%
#   dplyr::summarise(total.cases = sum(new_cases, na.rm = T),
#                    total.deaths = sum(new_deaths, na.rm = T)) %>%
#   ggplot(aes(total.cases, total.deaths)) +
#   geom_point(alpha = 0.6) +
#   geom_smooth(method = "lm", se = F) +
#   labs(
#     x = "Total Cases",
#     y = "Total Deaths",
#     title = "Scatter plot of total cases vs deaths"
#   ) +
#   theme_bw()
# p6

#Selecting certain columns of covid.data 
data_sample %>% 
  group_by(group) %>% 
  mutate_at(vars(x1,x2,x3), 
            ~replace_na(., 
                        mean(., na.rm = TRUE)))

covid.data_corr <- covid %>%
  select(new_cases, new_deaths, new_tests, population_density, median_age, gdp_per_capita, extreme_poverty, human_development_index, handwashing_facilities, male_smokers, female_smokers, icu_patients, hosp_patients)

#Plotting the correlation matrix
cor <- cor(covid.data_corr)
col <- colorRampPalette(c("#BB4444", "#EE9988", "#FFFFFF", "#77AADD", "#4477AA"))
corrplot(cor, method = 'color', 
         type = "upper", #Displays only upper part of the matrix
         order = "hclust",
         col=col(200),
         addCoef.col = "black",  #Add coeffiecient of correlation
         number.cex = 0.8,
         tl.col="black",  #Text label color
         tl.srt=90,  #Text label rotation
         diag = FALSE,
         sig.level = 0.01, insig = "blank")

#Polynomial Regression model
nepal.df <- covid %>%
  filter(location == "Nepal") %>%
  select(date, new_tests, new_cases, new_deaths, stringency_index, reproduction_rate, population)

train.data <- nepal.df %>%
  filter(date <= "2022-3-31")
test.data <- nepal.df %>%
  filter(date > "2022-4-1")

model <- lm(new_cases ~ poly(new_tests,3) + stringency_index, data = train.data)
summary(model)


