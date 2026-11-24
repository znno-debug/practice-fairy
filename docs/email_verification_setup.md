# 이메일 인증번호(6자리) 켜기 — Supabase 설정 가이드

> 코드(`index.html`의 `verify_email` 화면, `resendSignupOtp`)는 이미 들어가 있습니다.
> 지금(2026-11-24)은 Supabase의 **Confirm email이 꺼져 있어서** 이메일로 가입하면 인증 없이 바로 가입됩니다.
> 아래 설정을 마치면 가입할 때 "메일로 받은 숫자 입력" 단계가 자동으로 나타납니다.

설정 순서: **① 메일 발송 서버(SMTP) → ② 메일 문구 → ③ Confirm email 켜기** (순서를 지켜야 가입이 막히지 않습니다)

---

## ① 메일 발송 서버(SMTP) 연결 — 꼭 먼저

Supabase 기본 메일 서버는 **프로젝트 팀원 이메일로만, 시간당 몇 통만** 보냅니다. 그래서 실제 선생님들이 가입하면 인증 메일이 오지 않습니다. 비밀번호 재설정 메일도 지금 같은 이유로 일반 사용자에게는 오지 않을 수 있습니다.

1. 메일 발송 서비스를 하나 고릅니다. **우리 앱은 자체 도메인이 없어서(github.io) 도메인 인증이 필요 없는 서비스**를 골라야 합니다.
   - **Brevo (추천)**: 무료 하루 300통, 도메인 없이 "보내는 사람 이메일" 하나만 인증하면 됨. SMTP: `smtp-relay.brevo.com` / 포트 `587` / 사용자 이름·비밀번호는 Brevo [SMTP & API] 화면의 SMTP 로그인·SMTP 키
   - Gmail SMTP: 구글 계정 2단계 인증 + **앱 비밀번호** 필요, 보내는 사람이 개인 Gmail 주소로 보임. SMTP: `smtp.gmail.com` / 포트 `465`
   - Resend·SendGrid: 자체 도메인을 인증해야 일반 사용자에게 보낼 수 있어서 지금은 맞지 않음
2. 그 서비스에서 발송용 이메일을 인증하고 **SMTP 정보**(호스트, 포트, 사용자 이름, 비밀번호)를 받습니다
3. Supabase Dashboard → **Authentication > Emails > SMTP Settings** → **Enable custom SMTP** ON
   - Sender email: 발송용 주소 (예: `noreply@...`)
   - Sender name: `연습요정`
   - Host / Port / Username / Password: 2번에서 받은 값 → **Save**
4. **Authentication > Rate Limits**에서 이메일 발송 한도가 너무 낮지 않은지 확인합니다 (예: 시간당 30통 이상)

## ② 인증 메일 문구를 "숫자 인증번호"로 바꾸기

> ⚠️ Supabase는 **커스텀 SMTP를 켜기 전에는 메일 문구를 수정할 수 없게** 막아 둡니다(2026-11-25 확인). ①을 먼저 끝내야 이 단계가 열립니다.

Supabase Dashboard → **Authentication > Emails > Templates** → **Confirm signup**

- **Subject**: `[연습요정] 이메일 인증번호`
- **Body** (전체를 아래로 바꿈):

```html
<h2>연습요정 이메일 인증</h2>
<p>아래 인증번호를 연습요정 가입 화면에 입력해 주세요.</p>
<p style="font-size:28px;font-weight:bold;letter-spacing:6px;">{{ .Token }}</p>
<p>인증번호는 1시간 동안 유효합니다. 본인이 요청하지 않았다면 이 메일을 무시해 주세요.</p>
```

- `{{ .Token }}` 자리에 6자리 숫자가 들어갑니다. **Save**

## ③ Confirm email 켜기

Supabase Dashboard → **Authentication > Sign In / Providers** → **Email** → **Confirm email** ON → Save

## ④ 동작 확인

1. 앱 로그인 화면 → [새 선생님 회원가입] → 이메일·비밀번호 입력, 약관 전체 동의 → 가입하기
2. "인증번호를 보냈어요" 안내와 숫자 입력칸이 나오면 정상
3. 메일의 숫자를 입력 → "이메일 인증과 회원가입이 완료되었습니다!"가 나오면 성공
4. 인증 전에 창을 닫았다가 나중에 로그인하면, 앱이 새 인증번호를 다시 보내고 입력 화면으로 안내합니다

### 알아 둘 점
- **2026-11-25 실제 테스트 결과**: Brevo SMTP 연결·문구 변경·Confirm email 완료 후 가입 시 인증 메일 발송 확인.
  - 처음엔 인증번호가 **8자리**로 옴(Supabase 기본값) → 같은 날 Authentication > Sign In / Providers > Email > **Email OTP Length**를 **6**으로 변경함. 앱은 6~8자리 모두 받음.
  - 메일이 **스팸함**으로 감. 보내는 주소가 개인 Gmail이라 Brevo가 발신 주소를 `…@…brevosend.com`으로 바꿔 보내기 때문. 근본 해결은 자체 도메인을 사서 Brevo에서 도메인 인증(DKIM·DMARC)을 하는 것.
- 이미 가입된 이메일로 다시 가입하면 "이미 가입된 이메일입니다" 안내가 나옵니다.
- [인증번호 다시 받기]는 60초에 한 번 누를 수 있습니다.
- Confirm email을 켜기 전에 가입한 기존 계정은 그대로 로그인됩니다.
