import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:hire_me/app/modules/job_seeker/dashboard/views/widgets/job_card_widget.dart';
import 'package:hire_me/core/utils/app_color.dart';

import '../controllers/company_public_controller.dart';

class CompanyPublicPage extends GetView<CompanyPublicController> {
  const CompanyPublicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColor.kblue,
        elevation: 0,
        title: Obx(
          () => Text(
            controller.companyName.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppColor.kblue),
          );
        }

        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.business_rounded, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(
                    color: Color(0xFF8A8A9A),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              if (controller.description.isNotEmpty) ...[
                _buildSection('About', controller.description.value),
                const SizedBox(height: 16),
              ],
              _buildLocationMap(),
              const SizedBox(height: 16),
              _buildContactInfo(),
              const SizedBox(height: 22),
              _buildJobsSection(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xffDEE8F8),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: controller.logoUrl.isEmpty
              ? Icon(
                  Icons.business_rounded,
                  color: AppColor.kblue,
                  size: 44,
                )
                  : CachedNetworkImage(
                      imageUrl: controller.logoUrl.value,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Icon(
                        Icons.business_rounded,
                        color: AppColor.kblue,
                        size: 44,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            controller.companyName.value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1A1A2E),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1A1A2E),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF8A8A9A),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMap() {
    final hasLocation =
        controller.latitude.value != 0 || controller.longitude.value != 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 18, color: Color(0xFF1A1A2E)),
              SizedBox(width: 6),
              Text(
                'Location',
                style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (controller.location.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              controller.location.value,
              style: const TextStyle(
                color: Color(0xFF8A8A9A),
                fontSize: 13,
              ),
            ),
          ],
          if (hasLocation) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 150,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      controller.latitude.value,
                      controller.longitude.value,
                    ),
                    zoom: 14,
                  ),
                  markers: controller.markers,
                  zoomGesturesEnabled: false,
                  scrollGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    final hasEmail = controller.email.isNotEmpty;
    final hasPhone = controller.phone.isNotEmpty;
    final hasWebsite = controller.website.isNotEmpty;

    if (!hasEmail && !hasPhone && !hasWebsite) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.contact_page_outlined,
                  size: 18, color: Color(0xFF1A1A2E)),
              SizedBox(width: 6),
              Text(
                'Contact',
                style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasEmail)
            _contactTile(Icons.email_outlined, controller.email.value),
          if (hasPhone)
            _contactTile(Icons.phone_outlined, controller.phone.value),
          if (hasWebsite)
            _contactTile(Icons.language_rounded, controller.website.value),
        ],
      ),
    );
  }

  Widget _contactTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColor.kblue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsSection() {
    return Obx(() {
      if (controller.jobs.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.business_center_outlined,
                  size: 18, color: Color(0xFF1A1A2E)),
              SizedBox(width: 6),
              Text(
                'Open Positions',
                style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...controller.jobs.map(
            (job) => JobCardWidget(
              job: job,
              isSaved: false,
              onSaveTap: () {},
            ),
          ),
        ],
      );
    });
  }
}
