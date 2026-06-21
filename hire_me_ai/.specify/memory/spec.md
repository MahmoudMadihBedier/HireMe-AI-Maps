# Feature Specification: HireMe Recruitment Platform

**Feature Branch**: `feature/maps-ai`

**Created**: 2026-06-21

**Status**: Draft

**Input**: Flutter GetX recruitment platform connecting job seekers with companies. Dual-role authentication (Job Seeker / Company). Features: job browsing, search, applications, real-time chat, profile management, location-based job discovery, and application tracking.

## User Scenarios & Testing

### User Story 1 - Job Seeker Authentication & Onboarding (Priority: P1)

A job seeker discovers HireMe, completes the onboarding flow, creates an account with email/password (via Supabase PKCE flow), sets up their profile (skills, main fields), and logs in successfully to access the job dashboard.

**Why this priority**: Authentication is the entry point; without it, no other features are accessible. Onboarding establishes user trust and captures essential profile data.

**Independent Test**: Can be fully tested by completing signup → profile setup → login and verified by accessing dashboard without errors.

**Acceptance Scenarios**:

1. **Given** user launches the app for the first time, **When** they complete splash screen, **Then** onboarding flow displays role selection (Job Seeker / Company).
2. **Given** user selects Job Seeker role, **When** they enter email/password and confirm, **Then** account is created in Supabase Auth with auto-refresh enabled.
3. **Given** new job seeker, **When** they complete profile setup (skills, main fields), **Then** profile is persisted in Firestore with `merge: true` semantics.
4. **Given** registered job seeker, **When** they tap login and provide credentials, **Then** auth token is issued and FCM token is registered in Firestore.
5. **Given** logged-in job seeker with valid FCM token, **When** they receive a push notification, **Then** notification is routed correctly based on data type (`chat_message`, `application_update`, `new_application`).

---

### User Story 2 - Company Authentication & Dashboard Setup (Priority: P1)

A company recruiter creates an account via the Company role path, sets up company profile (name, location, description, logo), and accesses the company dashboard with job posting and application management capabilities.

**Why this priority**: Companies are the supply side of the platform; their authentication and dashboard are critical for the core business flow.

**Independent Test**: Can be fully tested by company signup → profile setup → dashboard access and verified by viewing job management interface.

**Acceptance Scenarios**:

1. **Given** user selects Company role during onboarding, **When** they provide company email and password, **Then** company account is created in Supabase Auth.
2. **Given** new company, **When** they complete company profile (name, location, description, logo upload to Supabase Storage), **Then** profile is stored in Firestore.
3. **Given** logged-in company recruiter, **When** they navigate to dashboard, **Then** they see job posting interface, application list, and analytics summary.
4. **Given** company recruiter with valid FCM token, **When** a new application is submitted, **Then** FCM notification is triggered with `application_update` data type.

---

### User Story 3 - Browse & Search Jobs with Distance Filtering (Priority: P1)

A job seeker opens the app, grants location permission, and browses a list of available jobs. They can search by job title/company, filter by distance from their location, and view detailed job information including company location on a map.

**Why this priority**: Job discovery is the core value proposition for job seekers. Distance-based filtering makes location relevant and improves user engagement.

**Independent Test**: Can be fully tested by granting permissions → browsing jobs → applying distance filter and verified by job list updates with correct distance calculations.

**Acceptance Scenarios**:

1. **Given** job seeker on dashboard, **When** they enable location permission, **Then** `userPosition` is captured via Geolocator and stored in observable.
2. **Given** job seeker with active location, **When** they toggle "Sort by Distance", **Then** jobs are reordered by calculated distance (via DistanceMixin).
3. **Given** job list rendered, **When** a job has null coordinates, **Then** it is sorted to the end (distance = null).
4. **Given** job seeker on search screen, **When** they enter a search term and apply filters, **Then** matching jobs are displayed with computed `distance` parameter in JobCardWidget.
5. **Given** job seeker viewing a job card, **When** they tap to view details, **Then** job map displays location via GoogleMap widget, and markers respond to `Marker.onTap` / `InfoWindow.onTap` callbacks.

