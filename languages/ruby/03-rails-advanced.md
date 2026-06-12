# 3. Rails 심화 (프론트엔드 개발자 관점)

## 목차
1. Active Record 심화 (관계, 쿼리 최적화)
2. Active Job과 Sidekiq
3. Action Cable (WebSocket)
4. Hotwire (Turbo + Stimulus)
5. API 모드와 JWT 인증
6. 테스팅 (RSpec, Factory Bot)
7. Rails 8 최신 변경사항
8. 면접 포인트

---

## 1. Active Record 심화

### 관계 (Associations)

```ruby
# has_many / belongs_to (1:N 관계)
class User < ApplicationRecord
  has_many :posts, dependent: :destroy   # User 삭제 시 Post도 삭제
  has_many :comments, dependent: :nullify # User 삭제 시 user_id를 NULL로
  has_one :profile, dependent: :destroy
end

class Post < ApplicationRecord
  belongs_to :user                        # posts 테이블에 user_id 컬럼 필요
  has_many :comments
  has_many :taggings
  has_many :tags, through: :taggings      # N:M 관계 (through)
end

class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post
end

# has_many :through (N:M 관계) — 중간 테이블
class Student < ApplicationRecord
  has_many :enrollments
  has_many :courses, through: :enrollments
end

class Course < ApplicationRecord
  has_many :enrollments
  has_many :students, through: :enrollments
end

class Enrollment < ApplicationRecord
  belongs_to :student
  belongs_to :course
  # 중간 테이블에 추가 속성 가능: grade, enrolled_at 등
end
```

### 관계 사용

```ruby
user = User.find(1)
user.posts                          # 해당 유저의 모든 게시글
user.posts.create(title: "Hello")   # 관계 통해 생성 (user_id 자동 설정)
user.posts.count                    # SQL: SELECT COUNT(*) FROM posts WHERE user_id = 1
user.posts.where(published: true)   # 체이닝 가능

# includes로 eager loading
users = User.includes(:posts).all
users.each { |u| u.posts.count }    # N+1 문제 없음
```

### 쿼리 최적화 (N+1 문제)

```ruby
# N+1 문제: JS에서 루프 안에 DB 쿼리를 날리는 패턴과 동일
# 나쁜 예: N+1 쿼리
posts = Post.all           # 쿼리 1번
posts.each do |post|
  puts post.user.name      # 각 post마다 쿼리 1번 => 총 N+1번
end

# 해결 1: includes (N+1 해결, LEFT OUTER JOIN 또는 IN 쿼리)
posts = Post.includes(:user).all
posts.each { |post| puts post.user.name }  # 쿼리 2번으로 끝

# 해결 2: joins + select (필요한 데이터만 조회, 메모리 효율)
posts = Post.joins(:user).select("posts.*, users.name as author_name")

# 해결 3: eager_load (항상 LEFT OUTER JOIN 사용)
posts = Post.eager_load(:user, :comments)

# 해결 4: preload (별도 쿼리 실행, includes의 기본 동작)
posts = Post.preload(:user)

# Bullet gem: N+1 자동 감지 (개발 환경)
# gem 'bullet' 추가 후 설정
```

### 스코프와 고급 쿼리

```ruby
class Post < ApplicationRecord
  # scope: 재사용 가능한 쿼리 조각 (JS의 쿼리 빌더 메서드와 유사)
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc).limit(10) }
  scope :by_author, ->(user) { where(user: user) }

  # 메서드 체이닝
  # Post.published.recent.by_author(current_user)
end

# 집계
User.group(:role).count           # => { "admin" => 2, "user" => 150 }
Post.where("created_at > ?", 1.week.ago).count  # ? 플레이스홀더
Post.select(:user_id).distinct.count  # 유니크한 user_id 수

# 페이지네이션 (kaminari gem)
@posts = Post.page(params[:page]).per(20)
```

---

## 2. Active Job과 Sidekiq

### Active Job 기본

```ruby
# 백그라운드 잡 생성
# rails generate job WelcomeEmail

# app/jobs/welcome_email_job.rb
class WelcomeEmailJob < ApplicationJob
  queue_as :default   # 큐 우선순위

  # retry_on: 실패 시 재시도 설정
  retry_on Net::TimeoutError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError  # 실패해도 재시도 안 함

  def perform(user_id)
    user = User.find(user_id)         # ID로 조회 (직렬화 안전)
    UserMailer.welcome(user).deliver_now
  end
end

# 잡 실행 방법
WelcomeEmailJob.perform_later(user.id)           # 백그라운드 실행
WelcomeEmailJob.set(wait: 5.minutes).perform_later(user.id)  # 지연 실행
WelcomeEmailJob.set(wait_until: Date.tomorrow.noon).perform_later(user.id)
WelcomeEmailJob.perform_now(user.id)             # 동기 실행 (테스트용)
```

