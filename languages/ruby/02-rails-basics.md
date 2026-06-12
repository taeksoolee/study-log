# 2. Rails 기초 (프론트엔드 개발자 관점)

## 목차
1. Rails 철학
2. Rails vs Express 비교
3. 프로젝트 구조
4. 라우팅
5. 컨트롤러
6. 뷰 (ERB, Partial, Turbo Frames)
7. 모델과 Active Record
8. 마이그레이션
9. Rails 콘솔 활용
10. 면접 포인트

---

## 1. Rails 철학

### Convention over Configuration (CoC)
설정보다 관례를 우선합니다. 파일 이름, 폴더 구조, 메서드 이름을 관례에 따르면 별도 설정 없이 동작합니다.

```
# 모델 이름이 User라면:
# - 테이블명은 자동으로 users
# - 파일명은 app/models/user.rb
# - 컨트롤러는 UsersController
# - 뷰 폴더는 app/views/users/
```

### DRY (Don't Repeat Yourself)
코드 중복을 최소화합니다. Active Record, Helper, Concern 등을 통해 반복 코드를 제거합니다.

### MVC 패턴
| 레이어 | 역할 | JS 비유 |
|--------|------|---------|
| Model | 데이터, 비즈니스 로직, DB 연결 | ORM (Sequelize, Prisma) |
| View | 사용자에게 보이는 화면 | React 컴포넌트 (JSX) |
| Controller | 요청 처리, 모델/뷰 연결 | Express 라우터 핸들러 |

---

## 2. Rails vs Express 비교

| 항목 | Rails | Express |
|------|-------|---------|
| 철학 | 의견이 강함 (Opinionated) | 최소한의 구조 |
| 설정 | 관례 우선, 설정 최소화 | 직접 설정 필요 |
| ORM | Active Record 내장 | 직접 선택 (Sequelize 등) |
| 인증 | Devise gem | passport.js 등 별도 |
| 라우팅 | 선언적 DSL (`resources`) | 수동 정의 |
| 마이그레이션 | 내장 | 별도 라이브러리 |
| 테스팅 | Minitest 내장 | Jest 등 별도 |
| 학습 곡선 | 가파름 (많은 관례) | 완만함 |
| 생산성 | 매우 높음 (보일러플레이트 적음) | 유연하지만 반복 작업 많음 |

```javascript
// Express 방식: 모든 것을 직접 구성
const express = require('express')
const app = express()
app.get('/users', async (req, res) => {
  const users = await User.findAll()
  res.json(users)
})
```

```ruby
# Rails 방식: 관례로 자동 처리
# routes.rb
resources :users  # GET /users, POST /users, GET /users/:id 등 자동 생성

# users_controller.rb
def index
  @users = User.all  # 뷰로 자동 전달
end
# app/views/users/index.html.erb 가 자동으로 렌더링됨
```

---

## 3. 프로젝트 구조

```bash
rails new myapp --database=postgresql
```

```
myapp/
├── app/
│   ├── assets/          # CSS, JS, 이미지 (Sprockets)
│   ├── channels/        # Action Cable (WebSocket)
│   ├── controllers/     # 컨트롤러 (요청 처리)
│   │   └── application_controller.rb
│   ├── helpers/         # 뷰 헬퍼 메서드
│   ├── javascript/      # Importmap / Webpack JS (Stimulus 등)
│   ├── jobs/            # Active Job (백그라운드 작업)
│   ├── mailers/         # Action Mailer (이메일 발송)
│   ├── models/          # Active Record 모델
│   │   └── application_record.rb
│   └── views/           # ERB 템플릿
│       └── layouts/
│           └── application.html.erb  # 레이아웃 (JS의 _app.tsx)
├── config/
│   ├── routes.rb        # 라우트 정의 (핵심!)
│   ├── database.yml     # DB 설정
│   └── environments/    # 환경별 설정 (development, test, production)
├── db/
│   ├── migrate/         # 마이그레이션 파일들
│   └── schema.rb        # 현재 DB 스키마 (자동 생성)
├── spec/ (또는 test/)   # 테스트
├── Gemfile              # 의존성 (package.json)
├── Gemfile.lock         # 고정 버전 (package-lock.json)
└── config.ru            # Rack 설정 (서버 진입점)
```

