import 'package:voice_todo_app/models/voice_command.dart';

class CommandParserService {
  // Simple keywords to detect command types
  static final Map<CommandType, List<String>> _commandKeywords = {
    CommandType.addTask: ['add', 'create', 'new'],
    CommandType.completeTask: ['complete', 'finish', 'done', 'mark as completed', 'mark as done'],
    CommandType.deleteTask: ['delete', 'remove', 'erase'],
    CommandType.listTasks: ['list', 'show', 'display', 'what are my tasks'],
    CommandType.updateTask: ['update', 'change', 'edit', 'modify'],
  };

  // Keywords that could indicate a task title
  static final List<String> _titleIndicators = [
    'called',
    'named',
    'titled',
    'to do',
    'task',
    'about',
  ];

  // Keywords for date references
  static final Map<String, int> _relativeDays = {
    'today': 0,
    'tomorrow': 1,
    'day after tomorrow': 2,
    'next week': 7,
    'next month': 30,
  };

  // Days of the week
  static final Map<String, int> _daysOfWeek = {
    'monday': 1, 'mon': 1,
    'tuesday': 2, 'tue': 2,
    'wednesday': 3, 'wed': 3,
    'thursday': 4, 'thu': 4,
    'friday': 5, 'fri': 5,
    'saturday': 6, 'sat': 6,
    'sunday': 0, 'sun': 0,
  };

  Future<VoiceCommand> parseCommand(String text) async {
    // Normalize text for easier parsing
    final normalizedText = text.toLowerCase().trim();
    
    // Determine command type based on keywords
    final commandType = _detectCommandType(normalizedText);
    
    // Extract parameters based on command type
    final parameters = _extractParameters(normalizedText, commandType);
    
    return VoiceCommand(
      rawText: text,
      type: commandType,
      parameters: parameters,
    );
  }