---

### User Story 4 - Job Application & Status Tracking (Priority: P1)

A job seeker applies for a job, uploads their resume/CV, and tracks the application status (Pending, Accepted, Rejected). They receive notifications when application status changes.

**Why this priority**: Applications are the conversion point; status tracking keeps users engaged and informed.

**Independent Test**: Can be fully tested by applying to a job → uploading file → receiving status notification and verified by checking My Applications tab.

**Acceptance Scenarios**:

1. **Given** job seeker viewing job details, **When** they tap "Apply" and upload CV to Supabase Storage, **Then** application document is created in Firestore with `status: "pending"`.
2. **Given** pending application, **When** company recruiter accepts/rejects it, **Then** Firestore document is updated with merge: true and onApplicationAccepted/onApplicationRejected Cloud Function is triggered.
3. **Given** job seeker, **When** their application status changes, **Then** FCM notification is sent with `application_update` data type.
4. **Given** job seeker on "My Applications" tab, **When** they view the Accepted/Rejected/Pending sub-tab, **Then** applications are filtered and displayed correctly.
5. **Given** job seeker on "Saved Jobs" tab in My Applications, **When** they view saved jobs, **Then** JobCardWidget displays saved jobs with distance parameter.

---

### User Story 5 - Real-Time Chat Between Job Seeker & Company (Priority: P1)

A job seeker initiates a chat with a company, exchanges messages in real-time, and maintains chat history. Both parties receive FCM notifications for new messages.

**Why this priority**: Real-time communication is essential for reducing friction in the hiring process and enables direct employer-candidate engagement.

**Independent Test**: Can be fully tested by initiating chat → sending/receiving messages → receiving FCM notification and verified by message history persistence.

**Acceptance Scenarios**:

1. **Given** job seeker viewing job or application, **When** they tap "Message Company", **Then** chat thread is created in Firestore (if not exists) and chat detail screen opens.
2. **Given** open chat thread, **When** either party sends a message, **Then** message is persisted in Firestore under `messages` subcollection and NotificationService routes `chat_message` FCM payload.
3. **Given** job seeker/company on chat details screen, **When** new message arrives, **Then** UI updates in real-time via Firestore stream listener.
4. **Given** user not on chat details screen, **When** new message arrives, **Then** FCM notification is received and `NotificationService._navigateFromData` routes to chat detail.
5. **Given** chat thread exists, **When** user navigates to chat list, **Then** all active chats are displayed with last message preview and timestamp.

---

### User Story 6 - Company Review & Manage Applications (Priority: P2)

A company recruiter views all received applications in a list, clicks on each to review the candidate's profile/CV, and changes application status (accept/reject). The candidate is notified of status changes.

**Why this priority**: Application review is the core workflow for recruiters; it directly impacts hiring efficiency.

**Independent Test**: Can be fully tested by viewing application list → reviewing applicant → updating status and verified by job seeker receiving notification.

**Acceptance Scenarios**:

1. **Given** company recruiter on Applications tab, **When** they view the list, **Then** all applications for their posted jobs are displayed with applicant info and status badge.
2. **Given** application in list, **When** recruiter taps it, **Then** application review screen opens with candidate profile, CV preview (via flutter_pdfview), and action buttons.
3. **Given** application review screen, **When** recruiter taps Accept/Reject, **Then** Firestore document `status` field is updated and onApplicationAccepted/onApplicationRejected Cloud Function executes (triggers notification + CV analysis if applicable).
4. **Given** recruiter accepts a candidate, **When** the action completes, **Then** candidate receives FCM notification with `application_update` data type.

---

### User Story 7 - Profile Management & Field Updates (Priority: P2)

A job seeker edits their profile (skills, experience, main fields) and sees changes reflected immediately. A company updates company profile (description, logo, contact info). Changes are persisted and do not overwrite unrelated fields.

**Why this priority**: Profile updates are frequent and must work reliably without data loss; critical for the Firestore merge principle.

**Independent Test**: Can be fully tested by editing profile → confirming changes persist → logging out/in and verified by profile reload.

