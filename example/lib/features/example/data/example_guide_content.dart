import 'package:flutter/material.dart';

/// Data model for an educational section in the Hosteday guide.
class GuideSection {
  final String id;
  final String categoryEn;
  final String categoryAr;
  final String titleEn;
  final String titleAr;
  final String descriptionEn;
  final String descriptionAr;
  final String code;
  final String language;
  final IconData icon;

  const GuideSection({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.code,
    this.categoryEn = 'SDK Guide',
    this.categoryAr = 'دليل الحزمة',
    this.language = 'dart',
    this.icon = Icons.code_rounded,
  });
}

/// Comprehensive bilingual content for using `hosteday_flutter` with the Hosteday platform.
abstract final class ExampleGuideContent {
  const ExampleGuideContent._();

  static const List<GuideSection> starterTemplateSections = <GuideSection>[
    GuideSection(
      id: 'app_blueprint',
      categoryEn: 'Boilerplate',
      categoryAr: 'قالب التطبيقات',
      icon: Icons.rocket_launch_rounded,
      titleEn: '1. Modular Architecture with GetX',
      titleAr: '١. المعمارية الموديلية باستخدام GetX',
      descriptionEn:
          'How this starter project is structured with GetX for instant duplication and rapid child app development on app.hosteday.com.',
      descriptionAr:
          'الهيكل الموديلي المعتمد على GetX لإتاحة الاستنساخ الفوري والتطوير السريع للتطبيقات الفرعية على app.hosteday.com.',
      code: '''/* Recommended Clean Project Structure with GetX:
lib/
├── core/
│   ├── bindings/     -> Global dependency injection (InitialBinding)
│   ├── bootstrap/    -> Hosteday initialization & SDK options
│   ├── config/       -> HosteDay configuration integration
│   ├── errors/       -> HostedayException formatting & alerts
│   ├── routes/       -> Named routing (AppRoutes & AppPages)
│   └── theme/        -> Multi-theme engine (6 Presets & ThemeController)
├── features/
│   ├── auth/         -> AuthController, Sign-In, Register, ForgotPassword
│   ├── home/         -> HomeController, adaptive navigation rail/bottom bar
│   ├── profile/      -> User profile, avatar upload, account deletion
│   ├── realtime/     -> Live WebSocket events & streaming
│   ├── notifications/-> Push tokens & notification triggers
│   └── [new_feature]/-> Orders, Products, Bookings, Chat, etc.
└── shared/
    └── widgets/      -> Reusable buttons, inputs, feedback boxes
*/''',
    ),
    GuideSection(
      id: 'getx_add_feature',
      categoryEn: 'Boilerplate',
      categoryAr: 'قالب التطبيقات',
      icon: Icons.add_circle_outline_rounded,
      titleEn: '2. Adding a New Feature in 3 Steps',
      titleAr: '٢. إضافة ميزة جديدة للتطبيق في ٣ خطوات',
      descriptionEn:
          'Follow this standard 3-step pattern to introduce any new module (e.g. Products/Orders) with high speed and zero boilerplate.',
      descriptionAr:
          'اتبع هذا النمط القياسي المكون من ٣ خطوات لإضافة أي ميزة جديدة (مثل المنتجات أو الطلبات) بأعلى سرعة وأقل كود.',
      code: '''// Step 1: Create your reactive Controller:
// lib/features/products/controllers/products_controller.dart
class ProductsController extends GetxController {
  final RxList<Map<String, dynamic>> products = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  Future<void> fetchProducts() async {
    isLoading.value = true;
    try {
      final page = await Hosteday.client.index('/products');
      products.assignAll(page.items);
    } finally {
      isLoading.value = false;
    }
  }
}

// Step 2: Create its lazy Binding:
// lib/features/products/bindings/products_binding.dart
class ProductsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProductsController());
  }
}

// Step 3: Register in AppRoutes & AppPages, then navigate:
// Get.toNamed('/products');''',
    ),
    GuideSection(
      id: 'multi_theme_guide',
      categoryEn: 'Boilerplate',
      categoryAr: 'قالب التطبيقات',
      icon: Icons.palette_outlined,
      titleEn: '3. Multi-Theme Engine (3 Light & 3 Dark)',
      titleAr: '٣. محرك الثيمات المتعددة (٣ فاتحة و ٣ داكنة)',
      descriptionEn:
          'Built-in ThemeController with 6 curated color schemes. Easily switchable from the side menu and auto-persisted in local storage.',
      descriptionAr:
          'محرك ثيمات متكامل يحتوي على 6 ألوان متناسقة (3 فاتحة و 3 داكنة). قابل للتبديل الفوري من القائمة الجانبية ومحفوظ تلقائياً.',
      code: '''// Switch theme instantly from anywhere:
final themeController = Get.find<ThemeController>();

// Change to any of the 6 color presets:
// Light: oceanBlueLight, emeraldMintLight, sunsetAmberLight
// Dark:  cyberMidnightDark, royalObsidianDark, amethystVioletDark
themeController.changeTheme(AppThemePreset.royalObsidianDark);

// Or open the interactive picker sheet:
ThemePickerSheet.show(context);''',
    ),
  ];