---

## 4. 라우팅

### 기본 RESTful 라우팅

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # resources: 7가지 RESTful 라우트를 한 번에 생성
  resources :users
  # GET    /users          => users#index    (목록)
  # GET    /users/new      => users#new      (생성 폼)
  # POST   /users          => users#create   (생성)
  # GET    /users/:id      => users#show     (상세)
  # GET    /users/:id/edit => users#edit     (수정 폼)
  # PATCH  /users/:id      => users#update   (수정)
  # DELETE /users/:id      => users#destroy  (삭제)

  # 특정 액션만 포함/제외
  resources :articles, only: [:index, :show]
  resources :comments, except: [:destroy]
end
```

### Namespace와 Scope

```ruby
# Namespace: URL 경로 + 컨트롤러 모듈명 변경
namespace :admin do
  resources :users    # GET /admin/users => Admin::UsersController#index
end

# Scope: URL 경로만 변경 (컨트롤러 모듈명은 변경 없음)
scope :api do
  resources :users    # GET /api/users => UsersController#index
end

# API 버전 관리
namespace :api do
  namespace :v1 do
    resources :users  # GET /api/v1/users => Api::V1::UsersController#index
  end
end
```

### Nested Routes (중첩 라우트)

```ruby
# 부모-자식 관계의 리소스
resources :posts do
  resources :comments  # GET /posts/:post_id/comments
end

# shallow 옵션: 불필요한 중첩 제거
resources :posts do
  resources :comments, shallow: true
  # GET    /posts/:post_id/comments  (index, new, create)
  # GET    /comments/:id             (show, edit, update, destroy)
end

# 단일 경로 추가
resources :users do
  member do
    post :follow       # POST /users/:id/follow
    delete :unfollow   # DELETE /users/:id/unfollow
  end
  collection do
    get :search        # GET /users/search
  end
end
```

### 경로 헬퍼

```ruby
# routes.rb에 정의하면 헬퍼 메서드가 자동 생성됨
users_path          # => "/users"
user_path(@user)    # => "/users/1"
new_user_path       # => "/users/new"
edit_user_path(@user) # => "/users/1/edit"

# URL 확인
rails routes | grep user
```

---

## 5. 컨트롤러

### 기본 구조

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :authenticate_user!        # 모든 액션 전 실행
  before_action :set_user, only: [:show, :update, :destroy]

  def index
    @users = User.all         # @ 변수는 뷰에서 접근 가능
    render json: @users       # JSON 응답 (API 모드)
  end

  def show
    render json: @user
  end

  def create
    @user = User.new(user_params)     # Strong Parameters 사용
    if @user.save
      render json: @user, status: :created
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      render json: @user
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    head :no_content
  end

  private

  def set_user
    @user = User.find(params[:id])    # params: 요청 파라미터
  end

  # Strong Parameters: 허용된 파라미터만 통과 (보안)
  # JS: 화이트리스트 방식의 입력 검증과 유사
  def user_params
    params.require(:user).permit(:name, :email, :password)
  end
end
```

### params 접근

```ruby
# URL 파라미터: /users?page=2&sort=name
params[:page]         # => "2"
params[:sort]         # => "name"

# 라우트 파라미터: /users/42
params[:id]           # => "42"

# POST 본문 (JSON or Form Data)
params[:user][:name]  # => "Alice"

# 타입 변환 (params는 모두 문자열)
params[:page].to_i    # => 2
```

### before_action (미들웨어 역할)

```ruby
class ApplicationController < ActionController::Base
  before_action :set_locale
  before_action :authenticate_user!

  private

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def authenticate_user!
    redirect_to login_path unless current_user
  end
end
```

---

## 6. 뷰 (ERB, Partial, Turbo Frames)

### ERB 템플릿

