import '../../shared/models/job_model.dart';
import '../utils/enums.dart';

/// Verbatim port of frontend/src/data/*.js (homepage marketing content + the
/// 12 sample jobs that the web merges with API data). Used by the homepage
/// and by the admin "Seed demo data" action.
class DemoData {
  const DemoData._();

  // ── data/provinces.js (65 entries, 5 municipalities first) ────────────
  static const List<String> provinces = [
    'Hà Nội', 'Hồ Chí Minh', 'Hải Phòng', 'Đà Nẵng', 'Cần Thơ',
    'An Giang', 'Bà Rịa - Vũng Tàu', 'Bắc Giang', 'Bắc Kạn', 'Bắc Ninh',
    'Bến Tre', 'Bình Định', 'Bình Dương', 'Bình Phước', 'Bình Thuận',
    'Cà Mau', 'Cao Bằng', 'Đắk Lắk', 'Đắk Nông', 'Điện Biên', 'Đồng Nai',
    'Đồng Tháp', 'Gia Lai', 'Hà Giang', 'Hà Nam', 'Hà Tĩnh', 'Hải Dương',
    'Hậu Giang', 'Hòa Bình', 'Hưng Yên', 'Khánh Hòa', 'Kiên Giang', 'Kon Tum',
    'Lai Châu', 'Lâm Đồng', 'Lạng Sơn', 'Lào Cai', 'Long An', 'Nam Định',
    'Nghệ An', 'Ninh Bình', 'Ninh Thuận', 'Phú Thọ', 'Phú Yên', 'Quảng Bình',
    'Quảng Nam', 'Quảng Ngãi', 'Quảng Ninh', 'Quảng Trị', 'Sóc Trăng', 'Sơn La',
    'Tây Ninh', 'Thái Bình', 'Thái Nguyên', 'Thanh Hóa', 'Thừa Thiên Huế',
    'Tiền Giang', 'Trà Vinh', 'Tuyên Quang', 'Vĩnh Long', 'Vĩnh Phúc', 'Yên Bái',
  ];

  // ── data/companies.js ─────────────────────────────────────────────────
  static const List<String> trustedCompanies = [
    'FPT', 'Viettel', 'VNPay', 'Shopee', 'MoMo', 'Grab', 'Techcombank', 'VNG',
  ];

  static const List<TopCompany> topCompanies = [
    TopCompany(
      id: 'co-1',
      name: 'FPT Software',
      industry: 'Công nghệ thông tin',
      location: 'Quận Cầu Giấy, Hà Nội',
      openPositions: 128,
      size: '10.000+ nhân viên',
      initials: 'FS',
      brand: 'bg-orange-50 text-orange-600',
      cover: 'assets/images/company-office.jpg',
    ),
    TopCompany(
      id: 'co-2',
      name: 'MoMo (M_Service)',
      industry: 'Fintech / Thanh toán số',
      location: 'Quận 7, TP. Hồ Chí Minh',
      openPositions: 64,
      size: '1.000 - 5.000 nhân viên',
      initials: 'MM',
      brand: 'bg-pink-50 text-pink-600',
      cover: 'assets/images/team-meeting.jpg',
    ),
    TopCompany(
      id: 'co-3',
      name: 'Shopee Vietnam',
      industry: 'Thương mại điện tử',
      location: 'Quận 6, TP. Hồ Chí Minh',
      openPositions: 96,
      size: '5.000+ nhân viên',
      initials: 'SH',
      brand: 'bg-amber-50 text-amber-600',
      cover: 'assets/images/team-collab.jpg',
    ),
  ];

  // ── data/features.js ──────────────────────────────────────────────────
  static const List<FeatureItem> features = [
    FeatureItem('sparkles', 'AI phân tích CV',
        'Hệ thống đọc hiểu CV của bạn, trích xuất kỹ năng và kinh nghiệm để tận dụng tối đa hồ sơ.'),
    FeatureItem('target', 'Đề xuất việc làm thông minh',
        'Gợi ý những vị trí phù hợp nhất với năng lực, mục tiêu nghề nghiệp và mức lương kỳ vọng.'),
    FeatureItem('bolt', 'Ứng tuyển nhanh chóng',
        'Chỉ với vài thao tác, hồ sơ của bạn sẽ được gửi đến nhà tuyển dụng cùng thư xin việc tối ưu.'),
    FeatureItem('clock', 'Theo dõi trạng thái hồ sơ',
        'Cập nhật trực tiếp tình trạng ứng tuyển: đã nhận, đang xét duyệt, mời phỏng vấn hay trúng tuyển.'),
    FeatureItem('building', 'Kết nối doanh nghiệp uy tín',
        'Hơn 10.000 doanh nghiệp đã được xác thực, mang đến cơ hội việc làm chất lượng và minh bạch.'),
    FeatureItem('shield', 'Bảo mật thông tin',
        'Dữ liệu cá nhân và CV được mã hóa, chỉ chia sẻ với nhà tuyển dụng khi bạn cho phép.'),
  ];

