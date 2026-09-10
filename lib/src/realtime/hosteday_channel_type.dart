/// Defines the channel types supported by Hosteday realtime.
enum HostedayChannelType {
  /// A public channel that does not require authentication.
  public,

  /// A private channel that requires user authentication.
  private,

  /// A presence channel that requires authentication and tracks members.
  presence,

  /// Requires backend support for end-to-end encrypted channels.
  privateEncrypted,
}

/// Deprecated spelling of [HostedayChannelType].
@Deprecated('Use HostedayChannelType instead.')
typedef HosteDayChannelType = HostedayChannelType;