  static const List<GuideSection> bootstrapSections = <GuideSection>[
    GuideSection(
      id: 'init_app',
      categoryEn: 'Setup & Config',
      categoryAr: 'التهيئة والإعداد',
      icon: Icons.settings_rounded,
      titleEn: '1. Initialize Hosteday in main()',
      titleAr: '١. تهيئة مكتبة Hosteday في دالة main()',
      descriptionEn:
          'Initialize the SDK before calling runApp. Provide your project domain from app.hosteday.com, API key, and optional realtime & notification settings.',
      descriptionAr:
          'قم بتهيئة الـ SDK قبل استدعاء runApp. مرر نطاق مشروعك من app.hosteday.com، ومفتاح الـ API، وإعدادات الوقت الفعلي والإشعارات.',
      code: '''void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hosteday.initializeApp(
    options: {
      HostedayOptionKeys.projectDomain: 'your-project.hosteday.com',
      HostedayOptionKeys.projectApiKey: 'your_optional_api_key',
      HostedayOptionKeys.realtimeAppKey: 'YOUR_REALTIME_KEY',
      HostedayOptionKeys.realtimeHost: 'ws3.hosteday.com',
      HostedayOptionKeys.notificationsEnabled: true,
      HostedayOptionKeys.defaultNotificationTopic: 'general_announcements',
    },
    authStorage: HostedaySharedPreferencesAuthStorage(),
  );

  runApp(const MyApp());
}''',
    ),
    GuideSection(
      id: 'compile_env',
      categoryEn: 'Setup & Config',
      categoryAr: 'التهيئة والإعداد',
      icon: Icons.tune_rounded,
      titleEn: '2. Official Control Plane CLI Setup',
      titleAr: '٢. التهيئة التلقائية عبر CLI المنصة الرسمي',
      descriptionEn:
          'Bootstrap and configure your application with a single command from dash.hosteday.com, generating lib/hosteday_config.dart automatically.',
      descriptionAr:
          'تهيئة وإعداد مشروعك بالكامل بأمر واحد رسمي من منصة HosteDay، يولد ملف lib/hosteday_config.dart تلقائياً دون أي إعداد يدوي.',
      code: '''// Run in terminal:
curl -fsSL https://dash.hosteday.com/cli/setup.sh | bash -s -- --project=<slug> --token='<token>' --clone

// Auto-generated lib/hosteday_config.dart:
import 'hosteday_config.dart';
import 'core/config/hosteday_config_adapter.dart';

await Hosteday.initializeApp(
  options: HosteDayConfigAdapter.toOptions(),
  authStorage: HostedaySharedPreferencesAuthStorage(),
);''',
    ),
  ];

