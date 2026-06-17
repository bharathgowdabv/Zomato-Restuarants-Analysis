--#1.  Neighbourhood Overview
SELECT
    location,
    COUNT(*) AS total_restaurants,
    ROUND(AVG(CAST(rating AS FLOAT)), 2) AS avg_rating,
    ROUND(AVG(CAST(cost_for_two AS FLOAT)), 0) AS avg_cost_for_two,
    ROUND(AVG(CAST(votes AS FLOAT)), 0) AS avg_votes,
    SUM(CASE WHEN online_order = 'Yes' THEN 1 ELSE 0 END) AS online_order_count,
    ROUND(100 * (CAST(SUM(CASE WHEN online_order = 'Yes' THEN 1 ELSE 0 END) AS FLOAT)/ COUNT(*)), 2) AS pct_online_order,
    SUM(CASE WHEN book_table = 'Yes' THEN 1 ELSE 0 END)    AS book_table_count,
    ROUND(100 * (CAST(SUM(CASE WHEN book_table = 'Yes' THEN 1 ELSE 0 END) AS FLOAT)/ COUNT(*)), 2) AS pct_book_table
FROM zomato_clean
WHERE rating       IS NOT NULL
  AND cost_for_two IS NOT NULL
GROUP BY location
HAVING COUNT(*) > 50
ORDER BY total_restaurants DESC;

--#2. Value for Money Score by Neighbourhood
WITH location_stats AS (
    SELECT
        location,
        COUNT(*) AS total_restaurants,
        ROUND(AVG(CAST(rating AS FLOAT)), 2) AS avg_rating,
        ROUND(AVG(CAST(cost_for_two AS FLOAT)), 0) AS avg_cost,
        ROUND(AVG(CAST(votes AS FLOAT)), 0) AS avg_votes
    FROM zomato_clean
	    WHERE rating       IS NOT NULL
      AND cost_for_two IS NOT NULL
    GROUP BY location
    HAVING COUNT(*) > 50
)
SELECT
    location,
    total_restaurants,
    avg_rating,
    avg_cost,
    avg_votes,

    -- Value Score: higher rating at lower cost = better value
    ROUND(avg_rating / (avg_cost / 1000), 3) AS value_score,

    -- Rankings
    RANK() OVER (ORDER BY avg_rating DESC) AS rating_rank,
    RANK() OVER (ORDER BY avg_cost ASC) AS affordability_rank,
    RANK() OVER (ORDER BY avg_rating /(avg_cost / 1000) DESC) AS value_rank,

    -- Cost category
    CASE
        WHEN avg_cost < 300  THEN 'Budget'
        WHEN avg_cost < 600  THEN 'Mid-Range'
        WHEN avg_cost < 1000 THEN 'Premium'
        ELSE 'Luxury'
    END  AS cost_category

FROM location_stats
ORDER BY value_rank;

--#3. Restaurant Type Performance- Which type of restaurant delivers the best experience?
SELECT
    restuarant_type,
    COUNT(*) AS total_restaurants,
    ROUND(AVG(CAST(rating AS FLOAT)), 2) AS avg_rating,
    ROUND(AVG(CAST(cost_for_two AS FLOAT)), 0) AS avg_cost,
    ROUND(AVG(CAST(votes AS FLOAT)), 0) AS avg_votes,
    SUM(CASE WHEN online_order = 'Yes' THEN 1 ELSE 0 END)  AS online_order_count,
    ROUND(100 * (CAST(SUM(CASE WHEN online_order = 'Yes' THEN 1 ELSE 0 END) AS FLOAT)/ COUNT(*)), 2) AS pct_online_order,
    ROUND(100 * (CAST(SUM(CASE WHEN book_table = 'Yes' THEN 1 ELSE 0 END)AS FLOAT)/ COUNT(*)), 1) AS pct_book_table
FROM zomato_clean
WHERE rating   IS NOT NULL
  AND restuarant_type IS NOT NULL
