/// Defines the channel types supported by HosteDay realtime.
enum HosteDayChannelType {
  /// A public channel that does not require authentication.
  public,

  /// A private channel that requires user authentication.
  private,

  /// A presence channel that requires authentication and tracks members.
  presence,

  /// Requires backend support for end-to-end encrypted channels.
  privateEncrypted,
}
