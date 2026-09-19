# بوت نتائج نجاح (Telegram)

بوت تلغرام فقط — لا يوجد موقع ولا لوحة تحكم ولا قاعدة بيانات.

## التشغيل

```bash
cd bot
cp .env.example .env     # ضع TELEGRAM_BOT_TOKEN
npm install
npx playwright install chromium
npm run dev              # أو: npm run build && npm start
```

## النشر 24/7 على Render

البوت يعمل بنظام long polling فلا يحتاج رابطاً عاماً — يُنشر على Render
كـ **Background Worker** (وليس Web Service). ملفات النشر جاهزة:
`Dockerfile` + `render.yaml`.

خطوات النشر:

1. ارفع مجلد `bot/` إلى مستودع GitHub (ولا ترفع ملف `.env` أبداً).
2. من لوحة Render: **New → Background Worker**.
3. اربط المستودع، وفي إعدادات الخدمة اختر:
   - **Root Directory**: `bot` (إن كان المستودع يحتوي أشياء أخرى)
   - **Runtime**: Docker — سيقرأ `Dockerfile` تلقائياً
   - (أو استخدم ملف `render.yaml` عبر **New → Blueprint**)
4. في **Environment** أضف المتغيرات:
   - `TELEGRAM_BOT_TOKEN` = التوكن من @BotFather
   - `NAJAH_AUTOMATION_AUTHORIZED` = `true`
5. اضغط **Create Worker** — سيبني الصورة ويثبّت Chromium تلقائياً ويعمل 24/7.
6. سجلات البوت تظهر مباشرة في تبويب **Logs** في Render.

مهم: لا تشغّل نسختين من البوت بنفس التوكن في نفس الوقت (نسخة محلية +
نسخة على Render) — تلغرام يسمح باستقبال رسائل من نسخة واحدة فقط،
فأوقف النسخة المحلية قبل تشغيل نسخة Render.

```

## ما اكتُشف فعلياً عن موقع najah.iq

تم تحليل الموقع مباشرة (وليس افتراضاً):

- صفحة الدخول `https://najah.iq/` ترسل:
  `POST https://najah.iq/api/student/student_check`
  بجسم JSON: `{ student_number, student_code, altcha }`
  (لا كوكيز، لا CSRF، لا session — الرد JSON يُخزَّن في localStorage باسم `studentData`).
- صفحة النتيجة `https://najah.iq/results.html` تبني الجدول من ذلك الـ JSON في المتصفح،
  وفيها زر "🖨️ طباعة النتيجة" الذي يستخدم `print.css`.
- **لا يوجد أي endpoint يعيد ملف PDF.** الموقع لا ينتج PDF على الخادم إطلاقاً.
  لذلك يفتح البوت صفحة النتيجة الرسمية نفسها عبر Playwright ويطبعها إلى PDF
  بنفس تنسيق الموقع (`src/najah/pdf.ts`).
- الدخول محمي بـ **ALTCHA** (اختبار تحقق proof-of-work) عبر
  `https://najah.iq/api/student/challenge`. حلّه آلياً = تجاوز حماية،
  لذلك البوت يرفض العمل ما لم تضبط `NAJAH_AUTOMATION_AUTHORIZED=true`
  بعد حصولك على إذن رسمي من الوزارة.

## ما لم يُختبر بعد

وقت التحليل كانت نقاط الـ API (`/api/student/challenge` و `/api/student/student_check`)
تعيد **404** من الخادم (الاستعلام مغلق خارج موسم النتائج). لذلك تعذّر اختبار:
تسجيل الدخول، جلب النتيجة، وإنتاج الـ PDF بنتيجة حقيقية.
عند فتح الموسم، شغّل البوت وجرّب رقماً امتحانياً حقيقياً؛ إن تغيّر شكل الـ JSON
قد تحتاج تعديل `hasResult` في `src/najah/result.ts` فقط.

## الخصوصية

- الرقم السري يبقى في الذاكرة ثوانٍ فقط ثم يُحذف (`clearSecret` / `resetSession`).
- لا يُكتب أي رقم في الـ logs (`src/utils/logger.ts` يخفي الأرقام الطويلة).
- لا تُحفظ كوكيز ولا tokens ولا ملفات PDF على القرص — الـ PDF في Buffer فقط.
- حد أقصى 3 استعلامات لكل مستخدم في الساعة (قابل للتعديل في `.env`).
