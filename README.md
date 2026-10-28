# نظام وَصل

نظام تقييم الزيارات الميدانية للحلقات - الجمعية الخيرية لتحفيظ القرآن الكريم بجازان.

- الموقع: https://abdullahys.github.io/field-visits/
- الاستضافة: GitHub Pages من الفرع `main` (كل دفع للفرع ينشر الموقع تلقائيًا).
- قاعدة البيانات وتسجيل الدخول: Supabase (المشروع `wasl-visits`).

## الملفات

| الملف | الوصف |
|---|---|
| `index.html` | النظام كاملًا (الواجهة والتقارير والمزامنة مع Supabase) |
| `og-image.jpg`، `icon-*.png`، `rafad-logo.svg` | صورة المعاينة في واتساب والأيقونات |
| `supabase/migrations/` | تغييرات قاعدة البيانات بالترتيب |
| `publish.ps1` | نشر التعديلات على GitHub بأمر واحد |

## النشر

```powershell
.\publish.ps1 "وصف التعديل"
```

## قاعدة البيانات

- كل الجداول محمية بـ RLS، ولا يصل إليها إلا من سجّل الدخول وبريده في جدول `team`.
- إضافة عضو للفريق (من محرر SQL في Supabase):

```sql
insert into public.team (email, name) values ('email@example.com', 'الاسم') on conflict (email) do nothing;
```
