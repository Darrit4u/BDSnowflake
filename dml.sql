TRUNCATE TABLE
    fact_sales,
    dim_product,
    dim_supplier,
    dim_store,
    dim_seller,
    dim_customer,
    dim_customer_pet,
    dim_location,
    dim_date,
    dim_product_category,
    dim_pet_category,
    dim_pet_type,
    dim_pet_breed,
    dim_product_brand,
    dim_product_color,
    dim_product_size,
    dim_product_material,
    dim_country
RESTART IDENTITY CASCADE;

INSERT INTO dim_country (country_name)
SELECT DISTINCT country_name
FROM (
    SELECT NULLIF(TRIM(customer_country::text), '') AS country_name FROM mock_data
    UNION
    SELECT NULLIF(TRIM(seller_country::text), '') FROM mock_data
    UNION
    SELECT NULLIF(TRIM(store_country::text), '') FROM mock_data
    UNION
    SELECT NULLIF(TRIM(supplier_country::text), '') FROM mock_data
) countries
WHERE country_name IS NOT NULL;

INSERT INTO dim_date (full_date, year, quarter, month, month_name, day, day_of_week)
SELECT DISTINCT
    full_date,
    EXTRACT(YEAR FROM full_date)::integer AS year,
    EXTRACT(QUARTER FROM full_date)::integer AS quarter,
    EXTRACT(MONTH FROM full_date)::integer AS month,
    TO_CHAR(full_date, 'TMMonth') AS month_name,
    EXTRACT(DAY FROM full_date)::integer AS day,
    EXTRACT(ISODOW FROM full_date)::integer AS day_of_week
FROM (
    SELECT sale_date::date AS full_date
    FROM mock_data
    WHERE NULLIF(TRIM(sale_date::text), '') IS NOT NULL

    UNION

    SELECT product_release_date::date
    FROM mock_data
    WHERE NULLIF(TRIM(product_release_date::text), '') IS NOT NULL

    UNION

    SELECT product_expiry_date::date
    FROM mock_data
    WHERE NULLIF(TRIM(product_expiry_date::text), '') IS NOT NULL
) dates;

INSERT INTO dim_location (
    country_key,
    city,
    state,
    postal_code,
    address,
    location_details
)
SELECT DISTINCT
    c.country_key,
    loc.city,
    loc.state,
    loc.postal_code,
    loc.address,
    loc.location_details
FROM (
    SELECT
        NULLIF(TRIM(customer_country::text), '') AS country_name,
        NULL::text AS city,
        NULL::text AS state,
        NULLIF(TRIM(customer_postal_code::text), '') AS postal_code,
        NULL::text AS address,
        NULL::text AS location_details
    FROM mock_data

    UNION

    SELECT
        NULLIF(TRIM(seller_country::text), ''),
        NULL::text,
        NULL::text,
        NULLIF(TRIM(seller_postal_code::text), ''),
        NULL::text,
        NULL::text
    FROM mock_data

    UNION

    SELECT
        NULLIF(TRIM(store_country::text), ''),
        NULLIF(TRIM(store_city::text), ''),
        NULLIF(TRIM(store_state::text), ''),
        NULL::text,
        NULL::text,
        NULLIF(TRIM(store_location::text), '')
    FROM mock_data

    UNION

    SELECT
        NULLIF(TRIM(supplier_country::text), ''),
        NULLIF(TRIM(supplier_city::text), ''),
        NULL::text,
        NULL::text,
        NULLIF(TRIM(supplier_address::text), ''),
        NULL::text
    FROM mock_data
) loc
LEFT JOIN dim_country c
    ON c.country_name = loc.country_name
WHERE
    loc.country_name IS NOT NULL
    OR loc.city IS NOT NULL
    OR loc.state IS NOT NULL
    OR loc.postal_code IS NOT NULL
    OR loc.address IS NOT NULL
    OR loc.location_details IS NOT NULL;

INSERT INTO dim_pet_type (pet_type_name)
SELECT DISTINCT NULLIF(TRIM(customer_pet_type::text), '') AS pet_type_name
FROM mock_data
WHERE NULLIF(TRIM(customer_pet_type::text), '') IS NOT NULL;

