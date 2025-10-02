-- 1. accounts
CREATE TABLE accounts (
    account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_company_id BIGINT NOT NULL,
    partner_user_id BIGINT NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP,
    deleted BOOLEAN DEFAULT FALSE
);

-- 2. brands
CREATE TABLE brands (
    brand_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_company_id BIGINT NOT NULL,
    partner_user_id BIGINT NOT NULL,
    brand_name VARCHAR(191) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP,
    deleted BOOLEAN DEFAULT FALSE
);

-- 3. brand_images
CREATE TABLE brand_images (
    brand_id UUID NOT NULL,
    image_url TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP,
    deleted BOOLEAN DEFAULT false,
    CONSTRAINT fk_brand_images_brands_id FOREIGN KEY (brand_id) REFERENCES brands(brand_id)
);


CREATE TABLE prefecture_municipalities (
    municipality_code CHAR(6) PRIMARY KEY,             -- JIS X 0402, unique toàn quốc
    municipality_name VARCHAR(100) NOT NULL,
    prefecture_code CHAR(2) NOT NULL,                  -- JIS X 0401
    prefecture_name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP,
    deleted BOOLEAN DEFAULT FALSE
);

CREATE TABLE stores (
    store_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_company_id BIGINT NOT NULL,
    partner_user_id BIGINT NOT NULL,
    brand_id UUID NOT NULL,
    municipality_code CHAR(6) NOT NULL,
    store_name VARCHAR(191) NOT NULL,
    store_name_katakana VARCHAR(191),
    store_name_brief VARCHAR(100),
    address TEXT NOT NULL,
    phone_number VARCHAR(20),
    open_time TIME,
    close_time TIME,
    open_date DATE NOT NULL,
    close_date DATE,
    logo_type UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP,
    deleted BOOLEAN DEFAULT false,
    CONSTRAINT fk_stores_brands_brand_id 
        FOREIGN KEY (brand_id) REFERENCES brands(brand_id),
    CONSTRAINT fk_stores_municipalities_municipality_code 
        FOREIGN KEY (municipality_code) REFERENCES prefecture_municipalities(municipality_code)
);


-- 7. notifications
CREATE TABLE notifications (
    notification_id BIGSERIAL PRIMARY KEY,
    partner_company_id BIGINT NOT NULL,
    partner_user_id BIGINT NOT NULL,
    title VARCHAR(191) NOT NULL,
    content VARCHAR(1000) NOT NULL,
    jump_url VARCHAR(500),
    is_top BOOLEAN,
    list_size VARCHAR(20) NOT NULL DEFAULT 'normal',
    publish_start TIMESTAMP,
    publish_end TIMESTAMP,
    push_enabled BOOLEAN,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    push_registered_at TIMESTAMP,
    push_canceled_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP,
    deleted BOOLEAN DEFAULT FALSE
);

-- 8. notification_images
CREATE TABLE notification_images (
    notification_id BIGINT NOT NULL,
    image_url TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP,
    deleted BOOLEAN DEFAULT false,
    CONSTRAINT fk_notification_images_notifications_id FOREIGN KEY (notification_id) REFERENCES notifications(notification_id)
);

-- 9. flyers
CREATE TABLE flyers (
    flyer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_company_id BIGINT NOT NULL,
    partner_user_id BIGINT NOT NULL,
    title VARCHAR(191) NOT NULL,
    content TEXT NOT NULL,
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    target_store_ids JSON,
    push_flag BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP,
    deleted BOOLEAN DEFAULT FALSE
);

-- 10. flyer_images
CREATE TABLE flyer_images (
    flyer_id UUID NOT NULL,
    image_url TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP,
    deleted BOOLEAN DEFAULT false,
    CONSTRAINT fk_flyers_image_flyers_id FOREIGN KEY (flyer_id) REFERENCES flyers(flyer_id)
);



CREATE TABLE advertisements (
    advertisement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    url TEXT NOT NULL,
    position VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP,
    deleted BOOLEAN DEFAULT FALSE
);
