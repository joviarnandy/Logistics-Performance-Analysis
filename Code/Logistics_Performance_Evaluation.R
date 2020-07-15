### DISCLAIMER:
## Below code is CPU Intensive! Make sure you run it on >= 16 GB RAM

#Load Library
library(vroom)
library(stringr)
library(bit64)
library(readxl)
library(reshape2)
library(purrr)
library(dplyr)

#Read huge data input quickly
data = vroom::vroom("delivery_orders_march.csv")
head(data)

#Convert character columns into UPPERCASE format
x = (as.data.frame(sapply(data[, 5:6], toupper)))
data$buyeraddress = x$buyeraddress
data$selleraddress = x$selleraddress
rm(x)
data$buyeraddress = as.character(data$buyeraddress)
data$selleraddress = as.character(data$selleraddress)

#Define function to simplify buyer and seller address
simplify_buy = function(df){
  output = tail(str_split(df, " ")[[1]], n=1)
  return(output)
}
simplify_sell = function(df){
  output = tail(str_split(df, " ")[[1]], n=1)
  return(output)
}

#Implement above function
y1 = (as.data.frame(sapply(data$buyeraddress, simplify_buy)))
rownames(y1) = NULL
colnames(y1) = "buyeraddress"
y2 = (as.data.frame(sapply(data$selleraddress, simplify_sell)))
rownames(y2) = NULL
colnames(y2) = "selleraddress"
rm(list=setdiff(ls(), c("data")))

#Further column format conversion
data$orderid = as.integer64(data$orderid)
colnames(data)[3] = "first_deliver_attempt"
colnames(data)[4] = "second_deliver_attempt"
data$pick = as.POSIXct(as.numeric(as.character(data$pick)),origin="1970-01-01",tz="Asia/Singapore")
data$first_deliver_attempt = as.POSIXct(as.numeric(as.character(data$first_deliver_attempt)),origin="1970-01-01",tz="Asia/Singapore")
data$second_deliver_attempt = as.POSIXct(as.numeric(as.character(data$second_deliver_attempt)),origin="1970-01-01",tz="Asia/Singapore")

#Read and Reformat SLA_Matrix
sla_mat = read_xlsx("../input/logistics-shopee-code-league/SLA_matrix.xlsx")
sla_mat = sla_mat[1:5,2:6]
x = sla_mat[2:5,2:5]
x = as.matrix(x)
rownames(x) = as.vector(unlist(sla_mat[2:5,1]))
colnames(x) = as.vector(unlist(sla_mat[1,2:5]))
y = as.matrix(as.numeric(gsub("([0-9]+).*$", "\\1", x)))
for (i in 1:(dim(x)[1])){
  for(j in 1:(dim(x)[2])){
    x[i,j] = (y[[i*j]])
  }
}
z=setNames(melt(x), c('selleraddress', 'buyeraddress', 'expected_days'))
z$selleraddress = as.character(z$selleraddress)
z$buyeraddress = as.character(z$buyeraddress)
z$days = as.numeric(z$expected_days)
SLA_matrix = z 
SLA_matrix$selleraddress = toupper(SLA_matrix$selleraddress)
SLA_matrix$buyeraddress = toupper(SLA_matrix$buyeraddress)
SLA_matrix$days = NULL 
SLA_matrix[SLA_matrix=="METRO MANILA"] = "MANILA"
SLA_matrix$expected_days = as.numeric(as.character(SLA_matrix$expected_days))
rm(list=setdiff(ls(), c("data","SLA_matrix")))

#Perform left join between data and formatted SLA_matrix
data = left_join(data,SLA_matrix)

#Making sure no NA value at orderid column
anyNA(data$orderid)

#Define function to calculate working days between dates 
#based on Shopee's Rule
networkDays <- function(beginDate, endDate, holidayDates) {
  # get all days between beginDate and endDate
  allDays <- seq.Date(from=beginDate, to=endDate, by=1)
  # use setdiff to remove holidayDates and convert back to date vector
  nonHolidays <- as.Date(setdiff(allDays, holidayDates), origin="1970-01-01")
  # find all weekends left in nonHolidays
  weekends <- nonHolidays[weekdays(nonHolidays) %in% c("Sunday")]
  # use setdiff again to remove the weekends from nonHolidays and convert back to date vector
  nonHolidaysWeekends <- as.Date(setdiff(nonHolidays, weekends), origin="1970-01-01")
  # return length of vector filtered for holidays and weekends
  length(nonHolidaysWeekends)
}
busday = function(df1,df2){
  d1 = as.Date(df1,tz = "Asia/Singapore")
  d2 = as.Date(df2,tz = "Asia/Singapore")
  holidays_definition <- c(as.Date("2020-03-25 00:00:00",tz = "Asia/Singapore"), as.Date("2020-03-30 00:00:00",tz = "Asia/Singapore"), as.Date("2020-03-31 00:00:00",tz = "Asia/Singapore"),as.Date("2020-03-08 00:00:00",tz = "Asia/Singapore"))
  output = networkDays(d1, d2, holidays_definition) - 1
  return(output)
}

#Perform above functions
p = data [1:dim(data)[1],]
p1 = (as.data.frame(mapply(busday, p$pick, p$first_deliver_attempt)))
colnames(p1) = "workdays_between_pick_and_firstdeliver"
data$workdays_between_pick_and_firstdeliver = p1$workdays_between_pick_and_firstdeliver
rm(p1)

#Fill NA Dates (you can change it as long as it's "far enough" 
#from final dates in the data)
data[is.na(data$second_deliver_attempt),4] = as.POSIXct("2020-05-15 00:00:00",origin="1970-01-01",tz="Asia/Singapore")

#Performa above funtions again..
pp = data [1:dim(data)[1],]
p2 = (as.data.frame(mapply(busday, pp$first_deliver_attempt, pp$second_deliver_attempt)))
colnames(p2) = "workdays_between_firstdeliver_and_seconddeliver"
data$workdays_between_firstdeliver_and_seconddeliver = p2$workdays_between_firstdeliver_and_seconddeliver
rm(pp,p2)

#Add important columns
data$first_deliver_time_reserve = data$expected_days - data$workdays_between_firstdeliver_and_seconddeliver
data$second_deliver_time_reserve = 3 - data$workdays_between_firstdeliver_and_seconddeliver

data = data %>%
  mutate(is_late = case_when(
    data$first_deliver_time_reserve >= 0 & data$second_deliver_time_reserve < 0 ~ "0",
    data$first_deliver_time_reserve >= 0 & data$second_deliver_time_reserve >= 0 ~ "0",
    data$first_deliver_time_reserve < 0 & data$second_deliver_time_reserve >= 0 ~ "0",
    data$first_deliver_time_reserve < 0 & data$second_deliver_time_reserve < 0 ~ "1"       
  )
  )

#write submission file for further analysis (i.e Mathew Correlation Matrix etc)
submission = data[c("orderid","is_late")]
rm(list=setdiff(ls(), c("submission")))
write.csv(submission,"submission.csv",row.names=FALSE)
cat("\014")
