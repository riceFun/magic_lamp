import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../config/constants.dart';
import 'repositories/task_template_repository.dart';

/// 数据库帮助类 - 单例模式
class DatabaseHelper {
  // 私有构造函数
  DatabaseHelper._();

  // 单例实例
  static final DatabaseHelper instance = DatabaseHelper._();

  // 数据库实例
  static Database? _database;

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 1. 用户表
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        avatar TEXT,
        role TEXT NOT NULL DEFAULT 'child',
        total_points INTEGER NOT NULL DEFAULT 0,
        password TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. 任务表
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        points INTEGER NOT NULL,
        type TEXT NOT NULL,
        priority TEXT NOT NULL DEFAULT 'normal',
        start_date TEXT,
        end_date TEXT,
        repeat_type TEXT NOT NULL DEFAULT 'none',
        repeat_config TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        project_id INTEGER,
        tags TEXT,
        replaced_by_task_id INTEGER,
        icon TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (project_id) REFERENCES projects (id)
      )
    ''');

    // 3. 任务完成记录表
    await db.execute('''
      CREATE TABLE task_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        points_earned INTEGER NOT NULL,
        bonus_points INTEGER NOT NULL DEFAULT 0,
        streak_count INTEGER NOT NULL DEFAULT 0,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (task_id) REFERENCES tasks (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // 4. 奖励商品表
    await db.execute('''
      CREATE TABLE rewards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        points INTEGER NOT NULL,
        min_points INTEGER,
        max_points INTEGER,
        word_code TEXT NOT NULL,
        icon TEXT,
        image_url TEXT,
        category TEXT NOT NULL,
        type TEXT,
        stock INTEGER NOT NULL DEFAULT -1,
        status TEXT NOT NULL DEFAULT 'active',
        exchange_frequency TEXT,
        max_exchange_count INTEGER,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // 5. 兑换记录表
    await db.execute('''
      CREATE TABLE exchanges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        reward_id INTEGER NOT NULL,
        reward_name TEXT NOT NULL,
        points_spent INTEGER NOT NULL,
        word_code TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        exchange_at TEXT NOT NULL,
        completed_at TEXT,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (reward_id) REFERENCES rewards (id)
      )
    ''');

    // 6. 积分记录表
    await db.execute('''
      CREATE TABLE point_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        points INTEGER NOT NULL,
        balance INTEGER NOT NULL,
        source_type TEXT NOT NULL,
        source_id INTEGER,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // 7. 预支记录表
    await db.execute('''
      CREATE TABLE advances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        interest_rate REAL NOT NULL,
        interest_amount INTEGER NOT NULL,
        total_amount INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        advance_at TEXT NOT NULL,
        due_date TEXT NOT NULL,
        repaid_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // 8. 项目表
    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        color TEXT NOT NULL,
        icon TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 9. 标签表
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 10. 任务模板表
    await db.execute('''
      CREATE TABLE task_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        points INTEGER NOT NULL,
        type TEXT NOT NULL,
        priority TEXT DEFAULT 'medium',
        category TEXT,
        icon TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 11. 目标表
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        target_points INTEGER NOT NULL,
        current_points INTEGER NOT NULL DEFAULT 0,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // 12. 用户词汇库表
    await db.execute('''
      CREATE TABLE user_words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        word_code TEXT NOT NULL,
        word_type TEXT NOT NULL,
        learned_at TEXT NOT NULL,
        source_type TEXT NOT NULL,
        source_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // 13. 设置表
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 14. 统计数据表
    await db.execute('''
      CREATE TABLE statistics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        points_earned INTEGER NOT NULL DEFAULT 0,
        points_spent INTEGER NOT NULL DEFAULT 0,
        tasks_completed INTEGER NOT NULL DEFAULT 0,
        exchanges_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        UNIQUE(user_id, date)
      )
    ''');

    // 15. 备份记录表
    await db.execute('''
      CREATE TABLE backups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_path TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        backup_at TEXT NOT NULL,
        note TEXT
      )
    ''');

    // 16. 故事学习记录表
    await db.execute('''
      CREATE TABLE story_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        story_id INTEGER NOT NULL,
        learned_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        UNIQUE(user_id, story_id, learned_at)
      )
    ''');

    // 17. 老虎机游戏记录表
    await db.execute('''
      CREATE TABLE slot_game_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        result1 TEXT NOT NULL,
        result2 TEXT NOT NULL,
        result3 TEXT NOT NULL,
        reward INTEGER NOT NULL DEFAULT 0,
        prize_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // 18. 惩罚项目表
    await db.execute('''
      CREATE TABLE penalties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        points INTEGER NOT NULL,
        icon TEXT,
        category TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // 19. 惩罚记录表
    await db.execute('''
      CREATE TABLE penalty_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        penalty_id INTEGER NOT NULL,
        penalty_name TEXT NOT NULL,
        points_deducted INTEGER NOT NULL,
        reason TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (penalty_id) REFERENCES penalties (id)
      )
    ''');

    // 创建索引以提高查询性能
    await _createIndexes(db);

    // 插入初始数据
    await _insertInitialData(db);
  }

  /// 创建索引
  Future<void> _createIndexes(Database db) async {
    // 任务表索引
    await db.execute('CREATE INDEX idx_tasks_user_id ON tasks(user_id)');
    await db.execute('CREATE INDEX idx_tasks_status ON tasks(status)');
    await db.execute('CREATE INDEX idx_tasks_type ON tasks(type)');

    // 任务记录表索引
    await db.execute('CREATE INDEX idx_task_records_task_id ON task_records(task_id)');
    await db.execute('CREATE INDEX idx_task_records_user_id ON task_records(user_id)');
    await db.execute('CREATE INDEX idx_task_records_completed_at ON task_records(completed_at)');

    // 奖励表索引
    await db.execute('CREATE INDEX idx_rewards_user_id ON rewards(user_id)');
    await db.execute('CREATE INDEX idx_rewards_status ON rewards(status)');
    await db.execute('CREATE INDEX idx_rewards_category ON rewards(category)');

    // 兑换记录表索引
    await db.execute('CREATE INDEX idx_exchanges_user_id ON exchanges(user_id)');
    await db.execute('CREATE INDEX idx_exchanges_exchange_at ON exchanges(exchange_at)');

    // 积分记录表索引
    await db.execute('CREATE INDEX idx_point_records_user_id ON point_records(user_id)');
    await db.execute('CREATE INDEX idx_point_records_created_at ON point_records(created_at)');

    // 用户词汇库索引
    await db.execute('CREATE INDEX idx_user_words_user_id ON user_words(user_id)');
    await db.execute('CREATE INDEX idx_user_words_word_type ON user_words(word_type)');

    // 任务模板表索引
    await db.execute('CREATE INDEX idx_task_templates_type ON task_templates(type)');
    await db.execute('CREATE INDEX idx_task_templates_category ON task_templates(category)');

    // 统计数据表索引
    await db.execute('CREATE INDEX idx_statistics_user_id ON statistics(user_id)');
    await db.execute('CREATE INDEX idx_statistics_date ON statistics(date)');

    // 故事学习记录表索引
    await db.execute('CREATE INDEX idx_story_records_user_id ON story_records(user_id)');
    await db.execute('CREATE INDEX idx_story_records_learned_at ON story_records(learned_at)');

    // 老虎机游戏记录表索引
    await db.execute('CREATE INDEX idx_slot_game_records_user_id ON slot_game_records(user_id)');
    await db.execute('CREATE INDEX idx_slot_game_records_created_at ON slot_game_records(created_at)');

    // 惩罚项目表索引
    await db.execute('CREATE INDEX idx_penalties_user_id ON penalties(user_id)');
    await db.execute('CREATE INDEX idx_penalties_status ON penalties(status)');
    await db.execute('CREATE INDEX idx_penalties_category ON penalties(category)');

    // 惩罚记录表索引
    await db.execute('CREATE INDEX idx_penalty_records_user_id ON penalty_records(user_id)');
    await db.execute('CREATE INDEX idx_penalty_records_created_at ON penalty_records(created_at)');
  }

  /// 插入初始数据
  Future<void> _insertInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // // 插入默认管理员用户
    // await db.insert('users', {
    //   'name': '爸爸',
    //   'avatar': 'person',
    //   'role': 'admin',
    //   'total_points': 0,
    //   'created_at': now,
    //   'updated_at': now,
    // });
    //
    // // 插入两个示例子用户
    // await db.insert('users', {
    //   'name': '小明',
    //   'avatar': 'face',
    //   'role': 'child',
    //   'total_points': 350,
    //   'created_at': now,
    //   'updated_at': now,
    // });
    //
    // await db.insert('users', {
    //   'name': '小红',
    //   'avatar': 'face_2',
    //   'role': 'child',
    //   'total_points': 420,
    //   'created_at': now,
    //   'updated_at': now,
    // });
    //
    // // 插入默认项目
    // await db.insert('projects', {
    //   'name': '学习',
    //   'description': '学习相关任务',
    //   'color': '#42A5F5',
    //   'icon': 'school',
    //   'status': 'active',
    //   'created_at': now,
    //   'updated_at': now,
    // });
    //
    // await db.insert('projects', {
    //   'name': '家务',
    //   'description': '家务相关任务',
    //   'color': '#66BB6A',
    //   'icon': 'home',
    //   'status': 'active',
    //   'created_at': now,
    //   'updated_at': now,
    // });

    // 插入示例惩罚项目（使用第一个用户的ID）
    await db.insert('penalties', {
      'user_id': 1,
      'name': '说谎',
      'description': '不诚实，说谎话',
      'points': 100,
      'icon': '🤥',
      'category': 'behavior',
      'status': 'active',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('penalties', {
      'user_id': 1,
      'name': '说脏话',
      'description': '使用不文明语言',
      'points': 100,
      'icon': '🤬',
      'category': 'language',
      'status': 'active',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('penalties', {
      'user_id': 1,
      'name': '不洗手',
      'description': '饭前便后不洗手',
      'points': 30,
      'icon': '🧼',
      'category': 'hygiene',
      'status': 'active',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('penalties', {
      'user_id': 1,
      'name': '不收拾玩具',
      'description': '玩完玩具不整理',
      'points': 50,
      'icon': '🧸',
      'category': 'behavior',
      'status': 'active',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('penalties', {
      'user_id': 1,
      'name': '作业马虎',
      'description': '作业不认真完成',
      'points': 80,
      'icon': '✏️',
      'category': 'study',
      'status': 'active',
      'created_at': now,
      'updated_at': now,
    });
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 从版本1升级到版本2：添加任务模板表
    if (oldVersion < 2) {
      // 创建任务模板表
      await db.execute('''
        CREATE TABLE task_templates (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          points INTEGER NOT NULL,
          type TEXT NOT NULL,
          priority TEXT DEFAULT 'medium',
          category TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      // 创建索引
      await db.execute('CREATE INDEX idx_task_templates_type ON task_templates(type)');
      await db.execute('CREATE INDEX idx_task_templates_category ON task_templates(category)');

      // // 插入初始模板数据
      // await TaskTemplateRepository.insertInitialTemplates(db);
    }

    // 从版本2升级到版本3：添加任务替换关系字段
    if (oldVersion < 3) {
      // 为tasks表添加replaced_by_task_id字段
      await db.execute('''
        ALTER TABLE tasks ADD COLUMN replaced_by_task_id INTEGER
      ''');

      print('Database upgraded to version 3: added replaced_by_task_id column to tasks table');
    }

    // 从版本3升级到版本4：添加任务图标字段
    if (oldVersion < 4) {
      // 为tasks表添加icon字段
      await db.execute('''
        ALTER TABLE tasks ADD COLUMN icon TEXT
      ''');

      print('Database upgraded to version 4: added icon column to tasks table');
    }

    // 从版本4升级到版本5：添加故事学习记录表
    if (oldVersion < 5) {
      // 创建故事学习记录表
      await db.execute('''
        CREATE TABLE story_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          story_id INTEGER NOT NULL,
          learned_at TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id),
          UNIQUE(user_id, story_id, learned_at)
        )
      ''');

      // 创建索引
      await db.execute('CREATE INDEX idx_story_records_user_id ON story_records(user_id)');
      await db.execute('CREATE INDEX idx_story_records_learned_at ON story_records(learned_at)');

      print('Database upgraded to version 5: added story_records table');
    }

    // 从版本5升级到版本6：添加积分大富翁游戏记录表
    if (oldVersion < 6) {
      // 创建老虎机游戏记录表
      await db.execute('''
        CREATE TABLE slot_game_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          result1 TEXT NOT NULL,
          result2 TEXT NOT NULL,
          result3 TEXT NOT NULL,
          reward INTEGER NOT NULL DEFAULT 0,
          prize_type TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');

      // 创建索引
      await db.execute('CREATE INDEX idx_slot_game_records_user_id ON slot_game_records(user_id)');
      await db.execute('CREATE INDEX idx_slot_game_records_created_at ON slot_game_records(created_at)');

      print('Database upgraded to version 6: added slot_game_records table');
    }

    // 从版本6升级到版本7：为rewards表添加新字段
    if (oldVersion < 7) {
      // 添加icon字段
      await db.execute('''
        ALTER TABLE rewards ADD COLUMN icon TEXT
      ''');

      // 添加exchange_frequency字段
      await db.execute('''
        ALTER TABLE rewards ADD COLUMN exchange_frequency TEXT
      ''');

      // 添加max_exchange_count字段
      await db.execute('''
        ALTER TABLE rewards ADD COLUMN max_exchange_count INTEGER
      ''');

      print('Database upgraded to version 7: added icon, exchange_frequency, max_exchange_count columns to rewards table');
    }

    // 从版本7升级到版本8：重构rewards表，移除不需要的字段，添加积分范围字段
    if (oldVersion < 8) {
      // 创建新的rewards表
      await db.execute('''
        CREATE TABLE rewards_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          points INTEGER NOT NULL,
          min_points INTEGER,
          max_points INTEGER,
          word_code TEXT NOT NULL,
          image_url TEXT,
          category TEXT NOT NULL,
          stock INTEGER NOT NULL DEFAULT -1,
          status TEXT NOT NULL DEFAULT 'active',
          exchange_frequency TEXT,
          max_exchange_count INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // 复制数据到新表（只复制需要的字段）
      await db.execute('''
        INSERT INTO rewards_new (
          id, name, description, points, word_code, image_url,
          category, stock, status, exchange_frequency, max_exchange_count,
          created_at, updated_at
        )
        SELECT
          id, name, description, points, word_code, image_url,
          category, stock, status, exchange_frequency, max_exchange_count,
          created_at, updated_at
        FROM rewards
      ''');

      // 删除旧表
      await db.execute('DROP TABLE rewards');

      // 重命名新表
      await db.execute('ALTER TABLE rewards_new RENAME TO rewards');

      // 重建索引
      await db.execute('CREATE INDEX idx_rewards_status ON rewards(status)');
      await db.execute('CREATE INDEX idx_rewards_category ON rewards(category)');

      print('Database upgraded to version 8: restructured rewards table, removed unused columns, added points range support');
    }

    // 从版本8升级到版本9：添加icon、type、note字段
    if (oldVersion < 9) {
      // 添加 icon 字段
      await db.execute('''
        ALTER TABLE rewards ADD COLUMN icon TEXT
      ''');

      // 添加 type 字段
      await db.execute('''
        ALTER TABLE rewards ADD COLUMN type TEXT
      ''');

      // 添加 note 字段
      await db.execute('''
        ALTER TABLE rewards ADD COLUMN note TEXT
      ''');

      print('Database upgraded to version 9: added icon, type, note columns to rewards table');
    }

    // 从版本9升级到版本10：添加惩罚功能表
    if (oldVersion < 10) {
      // 创建惩罚项目表
      await db.execute('''
        CREATE TABLE penalties (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          points INTEGER NOT NULL,
          icon TEXT,
          category TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'active',
          note TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // 创建惩罚记录表
      await db.execute('''
        CREATE TABLE penalty_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          penalty_id INTEGER NOT NULL,
          penalty_name TEXT NOT NULL,
          points_deducted INTEGER NOT NULL,
          reason TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id),
          FOREIGN KEY (penalty_id) REFERENCES penalties (id)
        )
      ''');

      // 创建索引
      await db.execute('CREATE INDEX idx_penalties_status ON penalties(status)');
      await db.execute('CREATE INDEX idx_penalties_category ON penalties(category)');
      await db.execute('CREATE INDEX idx_penalty_records_user_id ON penalty_records(user_id)');
      await db.execute('CREATE INDEX idx_penalty_records_created_at ON penalty_records(created_at)');

      print('Database upgraded to version 10: added penalties and penalty_records tables');
    }

    // 从版本10升级到版本11：为rewards和penalties表添加user_id字段
    if (oldVersion < 11) {
      // 获取第一个用户的ID作为默认值
      final firstUserResult = await db.rawQuery('SELECT id FROM users ORDER BY id ASC LIMIT 1');
      final defaultUserId = firstUserResult.isNotEmpty ? firstUserResult.first['id'] as int : 1;

      // 为rewards表添加user_id字段
      await db.execute('''
        ALTER TABLE rewards ADD COLUMN user_id INTEGER NOT NULL DEFAULT $defaultUserId
      ''');

      // 为penalties表添加user_id字段
      await db.execute('''
        ALTER TABLE penalties ADD COLUMN user_id INTEGER NOT NULL DEFAULT $defaultUserId
      ''');

      // 创建索引
      await db.execute('CREATE INDEX idx_rewards_user_id ON rewards(user_id)');
      await db.execute('CREATE INDEX idx_penalties_user_id ON penalties(user_id)');

      print('Database upgraded to version 11: added user_id column to rewards and penalties tables');
    }

    // 从版本11升级到版本12：检查并修复缺失的表
    if (oldVersion < 12) {
      await _checkAndCreateMissingTables(db);
      print('Database upgraded to version 12: checked and created missing tables');
    }

    // 从版本12升级到版本13：检查并添加tasks表缺失的列
    if (oldVersion < 13) {
      await _checkAndAddMissingTasksColumns(db);
      print('Database upgraded to version 13: checked and added missing columns to tasks table');
    }

    // 从版本13升级到版本14：确保story_records表存在
    if (oldVersion < 14) {
      await _checkAndCreateMissingTables(db);
      print('Database upgraded to version 14: ensured story_records table exists');
    }

    // 从版本14升级到版本15：为task_templates表添加icon字段
    if (oldVersion < 15) {
      await _addIconColumnToTaskTemplates(db);
      print('Database upgraded to version 15: added icon column to task_templates table');
    }
  }

  /// 检查并创建缺失的表
  Future<void> _checkAndCreateMissingTables(Database db) async {
    // 检查 story_records 表是否存在
    final storyRecordsCheck = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='story_records'"
    );

    if (storyRecordsCheck.isEmpty) {
      print('Creating missing story_records table...');
      await db.execute('''
        CREATE TABLE story_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          story_id INTEGER NOT NULL,
          learned_at TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id),
          UNIQUE(user_id, story_id, learned_at)
        )
      ''');
      await db.execute('CREATE INDEX idx_story_records_user_id ON story_records(user_id)');
      await db.execute('CREATE INDEX idx_story_records_learned_at ON story_records(learned_at)');
      print('story_records table created');
    }

    // 检查 slot_game_records 表是否存在
    final slotGameCheck = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='slot_game_records'"
    );

    if (slotGameCheck.isEmpty) {
      print('Creating missing slot_game_records table...');
      await db.execute('''
        CREATE TABLE slot_game_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          result1 TEXT NOT NULL,
          result2 TEXT NOT NULL,
          result3 TEXT NOT NULL,
          reward INTEGER NOT NULL DEFAULT 0,
          prize_type TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');
      await db.execute('CREATE INDEX idx_slot_game_records_user_id ON slot_game_records(user_id)');
      await db.execute('CREATE INDEX idx_slot_game_records_created_at ON slot_game_records(created_at)');
      print('slot_game_records table created');
    }
  }

  /// 检查并添加tasks表缺失的列
  Future<void> _checkAndAddMissingTasksColumns(Database db) async {
    // 获取tasks表的列信息
    final columns = await db.rawQuery('PRAGMA table_info(tasks)');
    final columnNames = columns.map((col) => col['name'] as String).toList();

    // 检查并添加 replaced_by_task_id 列
    if (!columnNames.contains('replaced_by_task_id')) {
      print('Adding missing replaced_by_task_id column to tasks table...');
      await db.execute('ALTER TABLE tasks ADD COLUMN replaced_by_task_id INTEGER');
      print('replaced_by_task_id column added');
    }

    // 检查并添加 icon 列
    if (!columnNames.contains('icon')) {
      print('Adding missing icon column to tasks table...');
      await db.execute('ALTER TABLE tasks ADD COLUMN icon TEXT');
      print('icon column added');
    }
  }

  /// 为task_templates表添加icon列
  Future<void> _addIconColumnToTaskTemplates(Database db) async {
    try {
      // 获取task_templates表的列信息
      final columns = await db.rawQuery('PRAGMA table_info(task_templates)');
      final columnNames = columns.map((col) => col['name'] as String).toList();

      // 检查icon列是否已存在
      if (!columnNames.contains('icon')) {
        print('Adding icon column to task_templates table...');
        await db.execute('ALTER TABLE task_templates ADD COLUMN icon TEXT');
        print('icon column added to task_templates table');
      } else {
        print('icon column already exists in task_templates table');
      }
    } catch (e) {
      print('Error adding icon column to task_templates table: $e');
    }
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// 清空数据库（谨慎使用）
  Future<void> clearDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, AppConstants.databaseName);
    await deleteDatabase(path);
    _database = null;
  }
}
