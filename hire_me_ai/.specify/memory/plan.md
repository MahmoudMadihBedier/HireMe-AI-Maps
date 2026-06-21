# Implementation Plan: HireMe Recruitment Platform

**Branch**: `feature/maps-ai` | **Date**: 2026-06-21 | **Spec**: `/spec.md`

**Input**: Feature specification defining job seeker + company recruitment platform with authentication, job discovery, applications, real-time chat, and location-based features.

## Summary

HireMe is a Flutter GetX mobile recruitment platform connecting job seekers with companies. Core flows: dual-role authentication (Job Seeker / Company), job discovery with distance filtering, application tracking, real-time chat, and profile management. Backend: Supabase Auth (PKCE) + Firebase (Firestore, RTDB, FCM) + Supabase Storage. Delivery strategy: foundational services first (Auth, Firestore persistence), then P1 user stories (authentication, discovery, applications, chat), then P2 features (profiles, maps, saved jobs, notifications). All Firestore writes use `merge: true`; all controllers inherit `GetxController`; manual fakes only in tests.

## Technical Context

**Language/Version**: Dart 3.11+, Flutter 3.41.6

**Primary Dependencies**: GetX (state management), Firebase (Firestore, RTDB, FCM, Auth), Supabase (Auth PKCE, Storage), google_maps_flutter (maps), geolocator (location), geocoding (reverse geocoding), firebase_storage, cloud_firestore, firebase_messaging, firebase_auth, firebase_database, image_picker, flutter_pdfview

**Storage**: Firestore (primary data store, must use merge: true), Firebase RTDB (real-time messaging), Supabase Storage (file uploads, profile images, CVs)

**Testing**: flutter test with manual fakes (NO Mockito/Mocktail); Get.reset() in tearDown

**Target Platform**: Android only (iOS/macOS/Windows/Linux are Flutter template defaults)

**Project Type**: Mobile app (Flutter)

**Performance Goals**: Job search <2s, chat delivery <2s, FCM delivery <30s, map rendering 100+ markers, 1000 concurrent users

**Constraints**: Offline-first cache, merge-safe Firestore writes, role-based route guards, FCM badge recovery on error, location permission optional

**Scale/Scope**: 2 roles (Job Seeker, Company), 12 user stories (5 P1, 7 P2), 49 functional requirements, 6 entities, 14 success criteria

## Constitution Check

✅ **GetX State Management Purity**: All controllers inherit `GetxController`, registered via Bindings, never direct `Get.put` in UI.

✅ **Firestore Merge Semantics (NON-NEGOTIABLE)**: Every Firestore write MUST use `SetOptions(merge: true)`; plain `set()` forbidden.

✅ **Firebase + Supabase Dual-Backend**: Firebase (auth, Firestore, FCM), Supabase (PKCE auth, storage). Logout sequence: delete FCM token → deleteToken() → clearAuthSession() → signOut().

✅ **Manual Testing Only**: Manual fakes, no Mockito/Mocktail; Get.reset() in tearDown.

✅ **Notification Data Routing & Badge Integrity**: 3 data types (chat_message, application_update, new_application); stream onError handlers MUST reset badge.

✅ **Modular Feature-First Architecture**: Features under `app/modules/{role}/{feature}/` with bindings.

✅ **Route Guards & Role-Based Access**: RoleGuardMiddleware for protected routes; public routes (pdf_viewer, maps) intentionally unguarded.

✅ **Configuration & Secrets**: `.env`, `firebase_options.dart`, `google-services.json` locked; never commit real credentials.

## Applied Guidelines

**GetX Architecture Patterns** (from AGENTS.md):
- Controller registration via Binding classes (not direct Get.put)
- LazyPut for deferred controllers (JobsMapController, JobSeekerSavedJobsController)
- Service layer (StorageService, NotificationService) registered in main.dart via Get.putAsync
- DistanceMixin for shared location/distance calculations (JobSeekerDashboardController, JobSeekerSearchJobsController, JobsMapController)

**Firestore Best Practices**:
- All writes use SetOptions(merge: true) to prevent concurrent write conflicts
- Subcollections for normalized data (messages under chat threads, applications under users)
- Timestamps for sorting and CDC events (onApplicationAccepted, onApplicationRejected, onNewChatMessage)

**Firebase Cloud Messaging**:
- Notification data types: chat_message, application_update, new_application
- Background handler: FirebaseMessaging.onBackgroundMessage (set before dotenv.load)
- Stream subscription error handlers reset badge count to 0 to prevent permanent failure
- FCM token cleanup on logout is MANDATORY (4-step sequence)

**File Storage**:
- Supabase Storage for all uploads (firebase_storage in pubspec.yaml is unused)
- Signed URLs for CV preview and profile images
- Structured path: `/uploads/{userId}/{type}/{timestamp}` for organization

## Project Structure

### Documentation (this feature)

```text
hire_me_ai/.specify/memory/
├── constitution.md      # HireMe governance (v1.0.0, ratified 2026-06-21)
├── spec.md             # Feature specification (12 user stories, 49 requirements)
└── plan.md             # This file (implementation phases + task breakdown)
```

### Source Code (lib/)

