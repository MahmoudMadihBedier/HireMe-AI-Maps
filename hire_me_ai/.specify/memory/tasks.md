# Task Breakdown: HireMe Recruitment Platform

**Branch**: `feature/maps-ai` | **Date**: 2026-06-21 | **Spec**: `/spec.md` | **Plan**: `/plan.md`

**Total Tasks**: 157 | **Phases**: 11 | **User Stories**: 12 (5 P1 + 7 P2)

---

## Phase 0: Setup & Foundations (13 Tasks)

### 0.1 Environment & Configuration

- [ ] **T001** [Plan:0.1] Verify Flutter SDK ^3.11.0 installed (`flutter --version` should show 3.41.6); verify Dart SDK ^3.11.0; verify Java 17+ for Android Gradle builds
  - **File Path**: N/A (verification step)
  - **Acceptance**: `flutter --version` outputs 3.41.6; `dart --version` outputs 3.11+; `java -version` shows Java 17+
  - **Owner**: DevOps / Local Setup

- [ ] **T002** [Plan:0.1] Create `.env` file in project root with SUPABASE_URL and SUPABASE_ANON_KEY (from Supabase project settings); git-ignore the file
  - **File Path**: `.env` (git-ignored)
  - **Acceptance**: `.env` exists in root; values are from Supabase console; `.gitignore` includes `.env`
  - **Owner**: Setup / DevOps

- [ ] **T003** [Plan:0.1] Run `flutterfire configure` to regenerate `lib/firebase_options.dart`; verify `android/app/google-services.json` is present (from Firebase console); both are git-ignored
  - **File Path**: `lib/firebase_options.dart` (auto-generated, DO NOT EDIT); `android/app/google-services.json` (git-ignored)
  - **Acceptance**: FirebaseOptions file reflects correct Firebase project IDs; google-services.json contains Android configuration
  - **Owner**: Setup / DevOps

- [ ] **T004** [Plan:0.1] Verify `analysis_options.yaml` exists with Flutter lint rules; run `flutter analyze --no-fatal-infos --no-fatal-warnings` and confirm zero violations (baseline check)
  - **File Path**: `analysis_options.yaml`
  - **Acceptance**: Analyze runs without errors; output shows "No issues found" or only informational messages
  - **Owner**: QA / Code Quality

---

### 0.2 Service Layer Foundation

- [ ] **T005** [Plan:0.2] Implement `StorageService` in `lib/app/services/storage_service.dart`: create Supabase Storage abstraction with methods for uploadFile(), downloadFile(), getSignedUrl(), deleteFile()
  - **File Path**: `lib/app/services/storage_service.dart`
  - **Methods**: uploadFile(path, file) → Future<String>; getSignedUrl(path) → Future<String>; deleteFile(path) → Future<bool>
  - **Dependencies**: supabase_flutter package, Supabase Storage bucket configured
  - **Acceptance**: StorageService compiles without errors; methods accept file paths and return URLs/bools

- [ ] **T006** [Plan:0.2] Implement `NotificationService` in `lib/app/services/notification_service.dart`: FCM initialization, notification routing (NotificationService._navigateFromData), badge count management (notification_count observable)
  - **File Path**: `lib/app/services/notification_service.dart`
  - **Key Components**: 
    - `notification_count` observable (RxInt)
    - `_navigateFromData(data)` method routes by data type: "chat_message" → ChatDetail, "application_update" → MyApplications, "new_application" → Dashboard
    - `onForegroundNotification(notification)` handler
    - `onBackgroundNotification(message)` handler for background messages
  - **Dependencies**: firebase_messaging package
  - **Acceptance**: Service compiles; notification_count observable updates; routing tested with mock data

- [ ] **T007** [Plan:0.2] Update `lib/main.dart` entrypoint: set FirebaseMessaging.onBackgroundMessage before dotenv.load() → load .env → initialize Firebase (Firebase.apps.isEmpty guard) + Supabase (parallel Future.wait) → Get.putAsync(StorageService) → Get.putAsync(NotificationService) → runApp(GetMaterialApp(...))
  - **File Path**: `lib/main.dart`
  - **Sequence**: 
    ```dart
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await dotenv.load();
    await Future.wait([
      Firebase.initializeApp(...),
      Supabase.initialize(...)
    ]);
    Get.putAsync(() => StorageService());
    Get.putAsync(() => NotificationService());
    ```
  - **Acceptance**: App launches without errors; services are registered in GetX container

---

### 0.3 Middleware & Route Scaffolding

- [ ] **T008** [Plan:0.3] Implement `RoleGuardMiddleware` in `lib/app/middleware/role_guard_middleware.dart`: check user role (from auth state) and block/redirect unauthorized access
  - **File Path**: `lib/app/middleware/role_guard_middleware.dart`
  - **Logic**: Extract route name → check user role → if role doesn't match allowed roles, redirect to home or login
  - **Usage**: Applied to protected routes in app_pages.dart
  - **Acceptance**: Middleware compiles; blocks job seeker from company routes and vice versa

- [ ] **T009** [Plan:0.3] Create all route constants in `lib/app/routes/app_pages.dart` (Routes.* namespace): include 40+ routes (auth, job seeker, company, profile, shared); mark public routes (pdf_viewer, maps, search_jobs) with no middleware
  - **File Path**: `lib/app/routes/app_pages.dart` and `lib/app/routes/app_routes.dart` (part of app_pages.dart, DO NOT import directly)
  - **Route List**:
    - Auth: login, register, forgotPassword, splash, onboarding, roleSelector, selectUser
    - Job Seeker: dashboard, searchJobs, jobDetails, applyJob, myApplications, savedJobs, jobsMap, chat, chatDetails, mainFields
    - Company: postJob, dashboard, applicationList, applicationReview, companyProfile, companyChatList, companyChatDetails
    - Shared: profileEdit, pdfViewer, settings
  - **Acceptance**: All routes defined; compile without errors; public routes have no middleware

- [ ] **T010** [Plan:0.3] Scaffold binding classes: create `MainWrapperBinding`, `JobSeekerBinding`, `JobSeekerMyApplicationsBinding`, `CompanyBinding` with lazyPut registrations for deferred controllers
  - **File Path**: `lib/app/bindings/` (multiple files)
  - **Key Bindings**:
    - MainWrapperBinding: JobsMapController (lazyPut), JobSeekerSavedJobsController (lazyPut)
    - JobSeekerMyApplicationsBinding: JobSeekerSavedJobsController (lazyPut - safe dedup)
    - JobSeekerBinding: Bind all job seeker controllers
    - CompanyBinding: Bind all company controllers
  - **Acceptance**: All binding classes compile; GetX lazyPut deduplication verified

---

### 0.4 Core Models & Base Classes

- [ ] **T011** [Plan:0.4] Create Firestore data models in `lib/core/models/`: User, Company, Job, Application, ChatThread, ChatMessage with toMap() and fromMap() serialization methods
  - **File Path**: `lib/core/models/{user,company,job,application,chat_thread,chat_message}.dart`
  - **User Model**: email, skills, experience, mainFields, profileUrl, savedJobs[], role, fcmToken
  - **Company Model**: name, description, location, logoUrl, recruiterId, postedJobs[]
  - **Job Model**: title, description, requirements, location (lat/lon), salary, companyId, createdAt
  - **Application Model**: jobId, jobSeekerId, status (pending/accepted/rejected), cvUrl, createdAt, updatedAt
  - **ChatThread Model**: participants (jobSeekerId, companyId), createdAt, lastMessage, lastMessageAt
  - **ChatMessage Model**: senderId, content, timestamp, readStatus
  - **Acceptance**: All models compile; toMap/fromMap work bidirectionally

- [ ] **T012** [Plan:0.4] Create `GetxController` base class wrapper (optional extension point) in `lib/core/base/getx_controller_base.dart`
  - **File Path**: `lib/core/base/getx_controller_base.dart`
  - **Content**: Can extend GetxController with common logging, error handling if needed (optional, can be empty for now)
  - **Acceptance**: Class compiles; future controllers can extend it

- [ ] **T013** [Plan:0.4] Create `GetxBinding` base class for common binding patterns in `lib/core/base/getx_binding_base.dart`
  - **File Path**: `lib/core/base/getx_binding_base.dart`
  - **Content**: Common pattern for binding registration; validates lazyPut deduplication
  - **Acceptance**: Class compiles; can be used as template for future bindings

---

## Phase 1: Authentication & Session Management (21 Tasks)

### 1.1 Supabase Auth Integration

- [ ] **T014** [US1] [Plan:1.1] Implement Supabase PKCE auth flow in `AuthController`: initialize with `Supabase.initialize(..., authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce, autoRefreshToken: true))`
  - **File Path**: `lib/app/modules/auth/login/auth_controller.dart`
  - **Dependencies**: supabase_flutter, PKCE flow configured in Supabase project
  - **Acceptance**: Auth controller compiles; PKCE flow is initialized

- [ ] **T015** [US1] [Plan:1.1] Implement `AuthController.signup(email, password, role)`: call `Supabase.auth.signUp(email: email, password: password)` → return auth session
  - **File Path**: `lib/app/modules/auth/register/register_controller.dart`
  - **Flow**: Email validation → password validation → Supabase.auth.signUp() → handle error/success
  - **Acceptance**: Signup creates account in Supabase Auth; session returned with auth token

