import '../models/earnings_entry.dart';
import '../models/monthly_payroll.dart';
import '../utils/swedish_tax_constants.dart';

/// Core calculation service implementing all Swedish payroll formulas.
class CalculationService {
  /// Calculate netto from brutto by removing 6% VAT
  /// nettoAmount = bruttoAmount / 1.06
  static double calculateNetto(double bruttoAmount) {
    if (bruttoAmount <= 0) return 0;
    return bruttoAmount / (1 + kMoms6);
  }

  /// Calculate net earnings after removing platform fee and 6% VAT
  static double calculateNetEarnings(double bruttoAmount, {double feeAmount = 0}) {
    if (bruttoAmount <= 0) return 0;
    final amountAfterFee = (bruttoAmount - feeAmount).roundToDouble();
    return (amountAfterFee / (1 + kMoms6)).roundToDouble();
  }

  /// Calculate 6% VAT (moms) amount
  static double calculateMoms(double bruttoAmount) {
    if (bruttoAmount <= 0) return 0;
    final netto = calculateNetto(bruttoAmount);
    return bruttoAmount - netto;
  }

  /// Calculate provision (commission) inkl semester
  /// provision_inkl_semester = nettoIntakter * commissionRate
  static double calculateProvisionInklSemester(
    double nettoIntakter,
    double commissionRate,
  ) {
    return nettoIntakter * commissionRate;
  }

  /// Calculate exkl semester
  /// exkl_semester = provision_inkl_semester / (1 + semesterRate)
  static double calculateExklSemester(
    double provisionInklSemester,
    double semesterRate,
  ) {
    if (semesterRate <= 0) return provisionInklSemester;
    return provisionInklSemester / (1 + semesterRate);
  }

  /// Calculate semester (holiday pay) amount
  /// semester = exkl_semester * semesterRate
  static double calculateSemester(
    double exklSemester,
    double semesterRate,
  ) {
    return exklSemester * semesterRate;
  }

  /// Calculate Fora insurance
  /// Base is exkl_semester + semester (Provision Inkl Semester)
  static double calculateFora(double provisionInklSemester) {
    return (provisionInklSemester * kForaSats).roundToDouble();
  }

  /// Calculate arbetsgivaravgifter (employer social contributions)
  /// Base is exkl_semester + semester (Provision Inkl Semester)
  static double calculateArbetsgivaravgifter(double provisionInklSemester) {
    return (provisionInklSemester * kArbetsgivaravgifter).roundToDouble();
  }

  /// Simplified social fees calculation for a given amount
  static double calculateSocialFees(double amount) {
    return amount * 0.15; // Estimated rate for quick calculations
  }

  /// Calculate total lönekostnad (total payroll cost)
  /// total = exkl_semester + semester + fora + arbetsgivaravgifter
  static double calculateTotalLonekostnad({
    required double exklSemester,
    required double semester,
    required double fora,
    required double arbetsgivaravgifter,
  }) {
    return exklSemester + semester + fora + arbetsgivaravgifter;
  }

  /// Calculate effective provision percentage
  /// effectiveRate = total_lonekostnad / totalInkortBelopp
  static double calculateEffectiveRate(
    double totalLonekostnad,
    double totalInkortBelopp,
  ) {
    if (totalInkortBelopp <= 0) return 0;
    return totalLonekostnad / totalInkortBelopp;
  }

  /// Get the semester rate based on commission rate
  static double getSemesterRateForCommission(double commissionRate) {
    return getSemesterRate(commissionRate);
  }

  /// Full payroll calculation from net earnings
  static PayrollResult calculateFullPayroll({
    required double nettoIntakter,
    required double commissionRate,
    double dricks = 0,
    double? overrideSemesterRate,
  }) {
    final semesterRate =
        overrideSemesterRate ?? getSemesterRateForCommission(commissionRate);

    // 1. Calculate base provision (ONLY on Netto, excluding tips)
    final provisionInklSemester =
        calculateProvisionInklSemester(nettoIntakter, commissionRate).roundToDouble();
    
    // 2. Split into Exkl and Semester
    final exklSemester =
        calculateExklSemester(provisionInklSemester, semesterRate).roundToDouble();
    final semester = (provisionInklSemester - exklSemester).roundToDouble();

    // 3. Social Fees (Base is Inkl. Semester)
    final fora = calculateFora(provisionInklSemester);
    final arbetsgivaravgifter = calculateArbetsgivaravgifter(provisionInklSemester);
    
    // 4. Total Payroll Cost for Company
    final totalLonekostnad = calculateTotalLonekostnad(
      exklSemester: exklSemester,
      semester: semester,
      fora: fora,
      arbetsgivaravgifter: arbetsgivaravgifter,
    ).roundToDouble();

    // 5. Driver's Gross Payout (Provision + 100% Tips)
    final driverGrossSalary = (provisionInklSemester + dricks).roundToDouble();
    
    // 6. Preliminary Tax (30% on Gross Salary)
    final preliminaryTax = (driverGrossSalary * 0.30).roundToDouble();
    final takeHomePay = (driverGrossSalary - preliminaryTax).roundToDouble();

    final netProfit = (nettoIntakter + dricks - totalLonekostnad - dricks).roundToDouble(); // Company doesn't keep tips
    // Simplified profit logic: Netto - Company's payroll costs (Tips are pass-through)
    final companyNetProfit = (nettoIntakter - totalLonekostnad).roundToDouble();
    final profitMargin = nettoIntakter > 0 ? (companyNetProfit / nettoIntakter) : 0.0;

    return PayrollResult(
      provisionInklSemester: provisionInklSemester,
      exklSemester: exklSemester,
      semesterAmount: semester,
      semesterRate: semesterRate,
      foraAmount: fora,
      arbetsgivaravgifter: arbetsgivaravgifter,
      totalLonekostnad: totalLonekostnad,
      preliminaryTax: preliminaryTax,
      takeHomePay: takeHomePay,
      netProfit: companyNetProfit,
      profitMargin: profitMargin,
    );
  }

