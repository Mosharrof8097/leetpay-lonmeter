import 'package:fleetpay/l10n/app_localizations_extension.dart';
import 'package:flutter/widgets.dart';
import 'package:fleetpay/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

extension AppLocalizationsMethods on AppLocalizations {
  String get(String key) {
    switch (key) {
      case 'month': return month;
      case 'dricks_total': return tipsTotal;
      case 'monthly_report': return monthlyReport;
      case 'auto_calculate': return autoCalculate;
      case 'earning_saved': return earningSaved('{platform}', '{week}');
      case 'provision_incl_semester': return provisionInclSemester;
      case 'excl_semester': return exclSemester;
      case 'andel_av_inkort': return shareOfRevenue;
      case 'total_lonekostnad': return totalPayrollCost;
      case 'pdf_saved': return pdfSaved('{path}');
      case 'error': return errorMessage('{error}');
      case 'excel_saved': return excelSaved('{path}');
      case 'no_earnings_registered': return noEarningsRegistered;
      case 'add_percentage': return 'Add %';
      case 'platforms_categories': return 'Platforms';
      case 'add_platform': return 'Add Platform';
      case 'delete_all_data': return deleteAllData;
      case 'delete_all_content': return deleteAllContent;
      case 'data_erased': return dataErased;
      case 'per_driver': return perDriver;
      case 'per_platform': return perPlatform;
      case 'monthly_payroll': return monthlyReport;
      case 'payroll_specification': return payrollSpecification;
      case 'no_data_registered': return noEarningsRegistered;
      case 'csv_saved': return 'CSV Saved';
      case 'import_complete': return 'Import complete';
      case 'import_failed': return 'Import failed';
      default: return key;
    }
  }

  String getMonthName(int month) {
    const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const sv = ['Jan', 'Feb', 'Mar', 'Apr', 'Maj', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dec'];
    final names = localeName == 'sv' ? sv : en;
    if (month < 1 || month > 12) return month.toString();
    return names[month - 1];
  }
}