- [ ] **T016** [US1] [Plan:1.1] Implement `AuthController.login(email, password)`: call `Supabase.auth.signInWithPassword(email: email, password: password)` → return auth session
  - **File Path**: `lib/app/modules/auth/login/login_controller.dart`
  - **Flow**: Email/password input → Supabase.auth.signInWithPassword() → handle error/success
  - **Acceptance**: Login creates session; auth token returned

- [ ] **T017** [US1] [Plan:1.1] Implement `AuthController.resetPassword(email)`: call `Supabase.auth.resetPasswordForEmail(email: email)` → email link sent
  - **File Path**: `lib/app/modules/auth/forgot_password/forgot_password_controller.dart`
  - **Flow**: Email input → Supabase.auth.resetPasswordForEmail() → show success message
  - **Acceptance**: Password reset email is sent; user can reset via email link

- [ ] **T018** [US1] [Plan:1.1] Verify auto-refresh token mechanism: after token expiry (simulated), next API call should auto-refresh token without manual intervention
  - **File Path**: Integration test or manual verification
  - **Test Scenario**: Wait for token expiry → make API call → observe token auto-refreshed in background
  - **Acceptance**: No manual token refresh needed; session continues seamlessly

---

### 1.2 Firestore Profile Creation & Persistence

- [ ] **T019** [US1] [Plan:1.2] Create job seeker profile after signup in `JobSeekerProfileController`: after auth.signUp(), call `Firestore.collection('users').doc(userId).set({email, skills: [], experience: '', mainFields: [], profileUrl: '', role: 'jobSeeker'}, SetOptions(merge: true))`
  - **File Path**: `lib/app/modules/job_seeker/profile/job_seeker_profile_controller.dart`
  - **Firestore Path**: `users/{userId}`
  - **Fields**: email, skills[], experience, mainFields[], profileUrl, role, savedJobs[], createdAt
  - **Acceptance**: Profile document created in Firestore with merge: true

- [ ] **T020** [US1] [Plan:1.2] Create company profile after signup in `CompanyProfileController`: after auth.signUp(), call `Firestore.collection('companies').doc(companyId).set({email, name, description, location, logoUrl, postedJobs: [], recruiterId: userId}, SetOptions(merge: true))`
  - **File Path**: `lib/app/modules/company/company_profile/company_profile_controller.dart`
  - **Firestore Path**: `companies/{companyId}`
  - **Fields**: email, name, description, location, logoUrl, postedJobs[], recruiterId, createdAt
  - **Acceptance**: Company document created in Firestore with merge: true

- [ ] **T021** [US1] [Plan:1.2] Implement profile update controller: edit skills, main fields, company description → `Firestore.collection('users/{userId}').update({...}, SetOptions(merge: true))` to ensure no field overwrites
  - **File Path**: `lib/app/modules/profile/profile_controller.dart`
  - **Method**: updateProfile(updatedFields) → Firestore.update() with SetOptions(merge: true)
  - **Acceptance**: Profile updates persist; unrelated fields not overwritten

- [ ] **T022** [US1] [Plan:1.2] Test concurrent profile updates: update field A (skills) and field B (experience) simultaneously → verify both persist via merge: true (no loss)
  - **File Path**: Unit test `test/profile_controller_test.dart`
  - **Test Scenario**: Two concurrent update calls → verify both fields in Firestore after completion
  - **Acceptance**: Concurrent updates succeed; no data loss

---

### 1.3 FCM Token Management

- [ ] **T023** [US1] [Plan:1.3] On login, register FCM token: `FirebaseMessaging.instance.getToken()` → `Firestore.collection('users').doc(userId).set({fcmToken: token}, SetOptions(merge: true))`
  - **File Path**: `lib/app/modules/auth/login/login_controller.dart` (after successful login)
  - **Flow**: After auth token issued → get FCM token → store in Firestore with merge: true
  - **Acceptance**: FCM token stored in Firestore under user document

- [ ] **T024** [US1] [Plan:1.3] On logout, delete FCM token (4-step sequence in ProfileController around line ~800-811):
  1. `Firestore.collection('users/{userId}/settings').update({fcmToken: FieldValue.delete()})`
  2. `FirebaseMessaging.instance.deleteToken()`
  3. `Supabase.auth.clearAuthSession()`
  4. `Supabase.auth.signOut()`
  - **File Path**: `lib/app/modules/profile/profile_controller.dart` (logout method, lines ~800-811)
  - **Sequence**: Must execute in order; skip any step = token leak
  - **Acceptance**: All 4 steps execute; FCM token deleted from Firestore + device

- [ ] **T025** [US1] [Plan:1.3] Test logout flow: logout user A → verify FCM token removed from Firestore → launch app with different device/account (user B) → user B receives notifications, user A does NOT
  - **File Path**: Integration test or manual QA
  - **Test Scenario**: Logout user A → verify user A receives NO notifications after logout; user B on different device receives notifications
  - **Acceptance**: Logout properly cleans up FCM token; no notifications received post-logout

---

### 1.4 Splash & Onboarding

- [ ] **T026** [US1] [Plan:1.4] Implement `SplashController`: check Supabase auth status on app launch → if auth exists, redirect to dashboard; if not, redirect to onboarding
  - **File Path**: `lib/app/modules/auth/splash/splash_controller.dart`
  - **Logic**: `Supabase.auth.currentSession` check → route accordingly
  - **Acceptance**: Splash controller routes correctly based on auth state

- [ ] **T027** [US1] [Plan:1.4] Implement `OnboardingController`: display role selection (Job Seeker / Company) → store selected role in observable → navigate to signup
  - **File Path**: `lib/app/modules/auth/onboarding/onboarding_controller.dart`
  - **Observable**: `selectedRole` (RxString)
  - **Actions**: selectJobSeekerRole(), selectCompanyRole()
  - **Acceptance**: Role selection works; observable updates; navigation proceeds

- [ ] **T028** [US1] [Plan:1.4] Implement `RoleSelector` view: two buttons (Job Seeker / Company) → tap button → call controller.selectRole() → navigate to signup
  - **File Path**: `lib/app/modules/auth/role_selector/role_selector_view.dart` and `role_selector_controller.dart`
  - **UI**: Two distinct buttons with labels and icons
  - **Acceptance**: Buttons tap correctly; role is stored; navigation to signup succeeds

---

### 1.5 Session Persistence & Auto-Refresh

- [ ] **T029** [US1] [Plan:1.5] Verify Supabase auth token auto-refresh: logout session (simulate token expiry) → wait for expiry → next Firestore query should auto-refresh token in background → no manual intervention needed
  - **File Path**: Integration test or manual verification
  - **Test Scenario**: Make authenticated request → wait for token expiry (or mock it) → make another request → observe token auto-refreshed
  - **Acceptance**: Token auto-refreshes without user action; session continues

- [ ] **T030** [US1] [Plan:1.5] Test multi-device session: logout on Device A → verify Device A receives NO notifications → login on Device B with same account → Device B registers new FCM token → verify Device B receives notifications (Device A still no notifications)
  - **File Path**: Integration test or manual QA
  - **Test Scenario**: Multi-device logout/login → verify FCM token isolation
  - **Acceptance**: Each device has independent FCM token; logout on one device doesn't affect other

---

### 1.6 Testing (Manual Fakes)

- [ ] **T031** [US1] [Plan:1.6] Create manual fakes for Supabase Auth in `test/fakes/fake_supabase_auth.dart`: implement signup(), login(), signOut(), resetPassword(), and auto-refresh simulation
  - **File Path**: `test/fakes/fake_supabase_auth.dart`
  - **Methods**: signup(email, password) → mock session; login(email, password) → mock session; signOut() → clear session; refreshToken() → simulate token refresh
  - **Acceptance**: Fakes compile; simulate auth flows for testing

- [ ] **T032** [US1] [Plan:1.6] Create manual fakes for Firestore in `test/fakes/fake_firestore_service.dart`: track set() calls and REJECT plain set() without merge: true
  - **File Path**: `test/fakes/fake_firestore_service.dart`
  - **Validation**: set() without SetOptions(merge: true) throws error; set() with merge: true succeeds
  - **Acceptance**: Fakes validate merge: true requirement

- [ ] **T033** [US1] [Plan:1.6] Create test `test/auth_login_controller_test.dart`: test login flow with manual fakes → verify auth token created → verify FCM token registered in Firestore → verify profile created
  - **File Path**: `test/auth_login_controller_test.dart`
  - **Test Cases**:
    1. Login with valid credentials → token issued
    2. FCM token registered in Firestore
    3. Profile document exists after login
  - **Setup/Teardown**: setUp(Get.reset()), tearDown(Get.reset())
  - **Acceptance**: All test cases pass

- [ ] **T034** [US1] [Plan:1.6] Create test `test/logout_controller_test.dart`: test logout flow with manual fakes → verify 4-step sequence executes → verify FCM token deleted from Firestore → verify session cleared
  - **File Path**: `test/logout_controller_test.dart`
  - **Test Cases**:
    1. Logout sequence: Firestore delete → deleteToken() → clearAuthSession() → signOut()
    2. FCM token not in Firestore after logout
    3. Auth session is null
  - **Acceptance**: All logout steps verified

