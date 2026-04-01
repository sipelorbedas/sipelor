/// Coverage test file - orchestrates all test files for coverage report
/// Run with: flutter test --coverage
/// Then generate report: genhtml coverage/lcov.info -o coverage/html
library;

// ─── Model Tests ─────────────────────────────────────────────────────────────
import 'models/booking_test.dart' as booking_model_test;
import 'models/field_test.dart' as field_model_test;
import 'models/venue_test.dart' as venue_model_test;
import 'models/review_test.dart' as review_model_test;
import 'models/staff_test.dart' as staff_model_test;
import 'models/user_role_test.dart' as user_role_model_test;
import 'models/time_slot_test.dart' as time_slot_model_test;
import 'models/maintenance_schedule_test.dart' as maintenance_schedule_model_test;
import 'models/revenue_analytics_test.dart' as revenue_analytics_model_test;
import 'models/chat_message_test.dart' as chat_message_model_test;
import 'models/payment_models_test.dart' as payment_models_test;
import 'models/push_notification_test.dart' as push_notification_model_test;

// ─── Repository Tests ────────────────────────────────────────────────────────
import 'repositories/booking_repository_test.dart' as booking_repository_test;

// ─── Provider Tests ──────────────────────────────────────────────────────────
import 'providers/booking_providers_test.dart' as booking_providers_test;

// ─── Service Tests ───────────────────────────────────────────────────────────
import 'services/booking_expiration_service_test.dart' as booking_expiration_service_test;
import 'services/supabase_service_test.dart' as supabase_service_test;
import 'services/error_tracking_service_test.dart' as error_tracking_service_test;
import 'services/rate_limiter_service_test.dart' as rate_limiter_service_test;
import 'services/notification_service_test.dart' as notification_service_test;
import 'services/chat_service_test.dart' as chat_service_test;
import 'services/audit_service_test.dart' as audit_service_test;
import 'services/biometric_auth_service_test.dart' as biometric_auth_service_test;
import 'services/auto_logout_service_test.dart' as auto_logout_service_test;
import 'services/password_service_test.dart' as password_service_test;
import 'services/email_verification_service_test.dart' as email_verification_service_test;
import 'services/file_encryption_service_test.dart' as file_encryption_service_test;
import 'services/encrypted_preferences_service_test.dart' as encrypted_preferences_service_test;
import 'services/secure_storage_service_test.dart' as secure_storage_service_test;
import 'services/staff_service_test.dart' as staff_service_test;
import 'services/maintenance_service_test.dart' as maintenance_service_test;
import 'services/revenue_analytics_service_test.dart' as revenue_analytics_service_test;
import 'services/notification_helper_test.dart' as notification_helper_test;
import 'services/bulk_operations_service_test.dart' as bulk_operations_service_test;
import 'services/content_moderation_service_test.dart' as content_moderation_service_test;
import 'services/deep_link_handler_test.dart' as deep_link_handler_test;
import 'services/onboarding_service_test.dart' as onboarding_service_test;
import 'services/social_auth_service_test.dart' as social_auth_service_test;
import 'services/push_notification_service_test.dart' as push_notification_service_test;
import 'services/owasp_security_checks_test.dart' as owasp_security_checks_test;
import 'services/security_education_service_test.dart' as security_education_service_test;
import 'services/certificate_rotation_service_test.dart' as certificate_rotation_service_test;

// ─── Security Tests ──────────────────────────────────────────────────────────
import 'security/rasp_security_test.dart' as rasp_security_test;
import 'security/anti_tamper_guard_test.dart' as anti_tamper_guard_test;
import 'security/data_integrity_verifier_test.dart' as data_integrity_verifier_test;
import 'security/network_security_manager_test.dart' as network_security_manager_test;
import 'security/app_security_manager_test.dart' as app_security_manager_test;

// ─── Config Tests ────────────────────────────────────────────────────────────
import 'config/ssl_config_test.dart' as ssl_config_test;
import 'config/build_config_test.dart' as build_config_test;

// ─── Constant Tests ──────────────────────────────────────────────────────────
import 'constants/app_colors_test.dart' as app_colors_test;
import 'constants/admin_colors_test.dart' as admin_colors_test;

// ─── Utility Tests ───────────────────────────────────────────────────────────
import 'utils/input_sanitizer_test.dart' as input_sanitizer_test;
import 'utils/booking_formatter_test.dart' as booking_formatter_test;
import 'utils/password_validator_test.dart' as password_validator_test;
import 'utils/session_manager_test.dart' as session_manager_test;
import 'utils/secure_logger_test.dart' as secure_logger_test;
import 'utils/time_helper_test.dart' as time_helper_test;
import 'utils/payment_formatters_test.dart' as payment_formatters_test;
import 'utils/security_config_test.dart' as security_config_test;

