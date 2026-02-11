# Nguyên tắc SOLID

SOLID là một tập hợp các nguyên tắc thiết kế phần mềm nhằm giúp các nhà phát triển tạo ra các hệ thống dễ bảo trì, mở rộng và hiểu rõ hơn. SOLID là viết tắt của năm nguyên tắc chính:
1. **Single Responsibility Principle (SRP) - Nguyên tắc trách nhiệm đơn**  
   Mỗi lớp nên chỉ có một lý do để thay đổi, nghĩa là mỗi lớp chỉ nên chịu trách nhiệm về một chức năng duy nhất trong hệ thống.
2. **Open/Closed Principle (OCP) - Nguyên tắc mở/đóng**  
   Các thực thể phần mềm (lớp, mô-đun, hàm, v.v.) nên được mở để mở rộng nhưng đóng để sửa đổi. Điều này có nghĩa là bạn có thể thêm chức năng mới mà không cần thay đổi mã nguồn hiện có.
3. **Liskov Substitution Principle (LSP) - Nguyên tắc thay thế Liskov**  
   Các đối tượng của một lớp con nên có thể thay thế các đối tượng của lớp cha mà không làm thay đổi tính đúng đắn của chương trình. Nói cách khác, lớp con phải tuân thủ hợp đồng của lớp cha.
4. **Interface Segregation Principle (ISP) - Nguyên tắc phân tách giao diện**  
   Nên tạo ra các giao diện nhỏ và chuyên biệt thay vì các giao diện lớn và đa năng. Điều này giúp các lớp chỉ cần triển khai những phương thức mà chúng thực sự sử dụng.
5. **Dependency Inversion Principle (DIP) - Nguyên tắc đảo ngược phụ thuộc**  
   Các mô-đun cấp cao không nên phụ thuộc vào các mô-đun cấp thấp; cả hai nên phụ thuộc vào các trừu tượng. Ngoài ra, các trừu tượng không nên phụ thuộc vào chi tiết; chi tiết nên phụ thuộc vào các trừu tượng.



## Single Responsibility Principle (SRP)
Nguyên tắc này nhấn mạnh rằng mỗi lớp nên có một và chỉ một lý do để thay đổi. Điều này giúp giảm sự phức tạp và làm cho mã dễ bảo trì hơn.
Ví dụ:
```ts
class Invoice {
    private items: Item[];
    private total: number;

    constructor(items: Item[]) {
        this.items = items;
        this.total = this.calculateTotal();
    }

    private calculateTotal(): number {
        return this.items.reduce((sum, item) => sum + item.price, 0);
    }

    private saveToDatabase(): void {
        // init connect to PostgreSQL
        // create pool connection
        // PgRepository.save(data);
    }

    private sendNotification(): void {
        // NotificationService.send(data);
    }

    private printInvoice(): void {
        // PrintService.print(data);
    }
}
```
Trong ví dụ trên, lớp `Invoice` chịu trách nhiệm về nhiều chức năng khác nhau như tính toán tổng, lưu vào cơ sở dữ liệu, gửi thông báo và in hóa đơn. 
Điều gì xảy ra nếu chúng ta cần thay đổi cách lưu trữ dữ liệu hoặc gửi thông báo, hoặc đổi cách in hóa đơn từ file PDF ra file XLXS ? Chúng ta sẽ phải sửa đổi lớp `Invoice`.
+ Nếu khách hàng yêu cầu thay đổi cách lưu trữ từ PostgreSQL sang MongoDB, chúng ta sẽ phải sửa đổi phương thức toàn bộ cách lưu trữ trong lớp `Invoice`. Mở file Invoice ra và tìm đến phương thức `saveToDatabase`, sau đó thay đổi toàn bộ logic kết nối và lưu trữ dữ liệu.
+ Nếu nghiệp vụ thay đổi cách gửi thông báo từ email sang SMS, chúng ta sẽ phải sửa đổi phương thức gửi thông báo trong lớp `Invoice`. Mở file Invoice ra và tìm đến phương thức `sendNotification`, sau đó thay đổi toàn bộ logic gửi thông báo.
+ Nếu thay đổi cách in hóa đơn từ file PDF sang file XLXS, chúng ta sẽ phải sửa đổi phương thức in hóa đơn trong lớp `Invoice`.
+ Nếu nghiệp vụ yêu cầu thay đổi cách tính tổng hóa đơn, chúng ta sẽ phải sửa đổi phương thức `calculateTotal` trong lớp `Invoice`.

