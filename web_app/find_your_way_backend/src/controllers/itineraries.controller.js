const { v4: uuid } = require('uuid');
const { readCollection, writeCollection } = require('../utils/jsonStore');

function withDestinations(itinerary, destinationsById) {
  return {
    ...itinerary,
    items: itinerary.items.map((item) => ({
      ...item,
      destination: destinationsById.get(item.destinationId) || null,
    })),
  };
}

function list(req, res) {
  const itineraries = readCollection('itineraries').filter((it) => it.userId === req.user.id);
  const destinations = readCollection('destinations');
  const destinationsById = new Map(destinations.map((d) => [d.id, d]));

  const enriched = itineraries
    .map((it) => withDestinations(it, destinationsById))
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

  return res.json({ count: enriched.length, itineraries: enriched });
}

function getById(req, res) {
  const itinerary = readCollection('itineraries').find(
    (it) => it.id === req.params.id && it.userId === req.user.id
  );

  if (!itinerary) {
    return res.status(404).json({ error: 'Itinerary not found' });
  }

  const destinations = readCollection('destinations');
  const destinationsById = new Map(destinations.map((d) => [d.id, d]));

  return res.json({ itinerary: withDestinations(itinerary, destinationsById) });
}

function create(req, res) {
  const { title, startDate, endDate, notes, items } = req.body || {};

  if (!title || !title.trim()) {
    return res.status(400).json({ error: 'Title is required' });
  }
  if (!Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'At least one destination item is required' });
  }

  const destinations = readCollection('destinations');
  const destinationIds = new Set(destinations.map((d) => d.id));
  const invalid = items.find((item) => !item || !destinationIds.has(item.destinationId));

  if (invalid) {
    return res.status(400).json({ error: 'One or more destinationId values are invalid' });
  }

  const itinerary = {
    id: uuid(),
    userId: req.user.id,
    title: title.trim(),
    startDate: startDate || null,
    endDate: endDate || null,
    notes: notes || '',
    items: items.map((item) => ({
      destinationId: item.destinationId,
      note: item.note || '',
    })),
    createdAt: new Date().toISOString(),
  };

  const itineraries = readCollection('itineraries');
  itineraries.push(itinerary);
  writeCollection('itineraries', itineraries);

  const destinationsById = new Map(destinations.map((d) => [d.id, d]));
  return res.status(201).json({ itinerary: withDestinations(itinerary, destinationsById) });
}

function remove(req, res) {
  const itineraries = readCollection('itineraries');
  const index = itineraries.findIndex(
    (it) => it.id === req.params.id && it.userId === req.user.id
  );

  if (index === -1) {
    return res.status(404).json({ error: 'Itinerary not found' });
  }

  itineraries.splice(index, 1);
  writeCollection('itineraries', itineraries);

  return res.status(204).send();
}

module.exports = { list, getById, create, remove };
