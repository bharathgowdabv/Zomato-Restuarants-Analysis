IF OBJECT_ID('zomato_raw','U') IS NOT NULL
DROP TABLE zomato_raw;

CREATE TABLE zomato_raw (
  url              NVARCHAR(MAX),
  address          NVARCHAR(MAX),
  name             NVARCHAR(MAX),
  online_order     NVARCHAR(MAX),
  book_table       NVARCHAR(MAX),
  rate             NVARCHAR(MAX),   
  votes            NVARCHAR(MAX),   
  phone            NVARCHAR(MAX),
  location         NVARCHAR(MAX),
  rest_type        NVARCHAR(MAX),
  dish_liked       NVARCHAR(MAX),
  cuisines         NVARCHAR(MAX),
  approx_cost      NVARCHAR(MAX),   
  reviews_list     NVARCHAR(MAX),
  menu_item        NVARCHAR(MAX),
  listed_type      NVARCHAR(MAX),
  listed_city      NVARCHAR(MAX)
);
