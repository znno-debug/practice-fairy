# CONTEXT — 연습요정 (Practice Fairy)

> **최종 갱신**: 2026-11-24 · `sw.js` 캐시 `fairy-cache-v28`
> **한 줄 요약**: 음악 1:1 레슨 선생님용 출결·수강료·레슨노트 관리 + 수강생 연습일지 PWA. 학부모에게는 카카오톡 카드로 1:1 리포트(`share.html`)를 보냄.
> **현재 단계**: 기능 시제품 완성, Supabase Auth 연동, GitHub Pages 배포 완료. 지금은 **카카오 공유 마무리와 모바일 다듬기** 단계.
> 이 문서는 작업 시작 전에 가장 먼저 읽고, 작업이 끝나면 곧바로 갱신한다(→ `CLAUDE.md` / `GEMINI.md`).

---

## 1. 인프라 / 환경

| 항목 | 값 | 소스 위치 |
| :--- | :--- | :--- |
| 배포 (GitHub Pages) | `https://znno-debug.github.io/practice-fairy/` | `index.html` `buildShareReportUrl()`, `sendKakaoReportCard()` |
| Supabase 프로젝트 | `https://zpfcocrqvmrotuiwpkru.supabase.co` (Auth + PostgreSQL + JS SDK v2) | `index.html:1926` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) |
| Supabase 테이블 (7개) | `fairy_teacher_profile_v1`, `fairy_students_v1`, `fairy_lessons_v1`, `fairy_notes_v1`, `fairy_practice_v1`, `fairy_questions_v1`, `fairy_sessions_v1` | `supabase_schema.sql`, `index.html:1950~` (LocalStorage 키와 같은 이름) |
| 카카오 개발자센터 | 앱 ID `1659300`, JS SDK `2.7.2`, `KAKAO_JS_KEY`는 `index.html:1933` | `index.html:25`, `:1933` |
| PWA | `sw.js` (현재 `fairy-cache-v24`), `manifest.json`, `icons/`, 루트 `icon-512.png` | |
| 로컬 테스트 서버 | `python3 server.py` → `http://localhost:8080` (같은 Wi-Fi 기기용 IP 자동 표시) | `server.py` |
| 기술 스택 | HTML5 + Vanilla JS + Tailwind CSS(CDN) + Supabase + Web Audio API + Service Worker + LocalStorage | |

## 2. 파일 구성

| 파일 | 역할 | 비고 |
| :--- | :--- | :--- |
| `index.html` (~5,400줄) | 메인 앱: 수업 캘린더, 레슨 노트, 수강생 관리, 마이 연습실, Auth 화면(`#auth-overlay`), PWA 설치 UI | 모든 로직이 이 파일 하나에 들어 있음 |
| `share.html` | 학부모/성인 수강생용 1:1 리포트. 링크 안 데이터만으로 열림(로그인 없음) | `?id=...&d=<base64url JSON 배열>`을 읽고, 예전 `#d=` 해시 방식도 지원 |
| `privacy.html` | 개인정보처리방침 및 서비스 이용약관 페이지 | 로그인 화면(`#auth-overlay`) 및 선생님 프로필 모달에서 연결 (스토어 심사 필수) |
| `sw.js` | 서비스 워커. HTML은 네트워크 우선, `/icons/`는 캐시 우선 | **HTML 수정 시 버전 +1 필수** |
| `manifest.json` | PWA 매니페스트 (상대 경로) | |
| `supabase_schema.sql` | 7개 테이블 + RLS 정책 SQL | **핵심 자산, 삭제 금지**. ⚠️ 4장 참고 |
| `build_icons.py` + `icons/` | PWA·파비콘 아이콘 생성 스크립트와 결과물 | **핵심 자산, 삭제 금지** |
| `icon-512.png` (루트) | 카카오 피드 카드 썸네일 (`imageUrl`) | 512×512 정사각형 |
| `server.py` | 로컬 테스트 서버 | |
| `README.md` | 기능 소개 (11-06 기준이라 일부 내용이 예전 상태) | |
| `docs/social_login_setup.md` | 카카오·구글 소셜 로그인 웹 콘솔 설정 가이드 (카카오 개발자센터 / Google Cloud / Supabase) | 콘솔 설정이 바뀌면 함께 갱신 |
| `docs/email_verification_setup.md` | 이메일 6자리 인증번호 켜기 (Supabase SMTP → 메일 문구 → Confirm email) | Supabase 메일 설정이 바뀌면 함께 갱신 |
| `docs/handover_notes.md` | 예전 인수인계 문서 (설문 원본 수치·셀링 포인트·결정 이력) | 보관용. 현재 상태는 이 문서(`CONTEXT.md`)가 기준이며, 이 파일은 갱신하지 않음 |

