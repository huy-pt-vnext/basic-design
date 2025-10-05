EXPLAIN
SELECT n.*, ni.image_url
FROM notifications n
join public.notification_images ni on n.notification_id = ni.notification_id
WHERE n.status = 'publishing'
  AND n.publish_start <= NOW()
  AND n.publish_end >= NOW()
  AND (
      (n.list_target->'brand_ids' ? 'b001')
   OR (n.list_target->'store_ids' ? 's010')
   OR (n.list_target->'area_ids' ? 'a05')
  )
and  n.notification_id  = 1786095



explain
SELECT n.*, ni.image_url
FROM notifications n
join public.notification_images ni on n.notification_id = ni.notification_id
WHERE n.status = 'publishing'
  AND n.publish_start <= NOW()
  AND n.publish_end >= NOW()
  
offset 1000001
limit 100



explain analyze
with  test as (
SELECT n.*
FROM notifications n
WHERE n.status = 'publishing'
  AND n.publish_start <= NOW()
  AND n.publish_end >= NOW()

offset 1000001
limit 100

)
SELECT n.*, ni.image_url
FROM test n
join public.notification_images ni on n.notification_id = ni.notification_id


explain analyze
SELECT n.partner_company_id, n.partner_user_id
FROM notifications n
where n.partner_company_id  = 10  and n.partner_user_id = 85



CREATE INDEX idx_notifications_partner_company_id
ON notifications (partner_company_id)

CREATE INDEX idx_notifications_partner_company_user_id
ON notifications (partner_company_id, partner_user_id)





explain
select title, deleted from notifications
where deleted = false

 explain
select  title from notifications


explain
select  deleted from notifications
where deleted = false


explain 
SELECT * 
FROM notifications
WHERE deleted = false 
  AND created_at > now() - INTERVAL '3 days'
ORDER BY created_at ASC;