  static const List<GuideSection> authSections = <GuideSection>[
    GuideSection(
      id: 'auth_gate',
      categoryEn: 'Authentication',
      categoryAr: 'المصادقة والمستخدمين',
      icon: Icons.lock_open_rounded,
      titleEn: '1. Reactive Auth Gate Pattern',
      titleAr: '١. نمط بوابة المصادقة التفاعلية (Auth Gate)',
      descriptionEn:
          'Use authStateChanges() Stream to instantly switch between the SignIn screen and the Main Shell whenever login or logout occurs.',
      descriptionAr:
          'استخدم دفق authStateChanges() للتبديل التلقائي بين شاشة تسجيل الدخول والشاشة الرئيسية بمجرد تسجيل الدخول أو الخروج.',
      code: '''class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HostedayUser?>(
      stream: Hosteday.auth.authStateChanges(),
      initialData: Hosteday.auth.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const SignInPage();
        }
        return HomeShell(user: user);
      },
    );
  }
}''',
    ),
    GuideSection(
      id: 'sign_in_up',
      categoryEn: 'Authentication',
      categoryAr: 'المصادقة والمستخدمين',
      icon: Icons.person_add_rounded,
      titleEn: '2. Sign In & Registration',
      titleAr: '٢. تسجيل الدخول وإنشاء حساب جديد',
      descriptionEn:
          'Authenticate with email & password. Additional user fields (e.g. name, phone) can be passed inside additionalData on sign up.',
      descriptionAr:
          'المصادقة باستخدام البريد وكلمة المرور. يمكنك تمرير بيانات إضافية (مثل الاسم أو الهاتف) عبر additionalData.',
      code: '''// Sign in existing user:
final credential = await Hosteday.auth.signInWithEmailAndPassword(
  email: 'user@example.com',
  password: 'Password123',
);
print('Welcome \${credential.user.displayName}');

// Register new user:
final newCredential = await Hosteday.auth.createUserWithEmailAndPassword(
  email: 'newuser@example.com',
  password: 'Password123',
  additionalData: {'name': 'Mustafa Ali'},
);''',
    ),
    GuideSection(
      id: 'profile_avatar',
      categoryEn: 'Authentication',
      categoryAr: 'المصادقة والمستخدمين',
      icon: Icons.badge_rounded,
      titleEn: '3. Profile & Avatar Management',
      titleAr: '٣. إدارة الملف الشخصي والصورة الشخصية',
      descriptionEn:
          'Update profile fields and upload avatar images directly as bytes to Hosteday user storage disk.',
      descriptionAr:
          'تحديث بيانات المستخدم ورفع الصورة الشخصية كـ Bytes مباشرة إلى مساحة تخزين المستخدمين في المنصة.',
      code: '''// Update display name:
await Hosteday.auth.updateProfile(name: 'New Name');

// Upload avatar bytes (e.g. from image_picker):
final bytes = await pickedFile.readAsBytes();
await Hosteday.auth.updateAvatar(bytes: bytes, extension: 'png');

// Reload user profile from server:
final refreshedUser = await Hosteday.auth.reload();''',
    ),
  ];

