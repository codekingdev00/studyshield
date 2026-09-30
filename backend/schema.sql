CREATE TABLE IF NOT EXISTS groups (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS materials (
  id TEXT PRIMARY KEY,
  group_id TEXT NOT NULL REFERENCES groups(id),
  title TEXT NOT NULL,
  subject TEXT NOT NULL,
  summary TEXT NOT NULL DEFAULT '',
  content TEXT NOT NULL DEFAULT '',
  video_url TEXT NOT NULL DEFAULT '',
  suggested_minutes INTEGER NOT NULL DEFAULT 10,
  sort_order INTEGER NOT NULL DEFAULT 0
);

INSERT OR IGNORE INTO groups (id, name) VALUES ('grade10', 'Grade 10 Study Group');

INSERT OR IGNORE INTO materials (id, group_id, title, subject, summary, content, video_url, suggested_minutes, sort_order) VALUES
('english-parts-of-speech', 'grade10', 'Parts of Speech', 'English',
 'Nouns, pronouns, verbs, adjectives and how they work together.',
 'English grammar organizes words into eight parts of speech:

1. Noun — names a person, place, thing, or idea (e.g. teacher, Lagos, book).
2. Pronoun — replaces a noun (he, she, it, they).
3. Verb — expresses an action or state (run, is, think).
4. Adjective — describes a noun (tall, blue, difficult).
5. Adverb — describes a verb, adjective, or another adverb (quickly, very).
6. Preposition — shows relationship in place/time (in, on, under, before).
7. Conjunction — joins words or clauses (and, but, because).
8. Interjection — expresses emotion (Wow!, Ouch!).

Practice: Identify the part of speech for each underlined word in your
textbook exercise, then try building three original sentences using at
least four different parts of speech in each.',
 'https://www.youtube.com/watch?v=xIVP1DlVDl8', 10, 1),

('maths-quadratic-equations', 'grade10', 'Quadratic Equations', 'Maths',
 'Solving ax² + bx + c = 0 by factoring and the quadratic formula.',
 'A quadratic equation has the form ax² + bx + c = 0, where a ≠ 0.

Method 1 — Factoring:
Rewrite the equation as a product of two binomials, then set each factor
to zero. Example: x² - 5x + 6 = 0 → (x - 2)(x - 3) = 0 → x = 2 or x = 3.

Method 2 — Quadratic formula:
x = (-b ± √(b² - 4ac)) / 2a

The discriminant (b² - 4ac) tells you the nature of the roots:
- Positive: two real roots
- Zero: one repeated real root
- Negative: two complex roots

Practice: Solve 2x² + 3x - 2 = 0 using both methods and confirm you get
the same answers.',
 'https://www.youtube.com/watch?v=i7idZfS8t8w', 15, 2),

('physics-newtons-laws', 'grade10', 'Newton''s Laws of Motion', 'Physics',
 'The three laws that describe how forces affect motion.',
 'Newton''s three laws of motion:

1. Law of Inertia: An object at rest stays at rest, and an object in
   motion stays in motion at constant velocity, unless acted on by a
   net external force.

2. F = ma: The acceleration of an object is directly proportional to
   the net force acting on it and inversely proportional to its mass.

3. Action-Reaction: For every action, there is an equal and opposite
   reaction.

Worked example: A 2 kg cart is pushed with a force of 10 N. Its
acceleration is a = F/m = 10/2 = 5 m/s².

Practice: A 5 kg box experiences a net force of 20 N. Calculate its
acceleration, then explain which law applies to a rocket launching
into space.',
 'https://www.youtube.com/watch?v=kKKM8Y-u7ds', 12, 3);
