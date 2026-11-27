# CONTEXT — 연습요정 (Practice Fairy)

> **최종 갱신**: 2026-11-27 · `sw.js` 캐시 `fairy-cache-v39`
> **한 줄 요약**: 음악 1:1 레슨 선생님용 출결·수강료·레슨노트 관리 + 수강생 연습일지 PWA. 학부모에게는 카카오톡 카드로 1:1 리포트(`share.html`)를 보냄.
> **현재 단계**: 기능 시제품 완성, Supabase Auth 연동, GitHub Pages 배포 완료. 지금은 **카카오 공유 마무리와 모바일 다듬기** 단계.
> 이 문서는 작업 시작 전에 가장 먼저 읽고, 작업이 끝나면 곧바로 갱신한다(→ `CLAUDE.md` / `GEMINI.md`).

---

## 1. 인프라 / 환경

| 항목 | 값 | 소스 위치 |
| :--- | :--- | :--- |
| 배포 (GitHub Pages) | `https://znno-debug.github.io/practice-fairy/` | `index.html` `buildShareReportUrl()`, `sendKakaoReportCard()` |
| Supabase 프로젝트 | `https://zpfcocrqvmrotuiwpkru.supabase.co` (Auth + PostgreSQL + JS SDK v2) | `index.html:1926` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) |
| Supabase 테이블 (7개 + 공유 2개) | `fairy_teacher_profile_v1`, `fairy_students_v1`, `fairy_lessons_v1`, `fairy_notes_v1`, `fairy_practice_v1`, `fairy_questions_v1`, `fairy_sessions_v1`, `fairy_shared_reports_v1`, `fairy_parent_links_v1` | `supabase_schema.sql`, `index.html:1950~` (LocalStorage 키와 같은 이름) |
| 카카오 개발자센터 | 앱 ID `1659300`, JS SDK `2.7.2`, `KAKAO_JS_KEY`는 `index.html:1933` | `index.html:25`, `:1933` |
| PWA | `sw.js` (현재 `fairy-cache-v39`), `manifest.json`, `icons/`, 루트 `icon-512.png` | |
| 로컬 테스트 서버 | `python3 server.py` → `http://localhost:8080` (같은 Wi-Fi 기기용 IP 자동 표시) | `server.py` |
| 기술 스택 | HTML5 + Vanilla JS + Tailwind CSS(CDN) + Supabase + Web Audio API(체크 효과음만) + Service Worker + LocalStorage | |

## 2. 파일 구성

