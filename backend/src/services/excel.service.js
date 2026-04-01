const ExcelJS = require('exceljs');

/**
 * Service to handle standardized Excel generation across the application
 */
class ExcelService {
  /**
   * Create a basic styled workbook with a single sheet
   * @param {string} sheetName - Name of the worksheet
   * @param {Array} columns - Column definitions { header: string, key: string, width: number }
   * @param {Array} data - Array of objects matching the column keys
   * @returns {Promise<Buffer>} - Excel file buffer
   */
  async generateSimpleExcel(sheetName, columns, data) {
    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'Engineering Pulse Team App';
    workbook.lastModifiedBy = 'Engineering Pulse Admin';
    workbook.created = new Date();
    
    const worksheet = workbook.addWorksheet(sheetName, {
      views: [{ state: 'frozen', ySplit: 1 }]
    });

    // 1. Define Columns
    worksheet.columns = columns.map(col => ({
      header: col.header.toUpperCase(),
      key: col.key,
      width: col.width || 20,
      style: { 
        alignment: { 
          vertical: 'middle', 
          horizontal: 'center',
          wrapText: true 
        } 
      }
    }));

    // 2. Style Header Row
    const headerRow = worksheet.getRow(1);
    headerRow.height = 25;
    headerRow.eachCell((cell) => {
      cell.fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FF1E293B' }, // slate-800
      };
      cell.font = {
        bold: true,
        color: { argb: 'FFFFFFFF' },
        size: 11
      };
      cell.border = {
        bottom: { style: 'medium', color: { argb: 'FF334155' } }
      };
    });

    // 3. Add Data Rows
    worksheet.addRows(data);

    // 4. Style Data Rows (Alternating colors)
    worksheet.eachRow((row, rowNumber) => {
      if (rowNumber === 1) return; // Skip header
      
      if (rowNumber % 2 === 0) {
        row.eachCell((cell) => {
          cell.fill = {
            type: 'pattern',
            pattern: 'solid',
            fgColor: { argb: 'FFF8FAFC' }, // slate-50
          };
        });
      }
      
      // Ensure vertical alignment and wrapping is applied to every cell during row iteration
      row.eachCell((cell) => {
        cell.alignment = { 
          vertical: 'middle', 
          horizontal: 'center', 
          wrapText: true 
        };
        
        cell.border = {
          bottom: { style: 'thin', color: { argb: 'FFE2E8F0' } },
          right: { style: 'thin', color: { argb: 'FFE2E8F0' } }
        };
      });
    });

    // 5. Generate Buffer
    return await workbook.xlsx.writeBuffer();
  }
}

module.exports = new ExcelService();
