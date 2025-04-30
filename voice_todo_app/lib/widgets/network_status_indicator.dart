import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_todo_app/providers/providers.dart';
import 'package:voice_todo_app/services/connectivity_service.dart';

class NetworkStatusIndicator extends ConsumerWidget {
  const NetworkStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatusAsync = ref.watch(networkStatusProvider);
    final isSyncingAsync = ref.watch(isSyncingProvider);
    
    return networkStatusAsync.when(
      data: (status) {
        return isSyncingAsync.when(
          data: (isSyncing) {
            return _buildIndicator(context, status, isSyncing);
          },
          loading: () => _buildIndicator(context, status, false),
          error: (_, __) => _buildIndicator(context, status, false),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildIndicator(BuildContext context, NetworkStatus status, bool isSyncing) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String text;
    
    if (status == NetworkStatus.online) {
      if (isSyncing) {
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.sync;
        text = 'Syncing...';
      } else {
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.cloud_done;
        text = 'Online';
      }
    } else {
      backgroundColor = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
      icon = Icons.cloud_off;
      text = 'Offline - Changes saved locally';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSyncing)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: textColor,
                strokeWidth: 2,
              ),
            )
          else
            Icon(
              icon,
              size: 16,
              color: textColor,
            ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
} 