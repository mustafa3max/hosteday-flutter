import 'package:hosteday_flutter/hosteday_flutter.dart';

abstract final class RealtimeUtils {
  static String normalizedChannelName(
    String channel,
    HosteDayChannelType type,
  ) {
    final normalized = channel.trim();

    if (normalized.isEmpty) {
      throw const FormatException('اسم القناة مطلوب.');
    }

    switch (type) {
      case HosteDayChannelType.public:
        return normalized;

      case HosteDayChannelType.private:
        return normalized.startsWith('private-')
            ? normalized
            : 'private-$normalized';

      case HosteDayChannelType.presence:
        return normalized.startsWith('presence-')
            ? normalized
            : 'presence-$normalized';

      case HosteDayChannelType.privateEncrypted:
        if (normalized.startsWith('private-encrypted-')) {
          return normalized;
        }

        if (normalized.startsWith('private-')) {
          return 'private-encrypted-'
              '${normalized.substring('private-'.length)}';
        }

        return 'private-encrypted-$normalized';
    }
  }

  static String channelTypeLabel(HosteDayChannelType type) {
    switch (type) {
      case HosteDayChannelType.public:
        return 'Public';
      case HosteDayChannelType.private:
        return 'Private';
      case HosteDayChannelType.presence:
        return 'Presence';
      case HosteDayChannelType.privateEncrypted:
        return 'Private Encrypted';
    }
  }
}
