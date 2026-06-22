import 'package:get/get_navigation/src/routes/get_route.dart';

import '../middleware/role_guard_middleware.dart';
import '../modules/auth/forgot_password/bindings/auth_forgot_password_binding.dart';
import '../modules/auth/forgot_password/views/auth_forgot_password_view.dart';
import '../modules/auth/login/bindings/auth_login_binding.dart';
import '../modules/auth/login/views/auth_login_view.dart';
import '../modules/auth/onboarding/bindings/onboarding_binding.dart';
import '../modules/auth/onboarding/views/onboarding_view.dart';
import '../modules/auth/register/bindings/auth_register_binding.dart';
import '../modules/auth/register/views/auth_register_view.dart';
import '../modules/auth/select_user/bindings/auth_select_user_binding.dart';
import '../modules/auth/select_user/views/auth_select_user_view.dart';
import '../modules/auth/splash/bindings/auth_splash_binding.dart';
import '../modules/auth/splash/views/auth_splash_view.dart';
import '../modules/company/application_list/bindings/application_list_binding.dart';
import '../modules/company/application_list/views/application_list_view.dart';
import '../modules/company/application_review/bindings/application_review_binding.dart';
import '../modules/company/application_review/views/application_review_view.dart';
import '../modules/company/company_chat/bindings/company_chat_binding.dart';
import '../modules/company/company_chat/views/company_chat_view.dart';
import '../modules/company/company_chat_details/bindings/company_chat_details_binding.dart';
import '../modules/company/company_chat_details/views/company_chat_details_view.dart';
import '../modules/company/company_main_wrapper/bindings/company_main_wrapper_binding.dart';
import '../modules/company/company_main_wrapper/views/company_main_wrapper_view.dart';
import '../modules/company/company_notifications/bindings/company_notifications_binding.dart';
import '../modules/company/company_notifications/views/company_notifications_view.dart';
import '../modules/company/company_profile/bindings/company_profile_binding.dart';
import '../modules/company/company_profile/views/company_profile_view.dart';
import '../modules/company/dashboard/bindings/company_dashboard_binding.dart';
import '../modules/company/dashboard/views/company_dashboard_view.dart';
import '../modules/company/post_job/bindings/company_post_job_binding.dart';
import '../modules/company/post_job/views/company_post_job_view.dart';
import '../modules/company/company_map/bindings/company_map_binding.dart';
import '../modules/company/company_map/views/company_map_view.dart';
import '../modules/job_seeker/Jobseekercongratulations/bindings/jobseekercongratulations_binding.dart';
import '../modules/job_seeker/Jobseekercongratulations/views/jobseekercongratulations_view.dart';
import '../modules/job_seeker/apply_job/bindings/job_seeker_apply_job_binding.dart';
import '../modules/job_seeker/apply_job/views/job_seeker_apply_job_view.dart';
import '../modules/job_seeker/chat/bindings/chat_binding.dart';
import '../modules/job_seeker/chat/views/chat_view.dart';
import '../modules/job_seeker/chat_details/bindings/chat_details_binding.dart';
import '../modules/job_seeker/chat_details/views/chat_details_view.dart';
import '../modules/job_seeker/dashboard/bindings/job_seeker_dashboard_binding.dart';
import '../modules/job_seeker/dashboard/views/job_seeker_dashboard_view.dart';
import '../modules/job_seeker/job_details/bindings/job_seeker_job_details_binding.dart';
import '../modules/job_seeker/job_details/views/job_seeker_job_details_view.dart';
import '../modules/job_seeker/jobseeker_main_wrapper/bindings/main_wrapper_binding.dart';
import '../modules/job_seeker/jobseeker_main_wrapper/views/main_wrapper_view.dart';
import '../modules/job_seeker/my_applications/bindings/job_seeker_my_applications_binding.dart';
import '../modules/job_seeker/my_applications/views/job_seeker_my_applications_view.dart';
import '../modules/job_seeker/cv_analysis/bindings/cv_analysis_binding.dart';
import '../modules/job_seeker/cv_analysis/views/cv_analysis_view.dart';
import '../modules/job_seeker/notifications/bindings/job_seeker_notifications_binding.dart';
import '../modules/job_seeker/notifications/views/job_seeker_notifications_view.dart';
import '../modules/job_seeker/profile/bindings/profile_binding.dart';
import '../modules/job_seeker/profile/views/profile_view.dart';
import '../modules/job_seeker/saved_jobs/bindings/job_seeker_saved_jobs_binding.dart';
import '../modules/job_seeker/saved_jobs/views/job_seeker_saved_jobs_view.dart';
import '../modules/job_seeker/jobs_map/bindings/jobs_map_binding.dart';
import '../modules/job_seeker/jobs_map/views/jobs_map_view.dart';
import '../modules/job_seeker/search_jobs/bindings/job_seeker_search_jobs_binding.dart';
import '../modules/job_seeker/search_jobs/views/job_seeker_search_jobs_view.dart';
import '../modules/job_seeker/recommendations/bindings/recommendations_binding.dart';
import '../modules/job_seeker/recommendations/views/recommendations_view.dart';
import '../modules/job_seeker/my_applications/bindings/application_detail_binding.dart';
import '../modules/job_seeker/my_applications/views/application_detail_view.dart';
import '../modules/pdf_viewer/bindings/pdf_viewer_binding.dart';
import '../modules/pdf_viewer/views/pdf_viewer_view.dart';
import '../modules/job_seeker/company_public/bindings/company_public_binding.dart';
import '../modules/job_seeker/company_public/views/company_public_page.dart';
import '../modules/job_seeker/edit_profile/bindings/edit_profile_binding.dart';
import '../modules/job_seeker/edit_profile/views/edit_profile_view.dart';
import '../modules/job_seeker/edit_profile/views/education_form_view.dart';
import '../modules/job_seeker/edit_profile/views/experience_form_view.dart';
import '../modules/job_seeker/edit_profile/views/skills_editor_view.dart';
import '../modules/job_seeker/edit_profile/views/language_form_view.dart';
import '../modules/job_seeker/edit_profile/views/link_form_view.dart';
import '../services/storage_service.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.splash;

  static final routes = [
    GetPage(
      name: Routes.splash,
      page: () => const AuthSplashView(),
      binding: AuthSplashBinding(),
    ),
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: Routes.authSelectUser,
      page: () => const AuthSelectUserView(),
      binding: AuthSelectUserBinding(),
    ),
    GetPage(
      name: Routes.authLogin,
      page: () => const AuthLoginView(),
      binding: AuthLoginBinding(),
    ),
    GetPage(
      name: Routes.authRegister,
      page: () => const AuthRegisterView(),
      binding: AuthRegisterBinding(),
    ),
    GetPage(
      name: Routes.authForgotPassword,
      page: () => const AuthForgotPasswordView(),
      binding: AuthForgotPasswordBinding(),
    ),
    GetPage(
      name: Routes.jobSeekerDashboard,
      page: () => const JobSeekerDashboardView(),
      binding: JobSeekerDashboardBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.jobSeekerCongratulations,
      page: () => const JobSeekerCongratulationsView(),
      binding: JobSeekerCongratulationsBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.jobSeekerJobDetails,
      page: () => const JobSeekerJobDetailsView(),
      binding: JobSeekerJobDetailsBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.applicationDetail,
      page: () => const ApplicationDetailView(),
      binding: ApplicationDetailBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.jobSeekerApplyJob,
      page: () => const JobSeekerApplyJobView(),
      binding: JobSeekerApplyJobBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.jobSeekerMyApplications,
      page: () => const JobSeekerMyApplicationsView(),
      binding: JobSeekerMyApplicationsBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.jobSeekerNotifications,
      page: () => const JobSeekerNotificationsView(),
      binding: JobSeekerNotificationsBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.jobSeekerCvAnalysis,
      page: () => const CvAnalysisView(),
      binding: CvAnalysisBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.companyDashboard,
      page: () => const CompanyDashboardView(),
      binding: CompanyDashboardBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.company.value),
      ],
    ),
    GetPage(
      name: Routes.companyPostJob,
      page: () => const CompanyPostJobView(),
      binding: CompanyPostJobBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.company.value),
      ],
    ),
    GetPage(
      name: Routes.jobSeekerSavedJobs,
      page: () => const JobSeekerSavedJobsView(),
      binding: JobSeekerSavedJobsBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.jobSeekerChat,
      page: () => const ChatView(),
      binding: ChatBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.jobSeekerChatDetails,
      page: () => const ChatDetailsView(),
      binding: ChatDetailsBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.mainWrapper,
      page: () => const MainWrapperView(),
      binding: MainWrapperBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.jobsMap,
      page: () => const JobsMapView(),
      binding: JobsMapBinding(),
    ),
    GetPage(
      name: Routes.applicationReview,
      page: () => const ApplicationReviewView(),
      binding: ApplicationReviewBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.company.value),
      ],
    ),
    GetPage(
      name: Routes.applicationList,
      page: () => const ApplicationListView(),
      binding: ApplicationListBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.company.value),
      ],
    ),
    GetPage(
      name: Routes.companyMainWrapper,
      page: () => const CompanyMainWrapperView(),
      binding: CompanyMainWrapperBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.company.value),
      ],
    ),
    GetPage(
      name: Routes.companyChat,
      page: () => const CompanyChatView(),
      binding: CompanyChatBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.company.value),
      ],
    ),
    GetPage(
      name: Routes.companyProfile,
      page: () => const CompanyProfileView(),
      binding: CompanyProfileBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.company.value),
      ],
    ),
    GetPage(
      name: Routes.companyChatDetails,
      page: () => const CompanyChatDetailsView(),
      binding: CompanyChatDetailsBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.company.value),
      ],
    ),
    GetPage(
      name: Routes.companyNotifications,
      page: () => const CompanyNotificationsView(),
      binding: CompanyNotificationsBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.company.value),
      ],
    ),
    GetPage(
      name: Routes.jobSeekerSearchJobs,
      page: () => const JobSeekerSearchJobsView(),
      binding: JobSeekerSearchJobsBinding(),
    ),
    GetPage(
      name: Routes.jobSeekerRecommendations,
      page: () => const RecommendationsView(),
      binding: RecommendationsBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.pdfViewer,
      page: () => const PdfViewerView(),
      binding: PdfViewerBinding(),
    ),
    GetPage(
      name: _Paths.COMPANY_MAP,
      page: () => const CompanyMapView(),
      binding: CompanyMapBinding(),
    ),
    GetPage(
      name: Routes.companyPublic,
      page: () => const CompanyPublicPage(),
      binding: CompanyPublicBinding(),
    ),
    GetPage(
      name: Routes.editProfile,
      page: () => EditProfileView(),
      binding: EditProfileBinding(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.experienceForm,
      page: () => const ExperienceFormView(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.educationForm,
      page: () => const EducationFormView(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.skillsEditor,
      page: () => const SkillsEditorView(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.languageForm,
      page: () => const LanguageFormView(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
    GetPage(
      name: Routes.linkForm,
      page: () => const LinkFormView(),
      middlewares: [
        RoleGuardMiddleware(requiredRole: AppUserRole.jobSeeker.value),
      ],
    ),
  ];
}