| 파일 | 역할 | 비고 |
| :--- | :--- | :--- |
| `index.html` (~5,400줄) | 메인 앱: 수업 캘린더, 레슨 노트, 수강생 관리, 마이 연습실, Auth 화면(`#auth-overlay`), PWA 설치 UI | 모든 로직이 이 파일 하나에 들어 있음 |
| `share.html` | 학부모/성인 수강생용 1:1 리포트(`?id=`) 및 학생별 고정 실시간 현황(`?p=`). 로그인 없이 전용 RPC로 열람 | `?p=<token>`은 `get_parent_student_status` RPC 실시간 조회, `?id=`는 `get_shared_report` RPC 조회 |
| `privacy.html` | 개인정보처리방침 및 서비스 이용약관 페이지 | 로그인 화면(`#auth-overlay`) 및 선생님 프로필 모달에서 연결 (스토어 심사 필수) |
| `sw.js` | 서비스 워커. HTML은 네트워크 우선, `/icons/`는 캐시 우선 | **HTML 수정 시 버전 +1 필수** |
| `manifest.json` | PWA 매니페스트 (상대 경로) | |
| `supabase_schema.sql` | 7개 테이블 + RLS 정책 SQL | **핵심 자산, 삭제 금지**. ⚠️ 4장 참고 |
| `build_icons.py` + `icons/` | PWA·파비콘 아이콘 생성 스크립트와 결과물 | **핵심 자산, 삭제 금지** |
| `icon-512.png` (루트) | 예전 카카오 카드 썸네일 (지금은 미사용, 예전 카드 표시용으로 보관) | 512×512 |
| `kakao-card.png` (루트) | 카카오 피드 카드 이미지 (`imageUrl`) | 800×400, 원본 `docs/assets/kakao_card.html` |
| `server.py` | 로컬 테스트 서버 | |
| `README.md` | 기능 소개 (11-06 기준이라 일부 내용이 예전 상태) | |
| `docs/social_login_setup.md` | 카카오·구글 소셜 로그인 웹 콘솔 설정 가이드 (카카오 개발자센터 / Google Cloud / Supabase) | 콘솔 설정이 바뀌면 함께 갱신 |
| `docs/email_verification_setup.md` | 이메일 6자리 인증번호 켜기 (Supabase SMTP → 메일 문구 → Confirm email) | Supabase 메일 설정이 바뀌면 함께 갱신 |
| `docs/sql/` | 운영 DB에 따로 실행할 변경 SQL (날짜별). 내용은 `supabase_schema.sql`에도 반영 | 실행했으면 변경 이력에 기록 |
| `docs/prompts/` | 다음 세션에 붙여 넣을 작업 지시문 (`parent_link_phase1.md`: 학부모 연결 0~1단계) | 작업이 끝나면 해당 지시문을 지우거나 '완료' 표시 |
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
- **학부모 고정 링크 1단계 (11-27)**: (B)안 확정 — `fairy_parent_links_v1` 테이블(3단계 확장용 `parent_user_id` 포함, anon 차단)과 화이트리스트 `SECURITY DEFINER` RPC `get_parent_student_status(p_token)`으로 실시간 조회. `index.html` 수강생 관리에서 생성·복사·카톡 카드(`sendKakaoParentLinkCard`)·켜기/끄기·재발급·학생 삭제 연동, `share.html?p=<token>`으로 열람.
- 시장 검증 (N=14, 뮬 설문): 10명 이하 소규모 레슨 78.6%, 횟수권 64.3%, 카톡 전달 64.3%, 관리 앱 지출 0%, 문제를 겪은 응답자 100%가 수강료 누락/안내 시점 놓침을 경험.

## 4. 코드와 문서를 대조하며 찾은 점 (주의)

1. **`supabase_schema.sql` 최신화 완료 (2026-11-23)**: 1~7번 테이블 `user_id UUID` 컬럼 및 `auth.uid() = user_id` RLS 정책, 8번 테이블(`fairy_shared_reports_v1`) 비로그인 학부모 열람(`SELECT`) + 작성자 쓰기 RLS 정책을 반영했습니다. Supabase SQL Editor에서 최신 SQL을 한 번 실행해 운영 DB와 맞춰 주세요.
2. **Kakao 공유 일원화는 코드상으로 끝난 상태입니다.** `Kakao.Share.sendDefault` 호출은 `sendKakaoReportCard()` 안 한 곳뿐이고, onclick 호출부는 두 곳(`index.html:1877` 공유 모달, `:3865` 노트 카드 하단)이며 둘 다 이 함수를 씁니다. 남은 것은 **실기기 검증**입니다.
3. 카카오 피드 카드는 `imageWidth: 800, imageHeight: 400`으로 선언했지만 실제 `icon-512.png`는 512×512입니다. 카드에서 이미지가 잘리거나 늘어나 보이면 800×400 썸네일을 따로 만드는 것을 검토하세요.
4. 수강료 골든타임 공유(`executeShareKakaoTuition`)는 Kakao SDK가 아니라 `navigator.share`(텍스트 공유)를 씁니다. 의도된 방식이며 통합 대상이 아닙니다.
5. `docs/handover_notes.md`에 적힌 내용 중 예전 정보: 캐시 버전(v3/v9 → 실제 v15), 작업 폴더 경로(`클로드작업/practice-fairy` → 실제 `test_1104`), 다음 할 일 중 "호스팅 배포"(이미 GitHub Pages로 완료).
6. **공유 리포트 전체 조회 문제 — 해결 완료 (2026-11-27)**: `fairy_shared_reports_v1` 읽기 정책이 `USING (true)`라 anon 키로 모든 리포트(학생 이름·노트·입금 계좌)를 목록 조회할 수 있었음(3건 조회 확인). 조치: anon 직접 조회 차단 + id가 정확히 일치하는 1건만 주는 `get_shared_report(p_id)` RPC(운영 DB 실행 완료, `docs/sql/2026-11-27_shared_report_lockdown.sql`), `share.html`은 RPC로만 조회, 새 링크 id는 `r_` + SHA-256(선생님 계정 전체 ID + 노트 id) 32자리(`toShareReportId`). 검증: anon 목록 조회 → `401 permission denied`, 기존 링크 2건 RPC로 열림, 없는 id는 `null`. 남은 참고: 예전 형식 링크 3건(`3752f7d5_n1`, `3752f7d5_n2`, `8dc4777d_n1`, 모두 테스트 데이터)은 앞 8자리를 아는 사람이 번호를 바꿔 볼 수 있는 형식이라, 정식 출시 전 지우는 것을 권장.