  // ── data/workflow.js ──────────────────────────────────────────────────
  static const List<WorkflowStep> workflowSteps = [
    WorkflowStep('wf-1', 'upload', 'Tải lên CV', 'Đăng tải hồ sơ PDF của bạn lên hệ thống trong vài giây.'),
    WorkflowStep('wf-2', 'sparkles', 'AI phân tích', 'Trí tuệ nhân tạo đọc và hiểu nội dung CV một cách tự động.'),
    WorkflowStep('wf-3', 'fileText', 'Trích xuất kỹ năng', 'Kỹ năng, kinh nghiệm và học vấn được cấu trúc hoá đầy đủ.'),
    WorkflowStep('wf-4', 'target', 'So khớp việc làm', 'Hồ sơ được đối chiếu với hàng ngàn việc làm phù hợp.'),
    WorkflowStep('wf-5', 'checkCircle', 'Đề xuất phù hợp', 'Nhận danh sách cơ hội việc làm tối ưu nhất cho bạn.'),
  ];

  // ── data/stats.js ─────────────────────────────────────────────────────
  static const List<StatItem> statistics = [
    StatItem('st-1', 'briefcase', '30.000+', 'Việc làm đang tuyển'),
    StatItem('st-2', 'building', '10.000+', 'Doanh nghiệp đối tác'),
    StatItem('st-3', 'users', '150.000+', 'Ứng viên tin tưởng'),
    StatItem('st-4', 'target', '95%', 'Độ chính xác gợi ý'),
  ];

  // ── data/testimonials.js ──────────────────────────────────────────────
  static const List<Testimonial> testimonials = [
    Testimonial(
      id: 'ts-1',
      name: 'Nguyễn Hoàng Anh',
      role: 'Lập trình viên Front-end',
      company: 'FPT Software',
      avatar: 'assets/images/portrait-anh.jpg',
      rating: 5,
      quote:
          'Nhờ AI phân tích CV, tôi hiểu rõ điểm mạnh của mình và nhận được những gợi ý việc làm thực sự phù hợp. Chỉ sau hai tuần, tôi đã nhận lời mời phỏng vấn từ công ty mơ ước.',
    ),
    Testimonial(
      id: 'ts-2',
      name: 'Trần Quang Minh',
      role: 'Kỹ sư Backend',
      company: 'MoMo',
      avatar: 'assets/images/portrait-minh.jpg',
      rating: 5,
      quote:
          'Hồ sơ được tối ưu tự động giúp tôi tiết kiệm rất nhiều thời gian. Việc theo dõi trạng thái ứng tuyển ngay trên nền tảng cũng vô cùng thuận tiện và minh bạch.',
    ),
    Testimonial(
      id: 'ts-3',
      name: 'Lê Thanh Linh',
      role: 'Chuyên viên Marketing',
      company: 'Grab',
      avatar: 'assets/images/portrait-linh.jpg',
      rating: 5,
      quote:
          'Các gợi ý việc làm rất chính xác và có lý do giải thích rõ ràng. Tôi cảm thấy tự tin hơn khi biết vị trí nào thực sự phù hợp với định hướng nghề nghiệp của mình.',
    ),
  ];

  // ── data/blogPosts.js ─────────────────────────────────────────────────
  static const List<BlogPost> blogPosts = [
    BlogPost(
      id: 'bl-1',
      category: 'Viết CV',
      title: 'Cách viết CV chuyên nghiệp thu hút nhà tuyển dụng',
      excerpt:
          'Những nguyên tắc cấu trúc và cách trình bày CV giúp hồ sơ của bạn nổi bật giữa hàng trăm ứng viên khác.',
      readTime: '6 phút đọc',
      date: '28/06/2026',
      cover: 'assets/images/workspace.jpg',
    ),
    BlogPost(
      id: 'bl-2',
      category: 'Lộ trình nghề nghiệp',
      title: 'Định hướng lộ trình nghề nghiệp cho người làm công nghệ',
      excerpt:
          'Khung phát triển năng lực theo từng giai đoạn, từ junior đến senior, kèm kỹ năng cần trau dồi.',
      readTime: '8 phút đọc',
      date: '21/06/2026',
      cover: 'assets/images/career-growth.jpg',
    ),
    BlogPost(
      id: 'bl-3',
      category: 'Phỏng vấn',
      title: 'Bí quyết trả lời phỏng vấn tự tin và ấn tượng',
      excerpt:
          'Phương pháp trả lời theo cấu trúc, các câu hỏi thường gặp và cách để lại dấu ấn tích cực.',
      readTime: '7 phút đọc',
      date: '14/06/2026',
      cover: 'assets/images/job-interview.jpg',
    ),
  ];

  /// Hero image + section photos (frontend/src/assets/images).
  static const String heroImage = 'assets/images/hero-office.jpg';
  static const String workflowImage = 'assets/images/resume-candidate.jpg';
  static const List<String> heroAvatars = [
    'assets/images/portrait-anh.jpg',
    'assets/images/portrait-minh.jpg',
    'assets/images/portrait-linh.jpg',
    'assets/images/portrait-tuan.jpg',
  ];

