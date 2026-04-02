import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReportExportService {
  static Future<void> exportToPdf(
    List<dynamic> reports,
    String title, {
    String fileNameSuffix = '',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Member', 'Task', 'Status', 'Description'],
            data: reports.map((r) {
              final date = r['createdAt']?.toString().split('T')[0] ?? '';
              final name = r['user']?['name'] ?? 'Unknown';
              final task = r['task']?['title'] ?? 'Unknown';
              final status =
                  r['task']?['status']?.toString().replaceAll('_', ' ') ?? '';
              final desc = r['reportText'] ?? '';
              return [date, name, task, status, desc];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(6),
            columnWidths: {
              0: const pw.FixedColumnWidth(80),
              1: const pw.FixedColumnWidth(100),
              2: const pw.FixedColumnWidth(150),
              3: const pw.FixedColumnWidth(80),
              4: const pw.FlexColumnWidth(),
            },
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/${title.replaceAll(' ', '_')}$fileNameSuffix.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Here is the $title.'),
    );
  }

  static Future<void> exportToExcel(
    List<dynamic> reports,
    String title, {
    String fileNameSuffix = '',
  }) async {
    var excel = Excel.createExcel();
    var sheet = excel['Sheet1'];

    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Member Name'),
      TextCellValue('Task Title'),
      TextCellValue('Status'),
      TextCellValue('Report / Remarks'),
    ]);

    for (var r in reports) {
      final date = r['createdAt']?.toString().split('T')[0] ?? '';
      final name = r['user']?['name'] ?? 'Unknown';
      final task = r['task']?['title'] ?? 'Unknown';
      final status =
          r['task']?['status']?.toString().replaceAll('_', ' ') ?? '';
      final desc = r['reportText'] ?? '';

      sheet.appendRow([
        TextCellValue(date),
        TextCellValue(name),
        TextCellValue(task),
        TextCellValue(status),
        TextCellValue(desc),
      ]);
    }

    var fileBytes = excel.save();

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/${title.replaceAll(' ', '_')}$fileNameSuffix.xlsx',
    );

    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Here is the $title.'),
      );
    }
  }
}
