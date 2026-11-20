# 에이전트 공통 지침 — 연습요정 (Practice Fairy)

> 이 파일은 `CLAUDE.md`(Claude Code)와 `GEMINI.md`(Antigravity IDE)에 **똑같은 내용**으로 들어 있다.

## 필수 규칙

1. **작업 시작 전 `CONTEXT.md`를 먼저 읽는다.** 인프라, 파일 구성, 결정 사항, 남은 작업을 확인한 뒤 시작한다.
2. **작업이 끝나면 곧바로 `CONTEXT.md`를 갱신한다.** 변경 사항은 "변경 이력"에, 남은 할 일은 "남은 마무리 작업" 체크리스트에 반영한다.
3. **`index.html` 또는 `share.html`을 수정하면 `sw.js`의 캐시 버전을 한 단계 올린다.** (`CACHE_NAME = 'fairy-cache-vN'` → `vN+1`, 첫 줄 주석도 함께 수정.) 모바일에 구버전 캐시가 남지 않게 하기 위함이다.
4. **`build_icons.py`, `supabase_schema.sql`, `icons/` 폴더는 핵심 자산이다. 임의로 삭제하지 않는다.**
5. **프로젝트 규칙이 바뀌면 `CLAUDE.md`와 `GEMINI.md` 두 파일을 항상 같은 내용으로 맞춘다.**

## 참고

- 사용자는 기획자에 가까우므로 설명은 쉬운 서비스/비즈니스 언어로 한다.
- 배포: GitHub Pages(`main` 푸시). 로컬 테스트: `python3 server.py`.
- 앱 로직은 대부분 `index.html` 한 파일에 있다. 수정 전에 관련 함수를 `grep`으로 찾는다.