## 3. 핵심 결정 사항 (요약)

- **리포트 링크에 데이터를 담는 방식**: 서버 비용 없이 학부모가 앱 설치·가입 없이 카톡에서 바로 열람.
- **5대 출결 체계**: `출석`(-1), `당일취소`(-1, 규정 차감), `결석`(0, 보강 필요), `순연`(0, 미리 연기), `보강`(-1).
- **수강료 골든타임**: 잔여 0~1회가 되면 모달이 뜨고 입금 계좌가 들어간 안내문을 자동 완성한 뒤 Web Share API로 공유(`executeShareKakaoTuition`).
- **보강 대기 위젯**: 결석 학생만 모아서 보강 일정을 잡게 함.
- **포지셔닝 피봇 (11-13)**: "출결 장부 앱"에서 **"수강료 누락을 막고 재등록률을 올리는 레슨 프로페셔널 패키지"**로 전환. 초기에는 유료화를 미루고 무료 배포로 사용자를 붙잡는다.
- **소셜 로그인 (11-24)**: 카카오·구글 로그인은 Supabase OAuth(`signInWithOAuth`)로 처리. 버튼은 `index.html`의 `OAUTH_PROVIDERS` 배열에서 자동 생성되며, 공통 핸들러는 `handleOAuthLogin(provider)`. Apple은 주석 처리된 한 줄로 대기 중. 돌아온 뒤에는 기존 `initSupabaseClient()` → `onAuthSessionEstablished()` 흐름을 그대로 사용.
- **멀티유저 (11-20)**: Supabase Auth 이메일/비밀번호 로그인. 7개 테이블을 `user_id` 기준으로 동기화하고, 유저별 PK 네임스페이스 적용.
- **카카오 공유 일원화 (11-20, `172b641`)**: 레슨 리포트 공유는 모두 `sendKakaoReportCard(noteId)` 하나로 처리(피드 카드 + `[레슨 리포트 상세보기]` 버튼, 링크는 GitHub Pages 절대경로).
- 시장 검증 (N=14, 뮬 설문): 10명 이하 소규모 레슨 78.6%, 횟수권 64.3%, 카톡 전달 64.3%, 관리 앱 지출 0%, 문제를 겪은 응답자 100%가 수강료 누락/안내 시점 놓침을 경험.

## 4. 코드와 문서를 대조하며 찾은 점 (주의)

1. **`supabase_schema.sql` 최신화 완료 (2026-11-23)**: 1~7번 테이블 `user_id UUID` 컬럼 및 `auth.uid() = user_id` RLS 정책, 8번 테이블(`fairy_shared_reports_v1`) 비로그인 학부모 열람(`SELECT`) + 작성자 쓰기 RLS 정책을 반영했습니다. Supabase SQL Editor에서 최신 SQL을 한 번 실행해 운영 DB와 맞춰 주세요.
2. **Kakao 공유 일원화는 코드상으로 끝난 상태입니다.** `Kakao.Share.sendDefault` 호출은 `sendKakaoReportCard()` 안 한 곳뿐이고, onclick 호출부는 두 곳(`index.html:1877` 공유 모달, `:3865` 노트 카드 하단)이며 둘 다 이 함수를 씁니다. 남은 것은 **실기기 검증**입니다.
3. 카카오 피드 카드는 `imageWidth: 800, imageHeight: 400`으로 선언했지만 실제 `icon-512.png`는 512×512입니다. 카드에서 이미지가 잘리거나 늘어나 보이면 800×400 썸네일을 따로 만드는 것을 검토하세요.
4. 수강료 골든타임 공유(`executeShareKakaoTuition`)는 Kakao SDK가 아니라 `navigator.share`(텍스트 공유)를 씁니다. 의도된 방식이며 통합 대상이 아닙니다.
5. `docs/handover_notes.md`에 적힌 내용 중 예전 정보: 캐시 버전(v3/v9 → 실제 v15), 작업 폴더 경로(`클로드작업/practice-fairy` → 실제 `test_1104`), 다음 할 일 중 "호스팅 배포"(이미 GitHub Pages로 완료).

