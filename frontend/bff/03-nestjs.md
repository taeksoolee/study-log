# 3. NestJS (프론트엔드 개발자 관점)

## 목차

1. [NestJS란?](#1-nestjs란)
2. [핵심 개념](#2-핵심-개념-module--controller--service--provider)
3. [데코레이터 기반 라우팅](#3-데코레이터-기반-라우팅)
4. [DTO + class-validator](#4-dto--class-validator로-요청-유효성-검사)
5. [의존성 주입 (DI)](#5-의존성-주입-di)
6. [Guard (인증/인가)](#6-guard-인증인가)
7. [Interceptor (응답 변환)](#7-interceptor-응답-변환)
8. [BFF로서의 NestJS](#8-bff로서의-nestjs-마이크로서비스-집계-예제)
9. [면접 포인트](#9-면접-포인트)

---

## 1. NestJS란?

NestJS는 **TypeScript 기반의 Node.js 백엔드 프레임워크**입니다. 내부적으로 Express(또는 Fastify)를 사용하지만, Angular에서 영감을 받은 **모듈 시스템과 데코레이터 문법**으로 구조화된 아키텍처를 제공합니다.

**프론트엔드 개발자에게 친숙한 이유:**

- TypeScript 퍼스트 설계 — 타입 안전성이 기본
- Angular 개발자라면 Module/Component 개념이 익숙
- React 개발자도 의존성 주입(DI), 데코레이터 패턴을 빠르게 이해 가능
- 폴더 구조가 잘 잡혀 있어 팀 온보딩 쉬움

```bash
# 설치
npm i -g @nestjs/cli
nest new my-bff
cd my-bff
npm run start:dev
```

---

## 2. 핵심 개념: Module / Controller / Service / Provider

```
Module ─── 기능 단위 묶음 (React의 feature 폴더 개념)
  ├── Controller ─── HTTP 요청/응답 처리 (라우트 핸들러)
  ├── Service ─────── 비즈니스 로직 (재사용 가능한 함수들)
  └── Provider ────── DI로 주입 가능한 모든 것 (Service, Repository, etc.)
```

```typescript
// users/users.module.ts
import { Module } from '@nestjs/common';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { HttpModule } from '@nestjs/axios'; // 외부 HTTP 호출용

@Module({
  imports: [HttpModule],         // 이 모듈에서 사용할 의존성
  controllers: [UsersController], // HTTP 요청을 처리할 컨트롤러
  providers: [UsersService],     // DI 컨테이너에 등록할 프로바이더
  exports: [UsersService],       // 다른 모듈에서 쓸 수 있도록 노출
})
export class UsersModule {}
```

```typescript
// app.module.ts (루트 모듈)
import { Module } from '@nestjs/common';
import { UsersModule } from './users/users.module';
import { OrdersModule } from './orders/orders.module';

@Module({
  imports: [UsersModule, OrdersModule],
})
export class AppModule {}
```

---

## 3. 데코레이터 기반 라우팅

```typescript
// users/users.controller.ts
import {
  Controller, Get, Post, Put, Delete,
  Param, Query, Body, HttpCode, HttpStatus,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';

@Controller('users') // 기본 경로: /users
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()                              // GET /users?page=1&limit=20
  findAll(
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '20',
  ) {
    return this.usersService.findAll({ page: +page, limit: +limit });
  }

  @Get(':id')                         // GET /users/123
  findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Post()                             // POST /users
  @HttpCode(HttpStatus.CREATED)       // 기본 200 대신 201 반환
  create(@Body() createUserDto: CreateUserDto) {
    return this.usersService.create(createUserDto);
  }

  @Put(':id')                         // PUT /users/123
  update(@Param('id') id: string, @Body() dto: UpdateUserDto) {
    return this.usersService.update(id, dto);
  }

  @Delete(':id')                      // DELETE /users/123
  @HttpCode(HttpStatus.NO_CONTENT)    // 204 반환
  remove(@Param('id') id: string) {
    return this.usersService.remove(id);
  }
}
```

---

## 4. DTO + class-validator로 요청 유효성 검사

DTO(Data Transfer Object)는 요청/응답 데이터 구조를 정의하는 클래스입니다.

```bash
npm i class-validator class-transformer
```

```typescript
// users/dto/create-user.dto.ts
import {
  IsEmail, IsString, MinLength, MaxLength,
  IsOptional, IsEnum, IsPhoneNumber,
} from 'class-validator';

export enum UserRole {
  USER = 'USER',
  ADMIN = 'ADMIN',
}

export class CreateUserDto {
  @IsString()
  @MinLength(2)
  @MaxLength(50)
  name: string;

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole = UserRole.USER;

  @IsOptional()
  @IsPhoneNumber('KR')
  phone?: string;
}
```

```typescript
// main.ts — ValidationPipe 전역 등록
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,        // DTO에 없는 필드 자동 제거
      forbidNonWhitelisted: true, // DTO에 없는 필드 있으면 400 에러
      transform: true,        // 쿼리스트링 string → 타입 자동 변환
    }),
  );

  await app.listen(3000);
}
bootstrap();
```

유효성 검사 실패 시 자동으로 400 Bad Request 응답이 반환됩니다.

```json
{
  "statusCode": 400,
  "message": ["email must be an email", "password is too short"],
  "error": "Bad Request"
}
```

---

## 5. 의존성 주입 (DI)

NestJS의 DI 컨테이너가 클래스 인스턴스 생성과 주입을 자동으로 처리합니다.

```typescript
// users/users.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

@Injectable() // DI 컨테이너에 등록
export class UsersService {
  constructor(
    private readonly httpService: HttpService, // 자동 주입
  ) {}

  async findOne(id: string) {
    try {
      const { data } = await firstValueFrom(
        this.httpService.get(`${process.env.USER_SERVICE_URL}/users/${id}`),
      );
      return data;
    } catch (err) {
      if (err.response?.status === 404) {
        throw new NotFoundException(`User ${id} not found`);
      }
      throw err;
    }
  }
}
```

```typescript
// 여러 서비스를 주입받는 컨트롤러
@Controller('dashboard')
export class DashboardController {
  constructor(
    private readonly usersService: UsersService,     // 자동 주입
    private readonly ordersService: OrdersService,   // 자동 주입
  ) {}
}
```

---

## 6. Guard (인증/인가)

Guard는 `canActivate()` 메서드가 `true`를 반환해야 라우트 핸들러로 진행할 수 있습니다.

```typescript
// auth/jwt.guard.ts
import {
  Injectable, CanActivate, ExecutionContext, UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private jwtService: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const token = this.extractToken(request);

    if (!token) throw new UnauthorizedException('No token provided');

    try {
      const payload = await this.jwtService.verifyAsync(token, {
        secret: process.env.JWT_SECRET,
      });
      request['user'] = payload; // 이후 핸들러에서 @Req() 또는 커스텀 데코레이터로 접근
      return true;
    } catch {
      throw new UnauthorizedException('Invalid token');
    }
  }

  private extractToken(request: Request): string | undefined {
    return request.headers.authorization?.split(' ')[1];
  }
}
```

```typescript
// 역할 기반 Guard
import { SetMetadata } from '@nestjs/common';

export const Roles = (...roles: string[]) => SetMetadata('roles', roles);

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.get<string[]>('roles', context.getHandler());
    if (!requiredRoles) return true; // 역할 없으면 모두 허용

    const { user } = context.switchToHttp().getRequest();
    return requiredRoles.some(role => user.roles?.includes(role));
  }
}
```

```typescript
// 컨트롤러에서 Guard 사용
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('admin')
export class AdminController {
  @Get('stats')
  @Roles('admin')
  getStats() { /* admin만 접근 가능 */ }
}
```

---

## 7. Interceptor (응답 변환)

Interceptor는 요청/응답을 가로채 변환할 수 있습니다. 응답 래핑, 로깅, 캐싱에 활용됩니다.

```typescript
// common/interceptors/transform.interceptor.ts
import {
  Injectable, NestInterceptor, ExecutionContext, CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface ApiResponse<T> {
  success: boolean;
  data: T;
  timestamp: string;
}

@Injectable()
export class TransformInterceptor<T>
  implements NestInterceptor<T, ApiResponse<T>>
{
  intercept(context: ExecutionContext, next: CallHandler): Observable<ApiResponse<T>> {
    return next.handle().pipe(
      map(data => ({
        success: true,
        data,
        timestamp: new Date().toISOString(),
      })),
    );
  }
}
```

```typescript
// 로깅 Interceptor
@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const req = context.switchToHttp().getRequest();
    const now = Date.now();

    return next.handle().pipe(
      tap(() => {
        console.log(`${req.method} ${req.url} — ${Date.now() - now}ms`);
      }),
    );
  }
}
```

```typescript
// main.ts에 전역 등록
app.useGlobalInterceptors(new TransformInterceptor(), new LoggingInterceptor());
```

---

## 8. BFF로서의 NestJS: 마이크로서비스 집계 예제

```typescript
// dashboard/dashboard.service.ts
import { Injectable } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class DashboardService {
  constructor(private readonly httpService: HttpService) {}

  async getDashboardData(userId: string) {
    const headers = { 'X-Internal-Token': process.env.INTERNAL_TOKEN };

    // Promise.allSettled로 부분 실패 허용
    const results = await Promise.allSettled([
      firstValueFrom(
        this.httpService.get(`${process.env.USER_SVC}/users/${userId}`, { headers }),
      ),
      firstValueFrom(
        this.httpService.get(`${process.env.ORDER_SVC}/orders?userId=${userId}&limit=5`, { headers }),
      ),
      firstValueFrom(
        this.httpService.get(`${process.env.PRODUCT_SVC}/recommendations/${userId}`, { headers }),
      ),
    ]);

    const [userResult, ordersResult, recsResult] = results;

    return {
      user: userResult.status === 'fulfilled'
        ? this.transformUser(userResult.value.data)
        : null,
      recentOrders: ordersResult.status === 'fulfilled'
        ? ordersResult.value.data.items.map(this.transformOrder)
        : [],
      recommendations: recsResult.status === 'fulfilled'
        ? recsResult.value.data.items
        : [],
    };
  }

  private transformUser(user: any) {
    return { id: user.userId, name: user.fullName, avatar: user.profileImageUrl };
  }

  private transformOrder(order: any) {
    return {
      id: order.orderId,
      status: order.orderStatus,
      total: order.totalAmount,
      items: order.lineItems?.length ?? 0,
    };
  }
}
```

```typescript
// dashboard/dashboard.controller.ts
@UseGuards(JwtAuthGuard)
@Controller('dashboard')
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  @Get()
  async getDashboard(@Req() req: Request) {
    return this.dashboardService.getDashboardData(req['user'].id);
  }
}
```

---

## 9. 면접 포인트

**Q. NestJS의 Module 시스템이란 무엇인가요?**

> Module은 기능 단위로 코드를 캡슐화하는 컨테이너입니다. 각 Module은 자신이 사용할 Controller, Provider를 선언하고, 외부에 공개할 Provider는 `exports`에 등록합니다. 루트 AppModule에서 모든 모듈을 조합합니다. 이 구조 덕분에 기능별 독립성이 높고, 테스트 시 Mock 교체가 쉽습니다.

**Q. Guard와 Middleware의 차이는?**

> Middleware는 Express 레벨에서 실행되며 NestJS 컨텍스트(실행 컨텍스트, 메타데이터 등)에 접근할 수 없습니다. Guard는 NestJS 실행 컨텍스트에 접근해 `@Roles()` 같은 데코레이터 메타데이터를 읽을 수 있습니다. 인증은 Middleware로도 가능하지만, 역할 기반 인가는 Guard에서 처리하는 것이 적합합니다.

**Q. 의존성 주입(DI)의 장점은?**

> 클래스가 의존하는 객체를 직접 생성하지 않고 외부에서 주입받으므로, 테스트 시 Mock으로 쉽게 교체할 수 있습니다. 또한 NestJS DI 컨테이너가 싱글톤 관리를 자동으로 해주므로 인스턴스 관리 코드를 직접 작성하지 않아도 됩니다.

**Q. Interceptor로 무엇을 할 수 있나요?**

> 요청 전 처리(로깅 시작, 캐시 확인), 응답 후 처리(응답 래핑, 로깅 종료, 캐시 저장), 에러 변환 등을 할 수 있습니다. AOP(관점 지향 프로그래밍) 개념으로, 핵심 비즈니스 로직과 횡단 관심사(cross-cutting concern)를 분리하는 데 활용합니다.