Điều này làm cho lớp `Invoice` trở nên khó bảo trì và dễ bị lỗi khi có nhiều thay đổi, thử hỏi bạn muốn maintain file code 2000 dòng import, xử lí nghiệp vụ chồng chéo hay thay vì sửa một file cụ thể chịu một trách nhiệm riêng lẻ . 
Hơn nữa là khi chúng ta cần thay đổi một chức năng, chúng ta có thể vô tình ảnh hưởng đến các chức năng khác trong cùng lớp.

Sau đây là các vấn đề của việc không tuân thủ nguyên tắc SRP:
- **Khó bảo trì**: Khi một lớp chịu trách nhiệm về nhiều chức năng, việc bảo trì trở nên phức tạp hơn vì thay đổi một chức năng có thể ảnh hưởng đến các chức năng khác.
- **Khó hiểu**: Lớp trở nên khó hiểu hơn vì nó chứa nhiều logic khác nhau, làm cho việc đọc và hiểu mã trở nên khó khăn hơn.
- **Class lớn dần theo thời gian**: Khi thêm nhiều chức năng vào một lớp, nó có thể trở nên quá lớn và khó quản lý.
- **Không thể tái sử dụng**: Các lớp không tuân thủ SRP thường khó tái sử dụng trong các ngữ cảnh khác vì chúng chứa nhiều logic không liên quan.
- **Khó kiểm thử**: Việc viết các bài kiểm thử đơn vị trở nên khó khăn hơn vì lớp chứa nhiều chức năng khác nhau. Làm sao để bản chỉ kiểm thử một chức năng mà không ảnh hưởng đến các chức năng khác, chẳng hản chỉ kiểm thử cách tính hóa đơn, lưu trữ dữ liệu, gửi thông báo và in hóa đơn riêng lẻ.

Để tuân thủ nguyên tắc SRP, chúng ta có thể tách lớp `Invoice` thành các lớp riêng biệt, mỗi lớp chịu trách nhiệm về một chức năng cụ thể:
```ts
class Invoice {
    private items: Item[];
    private total: number;
    private repository: InvoiceRepository;
    private notificationService: NotificationService;
    private printService: PrintService;
    constructor(
        items: Item[],
        repository: InvoiceRepository,
        notificationService: NotificationService,
        printService: PrintService
    ) {
        this.items = items;
        this.total = this.calculateTotal();
        this.repository = repository;
        this.notificationService = notificationService;
        this.printService = printService;
    }
    private calculateTotal(): number {
        return this.items.reduce((sum, item) => sum + item.price, 0);
    }
    public save(): void {
        this.repository.save(this);
    }
    public sendNotification(): void {
        this.notificationService.send(this);
    }
    public print(): void {
        this.printService.print(this);
    }
}
class InvoiceRepository {
    public save(invoice: Invoice): void {
        // Logic to save invoice to database
    }
}
class NotificationService {
    public send(invoice: Invoice): void {
        // Logic to send notification
    }
}
class PrintService {
    public print(invoice: Invoice): void {
        // Logic to print invoice
    }
}
```
Trong ví dụ trên, chúng ta đã tách các chức năng khác nhau của lớp `Invoice` thành các lớp riêng biệt: `InvoiceRepository`, `NotificationService`, và `PrintService`. Mỗi lớp bây giờ chỉ chịu trách nhiệm về một chức năng duy nhất, tuân thủ nguyên tắc SRP. Điều này làm cho mã dễ bảo trì, dễ hiểu và dễ kiểm thử hơn.