## 5. 남은 마무리 작업

- [x] **① 카카오 공유 최종 검증**: `fairy_shared_reports_v1` 단축 URL(`share.html?id=...`) 전환 및 `share.html` Supabase REST 조회 연동 완료(캐시 `v17`). (2026-11-25 확인: `fairy_shared_reports_v1` 테이블과 `delete_my_account` RPC 모두 운영 DB에 있음 → SQL 실행 완료). 남은 것: 실기기 카톡에서 두 진입점(공유 모달, 노트 카드 하단)으로 카드가 정상 발송되고 `[레슨 리포트 상세보기]` 버튼이 열리는지 확인. **2026-11-25 실기기 결과: 카드 발송은 됨, [상세보기] 버튼 클릭 안 됨.** `share.html?id=` 페이지 자체는 정상 열림(브라우저 확인) → 카카오 개발자센터의 링크 도메인 등록 문제로 추정. 확인할 곳: [앱] > [제품 링크 관리] > [웹 도메인](예전 콘솔은 [플랫폼] > [Web] > 사이트 도메인)에 `https://znno-debug.github.io` 등록. 등록 후에도 안 되면 오류 문구 캡처 필요. 예비안: 카드 대신 링크 문자 공유(도메인 등록 불필요). → **2026-11-25 원인 확인·조치**: [앱 설정] > [제품 링크 관리] > [웹 도메인]이 비어 있었음 → `https://znno-debug.github.io`(기본) 등록 완료(어사이드). **같은 날 실기기에서 [상세보기] 열림 성공 확인 → ① 완료.**
- [x] **② 카카오 개발자센터 앱(ID `1659300`) 기본 정보에 앱 아이콘 등록** (2026-11-24 `icons/icon-192.png`로 등록 완료) (사용자가 웹 콘솔에서 직접 진행. 플랫폼 > Web 사이트 도메인에 `https://znno-debug.github.io`가 등록되어 있는지도 함께 확인).
- [x] **③ 모바일(폭 ≤ 430px) 상단 헤더 반응형 다듬기**: `index.html:143` `<header>` 내 중복된 선생님 프로필 버튼(`#header-teacher-img`/`#header-teacher-name` ID 중복 포함)을 제거하고 모바일 패딩/간격을 컴팩트하게 정리. `sw.js` 캐시 `v18` 상향 완료.
- [x] (추가) `supabase_schema.sql`을 실제 운영 스키마(`user_id` + RLS)에 맞게 갱신 (4장 1번).
- [x] (추가) `README.md` 최신화 (Supabase Auth, 5대 출결, 카카오 카드 공유, 배포 URL).

