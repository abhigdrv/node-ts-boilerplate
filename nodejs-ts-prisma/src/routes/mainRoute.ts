import { Router } from 'express';
import { getMains, createMain } from '../controllers/mainController';

const router = Router();

router.get('/mains', getMains);
router.post('/mains', createMain);

export default router;
