CREATE TABLE "customers" (
                             "customer_id" int PRIMARY KEY,
                             "first_name" varchar,
                             "last_name" varchar,
                             "gender" varchar,
                             "DOB" date,
                             "job_title" varchar,
                             "job_industry_category" varchar,
                             "wealth_segment" varchar,
                             "deceased_indicator" varchar,
                             "owns_car" varchar,
                             "address" varchar,
                             "postcode" int,
                             "state" varchar,
                             "country" varchar,
                             "property_valuation" int
);

CREATE TABLE "products" (
                            "product_id" int PRIMARY KEY,
                            "brand" varchar,
                            "product_line" varchar,
                            "product_class" varchar,
                            "product_size" varchar,
                            "list_price" decimal,
                            "standard_cost" decimal
);

CREATE TABLE "transactions" (
                                "transaction_id" int PRIMARY KEY,
                                "customer_id" int NOT NULL,
                                "product_id" int NOT NULL,
                                "transaction_date" date,
                                "online_order" boolean,
                                "order_status" varchar
);

ALTER TABLE "transactions" ADD FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id");

ALTER TABLE "transactions" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("product_id");