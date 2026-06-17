TRUNCATE TABLE zomato_raw;

BULK INSERT zomato_raw
FROM 'E:\SQL projects\Zomato\Dataset\zomato.csv'
WITH (
    FORMAT       = 'CSV',        -- Handles quoted fields correctly
    FIELDQUOTE   = '"',          -- Treats double-quoted fields as single value
    FIRSTROW     = 2,            -- Skip header row
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    CODEPAGE        = '65001',   -- UTF-8 encoding for Indian restaurant names
    TABLOCK,
    KEEPNULLS                    -- Keep blank fields as NULL, not empty string
);