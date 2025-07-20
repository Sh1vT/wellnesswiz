import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wellwiz/utils/typing_indicator.dart';

class MessageTile extends StatelessWidget {
  const MessageTile({
    Key? key,
    required this.sendByMe,
    this.message,
    required this.senderName,
    this.avatarUrl,
    this.timestamp,
    this.typingIndicator = false,
    this.senderId,
  }) : super(key: key);

  final bool sendByMe;
  final String? message;
  final String senderName;
  final String? senderId;
  final DateTime? timestamp;
  final String? avatarUrl;
  final bool typingIndicator;

  @override
  Widget build(BuildContext context) {
    final themeGreen = const Color.fromARGB(255, 106, 172, 67);
    final themeGray = const Color.fromRGBO(97, 97, 97, 1);
    final timeStr = timestamp != null
        ? TimeOfDay.fromDateTime(timestamp!).format(context)
        : '';
    final avatar = avatarUrl != null && avatarUrl!.isNotEmpty
        ? CircleAvatar(
            radius: 18,
            backgroundImage: avatarUrl!.startsWith('http')
                ? NetworkImage(avatarUrl!)
                : AssetImage(avatarUrl!) as ImageProvider,
            backgroundColor: Colors.grey.shade300,
          )
        : CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade300,
            child: Icon(
              Icons.account_circle,
              color: sendByMe ? themeGreen : themeGray,
              size: 26,
            ),
          );

    Widget messageContent;
    if (typingIndicator) {
      messageContent = const TypingIndicator();
    } else {
      messageContent = MarkdownBody(
        data: message ?? '',
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: TextStyle(
            fontSize: 15,
            color: sendByMe ? Colors.white : themeGray,
            fontFamily: 'Mulish',
          ),
        ),
        onTapLink: (text, href, title) async {
          if (href != null) {
            await launchUrl(Uri.parse(href));
          }
        },
      );
    }

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 110, // Minimum width for short messages
        maxWidth:
            MediaQuery.of(context).size.width * 0.72, // Slightly wider max
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: sendByMe ? themeGreen : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(sendByMe ? 14 : 4),
            bottomRight: Radius.circular(sendByMe ? 4 : 14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: sendByMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (senderName.isNotEmpty)
              Text(
                sendByMe ? 'You' : senderName,
                style: TextStyle(
                  fontSize: 12,
                  color: sendByMe ? Colors.white70 : themeGreen,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Mulish',
                ),
              ),
            if (senderName.isNotEmpty) const SizedBox(height: 2),
            messageContent,
            if (timeStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: sendByMe ? Colors.white60 : Colors.grey.shade500,
                    fontFamily: 'Mulish',
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: sendByMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: sendByMe
            ? [
                bubble,
                const SizedBox(width: 6),
                // Avatar is bottom-aligned, but add extra bottom padding for visual flush
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: avatar,
                ),
              ]
            : [
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: avatar,
                ),
                const SizedBox(width: 6),
                bubble,
              ],
      ),
    );
  }
}