GROUP BY restuarant_type
HAVING COUNT(*) > 30
ORDER BY avg_rating DESC;

--#4. Cuisine Performance Analysis- Which cuisines are most loved in Bengaluru?
SELECT TOP 20
    primary_cuisine,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(CAST(rating AS FLOAT)), 2) AS avg_rating,
    ROUND(AVG(CAST(cost_for_two AS FLOAT)), 0) AS avg_cost,
    SUM(votes)                                             AS total_votes,
    ROUND(AVG(CAST(votes AS FLOAT)), 0)                    AS avg_votes_per_restaurant,
    -- Popularity score: rating weighted by votes
    ROUND(AVG(CAST(rating AS FLOAT)) * LOG(AVG(CAST(votes AS FLOAT)) + 1), 2) AS popularity_score
FROM zomato_clean
WHERE rating          IS NOT NULL
  AND primary_cuisine IS NOT NULL
GROUP BY primary_cuisine
HAVING COUNT(*) > 30
ORDER BY popularity_score DESC;

--#5. Online Order & Table Booking Impact- Does offering these features affect ratings and popularity?
SELECT
    online_order,
    book_table,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(CAST(rating AS FLOAT)), 2) AS avg_rating,
    ROUND(AVG(CAST(cost_for_two AS FLOAT)), 0) AS avg_cost,
    ROUND(AVG(CAST(votes AS FLOAT)), 0) AS avg_votes,

    -- What % of these restaurants are in premium locations
    ROUND(100 * (CAST(SUM(CASE WHEN location IN ('Koramangala 5th Block', 'Indiranagar','MG Road', 'Brigade Road', 'Lavelle Road')
	THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*)), 2)AS pct_in_premium_areas

FROM zomato_clean
WHERE rating IS NOT NULL
GROUP BY online_order, book_table
ORDER BY online_order, book_table;

--#6. Location vs Cuisine Heatmap Data
SELECT
    location,
    primary_cuisine,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(CAST(rating AS FLOAT)), 2) AS avg_rating,
    ROUND(AVG(CAST(cost_for_two AS FLOAT)), 0) AS avg_cost
FROM zomato_clean
WHERE rating          IS NOT NULL
  AND primary_cuisine IS NOT NULL
  AND cost_for_two    IS NOT NULL
GROUP BY location, primary_cuisine
HAVING COUNT(*) > 5
ORDER BY location, avg_rating DESC;

--#7. The top 5 restaurants in each neighbourhood
WITH ranked_restaurants AS (
    SELECT
        name,
        location,
        primary_cuisine,
        restuarant_type,
        rating,
        votes,
        cost_for_two,
        online_order,
        book_table,
        RANK() OVER (PARTITION BY location ORDER BY rating DESC, votes DESC) AS rank_in_location
    FROM zomato_clean
    WHERE rating IS NOT NULL
      AND votes IS NOT NULL
      AND cost_for_two IS NOT NULL
)
SELECT *
FROM ranked_restaurants
WHERE rank_in_location <= 5
ORDER BY location, rank_in_location;

--#8.  Market Gap Analysis
WITH neighbourhood_cuisine AS (
    SELECT
        location,
        primary_cuisine,
        COUNT(*) AS restaurant_count,
        ROUND(AVG(CAST(rating AS FLOAT)), 2) AS avg_rating,
        ROUND(AVG(CAST(votes AS FLOAT)), 0) AS avg_demand
    FROM zomato_clean
    WHERE rating          IS NOT NULL
      AND primary_cuisine IS NOT NULL
    GROUP BY location, primary_cuisine
),
city_cuisine_avg AS (
    SELECT
        primary_cuisine,
        ROUND(AVG(CAST(restaurant_count AS FLOAT)), 0) AS city_avg_count,
        ROUND(AVG(CAST(avg_rating AS FLOAT)), 2) AS city_avg_rating
    FROM neighbourhood_cuisine
    GROUP BY primary_cuisine
)
SELECT
    n.location,
    n.primary_cuisine,
    n.restaurant_count,
    n.avg_rating,
    n.avg_demand,
    c.city_avg_count,
    c.city_avg_rating,

    -- Gap flag: high demand, low supply vs rest of city
    CASE WHEN n.avg_demand    > c.city_avg_rating * 100 AND n.restaurant_count < c.city_avg_count THEN 'OPPORTUNITY — High Demand, Low Supply'
         WHEN n.avg_rating    > c.city_avg_rating  AND n.restaurant_count < c.city_avg_count THEN 'OPPORTUNITY — High Rating, Underrepresented'
         WHEN n.restaurant_count > c.city_avg_count * 2 THEN 'SATURATED — Too Many Competitors'
         ELSE 'NORMAL'
    END AS market_signal