---

## Phase 2: Job Discovery & Distance Filtering (18 Tasks)

### 2.1 Location & Distance Mixin

- [ ] **T035** [US3] [Plan:2.1] Implement `DistanceMixin` in `lib/app/modules/job_seeker/shared/distance_mixin.dart`: provide `userPosition` (RxDouble? for lat/lon), `jobDistances` (RxMap<jobId, distance>), `getDistanceToCompany(lat, lon)`, `updateJobDistancesFrom(userLat, userLon)`
  - **File Path**: `lib/app/modules/job_seeker/shared/distance_mixin.dart`
  - **Observables**:
    - `userPosition` (RxList<double> for [lat, lon])
    - `jobDistances` (RxMap<String, double>) where key=jobId, value=distance
  - **Methods**:
    - `getDistanceToCompany(lat, lon)` → double (km)
    - `updateJobDistancesFrom(userLat, userLon)` → calculate distance for all jobs
  - **Usage**: Mixin in JobSeekerDashboardController, JobSeekerSearchJobsController, JobsMapController
  - **Acceptance**: Mixin compiles; distances calculated correctly

- [ ] **T036** [US3] [Plan:2.1] Request location permission: `Geolocator.requestPermission()` → if GRANTED, `Geolocator.getCurrentPosition()` → store in `userPosition` observable
  - **File Path**: `lib/app/modules/job_seeker/shared/distance_mixin.dart` (requestLocationPermission() method)
  - **Flow**: Button tap → request permission → if granted, get current position → update userPosition
  - **Acceptance**: Permission request appears; if granted, location captured in observable

- [ ] **T037** [US3] [Plan:2.1] Implement distance calculation: `Geolocator.distanceBetween(userLat, userLon, jobLat, jobLon)` → returns distance in meters → convert to km → store in `jobDistances` map
  - **File Path**: `lib/app/modules/job_seeker/shared/distance_mixin.dart` (getDistanceToCompany method)
  - **Calculation**: Haversine formula via Geolocator
  - **Output**: Distance in km with 1 decimal place
  - **Acceptance**: Distances calculated correctly; stored in observable

- [ ] **T038** [US3] [Plan:2.1] Test location permission denied: if user denies permission → verify app functions without distance filtering (toggle greyed out) → distance calculations skipped
  - **File Path**: Integration test or manual QA
  - **Scenario**: Deny location permission → app still works → distance filter unavailable
  - **Acceptance**: App handles denied permission gracefully

---

### 2.2 Job Dashboard & Search

- [ ] **T039** [US3] [Plan:2.2] Implement `JobSeekerDashboardController` with DistanceMixin: fetch all jobs from Firestore → display in list with distance (if available)
  - **File Path**: `lib/app/modules/job_seeker/dashboard/job_seeker_dashboard_controller.dart`
  - **Mix-ins**: DistanceMixin
  - **Methods**:
    - `onInit()` → fetch jobs from Firestore
    - `refreshJobs()` → re-fetch job list
  - **Observables**: `jobs` (RxList<Job>), `isLoading` (RxBool)
  - **Acceptance**: Dashboard controller compiles; jobs list populated; distance calculated where available

- [ ] **T040** [US3] [Plan:2.2] Implement `JobSeekerSearchJobsController` with DistanceMixin: search textfield observable → Firestore query by title/company/keyword → filter results
  - **File Path**: `lib/app/modules/job_seeker/search_jobs/job_seeker_search_jobs_controller.dart`
  - **Mix-ins**: DistanceMixin
  - **Observables**: `searchQuery` (RxString), `searchResults` (RxList<Job>)
  - **Method**: `search(query)` → Firestore query with keyword matching
  - **Acceptance**: Search returns matching jobs; results update in real-time

- [ ] **T041** [US3] [Plan:2.2] Implement "Sort by Distance" toggle: `sortByDistance` (RxBool) observable → if true, re-order jobs by distance (ascending); jobs with null distance sort last
  - **File Path**: `lib/app/modules/job_seeker/dashboard/job_seeker_dashboard_controller.dart`
  - **Logic**: Sort jobs list by jobDistances map; if distance is null, push to end
  - **Acceptance**: Toggle works; jobs re-order by distance; null distances appear last

- [ ] **T042** [US3] [Plan:2.2] Test search performance: load 100+ jobs into Firestore → execute search query → measure response time → verify <2 seconds
  - **File Path**: Integration test or performance test
  - **Scenario**: 100+ jobs in Firestore → search for keyword → measure query + render time
  - **Acceptance**: Search returns in <2 seconds

---

### 2.3 Job Card Widget & Details

- [ ] **T043** [US3] [Plan:2.3] Implement `JobCardWidget` in `lib/app/modules/job_seeker/shared/job_card_widget.dart`: displays job title, company name, location, salary, and distance (if available)
  - **File Path**: `lib/app/modules/job_seeker/shared/job_card_widget.dart`
  - **Parameters**: job (Job model), distance (double?, can be null)
  - **UI**: Card with job info + distance label (e.g., "5.2 km away")
  - **Tap Action**: Navigate to JobDetails screen
  - **Acceptance**: Widget renders correctly; distance displays when available

- [ ] **T044** [US3] [Plan:2.3] Implement `JobDetailsController`: fetch full job description from Firestore → load company profile → calculate distance if user location available
  - **File Path**: `lib/app/modules/job_seeker/job_details/job_details_controller.dart`
  - **Methods**: onInit() → fetch job by ID, fetch company by companyId
  - **Observables**: `job` (Rx<Job>), `company` (Rx<Company>), `distance` (RxDouble?)
  - **Acceptance**: Controller loads job and company data; distance calculated

- [ ] **T045** [US3] [Plan:2.3] Implement `JobDetailsView`: display job title, description, requirements, company logo, salary, apply button, and save button
  - **File Path**: `lib/app/modules/job_seeker/job_details/job_details_view.dart`
  - **UI Elements**: Job header (title, company, salary) + description + requirements + apply/save buttons
  - **Acceptance**: View renders all job details; buttons are tappable

---

### 2.4 Google Map Integration

- [ ] **T046** [US3] [Plan:2.4] Implement `GoogleMap` widget in `JobDetailsView`: display job location as marker; center map on job coordinates
  - **File Path**: `lib/app/modules/job_seeker/job_details/job_details_view.dart` (map section)
  - **Implementation**: GoogleMap(initialCameraPosition, markers: [Marker(...)], ...)
  - **Acceptance**: Map renders; job marker visible; map centers on job location

- [ ] **T047** [US3] [Plan:2.4] Implement marker tap handling: `Marker.onTap` callback → show InfoWindow with job title or navigate to JobDetails
  - **File Path**: `lib/app/modules/job_seeker/job_details/job_details_view.dart`
  - **Action**: Tap marker → InfoWindow appears with job info + tap to view more
  - **Acceptance**: Marker tap works; InfoWindow displays job info

- [ ] **T048** [US3] [Plan:2.4] Implement reverse geocoding (company_map_controller only): convert job coordinates (lat/lon) → address string using geocoding package
  - **File Path**: `lib/app/modules/company/company_map/company_map_controller.dart`
  - **Usage**: Get human-readable address from coordinates
  - **Note**: Geocoding package only used in company_map_controller; not in job seeker distance calculations
  - **Acceptance**: Reverse geocoding returns address string

- [ ] **T049** [US3] [Plan:2.4] Test map performance: render 100+ job markers on single map → scroll and pan → verify no lag or janky animation
  - **File Path**: Integration test or manual QA
  - **Scenario**: Map with 100+ markers → perform scroll/pan operations → observe frame rate
  - **Acceptance**: Map renders smoothly; no frame drops

---

### 2.5 Testing (Manual Fakes)

- [ ] **T050** [US3] [Plan:2.5] Create `FakeGeolocator` in `test/fakes/fake_geolocator.dart`: mock userPosition, distance calculations (no real GPS in tests)
  - **File Path**: `test/fakes/fake_geolocator.dart`
  - **Methods**: getCurrentPosition() → mock Position(lat, lon); distanceBetween() → mock distance
  - **Acceptance**: Fake provides consistent mock data for testing

- [ ] **T051** [US3] [Plan:2.5] Create test `test/job_seeker_dashboard_controller_test.dart` with manual fakes: test distance sorting + null distance handling
  - **File Path**: `test/job_seeker_dashboard_controller_test.dart`
  - **Test Cases**:
    1. Load jobs with mixed coordinates (some null)
    2. Enable sort by distance → jobs ordered correctly
    3. Jobs with null distance appear last
  - **Acceptance**: All test cases pass

- [ ] **T052** [US3] [Plan:2.5] Create test `test/job_search_controller_test.dart`: search with distance filter enabled → verify correct job ordering
  - **File Path**: `test/job_search_controller_test.dart`
  - **Test Cases**:
    1. Search with keywords → results returned
    2. Enable distance sort → results re-ordered
    3. Null distance jobs appear last
  - **Acceptance**: All test cases pass

---

