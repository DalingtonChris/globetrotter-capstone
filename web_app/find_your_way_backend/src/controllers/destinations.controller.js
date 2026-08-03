const { readCollection } = require('../utils/jsonStore');

function matchesQuery(destination, q) {
  if (!q) return true;
  const needle = q.trim().toLowerCase();
  if (!needle) return true;

  const haystack = [
    destination.name,
    destination.city,
    destination.country,
    destination.category,
    destination.description,
    ...(destination.tags || []),
  ]
    .join(' ')
    .toLowerCase();

  return haystack.includes(needle);
}

function list(req, res) {
  const { q, category } = req.query;
  let destinations = readCollection('destinations');

  if (category && category !== 'All') {
    destinations = destinations.filter(
      (d) => d.category.toLowerCase() === String(category).toLowerCase()
    );
  }

  destinations = destinations.filter((d) => matchesQuery(d, q));
  destinations = [...destinations].sort((a, b) => b.popularity - a.popularity);

  return res.json({
    count: destinations.length,
    destinations,
  });
}

function categories(_req, res) {
  const destinations = readCollection('destinations');
  const unique = [...new Set(destinations.map((d) => d.category))].sort();
  return res.json({ categories: unique });
}

function getById(req, res) {
  const destinations = readCollection('destinations');
  const destination = destinations.find((d) => d.id === req.params.id);

  if (!destination) {
    return res.status(404).json({ error: 'Destination not found' });
  }

  return res.json({ destination });
}

function recommendations(req, res) {
  const destinations = readCollection('destinations');
  const limit = Math.min(parseInt(req.query.limit, 10) || 6, destinations.length);

  let userPreferences = [];
  let pastCategories = [];

  if (req.user) {
    const users = readCollection('users');
    const user = users.find((u) => u.id === req.user.id);
    userPreferences = user?.preferences || [];

    const itineraries = readCollection('itineraries');
    const myDestinationIds = new Set(
      itineraries
        .filter((it) => it.userId === req.user.id)
        .flatMap((it) => it.items.map((item) => item.destinationId))
    );
    pastCategories = destinations
      .filter((d) => myDestinationIds.has(d.id))
      .map((d) => d.category);
  }

  const personalizationTags = new Set(
    [...userPreferences, ...pastCategories].map((t) => t.toLowerCase())
  );

  const scored = destinations.map((d) => {
    let score = d.popularity;
    const destTags = [d.category, ...(d.tags || [])].map((t) => t.toLowerCase());
    const matchCount = destTags.filter((t) => personalizationTags.has(t)).length;
    score += matchCount * 40;
    return { destination: d, score };
  });

  scored.sort((a, b) => b.score - a.score);

  return res.json({
    personalized: personalizationTags.size > 0,
    destinations: scored.slice(0, limit).map((s) => s.destination),
  });
}

module.exports = { list, categories, getById, recommendations };