- [x] **④ 소셜 로그인 콘솔 설정** (2026-11-24 완료): 카카오(로그인 ON, Redirect URI, 닉네임 필수·사진 선택, Client Secret), Google(프로덕션 게시, 웹 클라이언트), Supabase(Kakao·Google ON, Kakao "Allow users without an email" ON, Site URL·Redirect URLs). 로컬(localhost) Redirect URL은 미등록.
- [x] **⑤ 카카오 로그인 KOE205 해결** (2026-11-24 완료, 코드 수정 없음): 앱 기본 정보에 아이콘(`icons/icon-192.png`)·대표 도메인(`https://znno-debug.github.io`) 등록 → 카카오비즈니스 통합 약관 동의(필수만) → **개인 개발자 비즈 앱 전환**(목적: 이메일 필수 동의) → 동의항목 이메일 **선택 동의**(목적: 회원 식별 및 계정 안내). 닉네임 필수·사진 선택 유지, Supabase "Allow users without an email" ON 유지. iPhone Safari에서 카카오 로그인 성공 확인. (앱 아이콘 등록으로 ② 작업도 처리됨 — 카톡 공유 카드 표시 확인 필요)
- [ ] **⑥ 소셜 로그인 남은 실기기 테스트**: 구글 로그인, 로그아웃→다른 계정 로그인 시 데이터 분리, 같은 이메일 계정 합쳐짐 여부(Supabase Users의 Providers 열), 탈퇴 확인창 표시, 뒤로 가기 버튼 복구(v26), 카카오톡 인앱 브라우저.
- [x] **⑦ 이메일 인증번호 켜기** (2026-11-25 완료): Brevo SMTP(`smtp-relay.brevo.com:587`, 발신자 인증된 Gmail 주소, 이름 `연습요정`) 연결 → Confirm signup 메일을 `{{ .Token }}` 문구로 변경 → Confirm email ON(`mailer_autoconfirm: false`). 실제 가입 테스트(`+test2`)에서 인증 메일 발송 확인.
- [ ] **⑨ 인증 메일 품질**: 인증번호 길이는 2026-11-25 6자리로 변경 완료(Email OTP Length 6). 남은 문제: 메일이 스팸함으로 감(Gmail 발신 → Brevo가 brevosend.com 주소로 바꿔 보냄). 근본 해결은 자체 도메인 구매 + Brevo 도메인 인증.
- [x] **⑧ 가입 화면 2차 개선** (2026-11-25 완료, v31): 탭 제거 → 첫 화면은 카카오·Google '시작하기' + 이메일 로그인, 회원가입·비밀번호 찾기·인증은 뒤로 가기가 있는 하위 화면. 새 비밀번호 8자+영문+숫자, 확인 칸, 보기 버튼, 실시간 안내. 최근 로그인 방법 배지(`fairy_last_login_method_v1`).
- [ ] **⑩ 학부모 연결: 링크 + 앱 이원 운영 (2026-11-27 방향 확정)**: 배경은 워킹맘 교수님 피드백("여러 수업의 남은 횟수·납부 시점을 엄마가 알 수 없고, 선생님도 물어보면 그제서야 셈"). GPS·QR 출석은 1:1 레슨에 맞지 않아 **하지 않기로 결정**(도착 ≠ 차감, 미성년자 위치정보 부담). 학생 가입보다 **학부모 가입**이 우선(보호자가 직접 동의 → 만 14세 미만 문제 해결). 앱스토어 앱 기준. 원칙: **데이터는 하나, 보는 창은 두 개**(링크=가입 없이 이 수업의 현재 상태 / 앱=여러 선생님 수업 한 화면 + 푸시 알림), 링크를 일부러 불편하게 만들지 않음, 링크에서 앱 설치 시 자동 연결.
  - [x] 0단계: 공유 리포트 보안 수정 (4장 6번) — **완료** (2026-11-27, v35)
  - [ ] 1단계: 학생별 고정 학부모 링크 — 코드·SQL 구현 완료 (2026-11-27, v36, `docs/sql/2026-11-27_parent_links.sql`). 2026-11-27 운영 DB에 SQL 실행 완료(Success), 배포 완료. **실계정 테스트(11-27) 결과: 링크가 열리지 않음** — 원인은 기존 동기화 버그. 클라우드 학생·수업·노트에 옛 ID(`s1`)와 새 ID(`<uid8>_s1`)가 함께 있어, 저장 때 같은 ID가 한 번에 두 번 올라가 upsert가 매번 실패(21000 `ON CONFLICT DO UPDATE command cannot affect row a second time`). 그래서 새 학생이 클라우드에 없고 RPC는 null. (1)(2) 코드 수정 완료(v37): `dedupeCloudRowsByLocalId`(불러올 때 같은 항목은 최신 저장본 1개만), `dedupeRowsByKey`(업로드 직전 같은 ID 1개만), 링크 생성 전 동기화 실패 시 링크를 만들지 않고 안내. (4) 어사이드 재테스트 통과(11-27, 0~9단계 전부 성공). (3) 클라우드 옛 ID 중복 줄 정리 완료(11-27, 6개 테이블 24줄, `fairy_backup` 스키마에 백업). 남은 것: 선생님 프로필 옛 `default` 행 삭제(승인 대기, SQL은 `docs/sql/2026-11-27_legacy_id_cleanup.sql` 아래쪽), 선생님 이름 등 프로필 다시 입력.
  - [ ] 2단계: 앱 포장(Capacitor 등 기존 HTML/JS 재사용) + Apple 로그인 + 유니버설 링크(앱 있으면 앱, 없으면 웹)
  - [ ] 3단계: 학부모 계정·아이 프로필·여러 선생님 수업 연결(읽기 전용 권한, 선생님이 공개 항목 선택)
  - [ ] 4단계: 푸시 알림(수업 완료·납부 미리 알림·보강), 선생님 카톡 공유와 중복 방지, 연결 해제