  CommandType _detectCommandType(String text) {
    for (final entry in _commandKeywords.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          return entry.key;
        }
      }
    }
    
    return CommandType.unknown;
  }

  Map<String, dynamic> _extractParameters(String text, CommandType type) {
    final params = <String, dynamic>{};
    
    switch (type) {
      case CommandType.addTask:
        params['title'] = _extractTaskTitle(text);
        params['dueDate'] = _extractDueDate(text);
        break;
        
      case CommandType.completeTask:
      case CommandType.deleteTask:
      case CommandType.updateTask:
        params['taskIdentifier'] = _extractTaskIdentifier(text);
        
        if (type == CommandType.updateTask) {
          params['newTitle'] = _extractTaskTitle(text, withIndicator: 'to');
          params['dueDate'] = _extractDueDate(text);
        }
        break;
        
      case CommandType.listTasks:
        final dateFilter = _extractDateFilter(text);
        if (dateFilter != null) {
          params['dateFilter'] = dateFilter;
        }
        
        if (text.contains('completed') || text.contains('done')) {
          params['status'] = 'completed';
        } else if (text.contains('pending') || text.contains('not done')) {
          params['status'] = 'pending';
        }
        break;
        
      case CommandType.unknown:
      default:
        // No parameters for unknown commands
        break;
    }
    
    return params;
  }

  String _extractTaskTitle(String text, {String? withIndicator}) {
    String processedText = text;
    
    // If title should come after a specific indicator
    if (withIndicator != null) {
      final parts = text.split(' $withIndicator ');
      if (parts.length > 1) {
        processedText = parts[1];
      }
    }
    
    // Try to find title after indicators
    for (final indicator in _titleIndicators) {
      if (processedText.contains(indicator)) {
        final parts = processedText.split('$indicator ');
        if (parts.length > 1) {
          // Extract title until the next keyword or end of text
          String title = parts[1];
          
          // Remove due date references if any
          for (final dateRef in ['due', 'by', 'on', 'for', 'before']) {
            if (title.contains(' $dateRef ')) {
              title = title.split(' $dateRef ')[0];
            }
          }
          
          return title.trim();
        }
      }
    }
    
    // Fallback: Try to extract title after command keywords
    for (final entry in _commandKeywords.entries) {
      if (entry.key == CommandType.addTask) {
        for (final keyword in entry.value) {
          if (processedText.startsWith(keyword)) {
            String title = processedText.substring(keyword.length).trim();
            
            // Remove due date references if any
            for (final dateRef in ['due', 'by', 'on', 'for', 'before']) {
              if (title.contains(' $dateRef ')) {
                title = title.split(' $dateRef ')[0];
              }
            }
            
            return title;
          }
        }
      }
    }
    
    // If all else fails, just return the text without command keywords
    for (final keywords in _commandKeywords.values) {
      for (final keyword in keywords) {
        if (processedText.startsWith(keyword)) {
          return processedText.substring(keyword.length).trim();
        }
      }
    }
    
    return processedText;
  }

  DateTime? _extractDueDate(String text) {
    final now = DateTime.now();
    
    // Check for relative days
    for (final entry in _relativeDays.entries) {
      if (text.contains(entry.key)) {
        return DateTime(
          now.year,
          now.month,
          now.day + entry.value,
        );
      }
    }
    
    // Check for days of the week
    for (final entry in _daysOfWeek.entries) {
      if (text.contains(entry.key)) {
        int currentWeekday = now.weekday % 7;  // 0-6 (sun-sat)
        int targetWeekday = entry.value;
        int daysToAdd = (targetWeekday - currentWeekday) % 7;
        
        // If the day is already today, schedule for next week
        if (daysToAdd == 0) daysToAdd = 7;
        
        return DateTime(
          now.year,
          now.month,
          now.day + daysToAdd,
        );
      }
    }
    
    // Try to find date in format "month day" or "day month"
    final months = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december',
      'jan', 'feb', 'mar', 'apr', 'may', 'jun', 
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
    ];
    
    final monthsMap = {
      'january': 1, 'jan': 1, 
      'february': 2, 'feb': 2, 
      'march': 3, 'mar': 3, 
      'april': 4, 'apr': 4, 
      'may': 5, 
      'june': 6, 'jun': 6, 
      'july': 7, 'jul': 7, 
      'august': 8, 'aug': 8, 
      'september': 9, 'sep': 9, 
      'october': 10, 'oct': 10, 
      'november': 11, 'nov': 11, 
      'december': 12, 'dec': 12
    };
    
    for (final month in months) {
      if (text.contains(month)) {
        final regex = RegExp('$month\\s+(\\d+)', caseSensitive: false);
        final matches = regex.allMatches(text);
        
        if (matches.isNotEmpty) {
          final day = int.tryParse(matches.first.group(1) ?? '');
          if (day != null && day >= 1 && day <= 31) {
            final monthValue = monthsMap[month] ?? 1;
            int year = now.year;
            
            // If the date is in the past, assume it's for next year
            if (monthValue < now.month || (monthValue == now.month && day < now.day)) {
              year += 1;
            }
            
            return DateTime(year, monthValue, day);
          }
        }
      }
    }
    
    return null;
  }

  String _extractTaskIdentifier(String text) {
    // This is a simplistic approach - we assume the task identifier is the text after
    // the command keyword and before any other keyword
    
    String identifier = text;
    
    // Remove command keywords
    for (final keywords in _commandKeywords.values) {
      for (final keyword in keywords) {
        if (identifier.startsWith(keyword)) {
          identifier = identifier.substring(keyword.length).trim();
          break;
        }
      }
    }
    
    // Remove words like "task", "the task", etc.
    for (final prefix in ['the task', 'task', 'the item', 'item']) {
      if (identifier.startsWith(prefix)) {
        identifier = identifier.substring(prefix.length).trim();
      }
    }
    
    return identifier;
  }

  Map<String, dynamic>? _extractDateFilter(String text) {
    if (text.contains('today')) {
      return {'type': 'today'};
    }
    
    if (text.contains('tomorrow')) {
      return {'type': 'tomorrow'};
    }
    
    if (text.contains('this week')) {
      return {'type': 'this_week'};
    }
    
    if (text.contains('next week')) {
      return {'type': 'next_week'};
    }
    
    if (text.contains('overdue')) {
      return {'type': 'overdue'};
    }
    
    return null;
  }
} 