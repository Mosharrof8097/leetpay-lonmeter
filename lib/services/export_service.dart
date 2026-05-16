import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../models/monthly_payroll.dart';
import '../models/earnings_entry.dart';
import '../utils/formatters.dart';
import '../services/database_service.dart';
import '../utils/swedish_tax_constants.dart';

class ExportService {
  static Future<File> generateMonthlyPDF({
    required List<MonthlyPayroll> payrolls,
    required String monthName,
    required int year,
    required String companyName,
    required Map<String, String> labels,
  }) async {

    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final baseStyle = pw.TextStyle(font: font, fontSize: 10);
    final boldStyle = pw.TextStyle(font: fontBold, fontSize: 10, fontWeight: pw.FontWeight.bold);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            '${labels['page'] ?? 'Sida'} ${context.pageNumber} / ${context.pagesCount}',
            style: baseStyle.copyWith(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(companyName, style: boldStyle.copyWith(fontSize: 18)),
                    pw.Text(labels['monthly_report'] ?? 'Månadsrapport', style: baseStyle.copyWith(fontSize: 14, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('$monthName $year', style: boldStyle.copyWith(fontSize: 16)),
                    pw.Text('${labels['generated'] ?? 'Skapad'}: ${DateTime.now().toString().substring(0, 16)}', 
                        style: baseStyle.copyWith(fontSize: 8)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text(labels['summary'] ?? 'Sammanfattning', style: boldStyle.copyWith(fontSize: 14)),
          pw.SizedBox(height: 8),
          _buildSummaryTable(payrolls, baseStyle, boldStyle, labels),
          pw.SizedBox(height: 24),
          _buildPlatformSummary(payrolls, baseStyle, boldStyle, labels),
          pw.SizedBox(height: 32),
          pw.Text(labels['driver_details'] ?? 'Förardetaljer', style: boldStyle.copyWith(fontSize: 14)),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 12),
          ...payrolls.map((p) => _buildDriverDetail(p, baseStyle, boldStyle, labels)),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Rapport_${monthName}_$year.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildSummaryTable(List<MonthlyPayroll> payrolls, pw.TextStyle baseStyle, pw.TextStyle boldStyle, Map<String, String> labels) {
    return pw.TableHelper.fromTextArray(
      headerStyle: boldStyle.copyWith(fontSize: 9, color: PdfColors.white),
      cellStyle: baseStyle.copyWith(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
      headers: [
        labels['drivers'] ?? 'Förare',
        labels['amount'] ?? 'Inkört',
        labels['provision_incl_semester'] ?? 'Prov inkl sem',
        labels['dricks_total'] ?? 'Dricks',
        labels['payroll_cost'] ?? 'Lönekostnad'
      ],
      data: payrolls.map((p) => [
        p.driverName,
        formatNumber(p.totalBrutto),
        formatNumber(p.provisionInklSemester),
        formatNumber(p.totalDricks),
        formatNumber(p.totalLonekostnad),
      ]).toList(),
    );
  }

  static pw.Widget _buildPlatformSummary(List<MonthlyPayroll> payrolls, pw.TextStyle baseStyle, pw.TextStyle boldStyle, Map<String, String> labels) {
    final Map<String, double> platformTotals = {};
    double totalAll = 0;
    
    for (final p in payrolls) {
      p.platformBrutto.forEach((id, amount) {
        platformTotals[id] = (platformTotals[id] ?? 0) + amount;
        totalAll += amount;
      });
    }

    final tableData = platformTotals.entries.map((e) {
      final name = e.key[0].toUpperCase() + e.key.substring(1).toLowerCase();
      return [name, formatNumber(e.value)];
    }).toList();
    
    tableData.add([labels['total'] ?? 'Totalt', formatNumber(totalAll)]);

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(labels['revenue_by_platform'] ?? 'Plattformssammanfattning',
          style: boldStyle.copyWith(fontSize: 12)),
      pw.SizedBox(height: 8),
      pw.SizedBox(
        width: 300,
        child: pw.TableHelper.fromTextArray(
          headerStyle: boldStyle.copyWith(fontSize: 9),
          cellStyle: baseStyle.copyWith(fontSize: 8),
          headers: [labels['platform'] ?? 'Plattform', labels['amount'] ?? 'Total Brutto'],
          data: tableData,
        ),
      ),
    ]);
  }

  static pw.Widget _buildDriverDetail(MonthlyPayroll p, pw.TextStyle baseStyle, pw.TextStyle boldStyle, Map<String, String> labels) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(p.driverName, style: boldStyle.copyWith(fontSize: 12, color: PdfColors.blue800)),
            pw.Text('${(p.commissionRate * 100).toStringAsFixed(1)}% Provision', style: baseStyle.copyWith(fontSize: 10)),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          cellStyle: baseStyle.copyWith(fontSize: 8),
          headerStyle: boldStyle.copyWith(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          headers: [labels['post'] ?? 'Post', labels['amount'] ?? 'Belopp (kr)'],
          data: [
            [labels['provision_incl_semester'] ?? 'Provision inkl semester', formatNumber(p.provisionInklSemester)],
            [labels['excl_semester'] ?? 'Exkl semester', formatNumber(p.exklSemester)],
            ['${labels['semester'] ?? 'Semester'} (${(p.semesterRate * 100).toStringAsFixed(1)}%)', formatNumber(p.semesterAmount)],
            ['${labels['fora'] ?? 'Fora'} (${(kForaSats * 100).toStringAsFixed(1)}%)', formatNumber(p.foraAmount)],
            ['${labels['arbetsgivaravgifter'] ?? 'Arbetsgivaravgifter'} (${(kArbetsgivaravgifter * 100).toStringAsFixed(2)}%)', formatNumber(p.arbetsgivaravgifter)],
            [labels['payroll_cost'] ?? 'Total lönekostnad', formatNumber(p.totalLonekostnad)],
            ['Skatteavdrag (30%)', formatNumber(-p.preliminaryTax)],
            ['Utbetalas till konto', formatNumber(p.takeHomePay)],
            [labels['share_of_revenue'] ?? 'Andel av inkört belopp', formatPercent(p.effectiveRate)],
          ],
        ),
      ]),
    );
  }

  static Future<File> generateMonthlyExcel({
    required List<MonthlyPayroll> payrolls,
    required String monthName,
    required int year,
    required String companyName,
    required Map<String, String> labels,
  }) async {
    final excel = Excel.createExcel();
    final String sheetName = labels['monthly_report'] ?? 'Månadsrapport';
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    // Title styling
    CellStyle titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontFamily: getFontFamily(FontFamily.Calibri),
      horizontalAlign: HorizontalAlign.Center,
    );

    CellStyle headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('FF1A237E'), // Blue 900
      fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
      fontSize: 11,
      fontFamily: getFontFamily(FontFamily.Calibri),
      horizontalAlign: HorizontalAlign.Center,
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Header Row
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 0));
    var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    cell.value = TextCellValue('$companyName - $monthName $year');
    cell.cellStyle = titleStyle;

    sheet.appendRow([]); // Spacer

    // Column Headers
    final headers = [
      labels['drivers'] ?? 'Förare',
      labels['amount'] ?? 'Inkört belopp',
      labels['show_netto'] ?? 'Netto',
      labels['dricks_total'] ?? 'Dricks',
      labels['provision_incl_semester'] ?? 'Prov inkl semester',
      labels['excl_semester'] ?? 'Exkl semester',
      labels['semester'] ?? 'Semester',
      labels['fora'] ?? 'Fora',
      labels['arbetsgivaravgifter'] ?? 'Arbetsgivaravgifter',
      labels['payroll_cost'] ?? 'Total lönekostnad',
      'Skatt',
      'Netto Payout',
      labels['share'] ?? 'Andel %',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    
    // Apply header style
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2)).cellStyle = headerStyle;
    }

    // Data Rows
    for (final p in payrolls) {
      sheet.appendRow([
        TextCellValue(p.driverName),
        DoubleCellValue(p.totalBrutto),
        DoubleCellValue(p.totalNetto),
        DoubleCellValue(p.totalDricks),
        DoubleCellValue(p.provisionInklSemester),
        DoubleCellValue(p.exklSemester),
        DoubleCellValue(p.semesterAmount),
        DoubleCellValue(p.foraAmount),
        DoubleCellValue(p.arbetsgivaravgifter),
        DoubleCellValue(p.totalLonekostnad),
        DoubleCellValue(-p.preliminaryTax),
        DoubleCellValue(p.takeHomePay),
        DoubleCellValue(p.effectiveRate * 100),
      ]);
    }

    // Set column widths (rough approximation)
    sheet.setColumnWidth(0, 25); // Name
    for (int i = 1; i < 10; i++) {
      sheet.setColumnWidth(i, 18);
    }
    sheet.setColumnWidth(10, 12); // %

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Rapport_${monthName}_$year.xlsx');
    final bytes = excel.encode();
    if (bytes != null) await file.writeAsBytes(bytes);
    return file;
  }
}