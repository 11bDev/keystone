import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/widgets/app_navigation_actions.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};

  @override
  void initState() {
    super.initState();
    // Initialize section keys
    for (var section in [
      'overview',
      'navigation',
      'tasks',
      'calendar',
      'notes',
      'journal',
      'search',
      'tags',
      'settings',
      'tips'
    ]) {
      _sectionKeys[section] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(String section) {
    final key = _sectionKeys[section];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Documentation'),
        actions: const [
          AppNavigationActions(currentRoute: '/help'),
        ],
      ),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        _buildTableOfContents(),
        const SizedBox(height: 24),
        ..._buildAllSections(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left sidebar with table of contents
        SizedBox(
          width: 280,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildTableOfContents(),
          ),
        ),
        const VerticalDivider(width: 1),
        // Main content area
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(24),
            children: _buildAllSections(),
          ),
        ),
      ],
    );
  }

  Widget _buildTableOfContents() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contents',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildTOCItem('Overview', 'overview', Icons.info_outline),
            _buildTOCItem('Navigation', 'navigation', Icons.menu),
            _buildTOCItem('Tasks & Events', 'tasks', Icons.check_box),
            _buildTOCItem('Calendar', 'calendar', Icons.calendar_today),
            _buildTOCItem('Notes', 'notes', Icons.note),
            _buildTOCItem('Journal', 'journal', Icons.book),
            _buildTOCItem('Search', 'search', Icons.search),
            _buildTOCItem('Tags & Projects', 'tags', Icons.tag),
            _buildTOCItem('Settings', 'settings', Icons.settings),
            _buildTOCItem('Tips & Shortcuts', 'tips', Icons.tips_and_updates),
          ],
        ),
      ),
    );
  }

  Widget _buildTOCItem(String title, String section, IconData icon) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20),
      title: Text(title),
      onTap: () => _scrollToSection(section),
    );
  }

  List<Widget> _buildAllSections() {
    return [
      _buildSection(
        'overview',
        'Overview',
        [
          _buildParagraph(
            'Keystone is a productivity app inspired by the Bullet Journal methodology. '
            'It combines tasks, events, notes, and journal entries in one unified system. '
            'Everything is organized by date and connected through tags and projects.',
          ),
          _buildSubheading('Core Concepts'),
          _buildBullet('Tasks: Things you need to do'),
          _buildBullet('Events: Scheduled activities with optional times'),
          _buildBullet('Notes: Quick thoughts and information'),
          _buildBullet('Journal: Daily reflections and entries'),
          _buildBullet('Tags: Organize with #hashtags'),
          _buildBullet('Projects: Group work with @mentions'),
        ],
      ),
      _buildSection(
        'navigation',
        'Navigation',
        [
          _buildParagraph(
            'The app has six main sections accessible from the navigation bar:',
          ),
          const SizedBox(height: 12),
          _buildIconExample(Icons.home, 'Home', 
            'Your daily dashboard with tasks due today'),
          _buildIconExample(Icons.calendar_today, 'Calendar', 
            'View tasks and events by date'),
          _buildIconExample(Icons.check_box, 'Tasks', 
            'All your tasks and to-dos'),
          _buildIconExample(Icons.account_tree, 'Projects', 
            'Tasks organized by @project'),
          _buildIconExample(Icons.search, 'Search', 
            'Find tasks, notes, and journal entries'),
          _buildIconExample(Icons.settings, 'Settings', 
            'Configure sync, themes, and preferences'),
        ],
      ),
      _buildSection(
        'tasks',
        'Tasks & Events',
        [
          _buildParagraph(
            'Tasks are action items you need to complete. Events are scheduled activities with specific times. '
            'Both can have tags, projects, notes, and due dates.',
          ),
          const SizedBox(height: 16),
          _buildSubheading('Adding Tasks'),
          _buildParagraph(
            '1. Tap the + button (shown below)\n'
            '2. Choose "Task" or "Event"\n'
            '3. Enter a description\n'
            '4. Add tags (#tag) and projects (@project)\n'
            '5. Set a due date and optional note',
          ),
          const SizedBox(height: 12),
          _buildIconExample(Icons.add, 'Add Button', 
            'Create new tasks or events'),
          const SizedBox(height: 16),
          _buildSubheading('Task Icons'),
          _buildParagraph(
            'Tasks display different icons based on their type and status:',
          ),
          const SizedBox(height: 12),
          _buildIconExample(Icons.circle, 'Task', 
            'Regular task'),
          _buildIconExample(Icons.remove, 'Event', 
            'Event with optional times'),
          _buildIconExample(Icons.clear, 'Complete', 
            'Completed task (grayed out)'),
          _buildIconExample(Icons.chevron_right, 'Migrated', 
            'Task moved to another date (grayed out)'),
          const SizedBox(height: 16),
          _buildSubheading('Date Indicators'),
          _buildParagraph(
            'Tasks show icons indicating when they\'re due:',
          ),
          const SizedBox(height: 12),
          _buildIconExample(Icons.today, 'Today', 
            'Task is due today'),
          _buildIconExample(Icons.history, 'Past', 
            'Task is overdue'),
          _buildIconExample(Icons.event, 'Future', 
            'Task is scheduled for later'),
          const SizedBox(height: 16),
          _buildSubheading('Task Actions'),
          _buildParagraph(
            'Tap on a task to see available actions:',
          ),
          const SizedBox(height: 12),
          _buildIconExample(Icons.check_circle_outline, 'Complete', 
            'Mark task as done'),
          _buildIconExample(Icons.edit, 'Edit', 
            'Modify task details'),
          _buildIconExample(Icons.chevron_right, 'Migrate', 
            'Move task to a different date (pending tasks only)'),
          _buildIconExample(Icons.block, 'Cancel', 
            'Mark task as cancelled'),
          _buildIconExample(Icons.undo, 'Undo', 
            'Restore a cancelled task'),
          _buildIconExample(Icons.delete, 'Delete', 
            'Permanently remove task', color: Colors.red),
          const SizedBox(height: 16),
          _buildSubheading('Date Selection'),
          _buildIconExample(Icons.calendar_today, 'Pick Date', 
            'Choose or change the due date'),
          const SizedBox(height: 16),
          _buildSubheading('Task Migration'),
          _buildParagraph(
            'Migration lets you move incomplete tasks to future dates. This is useful for tasks you couldn\'t '
            'complete today but still need to do.',
          ),
          _buildParagraph(
            'To migrate a task:\n'
            '1. Tap the task to open its menu\n'
            '2. Select "Migrate" (${_iconName(Icons.chevron_right)})\n'
            '3. Choose the new date\n'
            '4. The original task is marked as "migrated" and a new task is created on the selected date',
          ),
          _buildParagraph(
            'Migrated tasks appear grayed out with a ${_iconName(Icons.chevron_right)} icon. '
            'You can still view them, but they cannot be edited or completed.',
          ),
          const SizedBox(height: 16),
          _buildSubheading('Event Times'),
          _buildParagraph(
            'Events can have start and end times. When you enable Google Calendar sync in Settings, '
            'events with times will automatically sync to your Google Calendar.',
          ),
        ],
      ),
      _buildSection(
        'calendar',
        'Calendar View',
        [
          _buildParagraph(
            'The Calendar tab shows all your tasks and events organized by date. '
            'You can view upcoming items and see what\'s scheduled.',
          ),
          const SizedBox(height: 12),
          _buildSubheading('Calendar Actions'),
          _buildParagraph(
            'Tasks in the calendar view have the same actions as in the Tasks tab:',
          ),
          const SizedBox(height: 12),
          _buildIconExample(Icons.add, 'Complete Event', 
            'Mark event as done (grayed out)'),
          _buildIconExample(Icons.clear, 'Complete Task', 
            'Mark task as done (grayed out)'),
          _buildIconExample(Icons.edit, 'Edit', 
            'Modify task or event'),
          _buildIconExample(Icons.chevron_right, 'Migrate', 
            'Move to another date'),
          _buildIconExample(Icons.visibility, 'View Details', 
            'See full information'),
          _buildIconExample(Icons.delete, 'Delete', 
            'Remove task or event', color: Colors.red),
        ],
      ),
      _buildSection(
        'notes',
        'Notes',
        [
          _buildParagraph(
            'Notes are for capturing ideas, information, and reference material. '
            'Unlike tasks, notes don\'t have completion states or due dates.',
          ),
          const SizedBox(height: 12),
          _buildSubheading('Note Actions'),
          _buildIconExample(Icons.add, 'Add Note', 
            'Create a new note'),
          _buildIconExample(Icons.edit, 'Edit', 
            'Modify note content'),
          _buildIconExample(Icons.delete, 'Delete', 
            'Remove note permanently', color: Colors.red),
          const SizedBox(height: 12),
          _buildSubheading('Search Icon'),
          _buildIconExample(Icons.note, 'Note Result', 
            'Notes appear with this icon in search results'),
        ],
      ),
      _buildSection(
        'journal',
        'Journal Entries',
        [
          _buildParagraph(
            'Journal entries are daily reflections and notes. Each entry is tied to a specific date.',
          ),
          const SizedBox(height: 12),
          _buildSubheading('Journal Actions'),
          _buildIconExample(Icons.add, 'Add Entry', 
            'Create a new journal entry'),
          _buildIconExample(Icons.visibility, 'View', 
            'Read journal entry'),
          _buildIconExample(Icons.edit, 'Edit', 
            'Modify journal content'),
          _buildIconExample(Icons.delete, 'Delete', 
            'Remove entry permanently', color: Colors.red),
          const SizedBox(height: 12),
          _buildSubheading('Search Icon'),
          _buildIconExample(Icons.book, 'Journal Result', 
            'Journal entries appear with this icon in search results'),
        ],
      ),
      _buildSection(
        'search',
        'Search',
        [
          _buildParagraph(
            'Search lets you find tasks, notes, and journal entries across your entire workspace.',
          ),
          const SizedBox(height: 12),
          _buildSubheading('Search Icons'),
          _buildIconExample(Icons.search, 'Search Mode', 
            'Full text search across all items'),
          _buildIconExample(Icons.tag, 'Tag Search', 
            'Search by tags only'),
          _buildIconExample(Icons.clear, 'Clear', 
            'Clear search query'),
          _buildIconExample(Icons.search_off, 'No Results', 
            'No items match your search'),
          const SizedBox(height: 12),
          _buildSubheading('Result Type Icons'),
          _buildParagraph(
            'Search results show icons indicating the item type:',
          ),
          const SizedBox(height: 12),
          _buildIconExample(Icons.task_alt, 'Task Result', 
            'Task found in search'),
          _buildIconExample(Icons.note, 'Note Result', 
            'Note found in search'),
          _buildIconExample(Icons.book, 'Journal Result', 
            'Journal entry found in search'),
          _buildIconExample(Icons.event, 'Event', 
            'Event (task with time)'),
          _buildIconExample(Icons.circle, 'Regular Task', 
            'Standard task in results'),
        ],
      ),
      _buildSection(
        'tags',
        'Tags & Projects',
        [
          _buildParagraph(
            'Tags and projects help you organize and categorize your items.',
          ),
          const SizedBox(height: 12),
          _buildSubheading('Using Tags'),
          _buildParagraph(
            '• Tags start with # (e.g., #work, #home, #urgent)\n'
            '• Projects start with @ (e.g., @myproject, @website)\n'
            '• Add them anywhere in task descriptions, notes, or tags field\n'
            '• Multiple tags/projects are allowed',
          ),
          const SizedBox(height: 12),
          _buildSubheading('Icons in App'),
          _buildIconExample(Icons.tag, 'Tags (#)', 
            'Tag management and filtering - use #tag in text'),
          _buildIconExample(Icons.account_tree, 'Projects (@)', 
            'Project view and organization - use @project in text'),
          const SizedBox(height: 12),
          _buildSubheading('In Settings'),
          _buildParagraph(
            'You can view and manage all your tags and projects in the Settings screen.',
          ),
        ],
      ),
      _buildSection(
        'settings',
        'Settings',
        [
          _buildParagraph(
            'Configure sync, appearance, and app preferences.',
          ),
          const SizedBox(height: 12),
          _buildSubheading('Account & Auth'),
          _buildIconExample(Icons.person, 'User', 
            'Current user information'),
          _buildIconExample(Icons.login, 'Sign In', 
            'Authentication options'),
          _buildIconExample(Icons.error, 'Error', 
            'Authentication issues or warnings'),
          const SizedBox(height: 12),
          _buildSubheading('Sync Options'),
          _buildIconExample(Icons.phone_android, 'Device Sync', 
            'Local device storage only'),
          _buildIconExample(Icons.cloud, 'Cloud Sync', 
            'Firestore cloud synchronization'),
          _buildIconExample(Icons.cloud_done, 'Sync Status', 
            'Last successful sync time'),
          _buildIconExample(Icons.info_outline, 'Info', 
            'Sync information and help'),
          const SizedBox(height: 12),
          _buildSubheading('Google Calendar'),
          _buildIconExample(Icons.calendar_today, 'Calendar Sync', 
            'Enable/disable Google Calendar integration'),
          const SizedBox(height: 12),
          _buildSubheading('Appearance'),
          _buildIconExample(Icons.light_mode, 'Light Mode', 
            'Light theme'),
          _buildIconExample(Icons.dark_mode, 'Dark Mode', 
            'Dark theme'),
          _buildIconExample(Icons.auto_stories, 'Journal Style', 
            'Journal appearance preference'),
          _buildIconExample(Icons.menu_book, 'Alternative', 
            'Alternative appearance options'),
          _buildIconExample(Icons.article, 'Article View', 
            'Article-style layout'),
          const SizedBox(height: 12),
          _buildSubheading('Navigation'),
          _buildIconExample(Icons.help_outline, 'Help', 
            'This help documentation'),
          _buildIconExample(Icons.arrow_forward_ios, 'Navigate', 
            'Go to next screen'),
        ],
      ),
      _buildSection(
        'tips',
        'Tips & Best Practices',
        [
          _buildSubheading('Daily Workflow'),
          _buildBullet('Start each day by reviewing tasks in the Home tab'),
          _buildBullet('Use migration for tasks you couldn\'t complete'),
          _buildBullet('Add notes for context and additional details'),
          _buildBullet('Use journal entries for daily reflection'),
          const SizedBox(height: 12),
          _buildSubheading('Organization'),
          _buildBullet('Use consistent tag naming (#work, #personal, #urgent)'),
          _buildBullet('Group related tasks with @projects'),
          _buildBullet('Review your projects regularly to track progress'),
          _buildBullet('Use the Search tab to find items across dates'),
          const SizedBox(height: 12),
          _buildSubheading('Sync & Backup'),
          _buildBullet('Enable cloud sync to access items across devices'),
          _buildBullet('Use Google Calendar sync for events with times'),
          _buildBullet('On mobile, you can use local-only mode for privacy'),
          const SizedBox(height: 12),
          _buildSubheading('Events vs Tasks'),
          _buildBullet('Use tasks for action items (${_iconName(Icons.circle)})'),
          _buildBullet('Use events for scheduled activities (${_iconName(Icons.remove)})'),
          _buildBullet('Add start/end times to events for calendar integration'),
        ],
      ),
    ];
  }

  Widget _buildSection(String key, String title, List<Widget> children) {
    return Padding(
      key: _sectionKeys[key],
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSubheading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  Widget _buildIconExample(IconData icon, String label, String description, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _iconName(IconData icon) {
    if (icon == Icons.circle) return '●';
    if (icon == Icons.remove) return '−';
    if (icon == Icons.chevron_right) return '›';
    return '';
  }
}
