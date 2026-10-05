class BusinessSetupData {
  final String businessName;
  final String businessType;
  final String activity;
  final String kbliCode;
  final String kbliName;

  const BusinessSetupData({
    required this.businessName,
    required this.businessType,
    required this.activity,
    required this.kbliCode,
    required this.kbliName,
  });

  Map<String, dynamic> toJson() {
    return {
      'business_name': businessName,
      'business_type': businessType,
      'activity': activity,
      'kbli_code': kbliCode,
      'kbli_name': kbliName,
    };
  }
}
