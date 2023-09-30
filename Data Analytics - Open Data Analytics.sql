-- Stamp Registration
/* 1.How does the revenue generated from document registration vary across districts in Telangana? 
List down the top 5 districts that showed the highest document registration revenue growth between FY 2019 and 2022*/
WITH x AS
(SELECT dist_code,SUM(documents_registered_rev) AS rev_2019
FROM fact_stamps
WHERE YEAR(month) = 2019 AND  month(month)>=4 OR YEAR(month)=2020 AND month(month)<4
GROUP BY dist_code),
y AS
(SELECT dist_code,SUM(documents_registered_rev) AS rev_2022
FROM fact_stamps
WHERE YEAR(month) = 2022 AND  month(month)>=4 OR YEAR(month)=2023 AND month(month)<4
GROUP BY dist_code)
SELECT d.dist_code,d.district,rev_2019,rev_2022,((rev_2022-rev_2019)/rev_2019)*100 AS rev_growth_percent
FROM dim_districts d
JOIN x ON d.dist_code=x.dist_code
JOIN y ON x.dist_code=y.dist_code
ORDER BY rev_growth_percent DESC
LIMIT 5;

/* 2. How does the revenue generated from document registration compare to the revenue generated from e-stamp challans across districts?
List down the top 5 districts where e-stamps revenue contributes significantly more to the revenue than the documents in FY 2022? */
SELECT d.dist_code,d.district, SUM(documents_registered_rev) AS rev_doc, SUM(estamps_challans_rev) AS rev_estamps
FROM fact_stamps s
JOIN dim_districts d ON d.dist_code = s.dist_code
WHERE YEAR(month) = 2022 AND  month(month)>=4 OR YEAR(month)=2023 AND month(month)<4
GROUP BY d.dist_code,d.district
HAVING rev_estamps>rev_doc
ORDER BY rev_estamps DESC
LIMIT 5;

/* 3. Is there any alteration of e-Stamp challan count and document registration count pattern since the implementation of e-Stamp challan?
If so, what suggestions would you propose to the government?*/
SELECT  YEAR(month) AS years, SUM(documents_registered_cnt) AS doc_cnt, SUM(estamps_challans_cnt) AS challan_cnt
FROM fact_stamps
GROUP BY YEAR(month);

/* 4. Categorize districts into three segments based on their stamp registration revenue generation during
 the fiscal year 2021 to 2022. */
 WITH x AS
(SELECT d.dist_code,d.district,SUM(estamps_challans_rev)  AS rev_2021
FROM fact_stamps s
JOIN dim_districts d ON s.dist_code=d.dist_code
WHERE YEAR(month) = 2021 AND  month(month)>=4 OR YEAR(month)=2022 AND month(month)<4
GROUP BY d.dist_code,d.district
ORDER BY rev_2021 DESC)
SELECT *,
    CASE
        WHEN rev_2021 >= 1000000000 THEN 'High Revenue'
        WHEN rev_2021 >= 300000000 AND rev_2021 < 1000000000 THEN 'Moderate Revenue'
        ELSE 'Low Revenue'
    END AS segment
FROM x;

-- Transportation
/* 5.Investigate whether there is any correlation between vehicle sales and specific months or seasons in different districts.
Are there any months or seasons that consistently show higher or lower sales rate, and if yes, what could be the driving factors? (Consider Fuel-Type category only)*/
SELECT MONTHNAME(month) AS Months, SUM(fuel_type_petrol + fuel_type_diesel +fuel_type_electric + fuel_type_others) AS total_sales
FROM fact_transport
GROUP BY 1
ORDER BY total_sales DESC;

/* 6.How does the distribution of vehicles vary by vehicle class (MotorCycle, MotorCar, AutoRickshaw, Agriculture) across different districts?
Are there any districts with a predominant preference for a specific vehicle class? Consider FY 2022 for analysis.*/
SELECT d.dist_code,d.district,SUM(vehicleClass_MotorCycle) AS vc_MotorCycle,SUM(vehicleClass_MotorCar) AS vc_Motor_Car,SUM(vehicleClass_AutoRickshaw)  AS vc_AutoRickshaw,SUM(vehicleClass_Agriculture) AS vc_Agriculture
FROM fact_transport ft
JOIN dim_districts d ON ft.dist_code=d.dist_code
WHERE YEAR(month) = 2022 AND  month(month)>=4 OR YEAR(month)=2023 AND month(month)<4
GROUP BY d.dist_code,d.district;

