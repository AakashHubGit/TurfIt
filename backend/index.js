const connectToMongo = require('./db');
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

connectToMongo();

const app = express()
const port = 5000 || process.env.PORT

app.use(cors());
app.use(express.json());


app.use('/api/auth', require('./routes/auth'))
app.use('/api/turf', require('./routes/turf'))
app.use('/api/booking', require('./routes/booking'))
// app.use('/api/products', require('./routes/products'))



app.listen(port, () => {
    console.log(`Example app listening on port ${port}`)
})
