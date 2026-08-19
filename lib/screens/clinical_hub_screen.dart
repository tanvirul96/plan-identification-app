import 'package:flutter/material.dart';
import '../models/drug_interaction_model.dart';
import '../services/dosage_calculator_service.dart';
import '../services/drug_interaction_service.dart';
import '../services/localization_service.dart';
import '../services/rag_service.dart';
import '../services/toxicity_service.dart';
import '../widgets/neu_widgets.dart';

class ClinicalHubScreen extends StatefulWidget {
  final RagService ragService;
  final String? initialPlant;

  const ClinicalHubScreen({
    super.key,
    required this.ragService,
    this.initialPlant,
  });

  @override
  State<ClinicalHubScreen> createState() => _ClinicalHubScreenState();
}

class _ClinicalHubScreenState extends State<ClinicalHubScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final LocalizationService _loc = LocalizationService();
  final DrugInteractionService _drugService = DrugInteractionService();
  final ToxicityService _toxicityService = ToxicityService();

  // Drug Interaction State
  String _selectedInteractionPlant = 'All';
  final TextEditingController _drugSearchController = TextEditingController();

  // Dosage Calculator State
  late String _selectedDosePlant;
  PatientAgeGroup _selectedAgeGroup = PatientAgeGroup.adult;
  HerbalFormulation _selectedFormulation = HerbalFormulation.kwatha;
  double _patientWeight = 65.0;
  DosageResult? _calculatedDosage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedDosePlant = widget.initialPlant ?? 'Neem';
    _recalculateDosage();
  }

  void _recalculateDosage() {
    setState(() {
      _calculatedDosage = DosageCalculatorService.calculateDosage(
        plantName: _selectedDosePlant,
        ageGroup: _selectedAgeGroup,
        weightKg: _patientWeight,
        formulation: _selectedFormulation,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _drugSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final primary = NeuTheme.primaryColor(context);
    final onSurf = NeuTheme.onSurface(context);
    final isBn = _loc.isBangla;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            // Clinical Hub Tab Selector
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: NeuContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(6),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: primary,
                  unselectedLabelColor: NeuTheme.subtleText(context),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.compare_arrows, size: 20),
                      text: isBn ? "ওষুধ মিথস্ক্রিয়া" : "Drug Interaction",
                    ),
                    Tab(
                      icon: const Icon(Icons.calculate_outlined, size: 20),
                      text: isBn ? "মাত্রা ক্যালকুলেটর" : "Dosage Calc",
                    ),
                    Tab(
                      icon: const Icon(Icons.warning_amber_rounded, size: 20),
                      text: isBn ? "বিষাক্ততা ও জরুরি" : "Toxicity & ER",
                    ),
                  ],
                ),
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDrugInteractionsTab(isBn, primary, onSurf),
                  _buildDosageCalculatorTab(isBn, primary, onSurf),
                  _buildToxicityGuideTab(isBn, primary, onSurf),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 1: Drug-Herb Interaction Checker ─────────────────────────────────

  Widget _buildDrugInteractionsTab(bool isBn, Color primary, Color onSurf) {
    final plantOptions = ['All'] + widget.ragService.plants.map((p) => p.localName).toList();
    final interactions = _drugService.searchInteractions(
      plantName: _selectedInteractionPlant,
      drugQuery: _drugSearchController.text.trim(),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Filter Card
        NeuContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBn ? "🔍 ভেষজ ও ড্রাগ মিথস্ক্রিয়া পরীক্ষা" : "🔍 Drug-Herb Interaction Checker",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: onSurf),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: NeuInsetContainer(
                      borderRadius: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: plantOptions.contains(_selectedInteractionPlant)
                              ? _selectedInteractionPlant
                              : 'All',
                          isExpanded: true,
                          dropdownColor: NeuTheme.surfaceColor(context),
                          items: plantOptions.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(
                                p == 'All' ? (isBn ? 'সব উদ্ভিদ' : 'All Plants') : _loc.getPlantDisplayName(p),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurf),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedInteractionPlant = val);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: NeuInsetContainer(
                      borderRadius: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: TextField(
                        controller: _drugSearchController,
                        decoration: InputDecoration(
                          hintText: isBn ? "ওষুধ খুঁজুন (যেমন Metformin)..." : "Search drug (e.g. Aspirin)...",
                          hintStyle: TextStyle(fontSize: 12, color: NeuTheme.subtleText(context)),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.medication, size: 18, color: primary),
                        ),
                        style: TextStyle(fontSize: 13, color: onSurf),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Interactions List
        if (interactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.health_and_safety_outlined, size: 48, color: primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    isBn ? "কোনো ক্ষতিকর মিথস্ক্রিয়া পাওয়া যায়নি" : "No Critical Interactions Found",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: onSurf),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isBn
                        ? "নির্বাচিত ফিল্টারের সাথে কোনো বিপজ্জনক ড্রাগ সংমিশ্রণ তালিকাভুক্ত নেই।"
                        : "Selected combination has no documented severe adverse CYP interactions.",
                    style: TextStyle(fontSize: 12, color: NeuTheme.subtleText(context)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...interactions.map((item) => _buildInteractionCard(item, isBn, onSurf)),
      ],
    );
  }

  Widget _buildInteractionCard(HerbDrugInteraction item, bool isBn, Color onSurf) {
    Color badgeColor;
    String badgeText;
    IconData icon;

    switch (item.severity) {
      case InteractionSeverity.contraindicated:
        badgeColor = Colors.red.shade700;
        badgeText = isBn ? "🔴 সম্পূর্ণ নিষিদ্ধ" : "🔴 Contraindicated";
        icon = Icons.block;
        break;
      case InteractionSeverity.moderateCaution:
        badgeColor = Colors.orange.shade800;
        badgeText = isBn ? "🟡 বিশেষ সতর্কতা" : "🟡 Moderate Caution";
        icon = Icons.warning_amber;
        break;
      case InteractionSeverity.safe:
        badgeColor = Colors.green.shade700;
        badgeText = isBn ? "🟢 নিরাপদ" : "🟢 Safe";
        icon = Icons.check_circle_outline;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: NeuContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(icon, color: badgeColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${_loc.getPlantDisplayName(item.plantLocalName)} ⟷ ${item.drugName}",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: onSurf),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: badgeColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "${isBn ? 'ওষুধের ধরন' : 'Drug Class'}: ${item.drugClass}",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: NeuTheme.primaryColor(context)),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              isBn ? "প্রভাব" : "Clinical Effect",
              isBn ? item.clinicalEffectBn : item.clinicalEffectEn,
              onSurf,
            ),
            const SizedBox(height: 6),
            _buildInfoRow(
              isBn ? "প্রক্রিয়া" : "Mechanism",
              isBn ? item.mechanismBn : item.mechanismEn,
              onSurf,
            ),
            const SizedBox(height: 6),
            _buildInfoRow(
              isBn ? "পরামর্শ" : "Advisory",
              isBn ? item.recommendationBn : item.recommendationEn,
              onSurf,
              isHighlight: true,
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 2: Dosage & Formulation Calculator ───────────────────────────────

  Widget _buildDosageCalculatorTab(bool isBn, Color primary, Color onSurf) {
    final plantOptions = widget.ragService.plants.map((p) => p.localName).toList();
    final res = _calculatedDosage;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Calculator Input Card
        NeuContainer(
          borderRadius: 22,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calculate, color: primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    isBn ? "ভেষজ মাত্রা ও ডোজ ক্যালকুলেটর" : "Ayurvedic Dosage & Formulation Calc",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: onSurf),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Plant & Age Selector
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isBn ? "উদ্ভিদ নির্বাচন" : "Select Plant",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurf)),
                        const SizedBox(height: 6),
                        NeuInsetContainer(
                          borderRadius: 14,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: plantOptions.contains(_selectedDosePlant) ? _selectedDosePlant : plantOptions.first,
                              isExpanded: true,
                              dropdownColor: NeuTheme.surfaceColor(context),
                              items: plantOptions.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Text(_loc.getPlantDisplayName(p),
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurf)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  _selectedDosePlant = val;
                                  _recalculateDosage();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isBn ? "বয়সের ধরন" : "Patient Age",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurf)),
                        const SizedBox(height: 6),
                        NeuInsetContainer(
                          borderRadius: 14,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<PatientAgeGroup>(
                              value: _selectedAgeGroup,
                              isExpanded: true,
                              dropdownColor: NeuTheme.surfaceColor(context),
                              items: [
                                DropdownMenuItem(
                                  value: PatientAgeGroup.adult,
                                  child: Text(isBn ? "প্রাপ্তবয়স্ক" : "Adult",
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurf)),
                                ),
                                DropdownMenuItem(
                                  value: PatientAgeGroup.pediatric,
                                  child: Text(isBn ? "শিশু (২-১২)" : "Pediatric",
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurf)),
                                ),
                                DropdownMenuItem(
                                  value: PatientAgeGroup.geriatric,
                                  child: Text(isBn ? "বয়োজ্যেষ্ঠ" : "Geriatric",
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurf)),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  _selectedAgeGroup = val;
                                  _recalculateDosage();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Weight Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isBn ? "রোগীর ওজন:" : "Patient Weight:",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurf)),
                  NeuContainer(
                    isPressed: true,
                    borderRadius: 10,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    blurRadius: 4,
                    child: Text("${_patientWeight.round()} kg",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primary)),
                  ),
                ],
              ),
              Slider(
                value: _patientWeight,
                min: 10,
                max: 120,
                divisions: 22,
                activeColor: primary,
                onChanged: (val) {
                  _patientWeight = val;
                  _recalculateDosage();
                },
              ),
              const SizedBox(height: 10),

              // Formulation Preset Chips
              Text(isBn ? "প্রস্তুত প্রণালী (Formulation):" : "Formulation Type:",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurf)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFormulationChip(HerbalFormulation.kwatha, isBn ? "ক্বাথ (Decoction)" : "Decoction (Kwatha)"),
                  _buildFormulationChip(HerbalFormulation.swarasa, isBn ? "স্বরস (Fresh Juice)" : "Fresh Juice (Swarasa)"),
                  _buildFormulationChip(HerbalFormulation.churna, isBn ? "চূর্ণ (Powder)" : "Powder (Churna)"),
                  _buildFormulationChip(HerbalFormulation.kalka, isBn ? "কল্ক (Paste)" : "Paste (Kalka)"),
                  _buildFormulationChip(HerbalFormulation.arishta, isBn ? "অরিষ্ট (Elixir)" : "Elixir (Arishta)"),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Calculated Result Card
        if (res != null)
          NeuContainer(
            borderRadius: 22,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isBn ? res.formulationNameBn : res.formulationNameEn,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primary),
                    ),
                    NeuContainer(
                      isPressed: true,
                      borderRadius: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: Text(
                        "${res.calculatedDoseAmount} ${res.unit}",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primary),
                      ),
                    ),
                  ],
                ),
                Divider(height: 24, color: NeuTheme.shadowDark(context).withValues(alpha: 0.2)),
                _buildInfoRow(isBn ? "সেবন মাত্রা ও সময়" : "Frequency & Timing",
                    "${isBn ? res.frequencyBn : res.frequencyEn} • ${isBn ? res.timingBn : res.timingEn}", onSurf),
                const SizedBox(height: 8),
                _buildInfoRow(isBn ? "অনুপান (Carrier)" : "Vehicle (Anupana)",
                    isBn ? res.vehicleAnupanaBn : res.vehicleAnupanaEn, onSurf),
                const SizedBox(height: 8),
                _buildInfoRow(isBn ? "সর্বোচ্চ নিরাপদ সীমা" : "Safety Ceiling",
                    isBn ? res.safetyLimitBn : res.safetyLimitEn, onSurf,
                    isHighlight: true),
                const SizedBox(height: 10),
                ...(isBn ? res.clinicalNotesBn : res.clinicalNotesEn).map((n) => Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text("📌 $n",
                          style: TextStyle(fontSize: 11, color: NeuTheme.subtleText(context), height: 1.35)),
                    )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFormulationChip(HerbalFormulation form, String label) {
    final bool isSel = _selectedFormulation == form;
    final primary = NeuTheme.primaryColor(context);

    return GestureDetector(
      onTap: () {
        _selectedFormulation = form;
        _recalculateDosage();
      },
      child: NeuContainer(
        isPressed: isSel,
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        blurRadius: 4,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
            color: isSel ? primary : NeuTheme.onSurface(context),
          ),
        ),
      ),
    );
  }

  // ─── TAB 3: Toxicity & Emergency Protocol Guide ───────────────────────────

  Widget _buildToxicityGuideTab(bool isBn, Color primary, Color onSurf) {
    final profiles = _toxicityService.getAllProfiles();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Emergency Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade900.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade700.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.emergency, color: Colors.red.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? "🚨 জরুরি বিষাক্ততা ও ফার্স্ট-এইড প্রোটোকল" : "🚨 Emergency Toxicity & Triage Protocol",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red.shade800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isBn
                          ? "বিষাক্ত ভেষজ উদ্ভিদের সংস্পর্শে দ্রুত প্রাথমিক চিকিৎসা ও জরুরি চিকিৎসা নির্দেশিকা।"
                          : "Immediate first-aid actions for hazardous and toxic botanical exposures.",
                      style: TextStyle(fontSize: 11, color: NeuTheme.subtleText(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Toxic Species Cards
        ...profiles.map((p) => _buildToxicProfileCard(p, isBn, onSurf)),
      ],
    );
  }

  Widget _buildToxicProfileCard(ToxicPlantProfile p, bool isBn, Color onSurf) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: NeuContainer(
        borderRadius: 22,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_loc.getPlantDisplayName(p.plantName)} (${p.scientificName})",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: onSurf),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.riskTier,
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
                NeuContainer(
                  borderRadius: 14,
                  padding: const EdgeInsets.all(8),
                  blurRadius: 4,
                  child: const Text("⚠️", style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
            Divider(height: 20, color: NeuTheme.shadowDark(context).withValues(alpha: 0.15)),
            _buildInfoRow(isBn ? "বিষাক্ত অংশ" : "Toxic Parts", isBn ? p.toxicPartsBn : p.toxicPartsEn, onSurf),
            const SizedBox(height: 6),
            _buildInfoRow(isBn ? "বিষাক্ত উপাদান" : "Toxin Compounds",
                isBn ? p.toxinCompoundsBn : p.toxinCompoundsEn, onSurf),
            const SizedBox(height: 10),
            Text(isBn ? "লক্ষণসমূহ:" : "Clinical Symptoms:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red.shade800)),
            const SizedBox(height: 4),
            ...(isBn ? p.symptomsBn : p.symptomsEn).map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text("• $s",
                      style: TextStyle(fontSize: 11, color: onSurf, height: 1.35)),
                )),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade800.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isBn ? "⚡ জরুরি প্রাথমিক চিকিৎসা (First Aid):" : "⚡ Emergency First Aid:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red.shade800)),
                  const SizedBox(height: 4),
                  ...(isBn ? p.emergencyFirstAidBn : p.emergencyFirstAidEn).map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 3.0),
                        child: Text("✓ $a",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: onSurf, height: 1.35)),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color onSurf, {bool isHighlight = false}) {
    final primary = NeuTheme.primaryColor(context);
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 12,
          color: isHighlight ? primary : onSurf,
          height: 1.35,
          fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
        ),
        children: [
          TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
