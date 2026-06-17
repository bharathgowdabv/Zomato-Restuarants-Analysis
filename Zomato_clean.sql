
CREATE VIEW zomato_clean AS

SELECT 
	name,
	CASE 
        WHEN location IS NULL OR location = 'NULL' THEN 'UNKNOWN'
        WHEN CHARINDEX(',', location) > 0 
            THEN LTRIM(RTRIM(RIGHT(location, LEN(location) - CHARINDEX(',', location))))
      ELSE LTRIM(RTRIM(location))
    END AS location,
	CASE 
        WHEN rest_type IS NULL OR rest_type = 'NULL' THEN 'UNKNOWN'
        ELSE LTRIM(RTRIM(LEFT(rest_type, CHARINDEX(',', rest_type + ',') - 1)))
    END AS restuarant_type,
	CASE WHEN cuisines IS NULL OR cuisines = 'NULL' THEN 'UNKNOWN'
		 ELSE LTRIM(RTRIM(LEFT(cuisines, CHARINDEX(',', cuisines + ',') - 1))) 
	END AS primary_cuisine,
	cuisines AS all_Cuisines,
	listed_type,
	online_order,
	book_table,
	CASE WHEN rate IN ('NEW','-','NULL') THEN NULL
		 ELSE TRY_CAST(REPLACE(REPLACE(LTRIM(RTRIM(rate)), '/5', ''), ' ', '') AS FLOAT)
	END AS rating,
	TRY_CAST(NULLIF(REPLACE(LTRIM(RTRIM(votes)), ',', ''), '') AS INT) AS votes,
	TRY_CAST(NULLIF(REPLACE(LTRIM(RTRIM(approx_cost)), ',', ''), '') AS INT) AS cost_for_two
FROM zomato_raw

