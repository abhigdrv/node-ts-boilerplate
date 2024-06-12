#!/bin/bash
cd "nodejs-ts-prisma"
read -p "Enter API name (e.g., user): " API_NAME
read -p "Enter model attributes (e.g., name:string age:int): " MODEL_ATTRIBUTES

# Convert API name to PascalCase for class names and camelCase for variable names
CLASS_NAME=$(echo "$API_NAME" | sed -r 's/(^|-)(\w)/\U\2/g')
VAR_NAME=$(echo "$API_NAME" | sed -r 's/(-)(\w)/\U\2/g' | sed 's/^-//')

# Define Prisma model attributes
PRISMA_ATTRIBUTES=""
for ATTRIBUTE in $MODEL_ATTRIBUTES; do
  NAME=$(echo $ATTRIBUTE | cut -d: -f1)
  TYPE=$(echo $ATTRIBUTE | cut -d: -f2)
  case $TYPE in
    int) PRISMA_TYPE="Int";;
    string) PRISMA_TYPE="String";;
    float) PRISMA_TYPE="Float";;
    bool) PRISMA_TYPE="Boolean";;
    *) PRISMA_TYPE="String";;
  esac
  PRISMA_ATTRIBUTES+="  $NAME $PRISMA_TYPE\n"
done

PRISMA_ATTRIBUTES=$(echo -e "$PRISMA_ATTRIBUTES" | sed -r '/^\s*$/d')

# Create Prisma model
cat <<EOL >> prisma/schema.prisma

model $CLASS_NAME {
  id    Int    @id @default(autoincrement())
  $PRISMA_ATTRIBUTES
}
EOL

# Run Prisma migrate
npx prisma migrate dev --name "add_${API_NAME}_model"

# Create controller
cat <<EOL > src/controllers/${API_NAME}Controller.ts
import { Request, Response } from 'express';
import prisma from '../config/database';

export const get${CLASS_NAME}s = async (req: Request, res: Response): Promise<void> => {
    const ${VAR_NAME}s = await prisma.${VAR_NAME}.findMany();
    res.json(${VAR_NAME}s);
};

export const get${CLASS_NAME} = async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params;
    const ${VAR_NAME} = await prisma.${VAR_NAME}.findUnique({ where: { id: Number(id) } });
    res.json(${VAR_NAME});
};

export const create${CLASS_NAME} = async (req: Request, res: Response): Promise<void> => {
    const data = req.body;
    const ${VAR_NAME} = await prisma.${VAR_NAME}.create({ data });
    res.json(${VAR_NAME});
};

export const update${CLASS_NAME} = async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params;
    const data = req.body;
    const ${VAR_NAME} = await prisma.${VAR_NAME}.update({ where: { id: Number(id) }, data });
    res.json(${VAR_NAME});
};

export const delete${CLASS_NAME} = async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params;
    await prisma.${VAR_NAME}.delete({ where: { id: Number(id) } });
    res.json({ message: '${CLASS_NAME} deleted successfully' });
};
EOL

# Create routes
cat <<EOL > src/routes/${API_NAME}Route.ts
import { Router } from 'express';
import { get${CLASS_NAME}s, get${CLASS_NAME}, create${CLASS_NAME}, update${CLASS_NAME}, delete${CLASS_NAME} } from '../controllers/${API_NAME}Controller';

const router = Router();

router.get('/${VAR_NAME}s', get${CLASS_NAME}s);
router.get('/${VAR_NAME}s/:id', get${CLASS_NAME});
router.post('/${VAR_NAME}s', create${CLASS_NAME});
router.put('/${VAR_NAME}s/:id', update${CLASS_NAME});
router.delete('/${VAR_NAME}s/:id', delete${CLASS_NAME});

export default router;
EOL

# Update server.ts to include new routes
sed -i "/import mainRoute from '.\/routes\/mainRoute';/a import ${API_NAME}Route from './routes/${API_NAME}Route';" src/server.ts
sed -i "/app.use('\/api', mainRoute);/a app.use('/api/${API_NAME}', ${API_NAME}Route);" src/server.ts

# Create EJS views
mkdir -p src/views/${VAR_NAME}s
cat <<EOL > src/views/${VAR_NAME}s/index.ejs
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${CLASS_NAME}s</title>
</head>
<body>
    <h1>List of ${CLASS_NAME}s</h1>
    <a href="/${VAR_NAME}s/new">Create New ${CLASS_NAME}</a>
    <ul>
        <% ${VAR_NAME}s.forEach(${VAR_NAME} => { %>
            <li><a href="/${VAR_NAME}s/<%= ${VAR_NAME}.id %>"><%= ${VAR_NAME}.name %></a></li>
        <% }); %>
    </ul>
</body>
</html>
EOL