```text
lib/
├── main.dart                          # Entrypoint: Firebase/Supabase init, GetX services
├── firebase_options.dart              # Generated by flutterfire configure (DO NOT EDIT)
│
├── app/
│   ├── routes/
│   │   ├── app_pages.dart            # Routes.* constants (import this)
│   │   └── app_routes.dart           # part of app_pages.dart (DO NOT import directly)
│   │
│   ├── middleware/
│   │   └── role_guard_middleware.dart # RoleGuardMiddleware for protected routes
│   │
│   ├── services/
│   │   ├── storage_service.dart      # Supabase Storage abstraction (Get.putAsync in main)
│   │   └── notification_service.dart # FCM routing + badge management (Get.putAsync in main)
│   │
│   ├── bindings/
│   │   ├── main_wrapper_binding.dart # JobsMapController (lazyPut), JobSeekerSavedJobsController (lazyPut)
│   │   ├── job_seeker_my_applications_binding.dart # JobSeekerSavedJobsController (lazyPut - dedup OK)
│   │   └── [other role-specific bindings]
│   │
│   └── modules/
│       ├── auth/
│       │   ├── splash/
│       │   ├── onboarding/
│       │   ├── login/
│       │   ├── register/
│       │   ├── role_selector/
│       │   ├── forgot_password/
│       │   └── select_user/
│       │
│       ├── job_seeker/
│       │   ├── dashboard/                        # JobSeekerDashboardController + DistanceMixin
│       │   ├── search_jobs/                      # JobSeekerSearchJobsController + DistanceMixin
│       │   ├── job_details/
│       │   ├── apply_job/
│       │   ├── my_applications/
│       │   │   ├── job_seeker_my_applications_controller.dart
│       │   │   ├── job_seeker_saved_jobs_controller.dart (registered in MainWrapperBinding + MyApplicationsBinding)
│       │   │   └── views/ (tabs: All, Pending, Accepted, Rejected, Saved Jobs)
│       │   ├── saved_jobs/                      # JobCardWidget shared view
│       │   ├── jobs_map/                        # JobsMapController + DistanceMixin
│       │   ├── chat/
│       │   ├── chat_details/
│       │   ├── main_fields/
│       │   └── shared/
│       │       ├── distance_mixin.dart          # userPosition, jobDistances, getDistanceToCompany()
│       │       └── job_card_widget.dart         # Shared job display with distance parameter
│       │
│       ├── company/
│       │   ├── dashboard/                        # CompanyDashboardController
│       │   ├── post_job/
│       │   ├── application_list/
│       │   ├── application_review/               # PDF viewer (flutter_pdfview)
│       │   ├── company_profile/
│       │   ├── company_chat/
│       │   ├── company_chat_details/
│       │   └── company_main_wrapper/
│       │
│       ├── profile/
│       │   └── profile_controller.dart           # Logout sequence (lines ~800-811)
│       │
│       └── shared_widgets/                       # Cross-role shared widgets
│
├── core/
│   ├── models/
│   │   ├── user.dart                 # Job seeker user (Firestore document)
│   │   ├── company.dart              # Company recruiter (Firestore document)
│   │   ├── job.dart                  # Job posting (Firestore document with coords)
│   │   ├── application.dart          # Job application (Firestore document)
│   │   ├── chat_thread.dart          # Chat thread (Firestore document)
│   │   └── chat_message.dart         # Chat message (Firestore subcollection)
│   │
│   ├── utils/
│   │   ├── app_assets.dart           # Auto-generated (DO NOT EDIT)
│   │   ├── app_color.dart
│   │   ├── app_string.dart
│   │   ├── custom_textstyle.dart
│   │   └── constants.dart
│   │
│   ├── widgets/
│   │   └── [shared UI components]
│   │
│   └── helper/
│       └── [utility helpers]

test/
├── [all manual fakes, no Mockito]
└── [test files mirror module structure]
```

## Implementation Phases

### Phase 0: Setup & Foundations

Establish project environment, core services, and infrastructure for authentication + persistence.

#### 0.1 Environment & Configuration
- [ ] T001 [Plan:0.1] Verify Flutter 3.41.6, Dart 3.11+, Java 17; ensure pubspec.yaml has all dependencies (GetX, Firebase, Supabase, geolocator, google_maps_flutter, etc.)
- [ ] T002 [Plan:0.1] Create `.env` file with SUPABASE_URL and SUPABASE_ANON_KEY (git-ignored)
- [ ] T003 [Plan:0.1] Run `flutterfire configure` to regenerate firebase_options.dart; verify android/app/google-services.json exists (git-ignored)
- [ ] T004 [Plan:0.1] Create analysis_options.yaml with lint rules; run `flutter analyze --no-fatal-infos --no-fatal-warnings` to verify baseline

#### 0.2 Service Layer Foundation
- [ ] T005 [Plan:0.2] Implement `StorageService` abstraction (Supabase Storage upload/download, signed URLs) in `app/services/storage_service.dart`
- [ ] T006 [Plan:0.2] Implement `NotificationService` core (FCM routing, NotificationService._navigateFromData for 3 data types, badge count observable) in `app/services/notification_service.dart`
- [ ] T007 [Plan:0.2] Update `main.dart` entrypoint: FirebaseMessaging.onBackgroundMessage (before dotenv.load) → dotenv.load → Firebase.initializeApp + Supabase.initialize (parallel Future.wait) → Get.putAsync(StorageService) → Get.putAsync(NotificationService) → runApp