## Phase 3: Job Applications & Status Tracking (18 Tasks)

### 3.1 Application Creation & Submission

- [ ] **T053** [US4] [Plan:3.1] Implement `ApplyJobController`: capture CV file via file picker → upload to Supabase Storage → create Firestore application document with status: "pending"
  - **File Path**: `lib/app/modules/job_seeker/apply_job/apply_job_controller.dart`
  - **Flow**: Tap "Apply" → file picker → upload CV → create Firestore application record
  - **Observables**: `isUploading` (RxBool), `uploadProgress` (RxDouble)
  - **Acceptance**: File picker works; CV uploads; application created in Firestore

- [ ] **T054** [US4] [Plan:3.1] Implement CV upload to Supabase Storage: file picker (image_picker or file_picker) → upload to path `/applications/{jobId}/{userId}/{timestamp}.pdf` → return signed URL
  - **File Path**: `lib/app/services/storage_service.dart` (uploadFile method)
  - **Path Structure**: `/applications/{jobId}/{userId}/{timestamp}.pdf`
  - **Return**: Signed URL for future access
  - **Acceptance**: File uploads; signed URL returned

- [ ] **T055** [US4] [Plan:3.1] Test application creation: apply for job → verify Firestore application document exists with status: "pending" → verify merge: true was used
  - **File Path**: Integration test or manual QA
  - **Scenario**: Apply for job → check Firestore → application document present with correct fields
  - **Acceptance**: Application document created correctly

- [ ] **T056** [US4] [Plan:3.1] Test CV upload: upload CV → verify file appears in Supabase Storage → verify signed URL is accessible (no 403 errors)
  - **File Path**: Integration test or manual QA
  - **Scenario**: Upload CV → access via signed URL → verify file content
  - **Acceptance**: File uploaded; URL is accessible

---

### 3.2 Firestore Application Persistence

- [ ] **T057** [US4] [Plan:3.2] Create `Application` model in `lib/core/models/application.dart` with Firestore serialization: toMap() / fromMap() for fields (jobId, userId, status, cvUrl, timestamp, etc.)
  - **File Path**: `lib/core/models/application.dart`
  - **Fields**: id, jobId, userId, status (String: pending/accepted/rejected), cvUrl, appliedAt, updatedAt, companyFeedback
  - **Methods**: toMap() → Map, fromMap(Map) → Application
  - **Acceptance**: Model compiles; serialization works bidirectionally

- [ ] **T058** [US4] [Plan:3.2] Implement `ApplicationRepository` in `lib/core/repositories/application_repository.dart`: createApplication() method MUST use SetOptions(merge: true) to prevent overwrites
  - **File Path**: `lib/core/repositories/application_repository.dart`
  - **Method**: createApplication(application) → Firestore.doc(appId).set(application.toMap(), SetOptions(merge: true))
  - **Validation**: Reject any plain set() calls; only accept with merge: true
  - **Acceptance**: Repository enforces merge: true requirement

- [ ] **T059** [US4] [Plan:3.2] Test concurrent applications: multiple job seekers apply simultaneously → verify all applications persist without loss
  - **File Path**: Integration test or stress test
  - **Scenario**: N concurrent application submissions → check Firestore → all N documents exist with correct data
  - **Acceptance**: No application lost; all data persisted

---

### 3.3 Application Status Updates (Company-Side)

- [ ] **T060** [US4] [Plan:3.3] Implement `ApplicationReviewController`: fetch all applications for company's posted jobs with applicant info
  - **File Path**: `lib/app/modules/company/application_review/application_review_controller.dart`
  - **Query**: Firestore query: applications where company posted the job
  - **Observables**: `applications` (RxList<Application>)
  - **Acceptance**: Controller fetches and displays applications

- [ ] **T061** [US4] [Plan:3.3] Implement accept/reject action: tap accept/reject button → `Firestore.collection('applications').doc(appId).update({status: 'accepted'/'rejected'}, SetOptions(merge: true))` → Cloud Function triggered
  - **File Path**: `lib/app/modules/company/application_review/application_review_controller.dart`
  - **Methods**: acceptApplication(appId), rejectApplication(appId)
  - **Firestore Update**: Use merge: true; only update status field
  - **Acceptance**: Status updates in Firestore; Cloud Function execution triggered

- [ ] **T062** [US4] [Plan:3.3] Verify Cloud Function execution: after accept/reject, check Firebase Console → onApplicationAccepted/onApplicationRejected function logs → confirm execution with job seeker ID + application ID
  - **File Path**: Firebase Console (Cloud Functions logs)
  - **Functions**: `functions/index.js` (onApplicationAccepted, onApplicationRejected)
  - **Acceptance**: Cloud Function logs show function executed; no errors

---

### 3.4 Notification Routing for Application Updates

- [ ] **T063** [US4] [Plan:3.4] Implement FCM notification on application_update: Cloud Function sends FCM to job seeker with data: {type: "application_update", applicationId: "...", status: "accepted"/"rejected"}
  - **File Path**: `functions/index.js` (onApplicationAccepted, onApplicationRejected handlers)
  - **FCM Payload**: {data: {type: "application_update", applicationId, status, ...}}
  - **Acceptance**: FCM notification sent to job seeker device

- [ ] **T064** [US4] [Plan:3.4] Route notification in `NotificationService._navigateFromData()`: when data.type == "application_update" → navigate to MyApplications screen
  - **File Path**: `lib/app/services/notification_service.dart` (_navigateFromData method)
  - **Logic**: if (data['type'] == 'application_update') → Get.toNamed(Routes.myApplications)
  - **Acceptance**: Notification tap routes to MyApplications

- [ ] **T065** [US4] [Plan:3.4] Test end-to-end: company recruiter accepts application → job seeker receives FCM in foreground → taps notification → navigates to MyApplications → sees updated status
  - **File Path**: Integration test or manual QA
  - **Scenario**: Accept app → FCM received → tap → navigate → verify status visible
  - **Acceptance**: Entire flow works seamlessly

---

### 3.5 My Applications View

- [ ] **T066** [US4] [Plan:3.5] Implement `JobSeekerMyApplicationsController`: manage tabs (All, Pending, Accepted, Rejected)
  - **File Path**: `lib/app/modules/job_seeker/my_applications/job_seeker_my_applications_controller.dart`
  - **Observables**: `selectedTab` (RxInt), `filteredApplications` (RxList<Application>)
  - **Logic**: Filter applications by status based on selected tab
  - **Acceptance**: Tab selection filters correctly

- [ ] **T067** [US4] [Plan:3.5] Implement `JobSeekerSavedJobsController` (register in MainWrapperBinding + MyApplicationsBinding with lazyPut): fetch saved job IDs from user profile → fetch full job documents
  - **File Path**: `lib/app/modules/job_seeker/my_applications/job_seeker_saved_jobs_controller.dart`
  - **Registration**: MainWrapperBinding.lazyPut(() => JobSeekerSavedJobsController()), MyApplicationsBinding.lazyPut(() => JobSeekerSavedJobsController())
  - **Note**: GetX deduplicates lazyPut, so safe to register in multiple bindings
  - **Acceptance**: Controller loads saved jobs

- [ ] **T068** [US4] [Plan:3.5] Implement saved jobs display: use JobCardWidget with distance parameter for saved jobs in Saved Jobs tab
  - **File Path**: `lib/app/modules/job_seeker/my_applications/views/saved_jobs_tab.dart`
  - **UI**: List of saved jobs using JobCardWidget
  - **Acceptance**: Saved jobs tab displays jobs with distance where available

---

### 3.6 Testing (Manual Fakes)

- [ ] **T069** [US4] [Plan:3.6] Create `FakeApplicationRepository` in `test/fakes/fake_application_repository.dart`: track created applications with merge: true validation; reject plain set() calls
  - **File Path**: `test/fakes/fake_application_repository.dart`
  - **Tracking**: Store applications in memory; validate merge: true on all writes
  - **Acceptance**: Fake validates merge: true requirement

- [ ] **T070** [US4] [Plan:3.6] Create `FakeStorageService` in `test/fakes/fake_storage_service.dart`: mock CV upload → return mock signed URL
  - **File Path**: `test/fakes/fake_storage_service.dart`
  - **Methods**: uploadFile() → return mock URL; getSignedUrl() → return URL
  - **Acceptance**: Fake provides consistent mock URLs

- [ ] **T071** [US4] [Plan:3.6] Create test `test/application_review_controller_test.dart`: test application status update flow with manual fakes
  - **File Path**: `test/application_review_controller_test.dart`
  - **Test Cases**:
    1. Fetch applications list
    2. Accept application → status updates
    3. Reject application → status updates
  - **Acceptance**: All test cases pass

---

## Phase 4: Real-Time Chat (18 Tasks)

### 4.1 Chat Thread & Message Models

- [ ] **T072** [US5] [Plan:4.1] Create `ChatThread` model in `lib/core/models/chat_thread.dart`: Firestore document with participants (jobSeekerId, companyId), createdAt, lastMessage, lastMessageAt, with toMap/fromMap
  - **File Path**: `lib/core/models/chat_thread.dart`
  - **Fields**: id, jobSeekerId, companyId, createdAt, lastMessage (String), lastMessageAt, participants[2]
  - **Acceptance**: Model compiles; serialization works

