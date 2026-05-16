const fs = require('fs');
const puppeteer = require('puppeteer');
const { marked } = require('marked');

(async () => {
  try {
    console.log('Reading API_DOCS.md...');
    const markdown = fs.readFileSync('API_DOCS.md', 'utf-8');
    
    console.log('Converting Markdown to HTML...');
    const htmlContent = marked.parse(markdown);

    const html = `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>API Documentation</title>
      <style>
        body {
          font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
          line-height: 1.6;
          color: #333;
          margin: 0;
          padding: 20px 40px;
        }
        h1, h2, h3 {
          color: #2c3e50;
        }
        h1 { font-size: 28px; border-bottom: 2px solid #eee; padding-bottom: 10px; }
        h2 { font-size: 22px; margin-top: 30px; border-bottom: 1px solid #eee; padding-bottom: 5px; }
        h3 { font-size: 18px; color: #34495e; margin-top: 25px; }
        pre {
          background-color: #f8f9fa;
          padding: 15px;
          border-radius: 5px;
          border: 1px solid #e9ecef;
          overflow-x: auto;
          font-size: 13px;
          line-height: 1.4;
        }
        code {
          font-family: Consolas, Monaco, 'Andale Mono', monospace;
          background-color: #f1f3f5;
          padding: 2px 4px;
          border-radius: 3px;
        }
        pre code {
          background-color: transparent;
          padding: 0;
        }
        hr { border: 0; border-top: 1px dashed #ccc; margin: 30px 0; }
        .page-break { page-break-before: always; }
      </style>
    </head>
    <body>
      ${htmlContent}
    </body>
    </html>
    `;

    console.log('Launching Puppeteer to generate PDF...');
    const browser = await puppeteer.launch({ headless: 'new' });
    const page = await browser.newPage();
    
    await page.setContent(html, { waitUntil: 'networkidle0' });
    
    await page.pdf({
      path: 'API_DOCS.pdf',
      format: 'A4',
      printBackground: true,
      margin: {
        top: '20px',
        bottom: '40px',
        left: '20px',
        right: '20px'
      }
    });

    await browser.close();
    console.log('✅ API_DOCS.pdf generated successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error generating PDF:', error);
    process.exit(1);
  }
})();