// ─── Widget Tests ────────────────────────────────────────────────────────────
import 'widgets/home_screen_test.dart' as home_screen_test;
import 'widgets/sign_in_screen_test.dart' as sign_in_screen_test;
import 'widgets/sign_up_screen_test.dart' as sign_up_screen_test;
import 'widgets/user_bookings_screen_test.dart' as user_bookings_screen_test;
import 'widgets/booking_card_test.dart' as booking_card_test;
import 'widgets/booking_detail_screen_test.dart' as booking_detail_screen_test;
import 'widgets/booking_confirmation_screen_test.dart' as booking_confirmation_screen_test;
import 'widgets/e_ticket_screen_test.dart' as e_ticket_screen_test;
import 'widgets/profile_screen_test.dart' as profile_screen_test;
import 'widgets/edit_profile_screen_test.dart' as edit_profile_screen_test;
import 'widgets/venue_list_screen_test.dart' as venue_list_screen_test;
import 'widgets/venue_detail_screen_test.dart' as venue_detail_screen_test;
import 'widgets/user_chat_screen_test.dart' as user_chat_screen_test;
import 'widgets/admin_dashboard_screen_test.dart' as admin_dashboard_screen_test;
import 'widgets/admin_bookings_screen_test.dart' as admin_bookings_screen_test;
import 'widgets/admin_field_management_screen_test.dart' as admin_field_management_screen_test;
import 'widgets/admin_revenue_analytics_screen_test.dart' as admin_revenue_analytics_screen_test;
import 'widgets/admin_staff_management_screen_test.dart' as admin_staff_management_screen_test;
import 'widgets/payment_confirmation_screen_test.dart' as payment_confirmation_screen_test;
import 'widgets/security_settings_screen_test.dart' as security_settings_screen_test;

// ─── Integration Tests ───────────────────────────────────────────────────────
import 'integration/booking_flow_test.dart' as booking_flow_test;
import 'integration/authentication_flow_test.dart' as authentication_flow_test;
import 'integration/chat_flow_test.dart' as chat_flow_test;
import 'integration/user_booking_flow_test.dart' as user_booking_flow_test;
import 'integration/admin_management_flow_test.dart' as admin_management_flow_test;

void main() {
  // ─── Models ─────────────────────────────────────────────────────────────
  booking_model_test.main();
  field_model_test.main();
  venue_model_test.main();
  review_model_test.main();
  staff_model_test.main();
  user_role_model_test.main();
  time_slot_model_test.main();
  maintenance_schedule_model_test.main();
  revenue_analytics_model_test.main();
  chat_message_model_test.main();
  payment_models_test.main();
  push_notification_model_test.main();

  // ─── Repositories ────────────────────────────────────────────────────────
  booking_repository_test.main();

  // ─── Providers ───────────────────────────────────────────────────────────
  booking_providers_test.main();

  // ─── Services ────────────────────────────────────────────────────────────
  booking_expiration_service_test.main();
  supabase_service_test.main();
  error_tracking_service_test.main();
  rate_limiter_service_test.main();
  notification_service_test.main();
  chat_service_test.main();
  audit_service_test.main();
  biometric_auth_service_test.main();
  auto_logout_service_test.main();
  password_service_test.main();
  email_verification_service_test.main();
  file_encryption_service_test.main();
  encrypted_preferences_service_test.main();
  secure_storage_service_test.main();
  staff_service_test.main();
  maintenance_service_test.main();
  revenue_analytics_service_test.main();
  notification_helper_test.main();
  bulk_operations_service_test.main();
  content_moderation_service_test.main();
  deep_link_handler_test.main();
  onboarding_service_test.main();
  social_auth_service_test.main();
  push_notification_service_test.main();
  owasp_security_checks_test.main();
  security_education_service_test.main();
  certificate_rotation_service_test.main();

  // ─── Security ────────────────────────────────────────────────────────────
  rasp_security_test.main();
  anti_tamper_guard_test.main();
  data_integrity_verifier_test.main();
  network_security_manager_test.main();
  app_security_manager_test.main();

  // ─── Config ──────────────────────────────────────────────────────────────
  ssl_config_test.main();
  build_config_test.main();

  // ─── Constants ───────────────────────────────────────────────────────────
  app_colors_test.main();
  admin_colors_test.main();

  // ─── Utils ───────────────────────────────────────────────────────────────
  input_sanitizer_test.main();
  booking_formatter_test.main();
  password_validator_test.main();
  session_manager_test.main();
  secure_logger_test.main();
  time_helper_test.main();
  payment_formatters_test.main();
  security_config_test.main();

  // ─── Widgets ─────────────────────────────────────────────────────────────
  home_screen_test.main();
  sign_in_screen_test.main();
  sign_up_screen_test.main();
  user_bookings_screen_test.main();
  booking_card_test.main();
  booking_detail_screen_test.main();
  booking_confirmation_screen_test.main();
  e_ticket_screen_test.main();
  profile_screen_test.main();
  edit_profile_screen_test.main();
  venue_list_screen_test.main();
  venue_detail_screen_test.main();
  user_chat_screen_test.main();
  admin_dashboard_screen_test.main();
  admin_bookings_screen_test.main();
  admin_field_management_screen_test.main();
  admin_revenue_analytics_screen_test.main();
  admin_staff_management_screen_test.main();
  payment_confirmation_screen_test.main();
  security_settings_screen_test.main();

  // ─── Integration ─────────────────────────────────────────────────────────
  booking_flow_test.main();
  authentication_flow_test.main();
  chat_flow_test.main();
  user_booking_flow_test.main();
  admin_management_flow_test.main();
}
