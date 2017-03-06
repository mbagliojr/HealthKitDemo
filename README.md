# HealthKitDemo
HealthKitDemo

There are three methods that contain logic related to health kit.

## Question 1 method
This method gets all of the steps from the date in start date through end date

## Question 2 method
This method can take any health tracked type but is currently set to steps. It requests permission if it hasn't already been obtained for reading. It gets all the steps (in this case) for each day and prints them in the table view. It also always works on whole days regardless of the h:mm set in the start date and end date, date pickers. 

## Question 3 method
This method prints out every individual sample that makes up question 2. Rather than having N line items where N represents days. It has N line items, where N represents samples
