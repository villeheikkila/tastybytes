create table "public"."brands" (
    "id" bigint generated by default as identity not null,
    "name" text not null,
    "brand_owner_id" bigint not null,
    "created_at" timestamp with time zone not null,
    "created_by" uuid not null
);


alter table "public"."brands" enable row level security;

create table "public"."check_in_comments" (
    "id" bigint generated by default as identity not null,
    "content" text not null,
    "created_at" timestamp with time zone not null default now(),
    "created_by" uuid not null,
    "check_in_id" integer not null
);


alter table "public"."check_in_comments" enable row level security;

create table "public"."check_in_reactions" (
    "id" bigint generated by default as identity not null,
    "created_at" timestamp with time zone default now(),
    "created_by" uuid,
    "reaction_id" bigint not null,
    "check_in_id" bigint
);


alter table "public"."check_in_reactions" enable row level security;

create table "public"."check_ins" (
    "id" bigint generated by default as identity not null,
    "rating" text,
    "review" text,
    "created_at" timestamp with time zone not null default now(),
    "created_by" uuid not null,
    "product_id" bigint not null
);


alter table "public"."check_ins" enable row level security;

create table "public"."products" (
    "id" bigint generated by default as identity not null,
    "name" text not null,
    "description" text,
    "created_at" timestamp with time zone not null default now(),
    "created_by" uuid not null,
    "sub-brand_id" bigint not null,
    "subcategory_id" bigint not null,
    "manufacturer_id" bigint
);


alter table "public"."products" enable row level security;

create table "public"."profiles" (
    "id" uuid not null,
    "first_name" text,
    "last_name" text,
    "username" text not null
);


alter table "public"."profiles" enable row level security;

create table "public"."reactions" (
    "id" bigint generated by default as identity not null,
    "name" text not null
);


alter table "public"."reactions" enable row level security;

create table "public"."sub-brands" (
    "id" bigint generated by default as identity not null,
    "name" text,
    "brand_id" bigint not null,
    "created_at" timestamp with time zone not null default now(),
    "created_by" uuid not null
);


alter table "public"."sub-brands" enable row level security;

create table "public"."subcategories" (
    "id" bigint generated by default as identity not null,
    "name" text,
    "created_at" timestamp with time zone not null default now(),
    "created_by" uuid not null
);


alter table "public"."subcategories" enable row level security;

alter table "public"."categories" enable row level security;

alter table "public"."companies" add column "created_at" timestamp with time zone not null default now();

alter table "public"."companies" add column "created_by" uuid not null;

alter table "public"."companies" alter column "id" set generated by default;

alter table "public"."companies" alter column "id" set data type bigint using "id"::bigint;

alter table "public"."companies" enable row level security;

CREATE UNIQUE INDEX brand_pkey ON public.brands USING btree (id);

CREATE UNIQUE INDEX check_in_comments_pkey ON public.check_in_comments USING btree (id);

CREATE UNIQUE INDEX check_in_reactions_pkey ON public.check_in_reactions USING btree (id);

CREATE UNIQUE INDEX check_ins_pkey ON public.check_ins USING btree (id);

CREATE UNIQUE INDEX product_pkey ON public.products USING btree (id);

CREATE UNIQUE INDEX profiles_pkey ON public.profiles USING btree (id);

CREATE UNIQUE INDEX reactions_name_key ON public.reactions USING btree (name);

CREATE UNIQUE INDEX reactions_pkey ON public.reactions USING btree (id);

CREATE UNIQUE INDEX "sub-brand_pkey" ON public."sub-brands" USING btree (id);

CREATE UNIQUE INDEX subcategories_pkey ON public.subcategories USING btree (id);

alter table "public"."brands" add constraint "brand_pkey" PRIMARY KEY using index "brand_pkey";

alter table "public"."check_in_comments" add constraint "check_in_comments_pkey" PRIMARY KEY using index "check_in_comments_pkey";

alter table "public"."check_in_reactions" add constraint "check_in_reactions_pkey" PRIMARY KEY using index "check_in_reactions_pkey";

alter table "public"."check_ins" add constraint "check_ins_pkey" PRIMARY KEY using index "check_ins_pkey";

alter table "public"."products" add constraint "product_pkey" PRIMARY KEY using index "product_pkey";

