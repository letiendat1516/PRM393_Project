/**
 * Job detail content pools per industry family.
 * Each family has: responsibilities, requirements (skills), benefits, working hours.
 *
 * Content is realistic Vietnamese (IT uses English like real TopCV IT posts).
 * generate.js picks a random subset per job → no two jobs identical.
 *
 * Stored in job_description as JSON:
 *   { mo_ta, yeu_cau, quyen_loi, thoi_gian_lam_viec }
 */

// Shared benefit pool (most companies offer these). Family can add specifics.
const COMMON_BENEFITS = [
  "Lương thưởng theo năng lực, đánh giá hiệu suất 2 lần/năm.",
  "Đóng BHXH, BHYT đầy đủ theo quy định pháp luật.",
  "Lương tháng 13 và thưởng Lễ/Tết theo chính sách công ty.",
  "12-14 ngày phép/năm cộng phép thâm niên.",
  "Hỗ trợ phí ăn trưa / gửi xe / điện thoại theo vị trí.",
  "Khám sức khỏe định kỳ hàng năm.",
  "Môi trường làm việc trẻ trung, năng động, cơ hội thăng tiến rõ ràng.",
  "Đào tạo nội bộ, tài trợ thi chứng chỉ nghề nghiệp.",
  "Teambuilding, annual trip, các CLB thể thao (bóng đá, cầu lông, bóng rổ).",
  "Laptop/máy tính làm việc cấu hình cao.",
  "Hỗ trợ chăm sóc sức khỏe tâm lý và wellbeing.",
  "Cân bằng công việc - cuộc sống, linh hoạt giờ giấc.",
];

const WORKING_HOURS = [
  "Thứ 2 - Thứ 6 (từ 08:30 đến 17:30)",
  "Thứ 2 - Thứ 6 (từ 09:00 đến 18:00)",
  "Thứ 2 - Thứ 6 (từ 08:00 đến 17:30), Thứ 7 sáng (từ 08:00 đến 12:00)",
  "Thứ 2 - Thứ 6 (từ 09:00 đến 18:00), 1 ngày WFH/tuần",
  "Làm theo ca xoay (có ca sáng/chiều/tối)",
];

