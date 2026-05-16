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

  /// Calculate 0.0566 VAT (moms) amount as per user scenario
  static double calculateMoms(double bruttoAmount) {
    if (bruttoAmount <= 0) return 0;
    // Standard factor requested by user: 0.0566
    return (bruttoAmount * 0.0566).roundToDouble();
  }

  /// Calculate net earnings after removing platform fee and VAT
  /// Formula: Net = Gross - (VAT + PlatformFee)
  static double calculateNetEarnings(double bruttoAmount, {double feeAmount = 0}) {
    if (bruttoAmount <= 0) return 0;
    final vat = calculateMoms(bruttoAmount);
    return (bruttoAmount - (vat + feeAmount)).roundToDouble();
  }

  /// Calculate provision (commission) inkl semester
  /// Formula: provision = NetRevenue * DriverShare%
  static double calculateProvisionInklSemester(
    double netRevenue,
    double driverShareRate,
  ) {
    return (netRevenue * driverShareRate).roundToDouble();
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

  /// Full payroll calculation from net revenue with dynamic factors
  static PayrollResult calculateFullPayroll({
    required double netRevenue,
    required double driverShareRate,
    double dricks = 0,
    double holidayPayRate = 0.12,
    double pensionRate = 0.045,
  }) {
    // 1. Calculate driver's base share (Provision)
    final driverBaseShare = calculateProvisionInklSemester(netRevenue, driverShareRate);
    
    // 2. Calculate Holiday Pay (Z%)
    final holidayPay = (driverBaseShare * holidayPayRate).roundToDouble();
    
    // 3. Calculate Pension
    final pension = ((driverBaseShare + holidayPay) * pensionRate).roundToDouble();

    // 4. Total Employer Cost (Payroll Cost)
    // In the new scenario, employer costs are driverBase + holiday + pension
    final totalLonekostnad = (driverBaseShare + holidayPay + pension).roundToDouble();

    // 5. Driver's Gross Payout (Base + 100% Tips)
    // Note: Holiday pay is usually paid later or included. Here we treat Base+Tips as current payout.
    final driverGrossSalary = (driverBaseShare + dricks).roundToDouble();
    
    // 6. Preliminary Tax (30% on Gross Salary)
    final preliminaryTax = (driverGrossSalary * 0.30).roundToDouble();
    final takeHomePay = (driverGrossSalary - preliminaryTax).roundToDouble();

    // 7. Company's Net Profit
    // Profit = NetRevenue - (HolidayPay + Pension + DriverBaseShare)
    // Tips are pass-through, so they don't affect profit
    final companyNetProfit = (netRevenue - totalLonekostnad).roundToDouble();
    final profitMargin = netRevenue > 0 ? (companyNetProfit / netRevenue) : 0.0;

    return PayrollResult(
      provisionInklSemester: driverBaseShare,
      exklSemester: driverBaseShare, // Simplified for the new model
      semesterAmount: holidayPay,
      semesterRate: holidayPayRate,
      foraAmount: pension, // Using Fora field for Pension in this model
      arbetsgivaravgifter: 0, // Consolidated into totalLonekostnad
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
      final entryRate = useLiveRate ? commissionRate : (entry.appliedPercentage ?? commissionRate);
      
      final entryResult = calculateFullPayroll(
        netRevenue: entry.nettoAmount, // Provision ONLY on Netto
        dricks: entry.dricks,           // Tips added to payout separately
        driverShareRate: entryRate,
        // Standard Swedish defaults for now, but these can come from PlatformConfig
        holidayPayRate: 0.12, 
        pensionRate: 0.045,
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