- [ ] (iOS 출시 시) Apple 로그인: `OAUTH_PROVIDERS`의 `apple` 줄 주석 해제 + Apple Developer/Supabase 설정.
- [ ] **⑪ '오늘'을 실제 날짜로 바꾼 뒤 남은 날짜 관련 결정 (2026-11-27, v38)**:
  - [ ] 학생 마이 연습실 '오늘 총 누적 연습량'·타임라인이 날짜 구분 없이 **모든 날의 연습 기록을 합침**(`renderPracticeSessionsTimeline`). 예전엔 모든 기록이 11/06이라 티가 안 났음. 오늘 것만 보일지, 날짜별로 묶어 보일지 기획 결정 필요.
  - [ ] 학부모 화면 '다음 수업'(`get_parent_student_status` RPC)은 날짜와 상관없이 상태가 `예정`인 가장 이른 수업을 고름 → 지난 날짜에 처리 안 한 `예정` 수업이 '다음 수업'으로 보일 수 있음(SQL 수정 시 운영 DB 실행 필요).
  - [ ] 예시 데이터는 2026-11-06 장면으로 고정(`DEMO_SEED_DATE`). 12월 이후 가입한 새 계정은 캘린더 첫 화면(이번 달)과 '오늘 예정 레슨'에 예시 수업이 안 보이고, 지난달로 넘겨야 보임. 첫인상이 아쉬우면 가입일 기준으로 예시 날짜를 옮기는 방안 검토.
  - [ ] v38 이전에 남긴 질문 시각·노트 작성 시각(`createdAt`)은 UTC로 저장돼 9시간 이르게 보임(새로 남기는 것부터 한국 시간). 필요하면 기존 값 보정.

- [x] **앱스토어 심사 대비 회원 탈퇴(`delete_my_account`) & 개인정보처리방침(`privacy.html`) 추가**: `supabase_schema.sql`에 `delete_my_account()` RPC 추가, `index.html` 로그인/프로필 모달 연결, 캐시 `v22`. (2026-11-25 실사이트 탈퇴 테스트로 RPC 동작 확인)

## 5-1. 정식 배포 전 필수 체크 (리마인드)

> 정식 배포·홍보 전에 아래를 다시 확인한다. 에이전트는 "정식 배포/출시/오픈" 이야기가 나오면 이 목록을 먼저 알린다.

