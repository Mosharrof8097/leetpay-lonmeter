import 'package:fleetpay/l10n/app_localizations.dart';

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
      case 'tax_calculator': return taxCalculator;
      case 'calculation_basis': return calculationBasis;
      case 'result': return result;
      case 'semester': return holidayPay;
      case 'fora': return fora;
      case 'arbetsgivaravgifter': return arbetsgivaravgifter;
      case 'total_revenue': return totalRevenue;
      case 'payroll_cost': return payrollCost;
      case 'drivers': return drivers;
      case 'amount': return amount;
      case 'show_netto': return showNetto;
      case 'share': return share;
      case 'total': return total;
      case 'export_pdf': return exportPdf;
      case 'export_excel': return exportExcel;
      case 'no_data_for_period': return noDataForPeriod;
      case 'revenue_by_platform': return revenueByPlatform;
      case 'platform': return platform;
      case 'share_of_revenue': return shareOfRevenue;
      case 'settings': return settings;
      case 'company': return company;
      case 'company_name': return companyName;
      case 'tax_year': return taxYear;
      case 'appearance': return appearance;
      case 'system_standard': return systemStandard;
      case 'light_mode': return lightMode;
      case 'dark_mode': return darkMode;
      case 'backup_restore': return backupRestore;
      case 'export_json': return exportJson;
      case 'save_as_json': return saveAsJson;
      case 'import_json': return importJson;
      case 'restore_from_json': return restoreFromJson;
      case 'data_management': return dataManagement;
      case 'import_data': return importData;
      case 'universal_importer': return universalImporter;
      case 'import_history': return importHistory;
      case 'view_revert_history': return viewRevertHistory;
      case 'account': return account;
      case 'logout': return logout;
      case 'sign_out_desc': return signOutDesc;
      case 'week': return week;
      case 'earnings': return earnings;
      case 'delete_driver_content': return deleteDriverContent('{name}');
      case 'driver_not_found': return driverNotFound;
      case 'deactivate': return 'Deactivate';
      case 'activate': return 'Activate';
      case 'active': return active;
      case 'inactive': return inactive;
      case 'new_driver': return newDriver;
      case 'driver_name': return driverName;
      case 'enter_driver_name': return enterDriverName;
      case 'commission_label': return commissionLabel;
      case 'save_driver': return saveDriver;
      case 'driver_added': return driverAdded;
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

  // Common aliases
  String get semester => holidayPay;
  String get totalLonekostnad => totalPayrollCost;
  String get share => shareOfRevenue;
}
