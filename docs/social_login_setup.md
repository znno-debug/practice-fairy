# 카카오 · 구글 소셜 로그인 웹 콘솔 설정 가이드

> 코드(`index.html`의 `handleOAuthLogin`)는 이미 들어가 있습니다. 아래 세 곳을 설정해야 버튼이 실제로 동작합니다.
> 2026-11-24 확인 시점에는 Supabase에서 Kakao·Google이 둘 다 **꺼져 있음**(`provider is not enabled`).
> 콘솔 화면은 자주 개편되므로 메뉴 이름이 조금 다를 수 있습니다. 비슷한 이름의 메뉴를 찾으면 됩니다.

## 자주 쓰는 값 (복사용)

| 항목 | 값 |
| :--- | :--- |
| Supabase Callback URL (카카오·구글에 등록) | `https://zpfcocrqvmrotuiwpkru.supabase.co/auth/v1/callback` |
| 앱 주소 (Supabase에 등록) | `https://znno-debug.github.io/practice-fairy/` |
| 앱 도메인 (구글 자바스크립트 원본) | `https://znno-debug.github.io` |

설정 순서: **① 카카오 → ② 구글 → ③ Supabase** (①②에서 받은 키를 ③에 넣습니다)

---

## ① 카카오 개발자센터 (앱 ID `1659300`)

1. https://developers.kakao.com 로그인 → **내 애플리케이션** → 연습요정 앱(ID 1659300) 선택
2. **카카오 로그인 켜기**: [제품 설정] > [카카오 로그인] > **활성화 설정 ON**
3. **Redirect URI 등록**: 카카오 로그인 설정(새 콘솔은 [앱 키] > REST API 키 상세) 화면의 **Redirect URI**에 아래 주소를 추가하고 저장
   `https://zpfcocrqvmrotuiwpkru.supabase.co/auth/v1/callback`
   - ⚠️ 앱 주소(github.io)가 아니라 **Supabase 주소**를 넣어야 합니다.
4. **동의항목 설정**: [카카오 로그인] > [동의항목]
   - 닉네임(`profile_nickname`): **필수 동의**
   - 프로필 사진(`profile_image`): 선택 동의
   - 카카오계정(이메일)(`account_email`): **필수 또는 선택 동의**
     - ⚠️ Supabase는 카카오 로그인 때 `account_email`을 **항상** 함께 요청합니다(앱 코드로 뺄 수 없음). 이 항목이 꺼져 있으면 로그인 직후 `KOE205` 오류가 날 수 있으니, 사실상 이메일 동의항목 설정이 필요합니다.
     - "권한 없음"으로 보이면 [앱 설정] > [비즈니스]에서 **비즈 앱 전환**이 필요합니다(개인 개발자도 본인인증으로 전환 가능).
     - 이메일을 받을 수 없다면 ③에서 Supabase의 "Allow users without an email" 옵션을 켜세요.
5. **Client Secret 발급**: [보안](새 콘솔은 REST API 키 상세) > **Client Secret 코드 생성** → **활성화 상태: 사용함**
6. **메모해 둘 값**: [앱 키]의 **REST API 키**, 5번의 **Client Secret 코드**
7. (기존 공유 기능용) [플랫폼] > Web 사이트 도메인에 `https://znno-debug.github.io`가 있는지 확인

## ② Google Cloud Console

1. https://console.cloud.google.com 로그인 → 상단에서 프로젝트 선택(없으면 **새 프로젝트** "practice-fairy" 생성)
2. 메뉴 **Google 인증 플랫폼**(Google Auth Platform, 예전 이름 "OAuth 동의 화면") → **시작하기**
   - 앱 이름: `연습요정`, 사용자 지원 이메일: 본인 이메일
   - 대상(Audience): **외부(External)**
   - 연락처 이메일 입력 → 동의 후 **만들기**
3. **브랜딩**: 앱 로고(선택), 앱 홈페이지 `https://znno-debug.github.io/practice-fairy/`, 개인정보처리방침 `https://znno-debug.github.io/practice-fairy/privacy.html`, 승인된 도메인에 `znno-debug.github.io` 추가
4. **데이터 액세스**(범위): `email`, `profile`, `openid` (기본 범위라 따로 심사가 필요 없음)
5. **대상**: 게시 상태가 "테스트 중"이면 **테스트 사용자**에 본인 구글 계정을 추가하세요. 실제 선생님들이 쓰려면 **앱 게시(프로덕션으로 푸시)**를 누릅니다.
6. **클라이언트** → **클라이언트 만들기**
   - 애플리케이션 유형: **웹 애플리케이션**, 이름: `practice-fairy-web`
   - 승인된 자바스크립트 원본: `https://znno-debug.github.io`
   - 승인된 리디렉션 URI: `https://zpfcocrqvmrotuiwpkru.supabase.co/auth/v1/callback`
   - **만들기** → 나타나는 **클라이언트 ID**와 **클라이언트 보안 비밀번호**를 복사해 둡니다. 비밀번호는 다시 볼 수 없을 수 있습니다.

## ③ Supabase Dashboard

1. https://supabase.com/dashboard → 프로젝트(`zpfcocrqvmrotuiwpkru`) 선택
2. **Authentication > Sign In / Providers**(또는 Providers)
   - **Kakao**: Enable ON → **REST API Key**(Client ID 칸) = ①-6 REST API 키, **Client Secret** = ①-6 Client Secret → Save
     - 카카오 이메일을 받을 수 없으면 **Allow users without an email** ON
   - **Google**: Enable ON → **Client ID** / **Client Secret** = ②-6 값 → Save
   - 각 Provider 화면에 표시되는 Callback URL이 `https://zpfcocrqvmrotuiwpkru.supabase.co/auth/v1/callback`인지 확인
3. **Authentication > URL Configuration**
   - **Site URL**: `https://znno-debug.github.io/practice-fairy/`
   - **Redirect URLs**에 추가:
     - `https://znno-debug.github.io/practice-fairy/`
     - `https://znno-debug.github.io/practice-fairy/**`
     - (로컬 테스트용, 선택) `http://localhost:8080/**`
   - 여기에 없는 주소로는 로그인 후 돌아오지 못하고 Site URL로 이동합니다.

## ④ 동작 확인

1. 휴대폰 또는 PC의 **Safari/Chrome**에서 앱 주소를 열고 로그인 화면에서 [카카오로 계속하기] / [Google로 계속하기]
2. 로그인 후 앱으로 돌아오면 상단에 이름(또는 이메일)이 표시되고 "☁️ 동기화됨" 배지가 보이면 성공
3. 처음 로그인한 계정은 카카오/구글 프로필 이름·사진이 선생님 프로필 기본값으로 들어갑니다. 이미 클라우드에 프로필이 있으면 기존 프로필이 유지됩니다.

### 알아 둘 점
- **카카오톡 안에서 링크를 열면(인앱 브라우저) Google 로그인은 구글 정책상 막힙니다**(`403 disallowed_useragent`). 오른쪽 위 메뉴에서 "다른 브라우저로 열기"를 쓰세요. 카카오 로그인은 인앱에서도 동작합니다.
- 같은 이메일이라도 이메일 가입 계정과 구글 계정은 Supabase 설정에 따라 하나로 합쳐지거나 따로 만들어질 수 있습니다. 테스트할 때 확인하세요.
- Apple 로그인(iOS 출시 시): `index.html`의 `OAUTH_PROVIDERS`에서 주석 처리된 `apple` 한 줄의 주석을 풀고, Apple Developer 설정과 Supabase Apple Provider를 켜면 됩니다.
