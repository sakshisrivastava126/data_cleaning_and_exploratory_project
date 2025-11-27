SELECT *
FROM layoffs;
-- 1. remove duplicates
-- 2. standrize the data
-- 3. remove null or blank values
-- 4. remove any columns


#######remove duplicates#############

CREATE TABLE layoffs_staging
LIKE layoffs;

-- inserting the data into layoffs_staging
INSERT INTO layoffs_staging
SELECT * FROM layoffs;

-- creating row_number column to see number of duplicates
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;

-- removing duplicates
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- creating another file for data to store original data
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- inserting the data
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
) AS row_num
FROM layoffs_staging;

SET SQL_SAFE_UPDATES = 0;

-- deleting the duplicates
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- checking the data again
SELECT *
FROM layoffs_staging2
;

#######Standarizing data###########

-- removing extra spaces from the company name
SELECT company, TRIM(company)
FROM layoffs_staging2
;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- checking all the industries and country
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1
;

-- removing extra dot from US everywhere in the country column
UPDATE layoffs_staging2
SET country = 'United States' 
WHERE country LIKE 'United States%'
;

-- checking all the countries again
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1
;

-- changing the date column format from text -> date
SELECT `date`,
str_to_date(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = str_to_date(`date`, '%m/%d/%Y');

-- changing the date definition from text -> date
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- deleting columns where there is no layoffs
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
;

-- checking data of airbnb it seems NULL in one row and travel in another in industry column gotta fix it 
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb'
;

-- cleaning the industry column by converting empty strings ("") into NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- identifing if missing industries can be filled from other records of the same company
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;

-- removing the row_num column we added
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2
;

##Exploratory Data Analysis

-- creating another table for analysis
CREATE TABLE layoffs_staging3 LIKE layoffs_staging2;

INSERT INTO layoffs_staging3
SELECT DISTINCT
    company,
    location,
    industry,
    total_laid_off,
    percentage_laid_off,
    `date`,
    stage,
    country,
    funds_raised_millions
FROM layoffs_staging2;

-- checking the count of data 
SELECT COUNT(*) FROM layoffs_staging2;
SELECT COUNT(*) FROM layoffs_staging3;

-- checking max and min lay offs
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging3
;

SELECT *
FROM layoffs_staging3
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC
;

-- checking data when lay offs were done
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging3;

-- analysing which countries did the most lay offs
SELECT country, SUM(total_laid_off)
FROM layoffs_staging3
GROUP BY country
ORDER BY 2 DESC
;

-- checking year when lay offs were done the most
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging3
GROUP BY YEAR(`date`)
ORDER BY 1 DESC
;

-- on the basis of month and year analyzing the data
SELECT SUBSTRING(`date`, 1,7) AS MONTH, SUM(total_laid_off)
FROM layoffs_staging3
WHERE SUBSTRING(`date`, 1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
;

-- creating a rolling total column to add up total lay offs with each passing year
WITH Rolling_Total AS 
(
SELECT SUBSTRING(`date`, 1,7) AS MONTH, SUM(total_laid_off) AS total_off
FROM layoffs_staging3
WHERE SUBSTRING(`date`, 1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)

SELECT `MONTH`,total_off,
SUM(total_off) OVER (ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total
;

SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging3
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC
;

-- ranking the companies on the basis of the lay offs 
WITH Company_year (company,year, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging3
GROUP BY company, YEAR(`date`)
), Company_year_ranking AS
(
SELECT *, DENSE_RANK() OVER (PARTITION BY year ORDER BY total_laid_off DESC) AS 'ranking'
FROM Company_year
WHERE year IS NOT NULL
ORDER BY 'ranking'
)
SELECT *
FROM Company_year_ranking
WHERE ranking <= 5
;