### Sidekiq 연동

```ruby
# Gemfile
gem 'sidekiq'

# config/application.rb
config.active_job.queue_adapter = :sidekiq

# config/sidekiq.yml
:queues:
  - [critical, 3]   # 가중치: 3 (자주 처리)
  - [default, 2]
  - [low, 1]

# 실행
# sidekiq -C config/sidekiq.yml

# Sidekiq 직접 사용 (Active Job 없이)
class HardWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: 3

  def perform(user_id, options = {})
    user = User.find(user_id)
    # 무거운 작업 처리
  end
end

HardWorker.perform_async(user.id)
HardWorker.perform_in(1.hour, user.id)
```

---

## 3. Action Cable (WebSocket)

### 기본 설정

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    # JS의 WebSocket.onopen과 유사
    stream_from "chat_#{params[:room_id]}"
    # 또는
    stream_for current_user   # 모델 기반 스트림
  end

  def unsubscribed
    # JS의 WebSocket.onclose와 유사
    stop_all_streams
  end

  def speak(data)
    # 클라이언트에서 메시지 전송 시 실행
    message = Message.create!(
      content: data["message"],
      user: current_user,
      room_id: params[:room_id]
    )
    ActionCable.server.broadcast(
      "chat_#{params[:room_id]}",
      { message: render_message(message) }
    )
  end

  private

  def render_message(message)
    ApplicationController.renderer.render(
      partial: "messages/message",
      locals: { message: message }
    )
  end
end
```

```javascript
// app/javascript/channels/chat_channel.js
// JS 클라이언트 코드
import consumer from "./consumer"

const chatChannel = consumer.subscriptions.create(
  { channel: "ChatChannel", room_id: roomId },
  {
    connected() { console.log("Connected") },
    disconnected() { console.log("Disconnected") },
    received(data) {
      // 서버에서 브로드캐스트한 데이터 수신
      document.getElementById("messages").insertAdjacentHTML("beforeend", data.message)
    },
    speak(message) {
      this.perform("speak", { message })  // 서버 메서드 호출
    }
  }
)
```

---

## 4. Hotwire (Turbo + Stimulus)

### Turbo Drive (자동 적용)

```
# 일반 링크 클릭 시 전체 페이지 로드 대신 <body>만 교체
# JS 없이 SPA 같은 네비게이션 (React Router 없이)
# JS: window.history.pushState() + fetch() 조합과 유사한 효과
```

### Turbo Frames

```erb
<%# 페이지의 특정 부분만 업데이트 (JS의 컴포넌트 리렌더링과 유사) %>

<%# app/views/posts/index.html.erb %>
<%= turbo_frame_tag "post-list" do %>
  <%= render @posts %>
  <%= link_to "Load More", posts_path(page: 2) %>
<% end %>

<%# 응답: 같은 turbo_frame_tag "post-list" 부분만 교체됨 %>
```

### Turbo Streams (실시간 DOM 업데이트)

```ruby
# 컨트롤러에서 Turbo Stream 응답
def create
  @post = Post.new(post_params)
  if @post.save
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.prepend("posts", partial: "post", locals: { post: @post }),
          turbo_stream.replace("new-post-form", partial: "new_form")
        ]
      end
      format.html { redirect_to posts_path }
    end
  end
end
```

```erb
<%# turbo_stream 액션: append, prepend, replace, update, remove, before, after %>
<%= turbo_stream.append "comments" do %>
  <%= render @comment %>
<% end %>
```

### Stimulus (JS 컨트롤러)

```javascript
// app/javascript/controllers/toggle_controller.js
// JS의 React 컴포넌트처럼 동작 (하지만 HTML 중심)
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "button"]  // data-toggle-target="content"
  static values = { open: Boolean }       // data-toggle-open-value="true"

  toggle() {
    this.openValue = !this.openValue
  }

  openValueChanged() {
    this.contentTarget.hidden = !this.openValue
    this.buttonTarget.textContent = this.openValue ? "Close" : "Open"
  }
}
```

```erb
<%# HTML에 data 속성으로 Stimulus 연결 %>
<div data-controller="toggle">
  <button data-action="click->toggle#toggle" data-toggle-target="button">
    Open
  </button>
  <div data-toggle-target="content" hidden>
    Hidden content
  </div>