alter table "public"."profiles" add constraint "profiles_pkey" PRIMARY KEY using index "profiles_pkey";

alter table "public"."reactions" add constraint "reactions_pkey" PRIMARY KEY using index "reactions_pkey";

alter table "public"."sub-brands" add constraint "sub-brand_pkey" PRIMARY KEY using index "sub-brand_pkey";

alter table "public"."subcategories" add constraint "subcategories_pkey" PRIMARY KEY using index "subcategories_pkey";

alter table "public"."brands" add constraint "brands_brand_owner_id_fkey" FOREIGN KEY (brand_owner_id) REFERENCES companies(id) ON DELETE CASCADE not valid;

alter table "public"."brands" validate constraint "brands_brand_owner_id_fkey";

alter table "public"."brands" add constraint "brands_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL not valid;

alter table "public"."brands" validate constraint "brands_created_by_fkey";

alter table "public"."check_in_comments" add constraint "check_in_comments_check_in_id_fkey" FOREIGN KEY (check_in_id) REFERENCES check_ins(id) ON DELETE CASCADE not valid;

alter table "public"."check_in_comments" validate constraint "check_in_comments_check_in_id_fkey";

alter table "public"."check_in_comments" add constraint "check_in_comments_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE CASCADE not valid;

alter table "public"."check_in_comments" validate constraint "check_in_comments_created_by_fkey";

alter table "public"."check_in_reactions" add constraint "check_in_reactions_check_in_id_fkey" FOREIGN KEY (check_in_id) REFERENCES check_ins(id) ON DELETE CASCADE not valid;

alter table "public"."check_in_reactions" validate constraint "check_in_reactions_check_in_id_fkey";

alter table "public"."check_in_reactions" add constraint "check_in_reactions_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE CASCADE not valid;

alter table "public"."check_in_reactions" validate constraint "check_in_reactions_created_by_fkey";

alter table "public"."check_in_reactions" add constraint "check_in_reactions_reaction_id_fkey" FOREIGN KEY (reaction_id) REFERENCES reactions(id) ON DELETE CASCADE not valid;

alter table "public"."check_in_reactions" validate constraint "check_in_reactions_reaction_id_fkey";

alter table "public"."check_ins" add constraint "check_ins_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE CASCADE not valid;

alter table "public"."check_ins" validate constraint "check_ins_created_by_fkey";

alter table "public"."check_ins" add constraint "check_ins_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE not valid;

alter table "public"."check_ins" validate constraint "check_ins_product_id_fkey";

alter table "public"."companies" add constraint "companies_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL not valid;

alter table "public"."companies" validate constraint "companies_created_by_fkey";

alter table "public"."products" add constraint "products_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL not valid;

alter table "public"."products" validate constraint "products_created_by_fkey";

alter table "public"."products" add constraint "products_manufacturer_id_fkey" FOREIGN KEY (manufacturer_id) REFERENCES companies(id) ON DELETE CASCADE not valid;

alter table "public"."products" validate constraint "products_manufacturer_id_fkey";

alter table "public"."products" add constraint "products_sub-brand_id_fkey" FOREIGN KEY ("sub-brand_id") REFERENCES "sub-brands"(id) ON DELETE CASCADE not valid;

alter table "public"."products" validate constraint "products_sub-brand_id_fkey";

alter table "public"."products" add constraint "products_subcategory_id_fkey" FOREIGN KEY (subcategory_id) REFERENCES subcategories(id) ON DELETE CASCADE not valid;

alter table "public"."products" validate constraint "products_subcategory_id_fkey";

alter table "public"."profiles" add constraint "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) not valid;

alter table "public"."profiles" validate constraint "profiles_id_fkey";

alter table "public"."reactions" add constraint "reactions_name_key" UNIQUE using index "reactions_name_key";

alter table "public"."sub-brands" add constraint "sub-brands_brand_id_fkey" FOREIGN KEY (brand_id) REFERENCES brands(id) ON DELETE CASCADE not valid;

alter table "public"."sub-brands" validate constraint "sub-brands_brand_id_fkey";

alter table "public"."sub-brands" add constraint "sub-brands_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL not valid;

alter table "public"."sub-brands" validate constraint "sub-brands_created_by_fkey";

alter table "public"."subcategories" add constraint "subcategories_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL not valid;

alter table "public"."subcategories" validate constraint "subcategories_created_by_fkey";


