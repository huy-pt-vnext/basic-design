explain
SELECT n.*, ni.image_url
FROM notifications n
join public.notification_images ni on n.notification_id = ni.notification_id
WHERE n.status = 'publishing'
  AND n.publish_start <= NOW()
  AND n.publish_end >= NOW()
  
offset 1000001
limit 100

CREATE INDEX idx_notifications_list_target_gin
  ON notifications
  USING gin (list_target jsonb_path_ops);

CREATE INDEX idx_notifications_status_publish_dates_list_target
  ON notifications (status, publish_start, publish_end, list_target);

CREATE INDEX idx_notifications_status_publish_dates_
  ON notifications (status, publish_start, publish_end);

CREATE INDEX idx_notifications_status
  ON notifications (status);

CREATE INDEX idx_notification_image_notification_id
  ON notification_images (notification_id);

SELECT n.*
FROM notifications n


SELECT count(n.*)
FROM notifications n


SELECT count(ni.notification_id )
FROM notification_images ni

SELECT ni.*
FROM notification_images ni 




CREATE INDEX idx_notifications_deleted
  ON notifications(deleted)

  
  

CREATE INDEX idx_notifications_created_at
  ON notifications(created_at)
  
  
  
  
CREATE INDEX idx_notifications_created_at_not_deleted
  ON notifications (created_at DESC)
  WHERE deleted = false;
  
  
  
  
