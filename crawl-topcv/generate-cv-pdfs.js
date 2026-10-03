/**
 * Generate realistic Vietnamese CV PDFs using Playwright (HTML → PDF).
 *
 * Unlike pdfkit, this approach uses the browser's native font rendering,
 * so Vietnamese diacritics display perfectly without font embedding.
 *
 * Output: ai-lab/examples/cvs/<industry-slug>.pdf
 *
 * Usage:  node generate-cv-pdfs.js
 */

import { chromium } from "playwright";
import { writeFileSync, mkdirSync, existsSync, readFileSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";
import { CATEGORIES } from "./reference.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT_DIR = resolve(__dirname, "../../ai-lab/examples/cvs");

if (!existsSync(OUT_DIR)) mkdirSync(OUT_DIR, { recursive: true });

// ── Industry family → CV templates ──────────────────────────────────────────

const FAMILIES = {
  "it-software": {
    label: "IT - Phần mềm",
    cvs: [
      {
        name: "Nguyễn Văn Minh",
        dob: "15/03/1998",
        phone: "0987xxxxxx",
        email: "minh.nguyen@email.com",
        address: "Quận 7, TP. Hồ Chí Minh",
        objective:
          "Backend Developer với 3 năm kinh nghiệm, mong muốn phát triển lên vị trí Senior trong 2 năm tới. Đam mê xây dựng hệ thống scalable, ưu tiên môi trường làm việc có mentorship.",
        skills: [
          "Java",
          "Spring Boot",
          "MySQL",
          "PostgreSQL",
          "Redis",
          "Docker",
          "Kubernetes",
          "Microservices",
          "REST API",
          "Git",
          "CI/CD",
          "AWS",
        ],
        softSkills:
          "Làm việc nhóm, Tư duy phân tích, Quản lý thời gian, Giao tiếp tiếng Anh",
        experience: [
          {
            company: "CÔNG TY TNHH CÔNG NGHỆ VNPT IT",
            position: "Backend Developer",
            period: "01/2023 - nay",
            desc: "Phát triển và bảo trì hệ thống quản lý khách hàng cho 500K+ users. Thiết kế REST API, tối ưu query PostgreSQL (giảm 40% thời gian phản hồi). Triển khai CI/CD pipeline với GitLab CI + Docker.",
          },
          {
            company: "CÔNG TY CỔ PHẦN FPT SOFTWARE",
            position: "Junior Java Developer",
            period: "06/2021 - 12/2022",
            desc: "Tham gia team phát triển hệ thống ngân hàng số. Viết unit test (JUnit, Mockito), đạt coverage 85%. Hỗ trợ migrate monolith → microservices.",
          },
        ],
        education: "Đại học Bách Khoa TP.HCM — Khoa học Máy tính (2016 - 2021)",
        certifications:
          "AWS Certified Developer - Associate (2022) • Oracle Java SE 11 Programmer (2021)",
        languages: "Tiếng Anh: TOEIC 750 • Tiếng Việt: Bản ngữ",
      },
      {
        name: "Trần Thị Hồng",
        dob: "22/07/2000",
        phone: "0912xxxxxx",
        email: "hong.tran@email.com",
        address: "Cầu Giấy, Hà Nội",
        objective:
          "Frontend Developer yêu thích xây dựng giao diện người dùng thân thiện, hiệu năng cao. Mục tiêu trở thành Full-stack Developer trong 3 năm.",
        skills: [
          "ReactJS",
          "TypeScript",
          "Next.js",
          "Tailwind CSS",
          "Redux",
          "GraphQL",
          "Jest",
          "Figma",
          "HTML5/CSS3",
          "Node.js",
        ],
        softSkills: "Giao tiếp, Chủ động, Tỉ mỉ, Tiếng Anh tốt",
        experience: [
          {
            company: "CÔNG TY TNHH VNG CORPORATION",
            position: "Frontend Developer",
            period: "09/2022 - nay",
            desc: "Phát triển dashboard quản lý cho sản phẩm ZaloPay. Tối ưu bundle size (giảm 35%), cải thiện Lighthouse score từ 62 → 91. Review code cho 3 junior.",
          },
          {
            company: "CÔNG TY CỔ PHẦN TOPDEV",
            position: "Intern → Junior Frontend",
            period: "03/2021 - 08/2022",
            desc: "Xây dựng landing page, component library nội bộ. Chuyển đổi jQuery → React cho hệ thống quản lý tuyển dụng.",
          },
        ],
        education:
          "Đại học Công nghệ - ĐHQG HN — Công nghệ Thông tin (2018 - 2022)",
        certifications: "Meta Frontend Developer Certificate (2023)",
        languages: "Tiếng Anh: IELTS 6.5 • Tiếng Việt: Bản ngữ",
      },
      {
        name: "Lê Quang Huy",
        dob: "10/11/1996",
        phone: "0903xxxxxx",
        email: "huy.le@email.com",
        address: "Tân Bình, TP. Hồ Chí Minh",
        objective:
          "Senior DevOps Engineer với 5+ năm kinh nghiệm, tìm kiếm cơ hội dẫn dắt team infrastructure tại công ty product.",
        skills: [
          "AWS",
          "Terraform",
          "Kubernetes",
          "Docker",
          "Jenkins",
          "GitLab CI",
          "Prometheus",
          "Grafana",
          "ELK Stack",
          "Python",
          "Bash",
          "Ansible",
          "Linux",
        ],
        softSkills: "Lãnh đạo, Giải quyết vấn đề, Giao tiếp, Tư duy hệ thống",
        experience: [
          {
            company: "CÔNG TY TNHH SHOPEE",
            position: "DevOps Engineer",
            period: "04/2021 - nay",
            desc: "Quản lý hạ tầng AWS cho 200+ services. Thiết kế hệ thống monitoring (Prometheus + Grafana). Tự động hóa deployment với ArgoCD, giảm thời gian release từ 2h → 15 phút.",
          },
          {
            company: "CÔNG TY CỔ PHẦN TIKI",
            position: "System Administrator",
            period: "08/2018 - 03/2021",
            desc: "Vận hành hệ thống Linux 500+ servers. Triển khai Kubernetes cluster đầu tiên cho team. Viết script tự động hóa backup & restore.",
          },
        ],
        education:
          "Đại học Khoa học Tự nhiên TP.HCM — Mạng máy tính & Truyền thông (2014 - 2018)",
        certifications:
          "AWS Solutions Architect Professional (2023) • CKA - Certified Kubernetes Admin (2022)",
        languages: "Tiếng Anh: TOEIC 820 • Tiếng Việt: Bản ngữ",
      },
    ],
  },

  "sales-business": {
    label: "Kinh doanh / Sales",
    cvs: [
      {
        name: "Phạm Thanh Tùng",
        dob: "05/09/1995",
        phone: "0978xxxxxx",
        email: "tung.pham@email.com",
        address: "Bình Thạnh, TP. Hồ Chí Minh",
        objective:
          "Nhân viên kinh doanh B2B với 4 năm kinh nghiệm trong lĩnh vực SaaS. Mục tiêu đạt vị trí Sales Manager trong 2 năm, doanh số 5 tỷ/năm.",
        skills: [
          "Bán hàng B2B",
          "Đàm phán",
          "Chốt sale",
          "Quản lý pipeline",
          "CRM (Salesforce)",
          "Cold calling",
          "Presentation",
          "Microsoft Office",
          "Lập kế hoạch kinh doanh",
        ],
        softSkills:
          "Giao tiếp thuyết phục, Chịu áp lực cao, Đàm phán, Xây dựng quan hệ",
        experience: [
          {
            company: "CÔNG TY CỔ PHẦN BASECAMP VIỆT NAM",
            position: "Senior Sales Executive",
            period: "01/2022 - nay",
            desc: "Phụ trách mảng khách hàng doanh nghiệp (50-200 nhân sự). Đạt 120% quota năm 2023, 2024. Phát triển 30+ khách hàng mới, tổng giá trị hợp đồng ~8 tỷ.",
          },
          {
            company: "CÔNG TY TNHH VIETTEL BUSINESS",
            position: "Sales Representative",
            period: "06/2019 - 12/2021",
            desc: "Tư vấn giải pháp viễn thông cho doanh nghiệp vừa và nhỏ. Top 5 sales toàn miền Nam 2020. Xây dựng mối quan hệ với 100+ khách hàng.",
          },
        ],
        education: "Đại học Kinh tế TP.HCM — Quản trị Kinh doanh (2014 - 2019)",
        certifications:
          "Certificate in Professional Selling (VCCI) • Salesforce Administrator Certified",
        languages: "Tiếng Anh: TOEIC 680 • Tiếng Việt: Bản ngữ",
      },
      {
        name: "Vũ Thị Mai",
        dob: "18/12/1998",
        phone: "0965xxxxxx",
        email: "mai.vu@email.com",
        address: "Đống Đa, Hà Nội",
        objective:
          "Chuyên viên kinh doanh bất động sản, mong muốn làm việc tại công ty phát triển dự án lớn, có lộ trình thăng tiến rõ ràng.",
        skills: [
          "Môi giới BĐS",
          "Định giá bất động sản",
          "Tư vấn đầu tư",
          "Pháp lý BĐS",
          "Chăm sóc khách hàng",
          "Marketing online",
          "Chốt giao dịch",
        ],
        softSkills: "Kiên trì, Lắng nghe, Thuyết phục, Quản lý thời gian",
        experience: [
          {
            company: "CÔNG TY CỔ PHẦN ĐẤT XANH MIỀN BẮC",
            position: "Chuyên viên Kinh doanh BĐS",
            period: "10/2021 - nay",
            desc: "Tư vấn và môi giới căn hộ chung cư, đất nền khu vực Hà Nội. Đã chốt 15+ giao dịch, tổng giá trị ~25 tỷ. Xây dựng kênh TikTok marketing thu hút 500+ leads/tháng.",
          },
          {
            company: "NGÂN HÀNG TMCP VIETCOMBANK",
            position: "Chuyên viên Quan hệ Khách hàng",
            period: "08/2019 - 09/2021",
            desc: "Tư vấn sản phẩm vay mua nhà, thẻ tín dụng. Quản lý danh mục 200+ khách hàng cá nhân.",
          },
        ],
        education: "Học viện Tài chính — Tài chính - Ngân hàng (2015 - 2019)",
        certifications:
          "Chứng chỉ Môi giới BĐS (Bộ Xây dựng) • Chứng chỉ Định giá BĐS",
        languages: "Tiếng Anh: TOEIC 600 • Tiếng Việt: Bản ngữ",
      },
    ],
  },

  "accounting-finance": {
    label: "Kế toán / Tài chính / Kiểm toán",
    cvs: [
      {
        name: "Hoàng Thị Lan",
        dob: "12/04/1994",
        phone: "0983xxxxxx",
        email: "lan.hoang@email.com",
        address: "Gò Vấp, TP. Hồ Chí Minh",
        objective:
          "Kế toán tổng hợp với 6 năm kinh nghiệm, thành thạo MISA, Excel nâng cao. Mong muốn làm việc trong môi trường chuyên nghiệp, ổn định lâu dài.",
        skills: [
          "Kế toán tổng hợp",
          "Kê khai thuế",
          "Lập BCTC",
          "MISA",
          "Fast Accounting",
          "Excel (VBA, Pivot)",
          "Quyết toán thuế",
          "Kiểm soát công nợ",
          "Luật thuế",
        ],
        softSkills: "Cẩn thận, Tỉ mỉ, Trung thực, Chịu áp lực mùa vụ",
        experience: [
          {
            company: "CÔNG TY TNHH SẢN XUẤT ABC",
            position: "Kế toán Tổng hợp",
            period: "06/2020 - nay",
            desc: "Phụ trách toàn bộ sổ sách kế toán cho công ty 200 nhân sự. Lập BCTC quý/năm, kê khai thuế GTGT, TNDN, TNCN đúng hạn. Tối ưu chi phí thuế hợp lý, tiết kiệm ~300tr/năm.",
          },
          {
            company: "CÔNG TY CỔ PHẦN DỊCH VỤ XYZ",
            position: "Kế toán viên",
            period: "03/2017 - 05/2020",
            desc: "Quản lý công nợ phải thu/phải trả, đối chiếu số liệu với 50+ đối tác. Hỗ trợ kiểm toán nội bộ, phát hiện sai sót trị giá 200tr.",
          },
        ],
        education: "Đại học Kinh tế TP.HCM — Kế toán - Kiểm toán (2012 - 2016)",
        certifications:
          "Chứng chỉ CPA Việt Nam (2021) • Chứng chỉ Kế toán trưởng (2019) • MOS Excel Expert",
        languages: "Tiếng Anh: TOEIC 650 • Tiếng Việt: Bản ngữ",
      },
    ],
  },

  "marketing-content": {
    label: "Marketing / Content / Digital",
    cvs: [
      {
        name: "Đỗ Minh Anh",
        dob: "28/02/1997",
        phone: "0918xxxxxx",
        email: "minhanh.do@email.com",
        address: "Thanh Xuân, Hà Nội",
        objective:
          "Digital Marketing Specialist với thế mạnh về Performance Marketing & Content Strategy. Mục tiêu dẫn dắt team marketing 5-7 người trong 2 năm.",
        skills: [
          "Google Ads",
          "Facebook Ads",
          "SEO",
          "Content Marketing",
          "Google Analytics",
          "Email Marketing",
          "Canva",
          "WordPress",
          "Copywriting",
          "A/B Testing",
          "Data Analysis",
        ],
        softSkills:
          "Sáng tạo, Tư duy chiến lược, Phân tích số liệu, Làm việc nhóm",
        experience: [
          {
            company: "CÔNG TY CỔ PHẦN THỜI TRANG YODY",
            position: "Digital Marketing Executive",
            period: "04/2022 - nay",
            desc: "Quản lý ngân sách ads 500tr/tháng (Google + Facebook). Tăng ROAS từ 2.1 → 3.8 sau 6 tháng. Phát triển kênh TikTok organic đạt 100K followers.",
          },
          {
            company: "CÔNG TY TNHH TRUYỀN THÔNG GAPIT",
            position: "Content Marketing",
            period: "07/2020 - 03/2022",
            desc: "Lên kế hoạch nội dung cho 5 khách hàng B2B. Viết blog, social post, email sequence. Tăng traffic organic 200% cho khách hàng chính.",
          },
        ],
        education:
          "Đại học Ngoại thương Hà Nội — Kinh tế Đối ngoại (2015 - 2020)",
        certifications:
          "Google Ads Search • Facebook Blueprint Certified • HubSpot Content Marketing",
        languages: "Tiếng Anh: IELTS 7.0 • Tiếng Việt: Bản ngữ",
      },
    ],
  },

  "hr-admin": {
    label: "Nhân sự / Hành chính",
    cvs: [
      {
        name: "Nguyễn Thị Phương",
        dob: "03/08/1993",
        phone: "0909xxxxxx",
        email: "phuong.nguyen@email.com",
        address: "Hoàn Kiếm, Hà Nội",
        objective:
          "HR Specialist với 5 năm kinh nghiệm trong mảng tuyển dụng & đào tạo. Mong muốn phát triển lên vị trí HR Manager tại công ty công nghệ.",
        skills: [
          "Tuyển dụng (end-to-end)",
          "Onboarding",
          "Đào tạo & Phát triển",
          "Đánh giá hiệu suất",
          "Tính lương - BHXH",
          "Luật Lao động",
          "LinkedIn Recruiter",
          "HRIS",
          "Xây dựng văn hóa DN",
        ],
        softSkills: "Lắng nghe, Đồng cảm, Giao tiếp, Giải quyết xung đột",
        experience: [
          {
            company: "CÔNG TY TNHH CMC TECHNOLOGY",
            position: "Senior HR Specialist",
            period: "08/2021 - nay",
            desc: "Phụ trách tuyển dụng khối IT (30-40 vị trí/quý). Thiết kế & triển khai chương trình onboarding rút ngắn time-to-productivity từ 3 tháng → 6 tuần. Xây dựng khung đánh giá năng lực.",
          },
          {
            company: "CÔNG TY CỔ PHẦN FPT RETAIL",
            position: "Chuyên viên Nhân sự",
            period: "05/2018 - 07/2021",
            desc: "Tuyển dụng khối bán lẻ (60+ vị trí/quý). Quản lý hồ sơ 500+ nhân viên, xử lý BHXH, hợp đồng lao động. Tổ chức team building, sự kiện nội bộ.",
          },
        ],
        education:
          "Đại học Lao động - Xã hội — Quản trị Nhân lực (2012 - 2017)",
        certifications: "SHRM-CP (2022) • Chứng chỉ Hành nghề Nhân sự (VNHI)",
        languages: "Tiếng Anh: TOEIC 720 • Tiếng Việt: Bản ngữ",
      },
    ],
  },

  "design-creative": {
    label: "Thiết kế / Sáng tạo",
    cvs: [
      {
        name: "Bùi Hoàng Nam",
        dob: "20/06/1999",
        phone: "0934xxxxxx",
        email: "nam.bui@email.com",
        address: "Hai Bà Trưng, Hà Nội",
        objective:
          "Graphic Designer với 3 năm kinh nghiệm, chuyên về branding & UI design. Tìm kiếm môi trường sáng tạo, được làm việc với các dự án đa dạng.",
        skills: [
          "Adobe Photoshop",
          "Illustrator",
          "Figma",
          "After Effects",
          "InDesign",
          "Typography",
          "Color Theory",
          "Brand Identity",
          "UI/UX Design",
          "Motion Graphics",
        ],
        softSkills: "Sáng tạo, Tỉ mỉ, Quản lý deadline, Nhận feedback",
        experience: [
          {
            company: "CÔNG TY TNHH THIẾT KẾ CREATORY",
            position: "Graphic Designer",
            period: "01/2023 - nay",
            desc: "Thiết kế bộ nhận diện thương hiệu cho 10+ khách hàng startup. Thiết kế UI cho 3 mobile apps. Dẫn dắt 2 intern designer.",
          },
          {
            company: "CÔNG TY CỔ PHẦN IN ẤN HOÀNG GIA",
            position: "Junior Designer",
            period: "06/2020 - 12/2022",
            desc: "Thiết kế catalogue, brochure, banner cho 30+ khách hàng doanh nghiệp. Hỗ trợ art director trong các dự án lớn.",
          },
        ],
        education:
          "Đại học Mỹ thuật Công nghiệp — Thiết kế Đồ họa (2017 - 2021)",
        certifications:
          "Adobe Certified Professional - Photoshop • Google UX Design Certificate (2023)",
        languages: "Tiếng Anh: TOEIC 580 • Tiếng Việt: Bản ngữ",
      },
    ],
  },

  "construction-engineering": {
    label: "Xây dựng / Kỹ thuật",
    cvs: [
      {
        name: "Trần Văn Đức",
        dob: "08/11/1990",
        phone: "0945xxxxxx",
        email: "duc.tran@email.com",
        address: "Nam Từ Liêm, Hà Nội",
        objective:
          "Kỹ sư xây dựng với 8 năm kinh nghiệm giám sát công trình dân dụng & công nghiệp. Có chứng chỉ hành nghề, mong muốn vị trí Chỉ huy trưởng công trình.",
        skills: [
          "Đọc bản vẽ",
          "AutoCAD",
          "SAP2000",
          "ETABS",
          "Microsoft Project",
          "Dự toán",
          "Giám sát thi công",
          "Quản lý chất lượng",
          "An toàn lao động",
        ],
        softSkills:
          "Quản lý đội nhóm, Giải quyết vấn đề, Giao tiếp nhà thầu, Chịu áp lực",
        experience: [
          {
            company: "CÔNG TY CỔ PHẦN XÂY DỰNG COTECCONS",
            position: "Kỹ sư Giám sát Công trình",
            period: "06/2019 - nay",
            desc: "Giám sát thi công 3 dự án chung cư cao tầng (20-30 tầng). Quản lý đội 50+ công nhân, đảm bảo tiến độ & chất lượng. Xử lý các vấn đề kỹ thuật phát sinh tại công trường.",
          },
          {
            company: "CÔNG TY TNHH XÂY DỰNG HÒA BÌNH",
            position: "Kỹ sư Hiện trường",
            period: "03/2015 - 05/2019",
            desc: "Giám sát thi công phần thô & hoàn thiện cho 5 dự án nhà ở, biệt thự. Lập biện pháp thi công, quản lý vật tư, nghiệm thu khối lượng.",
          },
        ],
        education:
          "Đại học Xây dựng Hà Nội — Kỹ thuật Xây dựng Dân dụng (2008 - 2013)",
        certifications:
          "Chứng chỉ Hành nghề Giám sát Thi công (hạng I) • Chứng chỉ An toàn Lao động",
        languages: "Tiếng Anh: TOEIC 520 • Tiếng Việt: Bản ngữ",
      },
    ],
  },

  "healthcare-pharma": {
    label: "Y tế / Dược",
    cvs: [
      {
        name: "Lê Thị Hương",
        dob: "14/07/1995",
        phone: "0972xxxxxx",
        email: "huong.le@email.com",
        address: "Quận 10, TP. Hồ Chí Minh",
        objective:
          "Dược sĩ với 4 năm kinh nghiệm tại nhà thuốc và công ty dược phẩm. Mong muốn phát triển lên vị trí Trình dược viên chuyên nghiệp.",
        skills: [
          "Tư vấn thuốc",
          "Quản lý nhà thuốc GPP",
          "Kiến thức dược lý",
          "Kiểm soát chất lượng",
          "GMP/GLP",
          "Microsoft Office",
          "Báo cáo khoa học",
          "HACCP",
        ],
        softSkills:
          "Cẩn thận, Giao tiếp bệnh nhân, Làm việc độc lập, Trách nhiệm",
        experience: [
          {
            company: "CÔNG TY CỔ PHẦN DƯỢC HẬU GIANG",
            position: "Trình dược viên",
            period: "06/2022 - nay",
            desc: "Phụ trách địa bàn TP.HCM. Tư vấn sản phẩm cho bác sĩ/dược sĩ tại 80+ nhà thuốc & bệnh viện. Doanh số tăng trưởng 25% YoY.",
          },
          {
            company: "NHÀ THUỐC LONG CHÂU",
            position: "Dược sĩ Phụ trách",
            period: "01/2020 - 05/2022",
            desc: "Quản lý nhà thuốc đạt chuẩn GPP, doanh thu 300tr/tháng. Tư vấn 50+ bệnh nhân/ngày. Kiểm soát tồn kho, hạn dùng, nhập hàng.",
          },
        ],
        education: "Đại học Y Dược TP.HCM — Dược học (2013 - 2018)",
        certifications:
          "Chứng chỉ Hành nghề Dược • Chứng chỉ GPP • Chứng chỉ Trình dược viên",
        languages: "Tiếng Anh: TOEIC 610 • Tiếng Việt: Bản ngữ",
      },
    ],
  },

  "logistics-supply-chain": {
    label: "Logistics / Vận tải / Kho vận",
    cvs: [
      {
        name: "Vũ Đình Khánh",
        dob: "25/09/1993",
        phone: "0986xxxxxx",
        email: "khanh.vu@email.com",
        address: "Quận Bình Tân, TP. Hồ Chí Minh",
        objective:
          "Nhân viên Logistics với 5 năm kinh nghiệm xuất nhập khẩu & quản lý kho. Thành thạo incoterms, chứng từ hải quan.",
        skills: [
          "Xuất nhập khẩu",
          "Incoterms 2020",
          "Chứng từ hải quan",
          "Quản lý kho (WMS)",
          "Vận tải đường biển",
          "Đàm phán cước vận chuyển",
          "Excel nâng cao",
          "SAP",
        ],
        softSkills:
          "Tỉ mỉ, Quản lý thời gian, Xử lý tình huống, Giao tiếp đối tác",
        experience: [
          {
            company: "CÔNG TY TNHH GIAO HÀNG NHANH",
            position: "Chuyên viên Logistics",
            period: "10/2021 - nay",
            desc: "Điều phối vận tải cho 20+ xe/ngày (khu vực miền Nam). Tối ưu tuyến đường giảm 15% chi phí vận chuyển. Quản lý chứng từ xuất nhập khẩu cho 10+ container/tháng.",
          },
          {
            company: "CÔNG TY CỔ PHẦN GEMADEPT",
            position: "Nhân viên Chứng từ",
            period: "03/2018 - 09/2021",
            desc: "Xử lý chứng từ xuất nhập khẩu hàng FCL/LCL. Làm việc với hải quan, forwarder, khách hàng để thông quan nhanh.",
          },
        ],
        education:
          "Đại học Giao thông Vận tải TP.HCM — Logistics & Quản lý Chuỗi cung ứng (2012 - 2017)",
        certifications:
          "Certificate in Logistics Management (VLA) • Chứng chỉ Khai báo Hải quan",
        languages:
          "Tiếng Anh: TOEIC 630 • Tiếng Trung: HSK 3 • Tiếng Việt: Bản ngữ",
      },
    ],
  },

  "education-teaching": {
    label: "Giáo dục / Đào tạo",
    cvs: [
      {
        name: "Phan Thị Thảo",
        dob: "01/03/1996",
        phone: "0938xxxxxx",
        email: "thao.phan@email.com",
        address: "Cầu Giấy, Hà Nội",
        objective:
          "Giáo viên tiếng Anh với 4 năm kinh nghiệm giảng dạy đa lứa tuổi. Có chứng chỉ TESOL, phương pháp giảng dạy giao tiếp hiện đại.",
        skills: [
          "Giảng dạy tiếng Anh",
          "Thiết kế giáo án",
          "Phương pháp Communicative",
          "IELTS Preparation",
          "Quản lý lớp học",
          "PowerPoint",
          "Zoom/Google Meet",
          "Chấm thi Speaking",
        ],
        softSkills: "Kiên nhẫn, Truyền cảm hứng, Giao tiếp sư phạm, Tổ chức",
        experience: [
          {
            company: "TRUNG TÂM ANH NGỮ VUS",
            position: "Giáo viên Tiếng Anh",
            period: "05/2022 - nay",
            desc: "Giảng dạy 6 lớp (tổng 90 học viên) từ Beginner đến Intermediate. 85% học viên đạt điểm Speaking 6.5+ IELTS. Thiết kế tài liệu bổ trợ cho chương trình giao tiếp.",
          },
          {
            company: "TRUNG TÂM ANH NGỮ APOLLO",
            position: "Trợ giảng → Giáo viên",
            period: "08/2019 - 04/2022",
            desc: "Hỗ trợ giảng dạy lớp thiếu nhi & thiếu niên. Phụ trách chấm bài, kèm 1-1 học viên yếu. Được promoted lên giáo viên chính thức sau 1 năm.",
          },
        ],
        education:
          "Đại học Ngoại ngữ - ĐHQG HN — Sư phạm Tiếng Anh (2014 - 2019)",
        certifications: "TESOL Certificate (2019) • IELTS 8.0 Overall",
        languages: "Tiếng Anh: IELTS 8.0 • Tiếng Việt: Bản ngữ",
      },
    ],
  },

  "hospitality-tourism": {
    label: "Nhà hàng / Khách sạn / Du lịch",
    cvs: [
      {
        name: "Nguyễn Hải Yến",
        dob: "17/05/1997",
        phone: "0915xxxxxx",
        email: "yen.nguyen@email.com",
        address: "Ngũ Hành Sơn, Đà Nẵng",
        objective:
          "Quản lý nhà hàng/khách sạn với 3 năm kinh nghiệm. Có kỹ năng lãnh đạo đội nhóm, đam mê ngành dịch vụ khách hàng cao cấp.",
        skills: [
          "Quản lý nhà hàng",
          "F&B Operations",
          "Đào tạo nhân viên",
          "Quản lý ngân sách",
          "Đặt phòng (PMS)",
          "Chăm sóc khách VIP",
          "Xử lý phàn nàn",
          "Tiếng Anh giao tiếp",
        ],
        softSkills: "Lãnh đạo, Giao tiếp, Giải quyết vấn đề, Chịu áp lực cao",
        experience: [
          {
            company: "FUSION RESORT DANANG",
            position: "Assistant F&B Manager",
            period: "03/2023 - nay",
            desc: "Quản lý team 25 nhân viên nhà hàng & bar. Tăng điểm đánh giá khách hàng từ 4.2 → 4.7 trên TripAdvisor. Kiểm soát food cost đạt 28% (target 30%).",
          },
          {
            company: "KHÁCH SẠN MƯỜNG THANH ĐÀ NẴNG",
            position: "Nhân viên Lễ tân → Giám sát",
            period: "06/2020 - 02/2023",
            desc: "Check-in/out 50+ khách/ngày. Xử lý booking qua Agoda, Booking.com. Được promoted lên Giám sát sau 18 tháng với thành tích upsell phòng cao nhất team.",
          },
        ],
        education:
          "Cao đẳng Du lịch Đà Nẵng — Quản trị Khách sạn (2015 - 2019)",
        certifications:
          "ServSafe Food Protection Manager • First Aid & CPR Certified",
        languages:
          "Tiếng Anh: TOEIC 700 • Tiếng Hàn: Sơ cấp • Tiếng Việt: Bản ngữ",
      },
    ],
  },

  "manufacturing-production": {
    label: "Sản xuất / Công nhân",
    cvs: [
      {
        name: "Nguyễn Văn Long",
        dob: "10/10/1992",
        phone: "0968xxxxxx",
        email: "long.nguyen@email.com",
        address: "Thuận An, Bình Dương",
        objective:
          "Kỹ thuật viên điện - điện tử với 7 năm kinh nghiệm trong nhà máy sản xuất. Có tay nghề sửa chữa máy móc, PLC cơ bản.",
        skills: [
          "Sửa chữa điện công nghiệp",
          "PLC Siemens cơ bản",
          "Đọc sơ đồ mạch điện",
          "Bảo trì máy móc",
          "Hệ thống khí nén",
          "An toàn điện",
          "5S/Kaizen",
          "Máy CNC vận hành",
        ],
        softSkills: "Cẩn thận, Kỷ luật, Làm việc nhóm, Chịu khó",
        experience: [
          {
            company: "CÔNG TY TNHH SAMSUNG ELECTRONICS VIỆT NAM",
            position: "Kỹ thuật viên Bảo trì Điện",
            period: "05/2019 - nay",
            desc: "Bảo trì hệ thống điện, máy móc cho dây chuyền sản xuất linh kiện. Phát hiện và xử lý 20+ sự cố/năm, giảm downtime 30%. Đào tạo 5 công nhân mới về an toàn điện.",
          },
          {
            company: "CÔNG TY CỔ PHẦN NHỰA BÌNH MINH",
            position: "Công nhân Vận hành Máy",
            period: "03/2015 - 04/2019",
            desc: "Vận hành máy ép nhựa, kiểm tra chất lượng sản phẩm đầu ra. Đề xuất cải tiến quy trình giúp tăng năng suất 15%.",
          },
        ],
        education:
          "Cao đẳng Kỹ thuật Cao Thắng — Điện Công nghiệp (2011 - 2014)",
        certifications:
          "Chứng chỉ An toàn Điện • Chứng chỉ Vận hành Máy CNC • Chứng chỉ 5S",
        languages: "Tiếng Anh: Cơ bản • Tiếng Việt: Bản ngữ",
      },
    ],
  },

  "law-legal": {
    label: "Luật / Pháp chế",
    cvs: [
      {
        name: "Mai Thanh Tùng",
        dob: "30/08/1991",
        phone: "0904xxxxxx",
        email: "tung.mai@email.com",
        address: "Quận 1, TP. Hồ Chí Minh",
        objective:
          "Chuyên viên Pháp chế với 6 năm kinh nghiệm trong lĩnh vực doanh nghiệp & thương mại. Có chứng chỉ hành nghề luật sư.",
        skills: [
          "Luật Doanh nghiệp",
          "Luật Thương mại",
          "Soạn thảo hợp đồng",
          "Tố tụng dân sự",
          "Đàm phán pháp lý",
          "Tuân thủ (Compliance)",
          "Sở hữu trí tuệ",
          "Luật Lao động",
        ],
        softSkills:
          "Tư duy logic, Viết lách pháp lý, Đàm phán, Giải quyết vấn đề",
        experience: [
          {
            company: "CÔNG TY LUẬT TNHH VILAF",
            position: "Chuyên viên Pháp chế Cao cấp",
            period: "01/2022 - nay",
            desc: "Tư vấn pháp lý cho 10+ khách hàng doanh nghiệp FDI. Soạn thảo, rà soát 200+ hợp đồng/năm (M&A, liên doanh, thương mại). Đại diện khách hàng tại tòa án, trọng tài thương mại.",
          },
          {
            company: "CÔNG TY LUẬT TNHH INDUS TRIAL",
            position: "Chuyên viên Pháp chế",
            period: "07/2017 - 12/2021",
            desc: "Nghiên cứu & tư vấn pháp lý doanh nghiệp, đầu tư. Hỗ trợ soạn thảo hợp đồng lao động, NDA, hợp đồng thương mại. Tham gia tố tụng 15+ vụ án.",
          },
        ],
        education: "Đại học Luật TP.HCM — Luật Thương mại (2010 - 2015)",
        certifications:
          "Chứng chỉ Hành nghề Luật sư (2020) • Chứng chỉ Đào tạo Nghề Luật sư (Học viện Tư pháp)",
        languages: "Tiếng Anh: IELTS 7.0 • Tiếng Việt: Bản ngữ",
      },
    ],
  },

  "customer-service": {
    label: "Chăm sóc khách hàng",
    cvs: [
      {
        name: "Trịnh Thu Hà",
        dob: "21/01/1999",
        phone: "0923xxxxxx",
        email: "ha.trinh@email.com",
        address: "Quận 3, TP. Hồ Chí Minh",
        objective:
          "Chuyên viên Chăm sóc Khách hàng với 3 năm kinh nghiệm trong lĩnh vực thương mại điện tử. Kỹ năng xử lý khiếu nại, giữ chân khách hàng tốt.",
        skills: [
          "Chăm sóc khách hàng",
          "Xử lý khiếu nại",
          "CRM (Zendesk, Freshdesk)",
          "Live Chat",
          "Gọi điện CSKH",
          "Giữ chân khách hàng",
          "Báo cáo KPI CSKH",
          "Tiếng Anh giao tiếp",
        ],
        softSkills: "Kiên nhẫn, Lắng nghe, Giải quyết vấn đề, Thấu cảm",
        experience: [
          {
            company: "CÔNG TY TNHH SHOPEE",
            position: "Senior CS Agent",
            period: "12/2022 - nay",
            desc: "Xử lý 40-50 tickets/ngày qua Zendesk & hotline. CSAT score trung bình 92%. Mentor 5 new hires, xây dựng FAQ template giảm 25% ticket volume.",
          },
          {
            company: "CÔNG TY CỔ PHẦN LAZADA VIỆT NAM",
            position: "CS Agent",
            period: "03/2021 - 11/2022",
            desc: "Hỗ trợ khách hàng qua chat & điện thoại. Xử lý đổi trả, hoàn tiền, khiếu nại vận chuyển. Top 10 CSAT toàn team.",
          },
        ],
        education: "Đại học Kinh tế TP.HCM — Quản trị Dịch vụ (2017 - 2021)",
        certifications:
          "Zendesk Customer Service Professional • Customer Experience Certificate",
        languages: "Tiếng Anh: TOEIC 680 • Tiếng Việt: Bản ngữ",
      },
    ],
  },

  "media-journalism": {
    label: "Báo chí / Truyền thông",
    cvs: [
      {
        name: "Lâm Ngọc Diệp",
        dob: "12/06/1996",
        phone: "0975xxxxxx",
        email: "diep.lam@email.com",
        address: "Ba Đình, Hà Nội",
        objective:
          "Biên tập viên / Content Creator với 4 năm kinh nghiệm sản xuất nội dung đa nền tảng. Tìm kiếm vị trí Senior Content Editor.",
        skills: [
          "Viết bài báo",
          "Biên tập nội dung",
          "Sản xuất video",
          "Quay dựng (Premiere, CapCut)",
          "SEO Content",
          "Social Media",
          "Phỏng vấn",
          "Nghiên cứu",
        ],
        softSkills: "Viết lách, Sáng tạo, Giao tiếp, Quản lý deadline",
        experience: [
          {
            company: "BÁO TUỔI TRẺ ONLINE",
            position: "Phóng viên / Biên tập viên",
            period: "04/2022 - nay",
            desc: "Sản xuất 15-20 bài/tuần mảng kinh tế - công nghệ. Phỏng vấn 30+ CEO, chuyên gia. 5 bài đạt 100K+ views. Phát triển series video ngắn cho TikTok đạt 50K followers.",
          },
          {
            company: "ĐÀI TRUYỀN HÌNH VTV24",
            position: "Cộng tác viên Sản xuất",
            period: "06/2019 - 03/2022",
            desc: "Hỗ trợ sản xuất chương trình tin tức, phóng sự. Viết kịch bản, quay dựng hậu kỳ cho 50+ phóng sự ngắn.",
          },
        ],
        education:
          "Học viện Báo chí & Tuyên truyền — Báo chí Truyền thông (2015 - 2019)",
        certifications:
          "Certificate in Digital Journalism (Reuters) • Google News Initiative",
        languages: "Tiếng Anh: IELTS 7.5 • Tiếng Việt: Bản ngữ",
      },
    ],
  },

  "environment-energy": {
    label: "Năng lượng / Môi trường",
    cvs: [
      {
        name: "Hoàng Văn Thắng",
        dob: "05/08/1994",
        phone: "0947xxxxxx",
        email: "thang.hoang@email.com",
        address: "Ninh Kiều, Cần Thơ",
        objective:
          "Kỹ sư Môi trường với 5 năm kinh nghiệm trong lĩnh vực xử lý nước thải & đánh giá tác động môi trường.",
        skills: [
          "ĐTM (Đánh giá Tác động Môi trường)",
          "Xử lý nước thải",
          "Quan trắc môi trường",
          "ISO 14001",
          "AutoCAD",
          "GIS",
          "Lập báo cáo môi trường",
          "Vận hành hệ thống XLNT",
        ],
        softSkills: "Phân tích, Tỉ mỉ, Làm việc hiện trường, Báo cáo",
        experience: [
          {
            company: "CÔNG TY CỔ PHẦN MÔI TRƯỜNG ĐÔ THỊ CẦN THƠ",
            position: "Kỹ sư Môi trường",
            period: "08/2021 - nay",
            desc: "Vận hành & giám sát hệ thống xử lý nước thải công suất 5000m³/ngày. Lập báo cáo ĐTM cho 3 dự án khu công nghiệp. Đảm bảo tuân thủ QCVN về môi trường.",
          },
          {
            company: "CÔNG TY TNHH TƯ VẤN MÔI TRƯỜNG ECOSYSTEM",
            position: "Nhân viên Tư vấn Môi trường",
            period: "03/2018 - 07/2021",
            desc: "Khảo sát, lấy mẫu hiện trường. Lập báo cáo giám sát môi trường định kỳ cho 15+ doanh nghiệp. Tư vấn giải pháp xử lý chất thải.",
          },
        ],
        education: "Đại học Cần Thơ — Kỹ thuật Môi trường (2012 - 2017)",
        certifications:
          "Chứng chỉ ISO 14001:2015 • Chứng chỉ Vận hành Hệ thống XLNT",
        languages: "Tiếng Anh: TOEIC 550 • Tiếng Việt: Bản ngữ",
      },
    ],
  },

  "retail-services": {
    label: "Bán lẻ / Dịch vụ",
    cvs: [
      {
        name: "Trần Thị Ngọc",
        dob: "18/02/1998",
        phone: "0901xxxxxx",
        email: "ngoc.tran@email.com",
        address: "Quận Tân Phú, TP. Hồ Chí Minh",
        objective:
          "Quản lý cửa hàng bán lẻ với 3 năm kinh nghiệm trong chuỗi cửa hàng tiện lợi. Mục tiêu phát triển lên Area Manager.",
        skills: [
          "Quản lý cửa hàng",
          "Quản lý tồn kho",
          "Sắp xếp trưng bày",
          "Bán hàng",
          "Quản lý nhân sự ca",
          "POS System",
          "Báo cáo doanh thu",
          "Chăm sóc khách hàng",
        ],
        softSkills: "Lãnh đạo, Giao tiếp, Linh hoạt, Chịu áp lực",
        experience: [
          {
            company: "CÔNG TY CỔ PHẦN BÁN LÊ CIRCLE K VIỆT NAM",
            position: "Quản lý Cửa hàng",
            period: "09/2023 - nay",
            desc: "Quản lý toàn bộ hoạt động cửa hàng (doanh thu 500tr/tháng, 12 nhân viên). Tăng doanh thu 18% Q1/2024 qua chiến lược upselling & trưng bày. Giảm shrinkage từ 1.2% → 0.7%.",
          },
          {
            company: "CÔNG TY TNHH GS25 VIỆT NAM",
            position: "Nhân viên → Trợ lý Quản lý",
            period: "01/2021 - 08/2023",
            desc: "Phục vụ khách hàng, quản lý nhập xuất hàng hóa. Được promoted lên Trợ lý Quản lý sau 14 tháng. Đào tạo 10+ nhân viên mới.",
          },
        ],
        education:
          "Cao đẳng Kinh tế Đối ngoại — Kinh doanh Thương mại (2016 - 2019)",
        certifications: "",
        languages: "Tiếng Anh: TOEIC 550 • Tiếng Việt: Bản ngữ",
      },
    ],
  },
};

// ── Generate HTML ───────────────────────────────────────────────────────────

function cvHtml(cv) {
  const skillTags = cv.skills
    .map((s) => `<span class="tag">${s}</span>`)
    .join("");

  const expHtml = cv.experience
    .map(
      (j) => `
    <div class="exp-item">
      <div class="exp-header">
        <span class="exp-title">${j.position}</span>
        <span class="exp-period">${j.period}</span>
      </div>
      <div class="exp-company">${j.company}</div>
      <p class="exp-desc">${j.desc}</p>
    </div>
  `,
    )
    .join("");

  return `<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>CV - ${cv.name}</title>
<style>
  @page { size: A4; margin: 0; }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: "Segoe UI", Arial, sans-serif;
    font-size: 10.5pt;
    line-height: 1.55;
    color: #222;
    padding: 40px 44px;
    max-width: 210mm;
  }
  .header { text-align: center; margin-bottom: 10px; }
  .name { font-size: 22pt; font-weight: 700; color: #1a3c5e; margin-bottom: 4px; }
  .contact { font-size: 9pt; color: #555; margin-bottom: 2px; }
  .address { font-size: 9pt; color: #555; }
  .sep { border: none; border-top: 2px solid #1a5276; margin: 10px 0 12px 0; }

  .section { margin-bottom: 14px; }
  .section-title {
    font-size: 12pt;
    font-weight: 700;
    color: #1a5276;
    border-bottom: 1.5px solid #1a5276;
    padding-bottom: 3px;
    margin-bottom: 8px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }
  .objective { text-align: justify; margin-bottom: 4px; }

  .skills { display: flex; flex-wrap: wrap; gap: 5px; margin-bottom: 6px; }
  .tag {
    background: #e8f0fe;
    color: #1a5276;
    padding: 2px 9px;
    border-radius: 3px;
    font-size: 9pt;
    font-weight: 500;
  }
  .soft-label { font-weight: 600; color: #444; }
  .soft-text { color: #555; font-size: 10pt; margin-bottom: 2px; }

  .exp-item { margin-bottom: 10px; }
  .exp-header { display: flex; justify-content: space-between; align-items: baseline; }
  .exp-title { font-weight: 700; font-size: 11pt; }
  .exp-period { font-size: 9pt; color: #777; white-space: nowrap; }
  .exp-company { font-size: 9.5pt; color: #555; margin-bottom: 2px; }
  .exp-desc { font-size: 9.5pt; color: #333; text-align: justify; }

  .edu { font-weight: 600; }
  .edu-detail { font-size: 9.5pt; color: #555; }
  .cert { font-size: 9.5pt; color: #333; }
  .lang { font-size: 9.5pt; color: #333; }
</style>
</head>
<body>
<div class="header">
  <div class="name">${cv.name}</div>
  <div class="contact">${cv.dob} &nbsp;|&nbsp; ${cv.phone} &nbsp;|&nbsp; ${cv.email}</div>
  <div class="address">${cv.address}</div>
</div>
<hr class="sep">

<div class="section">
  <div class="section-title">Mục tiêu nghề nghiệp</div>
  <p class="objective">${cv.objective}</p>
</div>

<div class="section">
  <div class="section-title">Kỹ năng</div>
  <div class="skills">${skillTags}</div>
  <div class="soft-text"><span class="soft-label">Kỹ năng mềm:</span> ${cv.softSkills}</div>
</div>

<div class="section">
  <div class="section-title">Kinh nghiệm làm việc</div>
  ${expHtml}
</div>

<div class="section">
  <div class="section-title">Học vấn</div>
  <p class="edu">${cv.education.split(" — ")[0]}</p>
  <p class="edu-detail">${cv.education.split(" — ").slice(1).join(" — ")}</p>
</div>

${
  cv.certifications
    ? `
<div class="section">
  <div class="section-title">Chứng chỉ</div>
  <p class="cert">${cv.certifications}</p>
</div>
`
    : ""
}

<div class="section">
  <div class="section-title">Ngôn ngữ</div>
  <p class="lang">${cv.languages}</p>
</div>

</body>
</html>`;
}

// ── Main ────────────────────────────────────────────────────────────────────

async function main() {
  console.log(`\n📄 Generating CV PDFs (Playwright HTML→PDF) → ${OUT_DIR}\n`);

  const browser = await chromium.launch({ headless: true });

  let total = 0;
  for (const [key, family] of Object.entries(FAMILIES)) {
    console.log(`🏷️  ${family.label} (${family.cvs.length} CVs)`);
    for (let i = 0; i < family.cvs.length; i++) {
      const cv = family.cvs[i];
      const slug = `${key}-${cv.name
        .toLowerCase()
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "")
        .replace(/đ/g, "d")
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/-$/, "")}-${i + 1}`;
      const filePath = resolve(OUT_DIR, `${slug}.pdf`);

      const page = await browser.newPage();
      await page.setContent(cvHtml(cv), { waitUntil: "networkidle" });
      await page.pdf({
        path: filePath,
        format: "A4",
        printBackground: true,
        margin: { top: "0px", right: "0px", bottom: "0px", left: "0px" },
      });
      await page.close();

      console.log(`   ✅ ${slug}.pdf`);
      total++;
    }
  }

  await browser.close();

  console.log(
    `\n🎉 Done! Generated ${total} CV PDFs across ${Object.keys(FAMILIES).length} industry families.\n`,
  );
  console.log(`📁 Output: ${OUT_DIR}\n`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
