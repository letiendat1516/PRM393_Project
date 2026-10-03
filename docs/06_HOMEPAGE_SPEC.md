# JobHub Homepage Specification

# 1. Objective

The homepage is the first impression of JobHub.

Its purpose is not only to look beautiful, but also to establish trust, communicate the platform's value, and guide users toward meaningful actions.

The homepage should immediately make visitors feel that JobHub is a professional recruitment platform designed for the Vietnamese market.

The design must resemble a modern SaaS recruitment platform rather than an AI demo website.

The homepage should be comparable in quality to:

- TopCV
- VietnamWorks
- LinkedIn Jobs
- Indeed
- JobStreet
- Google Careers

DO NOT copy any existing design.

Instead, understand their UX principles and create an original experience.

---

# 2. Language

The entire homepage MUST use Vietnamese.

Every visible text should be natural, professional and meaningful.

Never use:

- English UI
- Lorem Ipsum
- Placeholder text
- Dummy content

All buttons, titles, descriptions, statistics and testimonials must be written in fluent Vietnamese.

---

# 3. Visual Direction

The homepage should feel:

- Professional
- Trustworthy
- Premium
- Corporate
- Clean
- Modern
- Human-centered
- Friendly
- Easy to use

Avoid looking like an AI startup.

The design should emphasize people, careers and opportunities.

---

# 4. Photography

Claude Code has Web Search.

Before implementing the homepage:

Research and download high-quality royalty-free images.

Preferred sources:

- Unsplash
- Pexels
- Pixabay

Only use real photography.

Never use:

- AI generated people
- AI illustrations
- Robots
- Neural networks
- Holograms
- Futuristic graphics
- Abstract AI backgrounds
- Fake dashboard images

Preferred photography:

- Developers working
- Office environments
- Team collaboration
- Business meetings
- Job interviews
- Recruiters
- Candidates
- Modern workspace
- Company offices
- Laptop working
- Corporate lifestyle

Store downloaded images in:

src/assets/images/

Use meaningful filenames.

Example:

hero-office.jpg

team-meeting.jpg

workspace.jpg

job-interview.jpg

company-office.jpg

resume-upload.jpg

career-growth.jpg

---

# 5. Color Palette

Primary

#0F4C81

Secondary

#00A86B

Background

#F8FAFC

White

#FFFFFF

Text

Dark Gray

Use color consistently.

Avoid excessive gradients.

---

# 6. Typography

Preferred fonts

- Inter

or

- Plus Jakarta Sans

Rules

Large headings

Bold

Clean

Easy to scan

Body text

16px+

Comfortable line spacing

Readable

Avoid decorative fonts.

---

# 7. Layout Principles

Use a modern SaaS layout.

Large whitespace.

Balanced composition.

Consistent spacing.

8pt Grid System.

Border radius

12px–16px

Soft shadows.

Minimal visual noise.

---

# 8. Homepage Structure

## 8.1 Navigation Bar

Sticky.

Transparent on top.

Solid background after scrolling.

Contains:

- Logo
- Trang chủ
- Việc làm
- Công ty
- Hồ sơ
- Tư vấn nghề nghiệp
- Giới thiệu
- Đăng nhập
- Đăng ký

Navigation should collapse elegantly on mobile.

---

## 8.2 Hero Section

Large real-world photography.

Headline

"Tìm đúng công việc phù hợp với năng lực của bạn."

Supporting description

Explain JobHub and AI recommendation clearly.

Primary CTA

"Tải CV"

Secondary CTA

"Khám phá việc làm"

Include a professional search bar.

Search placeholder

"Tìm theo vị trí, kỹ năng hoặc tên công ty..."

---

## 8.3 Trusted Companies

Display logos of well-known companies.

Example

FPT

Viettel

VNPay

Shopee

MoMo

Grab

Techcombank

Do not overuse logos.

Keep layout clean.

---

## 8.4 Featured Jobs

Display modern job cards.

Each card contains

- Company Logo
- Job Title
- Salary
- Location
- Experience
- Employment Type
- Remote / Hybrid / Onsite
- Save Job Button
- Apply Button

Cards should feel premium.

---

## 8.5 Why Choose JobHub

Display feature cards.

Examples

AI phân tích CV

Đề xuất việc làm thông minh

Ứng tuyển nhanh

Theo dõi trạng thái hồ sơ

Kết nối doanh nghiệp uy tín

Each card should contain

- Icon
- Title
- Description

---

## 8.6 AI Resume Analysis

Illustrate workflow only.

Do NOT create fake AI dashboards.

Workflow

Upload CV

↓

AI phân tích

↓

Trích xuất kỹ năng

↓

So khớp việc làm

↓

Đề xuất phù hợp

This section should explain the process simply.

---

## 8.7 Top Companies

Display featured companies.

Each card

Logo

Industry

Location

Open Positions

Company Size

---

## 8.8 Career Statistics

Display statistics.

Examples

30.000+

Việc làm

10.000+

Doanh nghiệp

150.000+

Ứng viên

95%

Độ chính xác gợi ý

Numbers should feel realistic.

---

## 8.9 Testimonials

Use realistic Vietnamese testimonials.

Use professional portraits.

Never generate AI faces.

---

## 8.10 Career Resources

Display blog cards.

Examples

- Cách viết CV
- Bí quyết phỏng vấn
- Lộ trình nghề nghiệp
- Kỹ năng mềm
- Xu hướng tuyển dụng

---

## 8.11 Footer

Contains

Company

Products

Support

Legal

Social Links

Copyright

---

# 9. Component Rules

Everything must be componentized.

Suggested components

Navbar

Hero

SearchBar

CompanyLogoGrid

JobCard

FeatureCard

WorkflowSection

StatisticCard

TestimonialCard

BlogCard

Footer

Each component must be reusable.

---

# 10. Responsive Design

Support

Desktop

Laptop

Tablet

Mobile

No horizontal scrolling.

Maintain consistent spacing.

---

# 11. Animations

Animations should be subtle.

Use Framer Motion.

Examples

Fade In

Slide Up

Small Scale

Hover Elevation

Avoid excessive animation.

Avoid parallax.

Avoid flashy effects.

---

# 12. Accessibility

Keyboard navigation.

ARIA labels.

Sufficient color contrast.

Readable font sizes.

Accessible buttons.

Accessible forms.

---

# 13. Performance

Optimize all images.

Use lazy loading.

Avoid unnecessary animations.

Use code splitting where appropriate.

Maintain fast page load.

---

# 14. Quality Requirements

The homepage should be production-ready.

Someone visiting the homepage should immediately think:

"This is a real recruitment platform."

NOT

"This looks like a school project."

NOT

"This looks AI-generated."

Every section should have a clear business purpose.

Every image should support the content.

Every CTA should guide users toward the next action.

The homepage should inspire confidence and encourage users to explore the platform.
