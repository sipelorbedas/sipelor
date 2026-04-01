import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Model for a single legal document section
class LegalSection {
  final String title;
  final String content;

  const LegalSection({
    required this.title,
    required this.content,
  });
}

/// Legal review status enum
enum LegalReviewStatus {
  pendingReview,
  underReview,
  approved,
  requiresRevision,
}

/// Reusable legal document template screen with professional legal review UI.
/// Used by PrivacyPolicyScreen and TermsOfServiceScreen.
class LegalDocumentTemplate extends StatefulWidget {
  final String title;
  final String subtitle;
  final String documentNumber;
  final String version;
  final String effectiveDate;
  final String lastUpdated;
  final LegalReviewStatus reviewStatus;
  final List<LegalSection> sections;
  final String contactEmail;
  final String contactPhone;
  final Color headerGradientStart;
  final Color headerGradientEnd;
  final String footerNote;
  final IconData headerIcon;

  const LegalDocumentTemplate({
    super.key,
    required this.title,
    required this.subtitle,
    required this.documentNumber,
    required this.version,
    required this.effectiveDate,
    required this.lastUpdated,
    required this.reviewStatus,
    required this.sections,
    required this.contactEmail,
    required this.contactPhone,
    this.headerGradientStart = const Color(0xFF1A237E),
    this.headerGradientEnd = const Color(0xFF0277BD),
    this.footerNote =
        'Dengan menggunakan SIPELOR BEDAS, Anda telah membaca, memahami, dan menyetujui isi dokumen ini.',
    this.headerIcon = Icons.gavel,
  });

  @override
  State<LegalDocumentTemplate> createState() => _LegalDocumentTemplateState();
}

