import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sv'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Lönmeter'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @drivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get drivers;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @taxCalculator.
  ///
  /// In en, this message translates to:
  /// **'Tax Calculator'**
  String get taxCalculator;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @activeDrivers.
  ///
  /// In en, this message translates to:
  /// **'Active Drivers'**
  String get activeDrivers;

  /// No description provided for @avgCommission.
  ///
  /// In en, this message translates to:
  /// **'Avg Commission'**
  String get avgCommission;

  /// No description provided for @addEarning.
  ///
  /// In en, this message translates to:
  /// **'Add Earning'**
  String get addEarning;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @revenueByPlatform.
  ///
  /// In en, this message translates to:
  /// **'Revenue by Platform'**
  String get revenueByPlatform;

  /// No description provided for @weeklyTrend.
  ///
  /// In en, this message translates to:
  /// **'Weekly Trend'**
  String get weeklyTrend;

  /// No description provided for @payrollOverview.
  ///
  /// In en, this message translates to:
  /// **'Payroll Overview'**
  String get payrollOverview;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Lönmeter!'**
  String get welcome;

  /// No description provided for @startHint.
  ///
  /// In en, this message translates to:
  /// **'Start by adding drivers and their earnings.'**
  String get startHint;

  /// No description provided for @addDriver.
  ///
  /// In en, this message translates to:
  /// **'Add Driver'**
  String get addDriver;

  /// No description provided for @payrollCost.
  ///
  /// In en, this message translates to:
  /// **'Payroll Cost'**
  String get payrollCost;

  /// No description provided for @effectiveRate.
  ///
  /// In en, this message translates to:
  /// **'Effective Rate'**
  String get effectiveRate;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @commissionRate.
  ///
  /// In en, this message translates to:
  /// **'Commission Rate'**
  String get commissionRate;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @newDriver.
  ///
  /// In en, this message translates to:
  /// **'New Driver'**
  String get newDriver;

  /// No description provided for @noDrivers.
  ///
  /// In en, this message translates to:
  /// **'No drivers yet'**
  String get noDrivers;

  /// No description provided for @addFirstDriver.
  ///
  /// In en, this message translates to:
  /// **'Press + to add a driver'**
  String get addFirstDriver;

  /// No description provided for @noEarningsRegistered.
  ///
  /// In en, this message translates to:
  /// **'No earnings registered'**
  String get noEarningsRegistered;

  /// No description provided for @noDataForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No data for this period'**
  String get noDataForPeriod;

  /// No description provided for @driverNotFound.
  ///
  /// In en, this message translates to:
  /// **'Driver \'{name}\' not found.'**
  String driverNotFound(Object name);

  /// No description provided for @deleteDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete driver?'**
  String get deleteDriverTitle;

  /// No description provided for @deleteDriverContent.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete {name} and all earnings?'**
  String deleteDriverContent(Object name);

  /// No description provided for @driverAdded.
  ///
  /// In en, this message translates to:
  /// **'Driver added!'**
  String get driverAdded;

  /// No description provided for @selectDriver.
  ///
  /// In en, this message translates to:
  /// **'Select driver'**
  String get selectDriver;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @earningSaved.
  ///
  /// In en, this message translates to:
  /// **'Earning saved for {platform} week {week}'**
  String earningSaved(Object platform, Object week);

  /// No description provided for @pdfSaved.
  ///
  /// In en, this message translates to:
  /// **'PDF saved: {path}'**
  String pdfSaved(Object path);

  /// No description provided for @excelSaved.
  ///
  /// In en, this message translates to:
  /// **'Excel saved: {path}'**
  String excelSaved(Object path);

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorMessage(Object error);

  /// No description provided for @showBrutto.
  ///
  /// In en, this message translates to:
  /// **'Show Gross'**
  String get showBrutto;

  /// No description provided for @showNetto.
  ///
  /// In en, this message translates to:
  /// **'Show Net'**
  String get showNetto;

  /// No description provided for @payrollSpecification.
  ///
  /// In en, this message translates to:
  /// **'Payroll Specification'**
  String get payrollSpecification;

  /// No description provided for @provisionInclSemester.
  ///
  /// In en, this message translates to:
  /// **'Provision incl holiday pay'**
  String get provisionInclSemester;

  /// No description provided for @exclSemester.
  ///
  /// In en, this message translates to:
  /// **'Excl holiday pay'**
  String get exclSemester;

  /// No description provided for @holidayPay.
  ///
  /// In en, this message translates to:
  /// **'Holiday pay'**
  String get holidayPay;

  /// No description provided for @fora.
  ///
  /// In en, this message translates to:
  /// **'Fora'**
  String get fora;

  /// No description provided for @arbetsgivaravgifter.
  ///
  /// In en, this message translates to:
  /// **'Employer contributions'**
  String get arbetsgivaravgifter;

  /// No description provided for @totalPayrollCost.
  ///
  /// In en, this message translates to:
  /// **'Total payroll cost'**
  String get totalPayrollCost;

  /// No description provided for @shareOfRevenue.
  ///
  /// In en, this message translates to:
  /// **'Share of Revenue'**
  String get shareOfRevenue;

  /// No description provided for @tipsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total tips'**
  String get tipsTotal;

  /// No description provided for @perDriver.
  ///
  /// In en, this message translates to:
  /// **'Per driver'**
  String get perDriver;

  /// No description provided for @perPlatform.
  ///
  /// In en, this message translates to:
  /// **'Per platform'**
  String get perPlatform;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get exportExcel;

  /// No description provided for @uberGrid.
  ///
  /// In en, this message translates to:
  /// **'Uber Weekly Grid'**
  String get uberGrid;

  /// No description provided for @monthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly Report'**
  String get monthlyReport;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete ALL data?'**
  String get deleteAllData;

  /// No description provided for @deleteAllContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all drivers and earnings. Cannot be undone.'**
  String get deleteAllContent;

  /// No description provided for @dataErased.
  ///
  /// In en, this message translates to:
  /// **'All data has been erased'**
  String get dataErased;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating;

  /// No description provided for @saveToDriver.
  ///
  /// In en, this message translates to:
  /// **'Save to driver'**
  String get saveToDriver;

  /// No description provided for @calculationSaved.
  ///
  /// In en, this message translates to:
  /// **'Calculation saved!'**
  String get calculationSaved;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemStandard.
  ///
  /// In en, this message translates to:
  /// **'System Standard'**
  String get systemStandard;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyName;

  /// No description provided for @taxYear.
  ///
  /// In en, this message translates to:
  /// **'Tax Year'**
  String get taxYear;

  /// No description provided for @defaultCommission.
  ///
  /// In en, this message translates to:
  /// **'Default Commission'**
  String get defaultCommission;

  /// No description provided for @defaultCommissionDesc.
  ///
  /// In en, this message translates to:
  /// **'Default commission rate for new drivers'**
  String get defaultCommissionDesc;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @sekFull.
  ///
  /// In en, this message translates to:
  /// **'Swedish Kronor (SEK)'**
  String get sekFull;

  /// No description provided for @standardCurrency.
  ///
  /// In en, this message translates to:
  /// **'Standard Currency'**
  String get standardCurrency;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data (Excel)'**
  String get importData;

  /// No description provided for @backupDesc.
  ///
  /// In en, this message translates to:
  /// **'Save all data as backup'**
  String get backupDesc;

  /// No description provided for @importDesc.
  ///
  /// In en, this message translates to:
  /// **'Read earnings from Excel file'**
  String get importDesc;

  /// No description provided for @deleteAllDesc.
  ///
  /// In en, this message translates to:
  /// **'Cannot be undone!'**
  String get deleteAllDesc;

  /// No description provided for @taxRates.
  ///
  /// In en, this message translates to:
  /// **'Tax Rates'**
  String get taxRates;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import completed: {count} rows read'**
  String importSuccess(Object count);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(Object error);

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @autoCalculate.
  ///
  /// In en, this message translates to:
  /// **'Auto Calculate'**
  String get autoCalculate;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @calculationBasis.
  ///
  /// In en, this message translates to:
  /// **'Calculation Basis'**
  String get calculationBasis;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// No description provided for @semesterRate.
  ///
  /// In en, this message translates to:
  /// **'Holiday Pay Rate'**
  String get semesterRate;

  /// No description provided for @autoCalcDesc.
  ///
  /// In en, this message translates to:
  /// **'Showing Gross earnings per week'**
  String get autoCalcDesc;

  /// No description provided for @autoCalcNettoDesc.
  ///
  /// In en, this message translates to:
  /// **'Showing Net (excl. VAT) per week'**
  String get autoCalcNettoDesc;

  /// No description provided for @driverName.
  ///
  /// In en, this message translates to:
  /// **'Driver Name'**
  String get driverName;

  /// No description provided for @enterDriverName.
  ///
  /// In en, this message translates to:
  /// **'Please enter driver name'**
  String get enterDriverName;

  /// No description provided for @commissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Commission Level'**
  String get commissionLabel;

  /// No description provided for @saveDriver.
  ///
  /// In en, this message translates to:
  /// **'Save Driver'**
  String get saveDriver;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @sendRecoveryLink.
  ///
  /// In en, this message translates to:
  /// **'Send Recovery Link'**
  String get sendRecoveryLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @accountCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully! Please verify your email.'**
  String get accountCreatedSuccess;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @recoveryLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Recovery link sent! Check your inbox.'**
  String get recoveryLinkSent;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedError;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get dontHaveAccount;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get netProfit;

  /// No description provided for @profitMargin.
  ///
  /// In en, this message translates to:
  /// **'Profit Margin'**
  String get profitMargin;

  /// No description provided for @afterAllTaxes.
  ///
  /// In en, this message translates to:
  /// **'After all taxes'**
  String get afterAllTaxes;

  /// No description provided for @avgPerDriver.
  ///
  /// In en, this message translates to:
  /// **'Avg. per driver'**
  String get avgPerDriver;

  /// No description provided for @margin.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get margin;

  /// No description provided for @totalActive.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String totalActive(Object count);

  /// No description provided for @shareOfRevenueInfo.
  ///
  /// In en, this message translates to:
  /// **'Share of revenue'**
  String get shareOfRevenueInfo;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupRestore;

  /// No description provided for @exportJson.
  ///
  /// In en, this message translates to:
  /// **'Export JSON Backup'**
  String get exportJson;

  /// No description provided for @importJson.
  ///
  /// In en, this message translates to:
  /// **'Import JSON Backup'**
  String get importJson;

  /// No description provided for @saveAsJson.
  ///
  /// In en, this message translates to:
  /// **'Save all data to a JSON file (Full Backup)'**
  String get saveAsJson;

  /// No description provided for @restoreFromJson.
  ///
  /// In en, this message translates to:
  /// **'Restore database from a JSON file'**
  String get restoreFromJson;

  /// No description provided for @importHistory.
  ///
  /// In en, this message translates to:
  /// **'Import History'**
  String get importHistory;

  /// No description provided for @viewRevertHistory.
  ///
  /// In en, this message translates to:
  /// **'View and revert past imports'**
  String get viewRevertHistory;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @signOutDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutDesc;

  /// No description provided for @universalImporter.
  ///
  /// In en, this message translates to:
  /// **'Universal Importer (.xlsx, .csv)'**
  String get universalImporter;

  /// No description provided for @addCommission.
  ///
  /// In en, this message translates to:
  /// **'Add Commission %'**
  String get addCommission;

  /// No description provided for @newPlatform.
  ///
  /// In en, this message translates to:
  /// **'New Platform Name'**
  String get newPlatform;

  /// No description provided for @renamePlatform.
  ///
  /// In en, this message translates to:
  /// **'Rename Platform'**
  String get renamePlatform;

  /// No description provided for @selectPlatform.
  ///
  /// In en, this message translates to:
  /// **'Select Platform'**
  String get selectPlatform;

  /// No description provided for @importComplete.
  ///
  /// In en, this message translates to:
  /// **'Import complete! {count} records added.'**
  String importComplete(Object count);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(Object error);

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully!'**
  String get restoreSuccess;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(Object error);

  /// No description provided for @revertImport.
  ///
  /// In en, this message translates to:
  /// **'Revert Import?'**
  String get revertImport;

  /// No description provided for @revertConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will delete all {count} earnings records from \"{file}\". This action cannot be undone.'**
  String revertConfirm(Object count, Object file);

  /// No description provided for @revertSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import reverted successfully'**
  String get revertSuccess;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @saveCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Save Company Name'**
  String get saveCompanyName;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @companyNameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Company name updated!'**
  String get companyNameUpdated;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Supabase Sync Error'**
  String get syncError;

  /// No description provided for @syncErrorDesc.
  ///
  /// In en, this message translates to:
  /// **'Could not save settings to the cloud.'**
  String get syncErrorDesc;

  /// No description provided for @boltFleetAutomation.
  ///
  /// In en, this message translates to:
  /// **'Bolt Fleet Automation'**
  String get boltFleetAutomation;

  /// No description provided for @syncDataFromBolt.
  ///
  /// In en, this message translates to:
  /// **'Sync Data from Bolt'**
  String get syncDataFromBolt;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @syncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sync successful!'**
  String get syncSuccess;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String syncFailed(Object error);

  /// No description provided for @ridePrice.
  ///
  /// In en, this message translates to:
  /// **'Ride Price'**
  String get ridePrice;

  /// No description provided for @boltCommission.
  ///
  /// In en, this message translates to:
  /// **'Bolt Commission'**
  String get boltCommission;

  /// No description provided for @vat6.
  ///
  /// In en, this message translates to:
  /// **'6% VAT'**
  String get vat6;

  /// No description provided for @employerFee.
  ///
  /// In en, this message translates to:
  /// **'Employer Fee'**
  String get employerFee;

  /// No description provided for @finalNetPayout.
  ///
  /// In en, this message translates to:
  /// **'Final Net Payout'**
  String get finalNetPayout;

  /// No description provided for @yourTrips.
  ///
  /// In en, this message translates to:
  /// **'Your Trips'**
  String get yourTrips;

  /// No description provided for @noTripsFound.
  ///
  /// In en, this message translates to:
  /// **'No trips found for you yet.'**
  String get noTripsFound;

  /// No description provided for @ref.
  ///
  /// In en, this message translates to:
  /// **'Ref'**
  String get ref;

  /// No description provided for @driverDashboard.
  ///
  /// In en, this message translates to:
  /// **'Driver Dashboard'**
  String get driverDashboard;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @netEarnings.
  ///
  /// In en, this message translates to:
  /// **'Net Earnings'**
  String get netEarnings;

  /// No description provided for @priceTotal.
  ///
  /// In en, this message translates to:
  /// **'Price Total'**
  String get priceTotal;

  /// No description provided for @saasIntegrations.
  ///
  /// In en, this message translates to:
  /// **'SaaS Integrations'**
  String get saasIntegrations;

  /// No description provided for @boltFleetApi.
  ///
  /// In en, this message translates to:
  /// **'Bolt Fleet API'**
  String get boltFleetApi;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @setupCredentials.
  ///
  /// In en, this message translates to:
  /// **'Setup your company credentials'**
  String get setupCredentials;

  /// No description provided for @checkingConnection.
  ///
  /// In en, this message translates to:
  /// **'Checking connection...'**
  String get checkingConnection;

  /// No description provided for @apiIntegration.
  ///
  /// In en, this message translates to:
  /// **'API Integration'**
  String get apiIntegration;

  /// No description provided for @clientId.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get clientId;

  /// No description provided for @clientSecret.
  ///
  /// In en, this message translates to:
  /// **'Client Secret'**
  String get clientSecret;

  /// No description provided for @fleetId.
  ///
  /// In en, this message translates to:
  /// **'Company / Fleet ID'**
  String get fleetId;

  /// No description provided for @saveIntegrationSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Integration Settings'**
  String get saveIntegrationSettings;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSaved;

  /// No description provided for @savePreset.
  ///
  /// In en, this message translates to:
  /// **'Save Preset'**
  String get savePreset;

  /// No description provided for @presetName.
  ///
  /// In en, this message translates to:
  /// **'Preset Name'**
  String get presetName;

  /// No description provided for @columnMapping.
  ///
  /// In en, this message translates to:
  /// **'Column Mapping'**
  String get columnMapping;

  /// No description provided for @loadPreset.
  ///
  /// In en, this message translates to:
  /// **'Load Preset'**
  String get loadPreset;

  /// No description provided for @notMapped.
  ///
  /// In en, this message translates to:
  /// **'Not Mapped'**
  String get notMapped;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @startImport.
  ///
  /// In en, this message translates to:
  /// **'Start Import'**
  String get startImport;

  /// No description provided for @unmatchedDriver.
  ///
  /// In en, this message translates to:
  /// **'Unmatched Driver'**
  String get unmatchedDriver;

  /// No description provided for @createNewDriver.
  ///
  /// In en, this message translates to:
  /// **'Create New Driver'**
  String get createNewDriver;

  /// No description provided for @mapAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Map & Continue'**
  String get mapAndContinue;

  /// No description provided for @skipRow.
  ///
  /// In en, this message translates to:
  /// **'Skip Row'**
  String get skipRow;

  /// No description provided for @linkToExisting.
  ///
  /// In en, this message translates to:
  /// **'Link to existing:'**
  String get linkToExisting;

  /// No description provided for @incompleteRowsSkipped.
  ///
  /// In en, this message translates to:
  /// **'Note: Incomplete rows will be skipped during import.'**
  String get incompleteRowsSkipped;

  /// No description provided for @signInDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your Lönmeter account'**
  String get signInDesc;

  /// No description provided for @signUpDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your fleet professionally'**
  String get signUpDesc;

  /// No description provided for @minCharacters.
  ///
  /// In en, this message translates to:
  /// **'Minimum {count} characters'**
  String minCharacters(Object count);

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// No description provided for @generated.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get generated;

  /// No description provided for @tax_deduction.
  ///
  /// In en, this message translates to:
  /// **'Tax Deduction'**
  String get tax_deduction;

  /// No description provided for @take_home_pay.
  ///
  /// In en, this message translates to:
  /// **'Take-Home Pay'**
  String get take_home_pay;

  /// No description provided for @andel_av_inkort.
  ///
  /// In en, this message translates to:
  /// **'Share of Revenue'**
  String get andel_av_inkort;

  /// No description provided for @weeklyEarnings.
  ///
  /// In en, this message translates to:
  /// **'Weekly Earnings'**
  String get weeklyEarnings;

  /// No description provided for @vat.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vat;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sv'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
