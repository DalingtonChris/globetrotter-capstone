const path = require('path');
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const authRoutes = require('./routes/auth.routes');
const destinationsRoutes = require('./routes/destinations.routes');
const itinerariesRoutes = require('./routes/itineraries.routes');

const app = express();

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

app.use('/static', express.static(path.join(__dirname, '..', 'static')));

app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', service: 'find-your-way-api', phase: 1 });
});

app.use('/api/auth', authRoutes);
app.use('/api', destinationsRoutes);
app.use('/api/itineraries', itinerariesRoutes);

app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

module.exports = app;