INSERT INTO dim_pet_breed (pet_breed_name)
SELECT DISTINCT NULLIF(TRIM(customer_pet_breed::text), '') AS pet_breed_name
FROM mock_data
WHERE NULLIF(TRIM(customer_pet_breed::text), '') IS NOT NULL;

INSERT INTO dim_customer_pet (pet_name, pet_type_key, pet_breed_key)
SELECT DISTINCT
    NULLIF(TRIM(m.customer_pet_name::text), '') AS pet_name,
    pt.pet_type_key,
    pb.pet_breed_key
FROM mock_data m
LEFT JOIN dim_pet_type pt
    ON pt.pet_type_name = NULLIF(TRIM(m.customer_pet_type::text), '')
LEFT JOIN dim_pet_breed pb
    ON pb.pet_breed_name = NULLIF(TRIM(m.customer_pet_breed::text), '')
WHERE
    NULLIF(TRIM(m.customer_pet_name::text), '') IS NOT NULL
    OR pt.pet_type_key IS NOT NULL
    OR pb.pet_breed_key IS NOT NULL;

INSERT INTO dim_product_category (product_category_name)
SELECT DISTINCT NULLIF(TRIM(product_category::text), '') AS product_category_name
FROM mock_data
WHERE NULLIF(TRIM(product_category::text), '') IS NOT NULL;

INSERT INTO dim_pet_category (pet_category_name)
SELECT DISTINCT NULLIF(TRIM(pet_category::text), '') AS pet_category_name
FROM mock_data
WHERE NULLIF(TRIM(pet_category::text), '') IS NOT NULL;

INSERT INTO dim_product_brand (brand_name)
SELECT DISTINCT NULLIF(TRIM(product_brand::text), '') AS brand_name
FROM mock_data
WHERE NULLIF(TRIM(product_brand::text), '') IS NOT NULL;

INSERT INTO dim_product_color (color_name)
SELECT DISTINCT NULLIF(TRIM(product_color::text), '') AS color_name
FROM mock_data
WHERE NULLIF(TRIM(product_color::text), '') IS NOT NULL;

INSERT INTO dim_product_size (size_name)
SELECT DISTINCT NULLIF(TRIM(product_size::text), '') AS size_name
FROM mock_data
WHERE NULLIF(TRIM(product_size::text), '') IS NOT NULL;

INSERT INTO dim_product_material (material_name)
SELECT DISTINCT NULLIF(TRIM(product_material::text), '') AS material_name
FROM mock_data
WHERE NULLIF(TRIM(product_material::text), '') IS NOT NULL;

INSERT INTO dim_customer (
    source_customer_id,
    first_name,
    last_name,
    age,
    email,
    location_key,
    customer_pet_key
)
SELECT DISTINCT
    NULLIF(TRIM(m.sale_customer_id::text), '')::integer AS source_customer_id,
    NULLIF(TRIM(m.customer_first_name::text), '') AS first_name,
    NULLIF(TRIM(m.customer_last_name::text), '') AS last_name,
    NULLIF(TRIM(m.customer_age::text), '')::integer AS age,
    NULLIF(TRIM(m.customer_email::text), '') AS email,
    l.location_key,
    cp.customer_pet_key
FROM mock_data m
LEFT JOIN dim_country c
    ON c.country_name = NULLIF(TRIM(m.customer_country::text), '')
LEFT JOIN dim_location l
    ON l.country_key IS NOT DISTINCT FROM c.country_key
    AND l.city IS NULL
    AND l.state IS NULL
    AND l.postal_code IS NOT DISTINCT FROM NULLIF(TRIM(m.customer_postal_code::text), '')
    AND l.address IS NULL
    AND l.location_details IS NULL
LEFT JOIN dim_pet_type pt
    ON pt.pet_type_name = NULLIF(TRIM(m.customer_pet_type::text), '')
LEFT JOIN dim_pet_breed pb
    ON pb.pet_breed_name = NULLIF(TRIM(m.customer_pet_breed::text), '')