- [ ] **T073** [US5] [Plan:4.1] Create `ChatMessage` model in `lib/core/models/chat_message.dart`: Firestore subcollection with senderId, content, timestamp, readStatus, with toMap/fromMap
  - **File Path**: `lib/core/models/chat_message.dart`
  - **Fields**: id, senderId, content (String), timestamp, readStatus (bool)
  - **Firestore Path**: `chats/{threadId}/messages/{messageId}`
  - **Acceptance**: Model compiles; ready for subcollection storage

- [ ] **T074** [US5] [Plan:4.1] Implement `ChatThreadRepository` in `lib/core/repositories/chat_thread_repository.dart`: methods createThread(), getThreads(), updateLastMessage()
  - **File Path**: `lib/core/repositories/chat_thread_repository.dart`
  - **Methods**:
    - `createThread(jobSeekerId, companyId)` → Firestore.collection('chats').add({...}, SetOptions(merge: true))
    - `getThreads(userId)` → Firestore query: where participants contains userId
    - `updateLastMessage(threadId, message)` → Firestore.doc(threadId).update({lastMessage, lastMessageAt}, SetOptions(merge: true))
  - **Acceptance**: Repository compiles; all methods use merge: true

- [ ] **T075** [US5] [Plan:4.1] Implement `ChatMessageRepository` in `lib/core/repositories/chat_message_repository.dart`: methods sendMessage(), getMessages() stream
  - **File Path**: `lib/core/repositories/chat_message_repository.dart`
  - **Methods**:
    - `sendMessage(threadId, message)` → Firestore.collection('chats/{threadId}/messages').add(message.toMap(), SetOptions(merge: true))
    - `getMessages(threadId)` → Firestore.collection('chats/{threadId}/messages').orderBy('timestamp').snapshots() (stream)
  - **Acceptance**: Repository compiles; stream returns messages ordered by timestamp

---

### 4.2 Chat List & Detail Screens

- [ ] **T076** [US5] [Plan:4.2] Implement `ChatListController`: fetch all chat threads for current user → display with last message preview + timestamp
  - **File Path**: `lib/app/modules/job_seeker/chat/chat_list_controller.dart` (and company equivalent)
  - **Observable**: `chatThreads` (RxList<ChatThread>)
  - **Query**: ChatThreadRepository.getThreads(currentUserId)
  - **Acceptance**: Controller fetches and displays threads

- [ ] **T077** [US5] [Plan:4.2] Implement `ChatDetailController`: fetch chat thread + messages stream listener → listen for new messages in real-time
  - **File Path**: `lib/app/modules/job_seeker/chat_details/chat_details_controller.dart`
  - **Stream**: ChatMessageRepository.getMessages(threadId) → update messages observable
  - **Observable**: `messages` (RxList<ChatMessage>), `chatThread` (Rx<ChatThread>)
  - **Acceptance**: Controller listens to messages stream; updates in real-time

- [ ] **T078** [US5] [Plan:4.2] Implement `ChatDetailView`: message list (scrollable) + input field + send button → tap send → message added to Firestore via stream listener
  - **File Path**: `lib/app/modules/job_seeker/chat_details/chat_details_view.dart`
  - **UI**: Message bubble list + TextField + send button
  - **Action**: Send button → ChatDetailController.sendMessage()
  - **Acceptance**: UI renders messages; send button functional

---

### 4.3 Message Sending & Persistence

- [ ] **T079** [US5] [Plan:4.3] Implement `sendMessage()`: user taps send → ChatMessageRepository.sendMessage() creates document in messages subcollection with timestamp
  - **File Path**: `lib/app/modules/job_seeker/chat_details/chat_details_controller.dart`
  - **Flow**: Tap send → create ChatMessage → sendMessage() → update Firestore + lastMessage
  - **Firestore**: `chats/{threadId}/messages/{newMessageId}` with merge: true
  - **Acceptance**: Message persists in Firestore

- [ ] **T080** [US5] [Plan:4.3] Implement message stream listener: `Firestore.collection('chats/{threadId}/messages').orderBy('timestamp').snapshots()` → update messages observable in real-time
  - **File Path**: `lib/app/modules/job_seeker/chat_details/chat_details_controller.dart`
  - **Stream Subscription**: StreamSubscription<QuerySnapshot> → on snapshot change, update messages list
  - **Error Handler**: onError → reset notifications if needed
  - **Acceptance**: New messages appear in UI instantly

- [ ] **T081** [US5] [Plan:4.3] Test concurrent messages: both parties send messages simultaneously (A sends, B sends at same time) → verify all messages persist in correct order
  - **File Path**: Integration test or manual QA
  - **Scenario**: Send from both sides simultaneously → check Firestore → all messages present with correct timestamps
  - **Acceptance**: No message loss; correct ordering by timestamp

---

### 4.4 Message Notifications (FCM)

- [ ] **T082** [US5] [Plan:4.4] Implement `onNewChatMessage` Cloud Function in `functions/index.js`: listen for new messages → send FCM to recipient with data: {type: "chat_message", threadId, senderId, preview}
  - **File Path**: `functions/index.js` (v2 event-driven handler)
  - **Trigger**: Firestore onCreate for `chats/{threadId}/messages`
  - **FCM Payload**: {data: {type: "chat_message", threadId, senderId, ...}}
  - **Acceptance**: Function executes on new message; FCM sent to recipient

- [ ] **T083** [US5] [Plan:4.4] Route FCM notification: in `NotificationService._navigateFromData()`, recognize "chat_message" data type → navigate to ChatDetail screen for that thread
  - **File Path**: `lib/app/services/notification_service.dart` (_navigateFromData method)
  - **Logic**: if (data['type'] == 'chat_message') → Get.toNamed(Routes.chatDetails, arguments: {threadId: data['threadId']})
  - **Acceptance**: Tap chat notification → opens correct ChatDetail

- [ ] **T084** [US5] [Plan:4.4] Test notification delivery: job seeker sends message to company (company not on chat screen) → company receives FCM → taps notification → navigates to ChatDetail → sees message
  - **File Path**: Integration test or manual QA
  - **Scenario**: Send chat message → recipient receives FCM → tap → navigate → verify message visible
  - **Acceptance**: Entire flow works

---

### 4.5 Initiate Chat from Job/Application

- [ ] **T085** [US5] [Plan:4.5] Implement "Message Company" button on `JobDetailsView`: tap → ChatThreadRepository.createThread(jobSeekerId, companyId) if not exists → navigate to ChatDetail
  - **File Path**: `lib/app/modules/job_seeker/job_details/job_details_view.dart`
  - **Action**: Tap "Message Company" → create or fetch existing thread → open ChatDetail
  - **Acceptance**: Button works; chat thread created/opened

- [ ] **T086** [US5] [Plan:4.5] Implement "Message Job Seeker" button on `ApplicationReviewView` (company): tap → ChatThreadRepository.createThread(jobSeekerId, companyId) if not exists → navigate to ChatDetail
  - **File Path**: `lib/app/modules/company/application_review/application_review_view.dart`
  - **Action**: Tap "Message" → create or fetch existing thread → open ChatDetail
  - **Acceptance**: Button works; chat thread created/opened

---

### 4.6 Testing (Manual Fakes)

- [ ] **T087** [US5] [Plan:4.6] Create `FakeChatRepository` in `test/fakes/fake_chat_repository.dart`: track sent messages with subcollection structure; validate merge: true
  - **File Path**: `test/fakes/fake_chat_repository.dart`
  - **Tracking**: Store messages in memory organized by threadId; validate merge: true on all writes
  - **Acceptance**: Fake simulates subcollection structure

- [ ] **T088** [US5] [Plan:4.6] Create test `test/chat_detail_controller_test.dart`: test message sending + stream listening with manual fakes
  - **File Path**: `test/chat_detail_controller_test.dart`
  - **Test Cases**:
    1. Send message → Firestore entry created
    2. Listen to messages stream → new message appears in observable
    3. Multiple messages in stream → ordered by timestamp
  - **Acceptance**: All test cases pass

- [ ] **T089** [US5] [Plan:4.6] Create test: FCM routing for "chat_message" → verify NotificationService navigates to correct ChatDetail thread
  - **File Path**: `test/notification_service_test.dart` (chat routing section)
  - **Test Scenario**: Mock FCM with chat_message data → call _navigateFromData() → verify route is ChatDetail with correct threadId
  - **Acceptance**: Routing test passes

---

## Phase 5: Company Dashboard & Application Management (10 Tasks)

### 5.1 Company Dashboard

- [ ] **T090** [US6] [Plan:5.1] Implement `CompanyDashboardController`: fetch all posted jobs → count applications per job → display analytics (total apps, pending, accepted, rejected)
  - **File Path**: `lib/app/modules/company/dashboard/company_dashboard_controller.dart`
  - **Observables**: `postedJobs` (RxList<Job>), `totalApplications` (RxInt), `applicationStats` (RxMap)
  - **Query**: Firestore.collection('jobs').where('companyId', isEqualTo: currentCompanyId)
  - **Analytics**: Calculate pending/accepted/rejected counts
  - **Acceptance**: Dashboard controller computes analytics

