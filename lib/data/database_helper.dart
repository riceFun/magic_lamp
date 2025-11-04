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

    // 16. 老虎机游戏记录表
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

    // 老虎机游戏记录表索引
    await db.execute('CREATE INDEX idx_slot_game_records_user_id ON slot_game_records(user_id)');
    await db.execute('CREATE INDEX idx_slot_game_records_created_at ON slot_game_records(created_at)');
  }

  /// 插入初始数据
  Future<void> _insertInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // 插入默认管理员用户
    await db.insert('users', {
      'name': '爸爸',
      'avatar': 'person',
      'role': 'admin',
      'total_points': 0,
      'created_at': now,
      'updated_at': now,
    });

    // 插入两个示例子用户
    await db.insert('users', {
      'name': '小明',
      'avatar': 'face',
      'role': 'child',
      'total_points': 350,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('users', {
      'name': '小红',
      'avatar': 'face_2',
      'role': 'child',
      'total_points': 420,
      'created_at': now,
      'updated_at': now,
    });

    // 插入一些示例奖励商品
    final rewards = [
      {
        'name': '看电影',
        'description': '去电影院看一场喜欢的电影',
        'points': 500,
        'word_code': '一帆风顺',
        'category': 'entertainment',
      },
      {
        'name': '买玩具',
        'description': '购买一个心仪的玩具',
        'points': 1000,
        'word_code': '心想事成',
        'category': 'toy',
      },
      {
        'name': '游乐园',
        'description': '去游乐园玩一天',
        'points': 1500,
        'word_code': 'Achievement',
        'category': 'entertainment',
      },
      {
        'name': '买书',
        'description': '购买喜欢的课外书',
        'points': 300,
        'word_code': '书香门第',
        'category': 'book',
      },
      {
        'name': '延长游戏时间',
        'description': '额外30分钟游戏时间',
        'points': 200,
        'word_code': 'Freedom',
        'category': 'privilege',
      },
    ];

    for (final reward in rewards) {
      await db.insert('rewards', {
        ...reward,
        'status': 'active',
        'stock': -1,
        'created_at': now,
        'updated_at': now,
      });
    }

    // 插入默认项目
    await db.insert('projects', {
      'name': '学习',
      'description': '学习相关任务',
      'color': '#42A5F5',
      'icon': 'school',
      'status': 'active',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('projects', {
      'name': '家务',
      'description': '家务相关任务',
      'color': '#66BB6A',
      'icon': 'home',
      'status': 'active',
      'created_at': now,
      'updated_at': now,
    });

    // 插入任务模板
    await TaskTemplateRepository.insertInitialTemplates(db);
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

      // 插入初始模板数据
      await TaskTemplateRepository.insertInitialTemplates(db);
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