#### 0.3 Middleware & Route Scaffolding
- [ ] T008 [Plan:0.3] Implement `RoleGuardMiddleware` in `app/middleware/role_guard_middleware.dart` to block unauthorized role access
- [ ] T009 [Plan:0.3] Create route constants in `app/routes/app_pages.dart` (Routes.* namespace) for all 40+ routes; mark public routes (pdf_viewer, maps, search_jobs) with no middleware
- [ ] T010 [Plan:0.3] Scaffold binding classes: `MainWrapperBinding`, `JobSeekerBinding`, `JobSeekerMyApplicationsBinding`, `CompanyBinding` with lazyPut registrations for deferred controllers

#### 0.4 Core Models & Base Classes
- [ ] T011 [Plan:0.4] Create Firestore data models (User, Company, Job, Application, ChatThread, ChatMessage) in `core/models/` with Firestore serialization (toMap/fromMap)
- [ ] T012 [Plan:0.4] Implement `GetxController` base class wrapper if needed (future extension point for common logic)
- [ ] T013 [Plan:0.4] Create `GetxBinding` base class for common binding patterns (GetX deduplication validation)

---

### Phase 1: Authentication & Session Management (P1 User Stories 1 & 2)

Enable job seekers and company recruiters to register, log in, set up profiles, and manage sessions with proper Firestore persistence and FCM token registration.

#### 1.1 Supabase Auth Integration
- [ ] T014 [US1] [Plan:1.1] Implement Supabase PKCE auth flow in AuthController (Supabase.initialize with AuthFlowType.pkce, autoRefreshToken: true)
- [ ] T015 [US1] [Plan:1.1] Implement signup (AuthController.signup) for both roles: email → password → Supabase Auth.signUp
- [ ] T016 [US1] [Plan:1.1] Implement login (AuthController.login): email → password → Supabase Auth.signInWithPassword → return auth token
- [ ] T017 [US1] [Plan:1.1] Implement password recovery (AuthController.resetPassword): email → Supabase.auth.resetPasswordForEmail → email link flow
- [ ] T018 [US1] [Plan:1.1] Verify auto-refresh token mechanism works: logout after token expiry → auto-refresh should renew session

#### 1.2 Firestore Profile Creation & Persistence
- [ ] T019 [US1] [Plan:1.2] Create job seeker profile after signup: JobSeekerProfileController → Firestore.collection('users').doc(userId).set({...}, SetOptions(merge: true))
- [ ] T020 [US1] [Plan:1.2] Create company profile after signup: CompanyProfileController → Firestore.collection('companies').doc(companyId).set({...}, SetOptions(merge: true))
- [ ] T021 [US1] [Plan:1.2] Implement profile update controller: edit skills, main fields, company description → Firestore with merge: true (verify no field overwrites)
- [ ] T022 [US1] [Plan:1.2] Test concurrent profile updates: update field A and B simultaneously → both persist (merge: true ensures no loss)

#### 1.3 FCM Token Management
- [ ] T023 [US1] [Plan:1.3] On login, register FCM token: getToken() → Firestore.collection('users/{userId}/settings').set({fcmToken: token}, SetOptions(merge: true))
- [ ] T024 [US1] [Plan:1.3] On logout, delete FCM token (4-step sequence): Firestore.collection('users/{userId}/settings').update({fcmToken: FieldValue.delete()}) → FirebaseMessaging.deleteToken() → Supabase.auth.clearAuthSession() → Supabase.auth.signOut()
- [ ] T025 [US1] [Plan:1.3] Test logout flow: logout → verify FCM token removed from Firestore → no notifications received post-logout

#### 1.4 Splash & Onboarding
- [ ] T026 [US1] [Plan:1.4] Implement SplashController: check Supabase auth status on app launch → redirect to onboarding (no auth) or dashboard (authenticated)
- [ ] T027 [US1] [Plan:1.4] Implement OnboardingController: role selection (Job Seeker / Company) → navigate to role-specific signup flow
- [ ] T028 [US1] [Plan:1.4] Implement RoleSelector view: Job Seeker / Company buttons → set user role in observable