- [ ] **T091** [US6] [Plan:5.1] Implement dashboard view: display job list with application count + status badges (pending count, accepted count, etc.)
  - **File Path**: `lib/app/modules/company/dashboard/company_dashboard_view.dart`
  - **UI**: Job cards with app counts + badges; tap job to navigate to application list
  - **Acceptance**: View renders jobs with application counts

- [ ] **T092** [US6] [Plan:5.1] Implement analytics summary: display total applications, pending percentage, acceptance rate, recent activity
  - **File Path**: `lib/app/modules/company/dashboard/company_dashboard_view.dart` (analytics section)
  - **Metrics**: Total apps, pending %, accepted %, rejected %
  - **Acceptance**: Analytics section displays key metrics

---

### 5.2 Application List

- [ ] **T093** [US6] [Plan:5.2] Implement `ApplicationListController`: fetch all applications for company's posted jobs with applicant info
  - **File Path**: `lib/app/modules/company/application_list/application_list_controller.dart`
  - **Query**: Firestore.collection('applications').where jobIds in company's posted jobs
  - **Observable**: `applications` (RxList<Application>)
  - **Acceptance**: Controller fetches applications

- [ ] **T094** [US6] [Plan:5.2] Implement list view: applicant name, job title, application date, current status (pending/accepted/rejected)
  - **File Path**: `lib/app/modules/company/application_list/application_list_view.dart`
  - **UI**: List of application tiles with applicant info + status badge
  - **Tap Action**: Navigate to ApplicationReview for detailed view
  - **Acceptance**: List displays applications with all required info

- [ ] **T095** [US6] [Plan:5.2] Implement search/filter: filter by job, status, applicant name
  - **File Path**: `lib/app/modules/company/application_list/application_list_controller.dart`
  - **Filters**: filterByJob(), filterByStatus(), filterByName()
  - **Observables**: filteredApplications updated based on selected filters
  - **Acceptance**: Filters work; list updates correctly

---

### 5.3 Application Review Screen

- [ ] **T096** [US6] [Plan:5.3] Implement `ApplicationReviewController`: fetch single application + candidate profile + job details
  - **File Path**: `lib/app/modules/company/application_review/application_review_controller.dart`
  - **Queries**: Firestore.doc('applications/{appId}') + user profile + job details
  - **Observables**: `application`, `candidateProfile`, `jobDetails`
  - **Acceptance**: Controller fetches all required data

- [ ] **T097** [US6] [Plan:5.3] Implement CV preview: `flutter_pdfview` displays CV from Supabase Storage signed URL
  - **File Path**: `lib/app/modules/company/application_review/application_review_view.dart` (CV preview section)
  - **Widget**: PDFView(url: cvSignedUrl)
  - **Acceptance**: PDF renders in-app preview

- [ ] **T098** [US6] [Plan:5.3] Implement accept/reject buttons: tap accept/reject → ApplicationRepository.updateApplicationStatus() → Firestore updated + Cloud Function triggered
  - **File Path**: `lib/app/modules/company/application_review/application_review_view.dart` and controller
  - **Methods**: acceptApplication(), rejectApplication()
  - **Acceptance**: Buttons update Firestore status; Cloud Function executes

---

### 5.4 Testing (Manual Fakes)

- [ ] **T099** [US6] [Plan:5.4] Create test `test/company_dashboard_controller_test.dart`: test job fetching + analytics calculation with manual fakes
  - **File Path**: `test/company_dashboard_controller_test.dart`
  - **Test Cases**:
    1. Fetch company jobs
    2. Fetch applications for jobs
    3. Calculate analytics (totals, percentages)
  - **Acceptance**: All calculations correct

- [ ] **T100** [US6] [Plan:5.4] Create test `test/application_review_controller_test.dart`: test application review flow + accept/reject status updates
  - **File Path**: `test/application_review_controller_test.dart`
  - **Test Cases**:
    1. Fetch single application with candidate profile
    2. Accept application → status updates in Firestore
    3. Reject application → status updates in Firestore
  - **Acceptance**: All test cases pass

---

## Phase 6: Profile Management & User Settings (8 Tasks)

### 6.1 Job Seeker Profile Editing

- [ ] **T101** [US7] [Plan:6.1] Implement `JobSeekerProfileController`: edit skills, experience, main fields → Firestore with `SetOptions(merge: true)`
  - **File Path**: `lib/app/modules/job_seeker/profile/job_seeker_profile_controller.dart`
  - **Methods**: updateSkills(), updateExperience(), updateMainFields()
  - **Firestore**: All updates use SetOptions(merge: true)
  - **Acceptance**: Updates persist without overwriting other fields

- [ ] **T102** [US7] [Plan:6.1] Implement profile picture upload: image picker → Supabase Storage upload → Firestore reference update (merge: true)
  - **File Path**: `lib/app/modules/job_seeker/profile/job_seeker_profile_controller.dart`
  - **Flow**: Pick image → upload to `/profiles/{userId}/picture.jpg` → get signed URL → update Firestore profileUrl (merge: true)
  - **Acceptance**: Picture uploads; Firestore reference updated

- [ ] **T103** [US7] [Plan:6.1] Test concurrent profile updates: update skills while updating profile picture simultaneously → verify both persist (merge: true ensures no loss)
  - **File Path**: Integration test or manual QA
  - **Scenario**: Two concurrent updates to different fields → Firestore has both updates
  - **Acceptance**: No data lost; merge: true worked

---

### 6.2 Company Profile Editing

- [ ] **T104** [US7] [Plan:6.2] Implement `CompanyProfileController`: edit company name, description, location → Firestore with `SetOptions(merge: true)`
  - **File Path**: `lib/app/modules/company/company_profile/company_profile_controller.dart`
  - **Methods**: updateName(), updateDescription(), updateLocation()
  - **Firestore**: All updates use SetOptions(merge: true)
  - **Acceptance**: Updates persist correctly

- [ ] **T105** [US7] [Plan:6.2] Implement company logo upload: image picker → Supabase Storage → Firestore reference update (merge: true)
  - **File Path**: `lib/app/modules/company/company_profile/company_profile_controller.dart`
  - **Flow**: Pick logo → upload to `/companies/{companyId}/logo.jpg` → get signed URL → update Firestore logoUrl (merge: true)
  - **Acceptance**: Logo uploads; Firestore reference updated

- [ ] **T106** [US7] [Plan:6.2] Test profile persistence: edit company profile → logout/login → verify profile data loads correctly from Firestore
  - **File Path**: Integration test or manual QA
  - **Scenario**: Edit profile → logout → login → profile loads with updated data
  - **Acceptance**: Data persisted and loaded correctly

---

### 6.3 Testing (Manual Fakes)

- [ ] **T107** [US7] [Plan:6.3] Create test: profile update with merge: true validation → verify no field overwrites when updating individual fields
  - **File Path**: `test/profile_update_test.dart`
  - **Test Scenario**: 
    1. Set profile with fields A, B, C
    2. Update only field A (with merge: true)
    3. Verify B and C unchanged
  - **Acceptance**: Merge semantics validated

- [ ] **T108** [US7] [Plan:6.3] Create test `test/profile_controller_test.dart`: profile editing + picture upload + logout sequence validation
  - **File Path**: `test/profile_controller_test.dart`
  - **Test Cases**:
    1. Update profile fields
    2. Upload profile picture
    3. Logout with 4-step sequence verification
  - **Acceptance**: All tests pass

---

## Phase 7: Location-Based Map View & Saved Jobs (10 Tasks)

### 7.1 Jobs Map View

- [ ] **T109** [US8] [Plan:7.1] Implement `JobsMapController` (register via MainWrapperBinding with lazyPut): fetch all jobs with coordinates → initialize GoogleMap
  - **File Path**: `lib/app/modules/job_seeker/jobs_map/jobs_map_controller.dart`
  - **Mix-ins**: DistanceMixin
  - **Observable**: `mapJobs` (RxList<Job>)
  - **Registration**: MainWrapperBinding.lazyPut(() => JobsMapController())
  - **Acceptance**: Controller loads map jobs

- [ ] **T110** [US8] [Plan:7.1] Implement map markers: for each job with coordinates, create `Marker(position: LatLng(lat, lon), infoWindow: InfoWindow(title: jobTitle))`
  - **File Path**: `lib/app/modules/job_seeker/jobs_map/jobs_map_view.dart`
  - **GoogleMap Widget**: Display all job markers
  - **Acceptance**: Markers render on map

- [ ] **T111** [US8] [Plan:7.1] Implement marker tap: `Marker.onTap` callback → show InfoWindow with job title + "View Details" or navigate directly to JobDetail
  - **File Path**: `lib/app/modules/job_seeker/jobs_map/jobs_map_view.dart`
  - **Action**: Tap marker → InfoWindow appears or navigate to JobDetail
  - **Acceptance**: Marker interactions work

- [ ] **T112** [US8] [Plan:7.1] Test map performance: render 100+ job markers on single map → scroll and pan → verify no lag or frame drops
  - **File Path**: Performance test or manual QA
  - **Scenario**: Map with 100+ markers → perform scroll/pan operations
  - **Acceptance**: Smooth performance; no janky animation