## Open/Closed Principle (OCP)
Nguyên tắc này nhấn mạnh rằng các thực thể phần mềm nên được mở để mở rộng nhưng đóng để sửa đổi. Điều này có nghĩa là bạn có thể thêm chức năng mới mà không cần thay đổi mã nguồn hiện có.
Ví dụ:
```ts
class Rectangle {
    constructor(public width: number, public height: number) {}
}
class Circle {
    constructor(public radius: number) {}
}
class AreaCalculator {
    public calculateArea(shapes: (Rectangle | Circle)[]): number {
        return shapes.reduce((total, shape) => {
            if (shape instanceof Rectangle) {
                return total + shape.width * shape.height;
            } else if (shape instanceof Circle) {
                return total + Math.PI * shape.radius * shape.radius;
            }
            return total;
        }, 0);
    }
}
```
Trong ví dụ trên, lớp `AreaCalculator` không tuân thủ nguyên tắc OCP vì nếu chúng ta muốn thêm một hình dạng mới, chẳng hạn như `Triangle`, chúng ta sẽ phải sửa đổi phương thức `calculateArea` để xử lý hình dạng mới này. Điều này vi phạm nguyên tắc OCP vì chúng ta đang thay đổi mã nguồn hiện có để thêm chức năng mới. Điều gì tiếp theo nếu chúng ta muốn thêm hình dạng mới như `Triangle`, `Square`, `Polygon`, v.v. Chúng ta sẽ phải tiếp tục mở rộng phương thức `calculateArea`, dẫn đến mã trở nên phức tạp và khó bảo trì.
Để tuân thủ nguyên tắc OCP, chúng ta có thể sử dụng kế thừa và đa hình để mở rộng chức năng mà không cần sửa đổi mã nguồn hiện có:
```ts
interface Shape {
    area(): number;
}
class Rectangle implements Shape {
    constructor(public width: number, public height: number) {}
    public area(): number {
        return this.width * this.height;
    }
}
class Circle implements Shape {
    constructor(public radius: number) {}
    public area(): number {
        return Math.PI * this.radius * this.radius;
    }
}
class AreaCalculator {
    public calculateArea(shapes: Shape[]): number {
        return shapes.reduce((total, shape) => total + shape.area(), 0);
    }
}
```
Trong ví dụ trên, chúng ta đã tạo một giao diện `Shape` với phương thức `area`. Các lớp `Rectangle` và `Circle` triển khai giao diện này và cung cấp cách tính diện tích riêng của chúng. Lớp `AreaCalculator` bây giờ chỉ cần gọi phương thức `area` của mỗi hình dạng mà không cần biết chi tiết về cách tính diện tích. Khi chúng ta muốn thêm một hình dạng mới, chẳng hạn như `Triangle`, chúng ta chỉ cần tạo một lớp mới triển khai giao diện `Shape` mà không cần sửa đổi mã nguồn của `AreaCalculator`. Điều này tuân thủ nguyên tắc OCP và làm cho mã dễ bảo trì và mở rộng hơn.

Ví dụ chúng ta thêm hình dạng mới như `Triangle` và `Square`, `Polygon`:
```ts
class Triangle implements Shape {
    constructor(public base: number, public height: number) {}
    public area(): number {
        return 0.5 * this.base * this.height;
    }
}
class Square implements Shape {
    constructor(public side: number) {}
    public area(): number {
        return this.side * this.side;
    }
}
class Polygon implements Shape {
    constructor(public sides: number[], public apothem: number) {}
    public area(): number {
        const perimeter = this.sides.reduce((sum, side) => sum + side, 0);
        return (perimeter * this.apothem) / 2;
    }
}


class AreaCalculator {
    public calculateArea(shapes: Shape[]): number {
        return shapes.reduce((total, shape) => total + shape.area(), 0);
    }
}
```

