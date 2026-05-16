// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Lönmeter';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get drivers => 'Drivers';

  @override
  String get earnings => 'Earnings';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get taxCalculator => 'Tax Calculator';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get activeDrivers => 'Active Drivers';

  @override
  String get avgCommission => 'Avg Commission';

  @override
  String get addEarning => 'Add Earning';

  @override
  String get report => 'Report';

  @override
  String get revenueByPlatform => 'Revenue by Platform';

  @override
  String get weeklyTrend => 'Weekly Trend';

  @override
  String get payrollOverview => 'Payroll Overview';

  @override
  String get welcome => 'Welcome to Lönmeter!';

  @override
  String get startHint => 'Start by adding drivers and their earnings.';

  @override
  String get addDriver => 'Add Driver';

  @override
  String get payrollCost => 'Payroll Cost';

  @override
  String get effectiveRate => 'Effective Rate';

  @override
  String get week => 'Week';

  @override
  String get platform => 'Platform';

  @override
  String get amount => 'Amount';

  @override
  String get date => 'Date';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get name => 'Name';

  @override
  String get commissionRate => 'Commission Rate';

  @override
  String get status => 'Status';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get newDriver => 'New Driver';

  @override
  String get noDrivers => 'No drivers yet';

  @override
  String get addFirstDriver => 'Press + to add a driver';

  @override
  String get noEarningsRegistered => 'No earnings registered';

  @override
  String get noDataForPeriod => 'No data for this period';

  @override
  String driverNotFound(Object name) {
    return 'Driver \'$name\' not found.';
  }

  @override
  String get deleteDriverTitle => 'Delete driver?';

  @override
  String deleteDriverContent(Object name) {
    return 'Do you want to delete $name and all earnings?';
  }

  @override
  String get driverAdded => 'Driver added!';

  @override
  String get selectDriver => 'Select driver';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String earningSaved(Object platform, Object week) {
    return 'Earning saved for $platform week $week';
  }

  @override
  String pdfSaved(Object path) {
    return 'PDF saved: $path';
  }

  @override
  String excelSaved(Object path) {
    return 'Excel saved: $path';
  }

  @override
  String errorMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String get showBrutto => 'Show Gross';

  @override
  String get showNetto => 'Show Net';

  @override
  String get payrollSpecification => 'Payroll Specification';

  @override
  String get provisionInclSemester => 'Provision incl holiday pay';

  @override
  String get exclSemester => 'Excl holiday pay';

  @override
  String get holidayPay => 'Holiday pay';

  @override
  String get fora => 'Fora';

  @override
  String get arbetsgivaravgifter => 'Employer contributions';

  @override
  String get totalPayrollCost => 'Total payroll cost';

  @override
  String get shareOfRevenue => 'Share of Revenue';

  @override
  String get tipsTotal => 'Total tips';

  @override
  String get perDriver => 'Per driver';

  @override
  String get perPlatform => 'Per platform';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get exportExcel => 'Export Excel';

  @override
  String get uberGrid => 'Uber Weekly Grid';

  @override
  String get monthlyReport => 'Monthly Report';

  @override
  String get deleteAllData => 'Delete ALL data?';

  @override
  String get deleteAllContent =>
      'This will permanently delete all drivers and earnings. Cannot be undone.';

  @override
  String get dataErased => 'All data has been erased';

  @override
  String get calculating => 'Calculating...';

  @override
  String get saveToDriver => 'Save to driver';

  @override
  String get calculationSaved => 'Calculation saved!';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get systemStandard => 'System Standard';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get company => 'Company';

  @override
  String get companyName => 'Company Name';

  @override
  String get taxYear => 'Tax Year';

  @override
  String get defaultCommission => 'Default Commission';

  @override
  String get defaultCommissionDesc => 'Default commission rate for new drivers';

  @override
  String get currency => 'Currency';

  @override
  String get sekFull => 'Swedish Kronor (SEK)';

  @override
  String get standardCurrency => 'Standard Currency';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get exportData => 'Export Data';

  @override
  String get importData => 'Import Data (Excel)';

  @override
  String get backupDesc => 'Save all data as backup';

  @override
  String get importDesc => 'Read earnings from Excel file';

  @override
  String get deleteAllDesc => 'Cannot be undone!';

  @override
  String get taxRates => 'Tax Rates';

  @override
  String importSuccess(Object count) {
    return 'Import completed: $count rows read';
  }

  @override
  String importFailed(Object error) {
    return 'Import failed: $error';
  }

  @override
  String get month => 'Month';

  @override
  String get autoCalculate => 'Auto Calculate';

  @override
  String get total => 'Total';

  @override
  String get share => 'Share';

  @override
  String get calculationBasis => 'Calculation Basis';

  @override
  String get result => 'Result';

  @override
  String get semesterRate => 'Holiday Pay Rate';

  @override
  String get autoCalcDesc => 'Showing Gross earnings per week';

  @override
  String get autoCalcNettoDesc => 'Showing Net (excl. VAT) per week';

  @override
  String get driverName => 'Driver Name';

  @override
  String get enterDriverName => 'Please enter driver name';

  @override
  String get commissionLabel => 'Commission Level';

  @override
  String get saveDriver => 'Save Driver';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get sendRecoveryLink => 'Send Recovery Link';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get accountCreatedSuccess =>
      'Account created successfully! Please verify your email.';

  @override
  String get enterValidEmail => 'Please enter a valid email';

  @override
  String get recoveryLinkSent => 'Recovery link sent! Check your inbox.';

  @override
  String get unexpectedError => 'An unexpected error occurred';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Sign Up';

  @override
  String get netProfit => 'Net Profit';

  @override
  String get profitMargin => 'Profit Margin';

  @override
  String get afterAllTaxes => 'After all taxes';

  @override
  String get avgPerDriver => 'Avg. per driver';

  @override
  String get margin => 'Margin';

  @override
  String totalActive(Object count) {
    return '$count total';
  }

  @override
  String get shareOfRevenueInfo => 'Share of revenue';

  @override
  String get backupRestore => 'Backup & Restore';

  @override
  String get exportJson => 'Export JSON Backup';

  @override
  String get importJson => 'Import JSON Backup';

  @override
  String get saveAsJson => 'Save all data to a JSON file (Full Backup)';

  @override
  String get restoreFromJson => 'Restore database from a JSON file';

  @override
  String get importHistory => 'Import History';

  @override
  String get viewRevertHistory => 'View and revert past imports';

  @override
  String get account => 'Account';

  @override
  String get logout => 'Logout';

  @override
  String get signOutDesc => 'Sign out of your account';

  @override
  String get universalImporter => 'Universal Importer (.xlsx, .csv)';

  @override
  String get addCommission => 'Add Commission %';

  @override
  String get newPlatform => 'New Platform Name';

  @override
  String get renamePlatform => 'Rename Platform';

  @override
  String get selectPlatform => 'Select Platform';

  @override
  String importComplete(Object count) {
    return 'Import complete! $count records added.';
  }

  @override
  String exportFailed(Object error) {
    return 'Export failed: $error';
  }

  @override
  String get restoreSuccess => 'Backup restored successfully!';

  @override
  String restoreFailed(Object error) {
    return 'Restore failed: $error';
  }

  @override
  String get revertImport => 'Revert Import?';

  @override
  String revertConfirm(Object count, Object file) {
    return 'This will delete all $count earnings records from \"$file\". This action cannot be undone.';
  }

  @override
  String get revertSuccess => 'Import reverted successfully';

  @override
  String get ok => 'OK';

  @override
  String get add => 'Add';

  @override
  String get update => 'Update';

  @override
  String get back => 'Back';

  @override
  String get saveCompanyName => 'Save Company Name';

  @override
  String get saving => 'Saving...';

  @override
  String get companyNameUpdated => 'Company name updated!';

  @override
  String get syncError => 'Supabase Sync Error';

  @override
  String get syncErrorDesc => 'Could not save settings to the cloud.';

  @override
  String get boltFleetAutomation => 'Bolt Fleet Automation';

  @override
  String get syncDataFromBolt => 'Sync Data from Bolt';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncSuccess => 'Sync successful!';

  @override
  String syncFailed(Object error) {
    return 'Sync failed: $error';
  }

  @override
  String get ridePrice => 'Ride Price';

  @override
  String get boltCommission => 'Bolt Commission';

  @override
  String get vat6 => '6% VAT';

  @override
  String get employerFee => 'Employer Fee';

  @override
  String get finalNetPayout => 'Final Net Payout';

  @override
  String get yourTrips => 'Your Trips';

  @override
  String get noTripsFound => 'No trips found for you yet.';

  @override
  String get ref => 'Ref';

  @override
  String get driverDashboard => 'Driver Dashboard';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get netEarnings => 'Net Earnings';

  @override
  String get priceTotal => 'Price Total';

  @override
  String get saasIntegrations => 'SaaS Integrations';

  @override
  String get boltFleetApi => 'Bolt Fleet API';

  @override
  String get connected => 'Connected';

  @override
  String get setupCredentials => 'Setup your company credentials';

  @override
  String get checkingConnection => 'Checking connection...';

  @override
  String get apiIntegration => 'API Integration';

  @override
  String get clientId => 'Client ID';

  @override
  String get clientSecret => 'Client Secret';

  @override
  String get fleetId => 'Company / Fleet ID';

  @override
  String get saveIntegrationSettings => 'Save Integration Settings';

  @override
  String get required => 'Required';

  @override
  String get settingsSaved => 'Settings saved successfully';

  @override
  String get savePreset => 'Save Preset';

  @override
  String get presetName => 'Preset Name';

  @override
  String get columnMapping => 'Column Mapping';

  @override
  String get loadPreset => 'Load Preset';

  @override
  String get notMapped => 'Not Mapped';

  @override
  String get preview => 'Preview';

  @override
  String get startImport => 'Start Import';

  @override
  String get unmatchedDriver => 'Unmatched Driver';

  @override
  String get createNewDriver => 'Create New Driver';

  @override
  String get mapAndContinue => 'Map & Continue';

  @override
  String get skipRow => 'Skip Row';

  @override
  String get linkToExisting => 'Link to existing:';

  @override
  String get incompleteRowsSkipped =>
      'Note: Incomplete rows will be skipped during import.';

  @override
  String get signInDesc => 'Sign in to your Lönmeter account';

  @override
  String get signUpDesc => 'Manage your fleet professionally';

  @override
  String minCharacters(Object count) {
    return 'Minimum $count characters';
  }

  @override
  String get page => 'Page';

  @override
  String get generated => 'Generated';

  @override
  String get tax_deduction => 'Tax Deduction';

  @override
  String get take_home_pay => 'Take-Home Pay';

  @override
  String get andel_av_inkort => 'Share of Revenue';

  @override
  String get weeklyEarnings => 'Weekly Earnings';

  @override
  String get vat => 'VAT';
}
