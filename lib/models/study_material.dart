import 'package:flutter/material.dart';

IconData iconForSubject(String subject) {
  switch (subject.toLowerCase()) {
    case 'english':
      return Icons.menu_book;
    case 'maths':
    case 'math':
    case 'mathematics':
      return Icons.functions;
    case 'physics':
      return Icons.science;
    case 'chemistry':
      return Icons.biotech;
    case 'biology':
      return Icons.eco;
    default:
      return Icons.school;
  }
}

class StudyMaterial {
  const StudyMaterial({
    required this.id,
    required this.title,
    required this.subject,
    required this.summary,
    required this.content,
    required this.suggestedMinutes,
    this.videoUrl = '',
  });

  final String id;
  final String title;
  final String subject;
  final String summary;
  final String content;
  final int suggestedMinutes;
  final String videoUrl;

  IconData get icon => iconForSubject(subject);
  bool get hasVideo => videoUrl.trim().isNotEmpty;

  factory StudyMaterial.fromJson(Map<String, dynamic> json) => StudyMaterial(
        id: json['id'] as String,
        title: json['title'] as String,
        subject: json['subject'] as String,
        summary: (json['summary'] as String?) ?? '',
        content: (json['content'] as String?) ?? '',
        suggestedMinutes: (json['suggestedMinutes'] as num?)?.toInt() ?? 10,
        videoUrl: (json['videoUrl'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'summary': summary,
        'content': content,
        'suggestedMinutes': suggestedMinutes,
        'videoUrl': videoUrl,
      };
}

class StudyGroup {
  const StudyGroup({required this.name, required this.materials});

  final String name;
  final List<StudyMaterial> materials;

  factory StudyGroup.fromJson(Map<String, dynamic> json) => StudyGroup(
        name: json['name'] as String,
        materials: (json['materials'] as List)
            .map((m) => StudyMaterial.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'materials': materials.map((m) => m.toJson()).toList(),
      };
}

/// Bundled offline fallback, used the first time the app runs before it can
/// reach the backend, or whenever the device has no cached data and no
/// internet connection.
const fallbackStudyGroup = StudyGroup(
  name: 'Grade 10 Study Group',
  materials: [
    StudyMaterial(
      id: 'english-parts-of-speech',
      title: 'Parts of Speech',
      subject: 'English',
      summary: 'Nouns, pronouns, verbs, adjectives and how they work together.',
      suggestedMinutes: 10,
      videoUrl: 'https://www.youtube.com/watch?v=xIVP1DlVDl8',
      content: '''
English grammar organizes words into eight parts of speech:

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
least four different parts of speech in each.
''',
    ),
    StudyMaterial(
      id: 'maths-quadratic-equations',
      title: 'Quadratic Equations',
      subject: 'Maths',
      summary: 'Solving ax² + bx + c = 0 by factoring and the quadratic formula.',
      suggestedMinutes: 15,
      videoUrl: 'https://www.youtube.com/watch?v=i7idZfS8t8w',
      content: '''
A quadratic equation has the form ax² + bx + c = 0, where a ≠ 0.

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
the same answers.
''',
    ),
    StudyMaterial(
      id: 'physics-newtons-laws',
      title: 'Newton\'s Laws of Motion',
      subject: 'Physics',
      summary: 'The three laws that describe how forces affect motion.',
      suggestedMinutes: 12,
      videoUrl: 'https://www.youtube.com/watch?v=kKKM8Y-u7ds',
      content: '''
Newton's three laws of motion:

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
into space.
''',
    ),
  ],
);