Trong ví dụ trên, chúng ta đã thêm các lớp `Triangle`, `Square`, và `Polygon` mà không cần sửa đổi mã nguồn của lớp `AreaCalculator`. Mỗi lớp mới triển khai giao diện `Shape` và cung cấp cách tính diện tích riêng của chúng. Điều này tuân thủ nguyên tắc OCP và làm cho mã dễ bảo trì và mở rộng hơn.

Tiếp theo với một ví dụ về thuật toán sắp xếp:
```ts
class Sorter {
    public sort(array: number[], algorithm: 'bubble' | 'quick'): number[] {
        if (algorithm === 'bubble') {
            return this.bubbleSort(array);
        } else if (algorithm === 'quick') {
            return this.quickSort(array);
        }
        throw new Error('Unknown sorting algorithm');
    }
    private bubbleSort(array: number[]): number[] {
        // Implementation of bubble sort
        return array;
    }
    private quickSort(array: number[]): number[] {
        // Implementation of quick sort
        return array;
    }
}
```
Trong ví dụ trên, lớp `Sorter` không tuân thủ nguyên tắc OCP vì nếu chúng ta muốn thêm một thuật toán sắp xếp mới, chẳng hạn như `merge sort`, chúng ta sẽ phải sửa đổi phương thức `sort` để xử lý thuật toán mới này. Điều này vi phạm nguyên tắc OCP vì chúng ta đang thay đổi mã nguồn hiện có để thêm chức năng mới.
Để tuân thủ nguyên tắc OCP, chúng ta có thể sử dụng kế thừa và đa hình để mở rộng chức năng mà không cần sửa đổi mã nguồn hiện có:
```ts
interface SortAlgorithm {
    sort(array: number[]): number[];
}
class BubbleSort implements SortAlgorithm {
    public sort(array: number[]): number[] {
        // Implementation of bubble sort
        return array;
    }
}
class QuickSort implements SortAlgorithm {
    public sort(array: number[]): number[] {
        // Implementation of quick sort
        return array;
    }
}
class Sorter {
    public sort(array: number[], algorithm: SortAlgorithm): number[] {
        return algorithm.sort(array);
    }
}
```
Trong ví dụ trên, chúng ta đã tạo một giao diện `SortAlgorithm` với phương thức `sort`. Các lớp `BubbleSort` và `QuickSort` triển khai giao diện này và cung cấp cách sắp xếp riêng của chúng. Lớp `Sorter` bây giờ chỉ cần gọi phương thức `sort` của thuật toán mà không cần biết chi tiết về cách sắp xếp. Khi chúng ta muốn thêm một thuật toán sắp xếp mới, chẳng hạn như `MergeSort`, chúng ta chỉ cần tạo một lớp mới triển khai giao diện `SortAlgorithm` mà không cần sửa đổi mã nguồn của `Sorter`. Điều này tuân thủ nguyên tắc OCP và làm cho mã dễ bảo trì và mở rộng hơn.
Ví dụ chúng ta thêm thuật toán sắp xếp mới như `MergeSort`, `BucketSort`:
```ts
class MergeSort implements SortAlgorithm {
    public sort(array: number[]): number[] {
        // Implementation of merge sort
        return array;
    }
}
class BucketSort implements SortAlgorithm {
    public sort(array: number[]): number[] {
        // Implementation of bucket sort
        return array;
    }
}
class Sorter {
    public sort(array: number[], algorithm: SortAlgorithm): number[] {
        return algorithm.sort(array);
    }
}
```
Trong ví dụ trên, chúng ta đã thêm các lớp `MergeSort` và `BucketSort` mà không cần sửa đổi mã nguồn của lớp `Sorter`. Mỗi lớp mới triển khai giao diện `SortAlgorithm` và cung cấp cách sắp xếp riêng của chúng. Điều này tuân thủ nguyên tắc OCP và làm cho mã dễ bảo trì và mở rộng hơn.

