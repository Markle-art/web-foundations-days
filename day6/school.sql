-- Day 6 Assignment: A School Database

DROP TABLE IF EXISTS enrolments;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS students;

-- Students table
CREATE TABLE students (
student_id INTEGER PRIMARY KEY,
name TEXT NOT NULL,
email TEXT NOT NULL UNIQUE
);

-- Courses table
CREATE TABLE courses (
course_id INTEGER PRIMARY KEY,
course_name TEXT NOT NULL UNIQUE
);

-- Enrolments links students and courses and stores each grade.
CREATE TABLE enrolments (
enrolment_id INTEGER PRIMARY KEY,
student_id INTEGER NOT NULL,
course_id INTEGER NOT NULL,
grade TEXT,
FOREIGN KEY (student_id) REFERENCES students(student_id),
FOREIGN KEY (course_id) REFERENCES courses(course_id),
UNIQUE (student_id, course_id)
);

-- Insert students
INSERT INTO students (student_id, name, email) VALUES
(1, 'Amina Hassan', 'amina@example.com'),
(2, 'Brian Otieno', 'brian@example.com'),
(3, 'Carol Wanjiku', 'carol@example.com'),
(4, 'David Kiptoo', 'david@example.com');

-- Insert courses
INSERT INTO courses (course_id, course_name) VALUES
(1, 'Database Systems'),
(2, 'Web Development'),
(3, 'Computer Networks');

-- Insert enrolments
INSERT INTO enrolments (enrolment_id, student_id, course_id, grade) VALUES
(1, 1, 1, 'A'),
(2, 1, 2, 'B'),
(3, 2, 1, 'B'),
(4, 2, 3, 'A'),
(5, 3, 2, 'A'),
(6, 3, 3, 'C');

-- QUERY 1: All courses for one student, searched by name
SELECT s.name, c.course_name, e.grade
FROM students AS s
JOIN enrolments AS e ON s.student_id = e.student_id
JOIN courses AS c ON e.course_id = c.course_id
WHERE s.name = 'Amina Hassan';

-- QUERY 2: All students on one course
SELECT s.name, c.course_name
FROM students AS s
JOIN enrolments AS e ON s.student_id = e.student_id
JOIN courses AS c ON e.course_id = c.course_id
WHERE c.course_name = 'Database Systems';

-- QUERY 3: Number of students per course
SELECT c.course_name, COUNT(e.student_id) AS student_count
FROM courses AS c
LEFT JOIN enrolments AS e ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_name
ORDER BY c.course_name;

-- QUERY 4: Students who have no enrolments
SELECT s.student_id, s.name
FROM students AS s
LEFT JOIN enrolments AS e ON s.student_id = e.student_id
WHERE e.enrolment_id IS NULL;

-- QUERY 5: Update one enrolment's grade
UPDATE enrolments
SET grade = 'A'
WHERE enrolment_id = 3;

-- Verify the updated grade
SELECT s.name, c.course_name, e.grade
FROM enrolments AS e
JOIN students AS s ON e.student_id = s.student_id
JOIN courses AS c ON e.course_id = c.course_id
WHERE e.enrolment_id = 3;

-- Index to speed up finding enrolments by student
CREATE INDEX idx_enrolments_student_id
ON enrolments(student_id);