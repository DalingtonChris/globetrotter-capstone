const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuid } = require('uuid');
const { readCollection, writeCollection } = require('../utils/jsonStore');

const SALT_ROUNDS = 10;

function toPublicUser(user) {
  const { passwordHash, ...publicUser } = user;
  return publicUser;
}

function signToken(user) {
  return jwt.sign(
    { sub: user.id, email: user.email, name: user.name },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
}

function isValidEmail(email) {
  return typeof email === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function register(req, res) {
  const { name, email, password } = req.body || {};

  if (!name || !name.trim()) {
    return res.status(400).json({ error: 'Name is required' });
  }
  if (!isValidEmail(email)) {
    return res.status(400).json({ error: 'A valid email is required' });
  }
  if (!password || password.length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters' });
  }

  const users = readCollection('users');
  const normalizedEmail = email.trim().toLowerCase();

  if (users.some((u) => u.email === normalizedEmail)) {
    return res.status(409).json({ error: 'An account with this email already exists' });
  }

  const user = {
    id: uuid(),
    name: name.trim(),
    email: normalizedEmail,
    passwordHash: bcrypt.hashSync(password, SALT_ROUNDS),
    preferences: [],
    createdAt: new Date().toISOString(),
  };

  users.push(user);
  writeCollection('users', users);

  const token = signToken(user);
  return res.status(201).json({ token, user: toPublicUser(user) });
}

function login(req, res) {
  const { email, password } = req.body || {};

  if (!isValidEmail(email) || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  const users = readCollection('users');
  const normalizedEmail = email.trim().toLowerCase();
  const user = users.find((u) => u.email === normalizedEmail);

  if (!user || !bcrypt.compareSync(password, user.passwordHash)) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }

  const token = signToken(user);
  return res.json({ token, user: toPublicUser(user) });
}

function me(req, res) {
  const users = readCollection('users');
  const user = users.find((u) => u.id === req.user.id);

  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }

  return res.json({ user: toPublicUser(user) });
}

function updatePreferences(req, res) {
  const { preferences } = req.body || {};

  if (!Array.isArray(preferences) || !preferences.every((p) => typeof p === 'string')) {
    return res.status(400).json({ error: 'preferences must be an array of strings' });
  }

  const users = readCollection('users');
  const index = users.findIndex((u) => u.id === req.user.id);

  if (index === -1) {
    return res.status(404).json({ error: 'User not found' });
  }

  users[index].preferences = preferences;
  writeCollection('users', users);

  return res.json({ user: toPublicUser(users[index]) });
}

module.exports = { register, login, me, updatePreferences, toPublicUser };