## 5. 남은 마무리 작업

- [ ] **① 카카오 공유 최종 검증**: `fairy_shared_reports_v1` 단축 URL(`share.html?id=...`) 전환 및 `share.html` Supabase REST 조회 연동 완료(캐시 `v17`). **Supabase SQL Editor에서 `supabase_schema.sql` 하단 `fairy_shared_reports_v1` 생성 SQL 실행 필요**. 그 뒤 실기기 카톡에서 두 진입점(공유 모달, 노트 카드 하단)으로 카드가 정상 발송되고 `[레슨 리포트 상세보기]` 버튼이 열리는지 확인.
- [x] **② 카카오 개발자센터 앱(ID `1659300`) 기본 정보에 앱 아이콘 등록** (2026-11-24 `icons/icon-192.png`로 등록 완료) (사용자가 웹 콘솔에서 직접 진행. 플랫폼 > Web 사이트 도메인에 `https://znno-debug.github.io`가 등록되어 있는지도 함께 확인).
- [x] **③ 모바일(폭 ≤ 430px) 상단 헤더 반응형 다듬기**: `index.html:143` `<header>` 내 중복된 선생님 프로필 버튼(`#header-teacher-img`/`#header-teacher-name` ID 중복 포함)을 제거하고 모바일 패딩/간격을 컴팩트하게 정리. `sw.js` 캐시 `v18` 상향 완료.
- [x] (추가) `supabase_schema.sql`을 실제 운영 스키마(`user_id` + RLS)에 맞게 갱신 (4장 1번).
- [x] (추가) `README.md` 최신화 (Supabase Auth, 5대 출결, 카카오 카드 공유, 배포 URL).

- [x] **④ 소셜 로그인 콘솔 설정** (2026-11-24 완료): 카카오(로그인 ON, Redirect URI, 닉네임 필수·사진 선택, Client Secret), Google(프로덕션 게시, 웹 클라이언트), Supabase(Kakao·Google ON, Kakao "Allow users without an email" ON, Site URL·Redirect URLs). 로컬(localhost) Redirect URL은 미등록.
- [x] **⑤ 카카오 로그인 KOE205 해결** (2026-11-24 완료, 코드 수정 없음): 앱 기본 정보에 아이콘(`icons/icon-192.png`)·대표 도메인(`https://znno-debug.github.io`) 등록 → 카카오비즈니스 통합 약관 동의(필수만) → **개인 개발자 비즈 앱 전환**(목적: 이메일 필수 동의) → 동의항목 이메일 **선택 동의**(목적: 회원 식별 및 계정 안내). 닉네임 필수·사진 선택 유지, Supabase "Allow users without an email" ON 유지. iPhone Safari에서 카카오 로그인 성공 확인. (앱 아이콘 등록으로 ② 작업도 처리됨 — 카톡 공유 카드 표시 확인 필요)
- [ ] **⑥ 소셜 로그인 남은 실기기 테스트**: 구글 로그인, 로그아웃→다른 계정 로그인 시 데이터 분리, 같은 이메일 계정 합쳐짐 여부(Supabase Users의 Providers 열), 탈퇴 확인창 표시, 뒤로 가기 버튼 복구(v26), 카카오톡 인앱 브라우저.
- [ ] **⑦ 이메일 인증번호 켜기 (사용자 진행)**: `docs/email_verification_setup.md` 순서대로 ① 커스텀 SMTP 연결(기본 메일 서버는 팀원 주소로만 발송 → 비밀번호 재설정 메일도 일반 사용자에게 안 갈 수 있음) ② Confirm signup 메일에 `{{ .Token }}` ③ Confirm email ON. 2026-11-24 기준 `mailer_autoconfirm: true`(인증 없이 가입됨).
- [ ] **⑧ 가입 화면 2차 개선(선택)**: 로그인/회원가입 탭 없애고 "카카오로 시작하기" 중심 화면, 비밀번호 8자+확인칸+보기 버튼, 최근 로그인 방법 표시.
- [ ] (iOS 출시 시) Apple 로그인: `OAUTH_PROVIDERS`의 `apple` 줄 주석 해제 + Apple Developer/Supabase 설정.

