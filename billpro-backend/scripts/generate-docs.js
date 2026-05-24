const fs = require('fs');
const listEndpoints = require('express-list-endpoints');
const app = require('../src/app'); // Import your express app

const endpoints = listEndpoints(app);

let markdown = `# BillQube Backend API Documentation\n\n`;
markdown += `Base URL: \`http://localhost:8587\`\n\n`;
markdown += `This document contains dynamically extracted endpoints, grouped by modules, with expected cURL commands and standardized responses.\n\n`;
markdown += `---\n\n`;

// Group endpoints by root path
const modules = {};

endpoints.forEach((ep) => {
  if (ep.path.includes('bull-board')) return; // skip bull-board

  const pathParts = ep.path.split('/');
  // usually /api/v1/module/...
  const moduleName = pathParts[3] || 'general';
  
  if (!modules[moduleName]) {
    modules[moduleName] = [];
  }
  modules[moduleName].push(ep);
});

Object.keys(modules).forEach((moduleName) => {
  markdown += `## Module: ${moduleName.toUpperCase()}\n\n`;
  
  modules[moduleName].forEach((ep) => {
    ep.methods.forEach((method) => {
      markdown += `### ${method} \`${ep.path}\`\n\n`;
      
      // Generate cURL
      markdown += `**Example cURL Request:**\n`;
      markdown += `\`\`\`bash\n`;
      markdown += `curl -X ${method} http://localhost:8587${ep.path} \\\n`;
      markdown += `  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \\\n`;
      markdown += `  -H "Content-Type: application/json"`;

      if (['POST', 'PUT', 'PATCH'].includes(method)) {
        markdown += ` \\\n  -d '{
    "exampleField": "Replace this with actual JSON payload based on validation rules"
  }'`;
      }
      markdown += `\n\`\`\`\n\n`;

      // Generate Success Response
      markdown += `**Success Response (200 / 201):**\n`;
      markdown += `\`\`\`json\n`;
      markdown += `{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}\n`;
      markdown += `\`\`\`\n\n`;

      // Generate Error Response
      markdown += `**Error Response (400 / 401 / 403 / 404 / 422 / 500):**\n`;
      markdown += `\`\`\`json\n`;
      markdown += `{
  "success": false,
  "message": "Error description or Validation failed",
  "errors": [
    { "field": "fieldName", "message": "Field specific error message" }
  ]
}\n`;
      markdown += `\`\`\`\n\n`;
      markdown += `---\n\n`;
    });
  });
});

fs.writeFileSync('API_DOCS.md', markdown);
console.log('✅ API_DOCS.md generated successfully with', endpoints.length, 'endpoints.');
