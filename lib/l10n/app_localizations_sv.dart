// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Lönmeter';

  @override
  String get dashboard => 'Översikt';

  @override
  String get drivers => 'Förare';

  @override
  String get earnings => 'Intäkter';

  @override
  String get reports => 'Rapporter';

  @override
  String get settings => 'Inställningar';

  @override
  String get taxCalculator => 'Skattekalkylator';

  @override
  String get totalRevenue => 'Total inkört belopp';

  @override
  String get activeDrivers => 'Aktiva förare';

  @override
  String get avgCommission => 'Snitt provision';

  @override
  String get addEarning => 'Lägg till intäkt';

  @override
  String get report => 'Rapport';

  @override
  String get revenueByPlatform => 'Intäkter per plattform';

  @override
  String get weeklyTrend => 'Veckoutveckling';

  @override
  String get payrollOverview => 'Löneöversikt denna månad';

  @override
  String get welcome => 'Välkommen till Lönmeter!';

  @override
  String get startHint => 'Börja med att lägga till förare och deras intäkter.';

  @override
  String get addDriver => 'Lägg till förare';

  @override
  String get payrollCost => 'Lönekostnad';

  @override
  String get effectiveRate => 'Effektiv provision';

  @override
  String get week => 'Vecka';

  @override
  String get platform => 'Plattform';

  @override
  String get amount => 'Belopp';

  @override
  String get date => 'Datum';

  @override
  String get save => 'Spara';

  @override
  String get cancel => 'Avbryt';

  @override
  String get delete => 'Ta bort';

  @override
  String get edit => 'Redigera';

  @override
  String get name => 'Namn';

  @override
  String get commissionRate => 'Provisionsnivå';

  @override
  String get status => 'Status';

  @override
  String get active => 'Aktiv';

  @override
  String get inactive => 'Inaktiv';

  @override
  String get newDriver => 'Ny förare';

  @override
  String get noDrivers => 'Inga förare ännu';

  @override
  String get addFirstDriver => 'Tryck + för att lägga till en förare';

  @override
  String get noEarningsRegistered => 'Inga intäkter registrerade';

  @override
  String get noDataForPeriod => 'Ingen data för denna period';

  @override
  String driverNotFound(Object name) {
    return 'Föraren \'$name\' hittades inte.';
  }

  @override
  String get deleteDriverTitle => 'Ta bort förare?';

  @override
  String deleteDriverContent(Object name) {
    return 'Vill du ta bort $name och alla intäkter?';
  }

  @override
  String get driverAdded => 'Förare tillagd!';

  @override
  String get selectDriver => 'Välj förare';

  @override
  String get enterAmount => 'Ange inkört belopp';

  @override
  String earningSaved(Object platform, Object week) {
    return 'Intäkt sparad för $platform vecka $week';
  }

  @override
  String pdfSaved(Object path) {
    return 'PDF sparad: $path';
  }

  @override
  String excelSaved(Object path) {
    return 'Excel sparad: $path';
  }

  @override
  String errorMessage(Object error) {
    return 'Fel: $error';
  }

  @override
  String get showBrutto => 'Visa Brutto';

  @override
  String get showNetto => 'Visa Netto';

  @override
  String get payrollSpecification => 'Lönespecifikation';

  @override
  String get provisionInclSemester => 'Provision inkl semester';

  @override
  String get exclSemester => 'Exkl semester';

  @override
  String get holidayPay => 'Semester';

  @override
  String get fora => 'Fora';

  @override
  String get arbetsgivaravgifter => 'Arbetsgivaravgifter';

  @override
  String get totalPayrollCost => 'Total lönekostnad';

  @override
  String get shareOfRevenue => 'Andel av inkört belopp';

  @override
  String get tipsTotal => 'Dricks totalt';

  @override
  String get perDriver => 'Per förare';

  @override
  String get perPlatform => 'Per plattform';

  @override
  String get exportPdf => 'Exportera PDF';

  @override
  String get exportExcel => 'Exportera Excel';

  @override
  String get uberGrid => 'Uber Veckogrid';

  @override
  String get monthlyReport => 'Månadsrapport';

  @override
  String get deleteAllData => 'Radera ALL data?';

  @override
  String get deleteAllContent =>
      'Detta tar bort alla förare och intäkter permanent. Kan inte ångras.';

  @override
  String get dataErased => 'All data har raderats';

  @override
  String get calculating => 'Beräknar...';

  @override
  String get saveToDriver => 'Spara till förare';

  @override
  String get calculationSaved => 'Beräkning sparad!';

  @override
  String get appearance => 'Utseende';

  @override
  String get language => 'Språk';

  @override
  String get systemStandard => 'Systemstandard';

  @override
  String get lightMode => 'Ljust läge';

  @override
  String get darkMode => 'Mörkt läge';

  @override
  String get company => 'Företag';

  @override
  String get companyName => 'Företagsnamn';

  @override
  String get taxYear => 'Beskattningsår';

  @override
  String get defaultCommission => 'Standardprovision';

  @override
  String get defaultCommissionDesc => 'Standard provisionssats för nya förare';

  @override
  String get currency => 'Valuta';

  @override
  String get sekFull => 'Svenska kronor (SEK)';

  @override
  String get standardCurrency => 'Standardvaluta';

  @override
  String get dataManagement => 'Datahantering';

  @override
  String get exportData => 'Exportera data';

  @override
  String get importData => 'Importera data (Excel)';

  @override
  String get backupDesc => 'Spara all data som backup';

  @override
  String get importDesc => 'Läs in intäkter från Excel-fil';

  @override
  String get deleteAllDesc => 'Kan inte ångras!';

  @override
  String get taxRates => 'Skattesatser';

  @override
  String importSuccess(Object count) {
    return 'Import slutförd: $count rader inlästa';
  }

  @override
  String importFailed(Object error) {
    return 'Import misslyckades: $error';
  }

  @override
  String get month => 'Månad';

  @override
  String get autoCalculate => 'Beräkna automatiskt';

  @override
  String get total => 'Totalt';

  @override
  String get share => 'Andel';

  @override
  String get calculationBasis => 'Beräkningsunderlag';

  @override
  String get result => 'Resultat';

  @override
  String get semesterRate => 'Semestersats';

  @override
  String get autoCalcDesc => 'Visar Brutto inkört per vecka';

  @override
  String get autoCalcNettoDesc => 'Visar Netto (exkl. moms) per vecka';

  @override
  String get driverName => 'Förarens namn';

  @override
  String get enterDriverName => 'Ange förarens namn';

  @override
  String get commissionLabel => 'Provisionsnivå';

  @override
  String get saveDriver => 'Spara förare';

  @override
  String get login => 'Logga in';

  @override
  String get signUp => 'Skapa konto';

  @override
  String get email => 'E-post';

  @override
  String get password => 'Lösenord';

  @override
  String get forgotPassword => 'Glömt lösenord?';

  @override
  String get sendRecoveryLink => 'Skicka återställningslänk';

  @override
  String get backToLogin => 'Tillbaka till logga in';

  @override
  String get alreadyHaveAccount => 'Har du redan ett konto? Logga in';

  @override
  String get resetPassword => 'Återställ lösenord';

  @override
  String get accountCreatedSuccess =>
      'Konto skapat! Vänligen verifiera din e-post.';

  @override
  String get enterValidEmail => 'Vänligen ange en giltig e-postadress';

  @override
  String get recoveryLinkSent =>
      'Återställningslänk skickad! Kontrollera din inkorg.';

  @override
  String get unexpectedError => 'Ett oväntat fel uppstod';

  @override
  String get dontHaveAccount => 'Har du inget konto? Skapa ett';

  @override
  String get netProfit => 'Nettovinst';

  @override
  String get profitMargin => 'Vinstmarginal';

  @override
  String get afterAllTaxes => 'Efter alla skatter';

  @override
  String get avgPerDriver => 'Snitt per förare';

  @override
  String get margin => 'Marginal';

  @override
  String totalActive(Object count) {
    return '$count totalt';
  }

  @override
  String get shareOfRevenueInfo => 'Andel av intäkter';

  @override
  String get backupRestore => 'Backup & Återställning';

  @override
  String get exportJson => 'Exportera JSON Backup';

  @override
  String get importJson => 'Importera JSON Backup';

  @override
  String get saveAsJson =>
      'Spara all data till en JSON-fil (Fullständig backup)';

  @override
  String get restoreFromJson => 'Återställ databasen från en JSON-fil';

  @override
  String get importHistory => 'Importhistorik';

  @override
  String get viewRevertHistory => 'Visa och återställ tidigare importer';

  @override
  String get account => 'Konto';

  @override
  String get logout => 'Logga ut';

  @override
  String get signOutDesc => 'Logga ut från ditt konto';

  @override
  String get universalImporter => 'Universell importör (.xlsx, .csv)';

  @override
  String get addCommission => 'Lägg till provision %';

  @override
  String get newPlatform => 'Nytt plattformsnamn';

  @override
  String get renamePlatform => 'Byt namn på plattform';

  @override
  String get selectPlatform => 'Välj plattform';

  @override
  String importComplete(Object count) {
    return 'Import slutförd! $count rader tillagda.';
  }

  @override
  String exportFailed(Object error) {
    return 'Export misslyckades: $error';
  }

  @override
  String get restoreSuccess => 'Backup återställd!';

  @override
  String restoreFailed(Object error) {
    return 'Återställning misslyckades: $error';
  }

  @override
  String get revertImport => 'Återställ import?';

  @override
  String revertConfirm(Object count, Object file) {
    return 'Detta kommer att radera alla $count intäkter från \"$file\". Detta kan inte ångras.';
  }

  @override
  String get revertSuccess => 'Importen har återställts';

  @override
  String get ok => 'OK';

  @override
  String get add => 'Lägg till';

  @override
  String get update => 'Uppdatera';

  @override
  String get back => 'Tillbaka';

  @override
  String get saveCompanyName => 'Spara företagsnamn';

  @override
  String get saving => 'Sparar...';

  @override
  String get companyNameUpdated => 'Företagsnamn uppdaterat!';

  @override
  String get syncError => 'Sync-fel med Supabase';

  @override
  String get syncErrorDesc => 'Kunde inte spara inställningar till molnet.';

  @override
  String get boltFleetAutomation => 'Bolt Fleet Automation';

  @override
  String get syncDataFromBolt => 'Synka data från Bolt';

  @override
  String get syncNow => 'Synka nu';

  @override
  String get syncing => 'Synkar...';

  @override
  String get syncSuccess => 'Synkronisering lyckades!';

  @override
  String syncFailed(Object error) {
    return 'Synkronisering misslyckades: $error';
  }

  @override
  String get ridePrice => 'Resepris';

  @override
  String get boltCommission => 'Bolt provision';

  @override
  String get vat6 => '6% Moms';

  @override
  String get employerFee => 'Arbetsgivaravgift';

  @override
  String get finalNetPayout => 'Slutlig nettoutbetalning';

  @override
  String get yourTrips => 'Dina resor';

  @override
  String get noTripsFound => 'Inga resor hittades för dig ännu.';

  @override
  String get ref => 'Ref';

  @override
  String get driverDashboard => 'Föraröversikt';

  @override
  String get adminDashboard => 'Adminöversikt';

  @override
  String get netEarnings => 'Nettointäkt';

  @override
  String get priceTotal => 'Totalt pris';

  @override
  String get saasIntegrations => 'SaaS-integrationer';

  @override
  String get boltFleetApi => 'Bolt Fleet API';

  @override
  String get connected => 'Ansluten';

  @override
  String get setupCredentials => 'Konfigurera dina företagsuppgifter';

  @override
  String get checkingConnection => 'Kontrollerar anslutning...';

  @override
  String get apiIntegration => 'API-integration';

  @override
  String get clientId => 'Klient-ID';

  @override
  String get clientSecret => 'Klienthemlighet';

  @override
  String get fleetId => 'Företags- / Fleet-ID';

  @override
  String get saveIntegrationSettings => 'Spara integrationsinställningar';

  @override
  String get required => 'Obligatorisk';

  @override
  String get settingsSaved => 'Inställningarna har sparats';

  @override
  String get savePreset => 'Spara förinställning';

  @override
  String get presetName => 'Namn på förinställning';

  @override
  String get columnMapping => 'Kolumnmappning';

  @override
  String get loadPreset => 'Ladda förinställning';

  @override
  String get notMapped => 'Inte mappad';

  @override
  String get preview => 'Förhandsgranska';

  @override
  String get startImport => 'Starta import';

  @override
  String get unmatchedDriver => 'Okänd förare';

  @override
  String get createNewDriver => 'Skapa ny förare';

  @override
  String get mapAndContinue => 'Mappa och fortsätt';

  @override
  String get skipRow => 'Hoppa över rad';

  @override
  String get linkToExisting => 'Länka till befintlig:';

  @override
  String get incompleteRowsSkipped =>
      'Obs: Ofullständiga rader kommer att hoppas över vid import.';

  @override
  String get signInDesc => 'Logga in på ditt Lönmeter-konto';

  @override
  String get signUpDesc => 'Hantera din flotta professionellt';

  @override
  String minCharacters(Object count) {
    return 'Minst $count tecken';
  }

  @override
  String get page => 'Sida';

  @override
  String get generated => 'Skapad';

  @override
  String get tax_deduction => 'Skatteavdrag';

  @override
  String get take_home_pay => 'Utbetalas';

  @override
  String get andel_av_inkort => 'Andel av inkört';

  @override
  String get weeklyEarnings => 'Veckointäkter';

  @override
  String get vat => 'Moms';
}