**Acceptance Scenarios**:

1. **Given** job seeker on profile screen, **When** they edit their main fields and tap Save, **Then** Firestore document is updated with `SetOptions(merge: true)` to prevent overwriting other fields.
2. **Given** profile with existing data, **When** user updates only one field, **Then** other fields remain unchanged in Firestore.
3. **Given** company recruiter on company profile screen, **When** they upload a logo to Supabase Storage, **Then** storage URL is stored in Firestore company document.
4. **Given** updated profile, **When** user logs out and logs back in, **Then** profile data loads correctly from Firestore.

---

### User Story 8 - Location-Based Job Map View (Priority: P2)

A job seeker can switch to a map view, see all available jobs plotted on a map as markers, and tap a marker to view job details or navigate to job details screen.

**Why this priority**: Map view is a discovery feature that enhances UX for location-aware job hunting; secondary but valuable engagement driver.

**Independent Test**: Can be fully tested by switching to map → viewing markers → tapping marker and verified by job details navigation.

**Acceptance Scenarios**:

1. **Given** job seeker on main wrapper (bottom nav), **When** they tap Map tab (index 4 in IndexedStack), **Then** JobsMapController is loaded via `MainWrapperBinding` (lazyPut).
2. **Given** map screen, **When** it renders, **Then** all jobs with valid coordinates are displayed as markers on GoogleMap.
3. **Given** marker on map, **When** user taps it, **Then** `Marker.onTap` callback fires and either displays InfoWindow or navigates to job detail screen.
4. **Given** marker with InfoWindow, **When** user taps the InfoWindow, **Then** job detail screen opens.

---

### User Story 9 - Save & Manage Favorite Jobs (Priority: P2)

A job seeker can save a job to their "Saved Jobs" list, view all saved jobs in a dedicated tab, and unsave jobs. Saved jobs persist and are accessible across sessions.

**Why this priority**: Saved jobs enable job seekers to curate a personalized list; improves retention and engagement.

**Independent Test**: Can be fully tested by saving job → navigating to Saved Jobs tab → verifying persistence and verified by logout/login.

**Acceptance Scenarios**:

1. **Given** job seeker viewing job details, **When** they tap Save/Like button, **Then** job ID is added to user's saved jobs list in Firestore (merge: true).
2. **Given** job seeker on My Applications tab, **When** they tap "Saved Jobs" sub-tab, **Then** saved jobs are fetched via JobSeekerSavedJobsController and rendered with JobCardWidget.
3. **Given** saved job in list, **When** user taps it, **Then** job detail screen opens or job is displayed for review.
4. **Given** saved job, **When** user taps unsave button, **Then** job ID is removed from saved jobs list in Firestore.

---

### User Story 10 - Notification Routing & Badge Management (Priority: P2)

A job seeker receives push notifications for job applications, messages, and new job postings. Badge count reflects unread notification count and resets on error without permanent failure.

**Why this priority**: Notifications drive engagement and keep users informed; badge integrity is critical for reliability.

**Independent Test**: Can be fully tested by sending FCM notification → receiving it → observing badge and verified by error handling.

**Acceptance Scenarios**:

1. **Given** job seeker with FCM token registered in Firestore, **When** a relevant event occurs (new application status, new message, new job), **Then** FCM notification is sent.
2. **Given** incoming FCM notification in foreground, **When** NotificationService._navigateFromData processes it, **Then** correct route is determined based on data type (`chat_message` → chat details, `application_update` → my applications, `new_application` → dashboard).
3. **Given** notification badge stream, **When** an error occurs in the stream, **Then** `onError` handler resets badge count to 0 (preventing permanent failure).
4. **Given** user viewed notifications, **When** they reset the app, **Then** badge count persists correctly.

---

### User Story 11 - Role-Based Route Protection & Navigation (Priority: P1)

A job seeker cannot access company-only routes (post job, manage applications) and vice versa. Public routes (PDF viewer, map) are accessible without authentication. Navigation guards enforce role-based access.

**Why this priority**: Security and UX depend on proper route isolation; prevents role confusion and unauthorized access.