- [ ] **인증 메일 스팸함 문제 (2026-11-25 보류 결정)**: 자체 도메인 구매 → Brevo 도메인 인증(DKIM·DMARC) → Supabase SMTP 발신 주소를 도메인 주소로 변경. 도메인을 바꾸면 앱 주소 변경에 맞춰 카카오(플랫폼 도메인·Redirect), Google(JS 원본), Supabase(Site URL·Redirect URLs)도 함께 갱신.
- [ ] **개인정보처리방침 문의처**: `privacy.html` 3장이 GitHub 저장소로만 안내됨 → 개인정보 보호책임자 이름·연락 이메일 기재.
- [ ] **사업자 정보·보호책임자**: 유료화·사업자 등록 시 `privacy.html` 3장 TODO 주석 위치에 상호·대표자·사업자등록번호·연락처 기재.
- [ ] **Supabase 서버 지역 (2026-11-25 확인: `ap-south-1` 인도 뭄바이, Free 플랜)**: `privacy.html` 표에 반영 완료. 사용자가 한국이라 서울(`ap-northeast-2`)보다 응답이 느림. 지역은 바꿀 수 없어 새 프로젝트를 만들어 옮겨야 하므로, **실사용자가 쌓이기 전에** 이전 여부 결정(옮기면 URL·키·카카오/구글 Redirect·SMTP 설정 모두 다시).
- [ ] **Supabase 무료 플랜 제약**: 7일간 사용이 없으면 프로젝트가 일시 정지되고 자동 백업이 없음 → 정식 운영 시 Pro 플랜 또는 정기 백업 검토.
- [ ] **발송 한도**: Brevo 무료 하루 300통, Supabase 인증 메일 시간당 30통(Rate Limits) → 가입 몰림 대비 확인.

## 6. 변경 이력

