import 'note_model.dart';

class AppTemplateTask {
  final String title;
  final String description;
  final String priority;
  final String category;
  final int estimatedMinutes;

  const AppTemplateTask({
    required this.title,
    required this.description,
    this.priority = 'medium',
    this.category = 'planning',
    this.estimatedMinutes = 25,
  });
}

class AppTemplate {
  final String id;
  final String title;
  final String description;
  final String noteTitle;
  final String noteContent;
  final List<String> tags;
  final List<NoteStructuredBlockModel> blocks;
  final List<AppTemplateTask> tasks;

  const AppTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.noteTitle,
    required this.noteContent,
    required this.tags,
    required this.blocks,
    this.tasks = const [],
  });

  bool get hasTaskPlan => tasks.isNotEmpty;
}

const appTemplates = [
  AppTemplate(
    id: 'daily_plan',
    title: 'Daily plan',
    description: 'Top priorities, schedule anchors, and closing review.',
    noteTitle: 'Daily Plan',
    noteContent: 'Today I will focus on the most important few things.',
    tags: ['planning', 'daily'],
    blocks: [
      NoteStructuredBlockModel(
        id: 'heading_daily',
        type: 'heading',
        text: 'Daily Plan',
      ),
      NoteStructuredBlockModel(
        id: 'bullets_daily',
        type: 'bullet_list',
        items: ['Top 3 priorities', 'Time blocks', 'Evening review'],
      ),
      NoteStructuredBlockModel(id: 'divider_daily', type: 'divider'),
      NoteStructuredBlockModel(
        id: 'checks_daily',
        type: 'checklist',
        checklistItems: [
          ChecklistItemModel(
            id: 'daily_1',
            text: 'Choose the top priority',
            isCompleted: false,
          ),
          ChecklistItemModel(
            id: 'daily_2',
            text: 'Block focused work time',
            isCompleted: false,
          ),
        ],
      ),
    ],
    tasks: [
      AppTemplateTask(
        title: 'Choose today priorities',
        description: 'Pick the top 3 outcomes for today.',
      ),
      AppTemplateTask(
        title: 'Review today plan',
        description: 'Adjust tasks and timing before starting.',
      ),
    ],
  ),
  AppTemplate(
    id: 'study_session',
    title: 'Study session',
    description: 'Prepare, focus, practice, and summarize.',
    noteTitle: 'Study Session',
    noteContent: 'Topic:\nGoal:\nWhat I learned:',
    tags: ['study'],
    blocks: [
      NoteStructuredBlockModel(
        id: 'heading_study',
        type: 'heading',
        text: 'Study Session',
      ),
      NoteStructuredBlockModel(
        id: 'checks_study',
        type: 'checklist',
        checklistItems: [
          ChecklistItemModel(
            id: 'study_1',
            text: 'Prepare material',
            isCompleted: false,
          ),
          ChecklistItemModel(
            id: 'study_2',
            text: 'Focus for one session',
            isCompleted: false,
          ),
          ChecklistItemModel(
            id: 'study_3',
            text: 'Write a short summary',
            isCompleted: false,
          ),
        ],
      ),
    ],
    tasks: [
      AppTemplateTask(
        title: 'Prepare study material',
        description: 'Open notes, references, and practice questions.',
        category: 'study',
      ),
      AppTemplateTask(
        title: 'Complete focused study session',
        description: 'Study without switching context.',
        category: 'study',
        estimatedMinutes: 50,
      ),
    ],
  ),
  AppTemplate(
    id: 'weekly_review',
    title: 'Weekly review',
    description: 'Review wins, blockers, habits, and next week.',
    noteTitle: 'Weekly Review',
    noteContent: 'Wins:\nLessons:\nNext week:',
    tags: ['review', 'planning'],
    blocks: [
      NoteStructuredBlockModel(
        id: 'heading_weekly',
        type: 'heading',
        text: 'Weekly Review',
      ),
      NoteStructuredBlockModel(
        id: 'bullets_weekly',
        type: 'bullet_list',
        items: ['Wins', 'Blockers', 'Habits', 'Next week focus'],
      ),
    ],
  ),
  AppTemplate(
    id: 'project_plan',
    title: 'Project plan',
    description: 'Outcome, milestones, risks, and next actions.',
    noteTitle: 'Project Plan',
    noteContent: 'Outcome:\nMilestones:\nRisks:\nNext actions:',
    tags: ['project', 'planning'],
    blocks: [
      NoteStructuredBlockModel(
        id: 'heading_project',
        type: 'heading',
        text: 'Project Plan',
      ),
      NoteStructuredBlockModel(id: 'divider_project', type: 'divider'),
      NoteStructuredBlockModel(
        id: 'checks_project',
        type: 'checklist',
        checklistItems: [
          ChecklistItemModel(
            id: 'project_1',
            text: 'Define project outcome',
            isCompleted: false,
          ),
          ChecklistItemModel(
            id: 'project_2',
            text: 'List first milestone',
            isCompleted: false,
          ),
          ChecklistItemModel(
            id: 'project_3',
            text: 'Create next action',
            isCompleted: false,
          ),
        ],
      ),
    ],
    tasks: [
      AppTemplateTask(
        title: 'Define project outcome',
        description: 'Write the target result and success criteria.',
        category: 'project',
      ),
      AppTemplateTask(
        title: 'Create first project milestone',
        description: 'Break the project into the first visible milestone.',
        category: 'project',
      ),
    ],
  ),
  AppTemplate(
    id: 'meeting_notes',
    title: 'Meeting notes',
    description: 'Agenda, decisions, action items, and follow-up.',
    noteTitle: 'Meeting Notes',
    noteContent: 'Attendees:\nAgenda:\nDecisions:\nActions:',
    tags: ['meeting'],
    blocks: [
      NoteStructuredBlockModel(
        id: 'heading_meeting',
        type: 'heading',
        text: 'Meeting Notes',
      ),
      NoteStructuredBlockModel(
        id: 'checks_meeting',
        type: 'checklist',
        checklistItems: [
          ChecklistItemModel(
            id: 'meeting_1',
            text: 'Capture decisions',
            isCompleted: false,
          ),
          ChecklistItemModel(
            id: 'meeting_2',
            text: 'Assign follow-up actions',
            isCompleted: false,
          ),
        ],
      ),
    ],
  ),
  AppTemplate(
    id: 'habit_reset',
    title: 'Habit reset',
    description: 'Choose one habit, reduce friction, and restart.',
    noteTitle: 'Habit Reset',
    noteContent: 'Habit:\nWhy it matters:\nSmallest next step:',
    tags: ['habits', 'reset'],
    blocks: [
      NoteStructuredBlockModel(
        id: 'heading_habit',
        type: 'heading',
        text: 'Habit Reset',
      ),
      NoteStructuredBlockModel(
        id: 'checks_habit',
        type: 'checklist',
        checklistItems: [
          ChecklistItemModel(
            id: 'habit_1',
            text: 'Choose one habit only',
            isCompleted: false,
          ),
          ChecklistItemModel(
            id: 'habit_2',
            text: 'Make it easier to start',
            isCompleted: false,
          ),
        ],
      ),
    ],
  ),
  AppTemplate(
    id: 'ramadan_daily_routine',
    title: 'Ramadan daily routine',
    description: 'Suhoor, prayers, Quran, energy, and Iftar reflection.',
    noteTitle: 'Ramadan Daily Routine',
    noteContent: 'Energy:\nQuran goal:\nReflection:',
    tags: ['ramadan', 'spiritual'],
    blocks: [
      NoteStructuredBlockModel(
        id: 'heading_ramadan',
        type: 'heading',
        text: 'Ramadan Daily Routine',
      ),
      NoteStructuredBlockModel(
        id: 'bullets_ramadan',
        type: 'bullet_list',
        items: [
          'Suhoor prep',
          'Prayer anchors',
          'Quran reading',
          'Iftar reflection',
        ],
      ),
      NoteStructuredBlockModel(
        id: 'checks_ramadan',
        type: 'checklist',
        checklistItems: [
          ChecklistItemModel(
            id: 'ramadan_1',
            text: 'Read Quran pages',
            isCompleted: false,
          ),
          ChecklistItemModel(
            id: 'ramadan_2',
            text: 'Reflect before sleep',
            isCompleted: false,
          ),
        ],
      ),
    ],
    tasks: [
      AppTemplateTask(
        title: 'Read Quran pages',
        description: 'Complete today Quran goal.',
        category: 'spiritual',
      ),
      AppTemplateTask(
        title: 'Prepare Iftar reflection',
        description: 'Write one lesson from the day.',
        category: 'spiritual',
      ),
    ],
  ),
];