  static const List<GuideSection> apiSections = <GuideSection>[
    GuideSection(
      id: 'api_index',
      categoryEn: 'Database & CRUD',
      categoryAr: 'قواعد البيانات والـ API',
      icon: Icons.table_rows_rounded,
      titleEn: '1. List All Records (index)',
      titleAr: '١. جلب قائمة السجلات (index)',
      descriptionEn:
          'Call collection endpoints using client.index() or raw get(). Returns a typed HostedayPage containing items and server pagination metadata.',
      descriptionAr:
          'استدعاء قائمة السجلات باستخدام client.index() المباشرة أو get(). تُرجع كائن HostedayPage يحتوي على قائمة السجلات مع بيانات الترقيم من الخادم.',
      code: '''// Native 2.3.0 Typed Index helper:
// GET /api/products?page=1&search=laptop
final HostedayPage page = await Hosteday.client.index(
  '/products',
  page: 1,
  search: 'laptop', // optional keyword search
  filters: {'status': 'active'}, // column filters
  relationField: 'category_id', // foreign key relation
  relationValue: 2,
  withAuth: true,
);

print('Page: \${page.currentPage} of \${page.lastPage}');
print('Loaded \${page.items.length} records. Total: \${page.total}');

// Raw GET request alternative:
final rawResponse = await Hosteday.client.get(
  '/products',
  queryParameters: {'page': 1},
  withAuth: true,
);
final List<Map<String, dynamic>> items = 
    ApiResponseReader.readList(rawResponse);''',
    ),
    GuideSection(
      id: 'api_show',
      categoryEn: 'Database & CRUD',
      categoryAr: 'قواعد البيانات والـ API',
      icon: Icons.find_in_page_rounded,
      titleEn: '2. Fetch Single Record (show)',
      titleAr: '٢. جلب سجل مفرد بالتفصيل (show)',
      descriptionEn:
          'Retrieve a single record using client.show(id: 42) or get(id: 42). Unwraps the object directly from the response envelope.',
      descriptionAr:
          'جلب تفاصيل سجل واحد بتمرير المعرف باستخدام client.show(id: 42) المباشرة أو get(id: 42). تستخرج الكائن مباشرة من استجابة الخادم.',
      code: '''// Native 2.3.0 Typed Show helper:
// GET /api/products/42
final Map<String, dynamic> product = await Hosteday.client.show(
  '/products',
  id: 42,
  withAuth: true,
);

print('Product: \${product['name']} (Price: \${product['price']})');

// Raw GET request alternative:
final response = await Hosteday.client.get('/products', id: 42);
final singleObject = ApiResponseReader.readObject(response);''',
    ),
    GuideSection(
      id: 'api_mutations',
      categoryEn: 'Database & CRUD',
      categoryAr: 'قواعد البيانات والـ API',
      icon: Icons.edit_note_rounded,
      titleEn: '3. Create, Update & Delete (store, update, destroy)',
      titleAr: '٣. الإضافة والتعديل والحذف (store, update, destroy)',
      descriptionEn:
          'Use post for store, put or patch for update with id, and delete for destroy. The SDK handles JSON encoding, error parsing, and status validation.',
      descriptionAr:
          'استخدم post للإضافة (store)، و put أو patch للتعديل بتمرير id، و delete للحذف بتمرير id. تتولى الحزمة تشفير JSON، معالجة الأخطاء، وترويسات المصادقة.',
      code: '''// Create a new record (store):
// POST /api/products
final created = await Hosteday.client.post(
  '/products',
  body: {'name': 'MacBook Pro', 'price': 1999, 'stock': 10},
  withAuth: true,
);

// Update existing record by ID (update):
// PUT /api/products/42
await Hosteday.client.put(
  '/products',
  id: 42,
  body: {'price': 1899, 'stock': 9},
  withAuth: true,
);

// Delete record by ID (destroy):
// DELETE /api/products/42
await Hosteday.client.delete(
  '/products',
  id: 42,
  withAuth: true,
);''',
    ),
  ];