  /// Generate monthly payroll for a driver from their earnings entries
  static MonthlyPayroll generateMonthlyPayroll({
    required String driverId,
    required String driverName,
    required double commissionRate,
    required int month,
    required int year,
    required List<EarningsEntry> entries,
    bool useLiveRate = false,
  }) {
    double totalBrutto = 0;
    double totalNetto = 0;
    double totalDricks = 0;
    double totalMoms = 0;
    final Map<String, double> platformNetto = {};
    final Map<String, double> platformBrutto = {};

    double totalExklSemester = 0;
    double totalSemesterAmount = 0;
    double totalFora = 0;
    double totalArbetsgivaravgifter = 0;
    double totalProvision = 0;
    double totalTax = 0;
    double totalTakeHome = 0;

    for (final entry in entries) {
      totalBrutto += entry.bruttoAmount;
      totalNetto += entry.nettoAmount;
      totalDricks += entry.dricks;
      totalMoms += entry.moms6;

      final pid = entry.platformId;
      platformNetto[pid] = (platformNetto[pid] ?? 0) + entry.nettoAmount;
      
      double currentBrutto = entry.bruttoAmount;
      if (pid == 'uber' && (entry.uberBrutto ?? 0) > 0) {
        currentBrutto = entry.uberBrutto ?? 0;
      }
      platformBrutto[pid] = (platformBrutto[pid] ?? 0) + currentBrutto;

      // Calculate payroll for this specific entry
      // If useLiveRate is true, we ignore the snapshot and use the driver's current rate
      final entryRate = useLiveRate ? commissionRate : (entry.appliedPercentage ?? commissionRate);
      
      final entryResult = calculateFullPayroll(
        nettoIntakter: entry.nettoAmount, // Provision ONLY on Netto
        dricks: entry.dricks,           // Tips added to payout separately
        commissionRate: entryRate,
      );

      totalExklSemester += entryResult.exklSemester;
      totalSemesterAmount += entryResult.semesterAmount;
      totalFora += entryResult.foraAmount;
      totalArbetsgivaravgifter += entryResult.arbetsgivaravgifter;
      totalProvision += entryResult.provisionInklSemester;
      totalTax += entryResult.preliminaryTax;
      totalTakeHome += entryResult.takeHomePay;
    }

    final totalLonekostnad = totalExklSemester + totalSemesterAmount + totalFora + totalArbetsgivaravgifter;
    final netProfit = (totalNetto + totalDricks) - totalLonekostnad;
    final profitMargin = (totalNetto + totalDricks) > 0 ? (netProfit / (totalNetto + totalDricks)) : 0.0;

    final effectiveRate = calculateEffectiveRate(
      totalLonekostnad,
      totalBrutto,
    );

    return MonthlyPayroll(
      driverId: driverId,
      driverName: driverName,
      month: month,
      year: year,
      totalBrutto: totalBrutto.roundToDouble(),
      totalNetto: totalNetto.roundToDouble(),
      totalDricks: totalDricks.roundToDouble(),
      totalMoms: totalMoms.roundToDouble(),
      commissionRate: commissionRate,
      provision: totalProvision.roundToDouble(),
      provisionInklSemester: totalProvision.roundToDouble(),
      exklSemester: totalExklSemester.roundToDouble(),
      semesterAmount: totalSemesterAmount.roundToDouble(),
      semesterRate: getSemesterRate(commissionRate),
      foraAmount: totalFora.roundToDouble(),
      arbetsgivaravgifter: totalArbetsgivaravgifter.roundToDouble(),
      totalLonekostnad: totalLonekostnad.roundToDouble(),
      preliminaryTax: totalTax.roundToDouble(),
      takeHomePay: totalTakeHome.roundToDouble(),
      effectiveRate: effectiveRate,
      netProfit: netProfit.roundToDouble(),
      profitMargin: profitMargin,
      platformNetto: platformNetto,
      platformBrutto: platformBrutto,
    );
  }
}

/// Result of a full payroll calculation
class PayrollResult {
  final double provisionInklSemester;
  final double exklSemester;
  final double semesterAmount;
  final double semesterRate;
  final double foraAmount;
  final double arbetsgivaravgifter;
  final double totalLonekostnad;
  final double preliminaryTax;
  final double takeHomePay;
  final double netProfit;
  final double profitMargin;

  const PayrollResult({
    required this.provisionInklSemester,
    required this.exklSemester,
    required this.semesterAmount,
    required this.semesterRate,
    required this.foraAmount,
    required this.arbetsgivaravgifter,
    required this.totalLonekostnad,
    required this.preliminaryTax,
    required this.takeHomePay,
    required this.netProfit,
    required this.profitMargin,
  });
}