---

### 7.2 Saved Jobs

- [ ] **T113** [US9] [Plan:7.2] Implement save job action: on JobDetailsView, tap "Save Job" button → add jobId to user's saved jobs list in Firestore (merge: true)
  - **File Path**: `lib/app/modules/job_seeker/job_details/job_details_controller.dart`
  - **Method**: saveJob(jobId) → Firestore.collection('users').doc(userId).update({savedJobs: FieldValue.arrayUnion([jobId])}, SetOptions(merge: true))
  - **Acceptance**: Job ID added to saved jobs

- [ ] **T114** [US9] [Plan:7.2] Implement `JobSeekerSavedJobsController` (register in MainWrapperBinding + MyApplicationsBinding with lazyPut): fetch saved job IDs from user profile → fetch full job documents from Firestore
  - **File Path**: `lib/app/modules/job_seeker/my_applications/job_seeker_saved_jobs_controller.dart`
  - **Bindings**: MainWrapperBinding.lazyPut(...), MyApplicationsBinding.lazyPut(...) (safe dedup)
  - **Observable**: `savedJobs` (RxList<Job>)
  - **Acceptance**: Controller loads saved jobs

- [ ] **T115** [US9] [Plan:7.2] Implement saved jobs tab: display saved jobs using `JobCardWidget` with distance parameter
  - **File Path**: `lib/app/modules/job_seeker/my_applications/views/saved_jobs_tab.dart`
  - **UI**: List of saved jobs; tap to view details
  - **Acceptance**: Tab displays saved jobs with distance

- [ ] **T116** [US9] [Plan:7.2] Implement unsave action: remove jobId from saved list in Firestore (merge: true)
  - **File Path**: `lib/app/modules/job_seeker/saved_jobs/saved_jobs_controller.dart`
  - **Method**: unsaveJob(jobId) → Firestore.update({savedJobs: FieldValue.arrayRemove([jobId])}, SetOptions(merge: true))
  - **Acceptance**: Job ID removed from saved jobs

---

### 7.3 Testing (Manual Fakes)

- [ ] **T117** [US8] [Plan:7.3] Create test: map rendering with 100+ markers → verify no performance issues
  - **File Path**: Performance test `test/map_performance_test.dart`
  - **Test Scenario**: Render map with 100+ markers → measure frame rate
  - **Acceptance**: Smooth rendering; fps > 55

- [ ] **T118** [US9] [Plan:7.3] Create test: save/unsave jobs → verify Firestore savedJobs array updates correctly
  - **File Path**: `test/saved_jobs_test.dart`
  - **Test Scenarios**:
    1. Save job → jobId added to array
    2. Unsave job → jobId removed from array
    3. Multiple save/unsave operations
  - **Acceptance**: All scenarios pass

---

## Phase 8: Notification Routing & Badge Management (8 Tasks)

### 8.1 Notification Badge Management

- [ ] **T119** [US10] [Plan:8.1] Implement `notification_count` observable in `NotificationService`: create `RxInt` to track unread notification count
  - **File Path**: `lib/app/services/notification_service.dart`
  - **Observable**: `notification_count` (RxInt, default 0)
  - **Acceptance**: Observable compiles; can be bound to UI

- [ ] **T120** [US10] [Plan:8.1] Implement badge increment: when FCM notification received → `notification_count.value++`
  - **File Path**: `lib/app/services/notification_service.dart` (onForegroundNotification handler)
  - **Logic**: Upon receipt, increment count
  - **Acceptance**: Badge count increases on notification

- [ ] **T121** [US10] [Plan:8.1] Implement badge reset: when user views notification or navigates to relevant screen → `notification_count.value = 0`
  - **File Path**: `lib/app/services/notification_service.dart` (reset method)
  - **Trigger**: Notification tap or screen navigation
  - **Acceptance**: Badge count resets to 0

- [ ] **T122** [US10] [Plan:8.1] Implement onError handler in stream subscriptions: if stream error occurs → reset `notification_count` to 0 (prevents permanent failure)
  - **File Path**: All stream subscriptions in chat, applications, notifications controllers
  - **Pattern**: `.listen(onData, onError: (e) { notification_count.value = 0; })`
  - **Acceptance**: Stream error doesn't break badge functionality

---

### 8.2 FCM Routing by Data Type

- [ ] **T123** [US10] [Plan:8.2] Verify `NotificationService._navigateFromData()` routes all 3 data types correctly:
  - "chat_message" → `Routes.chatDetails`
  - "application_update" → `Routes.myApplications`
  - "new_application" → `Routes.dashboard` (or home)
  - **File Path**: `lib/app/services/notification_service.dart` (_navigateFromData method)
  - **Test Scenario**: Mock FCM data for each type → verify route is correct
  - **Acceptance**: All 3 types route correctly

- [ ] **T124** [US10] [Plan:8.2] Test edge case: notification received while app in background → tap notification → correct screen opens
  - **File Path**: Integration test or manual QA
  - **Scenario**: App backgrounded → receive notification → tap notification → verify screen opens correctly
  - **Acceptance**: Navigation works from background

---

### 8.3 Testing (Manual Fakes)

- [ ] **T125** [US10] [Plan:8.3] Create test: badge stream error → verify onError handler resets badge to 0 (prevents permanent failure)
  - **File Path**: `test/notification_badge_test.dart`
  - **Test Scenario**: Stream subscription → emit error → verify badge reset
  - **Acceptance**: Badge recovers from error

- [ ] **T126** [US10] [Plan:8.3] Create test: FCM routing for all 3 data types
  - **File Path**: `test/fcm_routing_test.dart`
  - **Test Scenarios**:
    1. Route "chat_message" → ChatDetails
    2. Route "application_update" → MyApplications
    3. Route "new_application" → Dashboard
  - **Acceptance**: All routing tests pass

---

## Phase 9: Route Protection & Role-Based Access (8 Tasks)

### 9.1 Role Guard Middleware

- [ ] **T127** [US11] [Plan:9.1] Verify RoleGuardMiddleware blocks job seeker access to company routes: job seeker attempts to access `postJob`, `manageApplications` → redirect/block
  - **File Path**: `lib/app/middleware/role_guard_middleware.dart` (test scenario)
  - **Routes**: Routes.postJob, Routes.applicationList, Routes.applicationReview
  - **Acceptance**: Middleware blocks job seeker

- [ ] **T128** [US11] [Plan:9.1] Verify RoleGuardMiddleware blocks company access to job seeker routes: company attempts to access `dashboard` (job seeker), `applyJob` → redirect/block
  - **File Path**: `lib/app/middleware/role_guard_middleware.dart` (test scenario)
  - **Routes**: Routes.jobSeekerDashboard, Routes.applyJob, Routes.myApplications (job seeker)
  - **Acceptance**: Middleware blocks company

- [ ] **T129** [US11] [Plan:9.1] Verify public routes (pdf_viewer, maps, search_jobs) are accessible without authentication
  - **File Path**: `lib/app/routes/app_pages.dart` (route configuration)
  - **Routes**: Routes.pdfViewer, Routes.jobsMap, Routes.searchJobs
  - **Acceptance**: No middleware applied; routes accessible

- [ ] **T130** [US11] [Plan:9.1] Test access blocking: attempt unauthorized role access 100 times → verify 100% block rate (no leakage)
  - **File Path**: Stress test or automated test
  - **Scenario**: 100 unauthorized access attempts → 100 blocked
  - **Acceptance**: 100% block rate achieved

---

### 9.2 Route Configuration

- [ ] **T131** [US11] [Plan:9.2] Verify all protected routes use RoleGuardMiddleware in `app/routes/app_pages.dart`: company routes have CompanyGuard, job seeker routes have JobSeekerGuard
  - **File Path**: `lib/app/routes/app_pages.dart` (route definitions)
  - **Pattern**: GetPage(..., middlewares: [RoleGuardMiddleware()], ...)
  - **Acceptance**: All protected routes have middleware

- [ ] **T132** [US11] [Plan:9.2] Verify public routes have NO middleware: pdf_viewer, maps, search_jobs intentionally public
  - **File Path**: `lib/app/routes/app_pages.dart` (public route definitions)
  - **Verification**: grep for public routes → no middleware line
  - **Acceptance**: Public routes have no middleware

- [ ] **T133** [US11] [Plan:9.2] Test 100% unauthorized access blocking: all restricted route access attempts blocked; no role leakage
  - **File Path**: Automated test or manual QA
  - **Scenario**: Try all combinations of role + route → verify blocking
  - **Acceptance**: 100% success rate on blocking

---

### 9.3 Testing (Manual Fakes)

- [ ] **T134** [US11] [Plan:9.3] Create test `test/role_guard_middleware_test.dart`: verify middleware blocks unauthorized role access for all restricted routes
  - **File Path**: `test/role_guard_middleware_test.dart`
  - **Test Cases**:
    1. Job seeker blocked from company routes (10 routes)
    2. Company blocked from job seeker routes (10 routes)
    3. Public routes accessible (3 routes)
  - **Acceptance**: All test cases pass

---

## Phase 10: Password Recovery & Session Management (10 Tasks)

### 10.1 Password Recovery

