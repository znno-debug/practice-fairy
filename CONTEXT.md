# CONTEXT — 연습요정 (Practice Fairy)

> **최종 갱신**: 2026-11-24 · `sw.js` 캐시 `fairy-cache-v20`
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
| PWA | `sw.js` (현재 `fairy-cache-v17`), `manifest.json`, `icons/`, 루트 `icon-512.png` | |
| 로컬 테스트 서버 | `python3 server.py` → `http://localhost:8080` (같은 Wi-Fi 기기용 IP 자동 표시) | `server.py` |
| 기술 스택 | HTML5 + Vanilla JS + Tailwind CSS(CDN) + Supabase + Web Audio API + Service Worker + LocalStorage | |

## 2. 파일 구성

| 파일 | 역할 | 비고 |
| :--- | :--- | :--- |
| `index.html` (~5,400줄) | 메인 앱: 수업 캘린더, 레슨 노트, 수강생 관리, 마이 연습실, Auth 화면(`#auth-overlay`), PWA 설치 UI | 모든 로직이 이 파일 하나에 들어 있음 |
| `share.html` | 학부모/성인 수강생용 1:1 리포트. 링크 안 데이터만으로 열림(로그인 없음) | `?id=...&d=<base64url JSON 배열>`을 읽고, 예전 `#d=` 해시 방식도 지원 |
| `sw.js` | 서비스 워커. HTML은 네트워크 우선, `/icons/`는 캐시 우선 | **HTML 수정 시 버전 +1 필수** |
| `manifest.json` | PWA 매니페스트 (상대 경로) | |
| `supabase_schema.sql` | 7개 테이블 + RLS 정책 SQL | **핵심 자산, 삭제 금지**. ⚠️ 4장 참고 |
| `build_icons.py` + `icons/` | PWA·파비콘 아이콘 생성 스크립트와 결과물 | **핵심 자산, 삭제 금지** |
| `icon-512.png` (루트) | 카카오 피드 카드 썸네일 (`imageUrl`) | 512×512 정사각형 |
| `server.py` | 로컬 테스트 서버 | |
| `README.md` | 기능 소개 (11-06 기준이라 일부 내용이 예전 상태) | |
| `docs/handover_notes.md` | 예전 인수인계 문서 (설문 원본 수치·셀링 포인트·결정 이력) | 보관용. 현재 상태는 이 문서(`CONTEXT.md`)가 기준이며, 이 파일은 갱신하지 않음 |

## 3. 핵심 결정 사항 (요약)

- **리포트 링크에 데이터를 담는 방식**: 서버 비용 없이 학부모가 앱 설치·가입 없이 카톡에서 바로 열람.
- **5대 출결 체계**: `출석`(-1), `당일취소`(-1, 규정 차감), `결석`(0, 보강 필요), `순연`(0, 미리 연기), `보강`(-1).
- **수강료 골든타임**: 잔여 0~1회가 되면 모달이 뜨고 입금 계좌가 들어간 안내문을 자동 완성한 뒤 Web Share API로 공유(`executeShareKakaoTuition`).
- **보강 대기 위젯**: 결석 학생만 모아서 보강 일정을 잡게 함.
- **포지셔닝 피봇 (11-13)**: "출결 장부 앱"에서 **"수강료 누락을 막고 재등록률을 올리는 레슨 프로페셔널 패키지"**로 전환. 초기에는 유료화를 미루고 무료 배포로 사용자를 붙잡는다.
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
- [ ] **② 카카오 개발자센터 앱(ID `1659300`) 기본 정보에 `icon-512.png` 앱 아이콘 등록** (사용자가 웹 콘솔에서 직접 진행. 플랫폼 > Web 사이트 도메인에 `https://znno-debug.github.io`가 등록되어 있는지도 함께 확인).
- [x] **③ 모바일(폭 ≤ 430px) 상단 헤더 반응형 다듬기**: `index.html:143` `<header>` 내 중복된 선생님 프로필 버튼(`#header-teacher-img`/`#header-teacher-name` ID 중복 포함)을 제거하고 모바일 패딩/간격을 컴팩트하게 정리. `sw.js` 캐시 `v18` 상향 완료.
- [x] (추가) `supabase_schema.sql`을 실제 운영 스키마(`user_id` + RLS)에 맞게 갱신 (4장 1번).
- [x] (추가) `README.md` 최신화 (Supabase Auth, 5대 출결, 카카오 카드 공유, 배포 URL).

## 6. 변경 이력

| 날짜 | 내용 |
| :--- | :--- |
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
