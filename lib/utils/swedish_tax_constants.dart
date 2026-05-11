// All Swedish payroll tax constants for Lönmeter
// These are official rates used in Sweden for employer contributions.

const double kArbetsgivaravgifter = 0.3142; // Employer social contributions
const double kForaSats = 0.045; // Fora insurance rate
const double kSemesterSats12 = 0.12; // Holiday pay 12% (for 43%/45% commission)
const double kSemesterSats13 = 0.13; // Holiday pay 13% (for 37% commission)
const double kMoms6 = 0.06; // 6% Swedish VAT for transport

const Map<String, double> kCommissionRates = {
  'Prov43': 0.43,
  'Prov45': 0.45,
  'Prov37': 0.37,
};

/// Returns the semester (holiday pay) rate based on commission rate
double getSemesterRate(double commissionRate) {
  if (commissionRate == 0.37) return kSemesterSats13;
  return kSemesterSats12;
}

/// Platform enum names
const List<String> kPlatforms = ['Bolt', 'Uber', 'Wecab'];

/// Currency
const String kCurrency = 'SEK';

/// Week range for Uber grid
const int kMinWeek = 1;
const int kMaxWeek = 53;