  /// Seeded categories (web filter facets + the 12 sample jobs).
  static const List<String> categories = [
    'IT - Công nghệ thông tin', 'Nhân viên kinh doanh', 'Kế toán', 'Marketing',
    'Hành chính nhân sự', 'Ngân hàng', 'Chăm sóc khách hàng', 'Kỹ sư xây dựng',
    'Thiết kế đồ hoạ', 'Content Marketing', 'DevOps', 'Tài chính – Kế toán',
    'Kinh doanh', 'Nhân sự', 'Giáo dục', 'Y tế', 'Logistics', 'Bất động sản',
  ];

  // ── data/jobs.js (featured, homepage only) ────────────────────────────
  //
  // The legacy `bool hot` tag per row was dead — `JobModel.hot` is purely
  // `salaryMax >= 50M`, so the flag never reached rendering. Rows that
  // used to be flagged hot (jb-001, jb-002) are now bumped so their max
  // salary matches the intent, which the computed getter picks up.
  static List<JobModel> featuredJobs() {
    final now = DateTime.now();
    JobModel j(String id, String title, String company, String initials, String brand,
            num min, num max, String city, ExperienceLevel lvl, WorkMode mode,
            List<String> tags, int daysAgo) =>
        JobModel(
          jobId: id,
          employerId: 'demo-${initials.toLowerCase()}',
          employerName: company,
          jobTitle: title,
          salaryMin: min,
          salaryMax: max,
          city: city,
          location: city,
          experienceLevel: lvl,
          workMode: mode,
          jobType: JobType.fullTime,
          requiredSkills: [for (final t in tags) JobSkillRef(skillName: t)],
          status: JobStatus.open,
          isApproved: true,
          source: 'mock',
          createdAt: now.subtract(Duration(days: daysAgo)),
          applicationDeadline: now.add(const Duration(days: 30)),
          categoryName: 'IT - Công nghệ thông tin',
        );
    return [
      j('jb-001', 'Lập trình viên Front-end (ReactJS)', 'FPT Software', 'FS', 'orange', 25e6, 55e6, 'Hà Nội', ExperienceLevel.mid, WorkMode.hybrid, ['ReactJS', 'TypeScript', 'TailwindCSS'], 2),
      j('jb-002', 'Kỹ sư Backend Node.js / Express', 'MoMo', 'MM', 'pink', 30e6, 55e6, 'TP. Hồ Chí Minh', ExperienceLevel.senior, WorkMode.onsite, ['Node.js', 'PostgreSQL', 'Microservices'], 1),
      j('jb-003', 'Chuyên viên Phân tích Dữ liệu (Data Analyst)', 'Shopee', 'SH', 'amber', 20e6, 35e6, 'TP. Hồ Chí Minh', ExperienceLevel.junior, WorkMode.onsite, ['SQL', 'Python', 'Power BI'], 3),
      j('jb-004', 'Quản lý Sản phẩm Kỹ thuật (Technical PM)', 'Viettel', 'VT', 'red', 40e6, 65e6, 'Hà Nội', ExperienceLevel.senior, WorkMode.hybrid, ['Agile', 'SaaS', 'Roadmap'], 5),
      j('jb-005', 'Thiết kế UI/UX Senior', 'VNG', 'VNG', 'sky', 28e6, 45e6, 'TP. Hồ Chí Minh', ExperienceLevel.senior, WorkMode.remote, ['Figma', 'Design System', 'Research'], 7),
      j('jb-006', 'Chuyên viên Marketing Số (Digital Marketing)', 'Grab', 'GR', 'green', 18e6, 30e6, 'Hà Nội', ExperienceLevel.junior, WorkMode.hybrid, ['SEO', 'Performance', 'Content'], 4),
    ];
  }

