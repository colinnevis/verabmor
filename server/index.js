import express from 'express';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import Stripe from 'stripe';
import { fileURLToPath } from 'url';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.use(express.json());

const stripeSecret = process.env.STRIPE_SECRET_KEY || 'sk_test_stub';
const stripe = new Stripe(stripeSecret, { apiVersion: '2023-10-16' });

const placeholders = Array.from({ length: 10 }).map((_, idx) => `https://picsum.photos/seed/server${idx}/400/400`);

app.post('/imagegen/mock', (req, res) => {
  const term = req.body.term || 'card';
  const hash = Math.abs(term.split('').reduce((acc, ch) => acc + ch.charCodeAt(0), 0));
  const url = placeholders[hash % placeholders.length];
  res.json({ url, provider: 'mock', term });
});

app.post('/webhook/stripe', async (req, res) => {
  const event = req.body;
  console.log('Stripe webhook received', event.type);
  if (event.type === 'invoice.payment_succeeded') {
    console.log('Payment captured for', event.data?.object?.customer);
  }
  res.json({ received: true });
});

app.get('/export/tsv/:type', (req, res) => {
  const { type } = req.params;
  const filePath = path.join(__dirname, 'sample_exports', `${type}.tsv`);
  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'Unknown export type' });
  }
  res.setHeader('Content-Type', 'text/tab-separated-values');
  fs.createReadStream(filePath).pipe(res);
});

app.get('/health', (_, res) => res.json({ status: 'ok' }));

const port = process.env.PORT || 4000;
app.listen(port, () => {
  console.log(`Stub server listening on http://localhost:${port}`);
});