**Independent Test**: Can be fully tested by attempting to navigate to restricted route and verified by being blocked or redirected.

**Acceptance Scenarios**:

1. **Given** job seeker, **When** they attempt to navigate to `Routes.postJob` (company-only), **Then** RoleGuardMiddleware blocks access and redirects to allowed screen.
2. **Given** authenticated job seeker, **When** they navigate to `Routes.pdfViewer`, **Then** no middleware blocks them (intentionally public).
3. **Given** unauthenticated user, **When** they try to access `Routes.jobSeekerSearchJobs`, **Then** they are redirected to login screen.
4. **Given** logged-in company recruiter, **When** they access the dashboard, **Then** only company-scoped routes are available in navigation.

---

### User Story 12 - Password Recovery & Session Management (Priority: P1)

A job seeker or company recruiter can recover their password via email link, reset it, and log back in with the new password. Session tokens are refreshed automatically and FCM tokens are properly cleaned up on logout.

**Why this priority**: Password recovery and session management are security fundamentals; logout integrity is critical for multi-user devices.

**Independent Test**: Can be fully tested by initiating password recovery → receiving email → resetting password → logging in and verified by session validity.

**Acceptance Scenarios**:

1. **Given** forgot password screen, **When** user enters their email and submits, **Then** Supabase Auth sends password recovery email.
2. **Given** recovery email received, **When** user clicks reset link, **Then** password reset flow is initiated in the app or browser.
3. **Given** new password set, **When** user logs in with new credentials, **Then** session is established and FCM token is registered.
4. **Given** logged-in user, **When** they tap logout, **Then** FCM token is deleted from Firestore, deleteToken() is called, clearAuthSession() is called, and signOut() completes (in order).
5. **Given** logged-out state, **When** user navigates the app, **Then** they cannot access protected routes and are redirected to login.

---

### Edge Cases

- What happens when a job seeker tries to apply to a job that was deleted by the company? → Application creation fails gracefully and user is shown error message.
- How does the system handle when a user's location permission is revoked after initial grant? → Distance filtering is disabled and jobs sort without distance; "Sort by Distance" toggle is greyed out.
- What if a job seeker's Firestore profile document is corrupted or partially deleted? → App loads with defaults; merge: true semantics prevent catastrophic overwrites.
- How does the system handle concurrent application status updates (company accepts while job seeker rejects)? → Last-write-wins via Firestore timestamp; both parties see consistent state.
- What happens if FCM token registration fails during login? → Login completes but notifications won't be received; next login retry registers token (silent degradation, not blocking).
- How does the system handle when a user logs in on a different device? → New FCM token is registered; old device will not receive notifications (expected behavior).
- What if the company deletes a job while job seekers are viewing/applying? → Existing applications remain accessible; new applications cannot be created.
- How does the system handle chat message delivery when recipient is offline? → Message is persisted in Firestore; FCM notification is sent; recipient sees full history on next login.

## Requirements

### Functional Requirements

**Authentication & Authorization**

- **REQ-001**: System MUST authenticate users via Supabase Auth with PKCE flow, auto-refresh tokens enabled, and support email/password credentials.
- **REQ-002**: System MUST support dual-role authentication: Job Seeker and Company recruiter roles selectable during registration.
- **REQ-003**: System MUST register and manage FCM tokens in Firestore; tokens MUST be deleted from Firestore before calling deleteToken() on logout.
- **REQ-004**: System MUST enforce role-based route access via RoleGuardMiddleware; unauthorized role attempts MUST be blocked or redirected.
- **REQ-005**: System MUST support password recovery via email with Supabase Auth password reset flow.
- **REQ-006**: System MUST implement session timeout and auto-refresh token mechanisms via Supabase auto-refresh.

**Job Management (Job Seeker)**

