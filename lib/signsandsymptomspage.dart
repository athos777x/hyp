import 'package:flutter/material.dart';

class SignsAndSymptomsPage extends StatefulWidget {
  @override
  _SignsAndSymptomsPageState createState() => _SignsAndSymptomsPageState();
}

class _SignsAndSymptomsPageState extends State<SignsAndSymptomsPage> {
  final TextEditingController _searchController = TextEditingController();

  // Organized symptoms by category
  final Map<String, List<String>> symptomCategories = {
    'Common Symptoms': [
      'Severe headache',
      'Dizziness or lightheadedness',
      'Blurred or double vision',
      'Shortness of breath',
      'Chest pain or tightness',
      'Nosebleeds',
      'Fatigue or confusion',
      'Irregular heartbeat',
      'Nausea or vomiting',
      'Pounding sensation in the chest, neck, or ears',
    ],
    'Less Common Symptoms': [
      'Swelling in legs, ankles, or feet (fluid retention)',
      'Flushed face (temporary redness)',
      'Tinnitus (ringing in the ears)',
      'Frequent urination at night (nocturia)',
      'Difficulty concentrating or memory problems',
      'Tingling or numbness in extremities (fingers or toes)',
      'Vision changes or loss (damage to blood vessels in the eyes)',
      'Anxiety or nervousness',
      'Excessive sweating',
      'Fainting or near-fainting episodes',
    ],
    'Advanced Symptoms': [
      'Palpitations (racing or irregular heartbeat)',
      'Muscle tremors or weakness',
      'Severe anxiety or sense of impending doom',
      'Cold sweats',
      'Difficulty sleeping or insomnia',
      'Morning headaches',
      'Loss of appetite',
      'Sudden weight gain (fluid retention)',
      'Reduced physical endurance',
      'Chest discomfort radiating to jaw or arms',
    ],
    'Signs of Organ Damage': [
      'Blood in urine (indicates kidney damage)',
      'Reduced urination (kidney damage)',
      'Swelling in the abdomen, legs, or ankles (heart failure)',
      'Memory loss, confusion, or stroke-like symptoms',
      'Numbness or paralysis on one side of the body',
      'Difficulty speaking or slurred speech',
      'Seizures (rare, associated with hypertensive crisis)',
    ],
    'Emergency Symptoms': [
      'Systolic pressure over 180 mmHg or diastolic over 120 mmHg',
      'Sudden and severe chest pain',
      'Severe shortness of breath',
      'Severe headaches with no known cause',
      'Severe confusion or loss of consciousness',
      'Vision loss or severe vision changes',
      'Uncontrollable nosebleeds',
    ],
    'Rare Symptoms': [
      'Extreme tiredness (linked to strain on the heart)',
      'Cool or pale skin (circulatory issues)',
      'Frequent hiccups (potential nervous system involvement)',
      'Persistent dry cough (rare but possible side effect of hypertensive damage)',
      'Jaw pain (related to cardiovascular strain)',
    ],
  };

  List<MapEntry<String, List<String>>> filteredSymptoms = [];

  // Add this map to define severity colors
  final Map<String, Color> categoryColors = {
    'Common Symptoms': Color(0xFFFFF9C4), // Light yellow
    'Less Common Symptoms': Color(0xFFFFE0B2), // Light orange
    'Advanced Symptoms': Color(0xFFFFCCBC), // Light red-orange
    'Signs of Organ Damage': Color(0xFFFFAB91), // Darker orange-red
    'Emergency Symptoms': Color(0xFFFF8A80), // Red
    'Rare Symptoms': Color(0xFFFFECB3), // Light amber
  };

  @override
  void initState() {
    super.initState();
    filteredSymptoms = symptomCategories.entries.toList();
    _searchController.addListener(_filterSymptoms);
  }

  void _filterSymptoms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredSymptoms = symptomCategories.entries.toList();
      } else {
        filteredSymptoms = symptomCategories.entries
            .map((category) => MapEntry(
                  category.key,
                  category.value
                      .where((symptom) => symptom.toLowerCase().contains(query))
                      .toList(),
                ))
            .where((category) => category.value.isNotEmpty)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'search sign and symptoms',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            // Symptoms List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredSymptoms.length,
                itemBuilder: (context, categoryIndex) {
                  final category = filteredSymptoms[categoryIndex];
                  if (category.value.isEmpty) return SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_searchController.text.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 4.0,
                          ),
                          child: Text(
                            category.key,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                      ...category.value
                          .map((symptom) => Container(
                                margin: EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: categoryColors[category.key] ??
                                      Colors.white, // Use category color
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  title: Text(
                                    symptom,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  dense: true,
                                  visualDensity: VisualDensity(vertical: -2),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                ),
                              ))
                          .toList(),
                      SizedBox(height: 6),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
