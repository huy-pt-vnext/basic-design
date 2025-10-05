INSERT INTO notifications (
    partner_company_id,
    partner_user_id,
    title,
    content,
    jump_url,
    is_top,
    list_size,
    list_target,
    publish_start,
    publish_end,
    push_enabled,
    status,
    push_registered_at,
    push_canceled_at
)
SELECT
    (RANDOM() * 10)::INT + 1 AS partner_company_id,
    (RANDOM() * 100)::INT + 1 AS partner_user_id,
    '通知タイトル ' || gs::TEXT AS title,
    'これはお知らせの内容 ' || gs::TEXT AS content,
    'https://example.com/notice/' || gs::TEXT AS jump_url,
    (RANDOM() > 0.8) AS is_top,
    CASE WHEN RANDOM() > 0.5 THEN 'normal' ELSE 'compact' END AS list_size,
    (
        jsonb_build_object(
            'brand_ids', ARRAY[
                ('b' || LPAD(((RANDOM() * 20)::INT)::TEXT, 3, '0'))
            ],
            'store_ids', ARRAY[
                ('s' || LPAD(((RANDOM() * 200)::INT)::TEXT, 3, '0'))
            ],
            'area_ids', ARRAY[
                ('a' || LPAD(((RANDOM() * 30)::INT)::TEXT, 2, '0'))
            ]
        )
    ) AS list_target,
    NOW() - (RANDOM() * INTERVAL '10 days') AS publish_start,
    NOW() + (RANDOM() * INTERVAL '10 days') AS publish_end,
    (RANDOM() > 0.5) AS push_enabled,
    'publishing' AS status,
    NOW() AS push_registered_at,
    NULL AS push_canceled_at
FROM generate_series(1, 2000000) AS gs;




INSERT INTO notification_images (
    notification_id,
    image_url,
    created_at,
    updated_at
)
SELECT
    n.notification_id,
    'https://cdn.example.com/notice_' || n.notification_id || '_img' || i::TEXT || '.jpg',
    NOW(),
    NOW()
FROM notifications AS n
CROSS JOIN LATERAL generate_series(
    1,
    (1 + (RANDOM() * 6)::INT)  -- Random từ 1 đến 7 ảnh
) AS i;




explain analyze
SELECT n.*
FROM notifications n
where n.partner_company_id  = 10