- **REQ-007**: Job seekers MUST be able to browse all available jobs posted by companies with job title, company name, location, and salary (if provided).
- **REQ-008**: Job seekers MUST be able to search jobs by title, company name, or keyword with real-time filtering.
- **REQ-009**: Job seekers MUST be able to filter jobs by distance from their current location (requires location permission).
- **REQ-010**: System MUST calculate and display distance to each job using DistanceMixin when user location is available; jobs without coordinates MUST sort last.
- **REQ-011**: Job seekers MUST be able to save jobs to a "Saved Jobs" list via Firestore with merge: true semantics.
- **REQ-012**: Job seekers MUST be able to view full job details including description, requirements, company profile, and location on map.

**Job Management (Company)**

- **REQ-013**: Company recruiters MUST be able to create and post new job listings with title, description, location, salary, and requirements.
- **REQ-014**: Company recruiters MUST be able to view, edit, and delete their posted jobs.
- **REQ-015**: Company recruiters MUST be able to view analytics for each job (number of applications, status breakdown).

**Applications & Status Tracking**

- **REQ-016**: Job seekers MUST be able to apply for jobs by selecting a job and uploading their CV/resume to Supabase Storage.
- **REQ-017**: System MUST create application records in Firestore with status "pending" when job seeker applies.
- **REQ-018**: System MUST persist all application documents using SetOptions(merge: true) to prevent data loss.
- **REQ-019**: Company recruiters MUST be able to view all applications for their jobs in a list with applicant info and current status.
- **REQ-020**: Company recruiters MUST be able to accept or reject applications; system MUST trigger corresponding Cloud Functions and update Firestore status.
- **REQ-021**: System MUST notify job seekers of application status changes (accepted/rejected) via FCM with "application_update" data type.
- **REQ-022**: Job seekers MUST be able to view their application history organized by status (All, Pending, Accepted, Rejected).
- **REQ-023**: Job seekers MUST be able to view full application details including company feedback and CV.

**Real-Time Chat**

- **REQ-024**: Job seekers and company recruiters MUST be able to initiate one-to-one chat conversations.
- **REQ-025**: Chat messages MUST be persisted in Firestore under messages subcollection and delivered in real-time via stream listeners.
- **REQ-026**: System MUST send FCM notifications for new chat messages with "chat_message" data type when recipient is not actively viewing chat.
- **REQ-027**: Both parties MUST be able to view complete chat history including all previous messages in chronological order.
- **REQ-028**: System MUST notify user of new messages with badge count on chat icon.

**Profile Management**

- **REQ-029**: Job seekers MUST be able to create and edit their profile with skills, experience, main fields, and profile picture.
- **REQ-030**: Company recruiters MUST be able to create and edit company profile with name, description, location, logo, and contact info.
- **REQ-031**: All profile updates MUST use SetOptions(merge: true) to ensure unrelated fields are not overwritten.
- **REQ-032**: System MUST persist logo/profile pictures in Supabase Storage and store references in Firestore.

**Location & Map Features**

- **REQ-033**: System MUST request user location permission and capture GPS coordinates via Geolocator package.
- **REQ-034**: System MUST display jobs on interactive Google Map with markers at job locations.
- **REQ-035**: Map markers MUST respond to tap events via Marker.onTap or InfoWindow.onTap callbacks.
- **REQ-036**: System MUST use reverse geocoding (via geocoding package in company_map_controller only) to convert coordinates to addresses.
- **REQ-037**: System MUST calculate distance between user location and job location using standard geographic distance formula.

**Notifications**

- **REQ-038**: System MUST route incoming FCM notifications based on data type: "chat_message" → chat details, "application_update" → my applications, "new_application" → dashboard.
- **REQ-039**: Notification stream subscriptions MUST include onError handlers that reset badge count to 0 to prevent permanent failure on stream errors.
- **REQ-040**: System MUST display notification badges on relevant UI elements (chat icon, applications icon).
- **REQ-041**: System MUST persist unread notification count in observable and restore it on app restart.

**Data Persistence**

- **REQ-042**: All Firestore writes MUST use SetOptions(merge: true) without exception; plain set() is forbidden.
- **REQ-043**: System MUST persist user sessions and automatically refresh tokens via Supabase auto-refresh.
- **REQ-044**: System MUST maintain offline-first capability where possible; data syncs when connectivity is restored.

