require('dotenv').config();
const app = require('./app');

const PORT = process.env.PORT || 8999;

app.listen(PORT, () => {
  console.log(`Find Your Way API (Phase 1 - Monolith) listening on http://localhost:${PORT}`);
});
