/// Monthly payroll calculation result model.
/// This is computed on-the-fly, not stored in Hive.
class MonthlyPayroll {
  final String driverId;
  final String driverName;
  final int month;
  final int year;
  final double totalBrutto;
  final double totalNetto;
  final double totalDricks;
  final double totalMoms;
  final double commissionRate;
  final double provision;
  final double provisionInklSemester;
  final double exklSemester;
  final double semesterAmount;
  final double semesterRate;
  final double foraAmount;
  final double arbetsgivaravgifter;
  final double totalLonekostnad;
  final double effectiveRate;
  final double netProfit;
  final double profitMargin;
  final double preliminaryTax;
  final double takeHomePay;

  // Dynamic platform breakdowns
  final Map<String, double> platformNetto;
  final Map<String, double> platformBrutto;

  const MonthlyPayroll({
    required this.driverId,
    required this.driverName,
    required this.month,
    required this.year,
    this.totalBrutto = 0,
    this.totalNetto = 0,
    this.totalDricks = 0,
    this.totalMoms = 0,
    this.commissionRate = 0,
    this.provision = 0,
    this.provisionInklSemester = 0,
    this.exklSemester = 0,
    this.semesterAmount = 0,
    this.semesterRate = 0,
    this.foraAmount = 0,
    this.arbetsgivaravgifter = 0,
    this.totalLonekostnad = 0,
    this.effectiveRate = 0,
    this.netProfit = 0,
    this.profitMargin = 0,
    this.preliminaryTax = 0,
    this.takeHomePay = 0,
    this.platformNetto = const {},
    this.platformBrutto = const {},
  });

  double get momsAmount => totalMoms;
  double get totalTips => totalDricks;
}