```erb
<%# app/views/users/index.html.erb %>
<%# <%= ... %> : 출력, <% ... %> : 실행만 (출력 없음) %>

<h1>Users</h1>

<% @users.each do |user| %>
  <div class="user-card">
    <h2><%= user.name %></h2>         <%# XSS 자동 이스케이프 %>
    <p><%= user.email %></p>
    <%= link_to "Show", user_path(user), class: "btn" %>
    <%= link_to "Delete", user_path(user), method: :delete, data: { confirm: "Sure?" } %>
  </div>
<% end %>

<%# 폼 헬퍼 %>
<%= form_with model: @user do |f| %>
  <%= f.label :name %>
  <%= f.text_field :name, class: "input" %>
  <%= f.submit "Save", class: "btn btn-primary" %>
<% end %>
```

### Partial (부분 뷰)

```erb
<%# _user_card.html.erb (파일명 앞에 _ 붙임) %>
<div class="user-card">
  <h2><%= user.name %></h2>
  <p><%= user.email %></p>
</div>

<%# 사용: index.html.erb %>
<%= render "user_card", user: @user %>

<%# 컬렉션 렌더링 (JS의 .map() + 컴포넌트) %>
<%= render @users %>
<%# 또는 %>
<%= render partial: "user_card", collection: @users, as: :user %>
```

### Turbo Frames (Hotwire)

```erb
<%# 페이지 일부만 업데이트 (JS 없이 SPA 같은 UX) %>
<%# JS의 React 컴포넌트 부분 리렌더링과 유사 %>

<%# show.html.erb %>
<%= turbo_frame_tag "user-#{@user.id}" do %>
  <h2><%= @user.name %></h2>
  <%= link_to "Edit", edit_user_path(@user) %>
<% end %>

<%# edit.html.erb %>
<%= turbo_frame_tag "user-#{@user.id}" do %>
  <%= form_with model: @user do |f| %>
    <%= f.text_field :name %>
    <%= f.submit %>
  <% end %>
<% end %>
```

---

## 7. 모델과 Active Record

### 기본 CRUD

```ruby
# CREATE
user = User.new(name: "Alice", email: "alice@example.com")
user.save           # => true/false (유효성 검사 포함)

User.create(name: "Bob", email: "bob@example.com")  # new + save
User.create!(name: "Charlie")  # 실패 시 예외 발생

# READ
User.all                        # 전체 (JS ORM: User.findAll())
User.find(1)                    # ID로 찾기, 없으면 예외
User.find_by(email: "a@b.com")  # 조건으로 찾기, 없으면 nil
User.where(active: true)        # 조건 쿼리 (배열 반환)
User.first                      # 첫 번째
User.last                       # 마지막
User.count                      # 개수

# UPDATE
user = User.find(1)
user.update(name: "Alice Updated")
user.name = "Alice"; user.save

# DELETE
user.destroy      # 콜백 실행됨
User.delete(1)    # 콜백 없이 바로 삭제 (빠르지만 위험)
```

### 유효성 검사 (Validation)

```ruby
class User < ApplicationRecord
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :age, numericality: { greater_than: 0, less_than: 150 }, allow_nil: true

  validate :custom_validation   # 커스텀 검사

  private

  def custom_validation
    if name&.include?("admin") && !admin?
      errors.add(:name, "일반 사용자는 admin을 이름에 포함할 수 없습니다")
    end
  end
end

# 에러 확인
user = User.new
user.valid?               # => false
user.errors.full_messages # => ["Name can't be blank", ...]
```

### 콜백 (Callback)

```ruby
class User < ApplicationRecord
  before_validation :normalize_email   # 유효성 검사 전
  before_save :encrypt_password         # 저장 전
  after_create :send_welcome_email      # 생성 후
  before_destroy :check_dependencies    # 삭제 전

  private

  def normalize_email
    self.email = email.downcase.strip if email
  end
end
```

---

## 8. 마이그레이션

```bash
# 마이그레이션 파일 생성
rails generate migration CreateUsers name:string email:string:uniq age:integer
rails generate migration AddPhoneToUsers phone:string
rails generate migration RemoveAgeFromUsers age:integer
```

