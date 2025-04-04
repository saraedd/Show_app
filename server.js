require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const showRoutes = require('./routes/shows');
const authRoutes = require('./routes/auth'); // Ajouté

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(bodyParser.json());
app.use('/uploads', express.static('uploads'));
app.use('/shows', showRoutes);
app.use('/', authRoutes); // Ajouté pour gérer /login, /register, etc.

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});