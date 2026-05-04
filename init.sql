DROP TABLE IF EXISTS fact_sales;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_supplier;
DROP TABLE IF EXISTS dim_store;
DROP TABLE IF EXISTS dim_seller;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_customer_pet;
DROP TABLE IF EXISTS dim_location;
DROP TABLE IF EXISTS dim_date;
DROP TABLE IF EXISTS dim_product_category;
DROP TABLE IF EXISTS dim_pet_category;
DROP TABLE IF EXISTS dim_pet_type;
DROP TABLE IF EXISTS dim_pet_breed;
DROP TABLE IF EXISTS dim_product_brand;
DROP TABLE IF EXISTS dim_product_color;
DROP TABLE IF EXISTS dim_product_size;
DROP TABLE IF EXISTS dim_product_material;
DROP TABLE IF EXISTS dim_country;

CREATE TABLE dim_country (
    country_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_name varchar(255) NOT NULL UNIQUE
);

CREATE TABLE dim_location (
    location_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_key integer REFERENCES dim_country(country_key),
    city varchar(255),
    state varchar(255),
    postal_code varchar(64),
    address text,
    location_details text,

    UNIQUE (country_key, city, state, postal_code, address, location_details)
);

CREATE TABLE dim_date (
    date_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_date date NOT NULL UNIQUE,
    year integer NOT NULL,
    quarter integer NOT NULL CHECK (quarter BETWEEN 1 AND 4),
    month integer NOT NULL CHECK (month BETWEEN 1 AND 12),
    month_name varchar(20) NOT NULL,
    day integer NOT NULL CHECK (day BETWEEN 1 AND 31),
    day_of_week integer NOT NULL CHECK (day_of_week BETWEEN 1 AND 7)
);

CREATE TABLE dim_pet_type (
    pet_type_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pet_type_name varchar(255) NOT NULL UNIQUE
);

CREATE TABLE dim_pet_breed (
    pet_breed_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pet_breed_name varchar(255) NOT NULL UNIQUE
);

CREATE TABLE dim_customer_pet (
    customer_pet_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pet_name varchar(255),
    pet_type_key integer REFERENCES dim_pet_type(pet_type_key),
    pet_breed_key integer REFERENCES dim_pet_breed(pet_breed_key),

    UNIQUE (pet_name, pet_type_key, pet_breed_key)
);

CREATE TABLE dim_customer (
    customer_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_customer_id integer,
    first_name varchar(255),
    last_name varchar(255),
    age integer CHECK (age IS NULL OR age >= 0),
    email varchar(255),
    location_key integer REFERENCES dim_location(location_key),
    customer_pet_key integer REFERENCES dim_customer_pet(customer_pet_key),

    UNIQUE (email)
);

CREATE TABLE dim_seller (
    seller_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_seller_id integer,
    first_name varchar(255),
    last_name varchar(255),
    email varchar(255),
    location_key integer REFERENCES dim_location(location_key),

    UNIQUE (email)
);

CREATE TABLE dim_store (
    store_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    store_name varchar(255) NOT NULL,
    location_key integer REFERENCES dim_location(location_key),
    phone varchar(64),
    email varchar(255),

    UNIQUE (store_name, email)
);

CREATE TABLE dim_product_category (
    product_category_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_category_name varchar(255) NOT NULL UNIQUE
);

CREATE TABLE dim_pet_category (
    pet_category_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pet_category_name varchar(255) NOT NULL UNIQUE
);

CREATE TABLE dim_product_brand (
    product_brand_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    brand_name varchar(255) NOT NULL UNIQUE
);

CREATE TABLE dim_product_color (
    product_color_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    color_name varchar(255) NOT NULL UNIQUE
);

CREATE TABLE dim_product_size (
    product_size_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    size_name varchar(255) NOT NULL UNIQUE
);

CREATE TABLE dim_product_material (
    product_material_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    material_name varchar(255) NOT NULL UNIQUE
);

CREATE TABLE dim_supplier (
    supplier_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_name varchar(255) NOT NULL,
    contact text,
    email varchar(255),
    phone varchar(64),
    location_key integer REFERENCES dim_location(location_key),

    UNIQUE (supplier_name, email)
);

CREATE TABLE dim_product (
    product_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_product_id integer,
    product_name varchar(255) NOT NULL,
    product_price numeric(12, 2),
    product_quantity integer CHECK (product_quantity IS NULL OR product_quantity >= 0),
    product_weight numeric(12, 2),
    product_description text,
    product_rating numeric(3, 2),
    product_reviews integer CHECK (product_reviews IS NULL OR product_reviews >= 0),
    release_date_key integer REFERENCES dim_date(date_key),
    expiry_date_key integer REFERENCES dim_date(date_key),
    product_category_key integer REFERENCES dim_product_category(product_category_key),
    pet_category_key integer REFERENCES dim_pet_category(pet_category_key),
    product_brand_key integer REFERENCES dim_product_brand(product_brand_key),
    product_color_key integer REFERENCES dim_product_color(product_color_key),
    product_size_key integer REFERENCES dim_product_size(product_size_key),
    product_material_key integer REFERENCES dim_product_material(product_material_key),
    supplier_key integer REFERENCES dim_supplier(supplier_key),

    UNIQUE (
        product_name,
        product_price,
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
);

CREATE TABLE fact_sales (
    sales_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_id integer,
    source_customer_id integer,
    source_seller_id integer,
    source_product_id integer,
    sale_date_key integer NOT NULL REFERENCES dim_date(date_key),
    customer_key integer NOT NULL REFERENCES dim_customer(customer_key),
    seller_key integer NOT NULL REFERENCES dim_seller(seller_key),
    store_key integer NOT NULL REFERENCES dim_store(store_key),
    product_key integer NOT NULL REFERENCES dim_product(product_key),
    sale_quantity integer NOT NULL CHECK (sale_quantity > 0),
    sale_total_price numeric(12, 2) NOT NULL CHECK (sale_total_price >= 0)
);