## Liskov Substitution Principle (LSP)
Nguyên tắc này nhấn mạnh rằng các đối tượng của một lớp con nên có thể thay thế các đối tượng của lớp cha mà không làm thay đổi tính đúng đắn của chương trình. Nói cách khác, lớp con phải tuân thủ hợp đồng của lớp cha.
Ví dụ:
```ts
class Bird {
    public fly(): void {
        console.log('Flying');
    }
}
class Sparrow extends Bird {}
class Ostrich extends Bird {}
```
Trong ví dụ trên, lớp `Ostrich` không tuân thủ nguyên tắc LSP vì đà điểu không thể bay. Nếu chúng ta gọi phương thức `fly` trên một đối tượng `Ostrich`, nó sẽ không hoạt động đúng như mong đợi. Điều này vi phạm nguyên tắc LSP vì lớp con `Ostrich` không thể thay thế lớp cha `Bird` một cách an toàn.
Để tuân thủ nguyên tắc LSP, chúng ta có thể tách lớp `Bird` thành các lớp riêng biệt cho các loại chim có thể bay và không thể bay:
```ts
class Bird {}
class FlyingBird extends Bird {
    public fly(): void {
        console.log('Flying');
    }
}
class Sparrow extends FlyingBird {}
class Ostrich extends Bird {}
```
Trong ví dụ trên, chúng ta đã tạo một lớp `FlyingBird` cho các loại chim có thể bay. Lớp `Sparrow` kế thừa từ `FlyingBird` và có thể bay, trong khi lớp `Ostrich` kế thừa từ `Bird` và không có phương thức `fly`. Bây giờ, chúng ta có thể thay thế các đối tượng của lớp cha một cách an toàn mà không làm thay đổi tính đúng đắn của chương trình, tuân thủ nguyên tắc LSP.
Ví dụ khác về nguyên tắc LSP:
```ts
class Rectangle {
    constructor(public width: number, public height: number) {}
    public setWidth(width: number): void {
        this.width = width;
    }
    public setHeight(height: number): void {
        this.height = height;
    }
    public getArea(): number {
        return this.width * this.height;
    }
}
class Square extends Rectangle {
    constructor(side: number) {
        super(side, side);
    }
    public setWidth(width: number): void {
        this.width = width;
        this.height = width;
    }
    public setHeight(height: number): void {
        this.height = height;
        this.width = height;
    }
}
```
Trong ví dụ trên, lớp `Square` không tuân thủ nguyên tắc LSP vì nó thay đổi hành vi của các phương thức `setWidth` và `setHeight` so với lớp cha `Rectangle`. Nếu chúng ta sử dụng một đối tượng `Square` thay cho một đối tượng `Rectangle`, chúng ta có thể gặp phải các vấn đề không mong muốn khi tính diện tích. Điều này vi phạm nguyên tắc LSP vì lớp con `Square` không thể thay thế lớp cha `Rectangle` một cách an toàn.
Để tuân thủ nguyên tắc LSP, chúng ta có thể tách lớp `Rectangle` và `Square` thành các lớp riêng biệt mà không sử dụng kế thừa:
```ts
class Rectangle {
    constructor(public width: number, public height: number) {}
    public getArea(): number {
        return this.width * this.height;
    }
}
class Square {
    constructor(public side: number) {}
    public getArea(): number {
        return this.side * this.side;
    }
}
```
Trong ví dụ trên, chúng ta đã tách lớp `Rectangle` và `Square` thành các lớp riêng biệt mà không sử dụng kế thừa. Bây giờ, chúng ta có thể sử dụng các đối tượng của cả hai lớp một cách an toàn mà không làm thay đổi tính đúng đắn của chương trình, tuân thủ nguyên tắc LSP.

