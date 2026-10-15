import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

/// Glass pill text field and 42 px purple send button matching Image A.
class ChatInputBar extends StatefulWidget {
  final ValueChanged<String> onSend;
  final VoidCallback? onMicTap;
  final bool isBusy;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onMicTap,
    this.isBusy = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty || widget.isBusy) return;
    _textController.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Glass pill text field
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF141824).withValues(alpha: 0.28)
                        : Colors.white.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? AppDarkColors.border.withValues(alpha: 0.40)
                          : Colors.white.withValues(alpha: 0.60),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          enabled: !widget.isBusy,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submit(),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E1B3A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ask anything about nutrition…',
                            hintStyle: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF7A7699),
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mic icon inside glass pill
                      GestureDetector(
                        onTap: widget.onMicTap ?? () {
                          // Default mic tap hint
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Voice input is ready to listen'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.mic_none_rounded,
                            size: 22,
                            color: isDark ? const Color(0xFFB4A8FF) : const Color(0xFF5B4BDB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 42 px round purple send button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF5B4BDB),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B4BDB).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: widget.isBusy ? null : _submit,
                child: Center(
                  child: widget.isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          size: 19,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