</div>
```

---

## 5. API 모드와 JWT 인증

### Rails API Only 앱 생성

```bash
rails new myapi --api --database=postgresql
```

```ruby
# config/application.rb (API 모드에서 자동 설정)
config.api_only = true  # 세션, 쿠키, 뷰 미들웨어 제거

# app/controllers/application_controller.rb
class ApplicationController < ActionController::API  # Base 대신 API
  include ActionController::HttpAuthentication::Token::ControllerMethods
end
```

### JWT 인증 구현

```ruby
# Gemfile
gem 'jwt'
gem 'bcrypt'

# app/models/user.rb
class User < ApplicationRecord
  has_secure_password  # bcrypt 기반 비밀번호 암호화

  def generate_jwt
    payload = { user_id: id, exp: 24.hours.from_now.to_i }
    JWT.encode(payload, Rails.application.credentials.secret_key_base, "HS256")
  end
end

# app/controllers/concerns/authenticatable.rb
module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request
  end

  private

  def authenticate_request
    token = request.headers["Authorization"]&.split(" ")&.last
    raise AuthenticationError unless token

    payload = JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: "HS256")
    @current_user = User.find(payload.first["user_id"])
  rescue JWT::ExpiredSignature
    render json: { error: "Token expired" }, status: :unauthorized
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end

# app/controllers/auth_controller.rb
class AuthController < ApplicationController
  skip_before_action :authenticate_request, only: [:login]

  def login
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])  # bcrypt 비밀번호 확인
      render json: { token: user.generate_jwt, user: UserSerializer.new(user) }
    else
      render json: { error: "Invalid credentials" }, status: :unauthorized
    end
  end
end

# JSON 직렬화 (jbuilder 또는 blueprinter gem)
# app/views/users/show.json.jbuilder
json.id @user.id
json.name @user.name
json.email @user.email
json.posts @user.posts do |post|
  json.id post.id
  json.title post.title
end
```

---

## 6. 테스팅 (RSpec, Factory Bot)

### RSpec 기본 구조

```ruby
# Gemfile (test/development group)
gem 'rspec-rails'
gem 'factory_bot_rails'
gem 'faker'
gem 'shoulda-matchers'

# rails generate rspec:install 실행 후

# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  # describe: 테스트 그룹 (JS의 describe)
  # it: 개별 테스트 케이스 (JS의 it/test)
  # expect: 단언 (JS의 expect)

  describe "validations" do
    it "is valid with valid attributes" do
      user = build(:user)     # Factory Bot
      expect(user).to be_valid
    end

    it "is invalid without email" do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it { is_expected.to validate_presence_of(:name) }   # shoulda-matchers 단축형
    it { is_expected.to validate_uniqueness_of(:email) }
  end

  describe "associations" do
    it { is_expected.to have_many(:posts).dependent(:destroy) }
    it { is_expected.to belong_to(:team).optional }
  end
end

# spec/requests/users_spec.rb (API 테스트)
RSpec.describe "Users API", type: :request do
  let(:user) { create(:user) }       # 테스트용 데이터 생성
  let(:headers) { { "Authorization" => "Bearer #{user.generate_jwt}" } }

  describe "GET /api/v1/users" do
    before { create_list(:user, 3) }

    it "returns all users" do
      get "/api/v1/users", headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(4)
    end
  end

  describe "POST /api/v1/users" do
    context "with valid params" do    # context: 상황별 그룹
      it "creates a user" do
        expect {
          post "/api/v1/users", params: { user: attributes_for(:user) }, headers: headers
        }.to change(User, :count).by(1)
        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid params" do
      it "returns errors" do
        post "/api/v1/users", params: { user: { email: "" } }, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
```

### Factory Bot

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }              # 동적 데이터 (Faker 사용)
    email { Faker::Internet.unique.email }
    password { "password123" }
    active { true }

    trait :admin do                         # trait: 변형 (JS의 override와 유사)
      role { :admin }
    end

    trait :with_posts do
      after(:create) do |user|
        create_list(:post, 3, user: user)
      end
    end
  end
end

# 사용
user = create(:user)                    # DB에 저장
user = build(:user)                     # 저장 안 함 (빠름)
user = build_stubbed(:user)             # 가짜 객체 (더 빠름)
admin = create(:user, :admin)           # trait 적용
user = create(:user, :with_posts)       # 관계 포함 생성
users = create_list(:user, 5)           # 여러 개 생성
```

---

## 7. Rails 8 최신 변경사항

### Solid Queue (DB 기반 큐)