LEFT JOIN dim_customer_pet cp
    ON cp.pet_name IS NOT DISTINCT FROM NULLIF(TRIM(m.customer_pet_name::text), '')
    AND cp.pet_type_key IS NOT DISTINCT FROM pt.pet_type_key
    AND cp.pet_breed_key IS NOT DISTINCT FROM pb.pet_breed_key;

INSERT INTO dim_seller (
    source_seller_id,
    first_name,
    last_name,
    email,
    location_key
)
SELECT DISTINCT
    NULLIF(TRIM(m.sale_seller_id::text), '')::integer AS source_seller_id,
    NULLIF(TRIM(m.seller_first_name::text), '') AS first_name,
    NULLIF(TRIM(m.seller_last_name::text), '') AS last_name,
    NULLIF(TRIM(m.seller_email::text), '') AS email,
    l.location_key
FROM mock_data m
LEFT JOIN dim_country c
    ON c.country_name = NULLIF(TRIM(m.seller_country::text), '')
LEFT JOIN dim_location l
    ON l.country_key IS NOT DISTINCT FROM c.country_key
    AND l.city IS NULL
    AND l.state IS NULL
    AND l.postal_code IS NOT DISTINCT FROM NULLIF(TRIM(m.seller_postal_code::text), '')
    AND l.address IS NULL
    AND l.location_details IS NULL;

INSERT INTO dim_store (
    store_name,
    location_key,
    phone,
    email
)
SELECT DISTINCT
    NULLIF(TRIM(m.store_name::text), '') AS store_name,
    l.location_key,
    NULLIF(TRIM(m.store_phone::text), '') AS phone,
    NULLIF(TRIM(m.store_email::text), '') AS email
FROM mock_data m
LEFT JOIN dim_country c
    ON c.country_name = NULLIF(TRIM(m.store_country::text), '')
LEFT JOIN dim_location l
    ON l.country_key IS NOT DISTINCT FROM c.country_key
    AND l.city IS NOT DISTINCT FROM NULLIF(TRIM(m.store_city::text), '')
    AND l.state IS NOT DISTINCT FROM NULLIF(TRIM(m.store_state::text), '')
    AND l.postal_code IS NULL
    AND l.address IS NULL
    AND l.location_details IS NOT DISTINCT FROM NULLIF(TRIM(m.store_location::text), '');

INSERT INTO dim_supplier (
    supplier_name,
    contact,
    email,
    phone,
    location_key
)
SELECT DISTINCT
    NULLIF(TRIM(m.supplier_name::text), '') AS supplier_name,
    NULLIF(TRIM(m.supplier_contact::text), '') AS contact,
    NULLIF(TRIM(m.supplier_email::text), '') AS email,
    NULLIF(TRIM(m.supplier_phone::text), '') AS phone,
    l.location_key
FROM mock_data m
LEFT JOIN dim_country c
    ON c.country_name = NULLIF(TRIM(m.supplier_country::text), '')
LEFT JOIN dim_location l
    ON l.country_key IS NOT DISTINCT FROM c.country_key
    AND l.city IS NOT DISTINCT FROM NULLIF(TRIM(m.supplier_city::text), '')
    AND l.state IS NULL
    AND l.postal_code IS NULL
    AND l.address IS NOT DISTINCT FROM NULLIF(TRIM(m.supplier_address::text), '')
    AND l.location_details IS NULL;

INSERT INTO dim_product (
    source_product_id,
    product_name,
    product_price,
    product_quantity,
    product_weight,
    product_description,
    product_rating,
    product_reviews,
    release_date_key,
    expiry_date_key,
    product_category_key,
    pet_category_key,
    product_brand_key,
    product_color_key,
    product_size_key,
    product_material_key,
    supplier_key
)
SELECT DISTINCT
    NULLIF(TRIM(m.sale_product_id::text), '')::integer AS source_product_id,
    NULLIF(TRIM(m.product_name::text), '') AS product_name,
    NULLIF(TRIM(m.product_price::text), '')::numeric(12, 2) AS product_price,
    NULLIF(TRIM(m.product_quantity::text), '')::integer AS product_quantity,
    NULLIF(TRIM(m.product_weight::text), '')::numeric(12, 2) AS product_weight,
    NULLIF(TRIM(m.product_description::text), '') AS product_description,
    NULLIF(TRIM(m.product_rating::text), '')::numeric(3, 2) AS product_rating,
    NULLIF(TRIM(m.product_reviews::text), '')::integer AS product_reviews,
    rd.date_key AS release_date_key,
    ed.date_key AS expiry_date_key,
    pc.product_category_key,
    petc.pet_category_key,
    b.product_brand_key,
    col.product_color_key,
    sz.product_size_key,
    mat.product_material_key,
    s.supplier_key