  // ── data/jobsList.js (12 sample jobs with structured detail) ─────────
  static List<JobModel> sampleJobs() {
    final now = DateTime.now();
    var n = 0;
    JobModel j({
      required String title,
      required String company,
      required String category,
      num? min,
      num? max,
      required String city,
      required ExperienceLevel lvl,
      required WorkMode mode,
      JobType type = JobType.fullTime,
      required List<String> tags,
      required int daysAgo,
      required List<String> moTa,
      required List<String> yeuCau,
      required List<String> quyenLoi,
      required String thoiGian,
      required String bangCap,
    }) {
      n++;
      final id = 'SYN-${n.toString().padLeft(5, '0')}';
      return JobModel(
        jobId: id,
        employerId: 'demo-employer-$n',
        employerName: company,
        employerCity: city,
        jobTitle: title,
        categoryName: category,
        salaryMin: min,
        salaryMax: max,
        isSalaryNegotiable: min == null && max == null,
        city: city,
        location: city,
        experienceLevel: lvl,
        workMode: mode,
        jobType: type,
        requiredSkills: [for (final t in tags) JobSkillRef(skillName: t)],
        description: JobDescription(
          moTaCongViec: moTa,
          yeuCauUngVien: yeuCau,
          quyenLoi: quyenLoi,
          thoiGianLamViec: thoiGian,
          yeuCauKinhNghiem: lvl.jobMapperLabel,
          yeuCauBangCap: bangCap,
        ),
        status: JobStatus.open,
        isApproved: true,
        source: 'mock',
        createdAt: now.subtract(Duration(days: daysAgo)),
        applicationDeadline: now.add(Duration(days: 30 - daysAgo)),
      );
    }

    return [
      j(
        title: 'Chuyên Viên Kinh Doanh',
        company: 'CÔNG TY TNHH CÔNG NGHỆ FPT',
        category: 'Nhân viên kinh doanh',
        min: 15000000, max: 25000000, city: 'Hà Nội',
        lvl: ExperienceLevel.junior, mode: WorkMode.onsite,
        tags: ['Kinh doanh B2B', 'Sales'], daysAgo: 2,
        moTa: [
          'Tìm kiếm và tiếp cận khách hàng tiềm năng theo kênh được phân công.',
          'Tư vấn, giới thiệu sản phẩm/dịch vụ và chốt sale theo target đề ra.',
          'Xây dựng và duy trì mối quan hệ với khách hàng hiện tại.',
          'Lập kế hoạch kinh doanh cá nhân/hàng tuần/hàng tháng và báo cáo kết quả.',
          'Phối hợp với các phòng ban để đảm bảo trải nghiệm khách hàng tốt nhất.',
          'Cập nhật thông tin thị trường, đối thủ và xu hướng ngành.',
        ],
        yeuCau: [
          'Tốt nghiệp Cao đẳng/Đại học trở lên các chuyên ngành.',
          'Kinh nghiệm sales/kinh doanh là một lợi thế.',
          'Giao tiếp lưu loát, tự tin, có khả năng thuyết phục.',
          'Trung thực, nhiệt tình, chịu được áp lực cao về doanh số.',
          'Sử dụng thành thạo Office (Word, Excel) và CRM là một lợi thế.',
        ],
        quyenLoi: [
          'Lương cứng + thưởng hoa hồng không giới hạn theo doanh số.',
          'Thu nhập bình quân 15-30 triệu/tháng.',
          'Đóng BHXH, BHYT đầy đủ theo quy định pháp luật.',
          'Lương tháng 13 và thưởng Lễ/Tết.',
          'Đào tạo kỹ năng sales, sản phẩm định kỳ.',
          'Lộ trình thăng tiến lên Team Leader / Sales Manager rõ ràng.',
        ],
        thoiGian: 'Thứ 2 - Thứ 6 (từ 09:00 đến 18:00)', bangCap: 'Đại học trở lên',
      ),
      j(
        title: 'Backend Developer (NodeJS) - Hà Nội',
        company: 'CÔNG TY CỔ PHẦN PHÁT TRIỂN PHẦN MỀM VINGROUP',
        category: 'IT - Công nghệ thông tin',
        min: 25000000, max: 40000000, city: 'Hà Nội',
        lvl: ExperienceLevel.mid, mode: WorkMode.hybrid,
        tags: ['Node.js', 'PostgreSQL', 'REST API'], daysAgo: 1,
        moTa: [
          'Design, develop, and maintain reliable, scalable, and secure software applications.',
          'Build and consume RESTful APIs and microservices.',
          'Optimize application performance and database queries.',
          'Implement CI/CD pipelines and automated testing.',
          'Participate in code reviews and mentor junior developers.',
          'Collaborate with cross-functional teams (Product, QA, DevOps) to deliver features.',
          'Work in Agile/Scrum ceremonies (sprint planning, daily standup, retrospective).',
          'Document technical specifications and software components.',
        ],
        yeuCau: [
          "Bachelor's Degree in IT, Computer Science, Software Engineering, or related field.",
          'Proficiency in Node.js and at least one mainstream programming language.',
          'Experience with relational databases (PostgreSQL, MySQL) and SQL optimization.',
          'Experience with RESTful API design and microservices architecture.',
          'Familiarity with Git, Docker, and CI/CD workflows.',
          'Good English reading and writing skills for technical documentation.',
          'Strong analytical and problem-solving skills.',
        ],
        quyenLoi: [
          'Competitive salary (13th-month salary + performance bonus).',
          'Premium healthcare insurance from probation period.',
          '14+ annual leaves per year.',
          'Flexible working hours and hybrid/remote options.',
          'Laptop/máy tính làm việc cấu hình cao.',
          'Technical workshops, conferences, and training courses sponsored.',
        ],
        thoiGian: 'Thứ 2 - Thứ 6 (từ 09:00 đến 18:00), 1 ngày WFH/tuần', bangCap: 'Đại học trở lên',
      ),
      j(
        title: 'Kế Toán Tổng Hợp - Thu Nhập Hấp Dẫn',
        company: 'CÔNG TY TNHH TÀI CHÍNH MASAN',
        category: 'Kế toán',
        min: 18000000, max: 25000000, city: 'Hồ Chí Minh',
        lvl: ExperienceLevel.mid, mode: WorkMode.onsite,
        tags: ['Kế toán tổng hợp', 'MISA', 'Thuế'], daysAgo: 3,
        moTa: [
          'Theo dõi, hạch toán các nghiệp vụ kinh tế phát sinh hàng ngày.',
          'Lập hóa đơn, chứng từ và quản lý công nợ phải thu/phải trả.',
          'Thực hiện báo cáo thuế (GTGT, TNDN, TNCN) đúng thời hạn.',
          'Kiểm tra, đối chiếu số liệu kế toán và tồn kho.',
          'Lập báo cáo tài chính, báo cáo quản trị định kỳ.',
          'Tham gia quy trình quyết toán thuế năm và kiểm toán độc lập.',
          'Sử dụng phần mềm kế toán (MISA, Fast, ERP...).',
        ],
        yeuCau: [
          'Tốt nghiệp Đại học chuyên ngành Kế toán, Kiểm toán, Tài chính.',
          'Có chứng chỉ Chứng hành Kế toán / Kế toán trưởng là lợi thế.',
          'Thành thạo các phần mềm kế toán (MISA, Fast, Excel nâng cao).',
          'Nắm vững Luật Kế toán, Luật Thuế và các thông tư hiện hành.',
          'Cẩn thận, tỉ mỉ, trung thực, có tinh thần trách nhiệm cao.',
          'Kinh nghiệm quyết toán thuế và làm việc với cơ quan thuế.',
        ],
        quyenLoi: [
          'Lương ổn định, thưởng Lễ/Tết và thưởng hiệu suất.',
          'Hỗ trợ phí thi chứng chỉ nghề (ACCA, CPA, CMA).',
          'Đóng BHXH, BHYT đầy đủ theo quy định pháp luật.',
          'Khám sức khỏe định kỳ hàng năm.',
          'Môi trường làm việc chuyên nghiệp, quy trình rõ ràng.',
        ],
        thoiGian: 'Thứ 2 - Thứ 6 (từ 08:30 đến 17:30)', bangCap: 'Đại học trở lên',
      ),
      j(
        title: 'Digital Marketing Specialist - Remote',
        company: 'CÔNG TY CỔ PHẦN THƯƠNG MẠI SHOPEE',
        category: 'Marketing',
        min: 20000000, max: 30000000, city: 'Hồ Chí Minh',
        lvl: ExperienceLevel.junior, mode: WorkMode.remote,
        tags: ['Facebook Ads', 'Google Ads', 'SEO'], daysAgo: 5,
        moTa: [
          'Lên ý tưởng, lập kế hoạch và triển khai các chiến dịch marketing online.',
          'Chạy quảng cáo (Facebook Ads, Google Ads, TikTok Ads) và tối ưu chi phí.',
          'Quản lý và sáng tạo nội dung trên các kênh Social Media.',
          'Phân tích dữ liệu, đo lường hiệu quả chiến dịch và lập báo cáo định kỳ.',
          'Phối hợp với Design, Sales, Production để sản xuất tài liệu truyền thông.',
          'Nghiên cứu thị trường, đối thủ và xu hướng người tiêu dùng.',
        ],
        yeuCau: [
          'Tốt nghiệp Đại học chuyên ngành Marketing, Truyền thông, QTKD.',
          'Thành thạo các công cụ: Facebook Ads, Google Ads, Google Analytics.',
          'Kỹ năng sáng tạo nội dung (Content), tư duy thẩm mỹ tốt.',
          'Am hiểu Social Media trends và hành vi người dùng VN.',
          'Tiếng Anh đọc-viết tốt để research tài liệu quốc tế.',
          'Chủ động, sáng tạo, chịu được áp lực deadline.',
        ],
        quyenLoi: [
          'Lương + thưởng KPI theo hiệu quả chiến dịch.',
          'Hỗ trợ chi phí chạy Ads test và công cụ marketing.',
          'Lương tháng 13 và thưởng Lễ/Tết.',
          'Làm việc Remote 100%, linh hoạt thời gian.',
          'Được làm việc với nhiều brand lớn, đa ngành.',
        ],
        thoiGian: 'Thứ 2 - Thứ 6 (từ 09:00 đến 18:00)', bangCap: 'Đại học trở lên',
      ),
      j(
        title: 'Nhân Viên Hành Chính Nhân Sự',
        company: 'CÔNG TY TNHH LOGISTICS VIETTEL',
        category: 'Hành chính nhân sự',
        city: 'Bình Dương',
        lvl: ExperienceLevel.junior, mode: WorkMode.onsite,
        tags: ['Tuyển dụng', 'C&B', 'Excel'], daysAgo: 7,
        moTa: [
          'Hỗ trợ các công việc hành chính văn phòng: tiếp khách, hồ sơ, giấy tờ.',
          'Theo dõi, quản lý hợp đồng lao động, BHXH, chấm công, tính lương.',
          'Tham gia tuyển dụng: đăng tin, sàng lọc CV, sắp xếp phỏng vấn.',
          'Tổ chức các hoạt động nội bộ, văn hóa doanh nghiệp.',
          'Quản lý tài sản, văn phòng phẩm và cơ sở vật chất.',
          'Lưu trữ, sắp xếp hồ sơ tài liệu khoa học.',
        ],
        yeuCau: [
          'Tốt nghiệp Cao đẳng/Đại học chuyên ngành Hành chính, Nhân sự.',
          'Kinh nghiệm HC-NS hoặc tuyển dụng là lợi thế.',
          'Thành thạo Word, Excel, PowerPoint.',
          'Giao tiếp tốt, tỉ mỉ, cẩn thận.',
          'Am hiểu Luật Lao động, BHXH là lợi thế.',
        ],
        quyenLoi: [
          'Lương ổn định, thưởng Lễ/Tết và thưởng cuối năm.',
          'Đóng BHXH, BHYT đầy đủ.',
          'Môi trường văn phòng chuyên nghiệp, thân thiện.',
          'Lộ trình phát triển lên Specialist / HR Manager.',
        ],
        thoiGian: 'Thứ 2 - Thứ 6 (từ 08:00 đến 17:30), Thứ 7 sáng', bangCap: 'Cao đẳng trở lên',
      ),
      j(
        title: 'Senior Frontend Developer (ReactJS)',
        company: 'CÔNG TY CỔ PHẦN VNG',
        category: 'IT - Công nghệ thông tin',
        min: 40000000, max: 60000000, city: 'Hồ Chí Minh',
        lvl: ExperienceLevel.senior, mode: WorkMode.hybrid,
        tags: ['ReactJS', 'TypeScript', 'TailwindCSS'], daysAgo: 2,
        moTa: [
          'Design, develop, and maintain reusable React components and design systems.',
          'Optimize application performance (Core Web Vitals, bundle size).',
          'Participate in code reviews and mentor junior developers.',
          'Collaborate with Product and Design teams to ship features.',
          'Implement CI/CD pipelines and automated testing.',
          'Contribute to technical design and architecture decisions.',
        ],
        yeuCau: [
          "Bachelor's Degree in IT, Computer Science or related field.",
          '4+ years of experience in Frontend development with React.',
          'Deep knowledge of React, TypeScript, and modern build tools.',
          'Experience with state management (Redux, Zustand, React Query).',
          'Strong understanding of web performance and accessibility.',
          'Experience with TailwindCSS / design systems is a plus.',
        ],
        quyenLoi: [
          'Competitive salary (40-60 triệu) + 13th month + performance bonus.',
          'Premium healthcare insurance from probation period.',
          '14+ annual leaves per year.',
          'Stock options for senior roles.',
          'Annual company trip and teambuilding.',
          'Tailor-made career path with international mobility.',
        ],
        thoiGian: 'Thứ 2 - Thứ 6 (từ 09:00 đến 18:00), Hybrid', bangCap: 'Đại học trở lên',
      ),
      j(
        title: 'Chuyên Viên Tín Dụng - Ngân Hàng',
        company: 'NGÂN HÀNG TMCP VCB',
        category: 'Ngân hàng',
        min: 15000000, max: 30000000, city: 'Hà Nội',
        lvl: ExperienceLevel.junior, mode: WorkMode.onsite,
        tags: ['Tín dụng', 'Thẩm định'], daysAgo: 4,
        moTa: [
          'Tư vấn và cung cấp các sản phẩm dịch vụ tài chính cho khách hàng.',
          'Thẩm định hồ sơ vay vốn, đánh giá rủi ro tín dụng.',
          'Hỗ trợ khách hàng hoàn thiện hồ sơ và theo dõi giải ngân.',
          'Đạt chỉ tiêu KPI doanh số/tháng/quý theo phân công.',
          'Quản lý nợ và phối hợp thu hồi khi cần.',
        ],
        yeuCau: [
          'Tốt nghiệp Đại học trở lên chuyên ngành Tài chính, Ngân hàng.',
          'Kinh nghiệm tín dụng/kinh doanh ngân hàng là lợi thế.',
          'Ngoại hình sáng, giao tiếp tốt, phong cách chuyên nghiệp.',
          'Am hiểu sản phẩm ngân hàng và quy trình tín dụng.',
          'Trung thực, nhạy bén với rủi ro tín dụng.',
        ],
        quyenLoi: [
          'Thu nhập cộng dồn không giới hạn (lương cứng + hoa hồng).',
          'Được đào tạo bài bản, lộ trình thăng tiến lên Cấp quản lý.',
          'Chế độ đãi ngộ của ngân hàng (BHXH, lương tháng 13, thưởng KV).',
          'Khám sức khỏe định kỳ, phụ cấp ăn trưa.',
        ],
        thoiGian: 'Thứ 2 - Thứ 6 (từ 08:00 đến 17:00)', bangCap: 'Đại học trở lên',
      ),
      j(
        title: 'Nhân Viên Chăm Sóc Khách Hàng',
        company: 'CÔNG TY TNHH DỊCH VỤ GRAB',
        category: 'Chăm sóc khách hàng',
        min: 8000000, max: 12000000, city: 'Hồ Chí Minh',
        lvl: ExperienceLevel.intern, mode: WorkMode.onsite,
        tags: ['CSKH', 'Telesales'], daysAgo: 3,
        moTa: [
          'Tiếp nhận và xử lý các yêu cầu, khiếu nại của khách hàng.',
          'Tư vấn, hướng dẫn khách hàng sử dụng sản phẩm/dịch vụ.',
          'Cập nhật thông tin khách hàng vào hệ thống CRM.',
          'Đảm bảo chất lượng dịch vụ theo KPI/QA đề ra.',
          'Hỗ trợ chéo cho team Sales/Marketing khi cần.',
        ],
        yeuCau: [
          'Tốt nghiệp Trung cấp/Cao đẳng trở lên.',
          'Giọng nói dễ nghe, truyền cảm, không nói ngọng/địa phương.',
          'Kiên nhẫn, hòa nhã, chịu được áp lực.',
          'Sử dụng thành thạo máy tính, gõ phím nhanh.',
          'Làm việc theo ca xoay được (cho call center).',
        ],
        quyenLoi: [
          'Lương cứng + thưởng theo SLA và satisfaction.',
          'Phụ cấp ca đêm, hỗ trợ cơm trưa.',
          'Đào tạo kỹ năng CSKH và sản phẩm bài bản.',
          'Đóng BHXH đầy đủ, thưởng Lễ Tết.',
        ],
        thoiGian: 'Làm theo ca xoay (có ca sáng/chiều/tối)', bangCap: 'Trung cấp trở lên',
      ),
      j(
        title: 'Kỹ Sư Xây Dựng - Dự Án Lớn',
        company: 'CÔNG TY CỔ PHẦN XÂY DỰNG COTEC',
        category: 'Kỹ sư xây dựng',
        min: 20000000, max: 35000000, city: 'Đà Nẵng',
        lvl: ExperienceLevel.mid, mode: WorkMode.onsite,
        tags: ['Giám sát thi công', 'AutoCAD', 'Dự toán'], daysAgo: 6,
        moTa: [
          'Giám sát thi công công trình, đảm bảo tiến độ và chất lượng.',
          'Lập biện pháp thi công, dự toán khối lượng và chi phí.',
          'Quản lý nhân công, vật tư tại hiện trường.',
          'Kiểm tra, nghiệm thu các hạng mục theo hồ sơ thiết kế.',
          'Đảm bảo an toàn lao động (HSE) và vệ sinh môi trường.',
          'Xử lý các sự cố kỹ thuật phát sinh tại công trình.',
        ],
        yeuCau: [
          'Tốt nghiệp Đại học chuyên ngành Xây dựng dân dụng/công nghiệp.',
          'Kinh nghiệm giám sát/quản lý thi công công trình.',
          'Thành thạo AutoCAD, các phần mềm dự toán (G8, Sino).',
          'Có chứng chỉ hành nghề Supervision / Chỉ huy trưởng là lợi thế.',
          'Am hiểu tiêu chuẩn TCVN về xây dựng.',
        ],
        quyenLoi: [
          'Lương cao theo năng lực + phụ cấp hiện trường.',
          'Bảo hiểm tai nạn lao động.',
          'Phụ cấp đi lại, điện thoại, hỗ trợ chỗ ở tại công trường.',
          'Thưởng tiến độ dự án.',
        ],
        thoiGian: 'Thứ 2 - Thứ 7 (từ 07:30 đến 17:00)', bangCap: 'Đại học trở lên',
      ),
      j(
        title: 'Thiết Kế Đồ Hoạ (Graphic Designer)',
        company: 'CÔNG TY TNHH TRUYỀN THÔNG MUSECOS',
        category: 'Thiết kế đồ hoạ',
        min: 12000000, max: 18000000, city: 'Hồ Chí Minh',
        lvl: ExperienceLevel.junior, mode: WorkMode.onsite,
        tags: ['Photoshop', 'Illustrator', 'Premiere'], daysAgo: 2,
        moTa: [
          'Thiết kế ấn phẩm truyền thông: banner, poster, social post, logo.',
          'Lên ý tưởng visual cho các chiến dịch marketing.',
          'Sản xuất video ngắn, motion graphics cho social media.',
          'Phối hợp với Marketing, Content để ra visual đúng thông điệp.',
          'Làm việc với printer/production để đảm bảo chất lượng in ấn.',
        ],
        yeuCau: [
          'Tốt nghiệp Cao đẳng/Đại học chuyên ngành Thiết kế đồ họa.',
          'Thành thạo Photoshop, Illustrator, Premiere, After Effects.',
          'Có portfolio rõ ràng, tư duy thẩm mỹ tốt.',
          'Sáng tạo, nhạy bén với xu hướng visual.',
          'Kinh nghiệm UI/UX hoặc 3D là lợi thế lớn.',
        ],
        quyenLoi: [
          'Lương + thưởng theo dự án.',
          'Môi trường sáng tạo, thiết bị hỗ trợ (Wacom, máy cấu hình cao).',
          'Được làm việc với nhiều brand và phong cách đa dạng.',
          'Teambuilding, annual trip.',
        ],
        thoiGian: 'Thứ 2 - Thứ 6 (từ 09:00 đến 18:00)', bangCap: 'Cao đẳng trở lên',
      ),
      j(
        title: 'Content Creator - TikTok',
        company: 'CÔNG TY CỔ PHẦN E-COMMERCE TIKI',
        category: 'Content Marketing',
        min: 12000000, max: 20000000, city: 'Hà Nội',
        lvl: ExperienceLevel.fresher, mode: WorkMode.hybrid,
        tags: ['Content', 'TikTok', 'Video'], daysAgo: 1,
        moTa: [
          'Sáng tạo nội dung video ngắn cho kênh TikTok.',
          'Quay, dựng video theo trend và brief từ team marketing.',
          'Lên kịch bản, ý tưởng nội dung hấp dẫn người xem.',
          'Quản lý kênh TikTok, tương tác với cộng đồng.',
          'Phối hợp team design, marketing ra chiến dịch.',
        ],
        yeuCau: [
          'Tốt nghiệp Cao đẳng trở lên.',
          'Am hiểu nền tảng TikTok, nhạy bén với trend.',
          'Kỹ năng quay dựng (CapCut, Premiere) cơ bản.',
          'Sáng tạo, tư duy hình ảnh tốt.',
          'Chịu được áp lực view/deadline.',
        ],
        quyenLoi: [
          'Lương + thưởng theo view và hiệu quả kênh.',
          'Linh hoạt thời gian, Hybrid.',
          'Môi trường trẻ trung, năng động.',
          'Cơ hội trở thành KOL nội bộ.',
        ],
        thoiGian: 'Thứ 2 - Thứ 6 (từ 09:00 đến 18:00)', bangCap: 'Cao đẳng trở lên',
      ),
      j(
        title: 'DevOps Engineer',
        company: 'CÔNG TY CỔ PHẦN CLOUD VIETTEL',
        category: 'DevOps',
        min: 30000000, max: 50000000, city: 'Hà Nội',
        lvl: ExperienceLevel.senior, mode: WorkMode.remote,
        tags: ['Docker', 'Kubernetes', 'AWS', 'CI/CD'], daysAgo: 3,
        moTa: [
          'Manage and scale Kubernetes clusters in production.',
          'Implement and maintain CI/CD pipelines (GitHub Actions, GitLab CI).',
          'Monitor infrastructure (Prometheus, Grafana) and respond to incidents.',
          'Manage cloud infrastructure on AWS/GCP (IaC with Terraform).',
          'Automate deployment, scaling, and backup processes.',
          'Ensure security best practices across the platform.',
        ],
        yeuCau: [
          "Bachelor's Degree in IT, Computer Science or related field.",
          '4+ years experience in DevOps / SRE / Platform Engineering.',
          'Strong experience with Docker, Kubernetes, and cloud (AWS/GCP).',
          'Proficiency with Infrastructure as Code (Terraform, Ansible).',
          'Experience with monitoring stack (Prometheus, Grafana, ELK).',
          'Good English communication skills.',
        ],
        quyenLoi: [
          'Competitive salary (30-50 triệu) + 13th month + bonus.',
          'Remote-first, flexible hours.',
          'Annual learning & training budget.',
          'Premium healthcare insurance.',
          'Annual company trip, teambuilding activities.',
        ],
        thoiGian: 'Thứ 2 - Thứ 6 (linh hoạt, Remote 100%)', bangCap: 'Đại học trở lên',
      ),
    ];
  }

