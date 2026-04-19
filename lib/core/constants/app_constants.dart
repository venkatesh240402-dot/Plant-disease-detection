class AppConstants {
  static const double CONFIDENCE_THRESHOLD_HIGH = 0.85;
  static const double CONFIDENCE_THRESHOLD_MID = 0.50;
  static const double CONFIDENCE_THRESHOLD_ROOT = 0.75;
  static const double IDENTITY_THRESHOLD_SAME = 0.80;
  static const double IDENTITY_THRESHOLD_UNCERTAIN = 0.50;
  static const double GPS_RADIUS_METRES = 5.0;
  static const int FRAME_SAMPLE_RATE_FPS = 3;
  static const double FRAME_DIFF_THRESHOLD = 0.08;
  static const double BLUR_THRESHOLD_LAPLACIAN = 100.0;
  static const int API_TIMEOUT_SECONDS = 3;
  static const int SYNC_BATCH_SIZE = 50;
  static const int LLM_CONTEXT_TOKENS = 2048;
  static const int MODEL_ROLLBACK_HOURS = 48;
}