/* 7. List down the top 3 and bottom 3 districts that have shown the highest and lowest vehicle sales growth during FY 2022 compared to FY 2021?
(Consider and compare categories: Petrol, Diesel and Electric)*/
WITH x AS
(SELECT d.dist_code,d.district,SUM(fuel_type_petrol+fuel_type_diesel+fuel_type_electric) AS sales_2021
FROM fact_transport ft
JOIN dim_districts d ON ft.dist_code=d.dist_code
WHERE YEAR(month) = 2021 AND  month(month)>=4 OR YEAR(month)=2023 AND month(month)<4
GROUP BY d.dist_code,d.district
),
y AS
(SELECT d.dist_code,d.district,SUM(fuel_type_petrol+fuel_type_diesel+fuel_type_electric) AS sales_2022
FROM fact_transport ft
JOIN dim_districts d ON ft.dist_code=d.dist_code
WHERE YEAR(month) = 2022 AND  month(month)>=4 OR YEAR(month)=2023 AND month(month)<4
GROUP BY d.dist_code,d.district
)
SELECT x.district, x.sales_2021, y.sales_2022,ROUND(((sales_2022-sales_2021)/sales_2021)*100,2) AS vehicle_sales_growth_pct
FROM x
JOIN y ON x.dist_code=y.dist_code
ORDER BY vehicle_sales_growth_pct DESC;

-- Ts-Ipass (Telangana State Industrial Project Approval and Self Certification System)
/* 8. List down the top 5 sectors that have witnessed the most significant investments in FY 2022.*/
SELECT sector, ROUND(SUM(investment_cr),2) AS i_cr
FROM fact_ts_ipass
WHERE SUBSTRING(month,7, 4) = 2022 AND  SUBSTRING(month,4,2)>=4 OR SUBSTRING(month,7,4)=2023 AND SUBSTRING(month,4,2)<4
GROUP BY sector
ORDER BY i_cr DESC
LIMIT 5;

/*9. List down the top 3 districts that have attracted the most significant sector investments during FY 2019 to 2022?
What factors could have led to the substantial investments in these particular districts?*/
SELECT d.dist_code,d.district,
ROUND(SUM(CASE WHEN dd.fiscal_year = 2019 THEN investment_cr ELSE 0 END),2) AS Year_2019,
ROUND(SUM(CASE WHEN dd.fiscal_year = 2020 THEN investment_cr ELSE 0 END),2) AS Year_2020,
ROUND(SUM(CASE WHEN dd.fiscal_year = 2021 THEN investment_cr ELSE 0 END),2) AS Year_2021,
ROUND(SUM(CASE WHEN dd.fiscal_year = 2022 THEN investment_cr ELSE 0 END),2) AS Year_2022,
ROUND(SUM(investment_cr),2) AS total_investment
FROM dim_districts d 
JOIN fact_ts_ipass fti ON d.dist_code=fti.dist_code
JOIN dim_date dd ON STR_TO_DATE(fti.month, '%d-%m-%Y')=dd.month
GROUP BY d.dist_code,d.district
ORDER BY 7 DESC
LIMIT 3;

/* 10. Is there any relationship between district investments, vehicles sales and stamps revenue within the same district between FY 2021
and 2022?*/
WITH x AS
(SELECT d.dist_code,d.district,SUM(fs.estamps_challans_rev) AS dist_stamps_revenue
FROM dim_districts d
JOIN fact_stamps fs ON d.dist_code=fs.dist_code
JOIN dim_date dd ON fs.month=dd.month
WHERE dd.fiscal_year=2021
GROUP BY d.dist_code,d.district),
y AS
(SELECT d.dist_code,d.district,ROUND(SUM(fti.investment_cr),2) AS district_investment
FROM dim_districts d
JOIN fact_ts_ipass fti ON d.dist_code=fti.dist_code
WHERE SUBSTRING(fti.month,7, 4) = 2021 AND  SUBSTRING(fti.month,4,2)>=4 OR SUBSTRING(fti.month,7,4)=2022 AND SUBSTRING(fti.month,4,2)<4
GROUP BY d.dist_code,d.district),
z AS
(SELECT d.dist_code,d.district,SUM(ft.fuel_type_petrol+ft.fuel_type_diesel+ft.fuel_type_electric+ft.fuel_type_others)
AS dist_vehicle_sales
FROM dim_districts d
JOIN fact_transport ft ON d.dist_code=ft.dist_code
JOIN dim_date dd ON ft.month=dd.month
WHERE dd.fiscal_year=2021
GROUP BY d.dist_code,d.district)
SELECT d.dist_code,d.district, dist_stamps_revenue,dist_vehicle_sales,district_investment
FROM dim_districts d
JOIN x ON d.dist_code=x.dist_code
JOIN y ON d.dist_code=y.dist_code
JOIN z ON d.dist_code=z.dist_code;

/* 11. Are there any particular sectors that have shown substantial
investment in multiple districts between FY 2021 and 2022?*/
SELECT d.district,sector,ROUND(SUM(investment_cr),2) AS substantial_investment
FROM dim_districts d
JOIN fact_ts_ipass fti ON d.dist_code=fti.dist_code
JOIN dim_date dd ON STR_TO_DATE(fti.month, '%d-%m-%Y')=dd.month
WHERE fiscal_year IN (2021,2022)
GROUP BY 1,2
ORDER BY 1,3 DESC;