## Interface Segregation Principle (ISP)
Nguyên tắc này nhấn mạnh rằng nên tạo ra các giao diện nhỏ và chuyên biệt thay vì các giao diện lớn và đa năng. Điều này giúp các lớp chỉ cần triển khai những phương thức mà chúng thực sự sử dụng.
Ví dụ:
```ts
interface Worker {
    work(): void;
    eat(): void;
}
class HumanWorker implements Worker {
    public work(): void {
        console.log('Working');
    }
    public eat(): void {
        console.log('Eating');
    }
}
class RobotWorker implements Worker {
    public work(): void {
        console.log('Working');
    }
    public eat(): void {
        throw new Error('Robots do not eat');
    }
}
```
Trong ví dụ trên, giao diện `Worker` không tuân thủ nguyên tắc ISP vì lớp `RobotWorker` phải triển khai phương thức `eat`, mặc dù nó không cần thiết và không hợp lý đối với một robot. Điều này vi phạm nguyên tắc ISP vì các lớp bị ép buộc phải triển khai các phương thức mà chúng không sử dụng.
Để tuân thủ nguyên tắc ISP, chúng ta có thể tách giao diện `Worker` thành các giao diện riêng biệt cho các chức năng khác nhau:
```ts
interface Workable {
    work(): void;
}
interface Eatable {
    eat(): void;
}
class HumanWorker implements Workable, Eatable {
    public work(): void {
        console.log('Working');
    }
    public eat(): void {
        console.log('Eating');
    }
}
class RobotWorker implements Workable {
    public work(): void {
        console.log('Working');
    }
}
```
Trong ví dụ trên, chúng ta đã tách giao diện `Worker` thành hai giao diện riêng biệt: `Workable` và `Eatable`. Lớp `HumanWorker` triển khai cả hai giao diện, trong khi lớp `RobotWorker` chỉ triển khai giao diện `Workable`. Bây giờ, các lớp chỉ cần triển khai những phương thức mà chúng thực sự sử dụng, tuân thủ nguyên tắc ISP.

Thêm một ví dụ khác về nguyên tắc ISP:
```ts
interface Printer {
    print(document: Document): void;
    fax(document: Document): void;
    scan(document: Document): void;
}
class MultiFunctionPrinter implements Printer {
    public print(document: Document): void {
        console.log('Printing document');
    }
    public fax(document: Document): void {
        console.log('Faxing document');
    }
    public scan(document: Document): void {
        console.log('Scanning document');
    }
}
class SimplePrinter implements Printer {
    public print(document: Document): void {
        console.log('Printing document');
    }
    public fax(document: Document): void {
        throw new Error('SimplePrinter cannot fax');
    }
    public scan(document: Document): void {
        throw new Error('SimplePrinter cannot scan');
    }
}
```
Trong ví dụ trên, giao diện `Printer` không tuân thủ nguyên tắc ISP vì lớp `SimplePrinter` phải triển khai các phương thức `fax` và `scan`, mặc dù nó không cần thiết và không hợp lý đối với một máy in đơn giản. Điều này vi phạm nguyên tắc ISP vì các lớp bị ép buộc phải triển khai các phương thức mà chúng không sử dụng.
Để tuân thủ nguyên tắc ISP, chúng ta có thể tách giao diện `Printer` thành các giao diện riêng biệt cho các chức năng khác nhau:
```ts
interface Printable {
    print(document: Document): void;
}
interface Faxable {
    fax(document: Document): void;
}
interface Scannable {
    scan(document: Document): void;
}
class MultiFunctionPrinter implements Printable, Faxable, Scannable {
    public print(document: Document): void {
        console.log('Printing document');
    }
    public fax(document: Document): void {
        console.log('Faxing document');
    }
    public scan(document: Document): void {
        console.log('Scanning document');
    }
}
class SimplePrinter implements Printable {
    public print(document: Document): void {
        console.log('Printing document');
    }
}
```
Trong ví dụ trên, chúng ta đã tách giao diện `Printer` thành ba giao diện riêng biệt: `Printable`, `Faxable`, và `Scannable`. Lớp `MultiFunctionPrinter` triển khai cả ba giao diện, trong khi lớp `SimplePrinter` chỉ triển khai giao diện `Printable`. Bây giờ, các lớp chỉ cần triển khai những phương thức mà chúng thực sự sử dụng, tuân thủ nguyên tắc ISP.