// Per-family content. Keyed by family slug.
export const DETAIL_FAMILIES = {
  // ============ IT / SOFTWARE (English, like real TopCV IT posts) ============
  it: {
    responsibilities: [
      "Design, develop, and maintain reliable, scalable, and secure software applications.",
      "Write clean, maintainable, and well-tested code following best practices.",
      "Collaborate with cross-functional teams (Product, QA, DevOps) to deliver features.",
      "Participate in code reviews and mentor junior developers.",
      "Optimize application performance and database queries.",
      "Implement CI/CD pipelines and automated testing.",
      "Troubleshoot, debug, and resolve production issues.",
      "Contribute to technical design and architecture decisions.",
      "Build and consume RESTful APIs and microservices.",
      "Apply test-driven development and ensure appropriate test coverage.",
      "Document technical specifications and software components.",
      "Work in Agile/Scrum ceremonies (sprint planning, daily standup, retrospective).",
    ],
    requirements: [
      "Bachelor's Degree in IT, Computer Science, Software Engineering, or related field.",
      "Solid understanding of data structures, algorithms, and OOP principles.",
      "Proficiency in at least one mainstream programming language.",
      "Experience with relational databases (PostgreSQL, MySQL) and SQL optimization.",
      "Familiarity with Git, Docker, and CI/CD workflows.",
      "Experience with RESTful API design and microservices architecture.",
      "Good English reading and writing skills for technical documentation.",
      "Strong analytical and problem-solving skills.",
      "Experience with cloud platforms (AWS, GCP, Azure) is a plus.",
      "Understanding of security best practices (OWASP Top 10).",
    ],
    extra_benefits: [
      "Competitive salary (13th-month salary + performance bonus).",
      "Premium healthcare insurance from probation period.",
      "14+ annual leaves per year.",
      "Flexible working hours and hybrid/remote options.",
      "Annual company trip and teambuilding activities.",
      "Tailor-made career path with international mobility opportunities.",
      "Technical workshops, conferences, and training courses sponsored.",
    ],
  },

  // ============ SALES / KINH DOANH ============
  sales: {
    responsibilities: [
      "Tìm kiếm và tiếp cận khách hàng tiềm năng theo kênh được phân công.",
      "Tư vấn, giới thiệu sản phẩm/dịch vụ và chốt sale theo target đề ra.",
      "Xây dựng và duy trì mối quan hệ với khách hàng hiện tại.",
      "Lập kế hoạch kinh doanh cá nhân/hàng tuần/hàng tháng và báo cáo kết quả.",
      "Phối hợp với các phòng ban để đảm bảo trải nghiệm khách hàng tốt nhất.",
      "Cập nhật thông tin thị trường, đối thủ và xu hướng ngành.",
      "Theo dõi công nợ, thu hồi thanh toán đúng hạn.",
      "Thực hiện các công việc khác theo phân công của Quản lý trực tiếp.",
    ],
    requirements: [
      "Tốt nghiệp Cao đẳng/Đại học trở lên các chuyên ngành.",
      "Kinh nghiệm sales/kinh doanh là một lợi thế (chấp nhận ứng viên chưa có KN cho một số vị trí).",
      "Giao tiếp lưu loát, tự tin, có khả năng thuyết phục.",
      "Trung thực, nhiệt tình, chịu được áp lực cao về doanh số.",
      "Kỹ năng đàm phán, xử lý từ chối và chốt sale tốt.",
      "Sử dụng thành thạo Office (Word, Excel) và CRM là một lợi thế.",
      "Có phương tiện đi lại (xe máy) cho vị trí sales thị trường.",
    ],
    extra_benefits: [
      "Lương cứng + thưởng hoa hồng không giới hạn theo doanh số.",
      "Thu nhập bình quân 15-30 triệu/tháng (có vị trí 50 triệu+).",
      "Đào tạo kỹ năng sales, sản phẩm định kỳ.",
      "Lộ trình thăng tiến lên Team Leader / Sales Manager rõ ràng.",
    ],
  },

  // ============ MARKETING ============
  marketing: {
    responsibilities: [
      "Lên ý tưởng, lập kế hoạch và triển khai các chiến dịch marketing online/offline.",
      "Quản lý và sáng tạo nội dung trên các kênh Social Media (Facebook, TikTok, LinkedIn...).",
      "Chạy quảng cáo (Facebook Ads, Google Ads, TikTok Ads) và tối ưu chi phí.",
      "Phân tích dữ liệu, đo lường hiệu quả chiến dịch và lập báo cáo định kỳ.",
      "Phối hợp với Design, Sales, Production để sản xuất tài liệu truyền thông.",
      "Quản lý ngân sách marketing và đề xuất điều chỉnh kịp thời.",
      "Nghiên cứu thị trường, đối thủ và xu hướng người tiêu dùng.",
      "Quản lý SEO/Website và tối ưu trải nghiệm người dùng.",
    ],
    requirements: [
      "Tốt nghiệp Đại học chuyên ngành Marketing, Truyền thông, Quản trị kinh doanh.",
      "Có kinh nghiệm Marketing (Digital Marketing là lợi thế).",
      "Thành thạo các công cụ: Facebook Ads, Google Ads, Google Analytics.",
      "Kỹ năng sáng tạo nội dung (Content), tư duy thẩm mỹ tốt.",
      "Am hiểu Social Media trends và hành vi người dùng VN.",
      "Kỹ năng phân tích số liệu và lập báo cáo.",
      "Tiếng Anh đọc-viết tốt để research tài liệu quốc tế.",
      "Chủ động, sáng tạo, chịu được áp lực deadline.",
    ],
    extra_benefits: [
      "Lương + thưởng KPI theo hiệu quả chiến dịch.",
      "Hỗ trợ chi phí chạy Ads test và công cụ marketing.",
      "Được làm việc với nhiều brand lớn, đa ngành.",
    ],
  },

  // ============ ACCOUNTING / KẾ TOÁN ============
  accounting: {
    responsibilities: [
      "Theo dõi, hạch toán các nghiệp vụ kinh tế phát sinh hàng ngày.",
      "Lập hóa đơn, chứng từ và quản lý công nợ phải thu/phải trả.",
      "Thực hiện báo cáo thuế (GTGT, TNDN, TNCN) đúng thời hạn.",
      "Kiểm tra, đối chiếu số liệu kế toán và存货 kho.",
      "Lập báo cáo tài chính, báo cáo quản trị định kỳ.",
      "Tham gia quy trình quyết toán thuế năm và kiểm toán độc lập.",
      "Sử dụng phần mềm kế toán (MISA, Fast, SAP, ERP...).",
      "Tư vấn, đề xuất cải tiến quy trình tài chính - kế toán.",
    ],
    requirements: [
      "Tốt nghiệp Đại học chuyên ngành Kế toán, Kiểm toán, Tài chính.",
      "Có chứng chỉ Chứng hành Kế toán / Kế toán trưởng là lợi thế.",
      "Thành thạo các phần mềm kế toán (MISA, Fast, Excel nâng cao).",
      "Nắm vững Luật Kế toán, Luật Thuế và các thông tư hiện hành.",
      "Cẩn thận, tỉ mỉ, trung thực, có tinh thần trách nhiệm cao.",
      "Kỹ năng tổ chức công việc và quản lý thời gian tốt.",
      "Kinh nghiệm quyết toán thuế và làm việc với cơ quan thuế.",
    ],
    extra_benefits: [
      "Lương ổn định, thưởng Lễ/Tết và thưởng hiệu suất.",
      "Hỗ trợ phí thi chứng chỉ nghề (ACCA, CPA, CMA).",
      "Môi trường làm việc chuyên nghiệp, quy trình rõ ràng.",
    ],
  },

  // ============ BANKING / NGÂN HÀNG ============
  banking: {
    responsibilities: [
      "Tư vấn và cung cấp các sản phẩm dịch vụ tài chính cho khách hàng (vay vốn, thẻ, tiết kiệm).",
      "Tìm kiếm, tiếp cận khách hàng tiềm năng và duy trì quan hệ khách hàng.",
      "Thẩm định hồ sơ vay vốn, đánh giá rủi ro tín dụng.",
      "Hỗ trợ khách hàng hoàn thiện hồ sơ và theo dõi giải ngân.",
      "Đạt chỉ tiêu KPI doanh số/tháng/quý theo phân công.",
      "Cập nhật chính sách, sản phẩm mới của ngân hàng.",
      "Quản lý nợ và phối hợp thu hồi khi cần.",
      "Lập báo cáo định kỳ về tình hình kinh doanh.",
    ],
    requirements: [
      "Tốt nghiệp Đại học trở lên chuyên ngành Tài chính, Ngân hàng, Quản trị kinh doanh.",
      "Kinh nghiệm tín dụng/kinh doanh ngân hàng là lợi thế.",
      "Ngoại hình sáng, giao tiếp tốt, phong cách chuyên nghiệp.",
      "Am hiểu sản phẩm ngân hàng và quy trình tín dụng.",
      "Kỹ năng sale, đàm phán và chăm sóc khách hàng.",
      "Có sẵn data khách hàng là một lợi thế lớn.",
      "Trung thực, nhạy bén với rủi ro tín dụng.",
    ],
    extra_benefits: [
      "Thu nhập cộng dồn không giới hạn (lương cứng + hoa hồng).",
      "Được đào tạo bài bản, lộ trình thăng tiến lên Cấp quản lý.",
      "Chế độ đãi ngộ của ngân hàng (BHXH, BHYT cao, lương tháng 13, thưởng KV).",
    ],
  },

  // ============ ADMIN / HR ============
  admin_hr: {
    responsibilities: [
      "Hỗ trợ các công việc hành chính văn phòng: tiếp khách, hồ sơ, giấy tờ.",
      "Theo dõi, quản lý hợp đồng lao động, BHXH, chấm công, tính lương.",
      "Tham gia tuyển dụng: đăng tin, sàng lọc CV, sắp xếp phỏng vấn.",
      "Tổ chức các hoạt động nội bộ, văn hóa doanh nghiệp, teambuilding.",
      "Quản lý tài sản, văn phòng phẩm và cơ sở vật chất.",
      "Lưu trữ, sắp xếp hồ sơ tài liệu khoa học.",
      "Hỗ trợ onboard/offboard nhân sự mới.",
      "Lập báo cáo nhân sự, hành chính định kỳ.",
    ],
    requirements: [
      "Tốt nghiệp Cao đẳng/Đại học chuyên ngành Hành chính, Nhân sự, Quản trị văn phòng.",
      "Kinh nghiệm HC-NS hoặc tuyển dụng là lợi thế.",
      "Thành thạo Word, Excel, PowerPoint.",
      "Giao tiếp tốt, ngoại hình ưa nhìn cho vị trí Lễ tân.",
      "Tỉ mỉ, cẩn thận, bảo mật thông tin tốt.",
      "Kỹ năng tổ chức sự kiện và làm việc nhóm.",
      "Am hiểu Luật Lao động, BHXH là lợi thế.",
    ],
    extra_benefits: [
      "Lương ổn định, thưởng Lễ/Tết và thưởng cuối năm.",
      "Môi trường văn phòng chuyên nghiệp, thân thiện.",
      "Lộ trình phát triển lên Specialist / HR Manager.",
    ],
  },

  // ============ CUSTOMER SERVICE ============
  cs: {
    responsibilities: [
      "Tiếp nhận và xử lý các yêu cầu, khiếu nại của khách hàng qua điện thoại/email/chat.",
      "Tư vấn, hướng dẫn khách hàng sử dụng sản phẩm/dịch vụ.",
      "Lắng nghe, ghi nhận feedback và chuyển xử lý các phòng ban liên quan.",
      "Cập nhật thông tin khách hàng vào hệ thống CRM.",
      "Đảm bảo chất lượng dịch vụ theo KPI/QA đề ra.",
      "Hỗ trợ chéo cho team Sales/Marketing khi cần.",
      "Theo dõi thời gian xử lý và satisfaction rate.",
    ],
    requirements: [
      "Tốt nghiệp Trung cấp/Cao đẳng trở lên.",
      "Giọng nói dễ nghe, truyền cảm, không nói ngọng/địa phương.",
      "Kỹ năng giao tiếp, lắng nghe và xử lý tình huống khéo léo.",
      "Sử dụng thành thạo máy tính, gõ phím nhanh.",
      "Kiên nhẫn, hòa nhã, chịu được áp lực.",
      "Làm việc theo ca xoay được (cho call center).",
      "Tiếng Anh giao tiếp là lợi thế.",
    ],
    extra_benefits: [
      "Lương cứng + thưởng theo SLA và satisfaction.",
      "Phụ cấp ca đêm, hỗ trợ cơm trưa.",
      "Đào tạo kỹ năng CSKH và sản phẩm bài bản.",
    ],
  },

  // ============ CONSTRUCTION / KỸ SƯ ============
  construction: {
    responsibilities: [
      "Giám sát thi công công trình, đảm bảo tiến độ và chất lượng.",
      "Lập biện pháp thi công, dự toán khối lượng và chi phí.",
      "Quản lý nhân công, vật tư tại hiện trường.",
      "Kiểm tra, nghiệm thu các hạng mục theo hồ sơ thiết kế.",
      "Phối hợp với Chủ đầu tư, Tư vấn giám sát và nhà thầu phụ.",
      "Đảm bảo an toàn lao động (HSE) và vệ sinh môi trường.",
      "Lập báo cáo tiến độ, khối lượng định kỳ.",
      "Xử lý các sự cố kỹ thuật phát sinh tại công trình.",
    ],
    requirements: [
      "Tốt nghiệp Đại học chuyên ngành Xây dựng dân dụng/công nghiệp/cầu đường.",
      "Kinh nghiệm giám sát/quản lý thi công công trình.",
      "Thành thạo AutoCAD, các phần mềm dự toán (G8, Sino).",
      "Có chứng chỉ hành nghề Supervision / Chỉ huy trưởng là lợi thế.",
      "Sức khỏe tốt, chịu được điều kiện thời tiết hiện trường.",
      "Kỹ năng quản lý nhân sự, vật tư và chi phí.",
      "Am hiểu tiêu chuẩn TCVN về xây dựng.",
    ],
    extra_benefits: [
      "Lương cao theo năng lực + phụ cấp hiện trường.",
      "Bảo hiểm tai nạn lao động, hỗ trợ chỗ ở tại công trường.",
      "Phụ cấp đi lại, điện thoại, xe máy.",
    ],
  },

  // ============ DESIGN ============
  design: {
    responsibilities: [
      "Thiết kế ấn phẩm truyền thông: banner, poster, social post, logo, brand identity.",
      "Lên ý tưởng visual cho các chiến dịch marketing.",
      "Sản xuất video ngắn, motion graphics cho social media.",
      "Phối hợp với Marketing, Content để ra visual đúng thông điệp.",
      "Làm việc với printer/production để đảm bảo chất lượng in ấn.",
      "Quản lý asset thiết kế và brand guideline.",
      "Cập nhật xu hướng thiết kế và ứng dụng vào dự án.",
    ],
    requirements: [
      "Tốt nghiệp Cao đẳng/Đại học chuyên ngành Thiết kế đồ họa, Mỹ thuật.",
      "Thành thạo Photoshop, Illustrator, Premiere, After Effects.",
      "Có portfolio rõ ràng, tư duy thẩm mỹ tốt.",
      "Sáng tạo, nhạy bén với xu hướng visual.",
      "Chịu được áp lực deadline, làm việc được nhiều dự án song song.",
      "Kinh nghiệm UI/UX hoặc 3D là lợi thế lớn.",
      "Tiếng Anh đọc hiểu để tham khảo tài liệu.",
    ],
    extra_benefits: [
      "Lương + thưởng theo dự án.",
      "Môi trường sáng tạo, thiết bị hỗ trợ (Wacom, máy cấu hình cao).",
      "Được làm việc với nhiều brand và phong cách đa dạng.",
    ],
  },

  // ============ REAL ESTATE ============
  realestate: {
    responsibilities: [
      "Tìm kiếm và tư vấn các sản phẩm bất động sản phù hợp nhu cầu khách hàng.",
      "Đưa khách đi xem dự án, lập kế hoạch đầu tư BĐS.",
      "Chốt sale và hỗ trợ khách làm thủ tục đặt cọc, hợp đồng.",
      "Phát triển mạng lưới khách hàng và đối tác.",
      "Cập nhật thông tin thị trường, dự án, pháp lý BĐS.",
      "Phối hợp ngân hàng hỗ trợ khách vay vốn.",
      "Đạt chỉ tiêu doanh số theo quý/năm.",
    ],
    requirements: [
      "Tốt nghiệp Trung cấp trở lên.",
      "Ngoại hình sáng, giao tiếp tốt, xe máy riêng.",
      "Kiên trì, chịu áp lực doanh số cao.",
      "Am hiểu thị trường BĐS khu vực phụ trách.",
      "Kỹ năng chốt sale, đàm phán và xây dựng mối quan hệ.",
      "Chấp nhận đi công tác/tuần tra dự án thường xuyên.",
    ],
    extra_benefits: [
      "Hoa hồng cao 1.5-3% giá trị giao dịch (thu nhập 50-100 triệu+/tháng).",
      "Đào tạo bài bản về luật BĐS, kỹ năng sale.",
      "Môi trường năng động, lộ trình lên Sales Manager nhanh.",
    ],
  },

  // ============ EDUCATION ============
  education: {
    responsibilities: [
      "Soạn giáo án và giảng dạy theo chương trình được phân công.",
      "Theo dõi, đánh giá tiến độ học tập của học viên.",
      "Tổ chức các hoạt động học tập, thực hành, ngoại khóa.",
      "Phối hợp với phụ huynh và bộ phận học vụ.",
      "Cập nhật phương pháp giảng dạy và tài liệu mới.",
      "Tham gia họp giáo viên, sinh hoạt chuyên môn.",
      "Báo cáo định kỳ chất lượng giảng dạy.",
    ],
    requirements: [
      "Tốt nghiệp Đại học Sư phạm hoặc chuyên ngành liên quan.",
      "Có chứng chỉ nghiệp vụ sư phạm là lợi thế.",
      "Kiến thức chuyên môn vững, phương pháp truyền đạt tốt.",
      "Yêu nghề, kiên nhẫn, tâm huyết với học viên.",
      "Tiếng Anh tốt (cho vị trí giáo viên tiếng Anh).",
      "Kinh nghiệm giảng dạy là lợi thế.",
    ],
    extra_benefits: [
      "Lương giờ/lương tháng cạnh tranh.",
      "Hỗ trợ chỗ ở cho giáo viên ngoại tỉnh.",
      "Được đào tạo phương pháp sư phạm và công cụ giảng dạy.",
    ],
  },

  // ============ HEALTHCARE ============
  healthcare: {
    responsibilities: [
      "Khám, tư vấn và điều trị theo chuyên khoa được phân công.",
      "Lập hồ sơ bệnh án, theo dõi diễn biến bệnh lý.",
      "Phối hợp với các bác sĩ/kỹ thuật viên trong chẩn đoán và điều trị.",
      "Tư vấn用药 và chế độ chăm sóc cho bệnh nhân.",
      "Tuân thủ quy trình chuyên môn và an toàn y khoa.",
      "Tham gia hội chẩn, đào tạo liên tục (CME).",
      "Cập nhật y văn và phác đồ điều trị mới.",
    ],
    requirements: [
      "Tốt nghiệp Đại học Y/Dược/Học viện相关专业.",
      "Có chứng chỉ hành nghề Y/Dược.",
      "Kinh nghiệm lâm sàng là lợi thế lớn.",
      "Đạo đức nghề nghiệp, ân cần với bệnh nhân.",
      "Khả năng làm việc theo ca và xử lý cấp cứu.",
      "Tiếng Anh y khoa là lợi thế.",
    ],
    extra_benefits: [
      "Lương + phụ cấp chuyên khoa + thưởng productivity.",
      "Bảo hiểm y tế, khám chữa bệnh nội bộ ưu đãi.",
      "Đào tạo chuyên sâu, tài trợ hội thảo y khoa quốc tế.",
    ],
  },

  // ============ LOGISTICS ============
  logistics: {
    responsibilities: [
      "Theo dõi và xử lý các chứng từ xuất nhập khẩu (Invoice, Packing List, B/L, C/O).",
      "Làm việc với Hải quan, Forwarder, hãng tàu để thông quan hàng hóa.",
      "Khai báo hải quan điện tử (VNACCS/VCIS).",
      "Quản lý tiến độ giao nhận, kho bãi, vận tải.",
      "Lập chứng từ và kiểm tra tính hợp lệ theo L/C.",
      "Theo dõi công nợ, phí logistics và tối ưu chi phí.",
      "Lập báo cáo xuất nhập khẩu định kỳ.",
    ],
    requirements: [
      "Tốt nghiệp Đại học chuyên ngành Kinh tế đối ngoại, Logistics, QTKD.",
      "Kinh nghiệm XNK/Forwarder/Hải quan là lợi thế.",
      "Thành thạo tiếng Anh công việc (đọc hiểu chứng từ).",
      "Am hiểu INCOTERMS, UCP 600, quy trình XNK.",
      "Kỹ năng làm việc chính xác với số liệu và chứng từ.",
      "Sử dụng phần mềm khai báo hải quan.",
    ],
    extra_benefits: [
      "Lương + phụ cấp điện thoại/đi lại.",
      "Hỗ trợ phí đào tạo chứng chỉ chuyên ngành.",
      "Môi trường năng động, tiếp xúc nhiều đối tác quốc tế.",
    ],
  },

  // ============ PRODUCTION / SẢN XUẤT ============
  production: {
    responsibilities: [
      "Vận hành máy móc/dây chuyền sản xuất theo quy trình.",
      "Kiểm soát chất lượng sản phẩm (QC/QA) theo tiêu chuẩn.",
      "Báo cáo sản lượng, lỗi và hiệu suất máy.",
      "Bảo trì, vệ sinh máy móc định kỳ (5S).",
      "Tuân thủ quy định an toàn lao động và môi trường.",
      "Đề xuất cải tiến quy trình sản xuất.",
      "Phối hợp với bảo trì để xử lý sự cố máy.",
    ],
    requirements: [
      "Tốt nghiệp Trung cấp/Phổ thông trở lên.",
      "Sức khỏe tốt, chịu được môi trường nhà máy.",
      "Trung thực, kỷ luật, làm việc theo ca được.",
      "Kinh nghiệm vận hành máy CNC/injection molding là lợi thế.",
      "Đọc hiểu bản vẽ kỹ thuật cơ bản.",
      "Tuân thủ 5S và an toàn lao động.",
    ],
    extra_benefits: [
      "Lương sản phẩm + phụ cấp ca đêm, độc hại.",
      "Bảo hiểm tai nạn lao động, khám sức khỏe định kỳ.",
      "Cơm ca, xe đưa rước, hỗ trợ nhà ở công nhân.",
    ],
  },

  // ============ HOSPITALITY ============
  hospitality: {
    responsibilities: [
      "Phục vụ khách hàng tại nhà hàng/khách sạn theo tiêu chuẩn.",
      "Đón tiếp, hướng dẫn và giải đáp thắc mắc của khách.",
      "Đảm bảo vệ sinh, an toàn thực phẩm và phục vụ chuyên nghiệp.",
      "Phối hợp bếp/quản lý để vận hành trơn tru.",
      "Thanh toán, đối soát doanh thu cuối ca.",
      "Đề xuất cải tiến trải nghiệm khách hàng.",
    ],
    requirements: [
      "Tốt nghiệp Trung cấp trở lên (Quản trị khách sạn/du lịch là lợi thế).",
      "Ngoại hình sáng, giao tiếp tốt, tiếng Anh giao tiếp cơ bản.",
      "Kiên nhẫn, hòa nhã, chịu được áp lực giờ cao điểm.",
      "Làm việc theo ca xoay (sáng/chiều/tối).",
      "Sức khỏe tốt, vệ sinh cá nhân tốt.",
    ],
    extra_benefits: [
      "Lương + phí dịch vụ (service charge) + tip.",
      "Cơm ca, đồng phục, đào tạo tiêu chuẩn 5 sao.",
      "Lộ trình thăng tiến lên Quản lý/Trưởng ca.",
    ],
  },

  // ============ ELECTRICAL ============
  electrical: {
    responsibilities: [
      "Lắp đặt, bảo trì và sửa chữa hệ thống điện, điện lạnh, PCCC.",
      "Đọc bản vẽ điện và triển khai thi công.",
      "Kiểm tra, nghiệm thu và bàn giao công trình.",
      "Báo cáo tiến độ, vật tư và sự cố kỹ thuật.",
      "Tuân thủ tiêu chuẩn an toàn điện (TCVN, IEC).",
      "Hỗ trợ thiết kế biện pháp thi công MEP.",
    ],
    requirements: [
      "Tốt nghiệp Cao đẳng/Đại học chuyên ngành Điện, Điện lạnh, Cơ điện.",
      "Kinh nghiệm thi công/bảo trì MEP.",
      "Thành thạo AutoCAD điện.",
      "Sức khỏe tốt, làm việc tại công trình/điểm cao.",
      "Có chứng chỉ an toàn điện là lợi thế.",
    ],
    extra_benefits: [
      "Lương theo năng lực + phụ cấp hiện trường.",
      "Bảo hiểm tai nạn lao động, hỗ trợ công cụ.",
    ],
  },

  // ============ DRIVER ============
  driver: {
    responsibilities: [
      "Lái xe đưa đón lãnh đạo/khách hàng hoặc vận chuyển hàng hóa.",
      "Bảo quản, vệ sinh xe và kiểm tra định kỳ.",
      "Tuân thủ luật giao thông và an toàn khi lái xe.",
      "Ghi chép nhiên liệu, lộ trình và chi phí xe.",
      "Hỗ trợ các công việc khác theo phân công.",
    ],
    requirements: [
      "Có bằng lái B2, C, D hoặc E phù hợp vị trí.",
      "Kinh nghiệm lái xe từ 2 năm trở lên.",
      "Sức khỏe tốt, không tiền án tiền sự.",
      "Ngoại hình sáng, giao tiếp ứng xử lịch sự (cho vị trí lái xe sếp).",
      "Thành thạo đường phố khu vực làm việc.",
    ],
    extra_benefits: [
      "Lương + phụ cấp xăng, điện thoại.",
      "Hỗ trợ chỗ ở cho lái xe đường dài.",
      "Thưởng Lễ/Tết và chế độ BHXH đầy đủ.",
    ],
  },

  // ============ LAW ============
  law: {
    responsibilities: [
      "Tư vấn pháp lý cho các giao dịch, hợp đồng của công ty.",
      "Soạn thảo, rà soát hợp đồng và văn bản pháp lý.",
      "Theo dõi, cập nhật luật pháp và tư vấn tuân thủ.",
      "Đại diện công ty làm việc với cơ quan nhà nước.",
      "Xử lý tranh chấp, khiếu nại và tố tụng nếu phát sinh.",
      "Lập và lưu trữ hồ sơ pháp lý của doanh nghiệp.",
    ],
    requirements: [
      "Tốt nghiệp Đại học Luật.",
      "Có chứng chỉ hành nghề Luật sư là lợi thế.",
      "Kinh nghiệm pháp chế doanh nghiệp.",
      "Kỹ năng soạn thảo, đàm phán và tư vấn.",
      "Am hiểu Luật Doanh nghiệp, Lao động, Đất đai.",
      "Tiếng Anh pháp lý là lợi thế.",
    ],
    extra_benefits: [
      "Lương cạnh tranh + thưởng theo dự án.",
      "Hỗ trợ phí duy trì chứng chỉ hành nghề.",
      "Môi trường chuyên nghiệp, lộ trình lên Legal Manager.",
    ],
  },

  // ============ RETAIL / BÁN LẺ ============
  retail: {
    responsibilities: [
      "Tư vấn và bán hàng tại cửa hàng/showroom.",
      "Trưng bày sản phẩm và quản lý kho cửa hàng.",
      "Thanh toán, xuất hóa đơn và chăm sóc khách hàng.",
      "Báo cáo doanh số, tồn kho cuối ngày.",
      "Đảm bảo vệ sinh, trưng bày theo chuẩn visual merchandising.",
      "Phối hợp team marketing cho các chương trình khuyến mãi.",
    ],
    requirements: [
      "Tốt nghiệp Trung cấp trở lên.",
      "Ngoại hình sáng, giao tiếp tốt, nhiệt tình.",
      "Trung thực, cẩn thận với tiền và hàng hóa.",
      "Làm việc theo ca và cuối tuần.",
      "Sử dụng POS, Excel cơ bản.",
    ],
    extra_benefits: [
      "Lương + thưởng doanh số cửa hàng.",
      "Phụ cấp ăn trưa, đồng phục.",
      "Lộ trình lên Quản lý cửa hàng / Area Manager.",
    ],
  },

  // ============ CONSULTING ============
  consulting: {
    responsibilities: [
      "Tư vấn sản phẩm/dịch vụ cho khách hàng theo chuyên môn.",
      "Phân tích nhu cầu và đề xuất giải pháp phù hợp.",
      "Theo đuổi sale và đạt KPI khách hàng.",
      "Duy trì quan hệ khách hàng dài hạn.",
      "Phối hợp đối tác và phòng ban nội bộ.",
      "Cập nhật kiến thức chuyên môn và thị trường.",
    ],
    requirements: [
      "Tốt nghiệp Đại học chuyên ngành liên quan.",
      "Kỹ năng giao tiếp, thuyết phục và lắng nghe.",
      "Am hiểu sản phẩm và thị trường.",
      "Trung thực, chuyên nghiệp, chịu áp lực KPI.",
      "Tiếng Anh giao tiếp là lợi thế.",
    ],
    extra_benefits: [
      "Lương cứng + hoa hồng + thưởng KPI.",
      "Đào tạo chuyên môn bài bản.",
      "Lộ trình lên Chuyên viên cao cấp / Team Leader.",
    ],
  },

  // ============ TRANSLATION ============
  translation: {
    responsibilities: [
      "Biên dịch tài liệu (văn bản, hợp đồng, kỹ thuật) giữa tiếng Việt và ngoại ngữ.",
      "Phiên dịch họp, đàm phán, hội thảo.",
      "Hiệu đính và đảm bảo chất lượng bản dịch.",
      "Sử dụng CAT tools (Trados, MemoQ) khi cần.",
      "Tuân thủ deadline và bảo mật thông tin.",
    ],
    requirements: [
      "Tốt nghiệp Đại học Ngôn ngữ/Biên phiên dịch.",
      "Trình độ ngoại ngữ C1 trở lên.",
      "Kinh nghiệm biên phiên dịch chuyên ngành là lợi thế.",
      "Kỹ năng viết sắc sảo bằng cả hai ngôn ngữ.",
      "Chịu được áp lực deadline.",
    ],
    extra_benefits: [
      "Lương theo sản phẩm (số từ/số giờ).",
      "Linh hoạt thời gian, có thể nhận việc remote.",
      "Tiếp xúc nhiều lĩnh vực và tài liệu đa dạng.",
    ],
  },

  // ============ MEDIA ============
  media: {
    responsibilities: [
      "Sản xuất nội dung (bài viết, video, hình ảnh) cho các kênh truyền thông.",
      "Phỏng vấn, viết bài theo sự kiện/trend.",
      "Quay, dựng video cho social/YouTube/TikTok.",
      "Phối hợp Design, Marketing ra chiến dịch truyền thông.",
      "Theo dõi metrics và tối ưu nội dung.",
    ],
    requirements: [
      "Tốt nghiệp Đại học Báo chí, Truyền thông, Marketing.",
      "Kỹ năng viết sáng tạo, tư duy hình ảnh tốt.",
      "Thành thạo quay dựng (Premiere, CapCut).",
      "Nhạy bén với trend social media.",
      "Tiếng Anh đọc hiểu tốt.",
    ],
    extra_benefits: [
      "Lương + thưởng theo dự án/view.",
      "Môi trường sáng tạo, thiết bị hỗ trợ.",
      "Được làm việc với nhiều thương hiệu lớn.",
    ],
  },

  // ============ REPAIR ============
  repair: {
    responsibilities: [
      "Sửa chữa, bảo trì máy móc/thiết bị theo phân công.",
      "Chẩn đoán lỗi, báo giá và sửa chữa cho khách.",
      "Lập báo cáo sửa chữa, thay thế linh kiện.",
      "Đảm bảo an toàn lao động khi sửa chữa.",
      "Tư vấn sử dụng và bảo dưỡng cho khách hàng.",
    ],
    requirements: [
      "Tốt nghiệp Trung cấp kỹ thuật hoặc học nghề.",
      "Kinh nghiệm sửa chữa chuyên ngành.",
      "Sức khỏe tốt, cẩn thận, tỉ mỉ.",
      "Có công cụ làm việc riêng.",
      "Trung thực, trách nhiệm với khách.",
    ],
    extra_benefits: [
      "Lương + thưởng theo sản lượng.",
      "Phụ cấp công cụ, điện thoại.",
      "Cơ hội nhận thêm việc ngoài giờ.",
    ],
  },

  // ============ OTHER (fallback) ============
  other: {
    responsibilities: [
      "Thực hiện các công việc theo phân công của Quản lý trực tiếp.",
      "Phối hợp với các bộ phận liên quan để hoàn thành nhiệm vụ.",
      "Đảm bảo tiến độ và chất lượng công việc.",
      "Báo cáo định kỳ và đề xuất cải tiến.",
      "Tuân thủ nội quy và quy trình công ty.",
    ],
    requirements: [
      "Tốt nghiệp Trung cấp/Đại học chuyên ngành liên quan.",
      "Kỹ năng tin học văn phòng cơ bản.",
      "Trung thực, trách nhiệm, thái độ làm việc tích cực.",
      "Khả năng làm việc nhóm và chịu áp lực.",
    ],
    extra_benefits: COMMON_BENEFITS.slice(0, 6),
  },
};

