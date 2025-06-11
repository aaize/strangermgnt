import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AMCDetailsScreen extends StatelessWidget {
  const AMCDetailsScreen({super.key});

  Future<void> _launchWebsite(BuildContext context) async {
    final Uri url = Uri.parse('https://www.amcgroup.edu.in/');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch website')),
      );
    }
  }


  Widget _buildInfoItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(0xFF0A1A2F), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0A1A2F),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A2F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'AMC Engineering College',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Affiliated to VTU • NAAC A+ • NBA Accredited',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 30),

              // Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem(CupertinoIcons.location_solid,
                        "18th KM, Bannerghatta Main Road, Bengaluru, Karnataka"),
                    _buildInfoItem(CupertinoIcons.book_fill,
                        "Programs: B.E (CSE, ECE, CV, ME), MBA, MCA, M.Tech, Ph.D."),
                    _buildInfoItem(CupertinoIcons.star_fill,
                        "Ranked 16th in Times Engineering Survey 2025"),
                    _buildInfoItem(CupertinoIcons.person_3_fill,
                        "Top Recruiters: Infosys, Cognizant, Amazon, Flipkart"),
                    _buildInfoItem(CupertinoIcons.device_laptop,
                        "Fully Wi-Fi enabled campus with 75,000+ books in library"),
                    _buildInfoItem(CupertinoIcons.phone_fill,
                        "Phone: +91 9902044114"),
                    _buildInfoItem(CupertinoIcons.mail_solid,
                        "Email: admissions@amceducation.in"),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Visit Website Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _launchWebsite(context),
                  icon: const Icon(CupertinoIcons.globe),
                  label: const Text(
                    'Visit Official Website',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF0A1A2F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '← Back to Login',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
