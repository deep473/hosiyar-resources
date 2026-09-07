-- =====================================================================
--  Hosiyar.com  ·  SQL From Zero to Advanced
--  The LMS database used in every video of the series
--
--  Run this ONCE. It creates the database, ten tables, and fills them
--  with data. Everything is generated deterministically, so the rows
--  you get are exactly the rows shown in the videos.
--
--  Expected run time: 30 - 90 seconds. The last step inserts 500,000
--  rows into lesson_progress, which is what makes the indexing videos
--  in Module 7 actually mean something.
-- =====================================================================

DROP DATABASE IF EXISTS hosiyar_lms;
CREATE DATABASE hosiyar_lms
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE hosiyar_lms;

SET FOREIGN_KEY_CHECKS = 0;


-- =====================================================================
--  1. TABLES
-- =====================================================================

CREATE TABLE users (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  full_name     VARCHAR(100)  NOT NULL,
  email         VARCHAR(150)  NOT NULL UNIQUE,
  role          VARCHAR(20)   NOT NULL DEFAULT 'student',
  country       VARCHAR(60)       NULL,
  phone         VARCHAR(20)       NULL,
  signup_date   DATE          NOT NULL,
  last_login    DATETIME          NULL,
  is_active     TINYINT(1)    NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE instructors (
  id                INT AUTO_INCREMENT PRIMARY KEY,
  user_id           INT           NOT NULL UNIQUE,
  headline          VARCHAR(150)      NULL,
  years_experience  INT               NULL,
  CONSTRAINT fk_instructor_user
    FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE categories (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(80) NOT NULL,
  parent_id  INT             NULL,
  CONSTRAINT fk_category_parent
    FOREIGN KEY (parent_id) REFERENCES categories(id)
) ENGINE=InnoDB;

CREATE TABLE courses (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  title          VARCHAR(150)  NOT NULL,
  price          DECIMAL(8,2)  NOT NULL DEFAULT 0.00,
  level          VARCHAR(20)   NOT NULL,
  language       VARCHAR(30)   NOT NULL DEFAULT 'English',
  category_id    INT               NULL,
  instructor_id  INT               NULL,
  status         VARCHAR(20)   NOT NULL DEFAULT 'published',
  published_at   DATE              NULL,
  CONSTRAINT fk_course_category
    FOREIGN KEY (category_id)   REFERENCES categories(id),
  CONSTRAINT fk_course_instructor
    FOREIGN KEY (instructor_id) REFERENCES instructors(id)
) ENGINE=InnoDB;

CREATE TABLE lessons (
  id                INT AUTO_INCREMENT PRIMARY KEY,
  course_id         INT          NOT NULL,
  title             VARCHAR(150) NOT NULL,
  position          INT          NOT NULL,
  duration_minutes  INT          NOT NULL,
  is_free_preview   TINYINT(1)   NOT NULL DEFAULT 0,
  CONSTRAINT fk_lesson_course
    FOREIGN KEY (course_id) REFERENCES courses(id)
) ENGINE=InnoDB;

CREATE TABLE enrollments (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  user_id       INT      NOT NULL,
  course_id     INT      NOT NULL,
  enrolled_at   DATETIME NOT NULL,
  completed_at  DATETIME     NULL,
  UNIQUE KEY uq_enrollment (user_id, course_id),
  CONSTRAINT fk_enrollment_user
    FOREIGN KEY (user_id)   REFERENCES users(id),
  CONSTRAINT fk_enrollment_course
    FOREIGN KEY (course_id) REFERENCES courses(id)
) ENGINE=InnoDB;

CREATE TABLE payments (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT           NOT NULL,
  course_id  INT           NOT NULL,
  amount     DECIMAL(10,2) NOT NULL,
  status     VARCHAR(20)   NOT NULL,
  method     VARCHAR(20)   NOT NULL,
  paid_at    DATETIME          NULL,
  CONSTRAINT fk_payment_user
    FOREIGN KEY (user_id)   REFERENCES users(id),
  CONSTRAINT fk_payment_course
    FOREIGN KEY (course_id) REFERENCES courses(id)
) ENGINE=InnoDB;

CREATE TABLE reviews (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  enrollment_id  INT      NOT NULL UNIQUE,
  rating         INT      NOT NULL,
  comment        TEXT         NULL,
  created_at     DATETIME NOT NULL,
  CONSTRAINT fk_review_enrollment
    FOREIGN KEY (enrollment_id) REFERENCES enrollments(id)
) ENGINE=InnoDB;

CREATE TABLE quiz_attempts (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  enrollment_id   INT      NOT NULL,
  lesson_id       INT      NOT NULL,
  attempt_number  INT      NOT NULL,
  score           INT          NULL,
  attempted_at    DATETIME NOT NULL,
  CONSTRAINT fk_quiz_enrollment
    FOREIGN KEY (enrollment_id) REFERENCES enrollments(id),
  CONSTRAINT fk_quiz_lesson
    FOREIGN KEY (lesson_id)     REFERENCES lessons(id)
) ENGINE=InnoDB;

CREATE TABLE lesson_progress (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  enrollment_id    INT        NOT NULL,
  lesson_id        INT        NOT NULL,
  watched_seconds  INT        NOT NULL DEFAULT 0,
  completed        TINYINT(1) NOT NULL DEFAULT 0,
  last_watched_at  DATETIME       NULL,
  CONSTRAINT fk_progress_enrollment
    FOREIGN KEY (enrollment_id) REFERENCES enrollments(id),
  CONSTRAINT fk_progress_lesson
    FOREIGN KEY (lesson_id)     REFERENCES lessons(id)
) ENGINE=InnoDB;


-- =====================================================================
--  2. A HELPER TABLE OF NUMBERS
--  Used only to generate rows. Dropped again at the end.
-- =====================================================================

CREATE TABLE numbers (n INT NOT NULL PRIMARY KEY) ENGINE=InnoDB;

INSERT INTO numbers (n)
SELECT d3.d * 1000 + d2.d * 100 + d1.d * 10 + d0.d + 1
FROM      (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
           UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d0
CROSS JOIN (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
           UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d1
CROSS JOIN (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
           UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d2
CROSS JOIN (SELECT 0 d UNION ALL SELECT 1) d3;


-- =====================================================================
--  3. CATEGORIES  (a small tree — parent_id points at another category)
-- =====================================================================

INSERT INTO categories (id, name, parent_id) VALUES
  (1,  'Programming',      NULL),
  (2,  'Web Development',  1),
  (3,  'Backend',          1),
  (4,  'Frontend',         2),
  (5,  'Data',             NULL),
  (6,  'Databases',        5),
  (7,  'Data Science',     5),
  (8,  'Cloud and DevOps', NULL),
  (9,  'Java',             3),
  (10, 'Python',           1),
  (11, 'Career',           NULL),
  (12, 'Interview Prep',   11);


-- =====================================================================
--  4. USERS
--  1        = admin
--  2 - 5    = instructors
--  6 - 30   = named students
--  31-2000  = generated students
--  Some phone numbers and last_login values are deliberately NULL.
-- =====================================================================

INSERT INTO users (id, full_name, email, role, country, phone, signup_date, last_login, is_active) VALUES
  (1,  'Priya Nair',      'priya.nair@hosiyar.com',   'admin',      'India',     '+91-9800000001', '2024-01-05', '2026-08-30 09:14:00', 1),
  (2,  'Arjun Mehta',     'arjun.mehta@hosiyar.com',  'instructor', 'India',     '+91-9800000002', '2024-01-08', '2026-08-31 18:40:00', 1),
  (3,  'Sara Lopez',      'sara.lopez@hosiyar.com',   'instructor', 'Spain',     NULL,             '2024-02-11', '2026-08-29 11:02:00', 1),
  (4,  'Daniel Okafor',   'daniel.okafor@hosiyar.com','instructor', 'Nigeria',   '+234-8010000004','2024-03-02', NULL,                  1),
  (5,  'Mei Tanaka',      'mei.tanaka@hosiyar.com',   'instructor', 'Japan',     '+81-9012340005', '2024-03-19', '2026-08-28 07:55:00', 1),
  (6,  'Rahul Sharma',    'rahul.sharma@example.com', 'student',    'India',     '+91-9800000006', '2024-04-01', '2026-08-31 21:10:00', 1),
  (7,  'Rahul Sharma',    'r.sharma88@example.com',   'student',    'India',     NULL,             '2024-04-14', '2026-07-19 16:30:00', 1),
  (8,  'Ananya Iyer',     'ananya.iyer@example.com',  'student',    'India',     '+91-9800000008', '2024-05-02', NULL,                  1),
  (9,  'Tom Bennett',     'tom.bennett@example.com',  'student',    'UK',        '+44-7700900009', '2024-05-21', '2026-08-25 13:44:00', 1),
  (10, 'Fatima Zahra',    'fatima.zahra@example.com', 'student',    'Morocco',   NULL,             '2024-06-03', '2026-08-30 08:20:00', 1),
  (11, 'Carlos Silva',    'carlos.silva@example.com', 'student',    'Brazil',    '+55-1190000011', '2024-06-18', '2026-06-11 19:05:00', 0),
  (12, 'Ishita Bose',     'ishita.bose@example.com',  'student',    'India',     '+91-9800000012', '2024-07-07', '2026-08-27 22:15:00', 1),
  (13, 'Kwame Asante',    'kwame.asante@example.com', 'student',    'Ghana',     NULL,             '2024-07-25', NULL,                  1),
  (14, 'Elena Petrova',   'elena.petrova@example.com','student',    'Bulgaria',  '+359-880000014', '2024-08-09', '2026-08-31 06:48:00', 1),
  (15, 'Vikram Reddy',    'vikram.reddy@example.com', 'student',    'India',     '+91-9800000015', '2024-08-27', '2026-08-22 17:33:00', 1),
  (16, 'Grace Kim',       'grace.kim@example.com',    'student',    'South Korea','+82-1020000016','2024-09-12', '2026-08-30 12:01:00', 1),
  (17, 'Omar Haddad',     'omar.haddad@example.com',  'student',    'Jordan',    NULL,             '2024-09-30', '2026-05-04 10:12:00', 0),
  (18, 'Neha Kulkarni',   'neha.kulkarni@example.com','student',    'India',     '+91-9800000018', '2024-10-15', '2026-08-31 20:27:00', 1),
  (19, 'Liam Murphy',     'liam.murphy@example.com',  'student',    'Ireland',   '+353-830000019', '2024-11-01', '2026-08-18 09:39:00', 1),
  (20, 'Aisha Bello',     'aisha.bello@example.com',  'student',    'Nigeria',   '+234-8010000020','2024-11-19', NULL,                  1),
  (21, 'Rohan Gupta',     'rohan.gupta@example.com',  'student',    'India',     '+91-9800000021', '2024-12-04', '2026-08-29 15:52:00', 1),
  (22, 'Sofia Rossi',     'sofia.rossi@example.com',  'student',    'Italy',     NULL,             '2024-12-22', '2026-08-14 11:18:00', 1),
  (23, 'Yusuf Karim',     'yusuf.karim@example.com',  'student',    'Bangladesh','+880-1700000023','2025-01-09', '2026-08-31 07:04:00', 1),
  (24, 'Meera Pillai',    'meera.pillai@example.com', 'student',    'India',     '+91-9800000024', '2025-01-27', '2026-08-26 18:59:00', 1),
  (25, 'Jonas Weber',     'jonas.weber@example.com',  'student',    'Germany',   '+49-1510000025', '2025-02-13', '2026-07-30 14:22:00', 1),
  (26, 'Divya Menon',     'divya.menon@example.com',  'student',    'India',     NULL,             '2025-03-02', '2026-08-30 23:41:00', 1),
  (27, 'Peter Novak',     'peter.novak@example.com',  'student',    'Czechia',   '+420-600000027', '2025-03-20', NULL,                  0),
  (28, 'Zoya Khan',       'zoya.khan@example.com',    'student',    'Pakistan',  '+92-3000000028', '2025-04-06', '2026-08-28 16:07:00', 1),
  (29, 'Marcus Johnson',  'marcus.j@example.com',     'student',    'USA',       '+1-2125550029',  '2025-04-24', '2026-08-31 05:36:00', 1),
  (30, 'Lakshmi Rao',     'lakshmi.rao@example.com',  'student',    'India',     '+91-9800000030', '2025-05-11', '2026-08-19 10:45:00', 1);

-- generated students 31 - 2000
INSERT INTO users (id, full_name, email, role, country, phone, signup_date, last_login, is_active)
SELECT
  n + 30,
  CONCAT('Student ', n + 30),
  CONCAT('student', n + 30, '@example.com'),
  'student',
  ELT(1 + (n % 8), 'India','India','India','USA','UK','Germany','Nigeria','Brazil'),
  CASE WHEN n % 5 = 0 THEN NULL
       ELSE CONCAT('+91-98', LPAD(n, 8, '0')) END,
  DATE_ADD('2024-01-01', INTERVAL (n % 800) DAY),
  CASE WHEN n % 7 = 0 THEN NULL
       ELSE DATE_ADD('2026-06-01', INTERVAL (n % 90) DAY) END,
  CASE WHEN n % 23 = 0 THEN 0 ELSE 1 END
FROM numbers
WHERE n <= 1970;


-- =====================================================================
--  5. INSTRUCTORS
-- =====================================================================

INSERT INTO instructors (id, user_id, headline, years_experience) VALUES
  (1, 2, 'Backend engineer. Java and Spring since 2013.',        12),
  (2, 3, 'Systems and distributed architecture.',                15),
  (3, 4, 'Frontend and JavaScript. Ex-agency, now teaching.',      9),
  (4, 5, 'Data and cloud. Turns spreadsheets into pipelines.',    11);


-- =====================================================================
--  6. COURSES  (40 rows)
--  Four of them deliberately have no category — that is what the
--  IS NULL examples in Video 3 are looking for.
-- =====================================================================

INSERT INTO courses (id, title, price, level, language, category_id, instructor_id, status, published_at) VALUES
  (1,  'Spring Boot for Beginners',            499.00,  'beginner',     'English', 9,    1, 'published', '2024-06-10'),
  (2,  'SQL From Zero to Advanced',              0.00,  'beginner',     'English', 6,    1, 'published', '2024-07-01'),
  (3,  'Data Structures in Java',              899.00,  'intermediate', 'English', 9,    2, 'published', '2024-07-22'),
  (4,  'Advanced Kafka Patterns',             1299.00,  'advanced',     'English', 3,    2, 'published', '2024-08-14'),
  (5,  'JavaScript Basics',                    399.00,  'beginner',     'English', 4,    3, 'published', '2024-08-30'),
  (6,  'Modern JavaScript Deep Dive',          899.00,  'intermediate', 'English', 4,    3, 'published', '2024-09-18'),
  (7,  'Core Java',                            599.00,  'beginner',     'English', 9,    1, 'published', '2024-10-05'),
  (8,  'Java Concurrency in Practice',        1199.00,  'intermediate', 'English', 9,    2, 'published', '2024-10-27'),
  (9,  'Advanced SQL Tuning',                 1499.00,  'intermediate', 'English', 6,    1, 'published', '2024-11-12'),
  (10, 'SQL for Data Analysts',                699.00,  'beginner',     'English', 7,    4, 'published', '2024-11-29'),
  (11, 'MySQL Administration',                 999.00,  'intermediate', 'English', 6,    1, 'published', '2024-12-15'),
  (12, 'PostgreSQL vs MySQL',                    0.00,  'intermediate', 'English', 6,    1, 'published', '2025-01-04'),
  (13, 'Python for Absolute Beginners',          0.00,  'beginner',     'English', 10,   4, 'published', '2025-01-21'),
  (14, 'Python Data Analysis with Pandas',     799.00,  'intermediate', 'English', 7,    4, 'published', '2025-02-08'),
  (15, 'React from Scratch',                   749.00,  'beginner',     'English', 4,    3, 'published', '2025-02-25'),
  (16, 'Node.js API Development',              849.00,  'intermediate', 'English', 3,    3, 'published', '2025-03-14'),
  (17, 'HTML and CSS Foundations',               0.00,  'beginner',     'English', 4,    3, 'published', '2025-03-30'),
  (18, 'TypeScript for JavaScript Developers', 649.00,  'intermediate', 'English', 4,    3, 'published', '2025-04-16'),
  (19, 'Git and GitHub Essentials',            299.00,  'beginner',     'English', 8,    1, 'published', '2025-05-02'),
  (20, 'Docker Fundamentals',                  699.00,  'beginner',     'English', 8,    4, 'published', '2025-05-19'),
  (21, 'Kubernetes in Production',            1799.00,  'advanced',     'English', 8,    4, 'published', '2025-06-05'),
  (22, 'AWS Cloud Practitioner Prep',          899.00,  'beginner',     'English', 8,    4, 'published', '2025-06-22'),
  (23, 'Distributed Systems Design',          1999.00,  'advanced',     'English', 3,    2, 'published', '2025-07-09'),
  (24, 'System Design Interview Prep',        1599.00,  'intermediate', 'English', 12,   2, 'published', '2025-07-26'),
  (25, 'Coding Interview Patterns',           1099.00,  'intermediate', 'English', 12,   2, 'published', '2025-08-12'),
  (26, 'Resume and LinkedIn for Developers',   199.00,  'beginner',     'English', 11,   1, 'published', '2025-08-29'),
  (27, 'Spring Security Essentials',           949.00,  'intermediate', 'English', 9,    1, 'published', '2025-09-15'),
  (28, 'Hibernate and JPA Explained',          899.00,  'intermediate', 'English', 9,    1, 'published', '2025-10-02'),
  (29, 'REST API Design Principles',           599.00,  'beginner',     'English', 3,    2, 'published', '2025-10-19'),
  (30, 'GraphQL Introduction',                 549.00,  'beginner',     'English', 3,    3, 'published', '2025-11-05'),
  (31, 'Linux Command Line Basics',            249.00,  'beginner',     'English', 8,    4, 'published', '2025-11-22'),
  (32, 'Data Visualisation with Python',       749.00,  'intermediate', 'English', 7,    4, 'published', '2025-12-09'),
  (33, 'Machine Learning Foundations',        1249.00,  'intermediate', 'English', 7,    4, 'published', '2025-12-26'),
  (34, 'Statistics for Data Science',          649.00,  'beginner',     'English', 7,    4, 'published', '2026-01-12'),
  (35, 'Excel to SQL Transition',              349.00,  'beginner',     'English', NULL, 1, 'published', '2026-01-29'),
  (36, 'Database Design Workshop',            1099.00,  'intermediate', 'English', NULL, 1, 'published', '2026-02-15'),
  (37, 'Java Interview Questions',               0.00,  'beginner',     'English', NULL, 2, 'published', '2026-03-04'),
  (38, 'Writing Clean Code',                   449.00,  'beginner',     'English', NULL, 3, 'published', '2026-03-21'),
  (39, 'Testing with JUnit 5',                 799.00,  'intermediate', 'English', 9,    2, 'published', '2026-04-07'),
  (40, 'CI/CD with GitHub Actions',            899.00,  'intermediate', 'English', 8,    4, 'published', '2026-04-24');


-- =====================================================================
--  7. LESSONS  (25 per course = 1,000 rows)
-- =====================================================================

INSERT INTO lessons (course_id, title, position, duration_minutes, is_free_preview)
SELECT
  c.id,
  CONCAT(c.title, ' — Lesson ', n.n),
  n.n,
  6 + ((c.id * 3 + n.n * 7) % 25),
  CASE WHEN n.n <= 2 THEN 1 ELSE 0 END
FROM courses c
JOIN numbers n ON n.n <= 25
ORDER BY c.id, n.n;


-- =====================================================================
--  8. ENROLLMENTS  (roughly 20,000)
--  A student is enrolled in a course when a simple arithmetic rule
--  matches — no randomness, so everyone gets the same rows.
-- =====================================================================

INSERT INTO enrollments (user_id, course_id, enrolled_at, completed_at)
SELECT
  u.id,
  c.id,
  DATE_ADD('2025-01-01 08:00:00', INTERVAL ((u.id * 13 + c.id * 29) % 600) DAY),
  CASE WHEN (u.id + c.id) % 4 = 0
       THEN DATE_ADD('2025-03-01 08:00:00', INTERVAL ((u.id * 7 + c.id * 11) % 500) DAY)
       ELSE NULL END
FROM users u
JOIN courses c
WHERE u.role = 'student'
  AND (u.id * 17 + c.id * 7) % 4 = 0;


-- =====================================================================
--  9. PAYMENTS  (one per enrollment in a paid course)
-- =====================================================================

INSERT INTO payments (user_id, course_id, amount, status, method, paid_at)
SELECT
  e.user_id,
  e.course_id,
  c.price,
  ELT(1 + (e.id % 10), 'captured','captured','captured','captured','captured',
                       'captured','captured','refunded','failed','pending'),
  ELT(1 + (e.id % 4), 'upi','card','netbanking','wallet'),
  CASE WHEN e.id % 10 IN (8, 9) THEN NULL ELSE e.enrolled_at END
FROM enrollments e
JOIN courses c ON c.id = e.course_id
WHERE c.price > 0;


-- =====================================================================
-- 10. REVIEWS  (about a third of enrollments; some have no comment)
-- =====================================================================

INSERT INTO reviews (enrollment_id, rating, comment, created_at)
SELECT
  e.id,
  1 + (e.id % 5),
  CASE WHEN e.id % 3 = 0 THEN NULL
       ELSE ELT(1 + (e.id % 5),
                'Clear and well paced.',
                'Good, but the last section felt rushed.',
                'Exactly what I needed for my project.',
                'Decent. Could use more exercises.',
                'Best course I have taken here.') END,
  DATE_ADD(e.enrolled_at, INTERVAL (10 + (e.id % 60)) DAY)
FROM enrollments e
WHERE e.id % 3 = 0;


-- =====================================================================
-- 11. QUIZ ATTEMPTS  (some scores are still NULL — not graded yet)
-- =====================================================================

INSERT INTO quiz_attempts (enrollment_id, lesson_id, attempt_number, score, attempted_at)
SELECT
  e.id,
  l.id,
  n.n,
  CASE WHEN (e.id + n.n) % 11 = 0 THEN NULL
       ELSE 40 + ((e.id * 3 + n.n * 17) % 61) END,
  DATE_ADD(e.enrolled_at, INTERVAL (n.n * 5 + (e.id % 20)) DAY)
FROM enrollments e
JOIN lessons l ON l.course_id = e.course_id AND l.position = 5
JOIN numbers n ON n.n <= 3
WHERE e.id % 10 = 0;


-- =====================================================================
-- 12. LESSON PROGRESS  (about 500,000 rows — this is the slow step)
--     One row per enrolled student per lesson of that course.
-- =====================================================================

INSERT INTO lesson_progress (enrollment_id, lesson_id, watched_seconds, completed, last_watched_at)
SELECT
  e.id,
  l.id,
  ((e.id * 37 + l.id * 53) % (l.duration_minutes * 60)),
  CASE WHEN (e.id + l.position) % 3 = 0 THEN 1 ELSE 0 END,
  CASE WHEN (e.id + l.position) % 9 = 0 THEN NULL
       ELSE DATE_ADD(e.enrolled_at, INTERVAL (l.position * 2) DAY) END
FROM enrollments e
JOIN lessons l ON l.course_id = e.course_id;


-- =====================================================================
-- 13. TIDY UP
-- =====================================================================

DROP TABLE numbers;
SET FOREIGN_KEY_CHECKS = 1;


-- =====================================================================
-- 14. CHECK IT WORKED
-- =====================================================================

SELECT 'users'           AS table_name, COUNT(*) AS row_count FROM users
UNION ALL SELECT 'instructors',     COUNT(*) FROM instructors
UNION ALL SELECT 'categories',      COUNT(*) FROM categories
UNION ALL SELECT 'courses',         COUNT(*) FROM courses
UNION ALL SELECT 'lessons',         COUNT(*) FROM lessons
UNION ALL SELECT 'enrollments',     COUNT(*) FROM enrollments
UNION ALL SELECT 'payments',        COUNT(*) FROM payments
UNION ALL SELECT 'reviews',         COUNT(*) FROM reviews
UNION ALL SELECT 'quiz_attempts',   COUNT(*) FROM quiz_attempts
UNION ALL SELECT 'lesson_progress', COUNT(*) FROM lesson_progress;
