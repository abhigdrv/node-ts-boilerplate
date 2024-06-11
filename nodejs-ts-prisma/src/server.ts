import express from 'express';
import mainRoute from './routes/mainRoute';

const app = express();

app.use(express.json());
app.use('/api', mainRoute);

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