**Architecture & Code Quality**

- **REQ-045**: All controllers MUST inherit from GetxController and be registered via Binding classes; direct Get.put in UI is forbidden.
- **REQ-046**: All tests MUST use manual fakes only (no Mockito/Mocktail); test tearDown MUST call Get.reset().
- **REQ-047**: All route navigation MUST use Routes.* constants from app/routes/app_pages.dart; app_routes.dart MUST NOT be imported directly.
- **REQ-048**: All feature modules MUST follow modular structure: controller, bindings, views, local models under app/modules/{role}/{feature}/.
- **REQ-049**: Shared utilities MUST live in core/utils/; shared widgets in core/widgets/; codegen artifacts MUST NOT be edited manually.

### Key Entities

- **User** (Job Seeker): Firestore document with authentication via Supabase Auth; fields: email, profile (skills, experience, main fields), saved jobs, application history, FCM token.
- **Company**: Firestore document with company profile; fields: name, description, location, logo URL (Supabase Storage), posted jobs array, recruiter contact info.
- **Job Posting**: Firestore document posted by Company; fields: title, description, requirements, location (coordinates), salary, company reference, creation date, application count.
- **Application**: Firestore document; fields: job ID, job seeker ID, status (pending/accepted/rejected), resume URL (Supabase Storage), CV file, application date, status change timestamps.
- **Chat Thread**: Firestore document; fields: participants (job seeker ID, company ID), creation date, last message preview, messages subcollection with individual message documents.
- **Chat Message**: Firestore document in messages subcollection; fields: sender ID, content, timestamp, read status.
- **Notification**: Not stored in Firestore; delivered via FCM; fields: data type, recipient ID, payload (job/application/message reference).

### Non-Functional Requirements

- **Performance**: Job search and filtering MUST return results within 2 seconds; map rendering MUST support 100+ markers without lag.
- **Scalability**: System MUST support concurrent operations from 1000+ active users without degradation.
- **Security**: All network requests MUST use HTTPS; Firestore rules MUST enforce role-based access; user data MUST NOT be logged.
- **Reliability**: FCM delivery MUST be retried on transient failures; Firestore merge semantics MUST prevent data loss under concurrent writes.
- **Availability**: System MUST gracefully handle network disconnections and reconnect automatically.
- **Compliance**: User data retention MUST comply with platform privacy policies; sensitive data MUST be encrypted at rest.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Job seekers MUST be able to complete registration and view job listings within 3 minutes of app launch.
- **SC-002**: Job search with distance filtering MUST return results in under 2 seconds with 100+ jobs in database.
- **SC-003**: Chat messages MUST be delivered and visible to recipient within 2 seconds (real-time sync).
- **SC-004**: FCM notifications MUST be delivered to at least 95% of registered devices within 30 seconds of event trigger.
- **SC-005**: Application status updates MUST be visible to both job seeker and company recruiter within 5 seconds of change.
- **SC-006**: Map rendering MUST display 100+ job markers without visible lag or janky scrolling.
- **SC-007**: 90% of job seekers MUST successfully apply to a job on first attempt without errors.
- **SC-008**: 95% of company recruiters MUST successfully create and post a job without aborting.
- **SC-009**: Profile data MUST persist across app restarts; no data loss on Firestore merge updates.
- **SC-010**: Logout MUST fully clean up FCM tokens and sessions; no notifications MUST be received after logout.
- **SC-011**: Route guards MUST block unauthorized role access 100% of the time; no role leakage.
- **SC-012**: Badge notification counts MUST recover from stream errors and display correct count within 1 second.
- **SC-013**: System MUST support offline app launch (show cached data) and sync when connectivity restored.
- **SC-014**: 98% uptime for Firestore and FCM delivery over 30-day period.

## Assumptions

