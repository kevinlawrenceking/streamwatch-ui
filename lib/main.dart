import 'package:flutter/material.dart';
import 'pages/upload_page.dart';
import 'pages/job_detail_page.dart';
import 'pages/jobs_list_page.dart';

void main() {
  runApp(const StreamWatchApp());
}

class StreamWatchApp extends StatelessWidget {
  const StreamWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreamWatch',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFCE0000)),  // TMZ Red
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => const UploadPage(),
            );
          case '/jobs':
            return MaterialPageRoute(
              builder: (context) => const JobsListPage(),
            );
          case '/job':
            final jobId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => JobDetailPage(jobId: jobId),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const UploadPage(),
            );
        }
      },
    );
  }
}