- [ ] **T135** [US12] [Plan:10.1] Verify forgot password flow: user enters email → `Supabase.auth.resetPasswordForEmail(email)` sends recovery email
  - **File Path**: `lib/app/modules/auth/forgot_password/forgot_password_controller.dart` and view
  - **UI**: Email input → "Send Reset Link" button
  - **Acceptance**: Email received by user

- [ ] **T136** [US12] [Plan:10.1] Verify reset password: user receives email → clicks link → password reset page loads → user enters new password → confirmation
  - **File Path**: Deep link handler or email link callback
  - **Flow**: Email link → app opens reset screen → user enters new password → submit → Supabase updates password
  - **Acceptance**: Password reset page loads; new password accepted

- [ ] **T137** [US12] [Plan:10.1] Test login with new password: after password reset, user can login with new password → auth token issued
  - **File Path**: Integration test or manual QA
  - **Scenario**: Reset password → login with new password → dashboard loads
  - **Acceptance**: Login succeeds with new password

---

### 10.2 Logout & Session Cleanup

- [ ] **T138** [US12] [Plan:10.2] Verify logout sequence (ProfileController around line ~800-811):
  1. `Firestore.collection('users/{userId}/settings').update({fcmToken: FieldValue.delete()})`
  2. `FirebaseMessaging.instance.deleteToken()`
  3. `Supabase.auth.clearAuthSession()`
  4. `Supabase.auth.signOut()`
  - **File Path**: `lib/app/modules/profile/profile_controller.dart` (logout method, ~800-811)
  - **Verification**: Each step executes in order; no exceptions
  - **Acceptance**: All 4 steps complete successfully

- [ ] **T139** [US12] [Plan:10.2] Verify no residual auth state: after logout → cannot access protected routes → redirect to login screen
  - **File Path**: Integration test or manual QA
  - **Scenario**: Logout → try to access protected route → redirected to login
  - **Acceptance**: Auth state properly cleared

- [ ] **T140** [US12] [Plan:10.2] Test multi-device logout: logout on Device A → verify Device A receives NO notifications; new login on Device A creates new FCM token
  - **File Path**: Integration test or manual QA
  - **Scenario**: Device A logout → Device A silent; Device B active; Device A login → new token; both devices isolated
  - **Acceptance**: Each device has independent session

---

### 10.3 Token Refresh

- [ ] **T141** [US12] [Plan:10.3] Verify auto-refresh: Supabase auth token expires (or simulated) → next API call auto-refreshes → no manual intervention
  - **File Path**: Integration test or manual verification
  - **Test Scenario**: Make API call → wait for token expiry → make another call → observe refresh in background
  - **Acceptance**: Token auto-refreshes; session continues

- [ ] **T142** [US12] [Plan:10.3] Test edge case: logout after token expiry → verify session properly cleared (no stale token issues)
  - **File Path**: Integration test
  - **Scenario**: Wait for token expiry → logout → verify no stale token state
  - **Acceptance**: Logout succeeds even with expired token

---

### 10.4 Testing (Manual Fakes)

- [ ] **T143** [US12] [Plan:10.4] Create test: logout sequence validation → verify all 4 steps execute in correct order
  - **File Path**: `test/logout_sequence_test.dart`
  - **Test Scenario**: Call logout() → verify each step executed → verify final state (no auth, no FCM token)
  - **Acceptance**: Sequence validated

- [ ] **T144** [US12] [Plan:10.4] Create test: password reset flow with manual fakes
  - **File Path**: `test/password_reset_test.dart`
  - **Test Scenarios**:
    1. Request password reset → email triggered
    2. Reset password → new password stored
    3. Login with new password → succeeds
  - **Acceptance**: All scenarios pass

---

## Phase 11: Code Quality & Architecture Compliance (11 Tasks)

### 11.1 Code Review Checklist

- [ ] **T145** [Plan:11.1] Verify all controllers inherit `GetxController` (no exceptions): grep for `class.*Controller extends GetxController`
  - **File Path**: All controllers in `lib/app/modules/`
  - **Verification**: No `class.*extends Controller` or direct instantiation
  - **Acceptance**: 100% GetxController inheritance

- [ ] **T146** [Plan:11.1] Verify all Firestore writes use `SetOptions(merge: true)`: grep for `.set(` and `.update(` in repositories
  - **File Path**: All repositories in `lib/core/repositories/`
  - **Verification**: Every `.set()` call has `SetOptions(merge: true)` parameter; no plain `.set()` calls
  - **Acceptance**: 100% merge: true compliance

- [ ] **T147** [Plan:11.1] Verify all routes import from `app/routes/app_pages.dart` (Routes.* namespace): grep for `import.*app_routes.dart`
  - **File Path**: All controllers and views
  - **Verification**: No direct imports of `app_routes.dart`; only `Routes.*` usage
  - **Acceptance**: All routes use correct namespace

- [ ] **T148** [Plan:11.1] Verify all services registered via `Get.putAsync` in main.dart (not Get.put)
  - **File Path**: `lib/main.dart` (entrypoint)
  - **Verification**: StorageService and NotificationService use `Get.putAsync()`
  - **Acceptance**: Services registered asynchronously

- [ ] **T149** [Plan:11.1] Verify all tests use manual fakes (no Mockito/Mocktail imports)
  - **File Path**: All test files in `test/`
  - **Verification**: grep for `import.*mockito` or `import.*mocktail` → zero results
  - **Acceptance**: No mocking framework imports found

- [ ] **T150** [Plan:11.1] Verify all test tearDown calls `Get.reset()` (or setUp if setUp registers controllers)
  - **File Path**: All test files in `test/`
  - **Verification**: Every test file has `tearDown(Get.reset())` or `setUp(Get.reset())`
  - **Acceptance**: 100% Get.reset() coverage in tests

---

### 11.2 Build & Analyze

- [ ] **T151** [Plan:11.2] Run `flutter pub get` → resolve all dependencies
  - **Command**: `flutter pub get`
  - **Acceptance**: No resolution errors; all packages installed

- [ ] **T152** [Plan:11.2] Run `flutter analyze --no-fatal-infos --no-fatal-warnings` → zero violations
  - **Command**: `flutter analyze --no-fatal-infos --no-fatal-warnings`
  - **Acceptance**: "No issues found" output

- [ ] **T153** [Plan:11.2] Run `flutter test --no-pub` → all tests passing
  - **Command**: `flutter test --no-pub`
  - **Acceptance**: All tests pass; coverage meets requirements

- [ ] **T154** [Plan:11.2] Run `flutter build apk --release` → release APK generated
  - **Command**: `flutter build apk --release`
  - **Output**: `build/app/outputs/flutter-apk/app-release.apk` exists
  - **Acceptance**: APK builds successfully

---

### 11.3 Documentation & Runbooks

- [ ] **T155** [Plan:11.3] Update AGENTS.md with any new gotchas discovered during implementation
  - **File Path**: `AGENTS.md` (project root or root of workspace)
  - **Content**: Add new patterns, gotchas, conventions discovered
  - **Acceptance**: AGENTS.md updated; developers can reference new patterns

- [ ] **T156** [Plan:11.3] Create test runbook: document how to run tests locally + in CI
  - **File Path**: `docs/TESTING.md` or README.md section
  - **Content**: Test commands, environment setup, troubleshooting
  - **Acceptance**: Runbook enables team to run tests easily

- [ ] **T157** [Plan:11.3] Create deployment guide: Firebase deploy commands for functions, RTDB, Firestore indexes
  - **File Path**: `docs/DEPLOYMENT.md` or README.md section
  - **Content**: Step-by-step deployment commands, verification steps
  - **Acceptance**: Team can deploy to Firebase following runbook

---

## Execution Guidance

### Task Execution Order

1. **Phase 0** must complete before all others (setup is blocking)
2. **Within each phase**, foundational tasks (models, repositories, services) before UI controllers
3. **Parallelizable tasks** ([P] marker) can run simultaneously on different files
4. **User story phases** can overlap after Phase 1 (auth is prerequisite for all)

### Dependency Chain

```
Phase 0 (Setup)
  ↓
Phase 1 (Auth) + Phase 2 (Discovery) [can overlap after P1.1-P1.3]
  ↓
Phase 3 (Applications) + Phase 4 (Chat) + Phase 5 (Company) [can overlap]
  ↓
Phase 6 (Profiles) + Phase 7 (Maps) [can overlap]
  ↓
Phase 8 (Notifications) + Phase 9 (Routes) [can overlap]
  ↓
Phase 10 (Password & Session)
  ↓
Phase 11 (Quality & Compliance) [final gate]
```

### Testing Strategy

- **Manual fakes only**: No Mockito/Mocktail
- **Get.reset() required**: In all test tearDown methods
- **No Firebase init in tests**: Services mocked via manual fakes
- **Test coverage target**: >80% for all controllers, repositories, services

### Deployment Checkpoints

- After T154 (build apk): Code is production-ready for APK release
- After T157 (deployment guide): Team can deploy to Firebase
- After Phase 11 completion: Full feature release ready

---

**End of Task Breakdown**

Total: **157 tasks** across **11 phases** | **100% requirement coverage** | **All architecture principles verified**
