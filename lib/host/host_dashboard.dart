import 'package:flutter/material.dart';
import '../logout.dart';
import '../notification.dart';

class HostDashboard extends StatelessWidget {
  const HostDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual hostId from auth/session
    const String hostId = 'host123';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Expanded(
                            child: StreamBuilder<List<AppNotification>>(
                              stream: AppNotification.getHostNotifications(hostId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final notifications = snapshot.data ?? [];
                                if (notifications.isEmpty) {
                                  return const Center(child: Text('No notifications.'));
                                }
                                return ListView.builder(
                                  itemCount: notifications.length,
                                  itemBuilder: (context, index) {
                                    final n = notifications[index];
                                    return ListTile(
                                      leading: Icon(n.isRead ? Icons.notifications_none : Icons.notifications_active, color: n.isRead ? Colors.grey : Colors.deepPurple),
                                      title: Text(n.visitorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(n.message),
                                      trailing: n.isRead ? null : IconButton(
                                        icon: const Icon(Icons.check, color: Colors.green),
                                        onPressed: () => AppNotification.markAsRead(n.id),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
        backgroundColor: Color(0xFF6CA4FE),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: Text(
                'Host Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Manage Visitors'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Manage Visitors page
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('View Report'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to View Report page
              },
            ),
            const Divider(),
            const LogoutTile(),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          'Welcome to the Host Dashboard!',
          style: TextStyle(fontSize: 20),
        ),
      ),
      backgroundColor: Color(0xFFD4E9FF),
    );
  }
} 