# Application Startup Flow & Dependency Injection

## 📋 Table of Contents
- [Overview](#overview)
- [Phase 1: Application Bootstrap](#phase-1-application-bootstrap-)
- [Phase 2: Module Loading](#phase-2-module-loading-)
- [Phase 3: Config Services Initialization](#phase-3-config-services-initialization-)
- [Phase 4: Database Connection](#phase-4-database-connection-)
- [Phase 5: Other Modules DI](#phase-5-other-modules-dependency-injection-)
- [Phase 6: Lifecycle Hooks](#phase-6-lifecycle-hooks-execution-)
- [Phase 7: Runtime](#phase-7-runtime---config-access-)
- [Console Output Timeline](#-console-output-timeline)
- [Architecture Diagrams](#-architecture-diagrams)

---

## Overview

Tài liệu này mô tả chi tiết flow khởi động ứng dụng NestJS khi chạy `npm run start:dev`, bao gồm:
- Quá trình load configuration từ `.env` và AWS
- Dependency Injection của các config services
- Lifecycle hooks và timing
- Runtime config access pattern

---

## Phase 1: Application Bootstrap 🚀

```bash
npm run start:dev
    ↓
nest start --watch
    ↓
TypeScript Compilation (tsconfig.json)
    ↓
Execute: dist/main.js
```

### main.ts Entry Point

```typescript
// src/main.ts
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  //           ↑ Trigger toàn bộ module loading chain
  
  const appConfig = app.get(AppConfig);
  //    ↑ Get AppConfig từ DI container (đã được khởi tạo)
  
  // Setup CORS
  app.enableCors({
    origin: appConfig.corsOrigin,  // Từ .env: CORS_ORIGIN
    credentials: true,
  });
  
  // Setup Swagger documentation
  SwaggerConfig.setup(app);
  
  // Start server
  await app.listen(appConfig.port);  // Từ .env: PORT
  
  console.log('🚀 Application is running on:', await app.getUrl());
  console.log('📚 Swagger documentation:', SwaggerConfig.getDocumentationUrl());
}
bootstrap();
```

**Timing:** ~0ms

---

## Phase 2: Module Loading 🏗️

### AppModule Import Order

```typescript
// src/app.module.ts
@Module({
  imports: [
    // 1️⃣ Load FIRST - Đọc .env file
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
    }),

    // 2️⃣ Database connection - Cần DatabaseConfigService
    TypeOrmModule.forRootAsync({
      useFactory: async (dbConfigService: DatabaseConfigService) => {
        const { database, host, port, username, password, ssl } =
          dbConfigService.getDatabaseConfig();
        
        return {
          type: 'postgres',
          host,      // localhost (dev) hoặc từ AWS SSM (prod)
          port,      // 5432
          username,  // postgres (dev) hoặc từ AWS Secrets (prod)
          password,  // pass (dev) hoặc từ AWS Secrets (prod)
          database,  // test (dev)
          ssl: ssl ? { rejectUnauthorized: false } : false,
          entities: [Brand, BrandImage, ...],
          synchronize: false,
          logging: process.env.NODE_ENV === 'development',
        };
      },
      inject: [DatabaseConfigService],  // ← DI declaration
    }),

    // 3️⃣ Global config module
    InfrastructureModule,

    // 4️⃣ Feature modules
    CommonModule,
    HealthModule,
    AuthModule,
    BrandsModule,
    StoresModule,
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(TenantMiddleware).forRoutes('*');
  }
}
```

**Loading Order:**
1. ✅ ConfigModule → Load .env vào process.env
2. ✅ InfrastructureModule → Khởi tạo config services
3. ✅ TypeOrmModule → Inject DatabaseConfigService
4. ✅ Feature Modules → Inject các config services cần thiết

**Timing:** ~25ms

---

## Phase 3: Config Services Initialization ⚙️

### InfrastructureModule Structure

```typescript
// src/modules/infrastructure.module.ts
@Global()  // ← Quan trọng! Providers available globally
@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
  ],
  providers: [
    AppConfig,
    CognitoConfigService,
    DatabaseConfigService,
    S3ConfigService,
  ],
  exports: [
    AppConfig,
    CognitoConfigService,
    DatabaseConfigService,
    S3ConfigService,
  ],
})
export class InfrastructureModule {}
```

### 3.1 ConfigModule.forRoot() Process

```
Step 1: Đọc file .env hoặc .env.local
    ↓
Step 2: Parse content thành key-value pairs
    ↓
Step 3: Inject vào process.env
    ↓
Step 4: Tạo ConfigService instance (singleton, global)
```

**Example .env:**
```bash
NODE_ENV=development
PORT=3000
CORS_ORIGIN=*

# Database
DB_HOST=localhost
DB_PORT=5432
DB_DATABASE=test
DB_USERNAME=postgres
DB_PASSWORD=pass
DB_SSL=false

# AWS
AWS_REGION=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ENV_SUFFIX=dev

# S3
AWS_S3_BUCKET=public-bucket
AWS_S3_BUCKET_PRIVATE=private-bucket
```

### 3.2 AppConfig Initialization

```typescript
// src/infrastructure/config/AppConfig.ts
@Injectable()
export class AppConfig {
  constructor(private configService: ConfigService) {}
  //          ↑ NestJS tự động inject ConfigService

  get nodeEnv(): string {
    return this.configService.get<string>('NODE_ENV', 'development');
  }

  get isDevelopment(): boolean {
    return this.nodeEnv === 'development';
  }

  get port(): number {
    return this.configService.get<number>('PORT', 3000);
  }

  get corsOrigin(): string {
    return this.configService.get<string>('CORS_ORIGIN', '*');
  }

  get envSuffix(): string {
    return this.configService.get<string>('ENV_SUFFIX', 'dev');
  }

  get awsRegion(): string {
    return this.configService.get<string>('AWS_REGION', 'ap-northeast-1');
  }
}
```

**DI Flow:**
```
NestJS DI Container
    ↓
Tìm ConfigService (đã tạo bởi ConfigModule)
    ↓
Inject vào AppConfig constructor
    ↓
AppConfig instance được tạo
    ↓
Store trong DI Container với scope SINGLETON
```

### 3.3 DatabaseConfigService Initialization

```typescript
// src/infrastructure/config/DatabaseConfigService.ts
@Injectable()
export class DatabaseConfigService implements OnModuleInit {
  private databaseConfig: DatabaseConfig | null = null;
  private readonly CACHE_TTL_MS = 30 * 60 * 1000; // 30 minutes
  
  private ssmClient: SSMClient;
  private secretsClient: SecretsManagerClient;

  constructor(private configService: ConfigService) {
    const region = this.configService.get<string>('AWS_REGION', 'ap-northeast-1');
    
    // Setup AWS clients
    this.ssmClient = new SSMClient({
      region,
      credentials: {
        accessKeyId: this.configService.get<string>('AWS_ACCESS_KEY_ID')!,
        secretAccessKey: this.configService.get<string>('AWS_SECRET_ACCESS_KEY')!,
      }
    });

    this.secretsClient = new SecretsManagerClient({ region, credentials: {...} });
    
    // ⚠️ CRITICAL: Load config IMMEDIATELY for development
    // Vì TypeOrmModule.forRootAsync cần config ngay trong constructor phase
    const nodeEnv = this.configService.get<string>('NODE_ENV', 'development');
    if (nodeEnv === 'development') {
      this.databaseConfig = {
        host: this.configService.get<string>('DB_HOST', 'localhost'),
        port: this.configService.get<number>('DB_PORT', 5432),
        database: this.configService.get<string>('DB_DATABASE', 'test'),
        username: this.configService.get<string>('DB_USERNAME', 'postgres'),
        password: this.configService.get<string>('DB_PASSWORD', 'pass'),
        ssl: this.configService.get<string>('DB_SSL', 'false') === 'true',
      };
    }
  }

  async onModuleInit() {
    // Gọi SAU khi tất cả modules đã initialized
    await this.loadConfig();

    // Auto-refresh every 30 minutes
    setInterval(() => {
      this.loadConfig().catch((error) => {
        this.logger.error('Failed to refresh database configs', error);
      });
    }, this.CACHE_TTL_MS);
  }

  private async loadConfig(): Promise<void> {
    const nodeEnv = this.configService.get<string>('NODE_ENV', 'development');

    if (nodeEnv === 'development') {
      this.logger.log('Using development database config from .env');
      return;
    }

    // Production: Load từ AWS Parameter Store & Secrets Manager
    try {
      this.logger.log('Loading database configs from AWS...');
      
      const dbInfo = await this.loadFromParameterStore();
      const credentials = await this.loadCredentialsFromSecretsManager();
      
      this.databaseConfig = { ...dbInfo, ...credentials };
    } catch (error) {
      if (this.databaseConfig) {
        this.logger.warn('Failed to refresh config, using cached values');
      } else {
        throw new Error(`Cannot load database config: ${error.message}`);
      }
    }
  }

  private async loadFromParameterStore(): Promise<Omit<DatabaseConfig, 'username' | 'password'>> {
    const parameterPath = `/rakuten-payment/dev/database`;
    // Fetch từ AWS SSM Parameter Store
    // Parse JSON response
    // Return { host, port, database, ssl }
  }

  private async loadCredentialsFromSecretsManager(): Promise<Pick<DatabaseConfig, 'username' | 'password'>> {
    const secretName = `/rakuten-payment/dev/database/credentials`;
    // Fetch từ AWS Secrets Manager
    // Parse JSON response
    // Return { username, password }
  }

  getDatabaseConfig(): DatabaseConfig {
    if (!this.databaseConfig) {
      // Fallback to .env values
      this.logger.warn('Database config not loaded yet, using defaults');
      return {
        host: this.configService.get<string>('DB_HOST', 'localhost'),
        port: this.configService.get<number>('DB_PORT', 5432),
        database: this.configService.get<string>('DB_DATABASE', 'test'),
        username: this.configService.get<string>('DB_USERNAME', 'postgres'),
        password: this.configService.get<string>('DB_PASSWORD', 'pass'),
        ssl: this.configService.get<string>('DB_SSL', 'false') === 'true',
      };
    }
    return this.databaseConfig;
  }
}
```

**Timeline:**
```
[Constructor Phase - Synchronous]
  ConfigService injected
  ↓
  AWS SSM & Secrets Manager clients created
  ↓
  IF development → Load config từ .env NGAY LẬP TỨC
  ↓
  DatabaseConfigService instance ready

[OnModuleInit Phase - Asynchronous]
  onModuleInit() called AFTER all modules loaded
  ↓
  IF production → loadConfig() from AWS
  ↓
  Setup auto-refresh timer (30 minutes)
```

### 3.4 CognitoConfigService Initialization

```typescript
// src/infrastructure/config/CognitoConfigService.ts
@Injectable()
export class CognitoConfigService implements OnModuleInit {
  private userPoolConfigs: UserPoolConfig[] = [];
  private readonly CACHE_TTL_MS = 30 * 60 * 1000;
  private ssmClient: SSMClient;

  constructor(private configService: ConfigService) {
    const region = this.configService.get<string>('AWS_REGION', 'ap-northeast-1');
    
    this.ssmClient = new SSMClient({
      region,
      credentials: {
        accessKeyId: this.configService.get<string>('AWS_ACCESS_KEY_ID')!,
        secretAccessKey: this.configService.get<string>('AWS_SECRET_ACCESS_KEY')!,
      }
    });
  }

  async onModuleInit() {
    await this.loadUserPools();

    // Auto-refresh every 30 minutes
    setInterval(() => {
      this.loadUserPools().catch((error) => {
        this.logger.error('Failed to refresh Cognito configs', error);
      });
    }, this.CACHE_TTL_MS);
  }

  private async loadUserPools(): Promise<void> {
    const nodeEnv = this.configService.get<string>('NODE_ENV', 'development');

    if (nodeEnv === 'development') {
      this.logger.log('Loading Cognito configs for development mode...');
      
      // Hardcoded development user pools
      this.userPoolConfigs = [
        {
          userPoolId: '',
          clientId: '',
          clientSecret: '',
          tenant: '',
        },
        {
          userPoolId: '',
          clientId: '',
          clientSecret: '',
          tenant: '',
        },
      ];
      
      this.logConfig();
      return;
    }

    // Production: Load từ AWS Parameter Store
    try {
      this.logger.log('Loading Cognito configs from AWS Parameter Store...');
      const configs = await this.loadFromParameterStore();
      this.userPoolConfigs = configs;
      this.logConfig();
    } catch (error) {
      if (this.userPoolConfigs.length > 0) {
        this.logger.warn('Failed to refresh Cognito configs, using cached values');
      } else {
        throw new Error(`Cannot load Cognito configs: ${error.message}`);
      }
    }
  }

  private async loadFromParameterStore(): Promise<UserPoolConfig[]> {
    const parameterPath = `/rakuten-payment/dev/cognito`;
    // Fetch từ AWS SSM Parameter Store
    // Parse JSON: [{ userPoolId, clientId, clientSecret, tenant }, ...]
    // Return UserPoolConfig[]
  }

  findByTenant(tenant: string): UserPoolConfig | undefined {
    return this.userPoolConfigs.find((c) => c.tenant === tenant);
  }

  isValidTenant(tenant: string): boolean {
    return this.userPoolConfigs.some((c) => c.tenant === tenant);
  }

  getUserPoolConfigs(): UserPoolConfig[] {
    return this.userPoolConfigs;
  }

  logConfig(): void {
    this.logger.log('Cognito User Pool Configuration:');
    this.userPoolConfigs.forEach((pool) => {
      this.logger.log(`  Tenant: ${pool.tenant}`);
      this.logger.log(`    User Pool ID: ${pool.userPoolId}`);
      this.logger.log(`    Client ID: ${pool.clientId}`);
    });
  }
}
```

### 3.5 S3ConfigService Initialization

```typescript
// src/infrastructure/config/S3ConfigService.ts
@Injectable()
export class S3ConfigService {
  constructor(private configService: ConfigService) {}

  get region(): string {
    return this.configService.get<string>('AWS_REGION');
  }

  get accessKeyId(): string {
    return this.configService.get<string>('AWS_ACCESS_KEY_ID');
  }

  get secretAccessKey(): string {
    return this.configService.get<string>('AWS_SECRET_ACCESS_KEY');
  }

  get bucket(): string {
    return this.configService.get<string>('AWS_S3_BUCKET');
  }

  get bucketPrivate(): string {
    return this.configService.get<string>('AWS_S3_BUCKET_PRIVATE', 'private-bucket');
  }

  getS3Config() {
    return {
      region: this.region,
      credentials: {
        accessKeyId: this.accessKeyId,
        secretAccessKey: this.secretAccessKey,
      },
    };
  }
}
```

**Timing:** ~2ms

---

## Phase 4: Database Connection 🗄️

### TypeORM Async Configuration

```typescript
// src/app.module.ts
TypeOrmModule.forRootAsync({
  useFactory: async (
    dbConfigService: DatabaseConfigService,
    //              ↑ NestJS inject DatabaseConfigService từ InfrastructureModule
  ): Promise<TypeOrmModuleOptions> => {
    // Gọi getDatabaseConfig() để lấy config
    const { database, host, port, username, password, ssl } =
      dbConfigService.getDatabaseConfig();
    
    return {
      type: 'postgres',
      host,        // 'localhost' (dev)
      port,        // 5432
      username,    // 'postgres' (dev)
      password,    // 'pass' (dev)
      database,    // 'test' (dev)
      ssl: ssl ? { rejectUnauthorized: false } : false,
      entities: [Brand, BrandImage, Flyer, ...],
      synchronize: false,
      logging: process.env.NODE_ENV === 'development',
    };
  },
  inject: [DatabaseConfigService],  // ← Dependency declaration
})
```

**Execution Flow:**
```
NestJS DI Container
    ↓
Tìm DatabaseConfigService (từ InfrastructureModule @Global)
    ↓
Inject vào useFactory function parameter
    ↓
Execute useFactory function
    ↓
Call dbConfigService.getDatabaseConfig()
    ↓
Return config object (đã load ở constructor cho dev)
    ↓
useFactory return TypeOrmModuleOptions
    ↓
TypeORM khởi tạo connection pool
    ↓
Query: SELECT version()
    ↓
Query: SELECT * FROM current_schema()
    ↓
Connection ready ✅
```

**Timing:** ~40ms (bao gồm database connection handshake)

---

## Phase 5: Other Modules Dependency Injection 📦

### Example 1: BrandsModule - S3FileStorage

```typescript
// src/modules/brand/brands.module.ts
@Module({
  imports: [TypeOrmModule.forFeature([Brand]), AuthModule],
  controllers: [BrandsController],
  providers: [
    CreateBrandUseCase,
    GetAllBrandUseCase,
    GetDetailBrandUseCase,
    
    // File Storage Provider
    {
      provide: INFRA_TOKENS.FILE_STORAGE,
      useFactory: (s3Config: S3ConfigService) => {
        //          ↑ NestJS inject S3ConfigService
        return new S3FileStorage(s3Config);
        //                       ↑ Pass vào constructor
      },
      inject: [S3ConfigService],  // ← Dependency from InfrastructureModule
    },
    
    // Repository Provider
    {
      provide: REPOSITORY_TOKENS.BRAND_REPOSITORY,
      useFactory: (dataSource: DataSource) => {
        const schema = TenantContextService.getTenantSchema();
        return new BrandRepository(dataSource, schema);
      },
      inject: [DataSource],
      scope: Scope.REQUEST,  // ← New instance per request
    },
  ],
})
export class BrandsModule {}
```

**S3FileStorage Constructor:**
```typescript
// src/infrastructure/file-storage/S3FileStorage.ts
export default class S3FileStorage implements IFileStorage {
  private s3: S3Client;

  constructor(private s3Config: S3ConfigService) {
    //          ↑ S3ConfigService được inject
    
    // Khởi tạo S3 Client với config
    this.s3 = new S3Client(this.s3Config.getS3Config());
    //                     ↑ { region, credentials: { accessKeyId, secretAccessKey } }
  }

  async generatePutPresignedUrl(key: string, contentType: string): Promise<string> {
    const params = {
      Bucket: this.s3Config.bucketPrivate,  // ← Từ S3ConfigService
      Key: key,
      ContentType: contentType,
    };
    
    const command = new PutObjectCommand(params);
    return await getSignedUrl(this.s3, command, { expiresIn: 60 });
  }

  async generateGetPresignedUrl(key: string) {
    const params = {
      Bucket: this.s3Config.bucket,  // ← Từ S3ConfigService
      Key: key,
    };
    
    const command = new GetObjectCommand(params);
    return await getSignedUrl(this.s3, command, { expiresIn: 60 });
  }
}
```

### Example 2: AuthModule - LoginUserUseCase

```typescript
// src/modules/auth/use-case/LoginUserUseCase.ts
@Injectable()
export default class LoginUserUsecase {
  private cognitoClient: CognitoIdentityProviderClient;

  constructor(private cognitoConfig: CognitoConfigService) {
    //          ↑ CognitoConfigService được inject từ InfrastructureModule
    
    const region = process.env.AWS_REGION;
    this.cognitoClient = new CognitoIdentityProviderClient({ region });
  }

  async execute(loginDto: LoginUserRequest, tenant: string) {
    // Lấy config cho tenant cụ thể
    const poolConfig: UserPoolConfig = this.cognitoConfig.findByTenant(tenant);
    //                                  ↑ Đã load ở onModuleInit()
    
    if (!poolConfig) {
      throw new InvalidTenantException();
    }

    // Sử dụng poolConfig để authenticate
    const authCommand = new InitiateAuthCommand({
      AuthFlow: 'USER_PASSWORD_AUTH',
      ClientId: poolConfig.clientId,
      AuthParameters: {
        USERNAME: loginDto.email,
        PASSWORD: loginDto.password,
        SECRET_HASH: calculateSecretHash(
          loginDto.email,
          poolConfig.clientId,
          poolConfig.clientSecret,
        ),
      },
    });

    const authResponse = await this.cognitoClient.send(authCommand);
    // ...
  }
}
```

### Example 3: Middleware - TenantMiddleware

```typescript
// src/shared/middleware/tenant.middleware.ts
@Injectable()
export class TenantMiddleware implements NestMiddleware {
  constructor(private cognitoConfig: CognitoConfigService) {}
  //          ↑ CognitoConfigService được inject

  async use(req: Request, res: Response, next: NextFunction) {
    const tenantId = req.headers['x-tenant-id'] as string;

    if (!tenantId) {
      throw new BadRequestException('Missing X-Tenant-Id header');
    }

    // Validate tenant
    if (!this.cognitoConfig.isValidTenant(tenantId)) {
      //   ↑ Check tenant có trong config không
      throw new InvalidTenantException();
    }

    // Set tenant context
    TenantContextService.setTenant(tenantId);

    next();
  }
}
```

**Timing:** ~0ms (instant, chỉ setup providers)

---

## Phase 6: Lifecycle Hooks Execution 🔄

### Execution Order

```
1. Module Construction Phase (SYNCHRONOUS)
   ├── ConfigModule → Load .env
   ├── InfrastructureModule
   │   ├── AppConfig.constructor()
   │   ├── DatabaseConfigService.constructor()
   │   │   └── IF development → Load config từ .env
   │   ├── CognitoConfigService.constructor()
   │   └── S3ConfigService.constructor()
   ├── TypeOrmModule
   │   └── useFactory(DatabaseConfigService)
   │       └── getDatabaseConfig() → Return config
   └── Feature Modules (Auth, Brands, ...)

2. OnModuleInit Phase (ASYNCHRONOUS)
   ├── DatabaseConfigService.onModuleInit()
   │   ├── loadConfig()
   │   │   └── IF production → Load từ AWS SSM & Secrets Manager
   │   └── Setup auto-refresh timer (30 min)
   │
   └── CognitoConfigService.onModuleInit()
       ├── loadUserPools()
       │   ├── IF development → Use hardcoded values
       │   └── IF production → Load từ AWS SSM Parameter Store
       ├── logConfig() → Console output
       └── Setup auto-refresh timer (30 min)

3. Routes Registration
   └── Map all controller routes

4. Application Ready
   └── Listen on port (default: 3000)
```

### Config Loading Strategy

| Service | Constructor Phase | OnModuleInit Phase | Auto-Refresh |
|---------|-------------------|-----------------------|--------------|
| **AppConfig** | ✅ Đọc từ .env via ConfigService | ❌ N/A | ❌ Static |
| **S3ConfigService** | ✅ Đọc từ .env via ConfigService | ❌ N/A | ❌ Static |
| **DatabaseConfigService** | ✅ Dev: Load từ .env<br>⚠️ Prod: Setup AWS clients | ✅ Prod: Load từ AWS SSM/Secrets | ✅ Every 30 min |
| **CognitoConfigService** | ⚠️ Setup AWS SSM client | ✅ Dev: Hardcoded<br>✅ Prod: Load từ AWS SSM | ✅ Every 30 min |

**Timing:** ~500-800ms (bao gồm AWS API calls nếu production)

---

## Phase 7: Runtime - Config Access ⚡

### Request Flow Example: Login

```
1. Request: POST /api/v1/auth/login
   Headers: { "X-Tenant-Id": "PartnerA" }
   Body: { "email": "user@example.com", "password": "xxx" }
   
   ↓

2. TenantMiddleware.use()
   ├── Extract tenant from header: "PartnerA"
   ├── this.cognitoConfig.isValidTenant("PartnerA")
   │   └── Check trong userPoolConfigs[] (đã load)
   ├── Valid ✅
   └── TenantContextService.setTenant("PartnerA")
   
   ↓

3. AuthController.login()
   └── Call LoginUserUseCase.execute(loginDto, tenant)
   
   ↓

4. LoginUserUseCase.execute()
   ├── poolConfig = this.cognitoConfig.findByTenant("PartnerA")
   │   └── Return: {
   │         userPoolId: "ap-northeast-1_XjSb2RN20",
   │         clientId: "66j4f1281qvcv28uego4unmu6n",
   │         tenant: "PartnerA"
   │       }
   │
   ├── Create InitiateAuthCommand với poolConfig
   └── Call AWS Cognito API
   
   ↓

5. Response: { accessToken, idToken, refreshToken, ... }
```

### Request Flow Example: Create Brand

```
1. Request: POST /api/v1/brands
   Headers: { 
     "X-Tenant-Id": "PartnerA",
     "X-ID-Token": "eyJraWQiOiJ..."
   }
   Body: {
     "brandId": "BRAND001",
     "brandName": "My Brand",
     "images": [{ path: "...", contentType: "image/png", displayOrder: 1 }]
   }
   
   ↓

2. TenantMiddleware → Validate tenant
   
   ↓

3. BrandsController.create()
   └── Call CreateBrandUseCase.execute(createBrandDto)
   
   ↓

4. CreateBrandUseCase.execute()
   ├── Inject: IFileStorage (S3FileStorage)
   │   └── S3FileStorage đã được khởi tạo với S3ConfigService
   │
   ├── Loop qua images:
   │   └── fileStorage.generatePutPresignedUrl(key, contentType)
   │       └── S3Client.send(PutObjectCommand({
   │             Bucket: this.s3Config.bucketPrivate,  ← Từ .env
   │             Key: key,
   │             ContentType: contentType
   │           }))
   │
   └── Save to database với tenant schema
   
   ↓

5. Response: { brandId, presignedUrls: [...] }
```

---

## 📊 Console Output Timeline

```bash
# TypeScript Compilation
[10:05:10 AM] Starting compilation in watch mode...
[10:05:14 AM] Found 0 errors. Watching for file changes.

# Application Bootstrap
[10:05:15 AM] LOG [NestFactory] Starting Nest application...

# Module Loading (Phase 2)
[10:05:15 AM] LOG [InstanceLoader] AppModule dependencies initialized +23ms
[10:05:15 AM] LOG [InstanceLoader] TypeOrmModule dependencies initialized +0ms
[10:05:15 AM] LOG [InstanceLoader] CommonModule dependencies initialized +0ms
[10:05:15 AM] LOG [InstanceLoader] StoresModule dependencies initialized +1ms
[10:05:15 AM] LOG [InstanceLoader] ConfigHostModule dependencies initialized +0ms
[10:05:15 AM] LOG [InstanceLoader] ConfigModule dependencies initialized +4ms

# Config Services Initialization (Phase 3)
[10:05:15 AM] WARN [DatabaseConfigService] Database config not loaded yet, using defaults
[10:05:15 AM] LOG [InstanceLoader] InfrastructureModule dependencies initialized +2ms

# Feature Modules (Phase 5)
[10:05:15 AM] LOG [InstanceLoader] AuthModule dependencies initialized +22ms
[10:05:15 AM] LOG [InstanceLoader] TypeOrmCoreModule dependencies initialized +40ms
[10:05:15 AM] LOG [InstanceLoader] TypeOrmModule dependencies initialized +0ms
[10:05:15 AM] LOG [InstanceLoader] HealthModule dependencies initialized +1ms
[10:05:15 AM] LOG [InstanceLoader] BrandsModule dependencies initialized +0ms

# Routes Registration
[10:05:15 AM] LOG [RoutesResolver] HealthController {/api/v1}: +1ms
[10:05:15 AM] LOG [RouterExplorer] Mapped {/health, GET} route +2ms
[10:05:15 AM] LOG [RoutesResolver] AuthController {/api/v1/auth}: +0ms
[10:05:15 AM] LOG [RouterExplorer] Mapped {/api/v1/auth/login, POST} route +0ms
[10:05:15 AM] LOG [RouterExplorer] Mapped {/api/v1/auth/logout, POST} route +1ms
[10:05:15 AM] LOG [RouterExplorer] Mapped {/api/v1/auth/refresh, POST} route +0ms
[10:05:15 AM] LOG [RouterExplorer] Mapped {/api/v1/auth/profile, GET} route +1ms
[10:05:15 AM] LOG [RoutesResolver] BrandsController {/api/v1/brands}: +0ms
[10:05:15 AM] LOG [RouterExplorer] Mapped {/api/v1/brands, POST} route +0ms
[10:05:15 AM] LOG [RouterExplorer] Mapped {/api/v1/brands, GET} route +0ms
[10:05:15 AM] LOG [RouterExplorer] Mapped {/api/v1/brands/:id, GET} route +0ms

# OnModuleInit Hooks (Phase 6)
[10:05:15 AM] LOG [CognitoConfigService] Loading Cognito configs from AWS Parameter Store...
[10:05:15 AM] DEBUG [CognitoConfigService] Fetching parameter: /rakuten-payment/dev/cognito
[10:05:15 AM] LOG [DatabaseConfigService] Loading database configs from AWS...
[10:05:15 AM] DEBUG [DatabaseConfigService] Fetching database parameter: /rakuten-payment/dev/database

# Config Loaded & Logged
[10:05:16 AM] LOG [CognitoConfigService] Cognito User Pool Configuration:
[10:05:16 AM] LOG [CognitoConfigService]   Tenant: PartnerA
[10:05:16 AM] LOG [CognitoConfigService]     User Pool ID: ap-northeast-1_XjSb2RN20
[10:05:16 AM] LOG [CognitoConfigService]     Client ID: 66j4f1281qvcv28uego4unmu6n
[10:05:16 AM] LOG [CognitoConfigService]   Tenant: PartnerB
[10:05:16 AM] LOG [CognitoConfigService]     User Pool ID: ap-northeast-1_1LIUC7Wfb
[10:05:16 AM] LOG [CognitoConfigService]     Client ID: 5rr1sj79t98t7t9soucr67svle

# Application Ready (Phase 7)
[10:05:16 AM] LOG [NestApplication] Nest application successfully started +551ms
🚀 Application is running on: http://0.0.0.0:3000
📚 Swagger documentation: http://0.0.0.0:3000/api-docs
```

**Total Startup Time:** ~1.5 seconds (including AWS API calls)

---

## 🏗️ Architecture Diagrams

### Dependency Injection Chain

```
.env file
    ↓
ConfigModule.forRoot()
    ↓
process.env (populated)
    ↓
ConfigService (singleton, global)
    ↓
    ├─→ AppConfig
    │     └─→ main.ts (CORS, port)
    │
    ├─→ DatabaseConfigService
    │     ├─→ Development: Load từ .env (constructor)
    │     ├─→ Production: Load từ AWS SSM/Secrets (onModuleInit)
    │     └─→ TypeOrmModule.forRootAsync (database connection)
    │
    ├─→ CognitoConfigService
    │     ├─→ Development: Hardcoded pools (onModuleInit)
    │     ├─→ Production: Load từ AWS SSM (onModuleInit)
    │     ├─→ LoginUserUseCase (authentication)
    │     ├─→ RefreshTokenUseCase (token refresh)
    │     ├─→ GetProfileUseCase (user profile)
    │     └─→ TenantMiddleware (tenant validation)
    │
    └─→ S3ConfigService
          └─→ S3FileStorage (file operations)
                └─→ CreateBrandUseCase (presigned URLs)
```

### Module Import Hierarchy

```
AppModule
    ├── ConfigModule.forRoot() [FIRST]
    │     └── Load .env → ConfigService
    │
    ├── InfrastructureModule [@Global]
    │     ├── ConfigModule.forRoot()
    │     └── Providers:
    │           ├── AppConfig
    │           ├── DatabaseConfigService
    │           ├── CognitoConfigService
    │           └── S3ConfigService
    │
    ├── TypeOrmModule.forRootAsync
    │     └── inject: [DatabaseConfigService]
    │
    ├── CommonModule
    ├── HealthModule
    ├── AuthModule
    │     └── Providers:
    │           ├── LoginUserUseCase (inject: CognitoConfigService)
    │           ├── RefreshTokenUseCase (inject: CognitoConfigService)
    │           └── GetProfileUseCase (inject: CognitoConfigService)
    │
    ├── BrandsModule
    │     └── Providers:
    │           ├── S3FileStorage (inject: S3ConfigService)
    │           └── CreateBrandUseCase (inject: S3FileStorage)
    │
    └── StoresModule
```

### Config Loading Flow (Development vs Production)

```
Development Mode (NODE_ENV=development):
    
    ConfigService (.env)
        ↓
    AppConfig → Immediate (constructor)
        ↓
    S3ConfigService → Immediate (constructor)
        ↓
    DatabaseConfigService
        ├── Constructor: Load từ .env NGAY
        └── onModuleInit: Skip (already loaded)
        
    CognitoConfigService
        ├── Constructor: Setup AWS client
        └── onModuleInit: Use hardcoded values
        
Production Mode (NODE_ENV=production):
    
    ConfigService (.env - chỉ AWS credentials)
        ↓
    AppConfig → Immediate (constructor)
        ↓
    S3ConfigService → Immediate (constructor)
        ↓
    DatabaseConfigService
        ├── Constructor: Setup AWS SSM & Secrets Manager clients
        └── onModuleInit: Load từ AWS Parameter Store + Secrets Manager
            ├── GET /rakuten-payment/prod/database (SSM)
            ├── GET /rakuten-payment/prod/database/credentials (Secrets)
            └── Auto-refresh every 30 minutes
        
    CognitoConfigService
        ├── Constructor: Setup AWS SSM client
        └── onModuleInit: Load từ AWS Parameter Store
            ├── GET /rakuten-payment/prod/cognito (SSM)
            └── Auto-refresh every 30 minutes
```

---

## 📝 Key Takeaways

### 1. @Global() Module Pattern
- InfrastructureModule được đánh dấu `@Global()`
- Tất cả providers được export có thể inject vào BẤT KỲ module nào
- Không cần import InfrastructureModule vào từng feature module

### 2. Config Loading Strategy
- **Development**: Load ngay từ `.env` trong constructor (synchronous)
- **Production**: Load từ AWS trong `onModuleInit()` (asynchronous)
- Auto-refresh mỗi 30 phút để cập nhật config changes

### 3. Dependency Injection
- ConfigService là singleton, global
- Config services được inject ConfigService
- Feature modules inject config services
- Chain rõ ràng: .env → ConfigService → Config Services → Feature Services

### 4. Timing Critical
- DatabaseConfigService phải load config TRONG constructor cho development
- Vì TypeOrmModule.forRootAsync gọi `getDatabaseConfig()` ngay lập tức
- `onModuleInit()` chạy SAU khi TypeORM đã connected

### 5. Error Handling
- Config services có fallback mechanism
- Nếu AWS call fails, sử dụng cached values
- Development mode không phụ thuộc vào AWS connectivity

---

## 🔗 Related Documentation

- [NestJS Dependency Injection](https://docs.nestjs.com/fundamentals/custom-providers)
- [NestJS Lifecycle Events](https://docs.nestjs.com/fundamentals/lifecycle-events)
- [TypeORM Configuration](https://docs.nestjs.com/techniques/database#async-configuration)
- [AWS SDK for JavaScript v3](https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/)
- [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)

---

**Last Updated:** November 5, 2025
**Version:** 1.0.0