- [x] **앱스토어 심사 대비 회원 탈퇴(`delete_my_account`) & 개인정보처리방침(`privacy.html`) 추가**: `supabase_schema.sql`에 `delete_my_account()` RPC 추가, `index.html` 로그인/프로필 모달 연결, 캐시 `v22`. (**Supabase SQL Editor에서 최신 `supabase_schema.sql` 실행 필요**)

## 6. 변경 이력

| 날짜 | 내용 |
| :--- | :--- |
| 2026-11-24 | 테스트 계정으로 이메일 가입→탈퇴 실사이트 검증(약관 필수 체크, 탈퇴 화면, Supabase 사용자 삭제 확인). 발견 사항 수정: 로그아웃·탈퇴 후 로그인 화면 초기화(`resetAuthScreen`: 이름·이메일·약관 체크·인증번호 비움), 탈퇴 후 배지를 '💾 로컬'로 되돌리고 뒤쪽 화면을 처음 방문 상태로 다시 그림(`rerenderAllViews`), 탈퇴 시 마지막 로그인 계정 ID도 삭제. 참고: 새 계정은 예시 데이터(수강생 4명 등)로 시작하는 것이 현재 설계(다른 계정 데이터는 `fairy_last_auth_uid_v1` 비교로 초기화됨), 캐시 `v28` |
| 2026-11-24 | **가입·탈퇴 흐름을 일반 앱 방식으로 개선**: ① 약관 동의(전체 동의, [필수] 만 14세·이용약관·개인정보) — 이메일 가입은 가입 화면에서, 소셜 첫 로그인·동의 기록 없는 기존 계정은 로그인 직후 동의 화면(`ensureTermsConsent`, `user_metadata.terms_agreed_at/terms_version`), 거절 시 로그아웃 ② 이메일 6자리 인증번호 화면(`verify_email` 모드, 다시 받기 60초 제한, 미인증 계정 로그인 시 자동 재발송, 이미 가입된 이메일 안내) — Supabase Confirm email을 켜야 동작 ③ 회원 탈퇴 전용 화면(`modal-delete-account`: 삭제될 데이터 개수 안내, 백업 버튼, 카카오/구글 연결 끊는 방법, 확인 체크 후 탈퇴). `privacy.html`에 `#privacy`/`#terms` 앵커, 소셜 로그인 수집 항목, 가입 연령(만 14세) 조항 추가. 가이드 `docs/email_verification_setup.md`, 캐시 `v27` |
| 2026-11-24 | 카카오 비즈 앱 전환·이메일 선택 동의로 KOE205 해결, 실기기 카카오 로그인 성공. 이메일 없는 사용자 코드 경로 재점검(헤더·설정·탈퇴 확인창·동기화 모두 `user.id` 기준, 문제 없음) |
| 2026-11-24 | 실기기 카카오 로그인에서 `KOE205`(설정하지 않은 동의 항목: `account_email`) 확인. 코드로는 해결 불가 → 카카오 개인 비즈 앱 전환 후 이메일 동의항목 설정 필요(남은 작업 ⑤) |
| 2026-11-24 | 소셜 로그인 버튼 버그 수정: 카카오/구글 화면에서 뒤로 가기로 돌아오면(브라우저 페이지 복원) 버튼이 '이동 중...'으로 멈춰 있던 문제 → `pageshow` 시 버튼 다시 그리기, 이동 중에는 모든 소셜 버튼 잠금. 카카오 로그인 페이지 진입까지 실기기 확인(로그인 완료·KOE205 여부는 미확인), 캐시 `v26` |
| 2026-11-24 | 콘솔 설정 검토: 구글 정상, 카카오는 `account_email` 자동 요청으로 KOE205 위험 확인(남은 작업 ⑤). 회원 탈퇴 확인창에서 이메일 없는 카카오 계정이 `계정()`으로 보이던 문제 수정(닉네임/"카카오 계정" 표시), 캐시 `v25` |
| 2026-11-24 | **카카오·구글 소셜 로그인 추가**: 로그인 화면 소셜 버튼(`OAUTH_PROVIDERS` 기반 자동 생성, 비밀번호 재설정 화면에서는 숨김), `handleOAuthLogin(provider)` 공통 핸들러(이동 전 Provider 활성 여부 사전 점검), 리다이렉트 오류(`?error=`/`#error=`) 안내 및 주소창 정리, 소셜 프로필 이름·사진을 기본 선생님 프로필에 반영, 이메일 없는 카카오 계정의 헤더 표시 보완, 설정 가이드 `docs/social_login_setup.md`, 캐시 `v24` |
| 2026-11-24 | 로그인 화면 `비밀번호를 잊으셨나요?`(이메일 재설정 링크 발송 + `PASSWORD_RECOVERY` 새 비밀번호 설정) 추가, 캐시 `v23` |
| 2026-11-24 | 앱스토어 심사 대비 `privacy.html`(개인정보처리방침·이용약관) 신설, `handleDeleteAccount()` 및 Supabase `delete_my_account()` RPC 추가, 캐시 `v22` |
| 2026-11-24 | **배포 장애 수정**: v20에서 주간 캘린더 함수에 `const weekdayHeader`가 두 번 선언되어 메인 스크립트 전체가 SyntaxError로 멈춤(앱 모든 버튼 무반응). 예전 `remove('hidden')` 두 줄 삭제, 캐시 `v21` |
| 2026-11-24 | 모바일 주간 캘린더 1열 요일별 리스트 전환(이름 잘림 해결) 및 중복 요일 헤더 숨김(캐시 `v20`) |
| 2026-11-24 | 모바일 월간 캘린더 셀 도트 넘침(`max 3개` + `N건`) 및 당일 수업 카드 이름·과목·회차·배지 줄바꿈 정렬 수정(캐시 `v19`) |
| 2026-11-23 | 모바일 상단 헤더 중복 프로필 버튼 제거 및 반응형 간격 정리(캐시 `v18`), `supabase_schema.sql` 유저별 `user_id`/RLS 정책 최신화, `README.md` 최신화 |
| 2026-11-21 | `fairy_shared_reports_v1` 테이블 추가 및 단축 공유 URL(`share.html?id=...`) 전환(긴 `?d=` 제거), `share.html` Supabase REST 조회 연동, 캐시 v17 |
| 2026-11-21 | 공유 코드 병합 사고 복구(HEAD로 되돌린 뒤 unifiedLink·resolvedId만 다시 적용), ExecutionParams 제외, 캐시 v16 |
| 2026-11-20 | `CONTEXT.md` 신설(이 문서), `CLAUDE.md`/`GEMINI.md` 에이전트 공통 지침 추가, `handover_notes.md` → `docs/`로 이동(보관용) |
| 2026-11-20 | 카카오 공유를 `sendKakaoReportCard` 하나로 통일, 캐시 v15 (`172b641`) |
| 2026-11-20 | 카카오 SDK 피드 카드 공유 + `share.html` 모바일 인앱 리포트 UI, GitHub Pages 절대 `shareUrl` (`4f1d1f6`~`41a9659`) |
| 2026-11-20 | Supabase Auth 이메일/비밀번호 로그인 + `user_id` 멀티유저 동기화 (`07a73bd`) |
| 2026-11-18 | Supabase 7개 테이블 스키마 + JS 동기화 엔진, JSON 백업/복원, GitHub Pages 배포 |
| 2026-11-13 | 설문 분석 → 포지셔닝 피봇, 5대 출결·골든타임 모달·보강 위젯 |
| 2026-11-07 | PWA 시제품 완성 |