## Dependency Inversion Principle (DIP)
Nguyên tắc này nhấn mạnh rằng các mô-đun cấp cao không nên phụ thuộc vào các mô-đun cấp thấp; cả hai nên phụ thuộc vào các trừu tượng. Ngoài ra, các trừu tượng không nên phụ thuộc vào chi tiết; chi tiết nên phụ thuộc vào các trừu tượng.
Ví dụ:
```ts
class MySQLDatabase {
    public connect(): void {
        console.log('Connecting to MySQL database');
    }
}
class UserService {
    private database: MySQLDatabase;
    constructor() {
        this.database = new MySQLDatabase();
    }
    public getUser(id: number): void {
        this.database.connect();
        console.log(`Getting user with id: ${id}`);
    }
}
```
Trong ví dụ trên, lớp `UserService` phụ thuộc trực tiếp vào lớp `MySQLDatabase`, một mô-đun cấp thấp. Điều này vi phạm nguyên tắc DIP vì các mô-đun cấp cao (`UserService`) không nên phụ thuộc vào các mô-đun cấp thấp (`MySQLDatabase`).
Để tuân thủ nguyên tắc DIP, chúng ta có thể sử dụng một giao diện trừu tượng để tách rời sự phụ thuộc giữa các mô-đun cấp cao và cấp thấp:
```ts
interface Database {
    connect(): void;
}
class MySQLDatabase implements Database {
    public connect(): void {
        console.log('Connecting to MySQL database');
    }
}
class UserService {
    private database: Database;
    constructor(database: Database) {
        this.database = database;
    }
    public getUser(id: number): void {
        this.database.connect();
        console.log(`Getting user with id: ${id}`);
    }
}
```
Trong ví dụ trên, chúng ta đã tạo một giao diện `Database` để trừu tượng hóa cơ sở dữ liệu. Lớp `MySQLDatabase` triển khai giao diện này. Lớp `UserService` bây giờ phụ thuộc vào giao diện `Database` thay vì lớp `MySQLDatabase`. Khi chúng ta muốn thay đổi cơ sở dữ liệu, chẳng hạn như sử dụng `PostgreSQLDatabase`, chúng ta chỉ cần tạo một lớp mới triển khai giao diện `Database` mà không cần sửa đổi mã nguồn của `UserService`. Điều này tuân thủ nguyên tắc DIP và làm cho mã dễ bảo trì và mở rộng hơn.
Ví dụ chúng ta thêm cơ sở dữ liệu mới như `PostgreSQLDatabase`, `MongoDBDatabase`:
```ts
class PostgreSQLDatabase implements Database {
    public connect(): void {
        console.log('Connecting to PostgreSQL database');
    }
}
class MongoDBDatabase implements Database {
    public connect(): void {
        console.log('Connecting to MongoDB database');
    }
}
class UserService {
    private database: Database;
    constructor(database: Database) {
        this.database = database;
    }
    public getUser(id: number): void {
        this.database.connect();
        console.log(`Getting user with id: ${id}`);
    }
}
```
Trong ví dụ trên, chúng ta đã thêm các lớp `PostgreSQLDatabase` và `MongoDBDatabase` mà không cần sửa đổi mã nguồn của lớp `UserService`. Mỗi lớp mới triển khai giao diện `Database` và cung cấp cách kết nối riêng của chúng. Điều này tuân thủ nguyên tắc DIP và làm cho mã dễ bảo trì và mở rộng hơn.