FROM mock_data m
LEFT JOIN dim_date rd
    ON rd.full_date = m.product_release_date::date
LEFT JOIN dim_date ed
    ON ed.full_date = m.product_expiry_date::date
LEFT JOIN dim_product_category pc
    ON pc.product_category_name = NULLIF(TRIM(m.product_category::text), '')
LEFT JOIN dim_pet_category petc
    ON petc.pet_category_name = NULLIF(TRIM(m.pet_category::text), '')
LEFT JOIN dim_product_brand b
    ON b.brand_name = NULLIF(TRIM(m.product_brand::text), '')
LEFT JOIN dim_product_color col
    ON col.color_name = NULLIF(TRIM(m.product_color::text), '')
LEFT JOIN dim_product_size sz
    ON sz.size_name = NULLIF(TRIM(m.product_size::text), '')
LEFT JOIN dim_product_material mat
    ON mat.material_name = NULLIF(TRIM(m.product_material::text), '')
LEFT JOIN dim_supplier s
    ON s.supplier_name = NULLIF(TRIM(m.supplier_name::text), '')
    AND s.email IS NOT DISTINCT FROM NULLIF(TRIM(m.supplier_email::text), '');

INSERT INTO fact_sales (
    source_id,
    source_customer_id,
    source_seller_id,
    source_product_id,
    sale_date_key,
    customer_key,
    seller_key,
    store_key,
    product_key,
    sale_quantity,
    sale_total_price
)
SELECT
    NULLIF(TRIM(m.id::text), '')::integer AS source_id,
    NULLIF(TRIM(m.sale_customer_id::text), '')::integer AS source_customer_id,
    NULLIF(TRIM(m.sale_seller_id::text), '')::integer AS source_seller_id,
    NULLIF(TRIM(m.sale_product_id::text), '')::integer AS source_product_id,
    d.date_key AS sale_date_key,
    c.customer_key,
    sel.seller_key,
    st.store_key,
    p.product_key,
    NULLIF(TRIM(m.sale_quantity::text), '')::integer AS sale_quantity,
    NULLIF(TRIM(m.sale_total_price::text), '')::numeric(12, 2) AS sale_total_price
FROM mock_data m
JOIN dim_date d
    ON d.full_date = m.sale_date::date
JOIN dim_customer c
    ON c.email = NULLIF(TRIM(m.customer_email::text), '')
JOIN dim_seller sel
    ON sel.email = NULLIF(TRIM(m.seller_email::text), '')
JOIN dim_store st
    ON st.store_name = NULLIF(TRIM(m.store_name::text), '')
    AND st.email IS NOT DISTINCT FROM NULLIF(TRIM(m.store_email::text), '')
JOIN dim_product p
    ON p.product_name = NULLIF(TRIM(m.product_name::text), '')
    AND p.product_price IS NOT DISTINCT FROM NULLIF(TRIM(m.product_price::text), '')::numeric(12, 2)
    AND p.product_weight IS NOT DISTINCT FROM NULLIF(TRIM(m.product_weight::text), '')::numeric(12, 2)
    AND p.product_description IS NOT DISTINCT FROM NULLIF(TRIM(m.product_description::text), '')
    AND p.product_rating IS NOT DISTINCT FROM NULLIF(TRIM(m.product_rating::text), '')::numeric(3, 2)
    AND p.product_reviews IS NOT DISTINCT FROM NULLIF(TRIM(m.product_reviews::text), '')::integer
    AND p.source_product_id IS NOT DISTINCT FROM NULLIF(TRIM(m.sale_product_id::text), '')::integer;

