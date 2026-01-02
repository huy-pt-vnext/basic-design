# Stream

## Cái gì quyết định canWrite === false?
```ts
const canWrite = res.write(chunk);
```
Giả sử: client nhận chậm
+ res.writableHighWaterMark = 16KB // do node và client set, dev không control được
+ Transform.highWaterMark = 16KB // dev control được qua Transform

### Bước 1️⃣ Client chậm:
+ TCP send buffer đầy dần
+ Node không flush kịp
+ Nếu transform vẫn lấy data từ s3 => full memory => crash app

### Bước 2️⃣ res.write(chunk) → false
+ Tức client network chậm, node stream chunk => TCP send buffer đầy dần (16kb), lúc này res.write(chunk) = false

### Bước 3️⃣ Chúng ta outputStream.pause()
```ts
outputStream.pause();
```
+  👉 Transform không push thêm
+ Lúc này Transform.highWaterMark = 16KB => transform chỉ nhận trong memory từ S3 stream 16kb(không hơn), nó tự trigger nói rằng, tôi tạm thời không nhận, nên đừng gửi => 👉 Upstream S3 dừng tạm thời
+ 🔥 ĐIỂM QUAN TRỌNG pause():
  + dừng emit data
  + KHÔNG destroy
  + stream vẫn tồn tại
  + Upstream bị backpressure
  + 👉 Tại đây: outputStream ⏸️ (đứng im)

### 4️⃣ Nói cách khác (câu này quan trọng)
+ highWaterMark của Transform = giới hạn nội bộ pipeline
+ res.writableHighWaterMark = giới hạn giao tiếp với client
+ Hai cái:
  + độc lập
  + nhưng phối hợp với nhau để ổn định

### Bước 5️⃣: Đăng ký res.once('drain')
```ts
res.once('drain', () => {
  if (!aborted) {
    outputStream.resume();
  }
});
```
+ Khi client đọc kịp → socket flush → buffer rỗng
+ ➡ callback drain chạy

Tiếp theo: outputStream.resume();
👉 Sau resume():
+ outputStream tiếp tục emit data
+ Control quay lại đầu callback on('data')
+ Flow lặp lại từ đầu



