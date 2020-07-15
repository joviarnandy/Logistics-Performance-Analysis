# Logistics-Performance-Analysis

### Short Description of Repository

This repo contains data and R code for the Logistic Performance Analysis Task in the E-Commerce Industry, part of the 2020 Shopee Code League Competition hosted on Kaggle.

1. The primary data (CSV file) contains the following information:
    
    - orderid = transaction identification
    
    - pick = timestamp when order is picked up by Logistics Provider
    
    - 1st_deliver_attempt = timestamp when order is, for the first time, delivered by Logistics Provider
    
    - 2nd_deliver_attempt = timestamp when order is, for the second time because "failed" in the previous attempt, delivered by Logistics Provider
    
    - buyeraddress = street address of order receiver
    
    - selleraddress = street address of order sender

2. The secondary data (XLSX file) contains a directional matrix filled with numbers representing how long (in working days) it takes to deliver one order from one location to another location normally. FYI, this is also called Service Level Agreements (SLA) between Shopee and Logistics Provider. 

3. Our goal is to label each transaction/order as late by "1" or not late by "0"

4. The rules and assumption of labeling are listed below (quoted directly from Shopee):
    
    - Working Days are defined as Mon-Sat, Excluding Public Holidays.
    
    - Assume the following Public Holidays: 
      * 2020-03-08 (Sunday)
      * 2020-03-25 (Wednesday);
      * 2020-03-30 (Monday);
      * 2020-03-31 (Tuesday)
    
    - SLA calculation begins from the next day after pickup (Day 0 = Day of Pickup; Day 1 = Next Day after Pickup)
    
    - 2nd Attempt must be no later than 3 working days after the 1st Attempt, regardless of origin to destination route
      (Day 0 = Day of 1st Attempt; Day 1 = Next Day after 1st Attempt).
      

### Motivation

This task is important because we want to measure the quality of Shopee's delivery timeliness through Logistics Provider performance. 

### Disclaimer

* Pardon my messy writing on several lines of code.
* Make sure to run the code on PC/Laptop with at least 8 GB of RAM (possibly CPU-Intensive since it takes approximately two hours to run).

### TODO

Upload short tutorials in the future when time permits.