#### 1.5 Session Persistence & Auto-Refresh
- [ ] T029 [US1] [Plan:1.5] Verify Supabase auth token auto-refresh: logout session → wait for expiry → next API call should auto-refresh → no manual intervention needed
- [ ] T030 [US1] [Plan:1.5] Test edge case: logout on Device A → verify Device B receives no notifications (new FCM token only registered on Device B's login)

#### 1.6 Testing (Manual Fakes)
- [ ] T031 [US1] [Plan:1.6] Create manual fakes for Supabase Auth (no Mockito): FakeSupabaseAuth with signup/login/signOut methods → simulate token refresh
- [ ] T032 [US1] [Plan:1.6] Create manual fakes for Firestore: FakeFirestoreService with merge: true validation → reject plain set() calls
- [ ] T033 [US1] [Plan:1.6] Create test: `auth_login_controller_test.dart` with manual fakes → verify token persistence + profile creation + FCM token registration
- [ ] T034 [US1] [Plan:1.6] Create test: logout flow → verify FCM token deletion sequence + no residual auth state

---

### Phase 2: Job Discovery & Distance Filtering (P1 User Story 3)

Enable job seekers to browse jobs, search by title/company, filter by distance from their location, and view detailed job information including maps.

#### 2.1 Location & Distance Mixin
- [ ] T035 [US3] [Plan:2.1] Implement DistanceMixin in `app/modules/job_seeker/shared/distance_mixin.dart`: userPosition (Geolocator capture), jobDistances (computed Observable), getDistanceToCompany(), updateJobDistancesFrom()
- [ ] T036 [US3] [Plan:2.1] Request location permission: Geolocator.requestPermission() → store in userPosition observable
- [ ] T037 [US3] [Plan:2.1] Implement distance calculation: Geolocator.distanceBetween(lat1, lon1, lat2, lon2) → store in jobDistances map
- [ ] T038 [US3] [Plan:2.1] Test location permission denied: verify app functions without distance (toggle greyed out)

#### 2.2 Job Dashboard & Search
- [ ] T039 [US3] [Plan:2.2] Implement JobSeekerDashboardController with DistanceMixin: fetch all jobs → display in list with distance (if available)
- [ ] T040 [US3] [Plan:2.2] Implement JobSeekerSearchJobsController with DistanceMixin: search textfield → Firestore query by title/company/keyword → filter by distance if enabled
- [ ] T041 [US3] [Plan:2.2] Implement sort toggle: "Sort by Distance" observable → if enabled, sort jobs by distance; jobs with null distance sort last
- [ ] T042 [US3] [Plan:2.2] Test search performance: 100+ jobs in Firestore → search returns results in <2s

#### 2.3 Job Card Widget & Details
- [ ] T043 [US3] [Plan:2.3] Implement JobCardWidget in `app/modules/job_seeker/shared/job_card_widget.dart`: displays title, company, location, salary, distance parameter (can be null)
- [ ] T044 [US3] [Plan:2.3] Implement JobDetailsController: fetch full job description → display company profile + location on map
- [ ] T045 [US3] [Plan:2.3] Implement JobDetailsView: show job title, description, requirements, company logo, salary, apply button

#### 2.4 Google Map Integration
- [ ] T046 [US3] [Plan:2.4] Implement GoogleMap widget in job details: display job location marker via google_maps_flutter
- [ ] T047 [US3] [Plan:2.4] Implement marker tap handling: Marker.onTap callback → show InfoWindow or navigate to job details
- [ ] T048 [US3] [Plan:2.4] Implement geocoding for reverse lookup: company location (lat/lon) → address string via geocoding package (company_map_controller only)
- [ ] T049 [US3] [Plan:2.4] Test map rendering: 100+ markers on single map → no lag or janky scrolling

#### 2.5 Testing (Manual Fakes)
- [ ] T050 [US3] [Plan:2.5] Create FakeGeolocator for location: mock userPosition, distance calculations → no real GPS needed in tests
- [ ] T051 [US3] [Plan:2.5] Create test: `job_seeker_dashboard_controller_test.dart` with manual fakes → verify distance sorting + null distance handling
- [ ] T052 [US3] [Plan:2.5] Create test: search with distance filter → verify correct job ordering

---

### Phase 3: Job Applications & Status Tracking (P1 User Story 4)

Enable job seekers to apply for jobs, upload CVs, and track application status; enable companies to receive notifications and manage applications.

#### 3.1 Application Creation & Submission
- [ ] T053 [US4] [Plan:3.1] Implement ApplyJobController: capture CV upload → upload to Supabase Storage → create Firestore application document with status: "pending"
- [ ] T054 [US4] [Plan:3.1] Implement CV upload: file picker → Supabase Storage upload (path: `/applications/{jobId}/{userId}/{timestamp}.pdf`) → return signed URL
- [ ] T055 [US4] [Plan:3.1] Test application creation: apply for job → Firestore document created with correct structure (merge: true)
- [ ] T056 [US4] [Plan:3.1] Test CV upload: upload CV → verify file appears in Supabase Storage + signed URL is accessible

#### 3.2 Firestore Application Persistence
- [ ] T057 [US4] [Plan:3.2] Create Application model with Firestore serialization: toMap/fromMap for fields (jobId, userId, status, cvUrl, timestamp)
- [ ] T058 [US4] [Plan:3.2] Implement repository: ApplicationRepository.createApplication() with SetOptions(merge: true) to prevent overwrites
- [ ] T059 [US4] [Plan:3.2] Test concurrent applications: multiple job seekers apply simultaneously → all applications persist without loss

#### 3.3 Application Status Updates (Company-Side)
- [ ] T060 [US4] [Plan:3.3] Implement ApplicationReviewController: fetch all applications for company's posted jobs → display in list
- [ ] T061 [US4] [Plan:3.3] Implement accept/reject action: company taps accept/reject → Firestore application.status updated → Cloud Function triggered
- [ ] T062 [US4] [Plan:3.3] Verify Cloud Function execution: onApplicationAccepted/onApplicationRejected functions execute (external verification via Firebase Console)

#### 3.4 Notification Routing for Application Updates
- [ ] T063 [US4] [Plan:3.4] Implement FCM notification on application_update: Cloud Function sends FCM with data type: "application_update"
- [ ] T064 [US4] [Plan:3.4] Route notification in NotificationService._navigateFromData: "application_update" → navigate to MyApplications screen
- [ ] T065 [US4] [Plan:3.4] Test end-to-end: accept application → job seeker receives FCM → navigates to My Applications → sees status change

#### 3.5 My Applications View
- [ ] T066 [US4] [Plan:3.5] Implement JobSeekerMyApplicationsController: tabs (All, Pending, Accepted, Rejected)
- [ ] T067 [US4] [Plan:3.5] Implement Saved Jobs tab: JobSeekerSavedJobsController (registered in MainWrapperBinding + MyApplicationsBinding for lazyPut dedup)
- [ ] T068 [US4] [Plan:3.5] Implement saved job display: JobCardWidget with distance parameter for saved jobs

#### 3.6 Testing (Manual Fakes)
- [ ] T069 [US4] [Plan:3.6] Create FakeApplicationRepository: track created applications with merge: true semantics
- [ ] T070 [US4] [Plan:3.6] Create FakeStorageService: mock CV upload → return mock signed URL
- [ ] T071 [US4] [Plan:3.6] Create test: `application_review_controller_test.dart` → verify application status update flow

---

### Phase 4: Real-Time Chat (P1 User Story 5)

Enable job seekers and companies to initiate chats, exchange messages in real-time, and receive notifications.

#### 4.1 Chat Thread & Message Models
- [ ] T072 [US5] [Plan:4.1] Create ChatThread model: Firestore document with participants (jobSeekerId, companyId), createdAt, lastMessage, lastMessageAt
- [ ] T073 [US5] [Plan:4.1] Create ChatMessage model: Firestore subcollection (messages) with senderId, content, timestamp, readStatus
- [ ] T074 [US5] [Plan:4.1] Implement ChatThreadRepository: createThread(), getThreads(), updateLastMessage()
- [ ] T075 [US5] [Plan:4.1] Implement ChatMessageRepository: sendMessage() with SetOptions(merge: true), getMessages() stream

#### 4.2 Chat List & Detail Screens
- [ ] T076 [US5] [Plan:4.2] Implement ChatListController: fetch all chat threads for current user → display with last message preview + timestamp
- [ ] T077 [US5] [Plan:4.2] Implement ChatDetailController: fetch chat thread + messages stream → listen for new messages in real-time
- [ ] T078 [US5] [Plan:4.2] Implement ChatDetailView: message list + input field → send message → message appears instantly (Firestore stream)

#### 4.3 Message Sending & Persistence
- [ ] T079 [US5] [Plan:4.3] Implement sendMessage(): user taps send → ChatMessageRepository.sendMessage() creates document in messages subcollection with timestamp
- [ ] T080 [US5] [Plan:4.3] Implement message stream listener: Firestore.collection('chats/{threadId}/messages').orderBy('timestamp').snapshots() → update UI in real-time
- [ ] T081 [US5] [Plan:4.3] Test concurrent messages: both parties send simultaneously → all messages persist in order

#### 4.4 Message Notifications (FCM)
- [ ] T082 [US5] [Plan:4.4] Implement onNewChatMessage Cloud Function: listen for new messages → send FCM with data type: "chat_message"
- [ ] T083 [US5] [Plan:4.4] Route FCM notification: NotificationService._navigateFromData recognizes "chat_message" → navigate to ChatDetail screen
- [ ] T084 [US5] [Plan:4.4] Test notification delivery: send message from company → job seeker (if not on chat screen) receives FCM + navigates to chat detail

#### 4.5 Initiate Chat from Job/Application
- [ ] T085 [US5] [Plan:4.5] Implement "Message Company" button on JobDetailsView: tap → create ChatThread if not exists → navigate to ChatDetail
- [ ] T086 [US5] [Plan:4.5] Implement "Message Job Seeker" button on ApplicationReviewView (company): tap → create ChatThread if not exists → navigate to ChatDetail

#### 4.6 Testing (Manual Fakes)
- [ ] T087 [US5] [Plan:4.6] Create FakeChatRepository: track sent messages with subcollection structure
- [ ] T088 [US5] [Plan:4.6] Create test: `chat_detail_controller_test.dart` → verify message sending + stream listening
- [ ] T089 [US5] [Plan:4.6] Create test: FCM routing for chat_message → verify NotificationService navigates correctly

---

### Phase 5: Company Dashboard & Application Management (P2 User Story 6)

Enable company recruiters to view all applications, review candidates, and change application statuses.

#### 5.1 Company Dashboard
- [ ] T090 [US6] [Plan:5.1] Implement CompanyDashboardController: fetch all posted jobs → count applications per job → display analytics
- [ ] T091 [US6] [Plan:5.1] Implement dashboard view: job list with application count + status badges (pending, accepted, rejected)
- [ ] T092 [US6] [Plan:5.1] Implement analytics summary: total applications, pending count, acceptance rate

#### 5.2 Application List
- [ ] T093 [US6] [Plan:5.2] Implement ApplicationListController: fetch all applications for company's jobs with applicant info
- [ ] T094 [US6] [Plan:5.2] Implement list view: applicant name, job title, application date, current status
- [ ] T095 [US6] [Plan:5.2] Implement search/filter: filter by job, status, applicant name

#### 5.3 Application Review Screen
- [ ] T096 [US6] [Plan:5.3] Implement ApplicationReviewController: fetch single application + candidate profile
- [ ] T097 [US6] [Plan:5.3] Implement CV preview: flutter_pdfview displays CV from Supabase Storage signed URL
- [ ] T098 [US6] [Plan:5.3] Implement accept/reject buttons: tap → update Firestore status + trigger Cloud Function

#### 5.4 Testing (Manual Fakes)
- [ ] T099 [US6] [Plan:5.4] Create test: `company_dashboard_controller_test.dart` → verify job + application fetching + analytics calculation
- [ ] T100 [US6] [Plan:5.4] Create test: application review flow → verify accept/reject status update

---

### Phase 6: Profile Management & User Settings (P2 User Story 7)

Enable users to edit profiles without data loss and manage settings.

#### 6.1 Job Seeker Profile Editing
- [ ] T101 [US7] [Plan:6.1] Implement JobSeekerProfileController: edit skills, experience, main fields → Firestore with SetOptions(merge: true)
- [ ] T102 [US7] [Plan:6.1] Implement profile picture upload: image picker → Supabase Storage → Firestore reference update (merge: true)
- [ ] T103 [US7] [Plan:6.1] Test concurrent profile updates: update skills while updating profile picture → both persist (merge: true ensures no loss)

#### 6.2 Company Profile Editing
- [ ] T104 [US7] [Plan:6.2] Implement CompanyProfileController: edit company name, description, location → Firestore (merge: true)
- [ ] T105 [US7] [Plan:6.2] Implement company logo upload: image picker → Supabase Storage → Firestore reference update (merge: true)
- [ ] T106 [US7] [Plan:6.2] Test: edit company profile → logout/login → verify profile persists

#### 6.3 Testing (Manual Fakes)
- [ ] T107 [US7] [Plan:6.3] Create test: profile update with merge: true validation → verify no field overwrites
- [ ] T108 [US7] [Plan:6.3] Create test: `profile_controller_test.dart` → logout sequence validation

---

### Phase 7: Location-Based Map View & Saved Jobs (P2 User Stories 8 & 9)

Enable job seekers to view jobs on a map and save favorite jobs.

#### 7.1 Jobs Map View
- [ ] T109 [US8] [Plan:7.1] Implement JobsMapController (register via MainWrapperBinding lazyPut): fetch all jobs with coordinates → initialize GoogleMap
- [ ] T110 [US8] [Plan:7.1] Implement map markers: for each job, create Marker at (lat/lon) with job title
- [ ] T111 [US8] [Plan:7.1] Implement marker tap: Marker.onTap → show InfoWindow or navigate to JobDetail
- [ ] T112 [US8] [Plan:7.1] Test: map renders 100+ markers without lag

#### 7.2 Saved Jobs
- [ ] T113 [US9] [Plan:7.2] Implement save job action: on JobDetailsView, tap Save → add jobId to user's saved list in Firestore (merge: true)
- [ ] T114 [US9] [Plan:7.2] Implement JobSeekerSavedJobsController (register in MainWrapperBinding + MyApplicationsBinding): fetch saved job IDs → fetch full job data
- [ ] T115 [US9] [Plan:7.2] Implement saved jobs tab: display saved jobs using JobCardWidget with distance parameter
- [ ] T116 [US9] [Plan:7.2] Implement unsave action: remove jobId from saved list in Firestore

#### 7.3 Testing (Manual Fakes)
- [ ] T117 [US8] [Plan:7.3] Create test: map rendering with 100+ markers → verify no performance issues
- [ ] T118 [US9] [Plan:7.3] Create test: save/unsave jobs → verify Firestore persists correctly

---

### Phase 8: Notification Routing & Badge Management (P2 User Story 10)

Ensure robust notification delivery, badge counting, and recovery from stream errors.

#### 8.1 Notification Badge Management
- [ ] T119 [US10] [Plan:8.1] Implement notification_count observable in NotificationService
- [ ] T120 [US10] [Plan:8.1] Implement badge increment on FCM receipt: when notification arrives → increment notification_count
- [ ] T121 [US10] [Plan:8.1] Implement badge reset on notification tap or screen navigation
- [ ] T122 [US10] [Plan:8.1] Implement onError handler in stream subscriptions: if stream error occurs → reset notification_count to 0 (prevents permanent failure)

#### 8.2 FCM Routing by Data Type
- [ ] T123 [US10] [Plan:8.2] Verify NotificationService._navigateFromData routes all 3 data types correctly: "chat_message" → ChatDetail, "application_update" → MyApplications, "new_application" → Dashboard
- [ ] T124 [US10] [Plan:8.2] Test edge case: notification received while app in background → tap notification → correct screen opens

#### 8.3 Testing (Manual Fakes)
- [ ] T125 [US10] [Plan:8.3] Create test: badge stream error → verify onError handler resets badge to 0
- [ ] T126 [US10] [Plan:8.3] Create test: notification routing for all 3 data types

---

### Phase 9: Route Protection & Role-Based Access (P1 User Story 11)

Enforce role-based route guards and prevent unauthorized access.

#### 9.1 Role Guard Middleware
- [ ] T127 [US11] [Plan:9.1] Verify RoleGuardMiddleware blocks job seeker access to company routes (post job, manage applications)
- [ ] T128 [US11] [Plan:9.1] Verify RoleGuardMiddleware blocks company access to job seeker routes (search jobs, apply)
- [ ] T129 [US11] [Plan:9.1] Verify public routes (pdf_viewer, maps) are accessible without authentication
- [ ] T130 [US11] [Plan:9.1] Test: attempt to navigate to restricted route → verify redirect or block (no role leakage)

#### 9.2 Route Configuration
- [ ] T131 [US11] [Plan:9.2] Verify all protected routes use RoleGuardMiddleware in app/routes/app_pages.dart
- [ ] T132 [US11] [Plan:9.2] Verify public routes have no middleware (pdf_viewer, maps intentionally public)
- [ ] T133 [US11] [Plan:9.2] Test: route guard prevents 100% of unauthorized access attempts

#### 9.3 Testing (Manual Fakes)
- [ ] T134 [US11] [Plan:9.3] Create test: role guard blocks unauthorized access for all restricted routes

---

### Phase 10: Password Recovery & Session Management (P1 User Story 12)

Implement password recovery and ensure proper session cleanup on logout.

#### 10.1 Password Recovery
- [ ] T135 [US12] [Plan:10.1] Verify forgot password flow: user enters email → Supabase.auth.resetPasswordForEmail() sends recovery link
- [ ] T136 [US12] [Plan:10.1] Verify reset password: user receives email → clicks link → password reset page loads → new password persists
- [ ] T137 [US12] [Plan:10.1] Test: reset password → login with new password works

#### 10.2 Logout & Session Cleanup
- [ ] T138 [US12] [Plan:10.2] Verify logout sequence (ProfileController lines ~800-811): delete FCM token from Firestore → FirebaseMessaging.deleteToken() → Supabase.auth.clearAuthSession() → Supabase.auth.signOut()
- [ ] T139 [US12] [Plan:10.2] Verify no residual auth state: after logout → cannot access protected routes → redirect to login
- [ ] T140 [US12] [Plan:10.2] Test: logout on Device A → verify Device A receives no notifications; new login creates new FCM token

#### 10.3 Token Refresh
- [ ] T141 [US12] [Plan:10.3] Verify auto-refresh: Supabase auth token expires → next API call auto-refreshes → no manual intervention
- [ ] T142 [US12] [Plan:10.3] Test edge case: logout after token expiry → verify session cleared properly

#### 10.4 Testing (Manual Fakes)
- [ ] T143 [US12] [Plan:10.4] Create test: logout sequence validation → verify 4-step FCM token cleanup
- [ ] T144 [US12] [Plan:10.4] Create test: password reset flow

---

### Phase 11: Code Quality & Architecture Compliance

Verify all code adheres to constitution principles and architecture patterns.

#### 11.1 Code Review Checklist
- [ ] T145 [Plan:11.1] Verify all controllers inherit GetxController (no exceptions)
- [ ] T146 [Plan:11.1] Verify all Firestore writes use SetOptions(merge: true) (no plain set() calls)
- [ ] T147 [Plan:11.1] Verify all routes import from app/routes/app_pages.dart (Routes.* namespace)
- [ ] T148 [Plan:11.1] Verify all services registered via Get.putAsync in main.dart (not Get.put)
- [ ] T149 [Plan:11.1] Verify all tests use manual fakes (no Mockito/Mocktail imports)
- [ ] T150 [Plan:11.1] Verify all test tearDown calls Get.reset()

#### 11.2 Build & Analyze
- [ ] T151 [Plan:11.2] Run `flutter pub get` → resolve all dependencies
- [ ] T152 [Plan:11.2] Run `flutter analyze --no-fatal-infos --no-fatal-warnings` → zero violations
- [ ] T153 [Plan:11.2] Run `flutter test --no-pub` → all tests passing
- [ ] T154 [Plan:11.2] Run `flutter build apk --release` → release APK generated

#### 11.3 Documentation & Runbooks
- [ ] T155 [Plan:11.3] Update AGENTS.md with any new gotchas discovered during implementation
- [ ] T156 [Plan:11.3] Create runbook: how to run tests locally + in CI
- [ ] T157 [Plan:11.3] Create deployment guide: Firebase deploy commands (functions, RTDB, Firestore indexes)

---

## Requirement Mapping

| REQ ID | Description | Plan Items | Implementation Evidence |
|--------|-------------|------------|------------------------|
| REQ-001 | Supabase Auth PKCE flow with auto-refresh | P1.1 | AuthController.dart |
| REQ-002 | Dual-role authentication (Job Seeker / Company) | P1.1, P1.4 | OnboardingController.dart, RoleSelectorView.dart |
| REQ-003 | Register & manage FCM tokens in Firestore | P1.3 | NotificationService.dart, auth_login_controller.dart |
| REQ-004 | Role-based route access via RoleGuardMiddleware | P0.3, P9 | RoleGuardMiddleware.dart, app_pages.dart |
| REQ-005 | Password recovery via email | P1.1, P12.1 | AuthController.resetPassword() |
| REQ-006 | Session timeout & auto-refresh | P1.5, P12.2 | Supabase Auth (PKCE), main.dart |
| REQ-007 | Browse available jobs | P2.2 | JobSeekerDashboardController.dart |
| REQ-008 | Search jobs by title/company/keyword | P2.2 | JobSeekerSearchJobsController.dart |
| REQ-009 | Filter jobs by distance | P2.1, P2.2 | DistanceMixin.dart, distance sorting |
| REQ-010 | Calculate & display distance | P2.1 | DistanceMixin.getDistanceToCompany(), Geolocator.distanceBetween() |
| REQ-011 | Save jobs to "Saved Jobs" list | P7.2 | JobSeekerSavedJobsController.dart |
| REQ-012 | View full job details with map | P2.3, P2.4 | JobDetailsController.dart, GoogleMap widget |
| REQ-013 | Create & post new job listings | P5.1 | PostJobController.dart |
| REQ-014 | View, edit, delete posted jobs | P5.1 | CompanyDashboardController.dart |
| REQ-015 | View analytics (applications per job) | P5.1 | CompanyDashboardController analytics section |
| REQ-016 | Apply for jobs with CV upload | P3.1 | ApplyJobController.dart, CV upload to Supabase Storage |
| REQ-017 | Create application records with "pending" status | P3.1, P3.2 | ApplicationRepository.createApplication() |
| REQ-018 | Firestore writes with SetOptions(merge: true) | All phases | All Firestore repositories |
| REQ-019 | View all applications (company) | P5.2 | ApplicationListController.dart |
| REQ-020 | Accept/reject applications | P3.3, P5.3 | ApplicationReviewController.acceptApplication() |
| REQ-021 | Notify job seekers of status changes | P3.4 | onApplicationAccepted/onApplicationRejected Cloud Functions |
| REQ-022 | View application history by status | P3.5 | JobSeekerMyApplicationsController tabs |
| REQ-023 | View full application details + feedback | P5.3 | ApplicationReviewView with CV preview |
| REQ-024 | Initiate one-to-one chat | P4.1, P4.5 | ChatListController, "Message" button |
| REQ-025 | Persist messages in Firestore subcollection | P4.1, P4.3 | ChatMessageRepository, messages subcollection |
| REQ-026 | Send FCM notifications for new messages | P4.4 | onNewChatMessage Cloud Function |
| REQ-027 | View complete chat history | P4.2, P4.3 | ChatDetailController, Firestore stream |
| REQ-028 | Notify users of new messages with badge | P8.1 | NotificationService badge increment |
| REQ-029 | Job seeker profile creation & editing | P1.2, P6.1 | JobSeekerProfileController.dart |
| REQ-030 | Company profile creation & editing | P1.2, P6.2 | CompanyProfileController.dart |
| REQ-031 | All profile updates use merge: true | P1.2, P6.1, P6.2 | SetOptions(merge: true) in all profile updates |
| REQ-032 | Store logo/images in Supabase Storage | P1.2, P6.2 | StorageService.dart |
| REQ-033 | Request location permission | P2.1 | DistanceMixin, Geolocator.requestPermission() |
| REQ-034 | Display jobs on Google Map | P7.1 | JobsMapController, GoogleMap widget |
| REQ-035 | Map markers respond to tap | P2.4, P7.1 | Marker.onTap, InfoWindow.onTap |
| REQ-036 | Reverse geocoding (company_map_controller only) | P2.4 | geocoding package, company_map_controller.dart |
| REQ-037 | Calculate distance between user & job | P2.1 | Geolocator.distanceBetween() |
| REQ-038 | Route FCM by data type | P4.4, P8.2 | NotificationService._navigateFromData() |
| REQ-039 | Stream subscriptions have onError handlers | P8.1 | badge recovery on stream error |
| REQ-040 | Display notification badges | P8.1 | notification_count observable |
| REQ-041 | Persist notification count | P8.1 | SharedPreferences or Firestore |
| REQ-042 | All Firestore writes use merge: true | All phases | SetOptions(merge: true) enforcement |
| REQ-043 | Persist sessions & auto-refresh tokens | P1.5 | Supabase auto-refresh, main.dart |
| REQ-044 | Offline-first capability | All phases | local cache + sync on reconnect |
| REQ-045 | Controllers inherit GetxController | All phases | GetxController inheritance |
| REQ-046 | Tests use manual fakes only | P1.6, P3.6, etc. | Manual fakes, Get.reset() in tearDown |
| REQ-047 | Routes use Routes.* constants | All phases | app/routes/app_pages.dart |
| REQ-048 | Modular feature structure | All phases | app/modules/{role}/{feature}/ |
| REQ-049 | Shared utilities & codegen not edited | All phases | core/utils/, app_assets.dart |

---

## Summary of Tasks & Coverage

**Total Tasks**: 157 implementation tasks

**Breakdown by Phase**:
- Phase 0 (Setup): 13 tasks (T001–T013)
- Phase 1 (Auth): 21 tasks (T014–T034)
- Phase 2 (Job Discovery): 18 tasks (T035–T052)
- Phase 3 (Applications): 18 tasks (T053–T070)
- Phase 4 (Chat): 18 tasks (T072–T089)
- Phase 5 (Company Dashboard): 10 tasks (T090–T100)
- Phase 6 (Profile Management): 8 tasks (T101–T108)
- Phase 7 (Maps & Saved Jobs): 10 tasks (T109–T118)
- Phase 8 (Notifications): 8 tasks (T119–T126)
- Phase 9 (Route Protection): 8 tasks (T127–T134)
- Phase 10 (Password & Session): 10 tasks (T135–T144)
- Phase 11 (Quality & Compliance): 11 tasks (T145–T157)

**Requirement Coverage**: All 49 requirements (REQ-001 to REQ-049) mapped to plan items + implementation evidence

**User Story Coverage**: 12 user stories (5 P1 + 7 P2) with explicit [US1]–[US12] labels in task breakdown

**Architecture Compliance**: All constitution principles verified in Phase 11 code review checklist (GetX, Firestore merge, Firebase/Supabase, manual fakes, notifications, modular structure, route guards, configuration security).

---

## Notes for Implementation

1. **Parallel Execution**: Tasks marked [P] can execute in parallel (different files, no dependencies).
2. **Dependency Order**: Phase 0 (setup) must complete before all other phases; within each phase, foundational tasks (models, repositories) must complete before UI controllers.
3. **Testing Strategy**: Manual fakes only; no Mockito/Mocktail. Get.reset() in tearDown. Firebase/Supabase initialization skipped in tests.
4. **Firestore Schema**: All writes use `merge: true`; subcollections used for normalized data (messages, applications); timestamps for sorting.
5. **FCM Token Cleanup**: Logout sequence is MANDATORY: delete from Firestore → deleteToken() → clearAuthSession() → signOut(). Skipping any step leaks tokens.
6. **Performance Targets**: Job search <2s, chat delivery <2s, map 100+ markers without lag, 1000 concurrent users.
7. **Offline Capability**: Local cache + sync on reconnect; offline app launch shows cached data.
8. **Role-Based Access**: RoleGuardMiddleware enforces; no exceptions; 100% block rate target.