- Users have stable internet connectivity for real-time features (chat, notifications); offline capability is best-effort cache only.
- Mobile support is Android-only for v1; iOS/macOS/Windows/Linux template files are not active.
- Supabase Auth PKCE flow auto-refresh is enabled and functions correctly out-of-the-box.
- Firebase Realtime Database and Firestore indexes are pre-configured per `firebase.json` and `database.rules.json`.
- Google Maps API key is configured for Android; API quotas are sufficient for expected user volume.
- Geolocator and geocoding packages function correctly on Android; reverse geocoding is used only in company_map_controller.
- File uploads to Supabase Storage succeed within 30 seconds for typical CV files (< 10MB).
- Cloud Functions runtime (Node.js 20) can execute Groq SDK calls for CV analysis and ranking within 30 seconds.
- Job postings with null coordinates are valid and handled gracefully (sorted last, distance filtering disabled for them).
- Concurrent Firestore writes are rare; last-write-wins semantics are acceptable for application status updates.
- Users grant location permission voluntarily; app functions without it (distance filtering disabled).
- FCM token registration on login is essential; login does not fail if FCM registration fails, but notifications will not be delivered until token is registered on next session.
- Notification badge persistence is handled by observable state; no iOS-specific badge count APIs are needed for Android-only v1.
- Manual fakes in tests are sufficient; no complex mocking frameworks are required for test coverage.
- All tests run locally without Firebase/Supabase initialization; services are mocked via manual fakes.
- Flutter `3.41.6` and Dart `3.11+` are available in CI and local dev environments.
- Java 17 is available for Android Gradle builds.
- GetX lazyPut deduplicates across multiple bindings; safe to register same controller in multiple binding classes.

---

## Requirements Quality Checklist

### Requirement ID Coverage
- [x] All requirements use REQ-XXX format (REQ-001 through REQ-049)
- [x] All requirements are unique and sequential
- [x] All functional requirements are testable and unambiguous

### Testability
- [x] Every requirement is independently testable
- [x] Acceptance scenarios use Given-When-Then format
- [x] Success criteria are concrete and measurable
- [x] Edge cases are documented with expected behavior

### Completeness
- [x] Scope Baseline section complete (12 user stories with P1/P2 priorities)
- [x] User Scenarios prioritized (P1: 5 stories, P2: 7 stories)
- [x] Functional requirements cover all in-scope items (49 requirements across 8 domains)
- [x] Non-functional requirements address performance, scalability, security, reliability, availability, compliance
- [x] Success criteria are measurable (14 criteria with specific metrics)
- [x] Key entities identified (6 entities with attributes)

### Constitution Alignment
- [x] GetX State Management Purity (REQ-045, architecture requirements)
- [x] Firestore Merge Semantics (REQ-018, REQ-031, REQ-042)
- [x] Firebase + Supabase Dual-Backend (REQ-001, REQ-003, REQ-032)
- [x] Manual Testing Only (REQ-046, test requirements)
- [x] Notification Data Routing (REQ-038, REQ-039)
- [x] Modular Feature-First Architecture (REQ-048, REQ-049)
- [x] Route Guards & Role-Based Access (REQ-004, REQ-044)
- [x] Configuration & Secrets (implicit in auth flow, no secrets in spec)

### Architecture Patterns
- [x] DistanceMixin usage documented (REQ-010, User Story 3)
- [x] Maps & marker interactions covered (REQ-034, REQ-035, User Story 8)
- [x] Bottom navigation structure referenced (User Story 8 mentions IndexedStack order)
- [x] MyApplications tabs specified (User Story 4 mentions Pending/Accepted/Rejected/Saved Jobs)
- [x] Geocoding constraints noted (REQ-036, only in company_map_controller)

---

## Notes for Implementation Phase

1. **No Clarifications Required**: All critical decisions have reasonable defaults based on constitution and existing architecture.
2. **Constitution Compliance**: Specification adheres to all 8 core principles; implementation plan will reference these requirements.
3. **Test Coverage**: Each user story includes independent test steps; manual fakes will be used in unit tests per REQ-046.
4. **Firestore Schema**: Entities and subcollections (messages, applications) are designed for merge-safe updates.
5. **FCM Integration**: Notification routing is deterministic; badge recovery from errors is explicit (REQ-039).
6. **Performance Targets**: Success criteria include response time targets (2s for search, 5s for status updates, 30s for FCM).