class _LegalDocumentTemplateState extends State<LegalDocumentTemplate> {
  final _scrollController = ScrollController();
  bool _showTOC = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Returns (bgColor, textColor, label, icon) based on review status
  ({
    Color bgColor,
    Color textColor,
    String label,
    IconData icon,
    String badge,
  })
  get _reviewStatusInfo {
    switch (widget.reviewStatus) {
      case LegalReviewStatus.pendingReview:
        return (
          bgColor: const Color(0xFFFFF8E1),
          textColor: const Color(0xFFFF8F00),
          label: 'Menunggu Review Tim Legal',
          icon: Icons.pending_outlined,
          badge: 'DRAFT',
        );
      case LegalReviewStatus.underReview:
        return (
          bgColor: const Color(0xFFE3F2FD),
          textColor: const Color(0xFF1565C0),
          label: 'Sedang Dalam Review',
          icon: Icons.rate_review_outlined,
          badge: 'REVIEW',
        );
      case LegalReviewStatus.approved:
        return (
          bgColor: const Color(0xFFE8F5E9),
          textColor: const Color(0xFF2E7D32),
          label: 'Telah Disetujui Tim Legal',
          icon: Icons.verified_outlined,
          badge: 'SAH',
        );
      case LegalReviewStatus.requiresRevision:
        return (
          bgColor: const Color(0xFFFFEBEE),
          textColor: const Color(0xFFC62828),
          label: 'Perlu Revisi',
          icon: Icons.edit_note_outlined,
          badge: 'REVISI',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _reviewStatusInfo;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildReviewStatusBanner(status),
                _buildDocumentMetadata(),
                if (_showTOC) _buildTableOfContents(),
                _buildSections(),
                _buildFooter(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: widget.headerGradientStart,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        Tooltip(
          message: _showTOC ? 'Tutup Daftar Isi' : 'Daftar Isi',
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _showTOC ? Icons.close : Icons.format_list_bulleted,
                key: ValueKey(_showTOC),
                color: Colors.white,
              ),
            ),
            onPressed: () => setState(() => _showTOC = !_showTOC),
          ),
        ),
      ],
      title: Text(
        widget.title,
        style: GoogleFonts.mulish(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _buildHeaderBackground(),
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.headerGradientStart, widget.headerGradientEnd],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      widget.headerIcon,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.mulish(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle,
                          style: GoogleFonts.mulish(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildHeaderChip(Icons.tag, widget.documentNumber),
                            const SizedBox(width: 8),
                            _buildHeaderChip(Icons.history, widget.version),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.mulish(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStatusBanner(
    ({
      Color bgColor,
      Color textColor,
      String label,
      IconData icon,
      String badge,
    })
    status,
  ) {
    return Container(
      width: double.infinity,
      color: status.bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(status.icon, size: 22, color: status.textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: GoogleFonts.mulish(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: status.textColor,
                  ),
                ),
                Text(
                  'Dokumen sedang dalam proses review oleh tim legal DISPORA Kabupaten Bandung.',
                  style: GoogleFonts.mulish(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: status.textColor.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: status.textColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.badge,
              style: GoogleFonts.mulish(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: status.textColor,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentMetadata() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: widget.headerGradientStart,
                ),
                const SizedBox(width: 8),
                Text(
                  'Informasi Dokumen',
                  style: GoogleFonts.mulish(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showTOC = !_showTOC),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.headerGradientStart.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.format_list_bulleted,
                          size: 12,
                          color: widget.headerGradientStart,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Daftar Isi',
                          style: GoogleFonts.mulish(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.headerGradientStart,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _buildMetaRow(
                  Icons.tag,
                  'Nomor Dokumen',
                  widget.documentNumber,
                ),
                const SizedBox(height: 10),
                _buildMetaRow(Icons.history, 'Versi', widget.version),
                const SizedBox(height: 10),
                _buildMetaRow(
                  Icons.calendar_today,
                  'Tanggal Berlaku',
                  widget.effectiveDate,
                ),
                const SizedBox(height: 10),
                _buildMetaRow(
                  Icons.update,
                  'Terakhir Diperbarui',
                  widget.lastUpdated,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: widget.headerGradientStart.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.mulish(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryDark,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.mulish(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTableOfContents() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.headerGradientStart.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(
                  Icons.format_list_bulleted,
                  size: 16,
                  color: widget.headerGradientStart,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daftar Isi',
                  style: GoogleFonts.mulish(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.sections.length} pasal',
                  style: GoogleFonts.mulish(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...widget.sections.asMap().entries.map((entry) {
            final idx = entry.key;
            final section = entry.value;
            final isLast = idx == widget.sections.length - 1;
            return Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _showTOC = false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: widget.headerGradientStart.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${idx + 1}',
                            style: GoogleFonts.mulish(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: widget.headerGradientStart,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            section.title,
                            style: GoogleFonts.mulish(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.secondaryDark.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isLast)
                  const Divider(
                    height: 1,
                    indent: 52,
                    endIndent: 16,
                    color: Color(0xFFEEEEEE),
                  ),
              ],
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildSections() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          for (int i = 0; i < widget.sections.length; i++) ...[
            _buildSectionCard(i + 1, widget.sections[i]),
            if (i < widget.sections.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard(int number, LegalSection section) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.headerGradientStart.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: widget.headerGradientStart.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.headerGradientStart,
                        widget.headerGradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$number',
                    style: GoogleFonts.mulish(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.title,
                    style: GoogleFonts.mulish(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Section content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              section.content,
              style: GoogleFonts.mulish(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryDark,
                height: 1.75,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          // Review timeline card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timeline,
                      size: 16,
                      color: widget.headerGradientStart,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status Review Legal',
                      style: GoogleFonts.mulish(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTimelineStep(
                  icon: Icons.check_circle,
                  color: const Color(0xFF2E7D32),
                  label: 'Dokumen Dibuat',
                  date: widget.effectiveDate,
                  isDone: true,
                ),
                _buildTimelineStep(
                  icon: widget.reviewStatus == LegalReviewStatus.approved
                      ? Icons.check_circle
                      : Icons.pending_outlined,
                  color: widget.reviewStatus == LegalReviewStatus.approved
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFFF8F00),
                  label: 'Review Tim Legal',
                  date: widget.reviewStatus == LegalReviewStatus.approved
                      ? widget.lastUpdated
                      : 'Dalam Proses',
                  isDone: widget.reviewStatus == LegalReviewStatus.approved,
                ),
                _buildTimelineStep(
                  icon: widget.reviewStatus == LegalReviewStatus.approved
                      ? Icons.verified
                      : Icons.verified_outlined,
                  color: widget.reviewStatus == LegalReviewStatus.approved
                      ? const Color(0xFF2E7D32)
                      : AppColors.secondaryDark.withValues(alpha: 0.3),
                  label: 'Persetujuan Final',
                  date: widget.reviewStatus == LegalReviewStatus.approved
                      ? widget.lastUpdated
                      : 'Belum',
                  isDone: widget.reviewStatus == LegalReviewStatus.approved,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Contact card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [widget.headerGradientStart, widget.headerGradientEnd],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pertanyaan tentang dokumen ini?',
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hubungi tim legal DISPORA Kabupaten Bandung',
                  style: GoogleFonts.mulish(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 14),
                _buildContactRow(Icons.email_outlined, widget.contactEmail),
                const SizedBox(height: 8),
                _buildContactRow(Icons.phone_outlined, widget.contactPhone),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Acknowledgment
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: widget.headerGradientStart.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.footerNote,
                    style: GoogleFonts.mulish(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryDark,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '© 2026 SIPELOR BEDAS · Dinas Pemuda dan Olahraga Kabupaten Bandung',
            style: GoogleFonts.mulish(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryDark.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required Color color,
    required String label,
    required String date,
    required bool isDone,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, size: 20, color: color),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: const Color(0xFFE0E0E0),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.mulish(
                    fontSize: 13,
                    fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                    color: isDone ? AppColors.primaryDark : AppColors.secondaryDark,
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.mulish(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.mulish(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