FROM neighbourhood_cuisine AS n
JOIN city_cuisine_avg AS c 
ON n.primary_cuisine = c.primary_cuisine
WHERE n.restaurant_count > 3
ORDER BY market_signal, n.location;

--#9. Cost Segmentation Analysis- How is Bengaluru's restaurant market distributed across price points?
WITH cost_segments AS (
    SELECT
        name,
        location,
        primary_cuisine,
        restuarant_type,
        rating,
        votes,
		online_order,
        cost_for_two,
        CASE
            WHEN cost_for_two <  300  THEN 'Budget'
            WHEN cost_for_two <  600  THEN 'Mid-Range'
            WHEN cost_for_two <  1000 THEN 'Premium'
            WHEN cost_for_two >= 1000 THEN 'Luxury'
        END                          AS price_segment
    FROM zomato_clean
    WHERE cost_for_two IS NOT NULL
      AND rating       IS NOT NULL
)
SELECT
    price_segment,
    COUNT(*) AS total_restaurants,
    ROUND( 100 * (CAST(COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER ()), 2) AS pct_of_market,
    ROUND(AVG(CAST(rating AS FLOAT)), 2) AS avg_rating,
    ROUND(AVG(CAST(votes  AS FLOAT)), 0) AS avg_votes,
    COUNT(DISTINCT location) AS neighbourhoods_present,
    COUNT(DISTINCT primary_cuisine) AS cuisines_present,
    SUM(CASE WHEN online_order = 'Yes' THEN 1 ELSE 0 END)  AS online_order_count,
    ROUND( 100 * (CAST(SUM(CASE WHEN online_order = 'Yes' THEN 1 ELSE 0 END) AS FLOAT)/ COUNT(*)), 2) AS pct_online_order
FROM cost_segments
GROUP BY price_segment
ORDER BY price_segment;

--#10. Rating Distribution Analysis
WITH rating_buckets AS (
    SELECT
        name,
        location,
        rating,
        CASE
            WHEN rating >= 4.5 THEN 'Excellent'
            WHEN rating >= 4.0 THEN 'Very Good'
            WHEN rating >= 3.5 THEN 'Good'
            WHEN rating >= 3.0 THEN 'Average'
            ELSE 'Below Average'
        END  AS rating_bucket
    FROM zomato_clean
    WHERE rating IS NOT NULL
)
SELECT
    rating_bucket,
    COUNT(*) AS restaurant_count,
    ROUND(100.0 * (CAST(COUNT(*) AS FLOAT)/ SUM(COUNT(*)) OVER ()), 2) AS pct_of_total,
    COUNT(DISTINCT location) AS neighbourhoods,
    -- Running total
    SUM(COUNT(*)) OVER (ORDER BY rating_bucket ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM rating_buckets
GROUP BY rating_bucket
ORDER BY rating_bucket;

--#11. Neighbourhood Specialisation Index- Which neighbourhoods are known for specific cuisines?
WITH neighbourhood_cuisine AS (
    SELECT
        location,
        primary_cuisine,
        COUNT(*) AS cuisine_count
    FROM zomato_clean
    WHERE primary_cuisine IS NOT NULL
    GROUP BY location, primary_cuisine
),
neighbourhood_total AS (
    SELECT
        location,
        COUNT(*) AS total_restaurants
    FROM zomato_clean
    GROUP BY location
),
city_cuisine_share AS (
    SELECT
        primary_cuisine,
        COUNT(*) AS city_total,
        ROUND(100 * (CAST(COUNT(*) AS FLOAT)/ SUM(COUNT(*)) OVER ()), 2) AS city_pct
    FROM zomato_clean
    WHERE primary_cuisine IS NOT NULL
    GROUP BY primary_cuisine
)
SELECT
    nc.location,
    nc.primary_cuisine,
    nc.cuisine_count,
    nt.total_restaurants,
    ROUND(100 * (CAST(nc.cuisine_count AS FLOAT)/ nt.total_restaurants), 2) AS local_pct,
    cc.city_pct AS city_pct,
    -- Specialisation Index: how overrepresented is this cuisine locally vs city?
    ROUND((100.0 * nc.cuisine_count / nt.total_restaurants)/ NULLIF(cc.city_pct, 0), 2) AS specialisation_index
FROM neighbourhood_cuisine AS nc
JOIN neighbourhood_total AS nt 
ON nc.location = nt.location
JOIN city_cuisine_share AS cc 
ON nc.primary_cuisine = cc.primary_cuisine
WHERE nt.total_restaurants > 50
  AND nc.cuisine_count > 5
  AND cc.city_pct > 0.5   -- Only meaningful cuisines
ORDER BY specialisation_index DESC;

--#12. Competitor Density vs Quality- Is higher competition linked to better or worse quality?
WITH location_stats AS (
    SELECT
        location,
        COUNT(*) AS total_restaurants,
        ROUND(AVG(CAST(rating AS FLOAT)), 2) AS avg_rating,
        ROUND(AVG(CAST(votes  AS FLOAT)), 0) AS avg_votes,
        ROUND(AVG(CAST(cost_for_two AS FLOAT)), 0) AS avg_cost
    FROM zomato_clean
    WHERE rating IS NOT NULL
      AND cost_for_two IS NOT NULL
    GROUP BY location
    HAVING COUNT(*) > 50
)
SELECT
    location,
    total_restaurants,
    avg_rating,
    avg_votes,
    avg_cost,
    -- Competition tier
    CASE
        WHEN total_restaurants >= 1000 THEN 'Very High'
        WHEN total_restaurants >=  500 THEN 'High'
        WHEN total_restaurants >=  200 THEN 'Medium'
        ELSE 'Low'
    END AS competition_tier,

    -- Is this area punching above its weight?
    CASE
        WHEN avg_rating > AVG(avg_rating) OVER () AND total_restaurants > AVG(CAST(total_restaurants AS FLOAT)) OVER () THEN 'High Competition + High Quality'
        WHEN avg_rating > AVG(avg_rating) OVER () AND total_restaurants < AVG(CAST(total_restaurants AS FLOAT)) OVER () THEN 'Low Competition + High Quality — Hidden Gem'
        WHEN avg_rating < AVG(avg_rating) OVER () AND total_restaurants > AVG(CAST(total_restaurants AS FLOAT)) OVER () THEN 'High Competition + Low Quality — Saturated'
        ELSE 'Low Competition + Low Quality — Underdeveloped'
    END AS market_quadrant

FROM location_stats
ORDER BY total_restaurants DESC;

--#13. Listed Type Performance- Delivery vs Dine-out vs Buffet — which experience wins?
SELECT
    listed_type,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(CAST(rating AS FLOAT)), 2) AS avg_rating,
    ROUND(AVG(CAST(cost_for_two AS FLOAT)), 0) AS avg_cost,
    ROUND(AVG(CAST(votes  AS FLOAT)), 0) AS avg_votes,
    ROUND( 100 * (CAST(SUM(CASE WHEN online_order = 'Yes' THEN 1 ELSE 0 END) AS FLOAT)  / COUNT(*)), 2) AS pct_online_order,
    ROUND( 100 * (CAST(SUM(CASE WHEN book_table = 'Yes' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*)), 2) AS pct_book_table, 
    -- Rating rank across all listed types
    RANK() OVER (ORDER BY AVG(CAST(rating AS FLOAT)) DESC) AS rating_rank,
    RANK() OVER (ORDER BY AVG(CAST(votes  AS FLOAT)) DESC) AS popularity_rank

FROM zomato_clean
WHERE rating      IS NOT NULL
  AND listed_type IS NOT NULL
GROUP BY listed_type
ORDER BY avg_rating DESC;

--#14. Votes Percentile Ranking- Separate truly popular restaurants from the rest.
WITH votes_percentile AS (
    SELECT
        name,
        location,
        primary_cuisine,
        restuarant_type,
        rating,
        votes,
        cost_for_two,
        NTILE(4) OVER (ORDER BY votes DESC)                AS votes_quartile,
        NTILE(10) OVER (ORDER BY votes DESC)               AS votes_decile,
        PERCENT_RANK() OVER (ORDER BY votes)               AS votes_percentile
    FROM zomato_clean
    WHERE votes IS NOT NULL
      AND rating IS NOT NULL
)
SELECT
    CASE votes_quartile
        WHEN 1 THEN 'Top 25% — Most Reviewed'
        WHEN 2 THEN 'Upper Middle 25%'
        WHEN 3 THEN 'Lower Middle 25%'
        WHEN 4 THEN 'Bottom 25% — Least Reviewed'
    END                                                    AS popularity_tier,
    COUNT(*)                                               AS restaurant_count,
    ROUND(AVG(CAST(rating       AS FLOAT)), 2)             AS avg_rating,
    ROUND(AVG(CAST(votes        AS FLOAT)), 0)             AS avg_votes,
    ROUND(AVG(CAST(cost_for_two AS FLOAT)), 0)             AS avg_cost,
    MIN(votes)                                             AS min_votes,
    MAX(votes)                                             AS max_votes
FROM votes_percentile
GROUP BY votes_quartile
ORDER BY votes_quartile;

--#15.Executive Summary Numbers
SELECT
    -- Scale
    COUNT(*) AS total_restaurants,
    COUNT(DISTINCT location) AS total_neighbourhoods,
    COUNT(DISTINCT primary_cuisine) AS total_cuisines,
    COUNT(DISTINCT restuarant_type) AS total_rest_types,

    -- Ratings
    ROUND(AVG(CAST(rating AS FLOAT)), 2) AS city_avg_rating,
    MIN(rating) AS lowest_rating,
    MAX(rating) AS highest_rating,
    SUM(CASE WHEN rating >= 4.0 THEN 1 ELSE 0 END) AS restaurants_above_4,
    ROUND( 100 * (SUM(CASE WHEN rating >= 4.0 THEN 1 ELSE 0 END) / COUNT(rating)), 1) AS pct_above_4_rating,

    -- Cost
    ROUND(AVG(CAST(cost_for_two AS FLOAT)), 0) AS city_avg_cost,
    MIN(cost_for_two) AS cheapest,
    MAX(cost_for_two) AS most_expensive,

    -- Features
    ROUND( 100 * (CAST(SUM(CASE WHEN online_order = 'Yes' THEN 1 ELSE 0 END) AS FLOAT)  / COUNT(*)), 2) AS pct_online_order,
    ROUND( 100 * (CAST(SUM(CASE WHEN book_table = 'Yes' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*)), 2) AS pct_book_table,
    ROUND( 100 * (CAST(SUM(CASE WHEN online_order = 'Yes' AND book_table   = 'Yes' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*)), 2) AS pct_both_features

FROM zomato_clean
WHERE rating       IS NOT NULL
  AND cost_for_two IS NOT NULL;