```ruby
# db/migrate/20240101000000_create_users.rb
class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false, index: { unique: true }
      t.integer :age
      t.boolean :active, default: true
      t.text :bio
      t.references :team, foreign_key: true  # team_id 컬럼 + 외래키

      t.timestamps  # created_at, updated_at 자동 추가
    end
  end
end

# 컬럼 추가
class AddPhoneToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :phone, :string
    add_index :users, :phone
  end
end

# 컬럼 변경
class ChangeEmailLimitInUsers < ActiveRecord::Migration[7.1]
  def change
    change_column :users, :email, :string, limit: 255
  end
end
```

```bash
rails db:migrate          # 마이그레이션 실행
rails db:rollback         # 마지막 마이그레이션 취소
rails db:rollback STEP=3  # 3단계 롤백
rails db:migrate:status   # 마이그레이션 상태 확인
rails db:schema:load      # schema.rb로 DB 초기화
rails db:seed             # db/seeds.rb 실행 (초기 데이터)
```

---

## 9. Rails 콘솔 활용

```bash
rails console        # 또는 rails c (개발 환경)
rails c -e production  # 프로덕션 환경 (주의!)
```

```ruby
# 콘솔에서 모델 조작 (데이터베이스에 실제 반영됨)
User.create(name: "Test", email: "test@example.com")
User.all.count
User.where(active: true).pluck(:email)  # 특정 컬럼만 추출

# 쿼리 확인 (SQL 로그가 콘솔에 출력됨)
User.joins(:posts).where(posts: { published: true })

# 메서드 확인
User.instance_methods(false)  # User에만 정의된 메서드 목록
user = User.first
user.class.ancestors           # 상속 체인 확인

# reload!: 코드 변경 후 재로드
reload!

# 롤백 (테스트용 변경사항 되돌리기)
ActiveRecord::Base.transaction do
  User.delete_all
  raise ActiveRecord::Rollback
end
```

---

## 10. 면접 포인트

**Q. Rails의 "Convention over Configuration"란 무엇인가요?**
> 프레임워크가 파일 위치, 이름 규칙 등을 미리 정해두어 개발자가 설정 파일을 거의 작성하지 않아도 되는 원칙입니다. 예를 들어 `User` 모델은 자동으로 `users` 테이블과 매핑되고, `UsersController`의 `index` 액션은 `app/views/users/index.html.erb`를 자동 렌더링합니다.

**Q. Strong Parameters란 무엇이고 왜 사용하나요?**
> 컨트롤러에서 `params.require().permit()`을 통해 허용된 파라미터만 모델에 전달하는 보안 메커니즘입니다. Mass Assignment 취약점을 방지합니다. 허용되지 않은 파라미터로 중요 필드(예: `admin: true`)를 임의로 변경하는 공격을 막습니다.

**Q. `before_action`의 용도와 `only`, `except` 옵션 차이는?**
> `before_action`은 액션 실행 전에 공통 로직(인증, 데이터 로딩 등)을 실행합니다. `only`는 지정한 액션에만, `except`는 지정한 액션을 제외한 나머지에 적용됩니다.

**Q. `resources`와 `resource`의 차이는?**
> `resources`는 복수형으로 여러 리소스를 다루며 `/:id` 파라미터가 있습니다. `resource`는 단수형으로 현재 사용자 프로필 같은 단일 리소스에 사용하며 `/:id`가 없습니다.

**Q. 마이그레이션을 `rollback`하는 것이 위험한 이유는?**
> `rollback`은 이전 마이그레이션의 `down` 메서드를 실행하는데, 컬럼 삭제 같은 작업은 데이터를 영구 손실시킵니다. 특히 프로덕션 환경에서는 새로운 마이그레이션 파일을 만들어 변경하는 것이 안전합니다.

**Q. `destroy`와 `delete`의 차이는?**
> `destroy`는 Active Record 콜백(`before_destroy`, `after_destroy`)과 연관 모델의 dependent 옵션을 모두 실행합니다. `delete`는 콜백 없이 DB에 직접 DELETE 쿼리를 날립니다. 일반적으로 `destroy`를 사용하는 것이 안전합니다.