  static const List<GuideSection> realtimeSections = <GuideSection>[
    GuideSection(
      id: 'realtime_listen',
      categoryEn: 'Realtime WebSockets',
      categoryAr: 'الوقت الفعلي والويب سوكت',
      icon: Icons.bolt_rounded,
      titleEn: '1. Connect & Listen to Live Channels',
      titleAr: '١. الاتصال والاستماع للقنوات المباشرة',
      descriptionEn:
          'Subscribe to Public, Private (authenticated), or Presence (chat/presence) channels powered by Pusher-compatible WebSockets.',
      descriptionAr:
          'اشترك في القنوات العامة أو الخاصة (الموثقة) أو قنوات التواجد والمحادثات المباشرة عبر خوادم WebSocket السريعة.',
      code: '''// Open WebSocket connection:
await Hosteday.connectRealtime();

// Public channel subscription:
final subscription = await Hosteday.realtime.listenPublic(
  channel: 'orders',
  event: 'OrderCreated',
  onEvent: (HostedayRealtimeEvent event) {
    print('New order received: \${event.payload}');
  },
);

// Private channel (requires authenticated user):
final privateSub = await Hosteday.realtime.listenPrivate(
  channel: 'user.notifications.12',
  event: 'AlertEvent',
  onEvent: (event) => print(event.message),
);''',
    ),
    GuideSection(
      id: 'realtime_publish',
      categoryEn: 'Realtime WebSockets',
      categoryAr: 'الوقت الفعلي والويب سوكت',
      icon: Icons.cell_tower_rounded,
      titleEn: '2. Broadcast Realtime Events',
      titleAr: '٢. بث الأحداث اللحظية من التطبيق',
      descriptionEn:
          'Publish events to public or private channels. The server validates permissions and broadcasts to all active subscribers.',
      descriptionAr:
          'إرسال الأحداث إلى القنوات العامة أو الخاصة؛ حيث يتحقق السيرفر من الصلاحيات ويبثها لجميع المتصلين.',
      code: '''// Publish public event:
await Hosteday.client.publishPublicEvent(
  channel: 'announcements',
  event: 'NewAnnouncement',
  payload: {'message': 'System maintenance at 10 PM'},
);

// Publish private event:
await Hosteday.client.publishPrivateEvent(
  channel: 'chat.room.5',
  event: 'MessageSent',
  payload: {'text': 'Hello everyone!'},
);''',
    ),
  ];

  static const List<GuideSection> notificationSections = <GuideSection>[
    GuideSection(
      id: 'device_tokens',
      categoryEn: 'Smart Push Notifications',
      categoryAr: 'الإشعارات والمهام الذكية',
      icon: Icons.notifications_active_rounded,
      titleEn: '1. Register & Unregister Device Tokens',
      titleAr: '١. تسجيل وإلغاء رموز الأجهزة (Push Tokens)',
      descriptionEn:
          'Register FCM or APNs device tokens. Tokens are linked to the user and automatically cleaned up when Hosteday.auth.signOut() is called.',
      descriptionAr:
          'تسجيل رموز أجهزة FCM أو APNs. تُربط التوكنات بحساب المستخدم وتُلغى تلقائياً عند تسجيل الخروج Hosteday.auth.signOut().',
      code: '''// Register token from Firebase Messaging:
await Hosteday.notifications.registerDeviceToken(
  token: fcmToken,
  deviceType: 'android', // or 'ios', 'web'
  deviceId: 'unique_device_id',
);

// Check or observe registered token:
print('Current Token: \${Hosteday.notifications.currentToken}');

// Automated cleanup on sign out:
await Hosteday.auth.signOut(); // Unregisters token automatically''',
    ),
    GuideSection(
      id: 'dispatch_notifications',
      categoryEn: 'Smart Push Notifications',
      categoryAr: 'الإشعارات والمهام الذكية',
      icon: Icons.send_rounded,
      titleEn: '2. Dispatch Push Notifications',
      titleAr: '٢. إرسال وبث الإشعارات الفورية',
      descriptionEn:
          'Send push notifications targeted by topic, user ID, or direct device token through Hosteday Notification Gateway.',
      descriptionAr:
          'إرسال الإشعارات الموجهة حسب Topic عام، أو معرف مستخدم محدد، أو رمز جهاز مباشر عبر بوابة إشعارات Hosteday.',
      code: '''// Send notification to a topic:
final response = await Hosteday.notifications.sendNotification(
  title: 'Special Offer! / عرض خاص',
  body: 'Get 20% discount on all items today.',
  topic: 'promotions',
  data: {'promo_code': 'SUMMER20'},
);

print('Delivered successfully: \${response.success}');
print('Message ID: \${response.messageId}');''',
    ),
  ];
}
