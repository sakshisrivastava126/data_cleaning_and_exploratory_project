# data_cleaning_and_exploratory_project
This project focuses on cleaning and analyzing a global layoffs dataset collected from various tech and non-tech companies. The goal was to transform the raw data into a structured and reliable format and then perform exploratory data analysis to understand layoff patterns across industries, countries, companies, and time.
here’s a clean, GitHub-ready project description (under 350 words, professional but still fresh and easy to read):


## 🔹 Data Cleaning Process

The raw dataset contained **duplicates, missing values, inconsistent formatting, and blank fields**. All cleaning was done using SQL.

Key steps:

* Created a staging table from the raw dataset
* Identified and removed **duplicate records**
* Standardized text fields (trimmed whitespaces, corrected country formats, standardized company and industry names)
* Converted **string dates to proper DATE format**
* Replaced blank values with **NULL**
* Filled missing industries using information from other rows of the **same company**
* Removed rows where both total_laid_off and percentage_laid_off were NULL
* Built a final cleaned table with **only one instance of every unique record**

Final row count confirmed the dataset was reduced from ~29,000 repeated entries to a clean dataset of ~490 unique rows.

## 🔹 Exploratory Data Analysis

Analysis was performed using SQL to uncover insights such as:

* **Maximum layoffs by a single company**
* **Companies with 100% workforce layoffs**
* **Highest layoffs by industry and country**
* **Year-wise and month-wise layoff trends**
* **Top companies most affected**

These queries help identify where layoffs were most severe and which sectors and time periods were impacted the most.

## 🔹 Tech Used

* SQL (MySQL)
* MySQL Workbench

## 🔹 What this project demonstrates

* Practical end-to-end SQL data cleaning
* Handling datasets with large duplicate counts
* Fixing missing values logically using relational joins
* Performing EDA purely through SQL queries
* Organizing cleaned data into a final usable table for further analytics