| 날짜 | 내용 |
| :--- | :--- |
| 2026-11-27 | **'오늘' 날짜를 실제 한국 날짜로 변경**: 예전 시연용 고정값(`todayStr = '2026-11-06'`, `new Date(2026, 10, 6)`)을 `getKoreaTodayStr()`(Asia/Seoul 기준, `toISOString()` UTC 밀림 방지, 옛 브라우저는 기기 시간)로 교체. 캘린더 첫 화면·[오늘] 버튼·대시보드 '오늘 예정 레슨'/'이번 달 수업'·새 노트 기본 날짜·연습 기록 날짜가 실제 오늘 기준. 앱을 켜 둔 채 자정이 지나면 화면 복귀 시 '오늘'을 새로 맞춤(`refreshTodayIfDateChanged`, `visibilitychange`). 질문 시각·노트 작성 시각도 UTC → 한국 시간(`getKoreaNowStamp`). 예시(시드) 데이터는 `DEMO_SEED_DATE = '2026-11-06'`으로 고정해 그대로 유지(기기·가입일마다 예시 날짜가 달라져 동기화 충돌이 나지 않게). 날짜가 6일로 고정돼 숨어 있던 월 이동 버그(31일에서 다음 달 누르면 한 달 건너뜀) 수정. 로컬 확인: 캘린더 11/27로 열림·[오늘] 버튼·월 이동(1/31→2월, 3/31→2월)·주간 보기·자정 경과 흉내 모두 정상, LA 시간대 기기에서도 한국 날짜 계산 확인. 캐시 `v38` |
| 2026-11-27 | 어사이드로 v37 재테스트(localhost 탭): 학생 목록 8→4명 정상, 저장 후 `☁️ 동기화됨`, 링크 생성→열람(8회)→출석 후 7회·출석 표시→끄기 차단→켜기 열림→재발급(옛 링크 차단·새 링크 열림)→학생 삭제 후 차단까지 모두 성공. 21000 오류 없음. 테스트 데이터 삭제, 기존 학생 횟수 변화 없음. 참고: 앱 '오늘'이 `todayStr = '2026-11-06'`·`new Date(2026, 10, 6)`으로 고정됨(예전 시연용 값) |
| 2026-11-27 | **클라우드 옛 ID 중복 정리**(어사이드로 운영 DB 실행): 미리보기(`docs/sql/2026-11-27_legacy_id_preview.sql`)로 계정 8dc4777d에만 중복 24쌍, 모두 새 ID 줄이 최신임을 확인 후 `docs/sql/2026-11-27_legacy_id_cleanup.sql`로 `fairy_backup.*_legacy_20261127`에 백업하고 삭제(학생 4·수업 6·노트 3·질문 4·연습 4·연습기록 3). `fairy_backup`은 외부 API 비노출 확인(PGRST106). 정리 후 앱: 학생 4·노트 3·수업 6 그대로, 중복 경고·동기화 오류 없음. **발견된 사고**: 선생님 프로필에도 옛 `default` 행(예시 프로필 '김민주')이 남아 있었고, 앱이 불러올 때 순서 없는 `data[0]`을 써서 v37 재테스트 중(15:58 KST, 링크 생성 전 동기화) 실제 프로필(이름 '이준오' 등)이 예시 값으로 덮어써짐. 수정: `pullAllFromSupabase`가 `id = user_id` 행을 우선 사용. 캐시 `v39` |
| 2026-11-27 | **클라우드 동기화 실패 수정**(11-20부터 있던 버그): 옛 ID와 새 ID가 같은 항목으로 합쳐져 upsert가 21000으로 매번 실패하던 문제. `pullAllFromSupabase`에서 `dedupeCloudRowsByLocalId`로 최신 저장본 1개만 남기고, `syncTableToSupabase`에서 `dedupeRowsByKey`로 같은 ID 중복 업로드 차단. `createParentLinkForCurrentStudent`는 사전 동기화 실패 시 링크를 만들지 않고 안내. 캐시 `v37` |
| 2026-11-27 | 어사이드로 학부모 링크 실계정 테스트(localhost 탭, 로그인 계정). 테스트 학생 추가→링크 생성→출석→끄기/켜기→재발급→삭제까지 진행했으나 공유 화면은 모두 '열람할 수 없는 링크'. 원인: 클라우드 ID 중복으로 동기화 upsert 실패(11-20부터 있던 버그). 테스트 학생·링크는 삭제 완료, 기존 학생 데이터 변경 없음. 코드 변경 없음 |
| 2026-11-27 | 어사이드로 운영 DB에 `2026-11-27_parent_links.sql` 실행(Success). 확인: `get_parent_student_status` 없는 토큰에 null 반환, `fairy_parent_links_v1` anon 직접 조회 거부(42501), 기존 `get_shared_report` 정상. v36 배포(푸시) |
| 2026-11-27 | **학부모 연결 1단계(학생별 고정 학부모 링크) 구현**: (B)안 실시간 전용 RPC 채택. `fairy_parent_links_v1` 테이블(anon 차단, 3단계 확장용 `parent_user_id` 포함) + 화이트리스트 `get_parent_student_status(p_token)` RPC 및 `delete_my_account` 연동(`supabase_schema.sql`, `docs/sql/2026-11-27_parent_links.sql`). `index.html` 수강생 카드에 `[학부모 링크]` 관리 모달(생성·복사·`sendKakaoParentLinkCard` 카톡 카드 공유·켜기/끄기·재발급) 및 `deleteStudent` 삭제 연동 추가. `share.html?p=<token>` 실시간 현황 화면(남은 횟수·다음 수업·납부 강조/계좌 복사·최근 5대 출결·최근 레슨 노트·무효 링크 차단 안내) 구현. 캐시 `v36` |
| 2026-11-27 | 어사이드로 운영 DB에 `2026-11-27_shared_report_lockdown.sql` 실행(Success). anon 목록 조회 차단·기존 링크 열림 확인 후 `share.html` 임시 폴백 제거, 캐시 `v35` |
| 2026-11-27 | **공유 리포트 보안 수정**(4장 6번): `get_shared_report` RPC 추가·공개 읽기 정책 삭제(`supabase_schema.sql`, `docs/sql/2026-11-27_shared_report_lockdown.sql`), `share.html` RPC 조회(미실행 DB 폴백), 새 링크 id를 추측 불가한 해시로(`toShareReportId`, 동기식 `sha256Hex`), 수강생 삭제 시 새 id 리포트도 삭제. 쓰이지 않던 `fairy_notes_v1` 직접 조회 폴백 제거. 캐시 `v34` |
| 2026-11-27 | 기획 결정: GPS·QR 출석 안 함, 학부모 연결을 '링크 + 앱' 이원 운영으로 진행(남은 작업 ⑩). 공유 리포트 테이블 전체 조회 보안 문제 발견(4장 6번). 다음 세션 지시문 `docs/prompts/parent_link_phase1.md` 작성. 코드 변경 없음 |
| 2026-11-25 | 학생 마이 연습실에서 메트로놈 카드와 관련 코드(박자·BPM·재생) 삭제. 체크리스트를 눌렀을 때 나는 짧은 효과음은 `playTickSound`로 이름만 바꿔 유지. 예시 과제 문구 속 '메트로놈 ♩=84'와 칭찬 뱃지 '완벽한 메트로놈 박자'는 레슨 내용이라 그대로 둠. 캐시 `v33` |
| 2026-11-25 | 카카오 [상세보기] 실기기 성공(① 완료). 카톡 공유 카드 이미지를 정사각 아이콘에서 800×400 전용 이미지 `kakao-card.png`로 교체(원본 `docs/assets/kakao_card.html`, Chrome headless로 생성). Supabase 서버 지역 확인(인도 뭄바이) → `privacy.html` 위탁 표 반영. 캐시 `v32` |
| 2026-11-25 | 카카오 [상세보기] 버튼 미동작 원인: 제품 링크 관리 > 웹 도메인 미등록. `https://znno-debug.github.io` 등록(코드 수정 없음) |
| 2026-11-25 | **가입 화면 2차 개선**: 로그인/회원가입 탭 제거, 첫 화면 '카카오로 시작하기'·'Google로 시작하기' + 이메일 로그인, 회원가입·비밀번호 찾기·이메일 인증·새 비밀번호는 뒤로 가기 있는 하위 화면, 새 비밀번호 규칙 8자 이상+영문+숫자(기존 계정 로그인은 제한 없음)와 확인 칸·보기 버튼·실시간 안내, '최근 로그인' 배지, 입력칸 label 연결. 캐시 `v31` |
| 2026-11-25 | **법·신뢰·접근성 점검 1차 (20개 체크리스트 중 현재 단계 항목)**: ① 수강생 개별 삭제(`deleteStudent`: 일정·노트·질문·연습 기록·공유 리포트 링크를 기기와 클라우드에서 함께 삭제, 학부모 삭제 요청 대응), 지운 예시 수강생(`s4`) 자료가 다시 생기던 문제 차단(`hasStudentLocally`) ② 수강생 등록 창에 만 14세 미만 보호자 동의 안내 ③ 기본 프로필을 외부 인물 사진(Unsplash)에서 자체 아이콘 `icons/avatar-default.svg`로 교체(기존 계정도 자동 교체) ④ 접근성: 키보드 포커스 테두리, Esc로 창 닫기, 아이콘 버튼 이름(aria-label), 연회색 글자 대비 보강(index·share), 설치 배너 키보드 조작 ⑤ 과장 문구 '1초만에' 삭제 ⑥ `privacy.html`: 불필요 정보 미수집, 처리 위탁·국외 이전 표(Supabase·Brevo·GitHub·카카오·Google), 쿠키·기기 저장소(추적 쿠키 없음 → 동의 배너 불필요), 아동 정보, 이용자 권리(열람·내려받기·삭제, 광고 메일 없음), 이용약관 제5조 이용 요금(현재 무료·유료화 시 30일 전 고지·별도 동의), 글꼴·오픈소스 이용 안내 ⑦ svg `viewBox` 오류 수정. 약관 버전(`TERMS_VERSION`)은 그대로라 기존 사용자 재동의 없음, 캐시 `v30` |
| 2026-11-25 | Supabase Email OTP Length 8 → 6 변경(일반 앱과 같은 6자리 인증번호) |
| 2026-11-25 | Supabase 이메일 인증 설정 완료(Brevo 커스텀 SMTP, 인증번호 메일 문구, Confirm email ON). 실사이트 가입 테스트에서 인증 메일 도착 확인: 8자리 번호, 스팸함 도착(남은 작업 ⑨) |
| 2026-11-24 | **새 계정은 연락처·소개·입금 계좌 빈칸으로 시작**(`defaultTeacherProfile`): 예시 계좌가 학부모 수강료 안내에 나가는 위험 제거. 예전 예시값(`010-9876-1234`, 예시 약력, `3333-01-2345678`)이 남은 기존 계정은 `stripLegacyDemoProfile`로 빈칸 처리(저장 시 클라우드에도 반영). 계좌가 없으면 수강료 안내 문구에서 계좌 줄 생략, 안내 모달은 '등록 전' 표시·복사 시 등록 안내, `share.html` 납부 카드는 '선생님께 문의' 표시·복사 버튼 숨김. 프로필 계좌번호 필수 입력 해제. 예시 수강생·수업·노트는 그대로 유지, 캐시 `v29` |
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