cat <<EOL > src/views/${VAR_NAME}s/show.ejs
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Show ${CLASS_NAME}</title>
</head>
<body>
    <h1><%= ${VAR_NAME}.name %></h1>
    <p>Details:</p>
    <ul>
        <% for (let key in ${VAR_NAME}) { %>
            <% if (key !== 'id') { %>
                <li><%= key %>: <%= ${VAR_NAME}[key] %></li>
            <% } %>
        <% } %>
    </ul>
    <a href="/${VAR_NAME}s">Back to List</a>
    <a href="/${VAR_NAME}s/<%= ${VAR_NAME}.id %>/edit">Edit</a>
    <form action="/${VAR_NAME}s/<%= ${VAR_NAME}.id %>?_method=DELETE" method="POST">
        <button type="submit">Delete</button>
    </form>
</body>
</html>
EOL

cat <<EOL > src/views/${VAR_NAME}s/new.ejs
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create ${CLASS_NAME}</title>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
</head>
<body>
    <h1>Create ${CLASS_NAME}</h1>
    <form id="createForm">
        <% "${MODEL_ATTRIBUTES}".split(" ").forEach(attr => { %>
            <% let [name, type] = attr.split(":"); %>
            <label for="<%= name %>"><%= name %>:</label>
            <input type="text" id="<%= name %>" name="<%= name %>">
        <% }); %>
        <button type="submit">Create</button>
    </form>
    <a href="/${VAR_NAME}s">Back to List</a>

    <script>
        \$('#createForm').submit(function(event) {
            event.preventDefault();
            \$.ajax({
                url: '/api/${VAR_NAME}/${VAR_NAME}s',
                method: 'POST',
                data: \$(this).serialize(),
                success: function(response) {
                    window.location.href = '/${VAR_NAME}s';
                },
                error: function(error) {
                    console.error('Error creating ${VAR_NAME}:', error);
                }
            });
        });
    </script>
</body>
</html>
EOL

cat <<EOL > src/views/${VAR_NAME}s/edit.ejs
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit ${CLASS_NAME}</title>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
</head>
<body>
    <h1>Edit ${CLASS_NAME}</h1>
    <form id="editForm">
        <% "${MODEL_ATTRIBUTES}".split(" ").forEach(attr => { %>
            <% let [name, type] = attr.split(":"); %>
            <label for="<%= name %>"><%= name %>:</label>
            <input type="text" id="<%= name %>" name="<%= name %>" value="<%= ${VAR_NAME}[name] %>">
        <% }); %>
        <button type="submit">Update</button>
    </form>
    <a href="/${VAR_NAME}s">Back to List</a>

    <script>
        \$('#editForm').submit(function(event) {
            event.preventDefault();
            \$.ajax({
                url: '/api/${VAR_NAME}/${VAR_NAME}s/<%= ${VAR_NAME}.id %>?_method=PUT',
                method: 'POST',
                data: \$(this).serialize(),
                success: function(response) {
                    window.location.href = '/${VAR_NAME}s';
                },
                error: function(error) {
                    console.error('Error updating ${VAR_NAME}:', error);
                }
            });
        });
    </script>
</body>
</html>
EOL

# Create EJS view routes
cat <<EOL > src/routes/${API_NAME}ViewRoute.ts
import { Router } from 'express';
import prisma from '../config/database';

const router = Router();

router.get('/${VAR_NAME}s', async (req, res) => {
    const ${VAR_NAME}s = await prisma.${VAR_NAME}.findMany();
    res.render('${VAR_NAME}s/index', { ${VAR_NAME}s });
});

router.get('/${VAR_NAME}s/new', (req, res) => {
    res.render('${VAR_NAME}s/new');
});

router.get('/${VAR_NAME}s/:id', async (req, res) => {
    const { id } = req.params;
    const ${VAR_NAME} = await prisma.${VAR_NAME}.findUnique({ where: { id: Number(id) } });
    res.render('${VAR_NAME}s/show', { ${VAR_NAME} });
});

router.get('/${VAR_NAME}s/:id/edit', async (req, res) => {
    const { id } = req.params;
    const ${VAR_NAME} = await prisma.${VAR_NAME}.findUnique({ where: { id: Number(id) } });
    res.render('${VAR_NAME}s/edit', { ${VAR_NAME} });
});

export default router;
EOL

# Update server.ts to include new view routes
sed -i "/import mainRoute from '.\/routes\/mainRoute';/a import ${API_NAME}ViewRoute from './routes/${API_NAME}ViewRoute';" src/server.ts
sed -i "/app.use('\/api', mainRoute);/a app.use('/', ${API_NAME}ViewRoute);" src/server.ts

echo "CRUD API for $API_NAME created successfully with EJS views."
$SHELL
