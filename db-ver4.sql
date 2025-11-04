
CREATE TABLE brands (
    brand_id CHAR(100) PRIMARY KEY,
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

CREATE TABLE brand_images (
    brand_id CHAR(100) NOT NULL,
    partner_company_id BIGINT NOT NULL,
    partner_user_id BIGINT NOT NULL,
    image_url TEXT NOT NULL,
    display_order SMALLINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP,
    deleted BOOLEAN DEFAULT false,
    CONSTRAINT fk_brand_images_brands_id FOREIGN KEY (brand_id) REFERENCES brands(brand_id)
);




CREATE TABLE prefecture_municipalities (
    municipality_code CHAR(6) PRIMARY KEY,
    municipality_name VARCHAR(100) NOT NULL,
    prefecture_code CHAR(2) NOT NULL,
    prefecture_name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP,
    deleted BOOLEAN DEFAULT FALSE
);


CREATE TABLE stores (
    store_id CHAR(60) PRIMARY KEY,
    partner_company_id BIGINT NOT NULL,
    partner_user_id BIGINT NOT NULL,
    brand_id CHAR(100) NOT NULL,
    prefecture_code CHAR(2) NOT NULL,
    municipality_code CHAR(6) NOT NULL,
    store_name VARCHAR(191) NOT NULL,
    store_name_brief VARCHAR(100),
    store_name_katakana VARCHAR(191),
    address TEXT NOT NULL,
    phone_number VARCHAR(20),
    open_time TIME,
    close_time TIME,
    open_date DATE NOT NULL,
    close_date DATE,
    logo_type CHAR(100) NOT NULL,
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


CREATE TABLE notifications (
    notification_id BIGSERIAL PRIMARY KEY,
    partner_company_id BIGINT NOT NULL,
    partner_user_id BIGINT NOT NULL,
    title VARCHAR(191) NOT NULL,
    content VARCHAR(1000) NOT NULL,
    jump_url VARCHAR(500),
    is_top BOOLEAN DEFAULT FALSE,
    list_size VARCHAR(20) NOT NULL DEFAULT 'normal',
    list_target JSONB,
    publish_start TIMESTAMP,
    publish_end TIMESTAMP,
    push_enabled BOOLEAN,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    push_registered_at TIMESTAMP,
    push_canceled_at TIMESTAMP,
    appbox_push_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP,
    deleted BOOLEAN DEFAULT FALSE
);

CREATE TABLE notification_images (
    notification_id BIGINT NOT NULL,
    partner_company_id BIGINT NOT NULL,
    partner_user_id BIGINT NOT NULL,
    image_url TEXT NOT NULL,
    display_order SMALLINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP,
    deleted BOOLEAN DEFAULT false,
    CONSTRAINT fk_notification_images_notifications_id FOREIGN KEY (notification_id) REFERENCES notifications(notification_id)
);

CREATE TABLE flyers (
    flyer_id BIGSERIAL PRIMARY KEY,
    partner_company_id BIGINT NOT NULL,
    partner_user_id BIGINT NOT NULL,
    title VARCHAR(191) NOT NULL,
    content TEXT NOT NULL,
    list_target JSONB,
    publish_start TIMESTAMP,
    publish_end TIMESTAMP,
    push_flag BOOLEAN DEFAULT FALSE,
    push_enabled BOOLEAN,
    push_registered_at TIMESTAMP,
    push_canceled_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'draft',
    appbox_push_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP,
    deleted BOOLEAN DEFAULT FALSE
);

CREATE TABLE flyer_images (
    flyer_id BIGINT NOT NULL,
    partner_company_id BIGINT NOT NULL,
    partner_user_id BIGINT NOT NULL,
    display_order SMALLINT NOT NULL,
    image_url TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP,
    deleted BOOLEAN DEFAULT false,
    CONSTRAINT fk_flyers_image_flyers_id FOREIGN KEY (flyer_id) REFERENCES flyers(flyer_id)
);