```ruby
# Redis 없이 PostgreSQL/SQLite로 백그라운드 잡 처리
# Gemfile (Rails 8에서 기본 포함)
gem "solid_queue"

# config/application.rb
config.active_job.queue_adapter = :solid_queue

# config/queue.yml
default: &default
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "*"
      threads: 3
      processes: 2
      polling_interval: 0.1

# 기존 Active Job 코드 변경 없이 사용 가능
MyJob.perform_later(params)
```

### Solid Cache (DB 기반 캐시)

```ruby
# config/environments/production.rb
config.cache_store = :solid_cache_store

# 기존 캐시 API 그대로 사용
Rails.cache.write("key", "value", expires_in: 1.hour)
Rails.cache.read("key")
```

### Kamal 배포

```yaml
# config/deploy.yml (Kamal 설정)
service: myapp
image: user/myapp

servers:
  web:
    - 192.168.1.1
  job:
    hosts:
      - 192.168.1.2
    cmd: bundle exec sidekiq

registry:
  username: myuser
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
```

```bash
# Kamal 배포 명령
kamal setup     # 첫 배포 (서버 설정 + 배포)
kamal deploy    # 이후 배포
kamal rollback  # 롤백
kamal app logs  # 로그 확인
```

### Propshaft (Asset Pipeline)

```ruby
# Sprockets 대신 Propshaft (더 단순, 빠름)
# 기존: app/assets/stylesheets/*.css
# 사용: /assets/application.css (자동 다이제스트)
```

### Rails 8 기타 변경사항

```ruby
# Authentication Generator (새로 추가)
rails generate authentication
# Session 기반 인증 코드 자동 생성 (Devise 없이)

# SQLite 프로덕션 지원 강화
# Litestream으로 복제 지원
# 소규모 앱에서 Redis, PostgreSQL 없이 배포 가능

# Importmap 기반 JS (기본값)
# npm/webpack 없이 ESM으로 JS 관리
# bin/importmap pin stimulus
```

---

## 8. 면접 포인트

**Q. N+1 문제란 무엇이며 Rails에서 어떻게 해결하나요?**
> N+1 문제는 1번의 쿼리로 N개의 레코드를 가져온 후, 각 레코드의 연관 데이터를 조회하기 위해 N번의 추가 쿼리가 발생하는 성능 문제입니다. Rails에서는 `includes(:association)`로 eager loading하여 해결합니다. 개발 환경에서는 Bullet gem으로 자동 감지할 수 있습니다.

**Q. `has_many :through`와 `has_and_belongs_to_many`의 차이는?**
> `has_and_belongs_to_many`는 단순 N:M 관계(중간 테이블에 추가 속성 없을 때)에 사용하고, `has_many :through`는 중간 테이블에 추가 컬럼이 필요하거나 중간 모델에 직접 접근해야 할 때 사용합니다. 실무에서는 유연성 때문에 대부분 `has_many :through`를 선호합니다.

**Q. Turbo와 React의 차이는 무엇인가요?**
> React는 클라이언트 사이드에서 Virtual DOM을 관리하며 JSON API와 통신합니다. Turbo는 서버에서 렌더링된 HTML을 받아 DOM의 특정 부분만 교체합니다. Turbo는 JS를 최소화하면서 SPA 같은 UX를 제공하지만, 복잡한 클라이언트 상태 관리가 필요한 앱에는 React가 적합합니다.

**Q. `perform_later`와 `perform_now`의 차이와 사용 시기는?**
> `perform_later`는 잡을 큐에 넣고 백그라운드에서 비동기로 실행합니다(이메일 발송, 이미지 처리 등). `perform_now`는 현재 프로세스에서 즉시 동기 실행합니다(주로 테스트 환경에서 사용). 응답 시간에 영향을 주는 무거운 작업은 `perform_later`를 사용해야 합니다.

**Q. RSpec에서 `let`과 `let!`의 차이는?**
> `let`은 처음 사용될 때 한 번만 실행되는 지연 평가(lazy evaluation)이고, `let!`은 테스트 시작 전에 즉시 실행됩니다. DB에 데이터가 미리 존재해야 하는 테스트(예: 목록 조회)에서는 `let!`이나 `before { create(...) }`를 사용합니다.

**Q. Rails 8의 Solid Queue가 기존 Sidekiq(Redis)와 비교해 어떤 장단점이 있나요?**
> Solid Queue는 이미 사용 중인 DB(PostgreSQL/SQLite)를 큐로 사용하므로 Redis 서버를 별도 운영할 필요가 없어 인프라가 단순해집니다. 단, 고트래픽 환경에서는 Redis 기반 Sidekiq이 처리 속도와 성능이 더 뛰어납니다. 소규모~중규모 앱에서는 Solid Queue가 운영 비용 절감에 유리합니다.