  /// Distinct demo employers derived from [sampleJobs] (for seeding).
  static List<({String id, String name, String city, String industry})> sampleEmployers() {
    final seen = <String, ({String id, String name, String city, String industry})>{};
    for (final j in sampleJobs()) {
      seen.putIfAbsent(
        j.employerId,
        () => (id: j.employerId, name: j.employerName, city: j.city, industry: j.categoryName ?? ''),
      );
    }
    return seen.values.toList();
  }
}

class TopCompany {
  const TopCompany({
    required this.id,
    required this.name,
    required this.industry,
    required this.location,
    required this.openPositions,
    required this.size,
    required this.initials,
    required this.brand,
    required this.cover,
  });
  final String id;
  final String name;
  final String industry;
  final String location;
  final int openPositions;
  final String size;
  final String initials;
  final String brand;
  final String cover;
}

class FeatureItem {
  const FeatureItem(this.icon, this.title, this.description);
  final String icon;
  final String title;
  final String description;
}

class WorkflowStep {
  const WorkflowStep(this.id, this.icon, this.title, this.description);
  final String id;
  final String icon;
  final String title;
  final String description;
}

class StatItem {
  const StatItem(this.id, this.icon, this.value, this.label);
  final String id;
  final String icon;
  final String value;
  final String label;
}

class Testimonial {
  const Testimonial({
    required this.id,
    required this.name,
    required this.role,
    required this.company,
    required this.avatar,
    required this.rating,
    required this.quote,
  });
  final String id;
  final String name;
  final String role;
  final String company;
  final String avatar;
  final int rating;
  final String quote;
}

class BlogPost {
  const BlogPost({
    required this.id,
    required this.category,
    required this.title,
    required this.excerpt,
    required this.readTime,
    required this.date,
    required this.cover,
  });
  final String id;
  final String category;
  final String title;
  final String excerpt;
  final String readTime;
  final String date;
  final String cover;
}
