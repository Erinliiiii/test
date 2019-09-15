library(janitor)
library(plyr)
library(dplyr)

# load dataset
data = read.csv('test data.csv')
# transform title to standard format
data <- clean_names(data)

#2. Show the first, second and last transaction for every customer
first_second = data %>%
    group_by(customer) %>%
    filter(row_number(transaction_id)<=2) %>%
    mutate(row_num = row_number(transaction_id))

last = data %>%
    group_by(customer) %>%
    filter(row_number(desc(transaction_id))==1) %>%
    mutate(row_num = row_number(transaction_id))

last$row_num = 3  # convert row_num from 1 to 3 which indicates the last order of each customer
first_second_last = rbind(first_second, last)
first_second_last = first_second_last[order(first_second_last$customer, first_second_last$row_num),]

first_second_last$order[first_second_last$row_num==1] = 'first'
first_second_last$order[first_second_last$row_num==2] = 'second'
first_second_last$order[first_second_last$row_num==3] = 'last'

#3. Show the first, second and last transaction for every customer for every year
first_second2 = data %>%
    group_by(customer, year) %>%
    filter(row_number((transaction_id))<=2) %>%
    mutate(row_num = row_number((transaction_id)))

last2 = data %>%
    group_by(customer, year) %>%
    filter(row_number(desc(transaction_id))==1) %>%
    mutate(row_num = row_number((transaction_id)))

last2$row_num = 3
first_second_last2 = rbind(first_second2, last2)
first_second_last2 = first_second_last2[order(first_second_last2$customer, first_second_last2$year),]

first_second_last2$order[first_second_last2$row_num==1] = 'first'
first_second_last2$order[first_second_last2$row_num==2] = 'second'
first_second_last2$order[first_second_last2$row_num==3] = 'last'

#4. What months do customers make their first transaction. How many make 1st transaction in Jan., how many in Feb. etc.
first = data %>%
    group_by(customer) %>%
    filter(row_number((transaction_id))==1)

count_by_customer = first %>%
    group_by(month) %>%
    summarize(num = n())

month = unique(data$month)
month = month[order(month)]
month = ldply (month, data.frame) # transform list to dataframe
colnames(month) = 'month'

count_by_customer = left_join(month, count_by_customer, by = 'month')
count_by_customer$num[is.na(count_by_customer$num)] = 0

#5. What is average time between first and second transaction month for a customer
library(zoo)
data$date <- as.yearmon(paste(data$year, data$month, sep = '-')) # combine year and month
data$date = as.Date(data$date)


first_order <- data %>%
    group_by(customer) %>%
    filter(row_number(transaction_id)==1)


second_order <- data %>%
    group_by(customer) %>%
    filter(row_number(transaction_id)==2)

#inner join first and second order for each customer
month_diff <- inner_join(first_order, second_order, by = c("customer"="customer"))

# a function to get month difference
get_month_diff <- function(end_date, start_date) {
    ed <- as.POSIXlt(end_date)
    sd <- as.POSIXlt(start_date)
    12 * (ed$year - sd$year) + (ed$mon - sd$mon)
}

month_diff$diff <- get_month_diff(month_diff$date.y, month_diff$date.x)
avg_month_diff <- mean(month_diff$diff)

first_second3 <- data %>%
    group_by(customer) %>%
    filter(row_number(transaction_id)<=2) %>%
    mutate(row_num = row_number(transaction_id))

# create a new column which is row_num + 1
first_second3$row_num2 <- first_second3$row_num + 1
# join two tables
month_diff <- inner_join(first_second3, first_second3, by = c("row_num"="row_num2", "customer"="customer"))

# a function to get month difference
get_month_diff <- function(end_date, start_date) {
    ed <- as.POSIXlt(end_date)
    sd <- as.POSIXlt(start_date)
    12 * (ed$year - sd$year) + (ed$mon - sd$mon)
}

month_diff$diff <- get_month_diff(month_diff$date.x, month_diff$date.y)
avg_month_diff <- mean(month_diff$diff)
# 1.1667

#6. What % of customers have YoY increase in spend
spend_by_year <- data %>%
    group_by(customer, year) %>%
    summarize(total_spend = sum(spend))

# add a column which is year + 1
spend_by_year$year_plus_1 <- spend_by_year$year + 1
yoy <- inner_join(spend_by_year, spend_by_year, by = c('year'='year_plus_1', 'customer'='customer'))
sum((yoy$total_spend.x - yoy$total_spend.y)>0)/nrow(yoy)
# 100%







