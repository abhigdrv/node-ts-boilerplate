import { Request, Response } from 'express';
import prisma from '../config/database';

export const getMains = async (req: Request, res: Response): Promise<void> => {
    const mains = await prisma.main.findMany();
    res.json(mains);
};

export const createMain = async (req: Request, res: Response): Promise<void> => {
    const { name, value } = req.body;
    const main = await prisma.main.create({
        data: {
            name,
            value
        }
    });
    res.json(main);
};