/* 12. Can we identify any seasonal patterns or cyclicality in the
investment trends for specific sectors? Do certain sectors
experience higher investments during particular months?*/
SELECT sector,
ROUND(SUM(CASE WHEN MONTH(STR_TO_DATE(month, '%d-%m-%Y')) = 1 THEN investment_cr ELSE 0 END),2) AS January,
ROUND(SUM(CASE WHEN MONTH(STR_TO_DATE(month, '%d-%m-%Y')) = 2 THEN investment_cr ELSE 0 END),2) AS February,
ROUND(SUM(CASE WHEN MONTH(STR_TO_DATE(month, '%d-%m-%Y')) = 3 THEN investment_cr ELSE 0 END),2) AS March,
ROUND(SUM(CASE WHEN MONTH(STR_TO_DATE(month, '%d-%m-%Y')) = 4 THEN investment_cr ELSE 0 END),2) AS April,
ROUND(SUM(CASE WHEN MONTH(STR_TO_DATE(month, '%d-%m-%Y')) = 5 THEN investment_cr ELSE 0 END),2) AS May,
ROUND(SUM(CASE WHEN MONTH(STR_TO_DATE(month, '%d-%m-%Y')) = 6 THEN investment_cr ELSE 0 END),2) AS June,
ROUND(SUM(CASE WHEN MONTH(STR_TO_DATE(month, '%d-%m-%Y')) = 7 THEN investment_cr ELSE 0 END),2) AS July,
ROUND(SUM(CASE WHEN MONTH(STR_TO_DATE(month, '%d-%m-%Y')) = 8 THEN investment_cr ELSE 0 END),2) AS August,
ROUND(SUM(CASE WHEN MONTH(STR_TO_DATE(month, '%d-%m-%Y')) = 9 THEN investment_cr ELSE 0 END),2) AS September,
ROUND(SUM(CASE WHEN MONTH(STR_TO_DATE(month, '%d-%m-%Y')) = 10 THEN investment_cr ELSE 0 END),2) AS October,
ROUND(SUM(CASE WHEN MONTH(STR_TO_DATE(month, '%d-%m-%Y')) = 11 THEN investment_cr ELSE 0 END),2) AS November,
ROUND(SUM(CASE WHEN MONTH(STR_TO_DATE(month, '%d-%m-%Y')) = 12 THEN investment_cr ELSE 0 END),2) AS December
FROM fact_ts_ipass fti
GROUP BY sector;

-- Secondary Questions
/* 13. What are the top 5 districts to buy commercial properties in Telangana? Justify your answer.*/
-- This question can be answered by determining the purchasing power of each district and the investment made in that district.
SELECT d.dist_code,d.district, SUM(Brand_new_vehicles)
FROM dim_districts d
JOIN fact_transport ft ON d.dist_code=ft.dist_code
JOIN dim_date dd ON ft.month=dd.month
WHERE fiscal_year IN (2021,2022,2023)
GROUP BY d.dist_code,d.district
ORDER BY 3 DESC
LIMIT 5;
SELECT d.dist_code,d.district, ROUND(SUM(investment_cr),2) AS investment
FROM dim_districts d
JOIN fact_ts_ipass fti ON d.dist_code=fti.dist_code
JOIN dim_date dd ON STR_TO_DATE(fti.month, '%d-%m-%Y')=dd.month
WHERE fiscal_year IN (2019,2020,2021,2022)
GROUP BY d.dist_code,d.district
ORDER BY 3 DESC
LIMIT 5;

/* 14.What significant policies or initiatives were put into effect to enhance economic growth, investments, and employment in 
Telangana by the current government?Can we quantify the impact of these policies using available data?*/
SELECT sector,
ROUND(SUM(CASE WHEN dd.fiscal_year = 2019 THEN investment_cr ELSE 0 END),2) AS Year_2019,
ROUND(SUM(CASE WHEN dd.fiscal_year = 2020 THEN investment_cr ELSE 0 END),2) AS Year_2020,
ROUND(SUM(CASE WHEN dd.fiscal_year = 2021 THEN investment_cr ELSE 0 END),2) AS Year_2021,
ROUND(SUM(CASE WHEN dd.fiscal_year = 2022 THEN investment_cr ELSE 0 END),2) AS Year_2022,
ROUND(SUM(investment_cr),2) AS total_investment
FROM  fact_ts_ipass fti
JOIN dim_date dd ON STR_TO_DATE(fti.month, '%d-%m-%Y')=dd.month
GROUP BY sector
ORDER BY 6 DESC;




