# BigDataSnowflake
Анализ больших данных - лабораторная работа №1 - нормализация данных в снежинку

## Запуск


```cmd
git clone https://github.com/Darrit4u/BDSnowflake.git 
cd BDSnowflake
docker compose up
```

В volume докера скопируются исходные csv файлы и три файла sql-скриптов.

sql-скрипты скопируются в папку ```/docker-entrypoint-initdb.d/``` поэтому будут автоматически запущены:

- ```init.sql``` - DDL-скрипт - создает таблицы для снежинки

- ```import_mock.sql``` - забираем данные из исходных csv в одну таблицу mock_data

- ```dml.sql``` - DML-скрипт - заполнение данными из mock_data

### Подключения к postgresql

```cmd
jdbc:postgresql://localhost:5432/lab1
```

user: lab1_user

password: lab1_password

## Ход выполнения лабораторной работы

Для снежинки как факт выбран объект Продаж, так как это основная единица бизнес-процесса
Одна строка из исходных  csv-файлов соответсвует одной продаже.
Измерения, исходящие из факта: дата, покупатель, продукт, продавец, магазин.

Дополнительные измерения: география, питомец

Ниже подробнее про таблицы

### Таблица фактов

`fact_sales` хранит измеримые показатели продажи и ссылки на измерения:

- `sales_key` - первичный ключ факта;
- `source_id`, `source_customer_id`, `source_seller_id`, `source_product_id` - исходные идентификаторы из `mock_data`;
- `sale_date_key` - ссылка на дату продажи;
- `customer_key` - ссылка на покупателя;
- `seller_key` - ссылка на продавца;
- `store_key` - ссылка на магазин;
- `product_key` - ссылка на товар;
- `sale_quantity` - количество проданного товара;
- `sale_total_price` - итоговая сумма продажи.

### Измерение даты

`dim_date` для удобного представления дат и может быть последующего анализа данных:

- `date_key`;
- `full_date`;
- `year`;
- `quarter`;
- `month`;
- `month_name`;
- `day`;
- `day_of_week`.

Это измерение связано с `fact_sales` через `sale_date_key`, а также используется в `dim_product` для дат выпуска и срока годности товара.

### Измерение покупателя

`dim_customer` описывает покупателя:

- `customer_key`;
- `source_customer_id`;
- `first_name`;
- `last_name`;
- `age`;
- `email`;
- `location_key`;
- `customer_pet_key`.

Покупатель связан с географией через `dim_location` и с питомцем через `dim_customer_pet`.

Ветка питомца:

```text
dim_customer
    -> dim_customer_pet
        -> dim_pet_type
        -> dim_pet_breed
```

### Измерение продавца

`dim_seller` описывает продавца:

- `seller_key`;
- `source_seller_id`;
- `first_name`;
- `last_name`;
- `email`;
- `location_key`.

Продавец связан с географией через `dim_location`.

### Измерение магазина

`dim_store` описывает магазин, в котором была совершена продажа:

- `store_key`;
- `store_name`;
- `location_key`;
- `phone`;
- `email`.

Магазин связан с географией через `dim_location`.

### Измерение товара

`dim_product` описывает товар:

- `product_key`;
- `source_product_id`;
- `product_name`;
- `product_price`;
- `product_quantity`;
- `product_weight`;
- `product_description`;
- `product_rating`;
- `product_reviews`;
- `release_date_key`;
- `expiry_date_key`;
- `product_category_key`;
- `pet_category_key`;
- `product_brand_key`;
- `product_color_key`;
- `product_size_key`;
- `product_material_key`;
- `supplier_key`.

Товар нормализован через дополнительные справочники:

```text
dim_product
    -> dim_product_category
    -> dim_pet_category
    -> dim_product_brand
    -> dim_product_color
    -> dim_product_size
    -> dim_product_material
    -> dim_supplier
```

### Измерение поставщика

`dim_supplier` описывает поставщика товара:

- `supplier_key`;
- `supplier_name`;
- `contact`;
- `email`;
- `phone`;
- `location_key`.

Поставщик связан с географией через `dim_location`.

### Географическая ветка

География вынесена в отдельную нормализованную ветку:

```text
dim_location
    -> dim_country
```

`dim_location` хранит город, штат, почтовый индекс, адрес и дополнительные детали расположения. `dim_country` хранит уникальные страны. Эта ветка используется покупателями, продавцами, магазинами и поставщиками.

### Общая схема связей

```text
fact_sales
    -> dim_date
    -> dim_customer
        -> dim_customer_pet
            -> dim_pet_type
            -> dim_pet_breed
        -> dim_location
            -> dim_country
    -> dim_seller
        -> dim_location
            -> dim_country
    -> dim_store
        -> dim_location
            -> dim_country
    -> dim_product
        -> dim_date
        -> dim_product_category
        -> dim_pet_category
        -> dim_product_brand
        -> dim_product_color
        -> dim_product_size
        -> dim_product_material
        -> dim_supplier
            -> dim_location
                -> dim_country
```
