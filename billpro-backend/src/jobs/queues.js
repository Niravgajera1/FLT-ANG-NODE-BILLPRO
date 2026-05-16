const { Queue, Worker } = require('bullmq');
const { getRedis } = require('../config/redis');
const logger = require('../utils/logger');

let pdfQueue, emailQueue, gstRetryQueue;

const initQueues = () => {
  const connection = getRedis();

  // ─── PDF Generation Queue ─────────────────────────────────────────────────
  pdfQueue = new Queue(process.env.QUEUE_PDF_GENERATION || 'pdf-generation', { connection });

  new Worker(process.env.QUEUE_PDF_GENERATION || 'pdf-generation', async (job) => {
    const { type, data } = job.data;
    logger.info(`Processing PDF job: ${job.id} [${type}]`);

    if (type === 'sales_invoice') {
      // TODO: call PDF generation service
      // const pdfBuffer = await pdfService.generateInvoicePDF(data);
      // await s3Service.upload(pdfBuffer, `invoices/${data.invoiceNumber}.pdf`);
    }
  }, {
    connection,
    concurrency: 3,
  });

  // ─── Email Queue ──────────────────────────────────────────────────────────
  emailQueue = new Queue(process.env.QUEUE_EMAIL_SEND || 'email-send', { connection });

  new Worker(process.env.QUEUE_EMAIL_SEND || 'email-send', async (job) => {
    const { to, subject, html, attachments } = job.data;
    logger.info(`Sending email to: ${to} [${subject}]`);
    // TODO: call email service (SendGrid/SES)
  }, { connection, concurrency: 5 });

  // ─── GST API Retry Queue ──────────────────────────────────────────────────
  gstRetryQueue = new Queue(process.env.QUEUE_GST_RETRY || 'gst-retry', { connection });

  new Worker(process.env.QUEUE_GST_RETRY || 'gst-retry', async (job) => {
    const { invoiceId, companyId, attempt } = job.data;
    logger.info(`Retrying e-invoice for invoice: ${invoiceId} [attempt: ${attempt}]`);
    // TODO: call GSP API to generate IRN
  }, {
    connection,
    concurrency: 2,
    limiter: { max: 10, duration: 60000 }, // GSP API rate limit
  });

  logger.info('BullMQ queues initialized');
};

// ─── Queue Job Helpers ────────────────────────────────────────────────────────
const addPDFJob = async (type, data) => {
  return pdfQueue?.add(type, { type, data }, { attempts: 3, backoff: { type: 'exponential', delay: 2000 } });
};

const addEmailJob = async (emailData) => {
  return emailQueue?.add('send-email', emailData, { attempts: 3, backoff: { type: 'fixed', delay: 5000 } });
};

const addGSTRetryJob = async (invoiceId, companyId, attempt = 1) => {
  const delay = Math.min(attempt * 30000, 300000); // Max 5 min delay
  return gstRetryQueue?.add('retry-einvoice', { invoiceId, companyId, attempt }, {
    delay,
    attempts: 5,
    backoff: { type: 'exponential', delay: 30000 },
  });
};

module.exports = { initQueues, addPDFJob, addEmailJob, addGSTRetryJob };
