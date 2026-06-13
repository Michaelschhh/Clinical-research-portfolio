class RegulatoryData {
  static const List<Map<String, String>> gdprStatus = [
    {
      "destination": "EU to US",
      "status": "Adequate (Data Privacy Framework)",
      "notes": "Valid for certified organizations."
    },
    {
      "destination": "EU to UK",
      "status": "Adequate",
      "notes": "Subject to periodic review."
    },
    {
      "destination": "EU to Israel",
      "status": "Adequate",
      "notes": "Valid for ongoing transfers."
    },
  ];

  static const List<Map<String, String>> ichGcpPrinciples = [
    {
      "title": "Ethics",
      "description": "Clinical trials should be conducted in accordance with the ethical principles that have their origin in the Declaration of Helsinki."
    },
    {
      "title": "Risk/Benefit",
      "description": "Before a trial is initiated, foreseeable risks and inconveniences should be weighed against the anticipated benefit."
    },
    {
      "title": "Quality",
      "description": "Quality should be built into the scientific and operational design and conduct of clinical trials."
    },
  ];

  static const String lastUpdated = "2024-05-15";
}