Thêm một ví dụ khác về nguyên tắc DIP:
```ts
class EmailService {
    public sendEmail(to: string, subject: string, body: string): void {
        console.log(`Sending email to ${to}`);
    }

}
class NotificationService {
    private emailService: EmailService;
    constructor() {
        this.emailService = new EmailService();
    }
    public sendNotification(to: string, message: string): void {
        this.emailService.sendEmail(to, 'Notification', message);
    }
}
```
Trong ví dụ trên, lớp `NotificationService` phụ thuộc trực tiếp vào lớp `EmailService`, một mô-đun cấp thấp. Điều này vi phạm nguyên tắc DIP vì các mô-đun cấp cao (`NotificationService`) không nên phụ thuộc vào các mô-đun cấp thấp (`EmailService`).
Để tuân thủ nguyên tắc DIP, chúng ta có thể sử dụng một giao diện trừu tượng để tách rời sự phụ thuộc giữa các mô-đun cấp cao và cấp thấp:
```ts
interface MessageService {
    sendMessage(to: string, subject: string, body: string): void;
}
class EmailService implements MessageService {
    public sendMessage(to: string, subject: string, body: string): void {
        console.log(`Sending email to ${to}`);
    }
}
class NotificationService {
    private messageService: MessageService;
    constructor(messageService: MessageService) {
        this.messageService = messageService;
    }
    public sendNotification(to: string, message: string): void {
        this.messageService.sendMessage(to, 'Notification', message);
    }
}
```
Trong ví dụ trên, chúng ta đã tạo một giao diện `MessageService` để trừu tượng hóa dịch vụ gửi tin nhắn. Lớp `EmailService` triển khai giao diện này. Lớp `NotificationService` bây giờ phụ thuộc vào giao diện `MessageService` thay vì lớp `EmailService`. Khi chúng ta muốn thay đổi dịch vụ gửi tin nhắn, chẳng hạn như sử dụng `SMSService`, chúng ta chỉ cần tạo một lớp mới triển khai giao diện `MessageService` mà không cần sửa đổi mã nguồn của `NotificationService`. Điều này tuân thủ nguyên tắc DIP và làm cho mã dễ bảo trì và mở rộng hơn. 

Ví dụ chúng ta thêm dịch vụ gửi tin nhắn mới như `SMSService`, `PushNotificationService`:
```ts
class SMSService implements MessageService {
    public sendMessage(to: string, subject: string, body: string): void {
        console.log(`Sending SMS to ${to}`);
    }
}
class PushNotificationService implements MessageService {
    public sendMessage(to: string, subject: string, body: string): void {
        console.log(`Sending push notification to ${to}`);
    }
}
class NotificationService {
    private messageService: MessageService;
    constructor(messageService: MessageService) {
        this.messageService = messageService;
    }
    public sendNotification(to: string, message: string): void {
        this.messageService.sendMessage(to, 'Notification', message);
    }
}
```
Trong ví dụ trên, chúng ta đã thêm các lớp `SMSService` và `PushNotificationService` mà không cần sửa đổi mã nguồn của lớp `NotificationService`. Mỗi lớp mới triển khai giao diện `MessageService` và cung cấp cách gửi tin nhắn riêng của chúng. Điều này tuân thủ nguyên tắc DIP và làm cho mã dễ bảo trì và mở rộng hơn.

# Kết luận
Nguyên tắc SOLID là những hướng dẫn quan trọng giúp các nhà phát triển thiết kế phần mềm một cách hiệu quả và bền vững. Bằng cách tuân thủ các nguyên tắc này, chúng ta có thể tạo ra các hệ thống dễ bảo trì, mở rộng và hiểu rõ hơn. Việc áp dụng SOLID không chỉ giúp cải thiện chất lượng mã nguồn mà còn giúp giảm thiểu rủi ro và chi phí bảo trì trong quá trình phát triển phần mềm. Hãy luôn nhớ rằng, thiết kế phần mềm tốt không chỉ là về việc viết mã, mà còn là về việc tạo ra các hệ thống có thể phát triển và thích nghi với những thay đổi trong tương lai.

# Lời cảm ơn
Cảm ơn ChatGPT, Claude Sonnet 4.5 đã hỗ trợ tôi trong việc hoàn thành tài liệu này. Thanks for all AI tools!
