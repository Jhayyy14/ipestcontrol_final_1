import 'package:flutter/material.dart';

class ModeCard extends StatefulWidget {
  final String label;
  final bool value;
  final IconData icon;
  final Color iconColor;
  final ValueChanged<bool> onChanged;

  const ModeCard({
    super.key,
    required this. label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.onChanged,
  });

  @override
  State<ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<ModeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.value) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ModeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform. scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: GestureDetector(
              onTap: () => widget.onChanged(!widget.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: widget.value
                      ? LinearGradient(
                          colors: [
                            widget.iconColor.withOpacity(0.15),
                            widget.iconColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: widget.value ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.value
                        ? widget.iconColor.withOpacity(0.4)
                        : Colors.grey.shade200,
                    width: widget.value ? 2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.value
                          ? widget.iconColor.withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: widget.value ? 20 : 10,
                      offset: Offset(0, widget.value ? 8 : 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon Container
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: widget.value
                            ? widget.iconColor
                            : widget.iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: widget.value
                            ? [
                                BoxShadow(
                                  color: widget.iconColor.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        widget. icon,
                        color: widget.value ?  Colors.white : widget.iconColor,
                        size: 28,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Label
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: widget. value
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF64748B),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: widget.value ? 1.0 : 0.5,
                            child: Text(
                              widget.value ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 13,
                                color: widget. value
                                    ? widget.iconColor
                                    : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Toggle Switch
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 56,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: widget.value
                            ?  LinearGradient(
                                colors: [
                                  widget.iconColor,
                                  widget.iconColor.withOpacity(0.8),
                                ],
                              )
                            : null,
                        color: widget.value ? null : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: widget.value
                            ? [
                                BoxShadow(
                                  color: widget.iconColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: widget.value
                            ? Alignment.centerRight
                            : Alignment. centerLeft,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: widget.value
                              ? Icon(
                                  Icons.check,
                                  size: 14,
                                  color: widget.iconColor,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}