// Working hours + common benefits (exported for generator convenience).
export { COMMON_BENEFITS, WORKING_HOURS };

// Map each category family (from reference.js CATEGORY_FAMILY) → detail family.
export const FAMILY_TO_DETAIL = {
  it: "it",
  "lap-trinh-vien": "it",
  "backend-developer": "it",
  "frontend-developer": "it",
  devops: "it",
  tester: "it",
  "nhan-vien-kinh-doanh": "sales",
  "nhan-vien-sales": "sales",
  "nhan-vien-telesales": "sales",
  marketing: "marketing",
  "nhan-vien-marketing": "marketing",
  "content-marketing": "marketing",
  "digital-marketing": "marketing",
  ke_toan: "accounting",
  "nhan-vien-ke-toan": "accounting",
  "ke-toan-tong-hop": "accounting",
  "kiem-toan": "accounting",
  ngan_hang: "banking",
  "hanh-chinh-nhan-su": "admin_hr",
  "nhan-vien-hanh-chinh": "admin_hr",
  "tuyen-dung-cr177cb178cl182": "admin_hr",
  "nhan-vien-cham-soc-khach-hang": "cs",
  "ky-su-xay-dung": "construction",
  "xay-dung-cr1080": "construction",
  "thiet-ke-do-hoa-designer": "design",
  "thiet-ke-cr826": "design",
  "thiet-ke-noi-that": "design",
  "bat-dong-san": "realestate",
  giao_duc: "education",
  "giao-vien-tieng-anh": "education",
  "duoc-y-te-suc-khoe-cong-nghe-sinh-hoc-cr781": "healthcare",
  "logistics-thu-mua-kho-van-tai-cr711": "logistics",
  kho_van: "logistics",
  "san-xuat-cr417": "production",
  "cong-nhan-san-xuat": "production",
  "nha-hang-khach-san-du-lich-cr857": "hospitality",
  phuc_vu: "hospitality",
  "dien-dien-tu-vien-thong-cr644": "electrical",
  "tai-xe-cr1010": "driver",
  "luat-cr1014": "law",
  "ban-le-dich-vu-doi-song-cr544": "retail",
  "quan-ly-cua-hang": "retail",
  "tu-van-chuyen-mon-cr750": "consulting",
  "bien-phien-dich-cr1013": "translation",
  "phim-va-truyen-hinh-bao-chi-xuat-ban-cr612": "media",
  "tho-sua-chua": "repair",
  "nang-luong-moi-truong-nong-nghiep-cr883": "other",
  "nhom-nghe-khac-cr899": "other",
};
